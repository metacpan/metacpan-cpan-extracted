#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use Cwd;
use Wx::Perl::FSHandler::LWP;

my $ua = LWP::UserAgent->new;
my $handler = Wx::Perl::FSHandler::LWP->new( $ua );
Wx::FileSystem::AddHandler( $handler );

my $url = 'file:t/02_simple.t';
my $fs = Wx::FileSystem->new;
my $file = $fs->OpenFile( $url );

ok( $file );
is( $file->GetLocation, $url );

my $fh = $file->GetStream;

is( scalar( <$fh> ), "#!/usr/bin/perl -w\n" );
