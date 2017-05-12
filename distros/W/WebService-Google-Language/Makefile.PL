use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker 6.17;

print <<END;

DEPRECATION WARNING

The v1 API, which this module is based on, WILL BE SHUT OFF COMPLETELY
by Google on Dec 1, 2011.

See http://code.google.com/apis/language/translate/overview.html

END

sleep 5;

my $eumm = eval ExtUtils::MakeMaker->VERSION;

my $knows_license            = $eumm >= 6.3001;
my $knows_meta               = $eumm >= 6.46;
my $knows_min_perl_version   = $eumm >= 6.4701;
my $knows_configure_requires = $eumm >= 6.5103;
my $knows_build_requires     = $eumm >= 6.5503;

my $NAME = 'WebService::Google::Language';

(my $dist = $NAME) =~ s|::|-|g;
(my $path = $NAME) =~ s|::|/|g;

my $META = {
  no_index => {
    directory  => 'xt',
  },
  resources => {
    homepage   => "http://search.cpan.org/dist/$dist/",
    bugtracker => "http://rt.cpan.org/Public/Dist/Display.html?Name=$dist",
    repository => "https://github.com/hma/$dist",
    license    => 'http://dev.perl.org/licenses/',
  },
};

my %args = (
  NAME          => $NAME,
  AUTHOR        => 'Henning Manske <hma@cpan.org>',
  VERSION_FROM  => "lib/$path.pm",
  ABSTRACT_FROM => "lib/$path.pm",

  ( $knows_license            ? ( LICENSE            => 'perl' ) : () ),
  ( $knows_meta               ? ( META_MERGE         => $META  ) : () ),
  ( $knows_min_perl_version   ? ( MIN_PERL_VERSION   => 5.006  ) : () ),
  ( $knows_configure_requires ? ( CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.17' } ) : () ),

  BUILD_REQUIRES => {
    'HTTP::Response' => '0',
    'JSON'           => '2.0',
    'LWP::UserAgent' => '0',
    'Test::More'     => '0.62',
  },
  PREREQ_PM => {
    'JSON'           => '2.0',
    'LWP::UserAgent' => '0',
    'URI'            => '0',
  },

  dist  => { COMPRESS => 'gzip -9f' },
  clean => { FILES    => "$dist-* cover_db Debian_CPANTS.txt nytprof*" },
  test  => { TESTS    => 't/*.t xt/*.t' },

);

if ( ! $knows_build_requires && (my $br = delete $args{BUILD_REQUIRES}) ) {
  my $pp = $args{PREREQ_PM} ||= {};
  for (keys %$br) {
    $pp->{$_} = $br->{$_} if ! $pp->{$_} || eval $pp->{$_} < eval $br->{$_};
  }
}

WriteMakefile(%args);
