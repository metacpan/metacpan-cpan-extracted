# -*- perl -*-

# t/003_load_project.t - check project module loading

use Test::More;
use Data::Dumper;
my $t = 0;

BEGIN { use_ok( 'WWW::SourceForge::Project' ); }
$t++;

my $project = WWW::SourceForge::Project->new( name => 'storybook2' );

my $download_count = $project->downloads(
    start_date => '2012-07-01',
    end_date   => '2012-07-25'
);
is ( $download_count, 10732 );
$t++;

done_testing( $t );
