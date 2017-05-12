package VS::Chart::Color;

use strict;
use warnings;

use Carp qw(croak);
use List::MoreUtils qw(any);
use Scalar::Util qw(blessed);

use VS::Chart::Color::Gradient;

sub new {
    my $pkg = shift;
    
    if (@_ == 2) {
        my $c1 = $pkg->new(shift);
        my $c2 = $pkg->new(shift);
        
        return VS::Chart::Color::Gradient->new($c1, $c2);
    }
    if (@_ == 1) {
        my $rgba = shift;
        if ($rgba =~ m/^ # [:xdigit:]{6} ([:xdigit:]{2})? $/x) {
            $rgba =~ s/^#//;
            my ($r, $g, $b, $a) = map hex, $rgba =~ /(.{2})/g;
            $a = 255 if !defined $a;
            return $pkg->new($r, $g, $b, $a);
        }
        
        croak "Don't know how to handle '${rgba}'";
    }
    if (@_ == 3) {
        my $a = any { $_ > 1 } @_ ? 255 : 1;
        return $pkg->new(@_, $a);
    }
    if (@_ == 4) {
        my @colors = map { defined $_ ? $_ : 0 } @_;
        if (any { $_ > 1 } @colors ) {
            @colors = map { $_ / 255 } @colors;
        }
        my $self = bless \@colors, $pkg;
        return $self;
    }
    
    croak "Can't create color";
}

sub set {
    my ($self, $cx) = @_;    
    $cx->set_source_rgba(@$self);
}

sub get {
    my ($pkg, $spec, $default) = @_;

    return $pkg->color($default) unless defined $spec;
    return $spec if blessed $spec && $spec->isa("VS::Chart::Color");
    return $pkg->new(@$spec) if ref $spec eq 'ARRAY';
    return $pkg->color($default) if $spec eq '1';
    return $pkg->color($spec) if $spec =~ /^\w+$/;
    
     my $color;
     eval {
         $color = VS::Chart::Color->new($spec);
     };
     $color = $default if $@;
     return $color;    
}

BEGIN {
    my %color = (
        white       => '#ffffffff',
        black       => '#000000ff',
        red         => '#ff0000ff',
        green       => '#00ff00ff',
        blue        => '#0000ffff',
        grid        => '#ccccccff',
        axis        => '#333333ff',
        major_tick  => '#333333ff',
        minor_tick  => '#eeeeeeff',
        text        => '#000000ff',
        border      => '#000000ff',
        
        # Define default colors for 16 series
        dataset_0   => "#2e578cff",
        dataset_1   => "#5d9648ff",
        dataset_2   => "#e7a13dff",
        dataset_3   => "#bc2d30ff",
        dataset_4   => "#6f3d79ff",
        dataset_5   => "#7d807fff",
        dataset_6   => "#41699bff",
        dataset_7   => "#6ea45aff",
        dataset_8   => "#eaad55ff",
        dataset_9   => "#c54346ff",
        dataset_10  => "#814f8bff",
        dataset_11  => "#8e9190ff",
        dataset_12  => "#577caaff",
        dataset_13  => "#80b26eff",
        dataset_14  => "#eeb96dff",
        dataset_15  => "#ce5b5dff",
    );
    
    
    my %Colors;
    while (my ($name, $spec) = each %color) {
        $Colors{$name} = __PACKAGE__->new($spec);
    }
    
    sub color {
        my ($pkg, $name) = @_;
    
        return $name if blessed $name && $name->isa("VS::Chart::Color");
        return $Colors{$name} if exists $Colors{$name};
        return $Colors{black};
    }
}

sub as_hex {
    my $self = shift;
    return sprintf("#%02x%02x%02x", map { int($_ * 255) } @{$self}[0..2]);
}

1;
__END__

=head1 NAME

VS::Chart::Color - Solid colors

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( RED, GREEN, BLUE [, ALPHA ])

=item new ( HEX )

Creates a new instance with the color specified by either specifiying each component. Components should normally be 
defined as a decimal fraction from 0 to 1. Components may also be specified as a value from 0 to 255 but if any compoenent 
is specified as such all components will considered to be specified in the same way.

For simplicitiy it is also possible to specify a hexadecimal string with leading # as HTML. This must be either 6 or 8 
characters long. If it's 8 characters the last two are considered to be alpha.

An alpha value of 1 (255 or #ff) is non-translucent.

=item color ( NAME )

Returns the color with the predefined I<NAME>. 

Predefined colors are (in hexadecimal form without alpha):

 # Colors
 white          #ffffff
 black          #000000
 red            #ff0000
 green          #00ff00
 blue           #0000ff
 
 # Specific items on the chart
 grid           #cccccc
 axis           #333333
 major_tick     #333333
 minor_tick     #eeeeee
 text           #000000
 border         #000000

 # Colors for 16 series which may be repated
 dataset_0      #2e578c
 dataset_1      #5d9648
 dataset_2      #e7a13d
 dataset_3      #bc2d30
 dataset_4      #6f3d79
 dataset_5      #7d807f
 dataset_6      #41699b
 dataset_7      #6ea45a
 dataset_8      #eaad55
 dataset_9      #c54346
 dataset_10     #814f8b
 dataset_11     #8e9190
 dataset_12     #577caa
 dataset_13     #80b26e
 dataset_14     #eeb96d
 dataset_15     #ce5b5d
 
=item get ( [SPEC | COLOR], DEFAULT )

Returns a color either by spec (SEE C<new> above), an existing instance I<COLOR> or the default if I<SPEC> or I<COLOR> couldn't 
be handled correctly or are 1.

=back

=head2 INSTANCE METHODS

=over 4

=item set ( CONTEXT )

Sets the color to be the corrent drawing color for I<CONTEXT>.

=item as_hex 

Returns the color as a hexadecimal formated string suitable for using in CSS. Returned string is 
prefixed with #.

=back

=cut
