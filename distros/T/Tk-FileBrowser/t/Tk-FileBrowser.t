use strict;
use warnings;
use Test::More tests => 7;
use Test::Tk;
use Tk;

BEGIN {
	use_ok('Tk::FileBrowser::Header');
	use_ok('Tk::FileBrowser')
};

$delay = 1000;

createapp;

my $fb;
if (defined $app) {
	$app->geometry('640x400+100+100');
	$fb = $app->FileBrowser(
		-columns => [qw[Size Modified Big]],
		-columntypes => [
			Big => {
				display => sub {
					my $s = $fb->getSize(@_);
					return 'X' if $s > 2048;
					return '';
				},
				test => sub {
					return $fb->testSize(@_);
				},
			},
		],
#		-directoriesfirst => 0,
		-invokefile => sub { my $f = shift; print "invoking: $f\n" },
#		-selectmode => 'extended',
#		-showhidden => 1,
#		-sorton => 'Modified',
#		-sorton => 'Size',
#		-sortorder => 'descending',
	)->pack(
		-expand => 1,
		-fill => 'both',
	);
}

push @tests, (
	[ sub { return defined $fb }, 1, 'FileBrowser widget created' ],
	[ sub { return defined $fb->Subwidget('Tree') }, 1, 'Tree widget found' ],
	[ sub { $fb->load; return 1 }, 1, 'Loaded current directory' ],
);


starttesting;
















