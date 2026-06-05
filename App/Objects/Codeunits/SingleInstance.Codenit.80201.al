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


    var
        RecordIDs: List of [RecordID];
        GenJnlView: Text;
        DisableReportOutput: Boolean;

}