use Test::More tests => 7;

BEGIN { use_ok('WWW::phpBB::Mod::Installer') };

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

#modifications made to the files, includes the line above and below
my $mod1 = <<'END_MOD1';
include($phpbb_root_path . 'common.' . $phpEx);

//-- mod : Genders ------------------------------------------------------------
//-- add
include($phpbb_root_path . 'includes/functions_genders.' . $phpEx);
//-- fin mod : Genders --------------------------------------------------------

include($phpbb_root_path . 'includes/functions_display.' . $phpEx);
END_MOD1

my $mod2 = <<'END_MOD2';
                'U_VIEW_PROFILE'    => get_username_string('profile', $row['user_id'], $row['username'], $row['user_colour']),

//-- mod : Genders ------------------------------------------------------------
//-- add
                'USER_GENDER'        => get_user_gender($row['user_gender']),
//-- fin mod : Genders --------------------------------------------------------

            ));
END_MOD2
$mod2 =~ s/    /\t/g;

my $mod3 = <<'END_MOD3';
        'S_JABBER_ENABLED'    => ($config['jab_enable']) ? true : false,

//-- mod : Genders ------------------------------------------------------------
//-- add
        'USER_GENDER_IMG'    => get_user_gender($data['user_gender']),
        'USER_GENDER'        => get_user_gender($data['user_gender'], true),
//-- fin mod : Genders --------------------------------------------------------


        'U_SEARCH_USER'    => ($auth->acl_get('u_search')) ? append_sid("{$phpbb_root_path}search.$phpEx", "author_id=$user_id&amp;sr=posts") : '',
END_MOD3
$mod3 =~ s/    /\t/g;



delete_last_run();


mkdir 't/web_root';
copy ('t/orig_web_root/config.php', 't/web_root/config.php');
copy ('t/orig_web_root/memberlist.php', 't/web_root/memberlist.php');


eval{ install_phpbb_mod(
                  INSTALL_FILE => 't/mod/install.xml', 
                  WEB_ROOT     => 't/web_root', 
                  ); };

warn "\nWARNING: $@\n\n" if $@;

#check the file copies
ok (-f 't/web_root/includes/functions_genders.php', 'file copy OK');


#check the file edits
{
    local( $/, *FH ) ;
    open( FH, '<', 't/web_root/memberlist.php' );
    my $file_text = <FH>;
    close (FH);
    
    my $find_start = index($file_text, $mod1);
    ok($find_start >=0, 'edit 1 applied');
    $find_start = index($file_text, $mod2);
    ok($find_start >=0, 'edit 2 applied');
    $find_start = index($file_text, $mod3);
    ok($find_start >=0, 'edit 3 applied');
}



#check backups
opendir(DIR, 't/backups');
while (defined($file = readdir(DIR))) {
    if ( (-d "t/backups/$file") && ( ($file ne '.') && ($file ne '..') ) ){
        ok (-f "t/backups/$file/memberlist.php", 'memberlist backed up ok');
    }
}
closedir (DIR);

#check logs
ok(-z 't/logs/error.log', 'error log empty');


delete_last_run();




