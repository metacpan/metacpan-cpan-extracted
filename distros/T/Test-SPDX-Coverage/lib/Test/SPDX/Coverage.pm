package Test::SPDX::Coverage;
use strict;
use warnings;
use License::SPDX;
use Test::Builder;
use base qw{Exporter};

# SPDX-License-Identifier: MIT

our $VERSION = '0.05';
our @EXPORT  = qw{spdx_coverage_ok};

=encoding utf8

=head1 NAME

Test::SPDX::Coverage - Perl Test Harness to verify all matched files in Manifest have a SPDX-License-Identifier

=head1 SYNOPSIS

  #File: t/spdx-coverage.t
  use Test::More;
  eval "use Test::SPDX::Coverage";
  plan skip_all => "Test::SPDX::Coverage required for testing SPDX-License-Identifier coverage" if $@;
  spdx_coverage_ok();

=head1 DESCRIPTION

Test::SPDX::Coverage reads your manifest for .pm, .pl, .cgi files then searches for a SPDX-License-Identifier.  Once found, the License specified on the SPDX-License-Identifier line is extracted and verified against the L<License::SPDX> database.

For Perl source code, the SPDX-License-Identifier must be formatted like this:

  # SPDX-License-Identifier: LICENSE

Examples:

  # SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later
  # SPDX-License-Identifier: MIT

Essentially, this is a wrapper around License::SPDX->new->check_license($license_string, {check_type => "name"}) for all Perl files in your MANIFEST.

=head2 EXPORT

=head3 spdx_coverage_ok

  spdx_coverage_ok();
  spdx_coverage_ok({diag => 99}); #diag level 0-9
  spdx_coverage_ok({manifest => "MANIFEST", match=>qr/\.(?:pm|pl|cgi)\Z/, lines=>500, diag => 0}); #defaults 

=cut

sub spdx_coverage_ok {
  my $opt = shift    || {};
  die("Syntax: spdx_coverage_ok() or spdx_coverage_ok({})") unless ref($opt) eq 'HASH';

  $opt->{'manifest'} ||= "MANIFEST";
  die(sprintf('Error: option "manifest" invalid. File "%s" not found.'   , $opt->{'manifest'})) unless -f $opt->{'manifest'};
  die(sprintf('Error: option "manifest" invalid. File "%s" not readable.', $opt->{'manifest'})) unless -r $opt->{'manifest'};

  my $match = $opt->{'match'} ||= qr/\.(?:pm|pl|cgi)\Z/;
  die(sprintf('Error: option "match" invalid. Value "%s" must be a regular expression (e.g., qr//).', $match)) unless ref($match) eq "Regexp";

  my $lines = $opt->{'lines'} ||= 500; #the identifier is susposed to be in the "header" comments
  $lines   += 0;
  die(sprintf('Error: option "lines" invalid. Value "%s" must be greater than zero.', $lines)) unless $lines > 0;

  my $diag = $opt->{'diag'} ||= 0; $diag+=0;
  my $Test = $opt->{'builder'} ||= Test::Builder->new;
  $Test->diag("Start") if $diag > 1;
  my @filenames = ();
  $Test->diag(sprintf("Opening manifest file: %s", $opt->{'manifest'})) if $diag > 2;
  #TODO: Use a package to read MANIFEST e.g. Module::Manifest
  { #gather files for test plan count
    my $fh;
    open($fh, '<', $opt->{'manifest'}) or die(sprintf('Error: option "manifest" invalid. File "%s" could not be opened.', $opt->{'manifest'}));
    $Test->diag(qq{Reading manifest file}) if $diag > 3;
    while (my $entry = <$fh>) {
      $entry =~ s/\A\s*//; #ltrim - is this valid?
      next if $entry =~ m/\A#/; #comments
      $entry =~ s/\s*\Z//; #rtrim - instead of chomp for cross platform file support
      $entry =~ s/\s.*\Z//; #strip comments - format is filename {whitespace} comment - #TODO: support quoted filenames with whitespace
      $Test->diag("Filename: $entry") if $diag > 4;
      if ($entry =~ $match) {
        $Test->diag("Filename: $entry, Action: Adding, Reason: File matches regular expression.") if $diag > 2;
        push @filenames, $entry;
      } else {
        $Test->diag("Filename: $entry, File does not match regular expression. Skipping.") if $diag > 5;
      }
    }
    close($fh);
  }
  $Test->diag(sprintf("Files: %s", scalar(@filenames))) if $diag > 3;
  my $test_count = 2;
  $Test->plan(tests => $test_count * @filenames);
  my $license_spdx = License::SPDX->new;
  foreach my $filename (@filenames) {
    $Test->diag("Filename: $filename") if $diag > 1;
    my $found;
    { #scope for $fh
      my $fh;
      open($fh, '<', $filename) or die(sprintf('Error: File "%s" could not be opened for read', $filename));
      my $line_number  = 0;
      foreach my $line_text (<$fh>) {
        $line_number++;
        $line_text =~ s/[\n\r]+\Z//; #chompish
        if ($line_text =~ m/\A\s*#\s*SPDX-License-Identifier:\s*([a-zA-Z0-9 ()+.-]+)\s*\Z/) { #TODO: add c or xml capability i.e. //, /* */, <!-- -->
          my $license_expression = $1;
          $found      = {filename=>$filename, line_number=>$line_number, line_text=> $line_text , license_expression=> $license_expression};
          $Test->diag(qq{Filename: $filename, Line Number: $line_number, Line Text: "$line_text", License Expression: "$license_expression"}) if $diag > 0;
        }
        last if $found;
        last if $line_number >= $lines;
      }
      close($fh);
    }
    if ($found) {
      $Test->ok(1, "SPDX-License-Identifier Found");
      my $license_expression = $found->{'license_expression'}; #might be as expression
      my $separator          = qr/ +(?:AND|OR|WITH) +/;
      my @licenses           = $license_expression=~ $separator ? (split $separator, $license_expression) : ($license_expression);
      my $license_counter    = scalar(@licenses);
      foreach my $license (@licenses) {
        my $check = $license_spdx->check_license($license) ? 1 : 0; #convert Boolean to 1/0
        $Test->diag("License: $license, Check: $check") if $diag > 1;
        $license_counter-- if $check;
      }
      $Test->ok($license_counter == 0, "SPDX-License-Identifier license expression is valid");
    } else {
      $Test->ok(0, "SPDX-License-Identifier was not found.");
      $Test->skip("SPDX-License-Identifier license was not found.");
    }
  }
  $Test->diag("Finish") if $diag > 1;
}

=head1 SEE ALSO

L<License::SPDX>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Michael Davis, Michal Josef Špaček

MIT

=cut

1;
