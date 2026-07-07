// pageextension 80201 "BA Purchase Invoice" extends "Purchase Invoice"
// {
//     layout
//     {
//         addafter("Vendor Invoice No.")
//         {
//             field("BA Load No."; LoadNo)
//             {
//                 ApplicationArea = All;
//                 Caption = 'Load No.';
//                 ToolTip = 'Specifies the load number for this purchase invoice.';
//                 Enabled = ShowLoadNo;
//                 Editable = IsEditable;

//                 trigger onValidate()
//                 var
//                     RecRef: RecordRef;
//                 begin
//                     RecRef.GetTable(Rec);
//                     RecRef.Field(70200).Validate(LoadNo);
//                     RecRef.SetTable(Rec);
//                 end;
//             }
//         }
//     }

//     trigger OnAfterGetCurrRecord()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.GetTable(Rec);
//         if RecRef.FieldExist(70200) then begin
//             LoadNo := RecRef.Field(70200).Value();
//             ShowLoadNo := true;
//         end else
//             ShowLoadNo := false;
//         IsEditable := CurrPage.Editable();
//     end;


//     var
//         LoadNo: Code[20];
//         ShowLoadNo, IsEditable : Boolean;
// }