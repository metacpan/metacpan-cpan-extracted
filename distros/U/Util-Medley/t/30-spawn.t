use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::Spawn;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $spawn = Util::Medley::Spawn->new;
ok($spawn);

#####################################
# capture
#####################################

my $cmd = "echo foobar";

{
	my ( $stdout, $stderr, $exit ) = $spawn->capture($cmd);
	ok( !$exit );
	ok( $stdout eq 'foobar' );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->capture(cmd => $cmd, wantArrayRef => 1);
	ok( !$exit );
	ok(ref($stdout) eq 'ARRAY');
	ok(ref($stderr) eq 'ARRAY');
	ok($stdout->[0] eq 'foobar');
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->capture( cmd => $cmd );
	ok( !$exit );
	ok( $stdout eq 'foobar' );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->spawn($cmd);
	ok( !$exit );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->spawn( cmd => $cmd );
	ok( !$exit );
}

$cmd = [qw(echo foobar)];

{
	my ( $stdout, $stderr, $exit ) = $spawn->capture($cmd);
	ok( !$exit );
	ok( $stdout eq 'foobar' );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->capture( cmd => $cmd );
	ok( !$exit );
	ok( $stdout eq 'foobar' );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->spawn(cmd => $cmd);
	ok( !$exit );
}

{
	my ( $stdout, $stderr, $exit ) = $spawn->spawn( cmd => $cmd );
	ok( !$exit );
}

#####################################
# spawn
#####################################

done_testing;
