
use inc::Module::Install;
include 'Module::AutoInstall';

version(3.056);
all_from('lib/WWW/Search/Ebay.pm');

requires(perl => 5.005);
test_requires('Bit::Vector');
requires('Date::Manip');
# requires('DateTime::TimeZone');
test_requires('Date::Manip');
requires('HTML::TreeBuilder');
test_requires('IO::Capture::Stderr');
requires('LWP::Simple');
# Test::More is needed for `make test`:
test_requires('Test::More');
# We need the version where approximate_result_count() can return undef:
requires('WWW::Search' => 2.566);
# We need the version that has the bidder and seller methods:
requires('WWW::SearchResult' => 2.067);
# We need the version of WWW::Search::Test that checks for undefined approximate result count:
test_requires('WWW::Search::Test' => 2.294);

author_tests('xt');

my $ret = <<'PART0';
coverage :
	$(RM_RF) cover_db/*
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
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
  my $sFnameMakefile = q{Makefile};
  eval "use File::Slurp";
  my $s = read_file($sFnameMakefile);
  if ($s !~ s/(DIRFILESEP\s*=\s*).+$/$1\//m)
    {
    warn " EEE did not find DIRFILESEP in Makefile\n";
    } # if
  if ($s !~ s/(pm_to_blib\()\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find pm_to_blib@ARGV in Makefile\n";
    } # if
  if ($s !~ s/(from_to\s+=>\s+)\{\{\@ARGV\}\}/$1 . '{@ARGV}'/e)
    {
    warn " EEE did not find from_to@ARGV in Makefile\n";
    } # if
  write_file($sFnameMakefile, $s);
  } # if

__END__

