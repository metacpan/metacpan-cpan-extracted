use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON ();

my $pkg;
BEGIN {
    $pkg = 'RDF::LDF';
    use_ok $pkg;
}
require_ok $pkg;

done_testing;
