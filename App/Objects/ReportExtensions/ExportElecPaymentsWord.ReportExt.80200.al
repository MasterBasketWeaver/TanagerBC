reportextension 80200 "BA ExportElecPayments - Word" extends "ExportElecPayments - Word"
{
    dataset
    {
        add(CopyLoop)
        {
            column(BA_EntityAddr1; EntityAddr[1])
            {
            }
            column(BA_EntityAddr2; EntityAddr[2])
            {
            }
            column(BA_EntityAddr3; EntityAddr[3])
            {
            }
            column(BA_EntityAddr4; EntityAddr[4])
            {
            }
            column(BA_EntityAddr5; EntityAddr[5])
            {
            }
            column(BA_EntityAddr6; EntityAddr[6])
            {
            }
            column(BA_EntityPicture; DimensionValue.BssiPicture)
            {
            }
            column(BA_PurchLoadNo; PurchLoadNo)
            {
            }
            column(BA_EmailAddr; EmailAddr)
            {
            }
            column(BA_DocNo; DocNo) { }
            column(BA_RecBankAccName; RecBankAccName) { }
            column(BA_RecBankAccNo; RecBankAccNo) { }
            column(BA_RecBankTransitNo; RecBankTransitNo) { }
        }

        add("Vendor Ledger Entry")
        {
            column(BA_Vendor_Ledger_Entry_PurchLoadNo; PurchLoadNo2)
            {
            }
            column(BA_BuyFromAddr1; BuyFromAddr[1])
            {
            }
            column(BA_BuyFromAddr2; BuyFromAddr[2])
            {
            }
            column(BA_BuyFromAddr3; BuyFromAddr[3])
            {
            }
            column(BA_BuyFromAddr4; BuyFromAddr[4])
            {
            }
            column(BA_BuyFromAddr5; BuyFromAddr[5])
            {
            }
            column(BA_BuyFromAddr6; BuyFromAddr[6])
            {
            }
            column(BA_BuyFromAddr7; BuyFromAddr[7])
            {
            }
            column(BA_BuyFromAddr8; BuyFromAddr[8])
            {
            }
            column("BA_VendorLedgerEntry_DocumentNo"; "Document No.") { }
            column("BA_VendorLedgerEntry_LoadNo"; LoadNo) { }
        }
        modify("Vendor Ledger Entry")
        {
            trigger OnAfterAfterGetRecord()
            var
                PurchInvHeader: Record "Purch. Inv. Header";
                RecRef: RecordRef;
            begin
                LoadNo := '';
                Clear(BuyFromAddr);
                RecRef.GetTable("Vendor Ledger Entry");
                if RecRef.FieldExist(70202) then
                    LoadNo := Format(RecRef.Field(70202).Value());

                if ("Vendor Ledger Entry"."Document Type" = "Vendor Ledger Entry"."Document Type"::"Invoice") and PurchInvHeader.Get("Vendor Ledger Entry"."Document No.") then
                    FormatAddress.PurchInvBuyFrom(BuyFromAddr, PurchInvHeader);
            end;
        }

        modify("Gen. Journal Line")
        {
            trigger OnAfterAfterGetRecord()
            var
                GLSetup: Record "General Ledger Setup";
                PurchInvHeader: Record "Purch. Inv. Header";
                Vendor: Record Vendor;
                CustRepSelection: Record "Custom Report Selection";
                BankAccount2: Record "Bank Account";
            begin
                DocNo := '';
                PurchLoadNo := '';
                EmailAddr := '';
                GLSetup.Get();
                if DimensionValue.Get(GLSetup."Global Dimension 1 Code", "Gen. Journal Line"."Shortcut Dimension 1 Code") then begin
                    EntityAddr[1] := DimensionValue.Name;
                    EntityAddr[2] := DimensionValue.BssiBillingAddr1;
                    EntityAddr[3] := DimensionValue.BssiBillingAddress2;
                    EntityAddr[4] := DimensionValue.BssiBillingCity;
                    EntityAddr[5] := DimensionValue.BssiBillingZipCode;
                    EntityAddr[6] := DimensionValue.BssiBillingCountry;
                    EntityAddr[7] := DimensionValue.BssiBillingState;
                    DimensionValue.CalcFields(BssiPicture);
                end;
                if ("Document Type" = "Document Type"::Payment) and (("Applies-to Doc. Type" = "Applies-to Doc. Type"::Invoice)) then begin
                    if ("Account Type" = "Account Type"::Vendor) then
                        if PurchInvHeader.Get("Applies-to Doc. No.") then begin
                            PurchLoadNo := PurchInvHeader."Pre-Assigned No.";
                            DocNo := PurchInvHeader."No.";
                        end;
                end;
                if ("Account Type" = "Account Type"::Vendor) and (Vendor.Get("Account No.")) then begin
                    CustRepSelection.SetRange("Source Type", Database::Vendor);
                    CustRepSelection.SetRange("Source No.", Vendor."No.");
                    CustRepSelection.SetRange(Usage, CustRepSelection.Usage::"V.Remittance");
                    CustRepSelection.SetFilter("Send To Email", '<>%1', '');
                    if CustRepSelection.FindFirst() then
                        EmailAddr := CustRepSelection."Send To Email";
                end;

                if ("Gen. Journal Line"."Bal. Account Type" = "Gen. Journal Line"."Bal. Account Type"::"Bank Account") and BankAccount2.Get("Gen. Journal Line"."Bal. Account No.") then begin
                    RecBankAccName := BankAccount2.Name;
                    RecBankAccNo := BankAccount2."Bank Account No.";
                    RecBankTransitNo := BankAccount2."Transit No.";
                end else begin
                    RecBankAccName := '';
                    RecBankAccNo := '';
                    RecBankTransitNo := '';
                end;
            end;
        }

    }


    Rendering
    {
        layout("Tanager ACH Remittance")
        {
            Type = RDLC;
            LayoutFile = './Objects/Layouts/ExportElectronicPaymentsWord.rdl';
            Caption = 'Tanager ACH Remittance';
        }
    }

    var

        DimensionValue: Record "Dimension Value";
        FormatAddress: Codeunit "Format Address";
        EntityAddr, BuyFromAddr : array[8] of Text[100];
        LoadNo, DocNo, RecBankAccName, RecBankAccNo, RecBankTransitNo : Text;
        EmailAddr: Text[100];
        PurchLoadNo: Code[20];
        PurchLoadNo2: Code[20];













}