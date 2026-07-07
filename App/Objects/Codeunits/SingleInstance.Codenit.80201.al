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


    var
        RecordIDs: List of [RecordID];
        GenJnlView: Text;
        BankAccNo: Code[20];
        JournalTemplateName, JournalBatchName : Code[10];
        DisableReportOutput: Boolean;

}