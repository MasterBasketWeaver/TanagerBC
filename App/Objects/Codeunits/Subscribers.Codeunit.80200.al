codeunit 80200 "BA Subscribers"
{
    permissions = tabledata "Gen. Journal Line" = R,
        tabledata "Vendor Ledger Entry" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Purch. Inv. Header" = R,
        tabledata "Purch. Cr. Memo Hdr." = R,
        tabledata "Sales Invoice Header" = R,
        tabledata "Sales Cr.Memo Header" = R,
        tabledata "G/L Entry" = RM;



    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", "OnBeforeActionEvent", "ExportPaymentsToFile", true, true)]
    local procedure PaymentJournalOnBeforeExportPaymentsToFile(var Rec: Record "Gen. Journal Line")
    begin
        SingleInstance.SetGenJnlBatchDetails(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", "OnAfterActionEvent", "ExportPaymentsToFile", true, true)]
    local procedure PaymentJournalOnAfterExportPaymentsToFile(var Rec: Record "Gen. Journal Line")
    begin
        SingleInstance.ClearGenJnlBatchDetails();
    end;



    // [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", "OnAfterInsertEvent", '', true, true)]
    // local procedure VendorLedgerEntryOnAfterInsert(var Rec: Record "Vendor Ledger Entry")
    // var
    //     PurchInvHeader: Record "Purch. Inv. Header";
    //     PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    //     VendorLedgerEntry: Record "Vendor Ledger Entry";
    //     RecRef: RecordRef;
    //     FldRef: FieldRef;
    // begin
    //     RecRef.GetTable(Rec);
    //     if not RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
    //         exit;

    //     FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
    //     PurchInvHeader.SetRange("Vendor Ledger Entry No.", Rec."Entry No.");


    //     if not Confirm('%1 -> %2', false, PurchInvHeader.GetFilters(), PurchInvHeader.Count()) then
    //         Error('');


    //     PurchInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');

    //     if not Confirm('%1 -> %2', false, PurchInvHeader.GetFilters(), PurchInvHeader.Count()) then
    //         Error('');

    //     if PurchInvHeader.FindFirst() then begin
    //         if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
    //             FldRef.Value(PurchInvHeader."Pre-Assigned No.");
    //             RecRef.Modify(false);
    //             RecRef.Close();
    //         end;
    //         CopyVendorLoadNoToGLEntry(Rec, PurchInvHeader."Pre-Assigned No.");
    //         if VendorLedgerEntry.Get(Rec."Closed by Entry No.") then begin
    //             RecRef.GetTable(VendorLedgerEntry);
    //             FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
    //             if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
    //                 FldRef.Value(PurchInvHeader."Pre-Assigned No.");
    //                 RecRef.Modify(false);
    //             end;
    //             CopyVendorLoadNoToGLEntry(VendorLedgerEntry, PurchInvHeader."Pre-Assigned No.");
    //         end;
    //         exit;
    //     end;

    //     PurchInvHeader.SetRange("Vendor Ledger Entry No.", Rec."Closed by Entry No.");
    //     if PurchInvHeader.FindFirst() then begin
    //         if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
    //             FldRef.Value(PurchInvHeader."Pre-Assigned No.");
    //             RecRef.Modify(false);
    //             RecRef.Close();
    //         end;
    //         CopyVendorLoadNoToGLEntry(Rec, PurchInvHeader."Pre-Assigned No.");
    //         if VendorLedgerEntry.Get(Rec."Closed by Entry No.") then begin
    //             RecRef.GetTable(VendorLedgerEntry);
    //             FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
    //             if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
    //                 FldRef.Value(PurchInvHeader."Pre-Assigned No.");
    //                 RecRef.Modify(false);
    //             end;
    //             CopyVendorLoadNoToGLEntry(VendorLedgerEntry, PurchInvHeader."Pre-Assigned No.");
    //         end;
    //     end;
    // end;




    // [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", "OnAfterInsertEvent", '', true, true)]
    // local procedure CustomerLedgerEntryOnAfterInsert(var Rec: Record "Cust. Ledger Entry")
    // var
    //     SalesInvHeader: Record "Sales Invoice Header";
    //     SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    //     CustomerLedgerEntry: Record "Cust. Ledger Entry";
    //     RecRef: RecordRef;
    //     FldRef: FieldRef;
    // begin
    //     RecRef.GetTable(Rec);
    //     if not RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
    //         exit;

    //     FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
    //     SalesInvHeader.SetRange("Cust. Ledger Entry No.", Rec."Entry No.");
    //     SalesInvHeader.SetFilter("Pre-Assigned No.", '<>%1', '');
    //     if SalesInvHeader.FindFirst() then begin
    //         if Format(FldRef.Value()) <> SalesInvHeader."Pre-Assigned No." then begin
    //             FldRef.Value(SalesInvHeader."Pre-Assigned No.");
    //             RecRef.Modify(false);
    //             RecRef.Close();
    //         end;
    //         CopyCustomerLoadNoToGLEntry(Rec, SalesInvHeader."Pre-Assigned No.");
    //         if CustomerLedgerEntry.Get(Rec."Closed by Entry No.") then begin
    //             RecRef.GetTable(CustomerLedgerEntry);
    //             FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
    //             if Format(FldRef.Value()) <> SalesInvHeader."Pre-Assigned No." then begin
    //                 FldRef.Value(SalesInvHeader."Pre-Assigned No.");
    //                 RecRef.Modify(false);
    //             end;
    //             CopyCustomerLoadNoToGLEntry(CustomerLedgerEntry, SalesInvHeader."Pre-Assigned No.");
    //         end;
    //         exit;
    //     end;

    //     SalesInvHeader.SetRange("Cust. Ledger Entry No.", Rec."Closed by Entry No.");
    //     if SalesInvHeader.FindFirst() then begin
    //         if Format(FldRef.Value()) <> SalesInvHeader."Pre-Assigned No." then begin
    //             FldRef.Value(SalesInvHeader."Pre-Assigned No.");
    //             RecRef.Modify(false);
    //             RecRef.Close();
    //         end;
    //         CopyCustomerLoadNoToGLEntry(Rec, SalesInvHeader."Pre-Assigned No.");
    //         if CustomerLedgerEntry.Get(Rec."Closed by Entry No.") then begin
    //             RecRef.GetTable(CustomerLedgerEntry);
    //             FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
    //             if Format(FldRef.Value()) <> SalesInvHeader."Pre-Assigned No." then begin
    //                 FldRef.Value(SalesInvHeader."Pre-Assigned No.");
    //                 RecRef.Modify(false);
    //             end;
    //             CopyCustomerLoadNoToGLEntry(CustomerLedgerEntry, SalesInvHeader."Pre-Assigned No.");
    //         end;
    //     end;
    // end;









    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", "OnAfterUpdatePurchaseHeader", '', true, true)]
    local procedure PurchPostOnAfterUpdatePurchaseHeader(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(VendorLedgerEntry);
        if not RecRef.FieldExist(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()) then
            exit;

        if (PurchInvHeader."No." <> '') and (PurchInvHeader."Pre-Assigned No." <> '') then begin
            RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo()).Value(PurchInvHeader."Pre-Assigned No.");
            RecRef.Modify(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", "OnRunOnBeforeFinalizePosting", '', true, true)]
    local procedure PurchPostOnRunOnBeforeFinalizePosting(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if (PurchInvHeader."No." <> '') and (PurchInvHeader."Pre-Assigned No." <> '') and VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.") then begin
            RecRef.GetTable(VendorLedgerEntry);
            FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
                FldRef.Value(PurchInvHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
            CopyVendorLoadNoToGLEntry(VendorLedgerEntry, PurchInvHeader."Pre-Assigned No.");
            if VendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(VendorLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.VendorLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> PurchInvHeader."Pre-Assigned No." then begin
                    FldRef.Value(PurchInvHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                end;
                CopyVendorLoadNoToGLEntry(VendorLedgerEntry, PurchInvHeader."Pre-Assigned No.");
            end;
        end;
    end;















    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", "OnAfterUpdateSalesHeader", '', true, true)]
    local procedure SalesPostOnAfterUpdateSalesHeader(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(CustLedgerEntry);
        if not RecRef.FieldExist(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()) then
            exit;

        if (SalesInvoiceHeader."No." <> '') and (SalesInvoiceHeader."Pre-Assigned No." <> '') then begin
            RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo()).Value(SalesInvoiceHeader."Pre-Assigned No.");
            RecRef.Modify(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", "OnRunOnBeforeFinalizePosting", '', true, true)]
    local procedure SalesPostOnRunOnBeforeFinalizePosting(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        if (SalesInvoiceHeader."No." <> '') and (SalesInvoiceHeader."Pre-Assigned No." <> '') and CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.") then begin
            RecRef.GetTable(CustLedgerEntry);
            FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
            if Format(FldRef.Value()) <> SalesInvoiceHeader."Pre-Assigned No." then begin
                FldRef.Value(SalesInvoiceHeader."Pre-Assigned No.");
                RecRef.Modify(false);
                RecRef.Close();
            end;
            CopyCustomerLoadNoToGLEntry(CustLedgerEntry, SalesInvoiceHeader."Pre-Assigned No.");
            if CustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.") then begin
                RecRef.GetTable(CustLedgerEntry);
                FldRef := RecRef.Field(PopulateEntryLoadNos.CustomerLedgerEntryLoadNoFieldNo());
                if Format(FldRef.Value()) <> SalesInvoiceHeader."Pre-Assigned No." then begin
                    FldRef.Value(SalesInvoiceHeader."Pre-Assigned No.");
                    RecRef.Modify(false);
                end;
                CopyCustomerLoadNoToGLEntry(CustLedgerEntry, SalesInvoiceHeader."Pre-Assigned No.");
            end;
        end;
    end;












    local procedure CopyVendorLoadNoToGLEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; LoadNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetRange('');
        RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        GLEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
        GLEntry.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
        GLEntry.SetFilter(Amount, '%1|%2', VendorLedgerEntry.Amount, -VendorLedgerEntry.Amount);
        GLEntry.SetRange("Source No.", VendorLedgerEntry."Vendor No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            until GLEntry.Next() = 0;

        GLEntry.SetRange("Source No.");
        GLEntry.SetRange("Source Type");
        GLEntry.SetRange("Bal. Account No.", VendorLedgerEntry."Vendor No.");
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::Vendor);
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            until GLEntry.Next() = 0;
    end;

    local procedure CopyCustomerLoadNoToGLEntry(var CustomerLedgerEntry: Record "Cust. Ledger Entry"; LoadNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"G/L Entry");
        RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).SetRange('');
        RecRef.SetLoadFields(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo(), GLEntry.FieldNo("Transaction No."), GLEntry.FieldNo("Source No."), GLEntry.FieldNo("Amount"), GLEntry.FieldNo("Source Type"), GLEntry.FieldNo("Posting Date"));
        RecRef.SetTable(GLEntry);
        RecRef.Close();

        GLEntry.SetRange("Transaction No.", CustomerLedgerEntry."Transaction No.");
        GLEntry.SetRange("Posting Date", CustomerLedgerEntry."Posting Date");
        GLEntry.SetFilter(Amount, '%1|%2', CustomerLedgerEntry.Amount, -CustomerLedgerEntry.Amount);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Source No.", CustomerLedgerEntry."Customer No.");
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            until GLEntry.Next() = 0;

        GLEntry.SetRange("Source Type");
        GLEntry.SetRange("Source No.");
        GLEntry.SetRange("Bal. Account Type", GLEntry."Source Type"::Customer);
        GLEntry.SetRange("Bal. Account No.", CustomerLedgerEntry."Customer No.");
        if GLEntry.FindSet() then
            repeat
                RecRef.GetTable(GLEntry);
                RecRef.Field(PopulateEntryLoadNos.GeneralLedgerEntryLoadNoFieldNo()).Value(LoadNo);
                RecRef.Modify(false);
                RecRef.Close();
            until GLEntry.Next() = 0;
    end;



    var
        SingleInstance: Codeunit "BA Single Instance";
        PopulateEntryLoadNos: Codeunit "BA Populate Entry Load Nos.";
}