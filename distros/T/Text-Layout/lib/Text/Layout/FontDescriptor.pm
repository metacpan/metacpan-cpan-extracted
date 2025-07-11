#! perl

use strict;
use warnings;
use utf8;

package Text::Layout::FontDescriptor;

use Carp;

 our $VERSION = "0.045";

=head1 NAME

Text::Layout::FontDescriptor - font description for Text::Layout

=head1 SYNOPSIS

Font descriptors are used internally by Text::Layout and
Text::Layout::FontConfig.

=cut

=head1 METHODS

=over

=item new( [ %atts ] )

Creates a new FontDescriptor object.

Attributes:

=over

=item family

=item style

=item weight

The Family, style, and weight of this font. There are mandatory. For
defaults, use an empty string.

=item size

Optional, font size.

=item font

The actual font data.

=item loader

A code reference to call to actually create/load the font if necessary.

Loading will store the font data in the C<font> property.

=back

=back

=cut

sub new {
    my ( $pkg, %atts ) = @_;
    my $self = bless { style => "",
		       weight => "",
		       %atts } => $pkg;

    return $self;
}

=over

=item get_font

Returns the actual font data for the font this descriptor describes.

If necessary, the backend will be called to create/load the font.

=back

=cut

sub get_font {
    my ( $self, $context ) = @_;
    $self->{font} ||= do {
	croak("Forgot to pass a layout context to get_font?")
	  unless UNIVERSAL::isa( $context, 'Text::Layout' );
	$context->load_font( $self->{loader_data}, $self );
    };
}

=over

=item get_family

=item get_style

=item get_weight

Accessors to the font family, style, and weight.

Readonly.

=back

=cut

sub get_family {
    my ( $self ) = @_;
    $self->{family};
}

sub get_style {
    my ( $self ) = @_;
    $self->{style};
}

sub get_weight {
    my ( $self ) = @_;
    $self->{weight};
}

=over

=item set_size

=item get_size

Sets/gets the size property of the font.

=back

=cut

sub set_size {
    my ( $self, $size ) = @_;
    $self->{size} = $size;
}

sub get_size {
    my ( $self ) = @_;
    $self->{size};
}

=over

=item set_direction

=item get_direction

Sets/gets the direction property of the font.

=back

=cut

sub set_direction {
    my ( $self, $direction ) = @_;
    $self->{direction} = $direction;
}

sub get_direction {
    my ( $self ) = @_;
    $self->{direction};
}

# Not documented -- internal use only.

sub set_shaping {
    my ( $self, $sh ) = @_;
    $self->{shaping} = $sh // 1;
}

sub get_shaping {
    my ( $self ) = @_;
    $self->{shaping};
}

# Not documented -- internal use only.

sub set_interline {
    my ( $self, $sh ) = @_;
    $self->{interline} = $sh // 1;
}

sub get_interline {
    my ( $self ) = @_;
    $self->{interline};
}

# Not documented -- internal use only.

# Note that the ascender/descender values are filled in at load time,
# unless overridden by a set_... call.

sub set_ascender {
    my ( $self, $asc ) = @_;
    $self->{ascender} = $asc;
}

sub get_ascender {
    my ( $self ) = @_;
    $self->{ascender};
}

sub set_descender {
    my ( $self, $desc ) = @_;
    $self->{descender} = $desc;
}

sub get_descender {
    my ( $self ) = @_;
    $self->{descender};
}

=over

=item to_string

Returns a Pango-style font string, C<Sans Italic 14>.

=back

=cut

sub to_string {
    my ( $self ) = @_;
    my $desc = ucfirst( $self->{family} );
    $desc .= ucfirst( $self->{style} )
      if $self->{style} && $self->{style} ne "normal";
    $desc .= " " . ucfirst( $self->{weight} )
      if $self->{weight} && $self->{weight} ne "normal";
    $desc .= " " . $self->{size} if $self->{size};
    return $desc;
}

use overload '""' => \&to_string;

=head1 SEE ALSO

L<Text::Layout::FontConfig>, L<Text::Layout>.

=head1 AUTHOR

Johan Vromans, C<< <JV at CPAN dot org> >>

=head1 SUPPORT

This module is part of L<Text::Layout>.

Development takes place on GitHub:
L<https://github.com/sciurius/perl-Text-Layout>.

You can find documentation for this module with the perldoc command.

  perldoc Text::Layout::FontDescriptor

Please report any bugs or feature requests using the issue tracker for Text::Layout on GitHub.

=head1 LICENSE

See L<Text::Layout>.

=cut

1;
