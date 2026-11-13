use 5.016;
use warnings;

use ExtUtils::MakeMaker 6.64;
use Module::Metadata 1.000009;

WriteMakefile(
  NAME               => 'Twilio',
  AUTHOR             => 'Francisco Zarabozo <zarabozo@cpan.org>',
  VERSION_FROM       => 'lib/Twilio.pm',
  ABSTRACT_FROM      => 'lib/Twilio.pm',
  LICENSE            => 'mit',
  MIN_PERL_VERSION   => '5.016',
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64', 'Module::Metadata' => '1.000009' },
  TEST_REQUIRES      => { 'Test::More'          => '0.98' },
  PREREQ_PM          => {
    'Carp'            => '0',
    'Digest::SHA'     => '0',
    'HTTP::Tiny'      => '0.076',
    'IO::Socket::SSL' => '1.968',
    'JSON::PP'        => '0',
    'MIME::Base64'    => '0',
    'Mozilla::CA'     => '0',
    'Net::SSLeay'     => '1.49',
    'overload'        => '0',
    'parent'          => '0',
    'POSIX'           => '0',
    'Scalar::Util'    => '0',
    'Time::Local'     => '0',
    'Time::Piece'     => '0',
  },
  test  => { RECURSIVE_TEST_FILES => 1 },
  clean => { FILES                => 'Twilio-* cover_db' },

  # GNU tar options: on Windows every file would otherwise go in as executable, and with
  # the local owner's name. Under nmake, cmd reads a "/" after a word as a switch, so the
  # script's path takes DFSEP.
  dist => {
    TARFLAGS => '--owner=0 --group=0 --mode=a-x,u=rwX,go=rX -cvf',
    PREOP    => '$(PERL) tools$(DFSEP)check-changes.pl $(VERSION) $(DISTVNAME)$(DFSEP)Changes',
  },
  META_MERGE => {
    'meta-spec'    => { version => 2 },
    dynamic_config => 0,
    no_index       => { directory => ['t', 'xt'] },
    provides       => versioned_packages(),
    prereqs        => {

      # Crypt::OpenSSL::RSA signs for Public Key Client Validation only. 0.33 and 0.34 work
      # too; 0.35 to 0.37 refused the PKCS#1 v1.5 padding that RS256 needs.
      runtime => { recommends => { 'Cpanel::JSON::XS' => '0', 'Crypt::OpenSSL::RSA' => '0.38' } },
      develop => {
        requires => {
          'Perl::Critic'        => '0',
          'Perl::Tidy'          => '20260826',
          'Test::Pod'           => '1.52',
          'Test::Pod::Coverage' => '1.10',
        },
      },
    },
    resources => {
      license    => ['https://opensource.org/license/mit'],
      homepage   => 'https://github.com/Zarabozo/Twilio',
      bugtracker => { web => 'https://github.com/Zarabozo/Twilio/issues' },
      repository => {
        type => 'git',
        url  => 'https://github.com/Zarabozo/Twilio.git',
        web  => 'https://github.com/Zarabozo/Twilio',
      },
    },
  },
);

# With a provides list in META, PAUSE indexes from it and stores each file as written here.
# Without one, it stores the path under the distribution's directory, and the longest goes
# over the 128 characters of PAUSE's packages.file: indexing then fails with a database
# error. Only the package that owns each file is listed, the one with a $VERSION; its List,
# Context, Instance and Page classes are never installed by name.
sub versioned_packages {
  my $found = Module::Metadata->provides(dir => 'lib', version => 2, prefix => 'lib');
  my %provides;
  for my $package (grep { defined $found->{$_}{version} } keys %{$found}) {
    my %entry = %{ $found->{$package} };
    $entry{file} =~ tr{\\}{/};    # Module::Metadata joins with the native separator
    $provides{$package} = \%entry;
  }
  return \%provides;
}
