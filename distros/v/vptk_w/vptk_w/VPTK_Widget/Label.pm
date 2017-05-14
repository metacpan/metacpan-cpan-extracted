package vptk_w::VPTK_Widget::Label;

use strict;
use base qw(vptk_w::VPTK_Widget);

=head1 Name

  vptk_w::VPTK_Widget::Label - Label widget definition

=head1 Description

  This is a sample class derived from vptk_w::VPTK_Widget

=head1 Properties

  Correct object must have following obligatory properties:
    -instance_data => {-widget_data=>{},-geometry_data=>{}}
  Dynamic data:
    -id
    -visual_object
    -parent_object

=head1 Methods

  This class implement virtual methods defined by parent class:

  Getter methods (Class-related):

    HaveGeometry  => (0/1) 
    DefaultParams => [-relief=>'flat']
    TkClassName   => 'Tk::Label',
    PrintTitle    => 'Label',
    EditorProperties => {-background=>'color',-borderwidth=>'int+'},

  $w->JustDraw(parent) - draw the object using widget's actual parameters

=cut

sub HaveGeometry  { 1 }
sub DefaultParams { [-relief=>'flat'] }
sub TkClassName   { 'Tk::Label' }
sub PrintTitle    { 'Label' }
sub AssociatedIcon{ 'label' }
sub EditorProperties {
  return {
    -bitmap=>'bitmap',-image=>'variable',-highlightcolor=>'color',
    -background=>'color',-foreground=>'color',-borderwidth=>'int+',
    -justify=>'justify',-textvariable=>'variable',-underline=>'int+',
    -wraplength=>'int+',-relief=>'relief',-text=>'text',-height=>'int+',
    -padx=>'int+',-pady=>'int+',-width=>'int+',-anchor=>'anchor'
  }
}

sub JustDraw {
  my ($this,$parent,%args) = @_;
  delete $args{'-image'};
  return $parent->Label(%args);
}

1;#)
