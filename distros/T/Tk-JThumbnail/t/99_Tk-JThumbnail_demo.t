# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tk-JThumbnail.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use blib;
use File::Basename;
use Tk;
use Tk::JPEG;
use Tk::PNG;
use Tk ':eventtypes';

our $haveAnimation = 0;
eval 'use Tk::widgets qw/ Animation /; $haveAnimation = 1; 1';
$haveAnimation ? diag("ok, have Tk::Animation installed.")
		: diag("\n\nNOTE: (Optional) module Tk::Animation not found.\n\n");



use Test::More tests => ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) ? 1 : 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { use_ok('Tk::JThumbnail') };   #NEEDED THIS TO MAKE TEST HARNESS PASS?!?!?!

if (!$ENV{PERL_MM_USE_DEFAULT} && !$ENV{AUTOMATED_TESTING}) {

diag( "Testing Tk::JThumbnail, Testing v$Tk::JThumbnail::VERSION, Perl $], $^X" );
diag( "will popup Tk window now...");

$SIG{__WARN__} = sub { };

our $mw;
sub sam {
	$mw = eval { MainWindow->new; };
	if ($mw) {
		my $testimgdir = (-d '../lib/Tk/JThumbnail/images/')
				? '../lib/Tk/JThumbnail/images/'
				: ((-d 'lib/Tk/JThumbnail/images/') ? 'lib/Tk/JThumbnail/images/' : '.');
		my @list = directory($testimgdir);  #Fetch files from the current directory.

		my $thumb = $mw->Scrolled('JThumbnail',
				-images => \@list,
				-width => 150,
				-scrollbars => 'osoe',
				-highlightthickness => 1,
				-focus => 2,
				-nodirs => 1,
		)->pack(-side => 'top', -expand => 1, -fill => 'both');

		$thumb->Subwidget('yscrollbar')->configure(-takefocus => 0);
		$thumb->Subwidget('xscrollbar')->configure(-takefocus => 0);
		$thumb->Subwidget('corner')->Button(
				-bitmap => $Tk::JThumbnail::CORNER,
				-borderwidth => 1,
				-takefocus => 0,
				-command => [\&cornerjump, $thumb],
		)->pack;

		my $b2 = $mw->Button(
				-text=>'~Done',
				-command => sub{
					##TEST HARNESS WILL FAIL:	 exit(0);
					$mw->destroy();
				}
		)->pack(qw/-side top/);

		$thumb->bindImages('<ButtonRelease-3>' => [\&RighClickFunction]);

		$thumb->focus();

##TEST HARNESS WILL FAIL:		MainLoop;
		while (Tk::MainWindow->Count)
		{
			DoOneEvent(ALL_EVENTS);
		}

		diag "ok, done (Success)!\n";

		return 1;
}



		sub RighClickFunction
		{
			my $self = pop;

			my $indx = $self->index('mouse');
			my $fn = $self->get($indx);
			print "---You right-clicked on file ($fn) at position: $indx!\n";
		}

		sub cornerjump
		{
			my $self = shift;

			$self->activate($self->index('active') ? 0 : 'end');
		}

		sub directory
		{
			my ($dir) = @_;
			chdir($dir);
			$dir .= '/'  unless ($dir =~ m#\/#);
			my $pwd = `pwd`; chomp $pwd;
			$mw->title ("Directory: $pwd");
			opendir (DIR, ".") or die "Cannot open '.': $!\n";
			my @files = ();
			foreach my $name (readdir(DIR)) {	
				my $st = stat($name);
				next  unless ($st);
				push @files, $name;
			}
			return sort @files;
		}
	}
} else {
	diag( "ok, done (Skipping Demo program - no X-session)." );
}

unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
	is(&sam(), 1, 'running Tk::JThumbnail sample program.');
	diag( "Testing sample Tk::JThumbnail program." );
}

__END__
