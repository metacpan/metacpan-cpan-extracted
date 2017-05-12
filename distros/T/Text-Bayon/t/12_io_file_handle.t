use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 4;
use File::Spec::Functions;

{
    my $bayon = Text::Bayon->new;
    open( my $input_fh, "<", catfile( 't', 'data', 'input.tsv' ) );
    my $args = {
        output   => catfile( 't', 'data', 'output.tsv' ),
        clvector => catfile( 't', 'data', 'centroid.tsv' ),
    };
    my $result = $bayon->_io_file_names( $input_fh, $args );

    ok( -e $result->{input}, 'temporary input file is generated' );
    is( $result->{output},   't/data/output.tsv',   'output file ok' );
    is( $result->{clvector}, 't/data/centroid.tsv', 'clvector file ok' );

    open( FILE, "<", $result->{input} );
    my @input_data = <FILE>;
    close(FILE);
    is_deeply( \@input_data, correct_input(),
        'input file handle was passed correctly' );
}

sub correct_input {
    open( FILE, "<", catfile( 't', 'data', 'input.tsv' ) );
    my @correct_input = <FILE>;
    close(FILE);
    return \@correct_input;
}
