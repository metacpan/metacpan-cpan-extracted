@for /F "usebackq delims==" %%i in (`env date +%%Y-%%m-%%d--%%H-%%M`) do @set date=%%i
reg export "HKEY_CURRENT_USER\Software\Classes\Local Settings\MuiCache"           cache-16-%date%.reg
reg export "HKEY_CURRENT_USER\Software\Microsoft\Installer\Products"              products-16-%date%.reg
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout"  layout-16-%date%.reg
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layouts" layouts-16-%date%.reg

iconv -f UTF-16 -t UTF-8 layout-16-%date%.reg layouts-16-%date%.reg cache-16-%date%.reg products-16-%date%.reg > total-kbd-utf8-%date%.reg
zip -m kbd-regs-%date% *-16-%date%.reg
zip    kbd-regs-%date%  *-utf8-%date%.reg