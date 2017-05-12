# -*- perl -*-

# t/003_load_project.t - check project module loading

use Test::More;
my $t = 0;

BEGIN { use_ok( 'WWW::SourceForge::Project' ); }

my $object = WWW::SourceForge::Project->new( name => 'flightics' );
isa_ok( $object, 'WWW::SourceForge::Project',
    'WWW::SourceForge::Project interface loads ok' );
$t += 2;

is( $object->type(), 10,           'Allura project' );
is( $object->name(), 'Flight ICS', 'Project name' );
is( $object->summary(), 'Create ICS files from flight itinerary information', 'Project summary' );
is( $object->id(),   '631079',     'Project id' );
$t += 4;


my $object2 = WWW::SourceForge::Project->new( id => '631079' );
isa_ok( $object2, 'WWW::SourceForge::Project' );
is( $object2->name(), 'Flight ICS' );
$t += 2;

my $proj3 = WWW::SourceForge::Project->new( name => 'reefknot' );
is( $proj3->id(), 14603 );
$t++;

my @admins = $proj3->admins();

my $admin1 = $admins[0];
is( $admin1->username(), 'srl' );

my $admin2 = $admins[1];
is( $admin2->username(), 'skud' );

is( scalar( $proj3->admins() ), 3 ); # Should get it from the cache this time

is( scalar( $proj3->developers() ), 9 );

is( scalar( $proj3->users() ), 12 ); # This should be really fast
$t += 5;

# If I do that another ten times, it shouldn't take any time at all
for (1..10) {
    is( scalar( $proj3->users() ), 12 ); 
    $t++;
}

# Note that this will almost certainly be moved into a ::Files module at
# some point. Or Releases. Or something like that.
my @files = $proj3->files();
is( $proj3->latest_release(), 'Fri, 28 Dec 2001 02:25:45 +0000' );
$t++;

# Project logos
my $p = WWW::SourceForge::Project->new( name => 'flightics' );
is ( $p->logo(), 'http://sourceforge.net/p/flightics/icon' );

my $p2 = WWW::SourceForge::Project->new( name => 'rbclassic' );
is ( $p2->logo(), 'http://a.fsdn.com/con/img/project_default.png' );

my $p3 = WWW::SourceForge::Project->new( name => 'wings' );
is ( $p3->logo(), 'http://sourceforge.net/p/wings/icon' ); # They upgraded
$t+=3;

# Project logo for an allura project without an icon
my $p4 = WWW::SourceForge::Project->new( name => 'sfprojecttools' );
is ( $p4->logo(), 'http://a.fsdn.com/con/img/project_default.png' );
$t++;

done_testing( $t );

