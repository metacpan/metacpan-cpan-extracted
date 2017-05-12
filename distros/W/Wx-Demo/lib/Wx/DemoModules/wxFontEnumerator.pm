#############################################################################
## Name:        lib/Wx/DemoModules/wxFontEnumerator.pm
## Purpose:     wxPerl demo helper for Wx::FontEnumerator
## Author:      Mark Dootson
## Modified by:
## Created:     29/03/2013
## RCS-ID:      $Id: wxFontEnumerator.pm 3453 2013-03-30 04:25:07Z mdootson $
## Copyright:   (c) 2013 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxFontEnumerator;

use strict;
use Wx qw( :listctrl :id :sizer :font );
use base qw(Wx::Panel);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );
   
    # paper list setup
    my $list = Wx::ListView->new($self, wxID_ANY, [-1,-1],[-1,-1], wxLC_REPORT|wxLC_SINGLE_SEL );
    $list->InsertColumn(0, "Font Facename", wxLIST_FORMAT_LEFT, 200);
    $list->InsertColumn(1, "Example", wxLIST_FORMAT_LEFT, 200);
    
    my @facenames = ( $Wx::VERSION < 0.9918 )
        ? $self->get_facenames_broken()
        : $self->get_facenames();
    
    my @sortednames = sort { $a cmp $b } @facenames;
    
    # add facenames to the list;
    
    my $text = 'ABCDEFGHIJKLM abcdefghijklm';
    
    my $points = $list->GetFont->GetPointSize;
    
    for (my $i = 0; $i < @sortednames; $i++){
        my $index = $list->InsertStringItem( $i, $sortednames[$i] );
        my $font = Wx::Font->new($points, wxFONTFAMILY_DEFAULT,wxFONTSTYLE_NORMAL,wxFONTWEIGHT_NORMAL,0,$sortednames[$i] );
        my $ffamily = $font->GetFamily;
        if( $sortednames[$i] !~ /(dings|dingbats|symbol)/i ) {     # how do we determine a symbol font?
            if( $Wx::VERSION < 0.9918 ) {
                # work around for missing SetItemFont method
                my $item = $list->GetItem($index);
                $item->SetFont($font);
                $list->SetItem($item);
                
            } else {
                # method added in Wx 0.9918
                $list->SetItemFont($index, $font);
            }
            $list->SetItem($index, 1, $text);
        }
    }
    
    # layout
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    $mainsizer->Add($list,1,wxEXPAND|wxALL,0);
    $self->SetSizer($mainsizer);
    return $self;
}


sub get_facenames_broken {
    my $self = shift;
    my $enum = Wx::FontEnumerator->new;
    my @faces = $enum->GetFacenames;
    return @faces;
}

sub get_facenames {
    my $self = shift;
    
    my $fontencoding = wxFONTENCODING_SYSTEM; # Get everything, the default
    my $fixedwidthonly = 0;  # the default, don't restrict to fixedwidth
    
    # simple static call to get all facenames on the system
    # my @facenames = Wx::FontEnumerator::GetFacenames($fontencoding, $fixedwidthonly);
    
    # enumerated call using custom class
    
    my $enum = Wx::DemoModules::wxFontEnumerator::Custom->new;
    my @faces = $enum->get_enumerated_facenames($fontencoding, $fixedwidthonly);
    return @faces;
}

sub get_encodings {
    my($self, $facename) = @_;
    
    # simple static call to get all encodings for a facename
    # my @encodings = Wx::FontEnumerator::GetEncodings($facename);
    
    # simple static call to get all encodings on the system
    # my @encodings = Wx::FontEnumerator::GetEncodings();
    
    # enumerated call using custom class
    my $enum = Wx::DemoModules::wxFontEnumerator::Custom->new;
    my @encodings = $enum->get_enumerated_encodings($facename);
    return @encodings;
}


sub add_to_tags { qw( misc) }
sub title { 'wxFontEnumerator' }

package Wx::DemoModules::wxFontEnumerator::Custom;
use strict;
use warnings;
use base ( $Wx::VERSION < 0.9918 ) ? qw( Wx::FontEnumerator ) : qw( Wx::PlFontEnumerator );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{facenames} = [];
    $self->{encodings} = [];
    return $self;
}

sub OnFacename {
    my( $self, $facename) = @_;
    push @{ $self->{facenames} }, $facename;
    return 1;
}

sub get_enumerated_facenames {
    my ($self, $encoding, $fixedwidth) = @_;
    $self->{facenames} = [];
    $self->EnumerateFacenames($encoding, $fixedwidth);
    return @{ $self->{facenames} };
}

sub OnFontEncoding {
    my( $self, $facename, $encoding) = @_;
    push @{ $self->{encodings} }, $encoding;
    return 1;
}

sub get_enumerated_encodings {
    my ($self, $facename) = @_;
    $self->{encodings} = [];
    $self->EnumerateEncodings($facename);
    return @{ $self->{encodings} };
}




1;

