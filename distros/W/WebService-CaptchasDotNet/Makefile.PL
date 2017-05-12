use 5.006;

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'              => 'WebService::CaptchasDotNet',
  'VERSION_FROM'      => 'CaptchasDotNet.pm',
  'PREREQ_PM'         => { 'Digest::MD5' => 0,
                           'IO::File'    => 0,
                           'IO::Dir'     => 0,
                           'File::Spec'  => 0,
                           'File::Path'  => 0,
                           'Cwd'         => 0, },
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

warn $@ if $@;

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
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover
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
