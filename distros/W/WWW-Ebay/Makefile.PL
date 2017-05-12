
# $Id: Makefile.PL,v 1.43 2014-09-09 03:33:01 Martin Exp $

use inc::Module::Install;
use strict;

all_from('lib/WWW/Ebay.pm');

test_requires('Bit::Vector' => 0);
requires('Bit::Vector');
requires('Carp');
requires('Crypt::SSLeay');
test_requires('Data::Dumper');
requires('Data::Dumper');
test_requires('Date::Manip');
requires('Date::Manip');
requires('File::Glob');
requires('File::Spec');
requires('HTML::Form');
requires('HTML::Parser' => 3);
requires('HTML::TreeBuilder');
requires('HTTP::Cookies');
requires('HTTP::Request::Common');
test_requires('IO::Capture::Stderr');
requires('LWP::Simple');
requires('LWP::UserAgent');
test_requires('Test::More');
# Tk is only needed for Email::editor()
recommends('Tk' => 800);
requires('URI');
# We need the version that defines _load_env_useragent:
requires('WWW::Search' => 2.525);
# We need the version that has the shipping() method:
requires('WWW::SearchResult' => 2.070);
# We need the version that processes columns dynamically:
requires('WWW::Search::Ebay' => 2.267);
# We need the bug-fixed version of WWW::Search::Test with test_most():
test_requires('WWW::Search::Test' => 2.290);

author_tests('xt');

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  warn "DDD before WriteAll, this is author's development environment\n";
  use_ptar();
  } # if

WriteAll;

my @asNeeded;
foreach my $s (qw( EBAY_USERID EBAY_PASSWORD ))
  {
  push @asNeeded, $s unless ($ENV{$s} ne '');
  } # foreach
if (@asNeeded)
  {
  print STDERR join("\n", '',
                    q{In order to run all the automatic tests for this distribution,},
                    q{you should set the following environment variables:},
                    @asNeeded, '', '');
  } # if

sub MY::postamble
  {
  my $ret = <<'PART0';
coverage :
	- cover -delete
	$(MAKE) HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover
PART0
  return $ret;
  } # MY::postamble

use Env;
if (0 && $ENV{MTHURN_PERL_DEV})
  {
  print "DDD after WriteAll, this is author's development environment\n";
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

