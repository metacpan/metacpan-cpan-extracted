# -*- perl -*-

# t/003_load_project.t - check project module loading

use Test::More;
my $t = 0;

BEGIN { use_ok( 'WWW::SourceForge::Wiki' ); }

my $wiki = WWW::SourceForge::Wiki->new( project => 'newsgrowler' );
isa_ok( $wiki, 'WWW::SourceForge::Wiki',
    'WWW::SoruceForge::Wiki interface loads ok' );
$t += 2;

done_testing( $t );
