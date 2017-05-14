# -*- perl -*-

# t/003_load_project.t - check project module loading

use Test::More;
use Data::Dumper;
my $t = 0;

BEGIN { use_ok( 'WWW::SourceForge::Project' ); }

my $object = WWW::SourceForge::Project->new( name => 'flightics' );

isa_ok( $object, 'WWW::SourceForge::Project',
    'WWW::SourceForge::Project interface loads ok' );
$t += 2;

is( $object->name(), 'Flight ICS', 'Project name' );
is( $object->summary(), 'Create ICS files from flight itinerary information', 'Project summary' );
is( $object->id(),   '4ec6779f0594ca5beb000106',     'Project id' );
$t += 4;

my $proj3 = WWW::SourceForge::Project->new( name => 'reefknot' );
is( $proj3->id(), '4fbbbda1fd48f8364c000074');
$t++;

# 12 developers
is( scalar( $proj3->developers() ), 12 );
is( scalar( $proj3->users() ), 12 ); # This should be really fast
$t += 2;

# If I do that another ten times, it shouldn't take any time at all
for (1..10) {
    is( scalar( $proj3->users() ), 12 ); 
    $t++;
}

my $p2 = WWW::SourceForge::Project->new( name => 'rbclassic' );
is ( $p2->logo(), 'http://a.fsdn.com/con/img/project_default.png' );

# Project logo for an allura project without an icon
my $p4 = WWW::SourceForge::Project->new( name => 'sfprojecttools' );
is ( $p4->logo(), 'http://a.fsdn.com/con/img/project_default.png' );
$t++;

done_testing( $t );

