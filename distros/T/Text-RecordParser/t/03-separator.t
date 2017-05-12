#!perl

#
# test for "field_separator" and "record_separator"
#

use strict;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Test::More tests => 8;
use Text::RecordParser;
use Readonly;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new;
    is( $p->field_separator, ',', 'Field separator is comma' );
    is( $p->field_separator("\t"), "\t", 'Field separator is tab' );
    is( $p->field_separator('::'), '::', 'Field separator is double colon' );
    is( ref $p->field_separator(qr/\s+/), 'Regexp', 
        'Field separator is a regular expression' );

    is( $p->record_separator, "\n", 'Record separator is newline' );
    is( $p->record_separator("\n\n"), "\n\n", 
        'Record separator is double newline' 
    );
    is( $p->record_separator(':'), ':', 'Record separator is colon' );
}

{
    my $p2 = Text::RecordParser->new(catfile($TEST_DATA_DIR, 'simpsons.tab'));
    is( $p2->field_separator("\t"), "\t", 'Field separator guessed tab' );
}
