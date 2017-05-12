use strict;
use warnings;
use Test::More qw[no_plan];

use_ok('App::SmokeBrew::BuildPerl');

{
  eval {
    my $bp = App::SmokeBrew::BuildPerl->new(
      version => '6.10.1',
      builddir => '.',
      prefix => 'perl-5.10.1',
      perlargs => ['-Dusethreads','-Duse64bitint'],
    );
  };
  like( $@, qr/given is not a valid Perl version/s, q{We didn't like the version given} );
}

{
  my $bp = App::SmokeBrew::BuildPerl->new(
    version => '5.10.1',
    builddir => '.',
    prefix => 'perl-5.10.1',
    perlargs => ['-Dusethreads','-Duse64bitint'],
  );

  isa_ok($bp,'App::SmokeBrew::BuildPerl');
  isa_ok($bp->version, 'Perl::Version');
  is( $bp->perl_version, 'perl-5.10.1', 'The perl version is okay');
}

{
  eval {
    my $bp = App::SmokeBrew::BuildPerl->new(
      version => '5.005_03',
      builddir => '.',
      prefix => 'perl5.005_03',
      perlargs => ['-Dusethreads','-Duse64bitint'],
    );
  };
  like( $@, qr/given is not a valid Perl version/s, q{We didn't like the version given} );
}

