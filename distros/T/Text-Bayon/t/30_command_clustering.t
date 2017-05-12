use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 2;
use File::Spec::Functions;

{
    my $bayon
        = Text::Bayon->new( bayon_path => '/hoge/fuga/bayon', dry_run => 1 );
    my $input = catfile( 't', 'data', 'input.tsv' );

    my $outfiles = {
        output   => catfile( 't', 'data', 'output.tsv' ),
        clvector => catfile( 't', 'data', 'centroid.tsv' ),
    };
    my $options = {
        limit    => 2.0,
        clvector => 1,
    };
    my $cmd = $bayon->clustering( $input, $options, $outfiles );
    is( $cmd,
        '/hoge/fuga/bayon t/data/input.tsv -l 2 -c t/data/centroid.tsv > t/data/output.tsv'
    );
}

{
    my $bayon = Text::Bayon->new( dry_run => 1 );
    my $input = catfile( 't', 'data', 'input.tsv' );

    my $outfiles = {
        output   => catfile( 't', 'data', 'output.tsv' ),
        clvector => catfile( 't', 'data', 'centroid.tsv' ),
    };
    my $options = {
        number   => 40,
        clvector => 1,
        point    => 1,
    };
    my $cmd = $bayon->clustering( $input, $options, $outfiles );
    is( $cmd,
        'bayon t/data/input.tsv -n 40 -p -c t/data/centroid.tsv > t/data/output.tsv'
    );
}
