codeunit 80200 "BA Subscribers"
{
    permissions = tabledata "Gen. Journal Line" = R,
        tabledata "Vendor Ledger Entry" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Purch. Inv. Header" = R,
        tabledata "Purch. Cr. Memo Hdr." = R,
        tabledata "Sales Invoice Header" = R,
        tabledata "Sales Cr.Memo Header" = R,
        tabledata "G/L Entry" = RM;



    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", OnBeforeActionEvent, "ExportPaymentsToFile", true, true)]
    local procedure PaymentJournalOnBeforeExportPaymentsToFile(var Rec: Record "Gen. Journal Line")
    begin
        SingleInstance.SetGenJnlBatchDetails(Rec);
        SingleInstance.SetFilterACHReport(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", OnAfterActionEvent, "ExportPaymentsToFile", true, true)]
    local procedure PaymentJournalOnAfterExportPaymentsToFile(var Rec: Record "Gen. Journal Line")
    begin
        SingleInstance.ClearGenJnlBatchDetails();
        SingleInstance.SetFilterACHReport(false);
    end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterUpdatePurchaseHeader, '', true, true)]
    local procedure PurchPostOnAfterUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendorLedgerEntry);
        if not RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
            exit;

        if (PurchInvHeader."No." <> '') and (PurchInvHeader."Pre-Assigned No." <> '') then begin
            RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()).Value(PurchInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnRunOnBeforeFinalizePosting, '', true, true)]
    local procedure PurchPostOnRunOnBeforeFinalizePosting(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        FldRef, FldRef2 : FieldRef;
        LoadNo: Code[20];
    begin
        if (PurchInvHeader."No." <> '') and (PurchInvHeader."Pre-Assigned No." <> '') and VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.") then begin
            RecRef.Open(Database::"G/L Entry");
            if not RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()) then
                exit;
            RecRef.Close();
            RecRef.GetTable(VendorLedgerEntry);
            if not RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
                exit;
            FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
                FldRef.Value(PurchInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
            VendorLedgerEntry.CalcFields(Amount);
            CopyLoadNoToGLEntry(false, PurchInvHeader."Pre-Assigned No.", VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
            if VendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(VendorLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
                    FldRef.Value(PurchInvHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                end;
                VendorLedgerEntry.CalcFields(Amount);
                CopyLoadNoToGLEntry(false, PurchInvHeader."Pre-Assigned No.", VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
            end;
        end;
        if (PurchCrMemoHdr."No." <> '') and VendorLedgerEntry.Get(PurchCrMemoHdr."Vendor Ledger Entry No.") and (PurchCrMemoHdr."Applies-to Doc. No." = '') then begin
            RecRef.GetTable(PurchCrMemoHdr);
            if not RecRef.FieldExist(PopulateEntryLoadNos.PurchaseCreditMemoLoadNoFieldNo()) then
                exit;
            FldRef2 := RecRef.Field(PopulateEntryLoadNos.PurchaseCreditMemoLoadNoFieldNo());
            LoadNo := Format(FldRef2.Value());
            if LoadNo = '' then
                LoadNo := PurchCrMemoHdr."Pre-Assigned No.";
            if (LoadNo = '') and (PurchCrMemoHdr."No. Series" <> '') then
                LoadNo := NoSeries.PeekNextNo(PurchCrMemoHdr."No. Series", PurchCrMemoHdr."Posting Date");
            if LoadNo = '' then
                LoadNo := PurchCrMemoHdr."No.";
            RecRef.Close();
            RecRef.Open(Database::"G/L Entry");
            if not RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()) then
                exit;
            RecRef.Close();
            RecRef.GetTable(VendorLedgerEntry);
            if not RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
                exit;
            FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> LoadNo then begin
                FldRef.Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            end;
            VendorLedgerEntry.CalcFields(Amount);
            CopyLoadNoToGLEntry(false, LoadNo, VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
            if VendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(VendorLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> LoadNo then begin
                    FldRef.Value(LoadNo);
                    RecRef.Modify(false);
                end;
                VendorLedgerEntry.CalcFields(Amount);
                CopyLoadNoToGLEntry(false, LoadNo, VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
            end;
        end;
    end;















    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterUpdateSalesHeader, '', true, true)]
    local procedure SalesPostOnAfterUpdateSalesHeader(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustLedgerEntry);
        if not RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
            exit;

        if (SalesInvoiceHeader."No." <> '') and (SalesInvoiceHeader."Pre-Assigned No." <> '') then begin
            RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()).Value(SalesInvoiceHeader."Pre-Assigned No.");
            RecRef.Modify(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnRunOnBeforeFinalizePosting, '', true, true)]
    local procedure SalesPostOnRunOnBeforeFinalizePosting(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        FldRef, FldRef2 : FieldRef;
        LoadNo: Code[20];
    begin
        if (SalesInvoiceHeader."No." <> '') and (SalesInvoiceHeader."Pre-Assigned No." <> '') and CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.") then begin
            RecRef.Open(Database::"G/L Entry");
            if not RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()) then
                exit;
            RecRef.Close();
            RecRef.GetTable(CustLedgerEntry);
            if not RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
                exit;
            FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> SalesInvoiceHeader."Pre-Assigned No." then begin
                FldRef.Value(SalesInvoiceHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
            CustLedgerEntry.CalcFields(Amount);
            CopyLoadNoToGLEntry(true, SalesInvoiceHeader."Pre-Assigned No.", CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
            if CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(CustLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> SalesInvoiceHeader."Pre-Assigned No." then begin
                    FldRef.Value(SalesInvoiceHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                end;
                CustLedgerEntry.CalcFields(Amount);
                CopyLoadNoToGLEntry(true, SalesInvoiceHeader."Pre-Assigned No.", CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
            end;
        end;

        if (SalesCrMemoHeader."No." <> '') and CustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No.") and (SalesCrMemoHeader."Applies-to Doc. No." = '') then begin
            RecRef.GetTable(SalesCrMemoHeader);
            if not RecRef.FieldExist(PopulateEntryLoadNos.SalesCreditMemoLoadNoFieldNo()) then
                exit;
            FldRef2 := RecRef.Field(PopulateEntryLoadNos.SalesCreditMemoLoadNoFieldNo());
            LoadNo := Format(FldRef2.Value());
            if LoadNo = '' then
                LoadNo := SalesCrMemoHeader."Pre-Assigned No.";
            if (LoadNo = '') and (SalesCrMemoHeader."No. Series" <> '') then
                LoadNo := NoSeries.PeekNextNo(SalesCrMemoHeader."No. Series", SalesCrMemoHeader."Posting Date");
            if LoadNo = '' then
                LoadNo := SalesCrMemoHeader."No.";
            RecRef.Close();
            RecRef.Open(Database::"G/L Entry");
            if not RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()) then
                exit;
            RecRef.Close();
            RecRef.GetTable(CustLedgerEntry);
            if not RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
                exit;
            FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> LoadNo then begin
                FldRef.Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            end;
            CustLedgerEntry.CalcFields(Amount);
            CopyLoadNoToGLEntry(true, LoadNo, CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
            if CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(CustLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> LoadNo then begin
                    FldRef.Value(LoadNo);
                    RecRef.Modify(false);
                end;
                CustLedgerEntry.CalcFields(Amount);
                CopyLoadNoToGLEntry(true, LoadNo, CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
            end;
        end;
    end;









    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnBeforeCode, '', true, true)]
    local procedure GenJnlPostBatchOnBeforeCode()
    begin
        ClearSavedValues();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterPostApply, '', true, true)]
    local procedure GenJnlPostLineOnAfterPostApply(GenJnlLine: Record "Gen. Journal Line"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var NewCVLedgEntryBuf2: Record "CV Ledger Entry Buffer")
    begin
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Vendor:
                begin
                    SingleInstance.AddVendorLedgerEntryNo(OldCVLedgEntryBuf."Entry No.");
                    SingleInstance.AddVendorLedgerEntryNo(NewCVLedgEntryBuf."Entry No.");
                    SingleInstance.AddVendorLedgerEntryNo(NewCVLedgEntryBuf2."Entry No.");
                end;
            GenJnlLine."Account Type"::Customer:
                begin
                    SingleInstance.AddCustomerLedgerEntryNo(OldCVLedgEntryBuf."Entry No.");
                    SingleInstance.AddCustomerLedgerEntryNo(NewCVLedgEntryBuf."Entry No.");
                    SingleInstance.AddCustomerLedgerEntryNo(NewCVLedgEntryBuf2."Entry No.");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete, '', true, true)]
    local procedure GenJnlPostLineOnApplyVendLedgEntryOnBeforeTempOldVendLedgEntryDelete(var GenJournalLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        SingleInstance.AddAppliesToDocNo(GenJournalLine."Line No.", GenJournalLine."Applies-to Doc. No.");
        if SingleInstance.GetAppliesToDocNos().Get(GenJournalLine."Line No.").Count() = 2 then
            SingleInstance.AddMultiLoadVendorLedgerEntryNo(NewCVLedgEntryBuf."Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete, '', true, true)]
    local procedure GenJnlPostLineOnApplyCustLedgEntryOnBeforeTempOldCustLedgEntryDelete(var TempOldCustLedgEntry: Record "Cust. Ledger Entry" temporary; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer")
    begin
        SingleInstance.AddAppliesToDocNo(GenJnlLine."Line No.", GenJnlLine."Applies-to Doc. No.");
        if SingleInstance.GetAppliesToDocNos().Get(GenJnlLine."Line No.").Count() = 2 then
            SingleInstance.AddMultiLoadCustomerLedgerEntryNo(NewCVLedgEntryBuf."Entry No.");
    end;





    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnProcessLinesOnAfterPostGenJnlLines, '', true, true)]
    local procedure GenJnlPostBatchOnProcessLinesOnAfterPostGenJnlLines()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        AppliesToDocNos: Dictionary of [Integer, List of [Code[20]]];
        DocNos: List of [Code[20]];
        LoadNo, AppliedToDocNo : Code[20];
        EntryNos: List of [Integer];
        EntryNo, LineNo : Integer;
    begin
        RecRef.Open(Database::"Vendor Ledger Entry");
        if RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then begin
            EntryNos := SingleInstance.GetVendorLedgerEntryNo();
            foreach EntryNo in EntryNos do begin
                VendorLedgerEntry.Get(EntryNo);
                VendorLedgerEntry.CalcFields(Amount);
                RecRef.GetTable(VendorLedgerEntry);
                LoadNo := Format(RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()).Value());
                if LoadNo <> '' then
                    CopyLoadNoToGLEntry(false, LoadNo, VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
            end;

            EntryNos := SingleInstance.GetMultiLoadVendorLedgerEntryNo();
            foreach EntryNo in EntryNos do begin
                VendorLedgerEntry.Get(EntryNo);
                SetMultiLoadNos(false, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.");
            end;
            Clear(EntryNos);
        end;
        RecRef.Close();

        RecRef.Open(Database::"Cust. Ledger Entry");
        if RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then begin
            EntryNos := SingleInstance.GetCustomerLedgerEntryNo();
            foreach EntryNo in EntryNos do begin
                CustLedgerEntry.Get(EntryNo);
                CustLedgerEntry.CalcFields(Amount);
                RecRef.GetTable(CustLedgerEntry);
                LoadNo := Format(RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()).Value());
                if LoadNo <> '' then
                    CopyLoadNoToGLEntry(true, LoadNo, CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
            end;

            EntryNos := SingleInstance.GetMultiLoadCustomerLedgerEntryNo();
            foreach EntryNo in EntryNos do begin
                CustLedgerEntry.Get(EntryNo);
                SetMultiLoadNos(true, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.");
            end;
        end;

        ClearSavedValues();
    end;





    local procedure SetMultiLoadNos(IsCustomer: Boolean; SourceNo: Code[20]; TransactionNo: Integer)
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        RecRef: RecordRef;
        LoadNos: List of [Code[20]];
        LoadNo: Code[20];
        MultiLoadNo: Text;
    begin
        RecRef.GetTable(GLEntry);
        RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetRange('');
        RecRef.SetTable(GLEntry);
        GLEntry.SetRange("Transaction No.", TransactionNo);
        if IsCustomer then
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer)
        else
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        GLEntry.SetRange("Bal. Account No.", SourceNo);
        if not GLEntry.FindFirst() then
            exit;

        RecRef.GetTable(GLEntry2);
        RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetFilter('<>%1', '');
        RecRef.SetTable(GLEntry2);
        GLEntry2.SetFilter("Entry No.", '<>%1', GLEntry."Entry No.");
        GLEntry2.SetRange("Transaction No.", TransactionNo);
        if IsCustomer then
            GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Customer)
        else
            GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry2.SetRange("Source No.", SourceNo);
        if not GLEntry2.FindSet() then
            exit;

        repeat
            RecRef.GetTable(GLEntry2);
            LoadNo := Format(RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value());
            if not LoadNos.Contains(LoadNo) then
                LoadNos.Add(LoadNo);
        until GLEntry2.Next() = 0;

        if LoadNos.Count() = 1 then begin
            RecRef.GetTable(GLEntry);
            RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNos.Get(1));
            RecRef.Modify(false);
            exit;
        end;

        MultiLoadNo := LoadNos.Get(1);
        LoadNos.RemoveAt(1);
        foreach LoadNo in LoadNos do
            MultiLoadNo := StrSubstNo('%1,%2', MultiLoadNo, LoadNo);
        GLEntry."BA Multi-Load No." := CopyStr(MultiLoadNo, 1, MaxStrLen(GLEntry."BA Multi-Load No."));
        GLEntry.Modify(false);
    end;








    local procedure CopyLoadNoToGLEntry(IsCustomer: Boolean; LoadNo: Code[20]; Amount: Decimal; SourceNo: Code[20]; TransactionNo: Integer; PostingDate: Date)
    begin
        CopyLoadNoToGLEntry(IsCustomer, LoadNo, Amount, SourceNo, TransactionNo, PostingDate, false);
    end;


    local procedure CopyLoadNoToGLEntry(IsCustomer: Boolean; LoadNo: Code[20]; Amount: Decimal; SourceNo: Code[20]; TransactionNo: Integer; PostingDate: Date; Unapply: Boolean)
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        RecRef: RecordRef;
        EntryNoDict: Dictionary of [Integer, List of [Integer]];
    begin
        RecRef.Open(Database::"G/L Entry");
        if Unapply then
            RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetFilter('<>%1', '')
        else
            RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetRange('');
        RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetFilter(Amount, '%1|%2', Amount, -Amount);
        if IsCustomer then
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer)
        else
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        if Unapply then begin
            GLEntry2.CopyFilters(GLEntry);
            GLEntry2.SetRange(Amount);
            RecRef.GetTable(GLEntry2);
            RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
            RecRef.SetTable(GLEntry2);
            GLEntry.AddLoadFields("Document No.");
        end;
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
                if Unapply then
                    CopyLoadNoToRelatedUnappliedGLEntries(EntryNoDict, GLEntry, GLEntry2, LoadNo);
            until GLEntry.Next() = 0;

        GLEntry.SetRange("Source No.");
        GLEntry.SetRange("Source Type");
        if IsCustomer then
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer)
        else
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        GLEntry.SetRange("Bal. Account No.", SourceNo);
        if Unapply then begin
            GLEntry2.Reset();
            GLEntry2.CopyFilters(GLEntry);
            GLEntry2.SetRange(Amount);
            RecRef.GetTable(GLEntry2);
            RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
            RecRef.SetTable(GLEntry2);
        end;
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
                if Unapply then
                    CopyLoadNoToRelatedUnappliedGLEntries(EntryNoDict, GLEntry, GLEntry2, LoadNo);
            until GLEntry.Next() = 0;
    end;


    local procedure CopyLoadNoToRelatedUnappliedGLEntries(var EntryNoDict: Dictionary of [Integer, List of [Integer]]; var GLEntry: Record "G/L Entry"; var GLEntry2: Record "G/L Entry"; LoadNo: Code[20])
    var
        RecRef: RecordRef;
        EntryNos: List of [Integer];
        EntryNoFilter: Text;
        EntryNo: Integer;
    begin
        if not EntryNoDict.ContainsKey(GLEntry."Transaction No.") then begin
            Clear(EntryNos);
            EntryNos.Add(GLEntry."Entry No.");
            EntryNoDict.Add(GLEntry."Transaction No.", EntryNos);
        end else
            EntryNoDict.Get(GLEntry."Transaction No.").Add(GLEntry."Entry No.");
        GLEntry2.SetRange("Document No.", GLEntry."Document No.");
        foreach EntryNo in EntryNoDict.Get(GLEntry."Transaction No.") do
            if EntryNoFilter = '' then
                EntryNoFilter := StrSubstNo('<>%1', EntryNo)
            else
                EntryNoFilter := StrSubstNo('%1&<>%2', EntryNoFilter, EntryNo);
        GLEntry2.SetFilter("Entry No.", EntryNoFilter);
        if GLEntry2.FindSet() then
            repeat
                RecRef.GetTable(GLEntry2);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
                EntryNoDict.Get(GLEntry."Transaction No.").Add(GLEntry2."Entry No.");
            until GLEntry2.Next() = 0;
    end;



    local procedure ClearSavedValues()
    begin
        SingleInstance.ClearVendorLedgerEntryNos();
        SingleInstance.ClearCustomerLedgerEntryNos();
        SingleInstance.ClearMultiLoadVendorLedgerEntryNos();
        SingleInstance.ClearMultiLoadCustomerLedgerEntryNos();
        SingleInstance.ClearAppliesToDocNos();
    end;







    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", OnAfterPostUnapplyVendLedgEntry, '', true, true)]
    local procedure VendEntryApplyPostedEntriesOnAfterPostUnapplyVendLedgEntry(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if TempVendorLedgerEntry.FindSet() then
            repeat
                if VendorLedgerEntry.Get(TempVendorLedgerEntry."Entry No.") and (VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Invoice) then begin
                    PopulateEntryLoadNos.SetVendorLedgerEntryLoadNoValue(VendorLedgerEntry, '');
                    VendorLedgerEntry.Modify(false);
                    VendorLedgerEntry.CalcFields(Amount);
                    CopyLoadNoToGLEntry(false, '', VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date", true);
                end;
            until TempVendorLedgerEntry.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", OnAfterPostUnapplyCustLedgEntry, '', true, true)]
    local procedure CustEntryApplyPostedEntriesOnAfterPostUnapplyCustLedgEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        TempCustLedgerEntry.SetFilter("Document Type", '<>%1', CustLedgerEntry."Document Type"::Invoice);
        if TempCustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry.Get(TempCustLedgerEntry."Entry No.") and (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice) then begin
                    PopulateEntryLoadNos.SetCustLedgerEntryLoadNoValue(CustLedgerEntry, '');
                    CustLedgerEntry.Modify(false);
                    CustLedgerEntry.CalcFields(Amount);
                    CopyLoadNoToGLEntry(true, '', CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date", true);
                end;
            until TempCustLedgerEntry.Next() = 0;
    end;




    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", OnAfterPostApplyVendLedgEntry, '', true, true)]
    local procedure VendEntryApplyPostedEntriesOnAfterPostApplyVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        UpdateLoadNosForAppliedVendorEntries(VendorLedgerEntry."Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", OnAfterPostApplyCustLedgEntry, '', true, true)]
    local procedure CustEntryApplyPostedEntriesOnAfterPostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        UpdateLoadNosForAppliedCustomerEntries(CustLedgerEntry."Entry No.");
    end;


    local procedure UpdateLoadNosForAppliedVendorEntries(AppliedEntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        EntryNos: List of [Integer];
        LoadNos: List of [Code[20]];
        LoadNo: Code[20];
        MultiLoadNo: Text;
        EntryNo: Integer;
    begin
        if not LoadNoFieldsExist(false) then
            exit;
        if not VendorLedgerEntry.Get(AppliedEntryNo) then
            exit;

        EntryNos.Add(AppliedEntryNo);
        VendEntryApplyPostedEntries.GetAppliedVendLedgerEntries(TempVendorLedgerEntry, AppliedEntryNo);
        if TempVendorLedgerEntry.FindSet() then
            repeat
                if not EntryNos.Contains(TempVendorLedgerEntry."Entry No.") then
                    EntryNos.Add(TempVendorLedgerEntry."Entry No.");
            until TempVendorLedgerEntry.Next() = 0;

        foreach EntryNo in EntryNos do
            if VendorLedgerEntry.Get(EntryNo) then begin
                LoadNo := PopulateEntryLoadNos.GetVendorLedgerEntryLoadNoValue(VendorLedgerEntry);
                if (LoadNo <> '') and not LoadNos.Contains(LoadNo) then
                    LoadNos.Add(LoadNo);
            end;
        if LoadNos.Count() = 0 then
            exit;

        if LoadNos.Count() = 1 then begin
            LoadNo := LoadNos.Get(1);
            foreach EntryNo in EntryNos do
                if VendorLedgerEntry.Get(EntryNo) then begin
                    if PopulateEntryLoadNos.GetVendorLedgerEntryLoadNoValue(VendorLedgerEntry) <> LoadNo then begin
                        PopulateEntryLoadNos.SetVendorLedgerEntryLoadNoValue(VendorLedgerEntry, LoadNo);
                        VendorLedgerEntry.Modify(false);
                    end;
                    VendorLedgerEntry.CalcFields(Amount);
                    CopyLoadNoToGLEntry(false, LoadNo, VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
                    SpreadLoadNoToDocumentGLEntries(false, LoadNo, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
                    UpdateMultiLoadNoOnGLEntries(false, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date", '');
                end;
            exit;
        end;

        MultiLoadNo := JoinLoadNos(LoadNos);
        foreach EntryNo in EntryNos do
            if VendorLedgerEntry.Get(EntryNo) then begin
                LoadNo := PopulateEntryLoadNos.GetVendorLedgerEntryLoadNoValue(VendorLedgerEntry);
                VendorLedgerEntry.CalcFields(Amount);
                if LoadNo <> '' then begin
                    CopyLoadNoToGLEntry(false, LoadNo, VendorLedgerEntry.Amount, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
                    SpreadLoadNoToDocumentGLEntries(false, LoadNo, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Document No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date");
                end else
                    UpdateMultiLoadNoOnGLEntries(false, VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry."Posting Date", MultiLoadNo);
            end;
    end;


    local procedure UpdateLoadNosForAppliedCustomerEntries(AppliedEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        EntryNos: List of [Integer];
        LoadNos: List of [Code[20]];
        LoadNo: Code[20];
        MultiLoadNo: Text;
        EntryNo: Integer;
    begin
        if not LoadNoFieldsExist(true) then
            exit;
        if not CustLedgerEntry.Get(AppliedEntryNo) then
            exit;

        EntryNos.Add(AppliedEntryNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, AppliedEntryNo);
        if TempCustLedgerEntry.FindSet() then
            repeat
                if not EntryNos.Contains(TempCustLedgerEntry."Entry No.") then
                    EntryNos.Add(TempCustLedgerEntry."Entry No.");
            until TempCustLedgerEntry.Next() = 0;

        foreach EntryNo in EntryNos do
            if CustLedgerEntry.Get(EntryNo) then begin
                LoadNo := PopulateEntryLoadNos.GetCustLedgerEntryLoadNoValue(CustLedgerEntry);
                if (LoadNo <> '') and not LoadNos.Contains(LoadNo) then
                    LoadNos.Add(LoadNo);
            end;
        if LoadNos.Count() = 0 then
            exit;

        if LoadNos.Count() = 1 then begin
            LoadNo := LoadNos.Get(1);
            foreach EntryNo in EntryNos do
                if CustLedgerEntry.Get(EntryNo) then begin
                    if PopulateEntryLoadNos.GetCustLedgerEntryLoadNoValue(CustLedgerEntry) <> LoadNo then begin
                        PopulateEntryLoadNos.SetCustLedgerEntryLoadNoValue(CustLedgerEntry, LoadNo);
                        CustLedgerEntry.Modify(false);
                    end;
                    CustLedgerEntry.CalcFields(Amount);
                    CopyLoadNoToGLEntry(true, LoadNo, CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
                    SpreadLoadNoToDocumentGLEntries(true, LoadNo, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
                    UpdateMultiLoadNoOnGLEntries(true, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date", '');
                end;
            exit;
        end;

        MultiLoadNo := JoinLoadNos(LoadNos);
        foreach EntryNo in EntryNos do
            if CustLedgerEntry.Get(EntryNo) then begin
                LoadNo := PopulateEntryLoadNos.GetCustLedgerEntryLoadNoValue(CustLedgerEntry);
                CustLedgerEntry.CalcFields(Amount);
                if LoadNo <> '' then begin
                    CopyLoadNoToGLEntry(true, LoadNo, CustLedgerEntry.Amount, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
                    SpreadLoadNoToDocumentGLEntries(true, LoadNo, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date");
                end else
                    UpdateMultiLoadNoOnGLEntries(true, CustLedgerEntry."Customer No.", CustLedgerEntry."Transaction No.", CustLedgerEntry."Posting Date", MultiLoadNo);
            end;
    end;


    local procedure SpreadLoadNoToDocumentGLEntries(IsCustomer: Boolean; LoadNo: Code[20]; SourceNo: Code[20]; DocumentNo: Code[20]; TransactionNo: Integer; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        // Unapplying clears the Load No. on every G/L entry of the document, not just the
        // receivables/payables line, so applying has to put it back on all of them.
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetRange('');
        RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."),
            GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Document No.", DocumentNo);
        if IsCustomer then
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer)
        else
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry.SetRange("Source No.", SourceNo);
        WriteLoadNoToGLEntries(GLEntry, LoadNo);

        GLEntry.SetRange("Source Type");
        GLEntry.SetRange("Source No.");
        if IsCustomer then
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer)
        else
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        GLEntry.SetRange("Bal. Account No.", SourceNo);
        WriteLoadNoToGLEntries(GLEntry, LoadNo);
    end;


    local procedure WriteLoadNoToGLEntries(var GLEntry: Record "G/L Entry"; LoadNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        if not GLEntry.FindSet() then
            exit;
        repeat
            RecRef.GetTable(GLEntry);
            RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
            RecRef.Modify(false);
            RecRef.Close();
        until GLEntry.Next() = 0;
    end;


    local procedure LoadNoFieldsExist(IsCustomer: Boolean): Boolean
    var
        RecRef: RecordRef;
        FieldsExist: Boolean;
    begin
        if IsCustomer then
            RecRef.Open(Database::"Cust. Ledger Entry")
        else
            RecRef.Open(Database::"Vendor Ledger Entry");
        if IsCustomer then
            FieldsExist := RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo())
        else
            FieldsExist := RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
        RecRef.Close();
        if not FieldsExist then
            exit(false);

        RecRef.Open(Database::"G/L Entry");
        exit(RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()));
    end;


    local procedure JoinLoadNos(var LoadNos: List of [Code[20]]): Text
    var
        MultiLoadNo: Text;
        LoadNo: Code[20];
    begin
        if LoadNos.Count() = 0 then
            exit('');
        LoadNo := LoadNos.Get(1);
        LoadNos.RemoveAt(1);
        foreach LoadNo in LoadNos do
            MultiLoadNo := StrSubstNo('%1,%2', MultiLoadNo, LoadNo);
        exit(MultiLoadNo);
    end;


    local procedure UpdateMultiLoadNoOnGLEntries(IsCustomer: Boolean; SourceNo: Code[20]; TransactionNo: Integer; PostingDate: Date; MultiLoadNo: Text)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        if IsCustomer then
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer)
        else
            GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry.SetRange("Source No.", SourceNo);
        SetMultiLoadNoOnGLEntries(GLEntry, MultiLoadNo);

        GLEntry.SetRange("Source Type");
        GLEntry.SetRange("Source No.");
        if IsCustomer then
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer)
        else
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        GLEntry.SetRange("Bal. Account No.", SourceNo);
        SetMultiLoadNoOnGLEntries(GLEntry, MultiLoadNo);
    end;


    local procedure SetMultiLoadNoOnGLEntries(var GLEntry: Record "G/L Entry"; MultiLoadNo: Text)
    var
        NewMultiLoadNo: Text;
    begin
        NewMultiLoadNo := CopyStr(MultiLoadNo, 1, MaxStrLen(GLEntry."BA Multi-Load No."));
        if not GLEntry.FindSet() then
            exit;
        repeat
            if GLEntry."BA Multi-Load No." <> NewMultiLoadNo then begin
                GLEntry."BA Multi-Load No." := NewMultiLoadNo;
                GLEntry.Modify(false);
            end;
        until GLEntry.Next() = 0;
    end;







    var
        NoSeries: Codeunit "No. Series";
        SingleInstance: Codeunit "BA Single Instance";
        PopulateEntryLoadNos: Codeunit "BA Populate Entry Load Nos.";
}