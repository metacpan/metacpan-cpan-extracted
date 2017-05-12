
# $Id: Makefile.PL,v 1.1.1.1 2008/01/22 03:42:21 Daddy Exp $

use inc::Module::Install;

name('Tk-Wizard-Sizer');
abstract('Helps you determine best size for your Tk-Wizard application');
version(2.224);
author(q{Martin 'Kingpin' Thurn <mthurn@cpan.org>});
license('perl');

requires("Carp");
build_requires("Data::Dumper");
build_requires("ExtUtils::testlib");
build_requires("IO::Capture::Stdout::Extended");
build_requires("Test::More");
build_recommends('Test::Pod');
build_recommends('Test::Pod::Coverage');
build_requires('Tk');
requires('Tk::Wizard');

WriteAll;

sub MY::postamble
  {
  return <<'PART0';
coverage :
	- cover -delete
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
  } # MY::postamble

__END__
