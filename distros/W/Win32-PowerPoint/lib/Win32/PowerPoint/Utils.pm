package Win32::PowerPoint::Utils;

use strict;
use warnings;
use Exporter 'import';
use Carp;

our @EXPORT_OK = qw(
  RGB
  canonical_alignment
  canonical_pattern
  canonical_datetime
  convert_cygwin_path
  _defined_or
);

sub _defined_or {
  my ($target, $alternative) = @_;

  return defined $target ? $target : $alternative;
}

sub RGB {
  my @color;

  if ( @_ == 1 && !ref $_[0] ) { # combined string such as '255, 255, 255'
    my $str = shift;

    $str =~ s/^RGB//i;
    $str =~ tr/()//d;
    @color = _check_colors( split /[\s,]+/, $str );
  }
  elsif ( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
    @color = _check_colors( @{ $_[0] } );
  }
  elsif ( @_ == 3 ) {
    @color = _check_colors( @_ );
  }

  croak "wrong color specification" unless @color == 3;

  return $color[2] * 65536 + $color[1] * 256 + $color[0];
}

sub _check_colors {
  my @colors = @_;

  return map  { $_ = 0 if $_ < 0; $_ = 255 if $_ > 255; $_ }
         grep { defined $_ && /^\d+$/ }
         @colors;
}

sub canonical_alignment {
  my $align = shift;

  $align =~ s/^(?:pp)?align(?:ment)?//gi;
  $align = 'ppAlign' . (ucfirst lc $align);
  $align = 'ppAlignCenter'    if $align eq 'ppAlignCentre';
  $align = 'ppAlignmentMixed' if $align eq 'ppAlignMixed';

  $align;
}

sub canonical_pattern {
  my $pattern = shift;

  $pattern =~ s/^(?:mso)?Pattern//gi;
  $pattern =~ s/_([a-z])/\U$1\E/g;
  $pattern =~ s/(^|[0-9])([a-z])/$1\U$2\E/g;
  $pattern = "msoPattern$pattern";

  $pattern;
}

sub canonical_datetime {
  my $pattern = shift;

  $pattern =~ s/^(?:pp)?DateTime//gi;
  $pattern ="ppDateTime$pattern";
  $pattern;
}

sub convert_cygwin_path {
  my $path = shift;
  return $path unless $^O eq 'cygwin';
  return Cygwin::posix_to_win_path($path, 'absolute') if $] >= 5.010;
  require Filesys::CygwinPaths;
  return Filesys::CygwinPaths::fullwin32path($path);
}

1;

__END__

=head1 NAME

Win32::PowerPoint::Utils - Utility class

=head1 DESCRIPTION

This is used internally in L<Win32::PowerPoint>.

=head1 FUNCTIONS

=head2 RGB

Computes RGB color number from an array(ref) of RGB components or
color string like '255, 255, 255'. See also L<Win32::PowerPoint>.

=head2 canonical_alignment, canonical_pattern, canonical_datetime

Return canonicalized alignment/pattern/datetime format name to get constant's value.

=head2 convert_cygwin_path

Converts a Cygwin-ish path to a Windows-ish path.

=head1 SEE ALSO

L<Win32::PowerPoint>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
