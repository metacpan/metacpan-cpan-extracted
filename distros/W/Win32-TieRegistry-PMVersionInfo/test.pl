# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Win32::TieRegistry::PMVersionInfo;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
exit;
__END__

use lib "../..";
use Win32::TieRegistry::PMVersionInfo;

my $reg = new Win32::TieRegistry::PMVersionInfo (
	file_root	=> "D:/src/pl/spc2xml/version5/",
	ignore_dirs => ["Commercial/bin/",
					"Commercial/SPC/XSLT/SourceForge",
					"Commercial/SPC/XSLT/CSS",
					"Commercial/SPC/XSLT/imgs",
					],
	reg_root	=> 'LMachine/Software/LittleBits/',
	strip_path	=> $strip_path,
	chat=>1,
);
# $reg->get_from_MANIFEST('D:/src/pl/spc2xml/Version5/MANIFEST','D:/src/pl/spc2xml/Version5/MANIFEST.SKIP');
$reg->get;
$reg->store;
