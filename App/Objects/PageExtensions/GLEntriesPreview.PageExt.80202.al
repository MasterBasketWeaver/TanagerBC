pageextension 80202 "BA G/L Entries Preview" extends "G/L Entries Preview"
{
    layout
    {
        addafter("Document No.")
        {
            field("BA Load No."; LoadNo)
            {
                ApplicationArea = All;
                Caption = 'Load No.';
                ToolTip = 'Specifies the load number.';
            }
            field("BA Multi-Load No."; Rec."BA Multi-Load No.")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        if RecRef.FieldExist(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()) then
            LoadNo := RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value();
    end;

    var
        PopulateEntryLoadNos: Codeunit "BA Populate Entry Load Nos.";
        LoadNo: Code[20];
}