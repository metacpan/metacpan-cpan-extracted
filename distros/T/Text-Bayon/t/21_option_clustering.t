use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 3;
use File::Spec::Functions;

{
    my $bayon = Text::Bayon->new;
    my $input = catfile( 't', 'data', 'input.tsv' );
	my $options = {
        limit    => '2.0',
        clvector => 1,
        point    => 1,
        idf      => 1,
    };
    my $output_files = {
        output   => catfile( 't', 'data', 'output.tsv' ),
        clvector => catfile( 't', 'data', 'centroid.tsv' ),
    };
    my $io_files = $bayon->_io_file_names( $input, $output_files );
    my $option = $bayon->_option( 'clustering', $options, $io_files );

    is( $option, '-l 2.0 -p -c t/data/centroid.tsv --idf' );
}

{
    my $bayon = Text::Bayon->new;
    my $input = catfile( 't', 'data', 'input.tsv' );
	my $options = {
        number    => '5',
        point    => 1,
        idf      => 1,
    };
    my $output_files = {
        output   => catfile( 't', 'data', 'output.tsv' ),
    };
    my $io_files = $bayon->_io_file_names( $input, $output_files );
    my $option = $bayon->_option( 'clustering', $options, $io_files );

    is( $option, '-n 5 -p --idf' );
}

{
    my $bayon = Text::Bayon->new;
    my $input = catfile( 't', 'data', 'input.tsv' );
	my $options = {};
    my $output_files = {
        output   => catfile( 't', 'data', 'output.tsv' ),
    };
    my $io_files = $bayon->_io_file_names( $input, $output_files );
    my $option = $bayon->_option( 'clustering', $options, $io_files );

    is( $option, '-l 1.5' );
}
