# -*- perl -*-

# t/002_load_user.t - check user module loading

use Test::More tests => 5;

BEGIN { use_ok( 'WWW::SourceForge::User' ); }

my $user = WWW::SourceForge::User->new( username => 'rbowen' );

isa_ok ($user, 'WWW::SourceForge::User', 'WWW::SourceForge::User interface loads ok');

is( $user->username(), 'rbowen' );
is( $user->name(), 'Rich Bowen' );
is( $user->sex(), 'Male' );

# my @projects = $user->projects();
# ok( scalar( @projects ) >= 26, 'Buncha projects' );
# 
# my $p = $projects[0];
# is( $p->name(), 'modules.a.o' );


