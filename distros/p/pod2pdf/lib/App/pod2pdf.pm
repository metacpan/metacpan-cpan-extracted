# App::pod2pdf
#
# Copyright (C) 2007 Jon Allen <jj@jonallen.info>
#
# This software is licensed under the terms of the Artistic
# License version 2.0.
#
# For full license details, please read the file 'artistic-2_0.txt' 
# included with this distribution, or see
# http://www.perlfoundation.org/legal/licenses/artistic-2_0.html

package App::pod2pdf;

use strict;
use warnings;
use Carp;
use List::Util qw/max min/;
use PDF::API2;
use Pod::Escapes qw/e2char/;
use Pod::Parser;
use Pod::ParseLink;

use constant TRUE  => 1;
use constant FALSE => 0;

BEGIN {
  our @ISA     = qw/Pod::Parser/;
  our $VERSION = '0.42';
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

sub new {
  my $invocant = shift;
  my $class    = ref($invocant) || $invocant;

  my %user_options    = @_;
  my %default_options = (
    header        => TRUE,         # Include header on all pages
    footer        => TRUE,         # Include footer on all pages
    page_width    => 595,          # A4
    page_height   => 842,          # A4
    left_margin   => $user_options{margins} || 48,  # 0.75"
    right_margin  => $user_options{margins} || 48,  # 0.75"
    top_margin    => $user_options{margins} || 60,  # 
    bottom_margin => $user_options{margins} || 60,  # 
    font_face     => 'Helvetica',  # Sans-Serif text
    font_size     => 10,           # Text size = 10 points
    icon_scale    => 0.25,         # Icon scaling (%age)
    );
  
  my $self = $class->SUPER::new(%default_options,%user_options);
  
  $self->create_pdf;
  return $self;
}


#-----------------------------------------------------------------------

sub command {
  my ($self, $command, $paragraph, $line_num) = @_;
  my $expansion = $self->interpolate($paragraph, $line_num);  

  COMMAND: {
    if ($command eq 'ff') {
     $self->formfeed if ($self->print_flag);
    }
    if ($command =~ /^head[1234]$/) {
      $self->indent(0);
      $self->set_style('default');
      $self->newline;
      my $default_space = $self->{line_spacing};
      $self->set_style($command);
      my $heading_space = $self->{line_spacing};
      # Checks to see if there is space for a content line after
      # the heading - if not then starts a new page
      if ( ($self->{y_position} - $heading_space - $default_space - $self->{spacer}) < 
           ($self->{bottom_margin} + $self->{footer_height}) ) {
        $self->formfeed;
      } else {
        $self->{y_position} -= ($heading_space - $default_space);
      }
      $self->print_text_with_style($expansion,$command);
      $self->spacer;
      $self->indent(48);
    }
    if ($command eq 'over') {
      my $indentlevel = $expansion || 4;
      $self->set_style;
      $self->push_indent($indentlevel * $self->em);
      $self->reset_item_textblock_flag;
    }
    if ($command eq 'back') {
      $self->pop_indent;
      $self->spacer;
    }
    if ($command eq 'item') {
      $self->spacer if ($self->item_textblock_flag);
      $self->reset_item_textblock_flag;
      if ($expansion =~ '^\s*\*?\s*$') {
        # First check to see if there is space for any text
        if ($self->{y_position} - $self->{line_spacing} < ($self->{bottom_margin} + $self->{footer_height})) {
          $self->formfeed;
        } 
        my $indent = $self->pop_indent;
        $self->bullet($indent);
        $self->push_indent($indent);
      } elsif ($expansion =~ '^\s*(\d+\.?)\s*$') {
        # First check to see if there is space for any text
        if ($self->{y_position} - $self->{line_spacing} < ($self->{bottom_margin} + $self->{footer_height})) {
          $self->formfeed;
        } 
        my $indent = $self->pop_indent;
        $self->{y_position} -= $self->{line_spacing};
        $self->print_text_with_style($1,'default');
        $self->push_indent($indent);
        $self->{y_position} += $self->{line_spacing};
      } else {
        my $indent = $self->pop_indent;
        $self->set_style;
        $self->newline;
        $self->parse_text({-expand_ptree => 'print_tree'},$paragraph,$line_num);
        $self->spacer;    
        $self->push_indent($indent);
      }
    }
  }
}


#-----------------------------------------------------------------------

sub verbatim {
  my ($self, $paragraph, $line_num) = @_;
  if ($paragraph =~ /^[ \t]/) {
    $self->set_style('verbatim');
    $self->reset_space_flag;
    $self->set_item_textblock_flag;
    foreach my $line (split /\n/,$paragraph) {
      # todo: expand tabs
      if ($line =~ /\S/) {
        $self->newline;
        $self->print_text_with_style($line,'verbatim');
        $self->reset_space_flag;
      }
    }
    $self->newline;
    $self->spacer unless ($self->over);
  }
}


#-----------------------------------------------------------------------

sub textblock {
  my ($self, $text, $line_num) = @_;
  if ($text =~ /\S/) {  # ignore blank paragraphs
    $self->set_item_textblock_flag;
    $self->reset_space_flag;
    $self->set_style;
    $self->newline;
    $self->parse_text({-expand_ptree => 'print_tree'},$text,$line_num);
    $self->spacer;
    $self->spacer unless ($self->over);
  }
}


#-----------------------------------------------------------------------

sub interior_sequence {
  my ($self,$command,$text) = @_;
  #
  # need to check content of $text, i.e.
  # is there a nested formatting command?
  #
  # also this doesn't handle the L<> formatting
  # command, check with perlpodspec if this is
  # allowed in =head blocks
  #
  COMMAND: {
    if ($command eq 'X') {
      # no-op
      last COMMAND;
    }
    if ($command eq 'Z') {
      # no-op
      last COMMAND;
    }
    if ($command eq 'E') {
      return e2char($text);
    }
    DEFAULT: {
      return $text;
    }
  }
}


#-----------------------------------------------------------------------

sub print_tree {
  my $self = shift;
  my $tree = shift;
  NODE: foreach my $node ($tree->children) {
    if (ref $node) {
      COMMAND: { 
        my $command = $node->cmd_name;
        if ($command eq 'L') {
          #warn("Found link: ".$node->raw_text."\n");
          my $left_delimiter  = $node->left_delimiter;
          my $right_delimiter = $node->right_delimiter;
          (my $link_text = $node->raw_text) =~ s/L$left_delimiter\s*(.*?)\s*$right_delimiter$/$1/s;
          my ($text, $inferred, $name, $section, $type) = parselink($link_text);
	  $text     =~ s/^"(.*?)"$/$1/ if ($text);
	  $inferred =~ s/^"(.*?)"$/$1/ if ($inferred);
	  $name     =~ s/^"(.*?)"$/$1/ if ($name);
          $self->push_format('I');
          $self->parse_text({-expand_ptree => 'print_tree'},($text || $inferred || $name));
          $self->pop_format;
          last COMMAND;
        }
        if ($command eq 'O') {
          my $left_delimiter  = $node->left_delimiter;
          my $right_delimiter = $node->right_delimiter;
          (my $object_text = $node->raw_text) =~ s/O$left_delimiter\s*(.*?)\s*$right_delimiter$/$1/;
          my ($object_title,$object_location) = parseobject($object_text);
          if ($object_location =~ /\A\W+:[^:\s]\S*\z/) {
            # URL - cannot load (yet!)
            $self->warnonce('HTTP object loading not supported');
            $self->print_text_with_style($object_location,'I');
          } elsif (-e $object_location) {
            # Found file
            if ($self->images) {
              my $mime_type = File::Type->new->mime_type($object_location);
              if ($mime_type =~ /^image/) {
                unless ($self->insert_image($object_location)) {
                  $self->print_text_with_style($object_location,'I');                
                }
              } else {
                $self->print_text_with_style($object_location,'I');
              }
            } else {
              $self->print_text_with_style($object_location,'I');
            }
          } else {
            # Non-existant file
            $self->warnonce("Object not found: $object_location");
            $self->print_text_with_style("Object not found: $object_location",'I');
          }
          last COMMAND;
        }
        if ($command eq 'X') {
          # no-op
        }
        DEFAULT: {
          $self->push_format($node->cmd_name);
          $self->print_tree($node->parse_tree);
          $self->pop_format;
        }
      }
    } else {
      FORMAT: {
        $_ = $self->format;
        if (/X/) {
          # no-op
          last FORMAT;
        }
        if (/Z/) {
          # no-op
          last FORMAT;
        }
        if (/E/) {
          $node = e2char($node);
        }
        if (/BC.*I/) {
          $self->print_text_with_style($node,'BCI');
          last FORMAT;
        }
        if (/C.*I/) {
          $self->print_text_with_style($node,'CI');
          last FORMAT;
        }
        if (/B.*I/) {
          $self->print_text_with_style($node,'BI');        
          last FORMAT;
        }
        if (/BC/) {
          $self->print_text_with_style($node,'BC');        
          last FORMAT;
        }
        if (/B/) {
          $self->print_text_with_style($node,'B');        
          last FORMAT;
        }
        if (/C/) {
          $self->print_text_with_style($node,'C');        
          last FORMAT;
        }
        if (/I/) {
          $self->print_text_with_style($node,'I');        
          last FORMAT;
        }
        DEFAULT: {
          #warn "Line 414: $_\n";
          $self->print_text_with_style($node,'default');
          last FORMAT;
        }
      }
    }
  }
}


#-----------------------------------------------------------------------

sub insert_image {
  my $self     = shift;
  my $filename = shift;
  
  if ($self->images) {
    if (-e $filename) {
      my $image;
      my $type = File::Type->new->checktype_filename($filename);
      SWITCH: {
        if ($type eq 'image/jpeg')  {$image = $self->{pdf}->image_jpeg($filename); last}
        if ($type eq 'image/tiff')  {$image = $self->{pdf}->image_tiff($filename); last}
        if ($type eq 'image/gif')   {$image = $self->{pdf}->image_gif($filename);  last}
        if ($type eq 'image/x-png') {$image = $self->{pdf}->image_png($filename);  last}
        if ($type eq 'image/x-pnm') {$image = $self->{pdf}->image_pnm($filename);  last}
        $self->warnonce("[Warning] Unknown image format '$type' for image '$filename'");
        return FALSE;
      }
      
      unless ($image) {
        $self->warnonce("[Warning] Cannot load image file '$filename'");
        return FALSE;
      }

      my ($width,$height)  = imgsize($filename);
      my $available_width  = $self->{page_width} - $self->{right_margin} - $self->{x_position};
      my $scale_default    = 0.5;
      my $scale_min        = 0.4;
      my $scale            = min($available_width / $width, $scale_default);
      my $height_in_points = $height * $scale;

      if ($self->{y_position} < ($self->{bottom_margin} + $self->{footer_height} + $height_in_points + ($self->{line_spacing} / 2))) {
        my $available_height = $self->{y_position} - $self->{bottom_margin} - $self->{footer_height} - $self->{line_spacing};
        if ($available_height / $height > $scale_min) {
          $scale = $available_height / $height;
          $height_in_points = $height * $scale;
        } else {
          $self->formfeed;
          $self->set_print_flag;
        }
      }
  
      $self->{y_position} -= $height_in_points;
      $self->{y_position} += ($self->{line_spacing} / 2);
      $self->{gfx}         = $self->{page}->gfx unless (exists $self->{gfx});  
      $self->{gfx}->image($image,$self->{x_position},$self->{y_position},$scale);
      return TRUE;
    } else {
      $self->warnonce("Image '$filename' does not exist");
      return FALSE;
    }
  }
}


#-----------------------------------------------------------------------

sub images {
  my $self = shift;
  
  unless ($self->{image_modules_check}) {
    # Check if image modules are installed
    eval "use File::Type;use Image::Size;";
    if ($@) {
      $self->warnonce('Cannot use images, modules Image::Size and/or File::Type not installed');
    } else {      
      $self->{image_modules_loaded} = TRUE;
    }
    $self->{image_modules_check}  = TRUE;
  }
  
  return $self->{image_modules_loaded};  
}


#-----------------------------------------------------------------------

sub warnonce {
  my $self    = shift;
  my $warning = shift;
  
  unless ($self->{issued_warnings}->{$warning}) {
    warn("[Warning] $warning\n");
    $self->{issued_warnings}->{$warning} = TRUE;
  }
}


#-----------------------------------------------------------------------

sub parseobject {
  # Parses the O<...> formatting code as specified in perlpodextensions
  my $object_text = shift;
  if ($object_text =~ /(.*?)\|(.*)/) {
    return ($1,$2);
  } else {
    return (undef,$object_text);
  }
}


#-----------------------------------------------------------------------

sub create_pdf {
  my $self    = shift;
  my $class   = ref $self;
  my $version = $::{$class.'::'}{VERSION} ? ${ $::{$class.'::'}{VERSION} } : 'unknown';
      
  # Define styles
  #
  # Future enhancement: move the style definitions into a separate
  # module (e.g. Pod::Pdf::Styles) which can be subclassed to allow
  # non-core fonts to be used.
  #
  $self->{stylist} = {
    'header'      => {font=>'Helvetica-Bold',        size=>10       },
    'footer'      => {font=>'Helvetica-Bold',        size=>10       },
    'head1'       => {font=>'Helvetica-Bold',        size=>12       },
    'head2'       => {font=>'Helvetica-Bold',        size=>11       },
    'head3'       => {font=>'Helvetica-Bold',        size=>10       },
    'head4'       => {font=>'Helvetica',             size=>10       },
    'verbatim'    => {font=>'Courier',               verbatim=>TRUE },
    'B'           => {font=>'Helvetica-Bold'                        },
    'BC'          => {font=>'Courier-Bold',          verbatim=>TRUE },
    'BI'          => {font=>'Helvetica-BoldOblique'                 },
    'BCI'         => {font=>'Courier-BoldOblique',   verbatim=>TRUE },
    'C'           => {font=>'Courier',               verbatim=>TRUE },
    'CI'          => {font=>'Courier-Oblique',       verbatim=>TRUE },
    'I'           => {font=>'Helvetica-Oblique'                     },
  };
  
  # Set up first page
  PAGE_SIZE: {
    if ($self->{page_size}) {
      eval "use Paper::Specs 0.10 units=>'pt';";
      if ($@) {
        $self->warnonce("Cannot use '--page-size' option, module Paper::Specs (v0.10) not installed");
      } else {
        if (my $form = Paper::Specs->find(code=>$self->{page_size}, brand=>'standard')) {
          $self->{page_width}  = int($form->sheet_width + 0.5);
          $self->{page_height} = int($form->sheet_height + 0.5);
        } else {
          $self->warnonce("Unknown page size '".$self->{page_size}."'");
        } 
      }
    }
  }
  
  PAGE_ORIENTATION: {
    if ($self->{page_orientation}) {
      if (lc $self->{page_orientation} eq 'landscape') {
        ($self->{page_width},$self->{page_height}) = (
          max($self->{page_width},$self->{page_height}),
          min($self->{page_width},$self->{page_height}) 
        );
        last PAGE_ORIENTATION;
      }
      if (lc $self->{page_orientation} eq 'portrait') {
        ($self->{page_width},$self->{page_height}) = (
          min($self->{page_width},$self->{page_height}),
          max($self->{page_width},$self->{page_height}) 
        ); 
        last PAGE_ORIENTATION; 
      }
      $self->warnonce("Unknown page orientation '".$self->{page_orientation}."', must be 'portrait' or 'landscape'");
    }  
  }
  
  $self->{page_number}   = 0;
  $self->{line_spacing}  = $self->{font_size}+2 unless ($self->{line_spacing});
  $self->{x_position}    = $self->{left_margin};
  $self->{y_position}    = $self->{page_height} - $self->{top_margin};
  $self->{indent}        = 0;
  $self->{pdf}           = PDF::API2->new;
  $self->{pdf}->info('Producer'=>"$class version $version");
  $self->{pdf}->mediabox($self->{page_width},$self->{page_height});
  
  if ($self->{icon} && $self->images) {
      if (-e $self->{icon}) {
        my $type = File::Type->new->checktype_filename($self->{icon});
        SWITCH: {
          if ($type eq 'image/jpeg')  {$self->{icon_img} = $self->{pdf}->image_jpeg($self->{icon}); last}
          if ($type eq 'image/tiff')  {$self->{icon_img} = $self->{pdf}->image_tiff($self->{icon}); last}
          if ($type eq 'image/gif')   {$self->{icon_img} = $self->{pdf}->image_gif($self->{icon});  last}
          if ($type eq 'image/x-png') {$self->{icon_img} = $self->{pdf}->image_png($self->{icon});  last}
          if ($type eq 'image/x-pnm') {$self->{icon_img} = $self->{pdf}->image_pnm($self->{icon});  last}
          warn "[Warning] Unknown image format '$type' for icon ".$self->{icon}."\n";
        }
        if ($self->{icon_img}) {
          ($self->{icon_width},$self->{icon_height}) = imgsize($self->{icon});  
        }    
      } else {
        warn("[Warning] Cannot open icon file: ".$self->{icon}."\n");
      }
  }  

  $self->formfeed;
  $self->set_style;
  $self->{indent}        = 0;
  $self->{over}          = 0;
  $self->{spacer}        = 4;  # default spacing between paragraphs
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Item_textblock_flag methods
#
# This flag is used to control line spacing within =over sections. The
# flag is cleared after each =item command and set whenever a textblock
# is printed.
#
# At the start of processing an =item command, an extra half line space 
# (4 points) is inserted if the textblock flag is set. Because half
# spacing is the default in =over sections, this extra space between
# individual =items acts to visually group the =item paragraphs as a
# single element.

#-----------------------------------------------------------------------

sub item_textblock_flag {
  my $self = shift;
  return $self->{item_textblock_flag}->{$self->over} || 0;
}


#-----------------------------------------------------------------------

sub set_item_textblock_flag {
  my $self = shift;
  $self->{item_textblock_flag}->{$self->over} = TRUE;
}


#-----------------------------------------------------------------------

sub reset_item_textblock_flag {
  my $self = shift;
  $self->{item_textblock_flag}->{$self->over} = FALSE;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Print_flag methods
#
# The Print flag is used to prevent blank lines from appearing at the 
# start of a page, which can happen if a verbatim block or =over list 
# crosses a page break.
#
# When a new page is started, the print flag is reset. In this state
# any calls to newline() or spacer() will have no effect. Whenever any
# text is printed, the print flag will be set, then newlines will
# operate nomally.

#-----------------------------------------------------------------------

sub print_flag {
  my $self = shift;
  return $self->{print_flag} || 0;
}


#-----------------------------------------------------------------------

sub set_print_flag {
  my $self = shift;
  $self->{print_flag} = TRUE;
}


#-----------------------------------------------------------------------

sub reset_print_flag {
  my $self = shift;
  $self->{print_flag} = FALSE;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Space_flag methods
#
# The space flag is used to prevent the display of whitespace characters
# at the end of a paragraph. If these characters are not suppressed,
# then occasionally they will wrap onto the next line, causing unsightly 
# spaces in the finished document.
#
# Each string presented to the print_text_with_style() method is checked
# for trailling whitespace. If so, the space_flag is set. At the next
# call to print_text_with_style(), an extra space character is printed
# if the space_flag is set. The space_flag is cleared either when the
# spacer() method is called (to mark the 'real' end of a text block), or
# after the flag has caused a new space to be inserted.

#-----------------------------------------------------------------------

sub space_flag {
  my $self = shift;
  return $self->{space_flag} || 0;
}


#-----------------------------------------------------------------------

sub set_space_flag {
  my $self = shift;
  $self->{space_flag} = TRUE;
}


#-----------------------------------------------------------------------

sub reset_space_flag {
  my $self = shift;
  $self->{space_flag} = FALSE;
}


#-----------------------------------------------------------------------

sub flag {
  my $self = shift;
  my $flag = shift or return FALSE;
  return $self->{flags}->{$flag} || FALSE;
}


#-----------------------------------------------------------------------

sub set_flag {
  my $self = shift;
  my $flag = shift or return FALSE;
  $self->{flags}->{$flag} = TRUE;
}


#-----------------------------------------------------------------------

sub clear_flag {
  my $self = shift;
  my $flag = shift or return FALSE;
  $self->{flags}->{$flag} = FALSE;
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Text indent methods

#-----------------------------------------------------------------------

sub indent {
  # Sets the current indent (measured in points)
  my $self            = shift;
  $self->{indent}     = shift;
  $self->{x_position} = $self->{left_margin} + $self->{indent};
}


#-----------------------------------------------------------------------

sub over {
  # Returns the current number of nested =over blocks
  my $self = shift;
  return $self->{over};
}


#-----------------------------------------------------------------------

sub em {
  # Returns the width (in points) of an 'm' character, used by =over X
  # to decide how much to indent by
  my $self = shift;
  return $self->{mspace};
}


#-----------------------------------------------------------------------

sub push_indent {
  my $self   = shift;
  my $indent = shift;
  push @{$self->{indent_list}},$indent;
  $self->indent($self->{indent} + $indent);
  $self->{over}++;
}


#-----------------------------------------------------------------------

sub pop_indent {
  my $self = shift;
  $self->{over}--;
  if (@{$self->{indent_list}}) {
    my $indent = pop @{$self->{indent_list}};
    $self->indent($self->{indent} - $indent);
    return $indent;
  } else {
    return 0;
  }
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Text format methods
#
# During parsing, as each Pod::InteriorSequence object is encountered
# the formatting code (B, I, etc) is pushed onto a stack. When the
# parser gets to the individual text elements, the format() method will
# return the complete set of codes which need to be applied to the text.

#-----------------------------------------------------------------------

sub push_format {
  my $self   = shift;
  my $format = shift;
  push @{$self->{format}},$format;
}


#-----------------------------------------------------------------------

sub pop_format {
  my $self = shift;
  return pop @{$self->{format}} if (@{$self->{format}});
}


#-----------------------------------------------------------------------

sub format {
  # Returns the current text format as a scalar, e.g. 'BEI' for Bold
  # Italic with Escapes to be processed. Formatting codes are listed in
  # alphabetical order with duplicates removed.
  my $self = shift;
  my %format;
  foreach (@{$self->{format}}) {
    # Treat F<> as a synonym for I<> (renders filenames in italic)
    tr/F/I/;
    $format{$_}++;
  }
  return join '',sort keys %format;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

sub bullet {
  # Draws a bullet point (filled circle) at the current text position
  #
  # Todo: need to remove the integer values here and replace with
  # percentages of the current line spacing to handle different fonts
  
  my $self    = shift;
  my $indent  = shift;
  my $bullet  = $self->{page}->gfx;
  my $x_coord = $self->{left_margin} + $self->{indent} + 4 + $indent - 20;
  my $y_coord = $self->{y_position} - 9 + ($self->print_flag ? 0 : $self->{line_spacing});
  my $radius  = 2;

  $bullet->circle($x_coord,$y_coord,$radius);
  $bullet->fillstroke;
}


#-----------------------------------------------------------------------

sub newline {
  my $self = shift;
  
  if ($self->print_flag) {
    $self->linefeed;
    $self->set_flag('newline');
  }
}


#-----------------------------------------------------------------------

sub linefeed {
  my $self = shift;
  
  $self->{y_position} -= $self->{line_spacing};
  $self->{x_position}  = $self->{left_margin} + $self->{indent};
    
  if ($self->{y_position} < ($self->{bottom_margin} + $self->{footer_height})) {
    my $style = $self->{style};
    $self->formfeed;
    $self->set_style($style);
  } 
}


#-----------------------------------------------------------------------

sub spacer {
  my $self = shift;
  $self->reset_space_flag;

  if ($self->print_flag) {
    $self->{y_position} -= $self->{spacer};
    $self->{x_position} = $self->{left_margin} + $self->{indent};

    if ($self->{y_position} < ($self->{bottom_margin} + $self->{footer_height})) {
      $self->formfeed;
    }
  }  
}


#-----------------------------------------------------------------------

sub formfeed {
  my $self = shift;
  $self->{page}       = $self->{pdf}->page;
  $self->{x_position} = $self->{left_margin} + $self->{indent};
  $self->{page_number}++;

  delete $self->{text};
  delete $self->{gfx};  
  $self->{gfx}  = $self->{page}->gfx;
  $self->{text} = $self->{page}->text;
  
  $self->{y_position}    = $self->{page_height} - $self->{top_margin} - $self->{line_spacing};
  $self->{header_height} = ($self->{header}) ? $self->generate_header : 0;
  $self->{footer_height} = ($self->{footer}) ? $self->generate_footer : 0;
  $self->{y_position}   -= $self->{header_height};

  $self->reset_print_flag;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Page header and footer methods
#
# Future enhancement: pass the page number, filename, etc details as
# parameters to generate_header() and generate_footer(), allow these
# methods to be overridden by the user for custom page formatting.

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
  
  if ($self->{footer_text}) {
    $x = $self->{left_margin};
    $self->{text}->textlabel($x,$y,$self->{fontcache}->{$self->{font}},$self->{text_size},$self->{footer_text});
  }

  $self->{gfx} = $self->{page}->gfx unless (exists $self->{gfx});
  $self->{gfx}->move($self->{left_margin},$self->{bottom_margin}+10);
  $self->{gfx}->line($self->{page_width}-$self->{right_margin},$self->{bottom_margin}+10);
  $self->{gfx}->stroke;
  return 18;  # Footer height in points
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# PDF file output
#
# When the PDF object goes out of scope, the generated PDF file will be
# printed to STDOUT. 
#
# Update - this doesn't work with PAR, need explicit $pdf->output() method

#-----------------------------------------------------------------------

sub output {
  my $self = shift;
  print $self->{pdf}->stringify;
  #$self->{pdf}->end;
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Text printing methods

#-----------------------------------------------------------------------

sub print {
  my $self = shift;
  my $text = shift;

  $self->newline;
  $self->print_text_with_style($text);
}


#-----------------------------------------------------------------------

sub print_text_with_style {
  my $self  = shift;
  my $text  = shift;
  my $style = shift;

  #warn "print_text_with_style called with style '$style', text '$text'\n";

  
  $self->set_style($style);
  
  # Remove double  spaces unless we are printing verbatim text
  unless ($self->{stylist}->{$self->{style}}->{verbatim}) {
    $text =~ s/(\s)\s+/$1/g;
  }

  if ($self->space_flag) {
    #
    # Note that this space appears in the default style,
    # but it should be printed in the previous style.
    #
    $self->reset_space_flag;
    $self->set_style('default');
    $self->print_word(' ');
    $self->set_style($style);
  }
  if ($text =~ s/\s+$//) {
    $self->set_space_flag;
  }

  while ($text =~ /(\s+|\S+)/g) {
    my $word = $1;
    $self->print_word($word);
  }
}


#-----------------------------------------------------------------------

sub print_word {
  my $self = shift;
  my $word = shift;
  
  # If we are at the start of a line (newline flag is set) and we are
  # NOT printing verbatim text, then suppress any whitespace.
  if ($self->flag('newline')) {
    #warn "newline flag set\n";
    #warn "x position = $self->{x_position}\n";
  }
  
  
  $self->set_print_flag;
  $self->clear_flag('newline');

    my $width = $self->{text}->advancewidth($word);
    if ($self->{x_position} + $width > $self->{page_width} - $self->{right_margin}) {
      
      # If the word will not fit on one line, split it up and recurse the 'print_word' sub
      if ($width > ($self->{page_width} - $self->{left_margin} - $self->{right_margin} - $self->{indent})) {
        my $fit = int(($self->{page_width} - $self->{left_margin} - $self->{right_margin} - $self->{indent}) / $self->{nspace});
        my @words = (substr($word,0,$fit),substr($word,$fit));
        #warn "Recursing... Word=$word Fit=$fit Xpos=$$self{x_position}\n";
        $self->print_word($_) foreach @words; 
        return;
      }
      
      $self->newline;
      if ($word =~ /^\s+$/) {
        unless ($self->{stylist}->{$self->{style}}->{verbatim}) {
          return;
        }
      }
    }
    $self->{x_position} += $self->{text}->textlabel($self->{x_position},
                                                    $self->{y_position},
                                                    $self->{fontcache}->{$self->{font}},
                                                    $self->{text_size},
                                                    $word,
                                                    -color => $self->{text_color});
    if ($self->{x_position} > $self->{page_width} - $self->{right_margin}) {
      $self->newline;
    }
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

# Text style methods

#-----------------------------------------------------------------------

sub set_style {
  my $self  = shift;
  my $style = shift || 'default';
  
  $style = (exists $self->{stylist}->{$style}) ? $style : 'default';
  #carp "Setting style to $style";
  
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
  $self->{mspace}     = $self->{text}->advancewidth('m');
}


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

1;
