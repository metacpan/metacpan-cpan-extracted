use strict;
use Test::More;

plan tests => 2;

BEGIN {
    local $ENV{PERL_TEXT_CSV} = $ARGV[0] || 0;
    require Text::CSV::Encoded;
}

my $csv = Text::CSV::Encoded->new( { not_implemented_attr => 1 } );

ok( not $csv );

like( Text::CSV::Encoded->error_diag, qr/INI - / );
