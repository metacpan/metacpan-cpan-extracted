package mymm;

use strict;
use warnings;
use File::Which qw( which );

# Test::JSON::Diff shells out to jq and diff, and requires jq 1.7 or better
# since earlier versions do not preserve number literals.  If they aren't
# available, bail out without writing a Makefile, which CPAN testers
# reports as N/A rather than FAIL.

sub unsupported
{
  my($reason) = @_;
  print "OS unsupported: $reason\n";
  exit 0;
}

sub myWriteMakefile
{
  my %args = @_;

  my $jq = which('jq');
  unsupported('Test::JSON::Diff requires jq 1.7 or better, which I am unable to find')
    unless defined $jq;

  my $version = do {
    open my $fh, '-|', $jq, '--version' or unsupported("unable to run $jq --version: $!");
    my $line = <$fh>;
    close $fh;
    $line = '' unless defined $line;
    chomp $line;
    $line;
  };

  if($version =~ /^jq-([0-9]+)\.([0-9]+)/)
  {
    my($major, $minor) = ($1, $2);
    unsupported("Test::JSON::Diff requires jq 1.7 or better, found $version at $jq")
      if $major < 1 || ($major == 1 && $minor < 7);
    print "found $version at $jq\n";
  }
  else
  {
    unsupported("unable to determine version of $jq (got '$version')");
  }

  my $diff = which('diff');
  unsupported('Test::JSON::Diff requires diff, which I am unable to find')
    unless defined $diff;
  print "found diff at $diff\n";

  require ExtUtils::MakeMaker;
  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
