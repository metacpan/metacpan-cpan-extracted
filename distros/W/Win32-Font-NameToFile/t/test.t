use strict;
use vars qw($loaded $hastk);

BEGIN {
	$^W= 1;
	$| = 1;
	print "1..52\n";

	eval {
		require Tk;
		require Tk::Font;
	};
	$hastk = 1 unless $@;
}
END {print "not ok 1\n" unless $loaded;}

use Win32::Font::NameToFile qw (
	get_ttf_abs_path
	get_ttf_filename
	get_ttf_bold
	get_ttf_italic
	get_ttf_bold_italic
	get_ttf_list
	get_ttf_map
	get_ttf_matching);

my $testno = 1;
my $lasttest = 52;
$loaded = 1;

sub report_result {
	my ($result, $testmsg, $okmsg, $notokmsg) = @_;

	if ($result) {

		$okmsg = '' unless $okmsg;
		print STDOUT (($result eq 'skip') ?
			"ok $testno # skip $testmsg\n" :
			"ok $testno # $testmsg $okmsg\n");
	}
	else {
		$notokmsg = '' unless $notokmsg;
		print STDOUT
			"not ok $testno # $testmsg $notokmsg\n";
	}
	$testno++;
}

report_result(1, 'Module load', 'loaded');

unless (defined($ENV{SYSTEMROOT}) &&
	(-e "$ENV{SYSTEMROOT}\\Fonts\\Arial.ttf") &&
	(-e "$ENV{SYSTEMROOT}\\Fonts\\ArialBD.ttf") &&
	(-e "$ENV{SYSTEMROOT}\\Fonts\\ArialBI.ttf") &&
	(-e "$ENV{SYSTEMROOT}\\Fonts\\ArialI.ttf")) {
	report_result('skip', 'all tests; no font files')
		while ($testno < $lasttest);
}
#
#	test each regular, then for Tk (if available)
#	NOTE: we assume the following fonts exist:
#	arial, arial bold, arial italic, arial bold italic, arial black
#
my %fonthash = (
'Arial', 'ARIAL.TTF',
'Arial Bold', 'ARIALBD.TTF',
'Arial Bold Italic', 'ARIALBI.TTF',
'Arial Italic', 'ARIALI.TTF',
);

my ($file, $size);

foreach (keys %fonthash) {
	$file = get_ttf_abs_path($_);
	report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\$fonthash{$_}"),
		"get_ttf_abs_path($_)");

	$file = get_ttf_filename($_);
	report_result(defined($file) && ("$file.TTF" eq $fonthash{$_}),
		"get_ttf_filename($_)");

	($file, $size) = get_ttf_abs_path("$_ 12");
	report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\$fonthash{$_}") &&
		defined($size) && ($size eq 12), "get_ttf_abs_path('$_ 12')");

	($file, $size) = get_ttf_filename("$_ 12");
	report_result(defined($file) && ("$file.TTF" eq $fonthash{$_}) &&
			defined($size) && ($size eq 12), "get_ttf_filename('$_ 12')");

	$file = get_ttf_abs_path("$_ 12");
	report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\$fonthash{$_}"),
		"scalar get_ttf_abs_path('$_ 12')");

	$file = get_ttf_filename("$_ 12");
	report_result(defined($file) && ("$file.TTF" eq $fonthash{$_}),
		"scalar get_ttf_filename('$_ 12')");
}

$file = get_ttf_bold('Arial');
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALBD.TTF"),
	'get_ttf_bold()');

$file = get_ttf_italic('Arial 12');
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALI.TTF"),
	'get_ttf_italic(size)');

$file = get_ttf_bold_italic('Arial 12');
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALBI.TTF"),
	'get_ttf_bold_italic(size)');
#
#	test bad names
#
$file = get_ttf_abs_path('gooble gobble gooble gobble');
report_result((!defined($file)), 'get_ttf_abs_path(bad name)');

$file = get_ttf_filename('gooble gobble gooble gobble');
report_result((!defined($file)), 'get_ttf_filename(bad name)');

#
#	since there are some "hidden" fonts, we can only
#	verify that we got some fonts
#
my @listed = get_ttf_list();
my $count = scalar @listed;
report_result(scalar @listed, 'get_ttf_list()');

my %mapped = get_ttf_map();
my @mapped = keys %mapped;
report_result((scalar @mapped == $count) && ($mapped{'arial'} eq 'ARIAL.TTF'),
	'get_ttf_mapped()');
#
#	there may be more arials than we're using..
#
my %matched = get_ttf_matching('Arial');
my @matched = keys %matched;
report_result((scalar @matched >= 4), 'get_ttf_matching()');

unless ($hastk) {
#
#	skip all the tests w/ TK
#
	report_result('skip', 'Tk not installed')
		foreach ($testno..$lasttest);
	exit 1;
}

my %tkfonthash = (
'Arial', {-family => 'Arial', -weight => 'normal', -slant => 'roman', -size => -12},
'Arial Bold', {-family => 'Arial', -weight => 'bold', -slant => 'roman', -size => -12},
'Arial Bold Italic', {-family => 'Arial', -weight => 'bold', -slant => 'italic', -size => -12},
'Arial Italic', {-family => 'Arial', -weight => 'normal', -slant => 'italic', -size => -12},
);

my $mw = MainWindow->new();

foreach (keys %fonthash) {
	my $font = $mw->Font(%{$tkfonthash{$_}});

	$file = get_ttf_abs_path($font);
	report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\$fonthash{$_}"),
		"Tk get_ttf_abs_path($_)");

	$file = get_ttf_filename($_);
	report_result(defined($file) && ("$file.TTF" eq $fonthash{$_}),
		"Tk get_ttf_filename($_)");

	($file, $size) = get_ttf_abs_path($font);
	report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\$fonthash{$_}") &&
		defined($size) && ($size == 12), "Tk list get_ttf_abs_path()");

	($file, $size) = get_ttf_filename($font);
	report_result(defined($file) && ("$file.TTF" eq $fonthash{$_}) && defined($size) && ($size == 12),
		"Tk list get_ttf_filename()");
}

my $font = $mw->Font(%{$tkfonthash{'Arial'}});

$file = get_ttf_bold($font);
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALBD.TTF"),
	'Tk get_ttf_bold()');

$file = get_ttf_italic($font);
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALI.TTF"),
	'Tk get_ttf_italic(size)');

$file = get_ttf_bold_italic($font);
report_result(defined($file) && ($file eq "$ENV{SYSTEMROOT}\\Fonts\\ARIALBI.TTF"),
	'Tk get_ttf_bold_italic(size)');
