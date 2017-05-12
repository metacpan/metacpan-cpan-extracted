#############################################################################
## Name:        lib/Wx/DemoModules/wxVListBox.pm
## Purpose:     wxPerl demo helper for Wx::VListBox
## Author:      Mattia Barbon
## Modified by:
## Created:     30/09/2006
## RCS-ID:      $Id: wxVListBox.pm 3043 2011-03-21 17:25:36Z mdootson $
## Copyright:   (c) 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::Html;

package Wx::DemoModules::wxVListBox;

use strict;
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(wxLB_MULTIPLE :id :misc);
use Wx::Event qw(EVT_LISTBOX EVT_LISTBOX_DCLICK);

__PACKAGE__->mk_accessors( qw(htmllistbox) );

my $useversion = ( defined( &Wx::VListBox::HasMultipleSelection ) ) ? 'extended' : 'basic';

sub styles {
    my( $self ) = @_;

    return (  [ wxLB_MULTIPLE, 'Multiple selection' ],
    
             );
}

sub expandinsizer { 1 };

sub create_control {
    my( $self ) = @_;
    
    my $class = ( $useversion eq 'basic' ) ? 'Wx::DemoModules::wxVListBox::Custom' : 'Wx::DemoModules::wxVListBox::CustomExtra';
    
    my $listbox = $class->new( $self, -1, [-1, -1], [400, 400], $self->style );
    
    if( $useversion eq 'basic' ) {
        # Wx <= 0.98
        EVT_LISTBOX( $self, $listbox, \&OnListBox );
        EVT_LISTBOX_DCLICK( $self, $listbox, \&OnListBoxDoubleClick );
    } else {
        # Wx >= 0.99
        EVT_LISTBOX( $self, $listbox, \&OnListBoxExtra );
        EVT_LISTBOX_DCLICK( $self, $listbox, \&OnListBoxDoubleClick );
    }
    
    return $self->htmllistbox( $listbox );
}

sub OnListBox {
    my( $self, $event ) = @_;

    if( $event->GetInt == -1 ) {
        Wx::LogMessage( "List box has no selections any more" );
        return;
    }

    Wx::LogMessage( "ListBox click item is '%d'", $event->GetInt ) ;
}

sub OnListBoxDoubleClick {
    my( $self, $event ) = @_;

    Wx::LogMessage( "ListBox double click item is '%d'", $event->GetInt ) ;
}

sub OnListBoxExtra {
    my( $self, $event ) = @_;
  
    my $vlist = $event->GetEventObject;
    
    if( $vlist->HasMultipleSelection() ) {
        my @selections;
        my ($itemindex, $listcookie) = $vlist->GetFirstSelected();
        while( defined($itemindex) && ($itemindex != -1) ) {
            push @selections, $itemindex;
            ($itemindex, $listcookie) = $vlist->GetNextSelected($listcookie);
        }
        Wx::LogMessage('Multiple Selections are %s', join(',', @selections));
    } else {
        Wx::LogMessage('Selected Item is %s', $vlist->GetSelection);
    }
}


sub add_to_tags { qw(controls) }
sub title { 'wxVListBox' }

#----------------------------------------------------------------------
package Wx::DemoModules::wxVListBox::Custom;

use strict;
use base qw(Wx::PlVListBox);

use Wx qw(:brush);

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    $self->SetItemCount( 150 );

    return $self;
}

sub OnMeasureItem {
    my( $self, $item ) = @_;

    return ( ( $item % 3 ) / 2 + 1.5 ) * 25;
}

my @colors = ( Wx::Colour->new( 255, 128, 128 ),
               Wx::Colour->new( 128, 255, 128 ),
               Wx::Colour->new( 128, 128, 255 ),
               );

sub OnDrawItem {
    my( $self, $dc, $rect, $item ) = @_;

    $dc->SetBrush( Wx::Brush->new( $colors[ $item % 3 ], wxSOLID ) );
    $dc->DrawRectangle( $rect->x, $rect->y, $rect->width, $rect->height );

    if( $self->IsSelected( $item ) ) {
        $dc->DrawText( "Selected!", $rect->x + 3, $rect->y + 3 );
    } else {
        $dc->DrawText( $item, $rect->x + 3, $rect->y + 3 );
    }
}

