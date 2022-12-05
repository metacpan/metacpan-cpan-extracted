#!/usr/bin/perl -w

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk;
use Tk::FileTree;
$loaded = 1;
print "ok 1\n";

if ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	print "skipping 2\n";
	print "skipping 3\n";
#	print "skipping 4\n";
#	print "skipping 5\n";
	print "..done: 1 tests completed, 2 tests skipped.\n";
	exit (0);
}

my $bummer = ($^O =~ /MSWin/) ? 1 : 0;

my $top = MainWindow->new;
print $top ? "ok 2\n" : "not ok 2 main Tk window not created?!\n";

my $tree = $top->Scrolled('FileTree',
	-scrollbars => 'osoe',
	-selectmode => 'extended',
	-width => 40,
	-height => 16,
	-takefocus => 1,
)->pack( -fill => 'both', -expand => 1);

print $tree ? "ok 3\n" : "not ok 3 (FileTree widget not created? ($@ $?)!)\n";

my $ok = $top->Button( qw/-text Show -underline 0/,
                       -command => \&showme );
my $cancel = $top->Button( qw/-text Quit -underline 0/,
                           -command => sub { exit } );
$ok->pack(     qw/-side left  -padx 10 -pady 10/ );
$cancel->pack( qw/-side right -padx 10 -pady 10/ );

my ($root, $home);
if ($bummer) {
	$home = $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'};
	$home ||= $ENV{'USERPROFILE'};
	($root = $home) =~ s#\\[^\\]*$##;
} else {
	$root = '/home';
	$home = "/home/$ENV{'USER'}";
	$home = $root = '/'  unless (-d $home);
}

print "--home=$home= root=$root=\n";
$tree->set_dir($home, -root => $root);

MainLoop;

sub showme {
	my @selection = $tree->selectionGet;
	print "--Show me:  active=".$tree->index('active')."=\n";
	print "--selected=".join('|',@selection)."=\n";
	foreach my $i (@selection) {
		print "-----$i selected.\n";
	}
	my $state = $tree->state();
	print "--state=$state=\n";
	print (($state =~ /d/) ? "--enabling.\n" : "--disabling.\n");
	$tree->state(($state =~ /d/) ? 'normal' : 'disabled');
}

