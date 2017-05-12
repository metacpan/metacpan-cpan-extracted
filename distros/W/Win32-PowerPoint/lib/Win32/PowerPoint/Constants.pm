package Win32::PowerPoint::Constants;

use strict;
use Carp;

our $VERSION = '0.10';

our $AUTOLOAD;

sub new {
  my $class = shift;
  bless {

# ppSlideLayout
    ppLayoutBlank => 12,
    ppLayoutText  => 2,
    ppLayoutTitle => 1,

# ppAutoSize
    ppAutoSizeNone           => 0,
    ppAutoSizeShapeToFitText => 1,
    ppAutoSizeMixed          => -2,

# ppSaveAsFileType
    ppSaveAsPresentation => 1,
    ppSaveAsShow         => 7,

# ppParagraphAlignment
    ppAlignLeft       => 1,
    ppAlignCenter     => 2,
    ppAlignRight      => 3,
    ppAlignJustitfy   => 4,
    ppAlignDistribute => 5,
    ppAlignmentMixed  => -2,

# ppMouseActivation
    ppMouseClick => 1,
    ppMouseOver  => 2,

# ppDateTimeFormat
    ppDateTimeMdyy           => 1,
    ppDateTimeddddMMMMddyyyy => 2,
    ppDateTimedMMMMyyyy      => 3,
    ppDateTimeMMMMdyyyy      => 4,
    ppDateTimedMMMyy         => 5,
    ppDateTimeMMMMyy         => 6,
    ppDateTimeMMyy           => 7,
    ppDateTimeMMddyyHmm      => 8,
    ppDateTimeMMddyyhmmAMPM  => 9,
    ppDateTimeHmm            => 10,
    ppDateTimeHmmss          => 11,
    ppDateTimehmmAMPM        => 12,
    ppDateTimehmmssAMPM      => 13,
    ppDateTimeFormatMixed    => -2,

# msoPatternType
    msoPattern10Percent              => 2,
    msoPattern20Percent              => 3,
    msoPattern25Percent              => 4,
    msoPattern30Percent              => 5,
    msoPattern40Percent              => 6,
    msoPattern50Percent              => 7,
    msoPattern5Percent               => 1,
    msoPattern60Percent              => 8,
    msoPattern70Percent              => 9,
    msoPattern75Percent              => 10,
    msoPattern80Percent              => 11,
    msoPattern90Percent              => 12,
    msoPatternDarkDownwardDiagonal   => 15,
    msoPatternDarkHorizontal         => 13,
    msoPatternDarkUpwardDiagonal     => 16,
    msoPatternDarkVertical           => 14,
    msoPatternDashedDownwardDiagonal => 28,
    msoPatternDashedHorizontal       => 32,
    msoPatternDashedUpwardDiagonal   => 27,
    msoPatternDashedVertical         => 31,
    msoPatternDiagonalBrick          => 40,
    msoPatternDivot                  => 46,
    msoPatternDottedDiamond          => 24,
    msoPatternDottedGrid             => 45,
    msoPatternHorizontalBrick        => 35,
    msoPatternLargeCheckerBoard      => 36,
    msoPatternLargeConfetti          => 33,
    msoPatternLargeGrid              => 34,
    msoPatternLightDownwardDiagonal  => 21,
    msoPatternLightHorizontal        => 19,
    msoPatternLightUpwardDiagonal    => 22,
    msoPatternLightVertical          => 20,
    msoPatternMixed                  => -2,
    msoPatternNarrowHorizontal       => 30,
    msoPatternNarrowVertical         => 29,
    msoPatternOutlinedDiamond        => 41,
    msoPatternPlaid                  => 42,
    msoPatternShingle                => 47,
    msoPatternSmallCheckerBoard      => 17,
    msoPatternSmallConfetti          => 37,
    msoPatternSmallGrid              => 23,
    msoPatternSolidDiamond           => 39,
    msoPatternSphere                 => 43,
    msoPatternTrellis                => 18,
    msoPatternWave                   => 48,
    msoPatternWeave                  => 44,
    msoPatternWideDownwardDiagonal   => 25,
    msoPatternWideUpwardDiagonal     => 26,
    msoPatternZigZag                 => 38,

# msoTextOrientation
    msoTextOrientationHorizontal => 1,

# msoTriState
    msoTrue  => -1,
    msoFalse => 0,

  }, $class;
}

sub AUTOLOAD {
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  if (exists $self->{$name})      { return $self->{$name}; }
  if (exists $self->{"pp$name"})  { return $self->{"pp$name"}; }
  if (exists $self->{"mso$name"}) { return $self->{"mso$name"}; }
  croak "constant $name does not exist";
}

sub DESTROY {}

1;
__END__

=head1 NAME

Win32::PowerPoint::Constants - Constants holder

=head1 DESCRIPTION

This is used internally in L<Win32::PowerPoint>.

=head1 METHOD

=head2 new

Creates an object.

=head1 SEE ALSO

PowerPoint's object browser and MSDN documentation.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
