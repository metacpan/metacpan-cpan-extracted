# $Id: 0_versions.t,v 1.6 2013-11-19 03:33:28 Martin Exp $

use strict;
use warnings;

use Config;
use Test::More tests => 1;

# Create a list of modules we're interested in:
my @asModule = qw( Date::Manip File::Copy File::Find File::Spec Getopt::Long HTML::Parser HTML::TreeBuilder HTTP::Cookies LWP::UserAgent MIME::Lite Net::Domain Pod::Parser Pod::Tests Pod::Usage Test::Inline URI User );

# Extract the version number from each module:
my %hsvVersion;
foreach my $sModule (@asModule)
  {
  eval " require $sModule; ";
  unless($@)
    {
    no strict 'refs';
    $hsvVersion{$sModule} = ${$sModule .'::VERSION'} || "unknown";
    } # unless
  } # foreach

# Also look up the version number of perl itself:
$hsvVersion{perl} = $Config{version} || $];

# Print on STDERR details of installed modules:
diag('');
diag(sprintf("\r#  %-30s %s\n", 'Module', 'Version'));
foreach my $sModule (sort keys %hsvVersion)
  {
  $hsvVersion{$sModule} = 'Not Installed' unless(defined($hsvVersion{$sModule}));
  diag(sprintf(" %-30s %s\n", $sModule, $hsvVersion{$sModule}));
  } # foreach

# Make sure this file passes at least one test:
pass;
exit 0;
__END__
