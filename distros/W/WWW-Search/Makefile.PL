# This -*- cperl -*- program writes the Makefile for WWW::Search

use lib '.';

use inc::Module::Install;

version(2.519);
all_from('lib/WWW/Search.pm');
perl_version(5.005);
license('perl');

install_script('Programs/AutoSearch');
install_script('Programs/WebSearch');

# These are needed for AutoSearch:
requires('Data::Dumper');
requires('Date::Manip');
recommends('Email::Send');
recommends('Email::MIME');
recommends('Email::MIME::Creator');
requires('File::Copy');
requires('Getopt::Long' => 2.24);
requires('POSIX');
# These are needed for WebSearch:
requires('Getopt::Long' => 2.24);
# These are needed for WWW::Search base module and sub-modules:
requires('CGI');
requires('File::Basename');
requires('File::Find');
requires('File::Path');
requires('File::Slurp');
requires('File::Spec');
requires('HTML::Parser' => 2.23);
requires('HTML::TreeBuilder');  # HTML-Tree-0.51 is good
requires('LWP::UserAgent' => 2.0);
requires('LWP::MemberMixin');
requires('Net::Domain');
requires('Pod::Usage');
requires('URI');
requires('URI::Escape');
requires('User');
# These are used by WWW::Search::Test:
requires('Bit::Vector');
requires('Date::Manip');
requires('File::Path');
requires('File::Slurp');
requires('File::Spec');
requires('Test::More');
# These are needed during `make test`:
test_requires('File::Temp');
test_requires('IO::Capture::Stderr');
test_requires('Test::File');
test_requires('Test::More');
recommends('Test::Pod');
recommends('Test::Pod::Coverage');
# I think there's a bug in Module::CoreList or something, because this
# comes up missing on some platforms:
test_requires('Test::Simple');
# For the defunct test_parsing rule, we need a version that sets
# FULLPERLRUNINST:
test_requires('ExtUtils::MM_Unix' => 1.41);

sub MY::preamble
  {
  # This does not work because MakeMaker apparently does not have a
  # preamble method.
  return <<'PREAMBLE';
AutoSearch :: FORCE
	/bin/rm -f AutoSearch
PREAMBLE
  } # MY::preamble

  my $ret = q{};
  if (1)
    {
    $ret .= <<'PART0';
coverage :
	- cover -delete
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
    } # if
  if (0)
    {
    $ret .= <<'PART2';
test_parsing : pure_all
	$(FULLPERLRUNINST) t/test_parsing.pl $(TEST_ARGS)

PART2
    } # if
  if (1)
    {
    $ret .= <<'PART3';
tags:
	cat MANIFEST | etags -

PART3
    } # if
  postamble $ret;

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  warn "DDD This is author's development environment\n";
  use_ptar();
  } # if

WriteAll;

if (0 && $ENV{MTHURN_PERL_DEV})
  {
  print "DDD This is author's development environment\n";
  my $sFnameMakefile = q{Makefile};
  eval "use File::Slurp";
  my $s = read_file($sFnameMakefile);
  if ($s !~ s/(DIRFILESEP\s*=\s*).+$/$1\//m)
    {
    print " EEE did not find DIRFILESEP in Makefile\n";
    } # if
  if ($s !~ s/(pm_to_blib\()\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    print " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+)\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    print " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__

