use strict;
use Test::More;

use PICA::Data ':all';

my %tests = (
    "028A \$ax\n\n"                                   => 'Plain',
    '<record xlmns="info:srw/schema/5/picaXML-v1.0">' => 'XML',
    "028A \x{1F}a\x{1E}\x{0A}"                        => 'Plus',
    "028A \x{1F}a\x{1E}\x{1D}"                        => 'Binary',
    "[[\"028A\",\"\",\"a\",\"x\"]]\n"                 => 'JSON',
    '{"record":[["028A","","a","x"]]}'                => 'JSON'
);

while (my ($pica, $format) = each %tests) {
    note $pica;
    is pica_guess($pica), "PICA::Parser::$format", $format;
    if ($format ne 'XML') {
        my $record = pica_data($pica);
        isa_ok( $record, 'PICA::Data' );
        is(pica_string($record, $format), $pica) unless $pica =~ /record/;
    }
}

is pica_guess('WTF?!'), undef, '???';

done_testing;
