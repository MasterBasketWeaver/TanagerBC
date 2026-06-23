tableextension 80200 "BA G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(80200; "BA Multi-Load No."; Code[2048])
        {
            DataClassification = CustomerContent;
            Editable = false;
            Caption = 'Multi-Load No.';
        }
    }
}