#----------------------------------------------------------------------

package Wx::DemoModules::wxVListBox::CustomExtra;

use strict;
use base qw(Wx::PlVListBox);

use Wx qw( :brush :font :pen :colour );

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    $self->{lbdata} = [
    
        { name => 'My First Item',
          description => 'My First Item Description',
          colour => [ 255, 0, 0 ],
        },
        { name => 'My Second Item',
          description => 'My Second Item Description',
          colour => [ 0, 255, 0 ],
        },
        { name => 'My Third Item',
          description => 'My Third Item Description',
          colour => [ 0, 0, 255 ],
        },
        { name => 'My Fourth Item',
          description => 'My Fourth Item Description',
          colour => [ 255, 255, 0 ],
        },
        { name => 'My Fifth Item',
          description => 'My Fifth Item Description',
          colour => [ 0, 255, 255 ],
        },
        { name => 'My Sixth Item',
          description => 'My Sixth Item Description',
          colour => [ 255, 0, 255 ],
        },        
    ];

    
    # metrics
    $self->{margin} = 5;
    $self->{graphicsize} = 32;
    # For Wx < 0.99, you must call static Wx::Font->New like a method.
    # For Wx >= 0.99, expected function type calls work also
    $self->{largefontsize} = Wx::Size->new(7,16);
    $self->{largefont} = Wx::Font::New($self->{largefontsize}, wxFONTFAMILY_SWISS, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_BOLD, 0 );
    $self->{smallfont} = Wx::Font::New(Wx::Size->new(6,14), wxFONTFAMILY_SWISS, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0 );
    $self->{itemheight} = ($self->{margin} * 2) + $self->{graphicsize};  

    
    $self->SetItemCount( scalar @{$self->{lbdata}} );

    return $self;
}

sub OnMeasureItem {
    my( $self, $item ) = @_;
    return $self->{itemheight}; # all our items are same height
}


sub OnDrawItem {
    my( $self, $dc, $r, $item ) = @_;
    
    my $itemdata = $self->{lbdata}->[$item];
    
    # draw the graphic
    $dc->SetPen( Wx::Pen->new(wxLIGHT_GREY, 1, wxSOLID) );
    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new(@{ $itemdata->{colour} }), wxSOLID ) );
    
    $dc->DrawRectangle( $r->x + $self->{margin}, 
                        $r->y + $self->{margin}, 
                        $self->{graphicsize}, 
                        $self->{graphicsize} );
    
    # Draw name
    $dc->SetFont($self->{largefont});
    my $woffset = ( 2* $self->{margin} ) + $self->{graphicsize};
    $dc->DrawText($itemdata->{name}, $r->x + $woffset, $r->y + $self->{margin});
        
    # draw description
    $dc->SetFont($self->{smallfont});
    $dc->DrawText(
        $itemdata->{description}, 
        $r->x + $woffset, 
        $r->y + $self->{largefontsize}->y + $self->{margin});

}

sub OnDrawSeparator {
    my( $self, $dc, $rect, $item ) = @_;
    $dc->SetPen(wxLIGHT_GREY_PEN);
    my $bl = $rect->GetBottomLeft;
    my $br = $rect->GetBottomRight;
    $dc->DrawLine($bl->x, $bl->y, $br->x, $br->y);
    # shave off the line width of one pixel
    $rect->SetHeight( $rect->GetHeight - 1);
}

sub OnDrawBackground {
    my( $self, $dc, $rect, $item ) = @_;
    my $bgcolour = ( $self->IsSelected( $item ) ) ?  Wx::Colour->new(255,255,200) : wxWHITE;
    $dc->SetBrush(Wx::Brush->new($bgcolour, wxSOLID ));
    $dc->SetPen(Wx::Pen->new($bgcolour, 1, wxSOLID ));
    $dc->DrawRectangle($rect->x, $rect->y, $rect->width, $rect->height);    
}

1;
