pageextension 80200 "BA General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter("Entry No.")
        {
            field("BA Multi-Load No."; Rec."BA Multi-Load No.")
            {
                ApplicationArea = All;
            }
        }
    }
}