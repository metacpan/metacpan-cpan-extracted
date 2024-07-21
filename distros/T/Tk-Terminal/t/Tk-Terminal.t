
use strict;
use warnings;
use Tk;

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';

use Test::Tk;
use Test::More tests => 12;

BEGIN { use_ok('Tk::Terminal') };

createapp(
);

my $terminal;
if (defined $app) {
	$terminal = $app->Scrolled('Terminal',
		-historyfile => 't/cmdhistory',
		-dircall => sub { print "dir: ", shift, "\n" },
		-linkcall => sub { print "link: ", shift, "\n" },
		-linkreg => qr/[^\s]+\sline\s\d+/,
		-scrollbars => 'oe',
	)->pack(-expand => 1, -fill => 'both');
}

testaccessors($terminal, 'cur', 'err', 'hist', 'hp', 'in', 'linkScanned', 'out', 'pid');

push @tests, [sub {
	return defined $terminal 
}, 1, 'Terminal widget created'];

starttesting;




