pageextension 80204 "BA Cust. Ledg. Entries Preview" extends "Cust. Ledg. Entries Preview"
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
        }
    }

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        if RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
            LoadNo := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()).Value();
    end;

    var
        PopulateEntryLoadNos: Codeunit "BA Populate Entry Load Nos.";
        LoadNo: Code[20];
}