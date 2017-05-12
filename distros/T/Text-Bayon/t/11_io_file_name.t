use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 2;
use File::Spec::Functions;

{
    my $bayon = Text::Bayon->new;
	my $input = catfile( 't', 'data', 'input.tsv' ),
    my $args  = {
        output   => catfile( 't', 'data', 'output.tsv' ),
        clvector => catfile( 't', 'data', 'centroid.tsv' ),
    };
    my $result = $bayon->_io_file_names($input,$args);
    is_deeply(
        $result,
        {
            'clvector' => 't/data/centroid.tsv',
            'input'    => 't/data/input.tsv',
            'output'   => 't/data/output.tsv'
        },
        'file names are correct all',
    );
    open( FILE, "<", $result->{input} );
    my @input_data = <FILE>;
    close(FILE);
    is_deeply( \@input_data, correct_input(), 'input file data was passed correctly' );
}

sub correct_input {
    open( FILE, "<", catfile( 't', 'data', 'input.tsv' ) );
    my @correct_input = <FILE>;
    close(FILE);
    return \@correct_input;
}
