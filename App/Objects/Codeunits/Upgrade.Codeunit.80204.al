codeunit 80204 "BA Upgrade"
{
    Subtype = Upgrade;


    trigger OnUpgradePerCompany()
    var
        Install: Codeunit "BA Install";
    begin
        Install.InstallData();
    end;

}