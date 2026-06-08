codeunit 80200 "BA Factor Company Remit. Mgt."
{
    permissions = tabledata "Gen. Journal Line" = R,
        tabledata "Report Selections" = R,
        tabledata "Custom Report Selection" = R,
        tabledata Vendor = R;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bulk Vendor Remit Reporting", "OnRunWithRecordOnBeforeCustomLayoutProcessReport", '', true, true)]
    local procedure BulkVendorRemitReporting_OnRunWithRecordOnBeforeCustomLayoutProcessReport(var CustomLayoutReporting: Codeunit "Custom Layout Reporting")
    var
        GenJnlLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        Filter, Params, GenJnlFilter : Text;
        i, i2, i3, i4 : Integer;
        HasFactorCompany: Boolean;
    begin
        SingleInstance.SetDisableReportOutput(false);
        SingleInstance.SetGenJnlView('');
        SingleInstance.ClearRecordIDs();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        if ReportSelections.FindFirst() then
            if CustomLayoutReporting.HasRequestParameterData(ReportSelections."Report ID") then begin
                Params := CustomLayoutReporting.GetReportRequestPageParameters(ReportSelections."Report ID");
                if Params.Contains(GenJnlFilter) then
                    if TryToSetGenJnlLineView(GenJnlLine, Params) then begin
                        SetCustomReportSelectionFilters(CustomReportSelection);
                        repeat
                            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
                                if IsFactorCompany(GenJnlLine."Account No.") then begin
                                    CustomReportSelection.SetRange("Source No.", GenJnlLine."Account No.");
                                    HasFactorCompany := not CustomReportSelection.IsEmpty();
                                end;
                        until (GenJnlLine.Next() = 0) or HasFactorCompany;
                    end;
            end;


        if HasFactorCompany then begin
            CustomLayoutReporting.SetOutputSupression(true);
            SingleInstance.SetDisableReportOutput(true);
            SingleInstance.SetGenJnlView(GenJnlLine.GetView());
        end;
    end;

    [TryFunction]
    local procedure TryToSetGenJnlLineView(var GenJnlLine: Record "Gen. Journal Line"; var Params: Text)
    var
        Filter: Text;
        i, i2, i3, i4 : Integer;
    begin
        i := Params.IndexOf(GenJnlFilter);
        i2 := i + StrLen(GenJnlFilter);
        i3 := i + CopyStr(Params, i).IndexOf('>');
        i4 := i2 + CopyStr(Params, i2).IndexOf('</DataItem>');
        Filter := CopyStr(Params, i3, i4 - i3 - 1);
        GenJnlLine.SetView(Filter);
        GenJnlLine.FindSet();
    end;



    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", "OnBeforeRunReport", '', true, true)]
    local procedure CustomLayoutReporting_OnBeforeRunReport(var InHandled: Boolean)
    begin
        if SingleInstance.GetDisableReportOutput() then
            InHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterModifyEvent, '', true, true)]
    local procedure GenJnlLine_OnAfterModify(var Rec: Record "Gen. Journal Line")
    begin
        if SingleInstance.GetDisableReportOutput() and Rec."Check Exported" and (Rec."Account Type" = Rec."Account Type"::Vendor) and (Rec."Account No." <> '') then
            SingleInstance.AddRecordIDs(Rec.RecordID);
    end;



    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", "OnAfterActionEvent", "ExportPaymentsToFile", true, true)]
    local procedure PaymentJournal_OnAfterExportPaymentsToFile(var Rec: Record "Gen. Journal Line")
    begin
        if SingleInstance.GetDisableReportOutput() then begin
            PrintAdditionalLayouts();
            SingleInstance.SetDisableReportOutput(false);
            SingleInstance.SetGenJnlView('');
            SingleInstance.ClearRecordIDs();
        end;
    end;

    local procedure PrintAdditionalLayouts()
    var
        GenJnlLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        ReportLayoutList: Record "Report Layout List";
        AllObjWithCaption: Record AllObjWithCaption;
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        RecsToPrintDict: Dictionary of [Integer, List of [RecordID]];
        DefaultReportLayoutNames: Dictionary of [Integer, Text[250]];
        RecordIDs, RecordIds2 : List of [RecordID];
        RecordId: RecordID;
        RecordRef: RecordRef;
        IStream: InStream;
        OStream: OutStream;
        FilterText: TextBuilder;
        FileName: Text;
        DefaultReportID, ReportID : Integer;
        HasReportSelection: Boolean;
    begin
        RecordIDs := SingleInstance.GetRecordIDs();
        if RecordIDs.Count() = 0 then
            exit;

        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        if not ReportSelections.FindFirst() then
            Error(NoVendorRemitReportIDSelectedErr);
        DefaultReportID := ReportSelections."Report ID";


        SetCustomReportSelectionFilters(CustomReportSelection);
        foreach RecordId in RecordIDs do begin
            GenJnlLine.Get(RecordId);
            CustomReportSelection.SetRange("Source No.", GenJnlLine."Account No.");
            if CustomReportSelection.FindFirst() and IsFactorCompany(GenJnlLine."Account No.") then
                if not RecsToPrintDict.ContainsKey(CustomReportSelection."Report ID") then begin
                    Clear(RecordIds2);
                    RecordIds2.Add(RecordId);
                    RecsToPrintDict.Set(CustomReportSelection."Report ID", RecordIds2);
                end else
                    RecsToPrintDict.Get(CustomReportSelection."Report ID").Add(RecordId)
            else
                if not RecsToPrintDict.ContainsKey(DefaultReportID) then begin
                    Clear(RecordIds2);
                    RecordIds2.Add(RecordId);
                    RecsToPrintDict.Set(DefaultReportID, RecordIds2);
                end else
                    RecsToPrintDict.Get(DefaultReportID).Add(RecordId);
        end;


        GenJnlLine.Get(RecordId);
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        DataCompression.CreateZipArchive();
        foreach ReportID in RecsToPrintDict.Keys() do begin
            AllObjWithCaption.Get(ObjectType::Report, ReportID);
            if not GetDefaultReportLayoutSelection(ReportID, ReportLayoutList) then
                Error(NoDefaultLayoutErr, AllObjWithCaption."Object Caption", ReportID);
            ReportSelections.Reset();
            ReportSelections.SetRange("Report ID", ReportID);
            ReportSelections.SetRange("Report Layout Name", ReportLayoutList.Description);
            HasReportSelection := ReportSelections.FindFirst();

            foreach RecordId in RecsToPrintDict.Get(ReportID) do begin
                GenJnlLine.Get(RecordId);
                if FilterText.Length() = 0 then
                    FilterText.Append(Format(GenJnlLine."Line No."))
                else
                    FilterText.Append(StrSubstNo('|%1', GenJnlLine."Line No."));
            end;
            GenJnlLine.SetFilter("Line No.", FilterText.ToText());

            if not HasReportSelection then begin
                RecordRef.GetTable(GenJnlLine);
                TempBlob.CreateOutStream(OStream);
                Report.SaveAs(ReportID, '', ReportFormat::Pdf, OStream, RecordRef);
                Clear(RecordRef);
            end else
                ReportSelections.SaveReportAsPDFInTempBlob(TempBlob, ReportID, GenJnlLine, '', ReportSelections.Usage::"V.Remittance");
            TempBlob.CreateInStream(IStream);

            DataCompression.AddEntry(IStream, StrSubstNo('%1.pdf', AllObjWithCaption."Object Caption"));
            Clear(TempBlob);
            FilterText.Clear();
        end;

        TempBlob.CreateOutStream(OStream);
        DataCompression.SaveZipArchive(OStream);
        TempBlob.CreateInStream(IStream);
        FileName := 'VendorRemittanceReports.zip';
        DownloadFromStream(IStream, '', '', '', FileName);
    end;

    local procedure SetCustomReportSelectionFilters(var CustomReportSelection: Record "Custom Report Selection")
    begin
        CustomReportSelection.SetRange("Source Type", Database::Vendor);
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"V.Remittance");
        CustomReportSelection.SetFilter("Report ID", '<>%1', 0);
        CustomReportSelection.SetFilter("Send To Email", '<>%1', '');
    end;


    local procedure IsFactorCompany(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
        RecRef: RecordRef;
    begin
        if Vendor.Get(VendorNo) then begin
            RecRef.GetTable(Vendor);
            if RecRef.FieldExist(60101) then
                exit(RecRef.Field(60101).Value());
        end;
        exit(false);
    end;



    local procedure GetDefaultReportLayoutSelection(ReportId: Integer; var DefaultReportLayoutList: Record "Report Layout List"): Boolean
    var
        ReportMetadata: Record "Report Metadata";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        DefaultReportLayoutList.Reset();
        if TenantReportLayoutSelection.Get(ReportId, CompanyName(), EmptyGuid) then begin
            DefaultReportLayoutList.SetRange("Name", TenantReportLayoutSelection."Layout Name");
            DefaultReportLayoutList.SetRange("Application ID", TenantReportLayoutSelection."App ID");
            DefaultReportLayoutList.SetRange("Report ID", ReportId);
            exit(DefaultReportLayoutList.FindFirst());
        end;
        if ReportMetadata.Get(ReportId) then begin
            DefaultReportLayoutList.SetRange("Name", ReportMetadata."DefaultLayoutName");
            DefaultReportLayoutList.SetFilter("Application ID", '<>%1', EmptyGuid);
            DefaultReportLayoutList.SetRange("Report ID", ReportId);
            exit(DefaultReportLayoutList.FindFirst());
        end;

        exit(false);
    end;

    var
        SingleInstance: Codeunit "BA Single Instance";

        GenJnlFilter: Label '<DataItem name="Gen. Journal Line">VERSION(1) SORTING(Field1,Field51,Field2) WHERE(';
        NoDefaultLayoutErr: Label 'Must select a default report layout for report %1 (ID %2).', Comment = '%1 = Report Name, %2 = Report ID';
        NoVendorRemitReportIDSelectedErr: Label 'No Report ID specified for Vendor Remittance in Report Selections.\Please update via Report Selectiions - Purchase.';
}