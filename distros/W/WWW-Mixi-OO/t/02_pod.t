# -*- cperl -*-
# this script borrowed from SVN-Web/t/1use.t.

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw( dirname );

BEGIN {
    my %also_privates = (
	'WWW::Mixi::OO::Session' => [qr/^simple_request$/],
       );

    plan skip_all => 'Pod::Coverage not found'
	unless eval {require Pod::Coverage;};

    my $manifest = File::Spec->catdir( dirname(__FILE__), '..', 'MANIFEST' );

    plan skip_all => 'MANIFEST not exists' unless -e $manifest;
    open FH, $manifest;

    my @pm = map { s|^lib/||; chomp; $_ } grep { m|^lib/.*pm$| } <FH>;

    plan tests => scalar @pm;
    for (@pm) {
	s|\.pm$||;
	s|/|::|g;

    TODO: {
	    if ($] < 5.007 && /^WWW::Mixi::OO::I18N::UTF8$/) {
		skip 'maybe Encode not found', 1;
	    }
	    my $pc = Pod::Coverage->new(
		package => $_,
		also_private => $also_privates{$_});
	    my $rating = $pc->coverage;
	    todo_skip 'Pod::Coverage unrated (' . $pc->why_unrated . ')', 1
		unless defined $rating;
	    if ($pc->naked) {
		#local $TODO = 'Pod unfinished';
		fail("$_ has a Pod::Coverage rating of $rating");
		my @looky_here = $pc->naked;
		if ( @looky_here > 1 ) {
		    diag("$_: The following are uncovered: ",
			 join(", ", sort @looky_here));
		}
		elsif (@looky_here) {
		    diag("$_: '$looky_here[0]' is uncovered");
		}
	    } else {
		pass("$_ has a Pod::Coverage rating of $rating");
	    }
	};
    }
}
