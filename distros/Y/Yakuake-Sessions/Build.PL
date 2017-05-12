# @(#)$Ident: Build.PL 2013-12-14 14:26 pjf ;

use strict;
use warnings;

use Module::Build 0.4004;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'Yakuake-Sessions'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Module::Build' => '0.4004',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'requires' => {
    'Class::Usul' => 'v0.41.0',
    'File::DataClass' => 'v0.35.0',
    'Moo' => '1.004002',
    'Net::DBus' => 'v1.0.0',
    'Try::Tiny' => '0.22',
    'Unexpected' => 'v0.22.1',
    'namespace::autoclean' => '0.19',
    'perl' => '5.010001'
  },
};

if ($] < $perl_ver) {
   $ENV{AUTOMATED_TESTING}
      or $ENV{PERL_CPAN_REPORTER_CONFIG}
      or $ENV{PERL5_CPANPLUS_IS_VERSION}
      or whimper "Minimum required Perl version is ${perl_ver}";
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{build_requires}->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
}

Module::Build->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  %{ $prereqs },

)->create_build_script;

exit 0;
