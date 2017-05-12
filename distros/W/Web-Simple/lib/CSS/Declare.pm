package CSS::Declare;

use strict;
use warnings;

use Syntax::Keyword::Gather;

my $IN_SCOPE = 0;

sub import {
  die "Can't import CSS::Declare into a scope when already compiling one that uses it"
    if $IN_SCOPE;
  my ($class, @args) = @_;
  my $opts = shift(@args) if ref($args[0]) eq 'HASH';
  my $target = $class->_find_target(0, $opts);
  my $unex = $class->_export_tags_into($target);
  $class->_install_unexporter($unex);
  $IN_SCOPE = 1;
}

sub _find_target {
  my ($class, $extra_levels, $opts) = @_;
  return $opts->{into} if defined($opts->{into});
  my $level = ($opts->{into_level} || 1) + $extra_levels;
  return (caller($level))[0];
}

my @properties = qw{
accelerator
azimuth
background
background_attachment
background_color
background_image
background_position
background_position_x
background_position_y
background_repeat
behavior
border
border_bottom
border_bottom_color
border_bottom_style
border_bottom_width
border_collapse
border_color
border_left
border_left_color
border_left_style
border_left_width
border_right
border_right_color
border_right_style
border_right_width
border_spacing
border_style
border_top
border_top_color
border_top_style
border_top_width
border_width
bottom
caption_side
clear
clip
color
content
counter_increment
counter_reset
cue
cue_after
cue_before
cursor
direction
display
elevation
empty_cells
filter
float
font
font_family
font_size
font_size_adjust
font_stretch
font_style
font_variant
font_weight
height
ime_mode
include_source
layer_background_color
layer_background_image
layout_flow
layout_grid
layout_grid_char
layout_grid_char_spacing
layout_grid_line
layout_grid_mode
layout_grid_type
left
letter_spacing
line_break
line_height
list_style
list_style_image
list_style_position
list_style_type
margin
margin_bottom
margin_left
margin_right
margin_top
marker_offset
marks
max_height
max_width
min_height
min_width
orphans
outline
outline_color
outline_style
outline_width
overflow
overflow_X
overflow_Y
padding
padding_bottom
padding_left
padding_right
padding_top
page
page_break_after
page_break_before
page_break_inside
pause
pause_after
pause_before
pitch
pitch_range
play_during
position
quotes
_replace
richness
right
ruby_align
ruby_overhang
ruby_position
size
speak
speak_header
speak_numeral
speak_punctuation
speech_rate
stress
scrollbar_arrow_color
scrollbar_base_color
scrollbar_dark_shadow_color
scrollbar_face_color
scrollbar_highlight_color
scrollbar_shadow_color
scrollbar_3d_light_color
scrollbar_track_color
table_layout
text_align
text_align_last
text_decoration
text_indent
text_justify
text_overflow
text_shadow
text_transform
text_autospace
text_kashida_space
text_underline_position
top
unicode_bidi
vertical_align
visibility
voice_family
volume
white_space
widows
width
word_break
word_spacing
word_wrap
writing_mode
z_index
zoom
};

sub _export_tags_into {
  my ($class, $into) = @_;
   for my $property (@properties) {
      my $property_name = $property;
      $property_name =~ tr/_/-/;
      no strict 'refs';
      *{"$into\::$property"} = sub ($) { return ($property_name => $_[0]) };
   }
  return sub {
    foreach my $property (@properties) {
      no strict 'refs';
      delete ${"${into}::"}{$property}
    }
    $IN_SCOPE = 0;
  };
}

sub _install_unexporter {
  my ($class, $unex) = @_;
  $^H |= 0x20000; # localize %^H
  $^H{'CSS::Declare::Unex'} = bless($unex, 'CSS::Declare::Unex');
}

sub to_css_string {
   my @css = @_;
   return join q{ }, gather {
      while (my ($selector, $declarations) = splice(@css, 0, 2)) {
         take "$selector "._generate_declarations($declarations)
      }
   };
}

sub _generate_declarations {
   my $declarations = shift;

   return '{'.join(q{;}, gather {
      while (my ($property, $value) = splice(@{$declarations}, 0, 2)) {
         take "$property:$value"
      }
   }).'}';
}

package CSS::Declare::Unex;

sub DESTROY { local $@; eval { $_[0]->(); 1 } || warn "ARGH: $@" }

1;
