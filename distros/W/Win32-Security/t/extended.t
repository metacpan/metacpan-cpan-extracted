use strict;
$^W++;
use Win32::Security::NamedObject;
use Win32::Security::Recursor;
use Data::Dumper;
use Test;

use vars qw($enabled);
BEGIN {
	$|++;
	$enabled = 0; #Change this to 1 to enable the extended tests
	plan tests => $enabled ? 7607 : 1,
}
if (!$enabled) {
	ok(1);
	exit;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1; #Repeated to avoid warnings


($ENV{USERDOMAIN} ne '' && $ENV{USERNAME} ne '') or die "$0 requires the environment variables USERDOMAIN and USERNAME.  Testing has halted.\n";

my $username = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid("$ENV{USERDOMAIN}\\$ENV{USERNAME}")); # Cleanup capitalization

my $admin = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid('S-1-5-32-544')); # 'BUILTIN\\Administrators' localization

my $guestsid = Win32::Security::SID::ConvertSidToStringSid(Win32::Security::SID::ConvertNameToSid("$ENV{USERDOMAIN}\\$ENV{USERNAME}"));
$guestsid =~ s/-\d+$/-501/;
my $guest = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid($guestsid)); # "$ENV{USERDOMAIN}\\Guest" localization

my $system = Win32::Security::SID::ConvertSidToName(Win32::Security::SID::ConvertNameToSid('S-1-5-18')); # 'NT AUTHORITY\\SYSTEM' localization


`cacls.exe` =~ /Displays or modifies access control lists/si or die "$0 requires cacls.exe to function.  Unable to find cacls.exe so testing has halted.\n";

my $script_dir;
foreach my $inc (@INC) {
	$inc =~ s/\//\\/g;

	my $testinc = $inc.'\\Win32\\Security';
	if (-e "$testinc\\PermChg.pl" && -e "$testinc\\PermDump.pl" && -e "$testinc\\PermFix.pl") {
		$script_dir = $testinc;
		last;
	}

	($testinc = $inc) =~ s/\\lib$/\\script/;
	if (-e "$testinc\\PermChg.pl" && -e "$testinc\\PermDump.pl" && -e "$testinc\\PermFix.pl") {
		$script_dir = $testinc;
		last;
	}
}
defined $script_dir or die "$0 requires access to the Perm(Chg|Dump|Fix).pl scripts.  Unable to find them in \@INC so testing has halted.\n";

my $tempdir = "$ENV{TEMP}\\Win32-Security_TestDir_$$";
-d $tempdir and die "$0 requires a temp directory for testing.  The directory '$tempdir' already exists so testing has halted.\n";
mkdir($tempdir, 0);
-d $tempdir or die "$0 requires a temp directory for testing.  Unable to create the directory '$tempdir' so testing has halted.\n";

