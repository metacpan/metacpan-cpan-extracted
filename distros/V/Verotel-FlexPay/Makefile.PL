use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Verotel::FlexPay',
  VERSION_FROM     => 'FlexPay.pm',
  AUTHOR           => 'Verotel dev team',
  MIN_PERL_VERSION => 5.20.3,
  ABSTRACT => 'Unsupported! / This library allows merchants to use Verotel payment gateway and get paid by their users via Credit Card and other payment methods.',
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'Exporter' => 0,
    'Digest::SHA1' => 0,
    'Params::Validate' => 0,
    'Test::Spec' => 0,
    'Test::Exception' => 0,
    'URI::Escape' => 0,
    'URI' => 0,
    'Carp' => 0,
    'utf8' => 0,
  },
);