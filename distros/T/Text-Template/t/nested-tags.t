#!perl
#
# Test for breakage of Dist::Milla in v1.46
#

use strict;
use warnings;
use Text::Template;
use Test::More;

my $tmpl = Text::Template->new(
    TYPE       => 'STRING',
    SOURCE     => q| {{ '{{$NEXT}}' }} |,
    DELIMITERS => [ '{{', '}}' ]);

is $tmpl->fill_in, ' {{$NEXT}} ';

done_testing;
