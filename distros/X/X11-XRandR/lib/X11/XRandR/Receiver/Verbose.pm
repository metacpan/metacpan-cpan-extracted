package X11::XRandR::Receiver::Verbose;

# ABSTRACT: The Pegex Receiver for L<X11::XRandR::Grammar::Verbose>

#pod =for Pod::Coverage *EVERYTHING*
#pod
#pod =cut

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Memoize;

use base 'Pegex::Tree';

use Module::Runtime qw[ require_module ];

use String::CamelCase qw[ camelize ];

use Data::Dump qw[ dd pp ];

use X11::XRandR::CurMode;

our %NameMap = ( dimension_mm => 'dimension', );

sub remove_empty_arrays {
    scalar [ map { 'ARRAY' eq ref $_ ? ( @{$_} ? $_ : () ) : $_ } @{ $_[0] } ];
}

sub merge_hashes {
    scalar { map { %{$_} } @{ $_[0] } };
}

# cache module existence so that if the module doesn't exist, we don't
# keep looking for it.
memoize( '_require_module' );
sub _require_module {
    my $name = 'X11::XRandR::' . camelize( $_[0] );
    return $name if eval { require_module( $name ); 1; };
    return;
}

sub gotrule {
    my $self = shift;
    @_ || return ();

    my $res = $_[0];
    return
      if 'ARRAY' eq ref $res && !@$res || 'HASH' eq ref $res && !keys %$res;

    my $name = $self->{parser}{rule};

    if ( defined $NameMap{$name} ) {
        $name = $NameMap{$name};
    }
    else {
        $name
          =~ s/^(EDID|frequency|screen|output_header|output|mode|cur_mode)_//;
    }

    my ( $module_name )
      = map { _require_module( $_ ) || () } $self->{parser}{rule},
      $name;

    if ( defined $module_name ) {
        $res = eval { $module_name->new( $_[0] ) };
        if ( $@ ) {
            $res = $_[0];
            $self->{parser}->throw_error(
                "error instantiating $module_name from @{[ pp $_[0] ]}\n$@\n" );
        }
    }

    return $self->{parser}{parent}{-wrap}
      ? { $name => $res }
      : $res;
}

sub gotrule_boolean {
    my $self = shift;
    $self->gotrule( !!@{ $_[0] } );
}


sub gotrule_unwrap_array {
    my $self = shift;
    $self->gotrule( $_[0][0] );
}


sub gotrule_merge_hashes {
    my $self = shift;

    my $hash = merge_hashes( remove_empty_arrays( shift ) );
    return unless keys %$hash;
    $self->gotrule( $hash );
}

sub dump_match {
    my $self = shift;
    dd \@_;
    $self->gotrule( @_ );
}

sub got_screen_dims {
    my $self = shift;

    my %dim = map { $_->[0] => $_->[1] } @{ $_[0] };
    return $self->gotrule( {
        max_dim => delete $dim{maximum}{dimension},
        min_dim => delete $dim{minimum}{dimension},
        cur_dim => delete $dim{current}{dimension},
    } );
}

*got_state = \&gotrule_merge_hashes;

#<<< no perltidy
*got_Border =
*got_Brightness =
*got_CRTC =
*got_CRTCs =
*got_Clones =
*got_Gamma =
*got_Identifier =
*got_Panning =
*got_Subpixel =
*got_Timestamp =
*got_Tracking =
*got_filter =
*got_hSync =
*got_vSync =
*got_panning =
*got_property_EDID =
*got_ranges =
*got_supported =
\&gotrule_unwrap_array;
#>>> no perltidy

#<<< no perltidy
*got_border_values =
*got_cur_crtc =
*got_cur_mode =
*got_dimension =
*got_frequency =
*got_geometry =
*got_output =
*got_output_header =
*got_screen =
*got_xrandr =
\&gotrule_merge_hashes;
#>>> no perltidy

#<<< no perltidy
*got_mode_current =
*got_mode_preferred =
*got_output_primary =
\&gotrule_boolean;
#>>> no perltidy

sub got_float {
    my $self = shift;
    $_[0] += 0;
    $self->gotrule( @_ );
}

sub got_property {
    my $self = shift;

    my %property;
    @property{ 'name', 'value' } = @{ $_[0][0] };

    if ( @{ $_[0] } > 1 ) {
        die( "expected exactly one key in property acceptable values:",
            dd $_[0][1] )
          if keys %{ $_[0][1] } != 1;
        my ( $key, $values ) = each %{ $_[0][1] };
        $property{$key} = $values;
    }
    $self->gotrule( \%property );
}

sub got_dimension_mm {
    my $self = shift;
    my $hash = merge_hashes( shift );
    $hash->{unit} = 'mm';
    $self->gotrule( $hash );
}

sub got_offset {
    my $self = shift;

    my ( $xm, $x, $ym, $y ) = @{ $_[0] };

    $x *= -1 if $xm eq '-';
    $y *= -1 if $ym eq '-';

    $self->gotrule( { x => $x, y => $y } );
}

sub got_Transform {
    my $self   = shift;
    my @values = @{ $_[0][0] };
    return $self->gotrule( {
            matrix =>
              [ map { [ @values[@$_] ] }[ 0, 1, 2 ], [ 3, 4, 5 ], [ 6, 7, 8 ] ],
            filter => $_[0][1] } );
}

sub got_hexint {
    my $self = shift;
    $self->gotrule( hex $_[0] );
}

sub got_cur_mode_reflection {
    my $self = shift;
    $self->gotrule( X11::XRandR::CurMode->map_reflection_in( $_[0] ) );
}

sub got_output_header_reflections {
    my $self = shift;

    s/\s*axis// for @{ $_[0] };

    $self->gotrule( @_ );
}

sub got_mode {

    my $self = shift;

    my $hash = merge_hashes( remove_empty_arrays( @_ ) );
    my ( $hMode, $vMode )  = map { merge_hashes( delete $hash->{$_} ) } qw[ hMode vMode ];

    @{$hash}{keys %$hMode} = values %$hMode;
    @{$hash}{keys %$vMode} = values %$vMode;

    $self->gotrule( $hash );
}


1;

#
# This file is part of X11-XRandR
#
# This software is Copyright (c) 2018 by Diab Jerius.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

X11::XRandR::Receiver::Verbose - The Pegex Receiver for L<X11::XRandR::Grammar::Verbose>

=head1 VERSION

version 0.01

=for Pod::Coverage *EVERYTHING*

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=X11-XRandR> or by email
to L<bug-X11-XRandR@rt.cpan.org|mailto:bug-X11-XRandR@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/x11-xrandr>
and may be cloned from L<git://github.com/djerius/x11-xrandr.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<X11::XRandR|X11::XRandR>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Diab Jerius.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
