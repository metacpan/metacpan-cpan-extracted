# App::a2pdf
#
# Copyright (C) 2007 Jon Allen <jj@jonallen.info>
#
# This software is licensed under the terms of the Artistic
# License version 2.0.
#
# For full license details, please read the file 'artistic-2_0.txt' 
# included with this distribution, or see
# http://www.perlfoundation.org/legal/licenses/artistic-2_0.html

package App::a2pdf;

use strict;
use warnings;
use PDF::API2;
use Switch 'Perl6';

BEGIN {
}


#-----------------------------------------------------------------------

sub new {
  my $invocant = shift;
  my $class    = ref($invocant) || $invocant;;

  # Set default options
  my $self = { @_ }; 
  bless $self,$class;
  
  # Define style mapping
  # This will relate Perl::Tidy's token types to a printing style
  $self->{stylemap} = {
    'header'     => 'helvetica_bold_10',
    'footer'     => 'helvetica_bold_10',
    'k'          => 'black_bold',
    '{'          => 'black_bold',
    '}'          => 'black_bold',
    'POD'        => 'grey_italic',
    'POD_START'  => 'grey_italic',
    'POD_END'    => 'grey_italic',
    'END_START'  => 'grey_italic',
    'DATA_START' => 'grey_italic',
    'DATA'       => 'grey_italic',
    'SYSTEM'     => 'grey_italic',
    '#'          => 'grey_italic',
    'J'          => 'red_italic',
    'j'          => 'red_italic',
    'i'          => 'blue',
    '->'         => 'blue',
    'w'          => 'green',
    'L'          => 'brown',
    'R'          => 'brown',
    'Q'          => 'purple',
    'q'          => 'purple',
  };
  
  # Define styles
  # Supports 3 properties, font (e.g. Helvetica, Courier, Times),
  # color (in hex), and type (Bold, Oblique, or BoldOblique)
  $self->{stylist} = {
    'helvetica9'  => {font=>'Helvetica',size=>9},
    'helvetica_bold_10'  => {font=>'Helvetica',size=>10,type=>'Bold'},
    'black_bold'  => {color=>'#000000',type=>'Bold'},
    'grey_italic' => {color=>'#333333',type=>'Oblique'},
    'red_italic'  => {color=>'#cc2222',type=>'Oblique'},
    'blue'        => {color=>'#222288'},
    'green'       => {color=>'#228822'},
    'brown'       => {color=>'#666622'},
    'purple'      => {color=>'#882288'},
  };
  
  # Set up first page
  $self->{page_number}   = 0;
  $self->{line_number}   = 1;
  $self->{line_number_width} = 0;
  $self->{line_spacing}  = $self->{font_size}+2 unless ($self->{line_spacing});
  $self->{x_position}    = $self->{left_margin};
  $self->{y_position}    = $self->{page_height} - $self->{top_margin};
  $self->{pdf}           = PDF::API2->new;
  $self->{pdf}->mediabox($self->{page_width},$self->{page_height});
  
  if ($self->{icon}) {
    # Load required modules to handle images
    eval "use File::Type;use Image::Size";
    unless ($@) {
      if (-e $self->{icon}) {
        my $type = File::Type->new->checktype_filename($self->{icon});
        given ($type) {
          when 'image/jpeg'  {$self->{icon_img} = $self->{pdf}->image_jpeg($self->{icon})}
          when 'image/tiff'  {$self->{icon_img} = $self->{pdf}->image_tiff($self->{icon})}
          when 'image/gif'   {$self->{icon_img} = $self->{pdf}->image_gif($self->{icon})}
          when 'image/x-png' {$self->{icon_img} = $self->{pdf}->image_png($self->{icon})}
          when 'image/x-pnm' {$self->{icon_img} = $self->{pdf}->image_pnm($self->{icon})}
          default {warn "[Warning] Unknown image format '$type' for icon ".$self->{icon}."\n"}
        }
        if ($self->{icon_img}) {
          ($self->{icon_width},$self->{icon_height}) = imgsize($self->{icon});  
        }    
      } else {
        warn("[Warning] Cannot open icon file: ".$self->{icon}."\n");
      }
    } else {
      warn("[Warning] The modules File::Type and Image::Size are required to use icons\n")
    }
  }

  $self->formfeed;
  $self->set_style;
  return $self;
}


#-----------------------------------------------------------------------

sub print {
  my $self = shift;
  my $line = shift;

  if ($self->{newline_flag}) {
    $self->newline;
    $self->{newline_flag} = 0;
  }

  $self->print_line_number if $self->{line_numbers};
  $self->print_text_with_style($line);
  $self->{newline_flag} = 1;
}


