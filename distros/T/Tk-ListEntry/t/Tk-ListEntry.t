
use strict;
use warnings;
use Test::Tk;
use Tk;

use Test::More tests => 6;
BEGIN { use_ok('Tk::ListEntry') };


createapp(
);

my $le;
if (defined $app) {
	$le = $app->ListEntry(
		-command => sub { my $v = shift; print "selected: $v\n" },
		-values => [qw/Red Green Blue Cyan Magenta Yellow Black White Pink Purple Brown Beige Orange/],
	)->pack(-fill => 'x');
}
@tests = (
	[sub { return defined $le }, 1, 'Created ListEntry'],
	[sub { 
		$le->insert('end', 'Red');
		my $val = $le->validate;
		return $le->validate
	}, 1, 'Red is in the list'],
	[sub {
		$le->delete(0, 'end');
		$le->insert('end', 'Der');
		my $val = $le->validate;
		return $le->validate
	}, 0, 'Der is not in the list'],
);

starttesting



