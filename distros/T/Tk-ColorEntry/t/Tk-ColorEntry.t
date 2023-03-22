use strict;
use warnings;
use Test::More tests => 4;
use Test::Tk;
use Tk;

BEGIN { use_ok('Tk::ColorEntry') };

createapp;

my $entry;
if (defined $app) {
	my $frame = $app->Frame(
		-width => 200,
		-height => 100,
	)->pack(-fill => 'both');
	$entry = $frame->ColorEntry(
		-depthselect => 1,
		-indicatorwidth => 4,
		-historyfile => 't/colorentry_history',
	)->pack(
		-fill => 'x',
	);
	$frame->Entry->pack;

}

# 	#testing accessors
# 	my @accessors = qw(Colored ColorInf FoldButtons FoldInf highlightinterval LoopActive NoHighlighting);
# 	for (@accessors) {
# 		my $method = $_;
# 		push @tests, [sub {
# 			my $default = $text->$method;
# 			$text->$method('blieb');
# 			my $res1 = $text->$method;
# 			$text->$method('quep');
# 			my $res2 = $text->$method;
# 			$text->$method($default);
# 			return (($res1 eq 'blieb') and ($res2 eq 'quep'));
# 		}, 1, "Accessor $method"];
# 	}

push @tests, (
	[ sub { return defined $entry }, 1, 'ColorEntry widget created' ],
);


starttesting;
