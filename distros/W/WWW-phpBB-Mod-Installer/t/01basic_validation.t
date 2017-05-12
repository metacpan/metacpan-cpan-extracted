use Test::More tests => 4;
use WWW::phpBB::Mod::Installer;
use File::Copy;
use File::Path;

sub delete_last_run{
    if (-d 't/web_root'){
        rmtree('t/web_root');
    }
    if (-d 't/logs'){
        rmtree('t/logs');
    }
    if (-d 't/backups'){
        rmtree('t/backups');
    }
}


delete_last_run();


mkdir 't/web_root';
copy ('t/orig_web_root/config.php', 't/web_root/config.php');


eval {install_phpbb_mod(
                  INSTALL_FILE => 'not_exist.xml', 
                  WEB_ROOT     => '', 
                  STYLE        => '',
                  LANG         => '',
                  OPERATION    => 'INSTALL',
                  ); };
like ($@, qr/The install file 'not_exist.xml' does not exist/, 'install file does not exist');

eval {install_phpbb_mod(
                  INSTALL_FILE => 't/mod/install.xml', 
                  WEB_ROOT     => 'not_exist', 
                  STYLE        => '',
                  LANG         => '',
                  OPERATION    => 'INSTALL',
                  ); };
like ($@, qr/The phpbb web root directory 'not_exist' does not exist/, 'web root does not exist');

eval {install_phpbb_mod(
                  INSTALL_FILE => 't/mod/install.xml', 
                  WEB_ROOT     => 't/mod', 
                  STYLE        => '',
                  LANG         => '',
                  OPERATION    => 'INSTALL',
                  ); };
like ($@, qr/The phpbb web root directory '.+\/t\/mod' does not contain a config\.php/, 'web root has no config');

eval {install_phpbb_mod(
                  INSTALL_FILE => 't/mod/install.xml', 
                  WEB_ROOT     => 't/web_root', 
                  STYLE        => '',
                  LANG         => '',
                  OPERATION    => 'UNSUPPORTED',
                  ); };
like ($@, qr/Unsupported operation 'UNSUPPORTED'/, 'unsupported operation');


