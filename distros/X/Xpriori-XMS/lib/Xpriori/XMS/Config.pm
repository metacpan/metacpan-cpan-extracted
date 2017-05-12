#   Configuration file to run Xpriori::XMS
package Xpriori::XMS::Config;
our %_connect = (
    METHOD   => 'http',
    SERVER   => 'localhost',
    PORT     => '7700',
);
our %_cnf = (
    CHARSET  => 'utf-8',   # 'utf-8' or 'Shift-JIS' or 'EUC-JP' or 'ISO-2022-JP'
    LANGUAGE => 'en',      # 'en' or 'ja'
);
our %_svrCnf = (
    OSMODULE => 'Win32',   # currently : Win32 or Solaris
    PASSWORD => 'admin',
    # NEOHOME  => 'C:/NeoCore/neoxml', #Windows
    NEOHOME  => 'D:/Xpriori/neoxml', #Windows
);
1;
