use strict;
use warnings;

use Test::More tests => 10;

use XML::Writer;

my $normal = XML::Writer->new( OUTPUT => \my $normal_output );
my $contained = XML::Writer->new( OUTPUT => 'self' );

$normal->dataElement( normal => 'good old classic way' );
$contained->dataElement( selfcontained => 'new and shiny' );

is $normal_output => '<normal>good old classic way</normal>',
    'classic OUTPUT behaves the same way';

my $contained_result = "<selfcontained>new and shiny</selfcontained>\n";

is $contained->end => $contained_result, "end()";

is $contained->to_string => $contained_result, 'to_string() on self-contained';

eval { $normal->to_string };
like $@ => qr/'to_string' can only be used with self-contained output/,
    "to_string on normal OUTPUT";

is "$contained" => $contained_result,
    'auto-stringification on self-contained';

like "$normal" => qr/^XML::Writer=HASH/,
    'auto-stringification on normal';

is ref($normal->_overload_string) => '',
    'auto-stringification returns a string directly';

$contained = XML::Writer->new( OUTPUT => 'self' );
$contained->emptyTag('empty');
$contained->end;

is "$contained" => "<empty />\n", 'Calling end in a void context.';

SKIP: {
    eval { require IO::Scalar; };
    skip "IO::Scalar is not installed", 2 if $@;

    my $text = '';
    my $writer_ioscalar = XML::Writer->new( OUTPUT => IO::Scalar->new(\$text) );

    my $ioscalar_out = "<ioscalar>the IO::Scalar way</ioscalar>\n";
    $writer_ioscalar->dataElement( ioscalar => 'the IO::Scalar way' );
    $writer_ioscalar->end;

    is $text => $ioscalar_out,
        'IO::Scalar OUTPUT behaves the same way';

    eval { $writer_ioscalar->to_string };
    like $@ => qr/'to_string' can only be used with self-contained output/,
        "to_string on IO::Scalar OUTPUT";
}
