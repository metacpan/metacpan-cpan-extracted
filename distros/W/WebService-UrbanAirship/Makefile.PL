use 5.006;

use strict;

use ExtUtils::MakeMaker;
use File::Find qw(find);

my %directories;

find(sub { return unless m/\.t$/; $directories{$File::Find::name} = 1 }, 't');

my @tests = grep { ! m/live/ } sort keys %directories;


WriteMakefile(
  'NAME'              => 'WebService::UrbanAirship',
  'VERSION_FROM'      => 'lib/WebService/UrbanAirship.pm',
  'PREREQ_PM'         => { 'JSON::XS'       => 0, 
                           'Crypt::SSLeay'  => 0,
                           'LWP::UserAgent' => 0,
                         },
  test         => { TESTS => join ' ', @tests },
);

use constant HAS_APACHE_TEST => eval {
  require Apache::Test;
  require Apache::TestMM;
  require Apache::TestRun;

  Apache::TestMM->import(qw(test clean));
  Apache::TestMM::filter_args();

  my %args = @Apache::TestMM::Argv;
                                                                                                                           
  die 'suitable httpd required'
    unless ($args{apxs} or $args{httpd} or
            $ENV{APACHE_TEST_HTTPD} or $ENV{APACHE_TEST_APXS});

  Apache::TestRun->generate_script();
                                                                                                                             
  return Apache::TestMM->test;
};

sub MY::test {

  my $test = shift->MM::test(@_);

  eval { require Test::More } or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More
EOF

  return HAS_APACHE_TEST if HAS_APACHE_TEST;

  if (eval { require Devel::Cover }) {
    $test .= <<EOF;
testcover ::
\tcover -delete
\tHARNESS_PERL_SWITCHES=-MDevel::Cover make test
\tcover
EOF
  }

  return $test;
}


sub MY::clean {

  if (HAS_APACHE_TEST) {
      require Apache::TestMM;

      return Apache::TestMM::clean(@_);
  }

  return shift->MM::clean(@_);
}

