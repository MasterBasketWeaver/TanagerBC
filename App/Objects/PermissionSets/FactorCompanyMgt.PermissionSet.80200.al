permissionset 80200 "BA Factor Comp. Mgt."
{
    Assignable = true;
    Caption = 'Factor Company Mgt. Permissions';
    Permissions = report "BA Export Elec Payments" = X,
        codeunit "BA Factor Company Remit. Mgt." = X,
        codeunit "BA Single Instance" = X,
        codeunit "BA Install" = X,
        codeunit "BA Populate Entry Load Nos." = X,
        codeunit "BA Upgrade" = X;
}