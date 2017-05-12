use strict;
use warnings;
use Test::More qw[no_plan];
use_ok('App::SmokeBrew::Plugin::CPANPLUS::YACSmoke');

my $fetchtests = 1;

{
  # Check we can fetch a file from a CPAN mirror
  require IO::Socket::INET;
  my $sock = IO::Socket::INET->new( PeerAddr => 'cpanidx.org', PeerPort => 80, Timeout => 20 )
     or $fetchtests = 0;
}

{
  my $plugin = App::SmokeBrew::Plugin::CPANPLUS::YACSmoke->new(
      version   => '5.10.1',
      builddir => '.',
      prefix    => 'perl-5.10.1',
      email     => 'cpanplus@example.com',
      perl_exe  => $^X,
      mirrors   => [ 'http://www.cpan.org', 'ftp://ftp.cpan.org/' ],
  );
  isa_ok($plugin,'App::SmokeBrew::Plugin::CPANPLUS::YACSmoke');

  SKIP: {
    skip "No network tests", 1 unless $fetchtests;
    ok( $plugin->_cpanplus, 'Found a CPANPLUS path' );
  }

  isa_ok( $_, 'URI' ) for $plugin->mirrors;
}