eval {
	#First we set the permissions on $tempdir
	my $tempdir_no = Win32::Security::NamedObject->new('SE_FILE_OBJECT', $tempdir);
	$tempdir_no->dacl( $tempdir_no->dacl()->new(map {['ALLOW', 'FULL_INHERIT', 'FULL', $_]} ($admin, $system, $username)), 'PROTECTED_DACL_SECURITY_INFORMATION' );

	#Now we check the owner
	my $owner = $tempdir_no->ownerTrustee();
	ok( $owner eq $username || $owner eq $admin );

	my $dumper_output = undef;
	my $dumper = Win32::Security::Recursor::SE_FILE_OBJECT::PermDump->new({csv => 1, inherited => 1, recurse => 1},
			print => sub {
				my $self = shift;
				$dumper_output .= join('', @_);
			},
		);

	-d "$tempdir\\matrix" and die "Directory '$tempdir\\matrix' already exists.\n";
	mkdir("$tempdir\\matrix");
	-d "$tempdir\\matrix" or die "Unable to create dir '$tempdir\\matrix'.\n";

	ok( &permchg("$tempdir\\matrix", "-q -c -r -b -a=\"$admin:F\" -a=\"$system:F\" -a=\"$username:M\""), "" );

	foreach my $dir ('bar', 'bar\\bas', 'bar\\bas\\baz') {
		mkdir("$tempdir\\matrix\\$dir");
		-d "$tempdir\\matrix\\$dir" or die "Unable to create dir '$tempdir\\matrix\\$dir'.\n";
	}

	foreach my $file ('bar\\bar.txt', 'bar\\bas\\bas.txt', 'bar\\bas\\baz\\baz.txt') {
		touch("$tempdir\\matrix\\$file");
		-e "$tempdir\\matrix\\$file" or die "Unable to create '$tempdir\\matrix\\$file'.\n";
	}

	my $bar_no = Win32::Security::NamedObject::SE_FILE_OBJECT->new("$tempdir\\matrix\\bar");
	my $bas_no = Win32::Security::NamedObject::SE_FILE_OBJECT->new("$tempdir\\matrix\\bar\\bas");

	my(@guest_list);
	foreach my $user ($guest) {
		foreach my $perm (qw(FULL GENERIC_ALL MODIFY)) {
			foreach my $inherit (qw(FO CI OI FI CI|IO OI|IO FI|IO CI|NP OI|NP FI|NP CI|IO|NP OI|IO|NP FI|IO|NP)) {
				my $inherit_clean = $inherit eq 'FO' ? '' : $inherit;
				push(@guest_list, ["$user:$perm($inherit)", $bar_no->dacl()->new(['ALLOW', $inherit_clean, $perm, $user])]);
			}
		}
	}

	foreach my $bar_perm (@guest_list) {
		$bar_no->dacl($bar_perm->[1]);
		foreach my $bas_perm (@guest_list) {
			$bas_no->dacl($bas_perm->[1]);
			$dumper_output = undef;
			eval { $dumper->recurse("$tempdir\\matrix"); };
			$dumper_output .= $@;
			my $cleaned_output = join('', map {"$_\n"} grep {/^\s*(|.*[BXI])$/} split(/\n/, $dumper_output));
			ok( $dumper_output, $cleaned_output, "bar: $bar_perm->[0], bas: $bas_perm->[0]");
		}
	}

	my(@user_list);
	foreach my $user ($username, 'CREATOR OWNER') {
		foreach my $perm (qw(FULL GENERIC_ALL MODIFY)) {
			foreach my $inherit (qw(FO CI OI FI CI|IO OI|IO FI|IO CI|NP OI|NP FI|NP CI|IO|NP OI|IO|NP FI|IO|NP)) {
				my $inherit_clean = $inherit eq 'FO' ? '' : $inherit;
				push(@user_list, ["$user:$perm($inherit)", $bar_no->dacl()->new(['ALLOW', $inherit_clean, $perm, $user])]);
			}
		}
	}

	foreach my $bar_perm (@user_list) {
		$bar_no->dacl($bar_perm->[1]);
		foreach my $bas_perm (@user_list) {
			$bas_no->dacl($bas_perm->[1]);
			$dumper_output = undef;
			eval { $dumper->recurse("$tempdir\\matrix"); };
			$dumper_output .= $@;
			my $cleaned_output = join('', map {"$_\n"} grep {/^\s*(|.*[BXI])$/} split(/\n/, $dumper_output));
			ok( $dumper_output, $cleaned_output, "bar: $bar_perm->[0], bas: $bas_perm->[0]");
		}
	}

	system("rd /s /q \"$tempdir\\matrix\"");

};
my $err = $@;

system("rd /s /q \"$ENV{TEMP}\\Win32-Security_TestDir_$$\"");
-d "$ENV{TEMP}\\Win32-Security_TestDir_$$" and die "$0 used a temp directory for testing.  Unable to erase the directory '$tempdir' after testing was completed.\n";

die $err if $err ne '';





sub permchg {
	my($file, $options) = @_;

	my $echo = $options =~ /-q/ ? '' : "echo y| ";

	return `${echo}perl.exe "$script_dir\\PermChg.pl" $options "$file"`;
}

sub touch {
	my($file) = @_;

	open(TEMP, ">>$file") or return 0;
	close(TEMP);
	return 1;
}
