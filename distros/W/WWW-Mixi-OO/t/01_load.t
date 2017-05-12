# -*- cperl -*-
# this script borrowed from SVN-Web/t/1use.t.

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw( dirname );

BEGIN {
    my $manifest = File::Spec->catdir( dirname(__FILE__), '..', 'MANIFEST' );

    plan skip_all => 'MANIFEST not exists' unless -e $manifest;
    open FH, $manifest;

    my @pm = map { s|^lib/||; chomp; $_ } grep { m|^lib/.*pm$| } <FH>;

    plan tests => scalar @pm;
    for (@pm) {
	s|\.pm$||;
	s|/|::|g;

    SKIP: {
	    if ($] < 5.007 && /^WWW::Mixi::OO::I18N::UTF8$/) {
		skip 'maybe Encode not found', 1;
	    }
	    use_ok ($_);
	};
    }

}
