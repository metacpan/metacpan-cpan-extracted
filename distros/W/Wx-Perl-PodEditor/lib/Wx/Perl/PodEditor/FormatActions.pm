package Wx::Perl::PodEditor::FormatActions;

use strict;
use warnings;

use Wx qw(
    wxBOLD wxITALIC wxNORMAL
    wxDEFAULT
    wxTEXT_ATTR_BULLET_STYLE_ARABIC wxTEXT_ATTR_BULLET_STYLE_SYMBOL
);
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    bold
    italic
    headline
    list
    url
    default
);
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

our $VERSION = 0.01;

my %styles;

sub define_styles {
    %styles = (
        default  => Wx::RichTextListStyleDefinition->new( "default"  ),
        head1    => Wx::RichTextListStyleDefinition->new( "head1"    ),
        head2    => Wx::RichTextListStyleDefinition->new( "head2"    ),
        head3    => Wx::RichTextListStyleDefinition->new( "head3"    ),
        head4    => Wx::RichTextListStyleDefinition->new( "head4"    ),
        numbered => Wx::RichTextListStyleDefinition->new( "numbered" ),
        bullet   => Wx::RichTextListStyleDefinition->new( "bullet"   ),
    );
    
    $styles{numbered}->SetAttributes( 0, 50, 70, wxTEXT_ATTR_BULLET_STYLE_ARABIC );
    $styles{bullet}->SetAttributes( 0, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "*"  );
    
    my $attr_default = Wx::RichTextAttr->new;
    $attr_default->SetFontSize( 10 );
    $styles{default}->SetStyle( $attr_default );
    
    my $attr_head1 = Wx::RichTextAttr->new;
    $attr_head1->SetFontSize( 18 );
    $styles{head1}->SetStyle( $attr_head1 );
    
    my $attr_head2 = Wx::RichTextAttr->new;
    $attr_head2->SetFontSize( 16 );
    $styles{head2}->SetStyle( $attr_head2 );
    
    my $attr_head3 = Wx::RichTextAttr->new;
    $attr_head3->SetFontSize( 14 );
    $styles{head3}->SetStyle( $attr_head3 );
    
    my $attr_head4 = Wx::RichTextAttr->new;
    $attr_head4->SetFontSize( 12 );
    $styles{head4}->SetStyle( $attr_head4 );
}

sub get_style {
    my ($key) = @_;
    
    if( exists $styles{ $key } ){
        return $styles{ $key };
    }
    
    return;
}

sub bold {
    my ($self) = @_;
    
    my $edit = $self->_editor;
    $edit->ApplyBoldToSelection;
}

sub italic {
    my ($self) = @_;
    
    my $edit = $self->_editor;
    $edit->ApplyItalicToSelection;
}

sub headline {
    my ($self,$nr) = @_;
    if( grep{ $nr == $_ }(1..4) ){
        $self->_is_headline( 1 );
        my $editor = $self->_editor;
        my $key = 'head' . $nr;
        #my $range = $editor->GetSelectionRange();
        #$self->_editor->SetStyle( $range, $styles{$key} );
        $editor->ApplyStyle( $styles{ $key } );
    }
}

sub default {
    my ($self) = @_;
    my $editor = $self->_editor;
    $editor->ApplyStyle( $styles{ default } );
}

sub url {
    my ($self,$url) = @_;
}

sub list {
    my ($self,$type) = @_;
    
    my $editor = $self->_editor;
    $editor->ApplyStyle( $styles{$type} );
}

1;