#-----------------------------------------------------------------------



sub write_line {    # This is the write_line method called by Perl::Tidy
  my $self        = shift;
  my $line        = shift;
  my $line_number = $line->{_line_number};
  my $line_type   = $line->{_line_type};
  my $line_text   = $line->{_line_text};
  chomp $line_text;

  if ($self->{newline_flag}) {
    $self->newline;
    $self->{newline_flag} = 0;
  }
  $self->print_line_number if $self->{line_numbers};

  if ($line_type eq 'CODE') {
    $self->print_text_with_style($1) if ($line_text =~ /^(\s+)/);
    my @rtoken_list  = @{$line->{_rtokens}};
    my @rtoken_types = @{$line->{_rtoken_type}};
    foreach my $rtoken (@rtoken_list) {
      my $rtoken_type = shift @rtoken_types;
      $self->print_text_with_style($rtoken,$rtoken_type);
    }
  } else {
    $self->print_text_with_style($line_text,$line_type);
  }
  $self->{newline_flag} = 1;
}


#-----------------------------------------------------------------------

sub newline {
  my $self = shift;
  
  $self->linefeed;
  $self->{line_number}++;
  $self->{overflow} = 0;
}


#-----------------------------------------------------------------------

sub linefeed {
  my $self = shift;
  
  $self->{y_position} -= $self->{line_spacing};
  $self->{x_position}  = $self->{left_margin} + $self->{line_number_width};
  $self->{overflow}    = 1;
    
  if ($self->{y_position} < ($self->{bottom_margin} + $self->{footer_height})) {
    my $style = $self->{style};
    $self->formfeed;
    $self->set_style($style);
  } 
}


#-----------------------------------------------------------------------

sub formfeed {
  my $self = shift;
  $self->{page}       = $self->{pdf}->page;
  $self->{x_position} = $self->{left_margin} + $self->{line_number_width};
  $self->{page_number}++;

  delete $self->{text};
  delete $self->{gfx};  
  $self->{gfx}  = $self->{page}->gfx;
  $self->{text} = $self->{page}->text;
  
  $self->{y_position}    = $self->{page_height} - $self->{top_margin} - $self->{line_spacing};
  $self->{header_height} = ($self->{header}) ? $self->generate_header : 0;
  $self->{footer_height} = ($self->{footer}) ? $self->generate_footer : 0;
  $self->{y_position}   -= $self->{header_height};
}


#-----------------------------------------------------------------------

sub generate_header {
  my $self = shift;
  $self->set_style('header');
  
  my $header_padding = 2;
  my $header_spacing = 3;
  my $header_height  = $self->{text_size} + $header_spacing + $header_padding;
  
  # Draw header icon
  if ($self->{icon_img}) {
    my $icon_height_in_points = $self->{icon_height} * $self->{icon_scale};
    if ($icon_height_in_points > $self->{text_size}) {
      $header_height += ($icon_height_in_points - $self->{text_size});
    }
    my $ypos = $self->{page_height} - $self->{top_margin} - $icon_height_in_points;
    $self->{gfx}->image($self->{icon_img},$self->{left_margin},$ypos,$self->{icon_scale});
  }

  # Add page title
  my $x = $self->{page_width} - $self->{right_margin} - $self->{text}->advancewidth($self->{title});
  my $y = $self->{page_height} - $self->{top_margin} - $header_height + $header_spacing + $header_padding;
  $self->{text}->textlabel($x,$y,$self->{fontcache}->{$self->{font}},$self->{text_size},$self->{title});

  # Draw horizontal line
  $self->{gfx}->move($self->{left_margin},$self->{page_height}-$self->{top_margin}-$header_height + $header_padding);
  $self->{gfx}->line($self->{page_width}-$self->{right_margin},$self->{page_height}-$self->{top_margin}-$header_height + $header_padding);
  $self->{gfx}->stroke;
  
  return $header_height;
}


#-----------------------------------------------------------------------

sub generate_footer {
  my $self  = shift;
  $self->set_style('footer');

  # Add page footer
  my $t = 'Page '.$self->{page_number};
  my $x = $self->{page_width} - $self->{right_margin} - $self->{text}->advancewidth($t);
  my $y = $self->{bottom_margin};
  $self->{text}->textlabel($x,$y,$self->{fontcache}->{$self->{font}},$self->{text_size},$t);


  $self->{gfx} = $self->{page}->gfx unless (exists $self->{gfx});
  $self->{gfx}->move($self->{left_margin},$self->{bottom_margin}+10);
  $self->{gfx}->line($self->{page_width}-$self->{right_margin},$self->{bottom_margin}+10);
  $self->{gfx}->stroke;
  return 18;  # Footer height in points
}


