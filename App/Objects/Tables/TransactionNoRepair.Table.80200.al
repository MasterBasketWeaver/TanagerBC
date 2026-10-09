table 80200 "BA Transaction No. Repair"
{
    // Staging for BA Repair Transaction Nos.: DataTransfer cannot compute a new value, so each row's new
    // Transaction No. is written here first and then joined onto the ledger table by Entry No.
    // Kept after the repair as the record of every old -> new number.
    Caption = 'Transaction No. Repair';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Old Transaction No."; Integer)
        {
            Caption = 'Old Transaction No.';
        }
        field(4; "New Transaction No."; Integer)
        {
            Caption = 'New Transaction No.';
        }
    }

    keys
    {
        key(PK; "Table No.", "Entry No.")
        {
            Clustered = true;
        }
    }
}
