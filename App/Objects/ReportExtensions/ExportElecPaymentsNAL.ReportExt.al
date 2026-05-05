reportextension 80000 "BA Export Elec Payments NAL" extends "ExportElecPayments - WordNAL"
{
    dataset
    {
        add(CopyLoop)
        {
            column(RecBankAccName; RecBankAccName) { }
            column(RecBankAccNo; RecBankAccNo) { }
            column(RecBankTransitNo; RecBankTransitNo) { }
        }

        modify("Gen. Journal Line")
        {
            trigger OnAfterAfterGetRecord()
            var
                BankAccount: Record "Bank Account";
            begin
                if ("Gen. Journal Line"."Bal. Account Type" = "Gen. Journal Line"."Bal. Account Type"::"Bank Account") and BankAccount.Get("Gen. Journal Line"."Bal. Account No.") then begin
                    RecBankAccName := BankAccount.Name;
                    RecBankAccNo := BankAccount."Bank Account No.";
                    RecBankTransitNo := BankAccount."Transit No.";
                end else begin
                    RecBankAccName := '';
                    RecBankAccNo := '';
                    RecBankTransitNo := '';
                end;
            end;
        }
    }

    rendering
    {
        layout("Custom Layout")
        {
            LayoutFile = './Objects/Layouts/ExportElectronicPayments.rdl';
            Type = RDLC;
            Caption = 'Custom Layout without carrier details';
        }
    }


    protected var
        RecBankAccName, RecBankAccNo, RecBankTransitNo : Text;
}
