use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Pod::Checker; 1 }
        or plan skip_all => 'Pod::Checker not available';
}

plan tests => 1;

# RT#53557: Missing =back in Date::Parse POD before =head1 MULTI-LANGUAGE SUPPORT
{
    my $checker = Pod::Checker->new;
    $checker->parse_from_file('lib/Date/Parse.pm');
    is($checker->num_errors, 0, "RT#53557: Date::Parse.pm has valid POD (no missing =back)");
}
