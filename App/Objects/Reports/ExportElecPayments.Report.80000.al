report 80000 "BA Export Elec Payments"
{
    Caption = 'Export Electronic Payments';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './Objects/Layouts/ExportElectronicPayments.rdl';

    dataset
    {
        dataitem(GenJnlLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.")
                where("Bank Payment Type" = filter("Electronic Payment" | "Electronic Payment-IAT"),
                    "Document Type" = filter(Payment | Refund),
                    "Account Type" = filter(Vendor),
                    "Bal. Account Type" = filter("Bank Account"),
                    "Check Printed" = const(false));
            RequestFilterFields = "Journal Template Name", "Journal Batch Name";

            column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(Gen__Journal_Line_Line_No_; "Line No.")
            {
            }
            column(Gen__Journal_Line_Applies_to_ID; "Applies-to ID")
            {
            }
            column(GenJnlLine_AccountNo; "Account No.") { }


            trigger OnPreDataItem()
            var
                GLSetup: Record "General Ledger Setup";
                DimValue: Record "Dimension Value";
            begin
                if not GenJnlLine.FindFirst() then
                    Error(NoRecordsErr, GenJnlLine.GetFilters());

                GLSetup.Get();
                if DimValue.Get(GLSetup."Global Dimension 1 Code", GenJnlLine."Shortcut Dimension 1 Code") then begin
                    EntityAddr[1] := DimValue.Name;
                    EntityAddr[2] := DimValue.BssiBillingAddr1;
                    EntityAddr[3] := DimValue.BssiBillingAddress2;
                    EntityAddr[4] := DimValue.BssiBillingCity;
                    EntityAddr[5] := DimValue.BssiBillingZipCode;
                    EntityAddr[6] := DimValue.BssiBillingCountry;
                    EntityAddr[7] := DimValue.BssiBillingState;
                end;
            end;


            trigger OnAfterGetRecord()
            var
                PurchInvHeader: Record "Purch. Inv. Header";
                Vendor: Record Vendor;
                VendorBankAccount: Record "Vendor Bank Account";
                VendorLedgerEntry: Record "Vendor Ledger Entry";
                CustRepSelection: Record "Custom Report Selection";
                Values: Dictionary of [Integer, List of [Text]];
                LineValues, Temp : List of [Text];
                EmailAddr, BankAccountNo, BankTransitNo, BankName : Text;
                AppliedAmount: Decimal;
                i: Integer;
            begin
                for i := 1 to 7 do
                    LineValues.Add('');

                if ("Document Type" = "Document Type"::Payment) then
                    if "Applies-to ID" <> '' then begin
                        i := 0;
                        VendorLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                        VendorLedgerEntry.SetRange("Vendor No.", "Account No.");
                        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
                        if VendorLedgerEntry.FindSet() then
                            Repeat
                                //required because LineValues.Set() adds as var, whereas LineValues.Add() adds as value and doesn't override previous values (so stupid)
                                Clear(LineValues);
                                if PurchInvHeader.Get(VendorLedgerEntry."Document No.") then begin
                                    PurchInvHeader.CalcFields("Remaining Amount");
                                    LineValues.Add(PurchInvHeader."Pre-Assigned No.");
                                    LineValues.Add(PurchInvHeader."No.");
                                end else begin
                                    LineValues.Add('');
                                    LineValues.Add(VendorLedgerEntry."Document No.");
                                end;
                                LineValues.Add(VendorLedgerEntry."Buy-from Vendor No.");
                                if Vendor.Get(VendorLedgerEntry."Buy-from Vendor No.") then
                                    LineValues.Add(Vendor.Name)
                                else if Vendor.Get("Account No.") then
                                    LineValues.Add(Vendor.Name)
                                else
                                    LineValues.Add('');
                                LineValues.Add(Format(Round(Abs(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Amount to Apply"), 0.01)));
                                LineValues.Add(Format(Round(-VendorLedgerEntry."Amount to Apply", 0.01)));
                                LineValues.Add(Format(VendorLedgerEntry."Posting Date", 0, '<Month Text> <Day>, <Year4>'));
                                if VendorLineValues.ContainsKey(GenJnlLine."Account No.") then begin
                                    VendorLineValues.Get(GenJnlLine."Account No.", Values);
                                    Values.Add(GenJnlLine."Line No." + i, LineValues);
                                    VendorLineValues.Set(GenJnlLine."Account No.", Values);
                                end else begin
                                    Values.Add(GenJnlLine."Line No." + i, LineValues);
                                    VendorLineValues.Add(GenJnlLine."Account No.", Values);
                                end;
                                i += 1;
                                AppliedAmount -= VendorLedgerEntry."Amount to Apply";
                            until VendorLedgerEntry.Next() = 0;

                        if PaidAmounts.ContainsKey(GenJnlLine."Account No.") then
                            PaidAmounts.Set(GenJnlLine."Account No.", PaidAmounts.Get(GenJnlLine."Account No.") + AppliedAmount)
                        else
                            PaidAmounts.Add(GenJnlLine."Account No.", AppliedAmount);
                    end else
                        if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice) and ("Applies-to Doc. No." <> '') then begin
                            if PurchInvHeader.Get("Applies-to Doc. No.") then begin
                                PurchInvHeader.CalcFields("Remaining Amount");
                                LineValues.Set(1, PurchInvHeader."Pre-Assigned No.");
                                LineValues.Set(2, PurchInvHeader."No.");
                                LineValues.Set(3, PurchInvHeader."Buy-from Vendor No.");
                                LineValues.Set(4, PurchInvHeader."Buy-from Vendor Name");
                                LineValues.Set(5, Format(Round(PurchInvHeader."Remaining Amount" - GenJnlLine.Amount, 0.01)));
                                LineValues.Set(6, Format(Round(GenJnlLine.Amount, 0.01)));
                                LineValues.Set(7, Format(PurchInvHeader."Posting Date", 0, '<Month Text> <Day>, <Year4>'));

                                if VendorLineValues.ContainsKey(GenJnlLine."Account No.") then begin
                                    VendorLineValues.Get(GenJnlLine."Account No.", Values);
                                    Values.Add(GenJnlLine."Line No.", LineValues);
                                    VendorLineValues.Set(GenJnlLine."Account No.", Values);
                                end else begin
                                    Values.Add(GenJnlLine."Line No.", LineValues);
                                    VendorLineValues.Add(GenJnlLine."Account No.", Values);
                                end;
                            end;
                            if PaidAmounts.ContainsKey(GenJnlLine."Account No.") then
                                PaidAmounts.Set(GenJnlLine."Account No.", PaidAmounts.Get(GenJnlLine."Account No.") + GenJnlLine.Amount)
                            else
                                PaidAmounts.Add(GenJnlLine."Account No.", GenJnlLine.Amount);
                        end;

                if not VendorHeaderValues.ContainsKey(GenJnlLine."Account No.") then begin
                    if Vendor.Get("Account No.") then begin
                        CustRepSelection.SetRange("Source Type", Database::Vendor);
                        CustRepSelection.SetRange("Source No.", Vendor."No.");
                        CustRepSelection.SetRange(Usage, CustRepSelection.Usage::"V.Remittance");
                        CustRepSelection.SetFilter("Send To Email", '<>%1', '');
                        if CustRepSelection.FindFirst() then
                            EmailAddr := CustRepSelection."Send To Email"
                        else
                            EmailAddr := Vendor."E-Mail";
                        if VendorBankAccount.Get(Vendor."No.", GenJnlLine."Recipient Bank Account") then begin
                            BankName := VendorBankAccount.Name;
                            BankAccountNo := VendorBankAccount."Bank Account No.";
                            BankTransitNo := VendorBankAccount."Transit No.";
                        end;
                    end;

                    Clear(LineValues);
                    LineValues.Add(EmailAddr);
                    LineValues.Add(BankName);
                    LineValues.Add(BankAccountNo);
                    LineValues.Add(BankTransitNo);
                    LineValues.Add(Vendor.Name);
                    LineValues.Add(Format(GenJnlLine."Document Date", 0, '<Month Text> <Day>, <Year4>'));
                    VendorHeaderValues.Add(GenJnlLine."Account No.", LineValues);
                end;


            end;
        }
        dataitem(VendorLine; Integer)
        {
            dataitem(Line; Integer)
            {
                column(Line_LineNo; Number) { }
                column(Line_LoadNo; GetLineValue(VendorLine.Number, Line.Number, 1)) { }
                column(Line_DocNo; GetLineValue(VendorLine.Number, Line.Number, 2)) { }
                column(Line_VendorNo; GetLineValue(VendorLine.Number, Line.Number, 3)) { }
                column(Line_VendorName; GetLineValue(VendorLine.Number, Line.Number, 4)) { }
                column(Line_RemainingAmt; GetLineValue(VendorLine.Number, Line.Number, 5)) { }
                column(Line_Amount; GetLineValue(VendorLine.Number, Line.Number, 6)) { }
                column(Line_DocDate; GetLineValue(VendorLine.Number, Line.Number, 7)) { }

                trigger OnPreDataItem()
                begin
                    Line.SetRange(Number, 1, VendorLineValues.Get(VendorLineValues.Keys.Get(VendorLine.Number)).Count());
                end;
            }
            column(EntityAddr1; EntityAddr[1]) { }
            column(EntityAddr2; EntityAddr[2]) { }
            column(EntityAddr3; EntityAddr[3]) { }
            column(EntityAddr4; EntityAddr[4]) { }
            column(EntityAddr5; EntityAddr[5]) { }
            column(EntityAddr6; EntityAddr[6]) { }
            column(VendorLine_LineNo; Number) { }
            column(VendorLine_VendorNo; VendorLineValues.Keys.Get(VendorLine.Number)) { }
            column(VendorLine_EmailAddr; GetHeaderValue(VendorLine.Number, 1)) { }
            column(VendorLine_BankName; GetHeaderValue(VendorLine.Number, 2)) { }
            column(VendorLine_BankAccNo; GetHeaderValue(VendorLine.Number, 3)) { }
            column(VendorLine_BankTransitNo; GetHeaderValue(VendorLine.Number, 4)) { }
            column(VendorLine_VendorName; GetHeaderValue(VendorLine.Number, 5)) { }
            column(VendorLine_PaymentDate; GetHeaderValue(VendorLine.Number, 6)) { }
            column(VendorLine_TotalPaidAmount; PaidAmounts.Get(VendorLineValues.Keys.Get(VendorLine.Number))) { }

            trigger OnPreDataItem()
            begin
                VendorLine.SetRange(Number, 1, VendorLineValues.Count());
            end;
        }
    }
    requestpage
    {
        Caption = 'Export Electronic Payments';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(BankAccountNo; BankAccount."No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the payment is transmitted to.';
                    }
                    group(OutputOptions)
                    {
                        Caption = 'Output Options';

                        field(OutputMethod; SupportedOutputMethod)
                        {
                            ApplicationArea = All;
                            Caption = 'Output Method';
                            OptionCaption = 'Print,Preview,PDF,Email,Word,XML - RDLC layouts only', Comment = 'Verbs - to print, to preview, to export to PDF, to email, to export to word, to export to XML (with note that it''s for RDLC layouts only)';
                            ToolTip = 'Specifies how the electronic payment is exported.';

                            trigger OnValidate()
                            begin
                                MapOutputMethod();
                            end;
                        }
                        // required for reportrequest codeuntit to determine the output method for the report
                        // if removed will cause runtime error
                        field(ChosenOutputMethod; ChosenOutputMethod)
                        {
                            Visible = false;
                            ApplicationArea = All;
                        }
                    }

                    group(EmailOptions)
                    {
                        Caption = 'Email Options';
                        Visible = ShowPrintIfEmailIsMissing;

                        field(PrintMissingAddresses; PrintIfEmailIsMissing)
                        {
                            ApplicationArea = All;
                            Caption = 'Print remaining statements';
                            ToolTip = 'Specifies that amounts remaining to be paid will be included.';
                        }
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            BankAccountNo: Code[20];
            JournalTemplateName, JournalBatchName : Code[10];
        begin
            MapOutputMethod();
            SingleInstance.GetGenJnlBatchDetails(JournalTemplateName, JournalBatchName, BankAccountNo);
            if JournalTemplateName <> '' then
                GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
            if JournalBatchName <> '' then
                GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);
            if BankAccountNo <> '' then
                BankAccount.Get(BankAccountNo);
        end;
    }


    trigger OnPreReport()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Copy(GenJnlLine);
        if GenJournalLine.FindFirst() then begin
            GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
            // if not GenJournalTemplate."Force Doc. Balance" then
            // if not Confirm(CannotVoidQst, true) then
            //     Error(UserCancelledErr);
            if not UseRequestPage() then
                if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
                    GenJournalBatch.TestField("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
                    GenJournalBatch.TestField(GenJournalBatch."Bal. Account No.");
                    BankAccount."No." := GenJournalBatch."Bal. Account No.";
                end;
            BankAccount.Get(BankAccount."No.");
            BankAccount.TestField(Blocked, false);
            BankAccount.TestField("Export Format");
            BankAccount.TestField("Last Remittance Advice No.");
        end;
    end;





    local procedure MapOutputMethod()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        ShowPrintIfEmailIsMissing := (SupportedOutputMethod = SupportedOutputMethod::Email);
        // Map the supported option (shown on the page) to the list of supported output methods
        case SupportedOutputMethod of
            SupportedOutputMethod::Print:
                ChosenOutputMethod := CustomLayoutReporting.GetPrintOption();
            SupportedOutputMethod::Preview:
                ChosenOutputMethod := CustomLayoutReporting.GetPreviewOption();
            SupportedOutputMethod::PDF:
                ChosenOutputMethod := CustomLayoutReporting.GetPDFOption();
            SupportedOutputMethod::Email:
                ChosenOutputMethod := CustomLayoutReporting.GetEmailOption();
            SupportedOutputMethod::Word:
                ChosenOutputMethod := CustomLayoutReporting.GetWordOption();
            SupportedOutputMethod::XML:
                ChosenOutputMethod := CustomLayoutReporting.GetXMLOption();
        end;
    end;

    local procedure GetLineValue(HeaderNumber: Integer; LineNumber: Integer; Index: Integer): Text
    var
        VendorNo: Code[20];
        ValuesDict: Dictionary of [Integer, List of [Text]];
        Values: List of [Text];
        Value: Text;
        LineNo: Integer;
    begin
        if not VendorLineValues.Keys.Get(HeaderNumber, VendorNo) then
            exit('');
        if not VendorLineValues.Get(VendorNo, ValuesDict) then
            exit('');
        if ValuesDict.Count() = 0 then
            exit('');
        if not ValuesDict.Keys.Get(LineNumber, LineNo) then
            exit('');
        if not ValuesDict.Get(LineNo, Values) then
            exit('');
        if not Values.Get(Index, Value) then
            exit('');
        exit(Value);
    end;



    local procedure GetHeaderValue(HeaderNumber: Integer; Index: Integer): Text
    var
        VendorNo: Code[20];
        Values: List of [Text];
        Value: Text;
    begin
        if not VendorLineValues.Keys.Get(HeaderNumber, VendorNo) then
            exit('');
        if not VendorHeaderValues.Get(VendorNo, Values) then
            exit('');
        if not Values.Get(Index, Value) then
            exit('');
        exit(Value);
    end;


    protected var
        BankAccount: Record "Bank Account";
        SingleInstance: Codeunit "BA Single Instance";
        EntityAddr: array[8] of Text[100];
        PaidAmounts: Dictionary of [Code[20], Decimal];
        VendorHeaderValues: Dictionary of [Code[20], List of [Text]];
        VendorLineValues: Dictionary of [Code[20], Dictionary of [Integer, List of [Text]]];
        ChosenOutputMethod, NoCopies : Integer;
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Word,XML;
        PrintIfEmailIsMissing, ShowPrintIfEmailIsMissing : Boolean;

        NoRecordsErr: Label 'No records found for the selected filters:\%1', Comment = '%1 = GenJnlLine filters';

}
