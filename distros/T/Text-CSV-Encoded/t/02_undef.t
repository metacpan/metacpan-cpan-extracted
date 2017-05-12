
use strict;
use Test::More;

plan tests => 2;

BEGIN {
    local $ENV{PERL_TEXT_CSV} = $ARGV[0] || 0;
    require Text::CSV::Encoded;
}

my $csv = Text::CSV::Encoded->new( { encoding_in => 'utf8', encoding_out => 'shiftjis' } );

$csv->blank_is_undef( 1 );

$csv->parse('abc,"",,"def"');

is_deeply( [ $csv->fields ], [ 'abc', '', undef, 'def' ] );

$csv->blank_is_undef( 0 );

$csv->parse('abc,"",,"def"');

is_deeply( [ $csv->fields ], [ 'abc', '', '', 'def' ] );

