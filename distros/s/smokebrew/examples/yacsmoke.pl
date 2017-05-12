use strict;
use warnings;
use App::SmokeBrew::Plugin::CPANPLUS::YACSmoke;

my $plugin = App::SmokeBrew::Plugin::CPANPLUS::YACSmoke->new(
  version   => '5.8.9',
  builddir => 'build',
  prefix    => 'prefix',
  verbose   => 1,
  perl_exe  => 'prefix/perl-5.8.9/bin/perl',
  email     => 'bingos@cpan.org',
  mx        => '192.168.1.87',
  mirrors   => [ 'http://cpan.hexten.net/', 'http://cpan.cpantesters.org/' ],
);

$plugin->configure;
