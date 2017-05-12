use strict;
use warnings;
use Test::More qw[no_plan];
use_ok('App::SmokeBrew::Plugin::Null');

{
  my $plugin = App::SmokeBrew::Plugin::Null->new(
      version   => '5.10.1',
      builddir => '.',
      prefix    => 'perl-5.10.1',
      email     => 'cpanplus@example.com',
      perl_exe  => $^X,
      mirrors   => [ 'http://www.cpan.org', 'ftp://ftp.cpan.org/' ],
  );
  isa_ok($plugin,'App::SmokeBrew::Plugin::Null');
  isa_ok( $_, 'URI' ) for $plugin->mirrors;
}
