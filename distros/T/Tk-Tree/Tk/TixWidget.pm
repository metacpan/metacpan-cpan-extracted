#
# TixWidget -- General tix methods.
#
# Chris Dean <ctdean@cogit.com> 

package Tk::TixWidget;

use strict;

use Tk;
use Tk::Submethods ( 'tixEvent' => [qw(type)] );

sub tixEvent {
    my $w = shift;
    my $option = shift;
    my $data = $w->privateData( "Tk::TixWidget" );
    
    $data->{$option} = shift if @_;
    return( $data->{$option} );
}

use vars qw( %Images %IMAGE_METHODS );

%IMAGE_METHODS = ( 
    xpm => "Pixmap",
    gif => "Photo",
    ppm => "Photo",
    xbm => "Bitmap"
);

sub tixGetimage {
    my( $w, $name ) = @_;

    return( $Images{$name} ) if $Images{$name};

    foreach my $type (qw( xpm gif ppm xbm )) {
        my $method = $IMAGE_METHODS{$type};
        my $file = Tk->findINC( "$name.$type" );
        next unless( $file && $method );
        $Images{$name} = $w->$method( -file => $file );
        return( $Images{$name} );
    }

    # Try built-in bitmaps
    $Images{$name} = $w->Pixmap( -id => $name );
    return( $Images{$name} );
}

1;

__END__

=head1 NAME

Tk::TixWidget - methods for Tix widgets

=head1 SYNOPSIS

    use Tk::TixWidget;
    @ISA = qw(Tk::Widget Tk::TixWidget);

=head1 DESCRIPTION

C<Tk::TixWidget> provides methods that emulate the those used by
Tcl/Tix widgets.  There are currently only two methods supported:
C<tixEvent> and C<tixGetimage>.

=head1 tixGetimage( name )

Given I<name>, look for an image file with that base name and return
a C<Tk::Image>.  File extensions are tried in this order: F<xpm>,
F<gif>, F<ppm>, F<xbm> until a valid iamge is found.  If no image is
found, try a builtin image with that name.

=head1 tixEvent( option, ?value? )

Return or set the tixEvent variable C<option>.  Currently, the only
C<option> used is "type".

=head1 AUTHOR

Chris Dean E<lt>F<ctdean@cogit.com>E<gt>

=cut