#-----------------------------------------------------------------------

sub output {
  my $self = shift;
  print $self->{pdf}->stringify;
  #$self->{pdf}->end;
}


#-----------------------------------------------------------------------

sub line_number_chars {
  my $self                      = shift;
  my $line_number_chars         = shift;
  $self->{line_number_chars}    = $line_number_chars;
  $self->{line_number_width}    = ($self->{line_numbers}) ? $self->{text}->advancewidth('X' x ($line_number_chars + 2)) : 0;
  $self->{line_number_template} = '%'.$line_number_chars.'d: %s';
  $self->{x_position}           = $self->{left_margin} + $self->{line_number_width};
}


#-----------------------------------------------------------------------

sub print_line_number {
  my $self = shift;
  
  $self->set_style;
  my $width = $self->{text}->advancewidth($self->{line_number}.':X');
  my $x_pos = $self->{left_margin} + $self->{line_number_width} - $width;
  $self->{text}->textlabel($x_pos,$self->{y_position},$self->{fontcache}->{$self->{font}},$self->{text_size},$self->{line_number}.':');
}


#--print_text_with_style---------------------------------------------------

sub print_text_with_style {
  my $self  = shift;
  my $text  = shift;
  $self->set_style(shift);

  while ($text =~ /(\f|[^\f]+)/g) {
    my $block = $1;
    if ($block =~ /\f/ && !exists $self->{noformfeed}) {
      $self->formfeed;
      $self->{x_position} = $self->{left_margin} + $self->{line_number_width};
    } else {
      while ($block =~ /(\s+|\S+)/g) {
        my $word = $1;
        $self->print_word($word);
      }
    }
  }
}


#--print_word--------------------------------------------------------------
#
# Purpose: Adds a single word to the PDF in the current style
#
# Usage:   $self->print_word('word');
#
#--------------------------------------------------------------------------

sub print_word {
  my $self = shift;
  my $word = shift;
  

    my $width = $self->{text}->advancewidth($word);
    if ($self->{x_position} + $width > $self->{page_width} - $self->{right_margin}) {
      # If the word will not fit on one line, split it up and recurse the 'print_word' sub
      if ($width > ($self->{page_width} - $self->{left_margin} - $self->{right_margin})) {
        my $fit = int(($self->{page_width} - $self->{x_position} - $self->{right_margin}) / $self->{nspace});
        my @words = (substr($word,0,$fit),substr($word,$fit));
        $self->print_word($_) foreach @words; 
        return;
      }
      $self->linefeed;
      if ($word =~ /^\s+$/ &&
          $self->{overflow} &&
          $self->{x_position} == $self->{left_margin} + $self->{line_number_width}) {
        return;
      }
    }
    $self->{x_position} += $self->{text}->textlabel($self->{x_position},
                                                    $self->{y_position},
                                                    $self->{fontcache}->{$self->{font}},
                                                    $self->{text_size},
                                                    $word,
                                                    -color => $self->{text_color});
    if ($self->{x_position} > $self->{page_width} - $self->{right_margin}) {
      $self->linefeed;
    }
}


#--set_style---------------------------------------------------------------
#
# Purpose: Sets current style (font, size, colour)
#
# Usage:   $self->set_style('stylename');
#
#--------------------------------------------------------------------------

sub set_style {
  my $self  = shift;
  my $style = shift || 'default';
  
  $style = (exists $self->{stylemap}->{$style}) ? $self->{stylemap}->{$style} : 'default';
  
  # Create font object if necessary
  my $font = ($self->{stylist}->{$style}->{font} || $self->{font_face}) .
             ((exists $self->{stylist}->{$style}->{type}) ? '-'.$self->{stylist}->{$style}->{type} : '');
  unless (exists $self->{fontcache}->{$font}) {
    $self->{fontcache}->{$font} = $self->{pdf}->corefont($font);
  }
  
  $self->{style}      = $style;
  $self->{font}       = $font;
  $self->{text_color} = $self->{stylist}->{$style}->{color} || '#000000';
  $self->{text_size}  = $self->{stylist}->{$style}->{size}  || $self->{font_size};
  
  $self->{text}->font($self->{fontcache}->{$font},$self->{text_size});
  $self->{nspace}     = $self->{text}->advancewidth('n');
}


#--------------------------------------------------------------------------

sub _MANIFEST {
  require File::Type;
  require Image::Size;
  require PDF::API2::Content;
  require PDF::API2::Win32;
  require PDF::API2::Lite;
  require PDF::API2::UniWrap;
}

1;
