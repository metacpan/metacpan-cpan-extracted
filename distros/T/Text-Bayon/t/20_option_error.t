use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 1;
use File::Spec::Functions;

{
    my $bayon = Text::Bayon->new;
    my $input = catfile( 't', 'data', 'input.tsv' ),
    my $args  = {
        output => catfile( 't', 'data', 'output.tsv' ),
    };
    my $io_file = $bayon->_io_file_names($input, $args);
    eval { my $option = $bayon->_option( 'xxxxxx', $args, $io_file ); };
    like( $@, qr/wrong method name/ );
}

