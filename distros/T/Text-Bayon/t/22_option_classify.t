use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 1;
use File::Spec::Functions;

{
    my $bayon     = Text::Bayon->new;
    my $input     = catfile( 't', 'data', 'input.tsv' );
    my $clvector  = catfile( 't', 'data', 'clvector.tsv' );
    my $options = { 'classify' => $clvector };

    my $io_files = $bayon->_io_file_names($input);
    my $option = $bayon->_option( 'classify', $options, $io_files );

    is( $option, '--classify=t/data/clvector.tsv --inv-keys=20 --inv-size=100 --classify-size=20');
}
