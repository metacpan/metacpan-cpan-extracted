# Same tests as Web-Session-utf8.t with JSON::PP, which
# doesn't flag its result as UTF-8 when data holds only Latin-1 characters
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::PP' }

use strict;
use warnings;
use FindBin;
use File::Spec;
use JSON;
use Test::More;

is( JSON->backend, 'JSON::Backend::PP', 'JSON::PP backend used' );

# Locate the included test next to this file, whatever the current directory
my $file = File::Spec->catfile( $FindBin::Bin,
    'Web-Session-utf8.t' );
my $result = do $file;
die "Cannot parse $file: $@" if $@;
die "Cannot read $file: $!" unless defined $result;
