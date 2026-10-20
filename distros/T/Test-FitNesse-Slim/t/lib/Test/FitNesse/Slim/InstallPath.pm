package Test::FitNesse::Slim::InstallPath;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter qw(import);
use File::Spec;

our @EXPORT_OK = qw(verify_installed_path);

sub verify_installed_path {
  my ($actual, $expected, $prefix, $label) = @_;
  $label = 'installed file' unless defined($label) && length($label);
  die "$label: actual path is required" unless defined $actual;
  die "$label: expected path is required" unless defined $expected;
  die "$label: installation prefix is required" unless defined $prefix;
  die "$label: actual file is missing: $actual" unless -f $actual;
  die "$label: expected file is missing: $expected" unless -f $expected;
  die "$label: installation prefix is missing: $prefix" unless -d $prefix;

  my $actual_path = abs_path($actual)
    or die "$label: cannot resolve actual path $actual";
  my $expected_path = abs_path($expected)
    or die "$label: cannot resolve expected path $expected";
  my $prefix_path = abs_path($prefix)
    or die "$label: cannot resolve installation prefix $prefix";

  my $relative = File::Spec->abs2rel($expected_path, $prefix_path);
  my @parts = File::Spec->splitdir($relative);
  die "$label: expected path is outside installation prefix: $expected_path"
    if File::Spec->file_name_is_absolute($relative)
      || !@parts || $parts[0] eq File::Spec->updir;
  die "$label: loaded from unexpected location: $actual_path (expected $expected_path)"
    unless $actual_path eq $expected_path;

  return $actual_path;
}

1;

__END__

=head1 NAME

Test::FitNesse::Slim::InstallPath - Validate installed files by resolved path

=head1 DESCRIPTION

Provides a strict path check for the distribution installation smoke test.
Both loaded and expected paths are resolved before comparison, so filesystem
aliases such as macOS C</var> and C</private/var> identify the same file.
The expected file must also resolve beneath the installation prefix.

=head1 FUNCTIONS

=head2 verify_installed_path($actual, $expected, $prefix, $label)

Returns the canonical actual path when both paths resolve to the same file and
the expected file is beneath the resolved prefix. Dies with a specific error
when any path is missing, the expected file is outside the prefix, or the
loaded file differs.

=cut
