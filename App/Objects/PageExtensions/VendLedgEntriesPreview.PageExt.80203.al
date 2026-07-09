pageextension 80203 "BA Vend. Ledg. Entries Preview" extends "Vend. Ledg. Entries Preview"
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
        if RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
            LoadNo := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()).Value();
    end;

    var
        PopulateEntryLoadNos: Codeunit "BA Populate Entry Load Nos.";
        LoadNo: Code[20];
}