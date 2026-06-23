codeunit 80202 "BA Populate Entry Load Nos."
{
    Subtype = Normal;
    Permissions = TableData "G/L Entry" = RIMD,
        TableData "Vendor Ledger Entry" = RIMD,
        TableData "Purch. Inv. Header" = RIMD,
        TableData "Purch. Cr. Memo Hdr." = RIMD;

    trigger OnRun()
    begin
        PopulatePurchLoadNos();
        PopulateSalesLoadNos();
    end;

    local procedure PopulatePurchLoadNos()
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        CancelledDocument: Record "Cancelled Document";
        RecRef: RecordRef;
        LoadNo: Code[20];
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Source Code"), GLEntry.FieldNo("Entry No."));
        RecRef.Field(50101).SetRange('');
        RecRef.SetTable(GLEntry);
        RecRef.Close();
        GLEntry.SetFilter("Source Code", '%1|%2', 'PURCHJNL', 'PURCHASES');
        VendorLedgerEntry.SetFilter("Applies-to Ext. Doc. No.", '<>%1', '');
        VendorLedgerEntry.SetFilter("Document Type", '%1|%2', VendorLedgerEntry."Document Type"::"Invoice", VendorLedgerEntry."Document Type"::"Credit Memo");
        if GLEntry.FindSet() then
            repeat
                VendorLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
                if VendorLedgerEntry.FindFirst() then
                    case VendorLedgerEntry."Document Type" of
                        VendorLedgerEntry."Document Type"::"Invoice":
                            PopulateLoadNoFromPurchInvoiceEntry(GLEntry, VendorLedgerEntry);
                        VendorLedgerEntry."Document Type"::"Credit Memo":
                            PopulateLoadNoFromPurchCreditMemoEntry(GLEntry, VendorLedgerEntry);
                    end;
            until GLEntry.Next() = 0;
        Commit();

        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetFilter("Closed by Entry No.", '<>%1', 0);
        GLEntry.SetRange("Source Code", 'PAYMENTJNL');
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        if GLEntry.FindSet() then
            repeat
                VendorLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
                if VendorLedgerEntry.FindFirst() then
                    if VendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.") then
                        case VendorLedgerEntry."Document Type" of
                            VendorLedgerEntry."Document Type"::"Invoice":
                                PopulateLoadNoFromPurchInvoiceEntry(GLEntry, VendorLedgerEntry);
                            VendorLedgerEntry."Document Type"::"Credit Memo":
                                PopulateLoadNoFromPurchCreditMemoEntry(GLEntry, VendorLedgerEntry);
                        end;
            until GLEntry.Next() = 0;
        Commit();

        PurchInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
        PurchInvHeader.SetFilter("Vendor Ledger Entry No.", '<>%1', 0);
        if PurchInvHeader.FindSet() then
            repeat
                // UpdateLoadNoForEntries(PurchInvHeader."Vendor Ledger Entry No.", PurchInvHeader."Pre-Assigned No.", true);
                UpdateLoadNoForDocumentEntries(PurchInvHeader."No.", PurchInvHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
            until PurchInvHeader.Next() = 0;
        Commit();

        PurchCrMemoHeader.SetFilter("Vendor Cr. Memo No.", '<>%1', '');
        // PurchCrMemoHeader.SetFilter("Vendor Ledger Entry No.", '<>%1', 0);
        if PurchCrMemoHeader.FindSet() then
            repeat
                if PurchInvHeader.Get(CopyStr(PurchCrMemoHeader."Vendor Cr. Memo No.", 1, MaxStrLen(PurchInvHeader."No."))) then
                    if (PurchInvHeader."Buy-from Vendor No." = PurchCrMemoHeader."Buy-from Vendor No.") and (PurchInvHeader."Pre-Assigned No." <> '') then begin
                        // UpdateLoadNoForEntries(PurchCrMemoHeader."Vendor Ledger Entry No.", PurchInvHeader."Pre-Assigned No.", true);
                        UpdateLoadNoForDocumentEntries(PurchInvHeader."No.", PurchInvHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
                        UpdateLoadNoForDocumentEntries(PurchCrMemoHeader."No.", PurchCrMemoHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
                    end;
            until PurchCrMemoHeader.Next() = 0;
        Commit();

        CancelledDocument.SetRange("Source ID", Database::"Purch. Inv. Header");
        if CancelledDocument.FindSet() then
            repeat
                if PurchCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.") then
                    if PurchInvHeader.Get(CancelledDocument."Cancelled Doc. No.") and (PurchInvHeader."Pre-Assigned No." <> '') then begin
                        // UpdateLoadNoForEntries(PurchCrMemoHeader."Vendor Ledger Entry No.", PurchInvHeader."Pre-Assigned No.", true);
                        UpdateLoadNoForDocumentEntries(PurchInvHeader."No.", PurchInvHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
                    end;
            until CancelledDocument.Next() = 0;
        Commit();

        CancelledDocument.SetRange("Source ID", Database::"Purch. Cr. Memo Hdr.");
        if CancelledDocument.FindSet() then
            repeat
                if PurchCrMemoHeader.Get(CancelledDocument."Cancelled Doc. No.") then
                    if PurchInvHeader.Get(CancelledDocument."Cancelled By Doc. No.") and (PurchInvHeader."Pre-Assigned No." <> '') then begin
                        // UpdateLoadNoForEntries(PurchCrMemoHeader."Vendor Ledger Entry No.", PurchInvHeader."Pre-Assigned No.", true);
                        UpdateLoadNoForDocumentEntries(PurchInvHeader."No.", PurchInvHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
                        UpdateLoadNoForDocumentEntries(PurchCrMemoHeader."No.", PurchCrMemoHeader."Posting Date", PurchInvHeader."Pre-Assigned No.");
                    end;
            until CancelledDocument.Next() = 0;
        Commit();

        PopulateAppliedVendorEntries();
        CopyVendorLoadNosToGLEntries();
        SetMultiLoadNos(false);
    end;


    local procedure PopulateAppliedVendorEntries()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry, VendorLedgerEntry2 : Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        LoadNo: Code[20];
    begin
        PurchInvHeader.SetLoadFields("Pre-Assigned No.", "Vendor Ledger Entry No.");
        PurchInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
        PurchInvHeader.SetFilter("Vendor Ledger Entry No.", '<>%1', 0);
        if PurchInvHeader.FindSet() then
            repeat
                if VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.") then begin
                    RecRef.GetTable(VendorLedgerEntry);
                    RecRef.Field(70202).Value(PurchInvHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                    RecRef.Close();
                    if VendorLedgerEntry2.Get(VendorLedgerEntry."Closed by Entry No.") then begin
                        RecRef.GetTable(VendorLedgerEntry2);
                        RecRef.Field(70202).Value(PurchInvHeader."Pre-Assigned No.");
                        RecRef.Modify(false);
                        RecRef.Close();
                    end;
                end;
            until PurchInvHeader.Next() = 0;

        Commit();

        RecRef.Open(Database::"Vendor Ledger Entry");
        RecRef.SetLoadFields(70202, VendorLedgerEntry.FieldNo("Closed by Entry No."));
        RecRef.Field(70202).SetFilter('<>%1', '');
        RecRef.SetTable(VendorLedgerEntry);
        RecRef.Close();
        VendorLedgerEntry.SetFilter("Closed by Entry No.", '<>%1', 0);
        if VendorLedgerEntry.FindSet() then
            repeat
                if VendorLedgerEntry2.Get(VendorLedgerEntry."Closed by Entry No.") then begin
                    RecRef.GetTable(VendorLedgerEntry);
                    LoadNo := RecRef.Field(70202).Value();
                    RecRef.Close();
                    RecRef.GetTable(VendorLedgerEntry2);
                    RecRef.Field(70202).Value(LoadNo);
                    RecRef.Modify(false);
                    RecRef.Close();
                end;
            until VendorLedgerEntry.Next() = 0;

        Commit();
    end;

    local procedure CopyVendorLoadNosToGLEntries()
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        LoadNo: Code[20];
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetRange('');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        RecRef.Open(Database::"Vendor Ledger Entry");
        RecRef.Field(70202).SetFilter('<>%1', '');
        RecRef.SetLoadFields(70202, VendorLedgerEntry.FieldNo("Transaction No."), VendorLedgerEntry.FieldNo("Vendor No."), VendorLedgerEntry.FieldNo("Amount"), VendorLedgerEntry.FieldNo("Currency Code"), VendorLedgerEntry.FieldNo("Posting Date"));
        RecRef.SetTable(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Currency Code", '');
        VendorLedgerEntry.SetAutoCalcFields(Amount);
        if VendorLedgerEntry.FindSet() then
            repeat
                GLEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
                GLEntry.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
                GLEntry.SetFilter(Amount, '%1|%2', VendorLedgerEntry.Amount, -VendorLedgerEntry.Amount);

                GLEntry.SetRange("Source No.", VendorLedgerEntry."Vendor No.");
                GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
                if GLEntry.FindSet() then begin
                    RecRef.GetTable(VendorLedgerEntry);
                    LoadNo := RecRef.Field(70202).Value();
                    RecRef.Close();
                    repeat
                        RecRef.GetTable(GLEntry);
                        RecRef.Field(50101).Value(LoadNo);
                        RecRef.Modify(false);
                        RecRef.Close();
                    until GLEntry.Next() = 0;
                end;
                GLEntry.SetRange("Source No.");
                GLEntry.SetRange("Source Type");

                GLEntry.SetRange("Bal. Account No.", VendorLedgerEntry."Vendor No.");
                GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
                if GLEntry.FindSet() then begin
                    RecRef.GetTable(VendorLedgerEntry);
                    LoadNo := RecRef.Field(70202).Value();
                    RecRef.Close();
                    repeat
                        RecRef.GetTable(GLEntry);
                        RecRef.Field(50101).Value(LoadNo);
                        RecRef.Modify(false);
                        RecRef.Close();
                    until GLEntry.Next() = 0;
                end;
                GLEntry.SetRange("Bal. Account No.");
                GLEntry.SetRange("Bal. Account Type");
            until VendorLedgerEntry.Next() = 0;
        Commit();
    end;


    // local procedure UpdateMultiLoadVendorEntries()
    // var
    //     GLEntry, GLEntry2 : Record "G/L Entry";
    //     RecRef: RecordRef;
    // begin
    //     RecRef.Open(Database::"G/L Entry");
    //     RecRef.Field(50101).SetRange('');
    //     RecRef.SetLoadFields(50101, GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
    //     RecRef.SetTable(GLEntry);
    //     RecRef.Close();
    //     GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
    //     GLEntry.SetFilter("Source No.", '<>%1', '');
    //     GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
    //     GLEntry.SetFilter("Bal. Account No.", '<>%1', '');

    //     GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Vendor);
    //     GLEntry2.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"Bank Account");
    //     RecRef.GetTable(GLEntry2);
    //     // RecRef.Field(50101).SetFilter('<>%1', '');
    //     RecRef.SetLoadFields(50101, GLEntry2.FieldNo("Transaction No."), GLEntry2.FieldNo("Source No."), GLEntry2.FieldNo("Amount"), GLEntry2.FieldNo("Source Type"), GLEntry2.FieldNo("Posting Date"));
    //     RecRef.SetTable(GLEntry2);
    //     RecRef.Close();
    //     SetMultiLoadNos(GLEntry, GLEntry2);
    // end;


    // local procedure UpdateMultiLoadCustomerEntries()
    // var
    //     GLEntry, GLEntry2 : Record "G/L Entry";
    //     RecRef: RecordRef;
    // begin
    //     RecRef.Open(Database::"G/L Entry");
    //     RecRef.Field(50101).SetRange('');
    //     RecRef.SetLoadFields(50101, GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"),
    //         GLEntry.FieldNo("Bal. Account No."), GLEntry.FieldNo("Bal. Account Type"), GLEntry.FieldNo("BA Multi-Load No."));
    //     RecRef.SetTable(GLEntry);
    //     RecRef.Close();
    //     GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
    //     GLEntry.SetFilter("Source No.", '<>%1', '');
    //     GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer);
    //     GLEntry.SetFilter("Bal. Account No.", '<>%1', '');

    //     GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Customer);
    //     GLEntry2.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"Bank Account");
    //     RecRef.GetTable(GLEntry2);
    //     // RecRef.Field(50101).SetFilter('<>%1', '');
    //     RecRef.SetLoadFields(50101, GLEntry2.FieldNo("Transaction No."), GLEntry2.FieldNo("Source No."), GLEntry2.FieldNo("Amount"), GLEntry2.FieldNo("Source Type"), GLEntry2.FieldNo("Posting Date"),
    //         GLEntry2.FieldNo("Bal. Account No."), GLEntry2.FieldNo("Bal. Account Type"), GLEntry2.FieldNo("BA Multi-Load No."));
    //     RecRef.SetTable(GLEntry2);
    //     RecRef.Close();
    //     SetMultiLoadNos(GLEntry, GLEntry2);
    // end;







    local procedure PopulateSalesLoadNos()
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        RecRef: RecordRef;
        Amount: Decimal;
        MultiLoadNo: Text;
        LoadNo: Code[20];
        SingleLoad: Boolean;
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Source Code"), GLEntry.FieldNo("Entry No."));
        RecRef.Field(50101).SetRange('');
        RecRef.SetTable(GLEntry);
        RecRef.Close();
        GLEntry.SetRange("Source Code", 'SALES');
        CustomerLedgerEntry.SetFilter("Applies-to Ext. Doc. No.", '<>%1', '');
        CustomerLedgerEntry.SetFilter("Document Type", '%1|%2', CustomerLedgerEntry."Document Type"::"Invoice", CustomerLedgerEntry."Document Type"::"Credit Memo");
        if GLEntry.FindSet() then
            repeat
                CustomerLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
                if CustomerLedgerEntry.FindFirst() then
                    case CustomerLedgerEntry."Document Type" of
                        CustomerLedgerEntry."Document Type"::"Invoice":
                            PopulateLoadNoFromSalesInvoiceEntry(GLEntry, CustomerLedgerEntry);
                        CustomerLedgerEntry."Document Type"::"Credit Memo":
                            PopulateLoadNoFromSalesCreditMemoEntry(GLEntry, CustomerLedgerEntry);
                    end;
            until GLEntry.Next() = 0;
        Commit();



        CustomerLedgerEntry.Reset();
        CustomerLedgerEntry.SetLoadFields("Closed by Entry No.", "Transaction No.");
        CustomerLedgerEntry.SetFilter("Closed by Entry No.", '<>%1', 0);
        GLEntry.SetRange("Source Code", 'PAYMENTJNL');
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        if GLEntry.FindSet() then
            repeat
                CustomerLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
                if CustomerLedgerEntry.FindFirst() then
                    if CustomerLedgerEntry.Get(CustomerLedgerEntry."Closed by Entry No.") then
                        case CustomerLedgerEntry."Document Type" of
                            CustomerLedgerEntry."Document Type"::"Invoice":
                                PopulateLoadNoFromSalesInvoiceEntry(GLEntry, CustomerLedgerEntry);
                            CustomerLedgerEntry."Document Type"::"Credit Memo":
                                PopulateLoadNoFromSalesCreditMemoEntry(GLEntry, CustomerLedgerEntry);
                        end;
            until GLEntry.Next() = 0;
        Commit();

        SalesInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
        SalesInvHeader.SetFilter("Cust. Ledger Entry No.", '<>%1', 0);
        if SalesInvHeader.FindSet() then
            repeat
                // UpdateLoadNoForEntries(SalesInvHeader."Cust. Ledger Entry No.", SalesInvHeader."Pre-Assigned No.", false);
                UpdateLoadNoForDocumentEntries(SalesInvHeader."No.", SalesInvHeader."Posting Date", SalesInvHeader."Pre-Assigned No.");
            until SalesInvHeader.Next() = 0;
        Commit();

        CancelledDocument.SetRange("Source ID", Database::"Sales Invoice Header");
        if CancelledDocument.FindSet() then
            repeat
                if SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.") then
                    if SalesInvHeader.Get(CancelledDocument."Cancelled Doc. No.") and (SalesInvHeader."Pre-Assigned No." <> '') then begin
                        // UpdateLoadNoForEntries(SalesCrMemoHeader."Cust. Ledger Entry No.", SalesInvHeader."Pre-Assigned No.", false);
                        UpdateLoadNoForDocumentEntries(SalesInvHeader."No.", SalesInvHeader."Posting Date", SalesInvHeader."Pre-Assigned No.");
                        UpdateLoadNoForDocumentEntries(SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", SalesInvHeader."Pre-Assigned No.");
                    end;
            until CancelledDocument.Next() = 0;
        Commit();

        CancelledDocument.SetRange("Source ID", Database::"Sales Cr.Memo Header");
        if CancelledDocument.FindSet() then
            repeat
                if SalesCrMemoHeader.Get(CancelledDocument."Cancelled Doc. No.") then
                    if SalesInvHeader.Get(CancelledDocument."Cancelled By Doc. No.") and (SalesInvHeader."Pre-Assigned No." <> '') then begin
                        // UpdateLoadNoForEntries(SalesCrMemoHeader."Cust. Ledger Entry No.", SalesInvHeader."Pre-Assigned No.", false);
                        UpdateLoadNoForDocumentEntries(SalesInvHeader."No.", SalesInvHeader."Posting Date", SalesInvHeader."Pre-Assigned No.");
                        UpdateLoadNoForDocumentEntries(SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date", SalesInvHeader."Pre-Assigned No.");
                    end;
            until CancelledDocument.Next() = 0;
        Commit();

        PopulateAppliedCustomerEntries();
        CopyCustomerLoadNosToGLEntries();
        SetMultiLoadNos(true);
    end;


    local procedure PopulateAppliedCustomerEntries()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        CustomerLedgerEntry, CustomerLedgerEntry2 : Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        LoadNo: Code[20];
    begin
        SalesInvHeader.SetLoadFields("Pre-Assigned No.", "Cust. Ledger Entry No.");
        SalesInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
        SalesInvHeader.SetFilter("Cust. Ledger Entry No.", '<>%1', 0);
        if SalesInvHeader.FindSet() then
            repeat
                if CustomerLedgerEntry.Get(SalesInvHeader."Cust. Ledger Entry No.") then begin
                    RecRef.GetTable(CustomerLedgerEntry);
                    RecRef.Field(70201).Value(SalesInvHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                    RecRef.Close();
                    if CustomerLedgerEntry2.Get(CustomerLedgerEntry."Closed by Entry No.") then begin
                        RecRef.GetTable(CustomerLedgerEntry2);
                        RecRef.Field(70201).Value(SalesInvHeader."Pre-Assigned No.");
                        RecRef.Modify(false);
                        RecRef.Close();
                    end;
                end;
            until SalesInvHeader.Next() = 0;
        Commit();

        RecRef.Open(Database::"Cust. Ledger Entry");
        RecRef.SetLoadFields(70201, CustomerLedgerEntry.FieldNo("Closed by Entry No."));
        RecRef.Field(70201).SetFilter('<>%1', '');
        RecRef.SetTable(CustomerLedgerEntry);
        RecRef.Close();
        CustomerLedgerEntry.SetFilter("Closed by Entry No.", '<>%1', 0);
        if CustomerLedgerEntry.FindSet() then
            repeat
                if CustomerLedgerEntry2.Get(CustomerLedgerEntry."Closed by Entry No.") then begin
                    RecRef.GetTable(CustomerLedgerEntry);
                    LoadNo := RecRef.Field(70201).Value();
                    RecRef.Close();
                    RecRef.GetTable(CustomerLedgerEntry2);
                    RecRef.Field(70201).Value(LoadNo);
                    RecRef.Modify(false);
                    RecRef.Close();
                end;
            until CustomerLedgerEntry.Next() = 0;
        Commit();
    end;

    local procedure CopyCustomerLoadNosToGLEntries()
    var
        GLEntry: Record "G/L Entry";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        LoadNo: Code[20];
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetRange('');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        RecRef.Open(Database::"Cust. Ledger Entry");
        RecRef.Field(70201).SetFilter('<>%1', '');
        RecRef.SetLoadFields(70201, CustomerLedgerEntry.FieldNo("Transaction No."), CustomerLedgerEntry.FieldNo("Customer No."), CustomerLedgerEntry.FieldNo("Amount"), CustomerLedgerEntry.FieldNo("Currency Code"), CustomerLedgerEntry.FieldNo("Posting Date"));
        RecRef.SetTable(CustomerLedgerEntry);
        CustomerLedgerEntry.SetRange("Currency Code", '');
        CustomerLedgerEntry.SetAutoCalcFields(Amount);
        if CustomerLedgerEntry.FindSet() then
            repeat
                GLEntry.SetRange("Transaction No.", CustomerLedgerEntry."Transaction No.");
                GLEntry.SetRange("Posting Date", CustomerLedgerEntry."Posting Date");
                GLEntry.SetFilter(Amount, '%1|%2', CustomerLedgerEntry.Amount, -CustomerLedgerEntry.Amount);
                GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
                GLEntry.SetRange("Source No.", CustomerLedgerEntry."Customer No.");
                if GLEntry.FindSet() then begin
                    RecRef.GetTable(CustomerLedgerEntry);
                    LoadNo := RecRef.Field(70201).Value();
                    repeat
                        RecRef.GetTable(GLEntry);
                        RecRef.Field(50101).Value(LoadNo);
                        RecRef.Modify(false);
                        RecRef.Close();
                    until GLEntry.Next() = 0;
                end;
                GLEntry.SetRange("Source Type");
                GLEntry.SetRange("Source No.");

                GLEntry.SetRange("Bal. Account Type", GLEntry."Source Type"::Customer);
                GLEntry.SetRange("Bal. Account No.", CustomerLedgerEntry."Customer No.");
                if GLEntry.FindSet() then begin
                    RecRef.GetTable(CustomerLedgerEntry);
                    LoadNo := RecRef.Field(70201).Value();
                    repeat
                        RecRef.GetTable(GLEntry);
                        RecRef.Field(50101).Value(LoadNo);
                        RecRef.Modify(false);
                        RecRef.Close();
                    until GLEntry.Next() = 0;
                end;
                GLEntry.SetRange("Bal. Account Type");
                GLEntry.SetRange("Bal. Account No.");
            until CustomerLedgerEntry.Next() = 0;
        Commit();
    end;
















    // local procedure UpdateLoadNoForEntries(EntryNo: Integer; LoadNo: Code[20]; IsVendor: Boolean)
    // var
    //     EntryNos: List of [Integer];
    // begin
    //     EntryNos.Add(EntryNo);
    //     UpdateLoadNoForEntries(EntryNo, LoadNo, IsVendor, EntryNos);
    // end;

    // local procedure UpdateLoadNoForEntries(EntryNo: Integer; LoadNo: Code[20]; IsVendor: Boolean; var EntryNos: List of [Integer])
    // var
    //     CustomerLedgerEntry: Record "Cust. Ledger Entry";
    //     VendorLedgerEntry: Record "Vendor Ledger Entry";
    //     GLEntry: Record "G/L Entry";
    //     RecRef: RecordRef;
    // begin
    //     if IsVendor then begin
    //         VendorLedgerEntry.Get(EntryNo);
    //         if VendorLedgerEntry."Closed by Entry No." <> 0 then
    //             if not EntryNos.Contains(VendorLedgerEntry."Closed by Entry No.") then begin
    //                 EntryNos.Add(VendorLedgerEntry."Closed by Entry No.");
    //                 UpdateLoadNoForEntries(VendorLedgerEntry."Closed by Entry No.", LoadNo, IsVendor, EntryNos);
    //             end;
    //         RecRef.GetTable(VendorLedgerEntry);
    //         RecRef.Field(70202).Value(LoadNo);
    //         RecRef.Modify(false);
    //         RecRef.Close();
    //         GLEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
    //     end else begin
    //         CustomerLedgerEntry.Get(EntryNo);
    //         if CustomerLedgerEntry."Closed by Entry No." <> 0 then
    //             if not EntryNos.Contains(CustomerLedgerEntry."Closed by Entry No.") then begin
    //                 EntryNos.Add(CustomerLedgerEntry."Closed by Entry No.");
    //                 UpdateLoadNoForEntries(CustomerLedgerEntry."Closed by Entry No.", LoadNo, IsVendor, EntryNos);
    //             end;
    //         RecRef.GetTable(CustomerLedgerEntry);
    //         RecRef.Field(70201).Value(LoadNo);
    //         RecRef.Modify(false);
    //         RecRef.Close();
    //         GLEntry.SetRange("Transaction No.", CustomerLedgerEntry."Transaction No.");
    //     end;
    //     RecRef.GetTable(GLEntry);
    //     if RecRef.FindSet() then
    //         repeat
    //             RecRef.Field(50101).Value(LoadNo);
    //             RecRef.Modify(false);
    //         until RecRef.Next() = 0;
    //     RecRef.Close();
    // end;

    local procedure UpdateLoadNoForDocumentEntries(DocumentNo: Code[20]; PostingDate: Date; LoadNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Document No.", DocumentNo);
        RecRef.GetTable(GLEntry);
        RecRef.Field(50101).SetFilter('<>%1', '');
        if RecRef.FindSet() then
            repeat
                RecRef.Field(50101).Value(LoadNo);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;





    local procedure PopulateLoadNoFromSalesInvoiceEntry(var GLEntry: Record "G/L Entry"; var CustomerLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        RecRef: RecordRef;
    begin
        if SalesInvHeader.Get(CustomerLedgerEntry."Document No.") and (SalesInvHeader."Pre-Assigned No." <> '') then begin
            RecRef.GetTable(GLEntry);
            RecRef.Field(50101).Value(SalesInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
            RecRef.Close();
            RecRef.GetTable(CustomerLedgerEntry);
            RecRef.Field(70201).Value(SalesInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
            RecRef.Close();
        end;
    end;

    local procedure PopulateLoadNoFromSalesCreditMemoEntry(var GLEntry: Record "G/L Entry"; var CustomerLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
    begin
        if SalesCrMemoHeader.Get(CustomerLedgerEntry."Document No.") then begin
            SalesInvHeader.SetRange("Sell-to Customer No.", SalesCrMemoHeader."Sell-to Customer No.");
            SalesInvHeader.SetRange("External Document No.", CustomerLedgerEntry."Applies-to Ext. Doc. No.");
            SalesInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
            if SalesInvHeader.FindFirst() then begin
                RecRef.GetTable(GLEntry);
                RecRef.Field(50101).Value(SalesInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
                RecRef.GetTable(CustomerLedgerEntry);
                RecRef.Field(70201).Value(SalesInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
        end;
    end;



    local procedure PopulateLoadNoFromPurchInvoiceEntry(var GLEntry: Record "G/L Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RecRef: RecordRef;
    begin
        if PurchInvHeader.Get(VendorLedgerEntry."Document No.") and (PurchInvHeader."Pre-Assigned No." <> '') then begin
            RecRef.GetTable(GLEntry);
            RecRef.Field(50101).Value(PurchInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
            RecRef.Close();
            RecRef.GetTable(VendorLedgerEntry);
            RecRef.Field(70202).Value(PurchInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
            RecRef.Close();
        end;
    end;

    local procedure PopulateLoadNoFromPurchCreditMemoEntry(var GLEntry: Record "G/L Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        RecRef: RecordRef;
    begin
        if PurchCrMemoHeader.Get(VendorLedgerEntry."Document No.") then begin
            PurchInvHeader.SetRange("Buy-from Vendor No.", PurchCrMemoHeader."Buy-from Vendor No.");
            PurchInvHeader.SetRange("Vendor Invoice No.", VendorLedgerEntry."Applies-to Ext. Doc. No.");
            PurchInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
            if PurchInvHeader.FindFirst() then begin
                RecRef.GetTable(GLEntry);
                RecRef.Field(50101).Value(PurchInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
                RecRef.GetTable(VendorLedgerEntry);
                RecRef.Field(70202).Value(PurchInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
        end;
    end;





    local procedure PopulateRelatedGLEntries()
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        DictOfEntryNos: Dictionary of [Integer, List of [Integer]];
        EntryNos: List of [Integer];
        RecRef: RecordRef;
        LoadNo: Code[20];
        EntryNo: Integer;
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetFilter('<>%1', '');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Entry No."), GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("Document No."));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetRange('');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Entry No."), GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("Document No."));
        RecRef.SetTable(GLEntry2);
        RecRef.Close();

        if GLEntry.FindSet() then
            repeat
                GLEntry2.SetFilter("Entry No.", '<>%1', GLEntry."Entry No.");
                GLEntry2.SetRange("Posting Date", GLEntry."Posting Date");
                GLEntry2.SetRange("Document No.", GLEntry."Document No.");
                if GLEntry2.FindSet() then begin
                    Clear(EntryNos);
                    repeat
                        EntryNos.Add(GLEntry2."Entry No.");
                    until GLEntry2.Next() = 0;
                    DictOfEntryNos.Add(GLEntry."Entry No.", EntryNos);
                end;
            until GLEntry.Next() = 0;

        foreach EntryNo in DictOfEntryNos.Keys() do begin
            GLEntry.Get(EntryNo);
            RecRef.GetTable(GLEntry);
            LoadNo := RecRef.Field(50101).Value();
            RecRef.Close();
            foreach EntryNo in DictOfEntryNos.Get(GLEntry."Entry No.") do begin
                GLEntry2.Get(EntryNo);
                RecRef.GetTable(GLEntry2);
                RecRef.Field(50101).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            end;
        end;
    end;


    local procedure PopulateMatchingGLEntries()
    var
        GLEntry, GLEntry2 : Record "G/L Entry";
        RecRef: RecordRef;
        LoadNo: Code[20];
        EntryNo: Integer;
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetRange('');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Entry No."), GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Amount"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(50101).SetFilter('<>%1', '');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Entry No."), GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("Document No."), GLEntry.FieldNo("Amount"));
        RecRef.SetTable(GLEntry2);
        RecRef.Close();

        GLEntry.SetAutoCalcFields(Amount);
        if GLEntry.FindSet() then
            repeat
                GLEntry2.SetFilter("Entry No.", '<>%1', GLEntry."Entry No.");
                GLEntry2.SetRange("Posting Date", GLEntry."Posting Date");
                GLEntry2.SetRange("Document No.", GLEntry."Document No.");
                GLEntry2.SetRange(Amount, -GLEntry."Amount");
                if GLEntry2.FindFirst() then begin
                    RecRef.GetTable(GLEntry2);
                    LoadNo := RecRef.Field(50101).Value();
                    RecRef.Close();
                    RecRef.GetTable(GLEntry);
                    RecRef.Field(50101).Value(LoadNo);
                    RecRef.Modify(false);
                    RecRef.Close();
                end;
            until GLEntry.Next() = 0;
    end;


    local procedure SetMultiLoadNos(IsCustomer: Boolean)
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        RecRef, RecRef2 : RecordRef;
        Amount: Decimal;
        MultiLoadNo: Text;
        LoadNos: List of [Code[20]];
        LoadNo: Code[20];
        SingleLoad: Boolean;
    begin
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
        GLEntry.SetFilter("Source No.", '<>%1', '');
        if IsCustomer then
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Customer)
        else
            GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        GLEntry.SetFilter("Bal. Account No.", '<>%1', '');
        RecRef.GetTable(GLEntry);
        RecRef.Field(50101).SetRange('');
        RecRef.SetLoadFields(50101, GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"),
            GLEntry.FieldNo("Bal. Account No."), GLEntry.FieldNo("Bal. Account Type"), GLEntry.FieldNo("BA Multi-Load No."));

        if IsCustomer then
            GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Customer)
        else
            GLEntry2.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry2.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"Bank Account");
        RecRef2.GetTable(GLEntry2);
        RecRef2.SetLoadFields(50101, GLEntry2.FieldNo("Transaction No."), GLEntry2.FieldNo("Source No."), GLEntry2.FieldNo("Amount"), GLEntry2.FieldNo("Source Type"), GLEntry2.FieldNo("Posting Date"),
            GLEntry2.FieldNo("Bal. Account No."), GLEntry2.FieldNo("Bal. Account Type"), GLEntry2.FieldNo("BA Multi-Load No."));
        RecRef2.SetTable(GLEntry2);
        RecRef2.Close();


        if RecRef.FindSet() then
            repeat
                RecRef.SetTable(GLEntry);
                GLEntry2.SetRange("Transaction No.", GLEntry."Transaction No.");
                GLEntry2.SetRange("Source No.", GLEntry."Bal. Account No.");
                GLEntry2.SetRange("Bal. Account No.", GLEntry."Source No.");
                if GLEntry2.FindSet() then begin
                    RecRef2.GetTable(GLEntry2);
                    MultiLoadNo := Format(RecRef2.Field(50101).Value());
                    if MultiLoadNo <> '' then
                        LoadNos.Add(MultiLoadNo);
                    Amount := -GLEntry2.Amount;
                    SingleLoad := false;
                    RecRef2.Close();
                    if GLEntry2.Next() <> 0 then
                        repeat
                            RecRef2.GetTable(GLEntry2);
                            LoadNo := Format(RecRef2.Field(50101).Value());
                            if (LoadNo <> '') then
                                if not LoadNos.Contains(LoadNo) then begin
                                    LoadNos.Add(LoadNo);
                                    MultiLoadNo := CopyStr(StrSubstNo('%1,%2', MultiLoadNo, LoadNo), 1, MaxStrLen(GLEntry."BA Multi-Load No."));
                                end;
                            Amount -= GLEntry2.Amount;
                            RecRef2.Close();
                        until GLEntry2.Next() = 0
                    else
                        SingleLoad := true;
                    if LoadNos.Count() <= 1 then
                        SingleLoad := true;
                    if MultiLoadNo[1] = ',' then
                        MultiLoadNo := CopyStr(MultiLoadNo, 2);
                    if SingleLoad and (MultiLoadNo <> '') then begin
                        RecRef.Field(50101).Value(CopyStr(MultiLoadNo, 1, RecRef.Field(50101).Length()));
                        RecRef.Modify(false);
                    end else if GLEntry.Amount = Amount then begin
                        RecRef.Field(GLEntry.FieldNo("BA Multi-Load No.")).Value(CopyStr(MultiLoadNo, 1, MaxStrLen(GLEntry."BA Multi-Load No.")));
                        RecRef.Modify(false);
                    end;
                    Clear(LoadNos);
                end;
            until RecRef.Next() = 0;
        Commit();
    end;
}