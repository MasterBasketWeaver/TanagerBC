codeunit 80205 "BA Repair Transaction Nos."
{
    // G/L entries inserted at the end of the table by BA Install on 2026-08-26 (twice) and 2026-08-30 (twice)
    // carried older Transaction Nos., and BC derives the next Transaction No. from the last G/L entry.
    // Every posting after each insert therefore reused numbers already belonging to other transactions.
    // Rows posted inside each window get their Transaction No. shifted by Window * 1,000,000 so every window
    // lands in its own range, above everything posted before the first rewind, in chronological order.
    // The new numbers are staged first and applied with one DataTransfer per table.
    Permissions = tabledata "G/L Entry" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Detailed Cust. Ledg. Entry" = RM,
        tabledata "Vendor Ledger Entry" = RM,
        tabledata "Detailed Vendor Ledg. Entry" = RM,
        tabledata "Employee Ledger Entry" = RM,
        tabledata "Detailed Employee Ledger Entry" = RM,
        tabledata "Bank Account Ledger Entry" = RM,
        tabledata "VAT Entry" = RM,
        tabledata "FA Ledger Entry" = RM,
        tabledata "Maintenance Ledger Entry" = RM,
        tabledata "BA Transaction No. Repair" = RIM;

    procedure RepairTransactionNos()
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        VATEntry: Record "VAT Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        InitRewinds();
        GLEntry.LockTable();
        GLEntry.Get(LastEntryBeforeRewind());
        GLEntry.TestField("Transaction No.", LastTransactionNoBeforeRewind());

        StageGLEntries();
        StageCustLedgerEntries();
        StageDtldCustLedgEntries();
        StageVendorLedgerEntries();
        StageDtldVendLedgEntries();
        StageEmployeeLedgerEntries();
        StageDtldEmplLedgEntries();
        StageBankAccountLedgerEntries();
        StageVATEntries();
        StageFALedgerEntries();
        StageMaintenanceLedgerEntries();

        TransferStaged(Database::"G/L Entry", GLEntry.FieldNo("Entry No."), GLEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Entry No."), CustLedgerEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Detailed Cust. Ledg. Entry", DtldCustLedgEntry.FieldNo("Entry No."), DtldCustLedgEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Vendor Ledger Entry", VendorLedgerEntry.FieldNo("Entry No."), VendorLedgerEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Detailed Vendor Ledg. Entry", DtldVendLedgEntry.FieldNo("Entry No."), DtldVendLedgEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Employee Ledger Entry", EmployeeLedgerEntry.FieldNo("Entry No."), EmployeeLedgerEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Detailed Employee Ledger Entry", DtldEmplLedgEntry.FieldNo("Entry No."), DtldEmplLedgEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Bank Account Ledger Entry", BankAccountLedgerEntry.FieldNo("Entry No."), BankAccountLedgerEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"VAT Entry", VATEntry.FieldNo("Entry No."), VATEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"FA Ledger Entry", FALedgerEntry.FieldNo("Entry No."), FALedgerEntry.FieldNo("Transaction No."));
        TransferStaged(Database::"Maintenance Ledger Entry", MaintenanceLedgerEntry.FieldNo("Entry No."), MaintenanceLedgerEntry.FieldNo("Transaction No."));
    end;

    local procedure StageGLEntries()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if GLEntry.Find('+') then
            repeat
                // The inserted rows keep their originals' Transaction No., and their SystemCreatedAt was
                // copied from older entries, so they must not be allowed to end the scan.
                if not IsInsertedGLEntry(GLEntry."Entry No.") then
                    if not Stage(Database::"G/L Entry", GLEntry."Entry No.", GLEntry."Transaction No.", GLEntry.SystemCreatedAt) then
                        exit;
            until GLEntry.Next(-1) = 0;
    end;

    local procedure StageCustLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if CustLedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"Cust. Ledger Entry", CustLedgerEntry."Entry No.", CustLedgerEntry."Transaction No.", CustLedgerEntry.SystemCreatedAt) then
                    exit;
            until CustLedgerEntry.Next(-1) = 0;
    end;

    local procedure StageDtldCustLedgEntries()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if DtldCustLedgEntry.Find('+') then
            repeat
                if not Stage(Database::"Detailed Cust. Ledg. Entry", DtldCustLedgEntry."Entry No.", DtldCustLedgEntry."Transaction No.", DtldCustLedgEntry.SystemCreatedAt) then
                    exit;
            until DtldCustLedgEntry.Next(-1) = 0;
    end;

    local procedure StageVendorLedgerEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if VendorLedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"Vendor Ledger Entry", VendorLedgerEntry."Entry No.", VendorLedgerEntry."Transaction No.", VendorLedgerEntry.SystemCreatedAt) then
                    exit;
            until VendorLedgerEntry.Next(-1) = 0;
    end;

    local procedure StageDtldVendLedgEntries()
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if DtldVendLedgEntry.Find('+') then
            repeat
                if not Stage(Database::"Detailed Vendor Ledg. Entry", DtldVendLedgEntry."Entry No.", DtldVendLedgEntry."Transaction No.", DtldVendLedgEntry.SystemCreatedAt) then
                    exit;
            until DtldVendLedgEntry.Next(-1) = 0;
    end;

    local procedure StageEmployeeLedgerEntries()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if EmployeeLedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"Employee Ledger Entry", EmployeeLedgerEntry."Entry No.", EmployeeLedgerEntry."Transaction No.", EmployeeLedgerEntry.SystemCreatedAt) then
                    exit;
            until EmployeeLedgerEntry.Next(-1) = 0;
    end;

    local procedure StageDtldEmplLedgEntries()
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmplLedgEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if DtldEmplLedgEntry.Find('+') then
            repeat
                if not Stage(Database::"Detailed Employee Ledger Entry", DtldEmplLedgEntry."Entry No.", DtldEmplLedgEntry."Transaction No.", DtldEmplLedgEntry.SystemCreatedAt) then
                    exit;
            until DtldEmplLedgEntry.Next(-1) = 0;
    end;

    local procedure StageBankAccountLedgerEntries()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if BankAccountLedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"Bank Account Ledger Entry", BankAccountLedgerEntry."Entry No.", BankAccountLedgerEntry."Transaction No.", BankAccountLedgerEntry.SystemCreatedAt) then
                    exit;
            until BankAccountLedgerEntry.Next(-1) = 0;
    end;

    local procedure StageVATEntries()
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if VATEntry.Find('+') then
            repeat
                if not Stage(Database::"VAT Entry", VATEntry."Entry No.", VATEntry."Transaction No.", VATEntry.SystemCreatedAt) then
                    exit;
            until VATEntry.Next(-1) = 0;
    end;

    local procedure StageFALedgerEntries()
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if FALedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"FA Ledger Entry", FALedgerEntry."Entry No.", FALedgerEntry."Transaction No.", FALedgerEntry.SystemCreatedAt) then
                    exit;
            until FALedgerEntry.Next(-1) = 0;
    end;

    local procedure StageMaintenanceLedgerEntries()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetLoadFields("Transaction No.", SystemCreatedAt);
        if MaintenanceLedgerEntry.Find('+') then
            repeat
                if not Stage(Database::"Maintenance Ledger Entry", MaintenanceLedgerEntry."Entry No.", MaintenanceLedgerEntry."Transaction No.", MaintenanceLedgerEntry.SystemCreatedAt) then
                    exit;
            until MaintenanceLedgerEntry.Next(-1) = 0;
    end;

    // Returns false once the scan reaches rows created before the first rewind; ledger Entry Nos. follow
    // creation order, so nothing older needs to be read.
    local procedure Stage(TableNo: Integer; EntryNo: Integer; TransactionNo: Integer; CreatedAt: DateTime): Boolean
    var
        TransactionNoRepair: Record "BA Transaction No. Repair";
        Window: Integer;
    begin
        Window := GetWindow(CreatedAt);
        if Window = 0 then
            exit(false);
        // Already repaired rows, and rows posted once the counter climbed past the old maximum,
        // are above LastTransactionNoBeforeRewind and stay as they are.
        if (TransactionNo = 0) or (TransactionNo > LastTransactionNoBeforeRewind()) then
            exit(true);
        TransactionNoRepair."Table No." := TableNo;
        TransactionNoRepair."Entry No." := EntryNo;
        TransactionNoRepair."Old Transaction No." := TransactionNo;
        TransactionNoRepair."New Transaction No." := TransactionNo + Window * 1000000;
        TransactionNoRepair.Insert();
        exit(true);
    end;

    local procedure TransferStaged(TableNo: Integer; EntryNoFieldNo: Integer; TransactionNoFieldNo: Integer)
    var
        TransactionNoRepair: Record "BA Transaction No. Repair";
        DataTransfer: DataTransfer;
    begin
        TransactionNoRepair.SetRange("Table No.", TableNo);
        if TransactionNoRepair.IsEmpty() then
            exit;
        DataTransfer.SetTables(Database::"BA Transaction No. Repair", TableNo);
        DataTransfer.AddSourceFilter(TransactionNoRepair.FieldNo("Table No."), '=%1', TableNo);
        DataTransfer.AddJoin(TransactionNoRepair.FieldNo("Entry No."), EntryNoFieldNo);
        DataTransfer.AddFieldValue(TransactionNoRepair.FieldNo("New Transaction No."), TransactionNoFieldNo);
        DataTransfer.CopyFields();
    end;

    local procedure GetWindow(CreatedAt: DateTime): Integer
    var
        i: Integer;
    begin
        for i := 4 downto 1 do
            if CreatedAt >= RewindAt[i] then
                exit(i);
        exit(0);
    end;

    local procedure IsInsertedGLEntry(EntryNo: Integer): Boolean
    begin
        exit(EntryNo in [3022288 .. 3022314, 3366001, 3366002]);
    end;

    local procedure InitRewinds()
    begin
        // 3022288 inserted (Heb 06.08.2026-2), then 3022289..3022314 (OTR 06.25.2026)
        Evaluate(RewindAt[1], '2026-08-26T21:43:50.190Z', 9);
        // second PopulateManualEntries run; its inserted rows were deleted afterwards
        Evaluate(RewindAt[2], '2026-08-26T21:47:54.660Z', 9);
        // 3366001 inserted (PCM000465)
        Evaluate(RewindAt[3], '2026-08-30T15:02:11.780Z', 9);
        // 3366002 inserted (JE010352)
        Evaluate(RewindAt[4], '2026-08-30T16:11:03.620Z', 9);
    end;

    local procedure LastEntryBeforeRewind(): Integer
    begin
        exit(3022287);
    end;

    local procedure LastTransactionNoBeforeRewind(): Integer
    begin
        exit(815806);
    end;

    var
        RewindAt: array[4] of DateTime;
}
