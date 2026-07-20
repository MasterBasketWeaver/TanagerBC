codeunit 80201 "BA Single Instance"
{
    SingleInstance = true;

    procedure SetDisableReportOutput(NewValue: Boolean)
    begin
        DisableReportOutput := NewValue;
    end;

    procedure GetDisableReportOutput(): Boolean
    begin
        exit(DisableReportOutput);
    end;

    procedure SetGenJnlView(NewValue: Text)
    begin
        GenJnlView := NewValue;
    end;

    procedure GetGenJnlView(): Text
    begin
        exit(GenJnlView);
    end;


    procedure AddRecordIDs(NewValue: RecordID)
    begin
        RecordIDs.Add(NewValue);
    end;

    procedure GetRecordIDs(): List of [RecordID]
    begin
        exit(RecordIDs);
    end;

    procedure ClearRecordIDs()
    begin
        Clear(RecordIDs);
    end;


    procedure SetGenJnlBatchDetails(var GenJnlLine: Record "Gen. Journal Line")
    begin
        JournalTemplateName := GenJnlLine."Journal Template Name";
        JournalBatchName := GenJnlLine."Journal Batch Name";
        BankAccNo := GenJnlLine."Bal. Account No.";
    end;

    procedure GetGenJnlBatchDetails(var TemplateName: Code[10]; var BatchName: Code[10]; var BankAccountNo: Code[20])
    begin
        TemplateName := JournalTemplateName;
        BatchName := JournalBatchName;
        BankAccountNo := BankAccNo;
    end;

    procedure ClearGenJnlBatchDetails()
    begin
        JournalTemplateName := '';
        JournalBatchName := '';
        BankAccNo := '';
    end;


    procedure AddVendorLedgerEntryNo(NewValue: Integer)
    begin
        VLENos.Add(NewValue);
    end;

    procedure GetVendorLedgerEntryNo(): List of [Integer]
    begin
        exit(VLENos);
    end;

    procedure ClearVendorLedgerEntryNos()
    begin
        Clear(VLENos);
    end;

    procedure AddCustomerLedgerEntryNo(NewValue: Integer)
    begin
        CLENos.Add(NewValue);
    end;

    procedure GetCustomerLedgerEntryNo(): List of [Integer]
    begin
        exit(CLENos);
    end;

    procedure ClearCustomerLedgerEntryNos()
    begin
        Clear(CLENos);
    end;



    procedure AddMultiLoadVendorLedgerEntryNo(NewValue: Integer)
    begin
        MultiLoadVLE.Add(NewValue);
    end;

    procedure GetMultiLoadVendorLedgerEntryNo(): List of [Integer]
    begin
        exit(MultiLoadVLE);
    end;

    procedure ClearMultiLoadVendorLedgerEntryNos()
    begin
        Clear(MultiLoadVLE);
    end;

    procedure AddMultiLoadCustomerLedgerEntryNo(NewValue: Integer)
    begin
        MultiLoadCLE.Add(NewValue);
    end;

    procedure GetMultiLoadCustomerLedgerEntryNo(): List of [Integer]
    begin
        exit(MultiLoadCLE);
    end;

    procedure ClearMultiLoadCustomerLedgerEntryNos()
    begin
        Clear(MultiLoadCLE);
    end;



    procedure AddAppliesToDocNo(LineNo: Integer; NewValue: Code[20])
    var
        DocNos: List of [Code[20]];
    begin
        if not AppliesToDocNos.ContainsKey(LineNo) then begin
            DocNos.Add(NewValue);
            AppliesToDocNos.Add(LineNo, DocNos);
        end else
            AppliesToDocNos.Get(LineNo).Add(NewValue);
    end;

    procedure GetAppliesToDocNos(): Dictionary of [Integer, List of [Code[20]]]
    begin
        exit(AppliesToDocNos);
    end;

    procedure ClearAppliesToDocNos()
    begin
        Clear(AppliesToDocNos);
    end;


    procedure SetFilterACHReport(NewValue: Boolean)
    begin
        FilterACHReport := NewValue;
    end;

    procedure GetFilterACHReport(): Boolean
    begin
        exit(FilterACHReport);
    end;




    var
        AppliesToDocNos: Dictionary of [Integer, List of [Code[20]]];
        RecordIDs: List of [RecordID];

        VLENos, CLENos, MultiLoadVLE, MultiLoadCLE : List of [Integer];
        GenJnlView: Text;
        BankAccNo: Code[20];
        JournalTemplateName, JournalBatchName : Code[10];
        DisableReportOutput, FilterACHReport, ACHFromEmail : Boolean;

}