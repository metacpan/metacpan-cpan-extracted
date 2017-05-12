use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::MethodName;

all_methods_ok(
    'MyApp' => sub {
        my $method = shift;
        return ( $method =~ m!check! ) ? undef : 'pass';
    },
);
