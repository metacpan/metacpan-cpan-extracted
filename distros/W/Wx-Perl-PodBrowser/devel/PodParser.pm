# Copyright 2012, 2013 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.





# require Wx::Perl::PodRichText::PodParser;
# my $parser = Wx::Perl::PodRichText::PodParser->new
#   (richtext => $self);
# $parser->parse_from_filehandle ($fh);
# if ($options{'close_fh'}) {
#   close $fh
#     or $self->WriteText ("\n\n\nError closing filehandle: $!");
# }





package Wx::Perl::PodRichText::PodParser;
use strict;
use warnings;
use Carp;
use Pod::Escapes;
use Pod::ParseLink;
use base 'Pod::Parser';
our $VERSION = 15;

# uncomment this to run the ### lines
#use Smart::Comments;

# sub new {
#   my $class = shift;
#   ### PodRichText-Parser new() ...
#   my $self = $class->SUPER::new (@_);
#   return $self;
# }
#
# sub parse_from_string {
#   my ($self, $str) = @_;
#   open my $fh, '<', \$str
#     or die "Oops, cannot open filehandle on string";
#   $self->parse_from_filehandle ($fh);
# }

my %accept_begin = ('' => 1, # when not in any begin
                    text => 1,
                    TEXT => 1);

# begin/end of whole document
sub begin_pod {
  my $self = shift;
  $self->SUPER::begin_pod(@_);

  $self->{'in_begin'} = '';
  $self->{'in_begin_stack'} = [];
  $self->{'indent'} = 0;

  my $richtext = $self->{'richtext'};
  my $attrs = $richtext->GetBasicStyle;
  my $font = $attrs->GetFont;
  my $font_mm = $font->GetPointSize * (1/72 * 25.4);
  # 1.5 characters expressed in tenths of mm
  $self->{'indent_step'} = int($font_mm*10 * 1.5);
  ### $font_mm
  ### indent_step: $self->{'indent_step'}

  $richtext->Clear;
  $richtext->SetDefaultStyle ($richtext->GetBasicStyle);
  $richtext->BeginSuppressUndo;
  # .6 of a line, expressed in tenths of a mm
  $richtext->BeginParagraphSpacing ($font_mm*10 * .2,  # before
                                    $font_mm*10 * .4); # after
  $richtext->{'section_positions'} = {};
  $richtext->{'heading_list'} = [];
  $self->{'freezer'} = Wx::WindowUpdateLocker->new($richtext);
}
sub end_pod {
  my $self = shift;
  $self->SUPER::end_pod(@_);
  ### end_pod() ...

  delete $self->{'freezer'};
  my $richtext = $self->{'richtext'};
  $richtext->EndSuppressUndo;
  $richtext->EndParagraphSpacing;
  $richtext->SetInsertionPoint(0);
  $richtext->Thaw;
}

sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### $command
  ### $text
  ### $paraobj

  if ($command eq 'begin') {
    push @{$self->{'in_begin_stack'}}, $self->{'in_begin'};
    if ($text =~ /(\w+)/) {
      $self->{'in_begin'} = $1;  # first word only
    } else {
      $self->{'in_begin'} = '';
    }
    return '';
  }
  if ($command eq 'end') {
    $self->{'in_begin'} = pop @{$self->{'in_begin_stack'}};
    if (! defined $self->{'in_begin'}) {
      $self->{'in_begin'} = '';  # if too many =end
    }
    ### pop to in_begin: $self->{'in_begin'}
    return '';
  }

  if (! $accept_begin{$self->{'in_begin'}}) {
    ### ignore: $self->{'in_begin'}
    return ''
  }

  my $richtext = $self->{'richtext'};
  $text =~ s/\s+$//;  # trailing whitespace

  if ($command eq 'over') {
    $self->{'indent'} += $self->{'indent_step'};
  } elsif ($command eq 'back') {
    $self->{'indent'} -= $self->{'indent_step'};

  } elsif ($command =~ /^head(\d*)/) {
    my $level = $1;
    $richtext->BeginLeftIndent($self->{'indent'}
                               + ($level > 1 ? $self->{'indent_step'} / 2 : 0));
    $richtext->BeginBold;
    my $start = $richtext->GetInsertionPoint;
    $self->write_text($text,$linenum);
    $self->set_section_position
      ($richtext->GetRange($start,$richtext->GetInsertionPoint),
       $start);
    $richtext->EndBold;
    $richtext->Newline;
    $richtext->EndLeftIndent;

  } elsif ($command =~ /^item/) {
    if ($text eq '*') {
      $self->{'bullet'} = 1;
    } elsif ($text =~ /^\d+$/) {
      $self->{'numbered_bullet'} = 1;
      $self->{'number'} = $text;
    } else {
      $richtext->BeginLeftIndent($self->{'indent'});
      my $start = $richtext->GetInsertionPoint;
      $self->write_text($text,$linenum);
      $self->set_item_position
        ($richtext->GetRange($start,$richtext->GetInsertionPoint),
         $start);
      $richtext->Newline;
      $richtext->EndLeftIndent;
    }

  } elsif ($command eq 'for') {

  } else {
    carp "Unknown command =$command";
    $richtext->WriteText("=for $command $text");
    $richtext->Newline;
  }
  return '';
}

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock() ...
  ### $text
  ### $linenum
  ### $paraobj

  if (! $accept_begin{$self->{'in_begin'}}) {
    ### ignore: $self->{'in_begin'}
    return ''
  }

  my $richtext = $self->{'richtext'};
  if (delete $self->{'bullet'}) {
    my $start = $richtext->GetInsertionPoint;
    $richtext->BeginStandardBullet("standard/circle",
                                   $self->{'indent'},
                                   $self->{'indent_step'});
    $self->write_text($text,$linenum);
    $self->set_item_position
      ($richtext->GetRange($start,$richtext->GetInsertionPoint),
       $start);
    $richtext->Newline;
    $richtext->EndStandardBullet;

  } elsif (delete $self->{'numbered_bullet'}) {
    my $start = $richtext->GetInsertionPoint;
    $richtext->BeginLeftIndent($self->{'indent'},
                               $self->{'indent_step'});
    $richtext->WriteText($self->{'number'}.'. ');
    $self->write_text($text,$linenum);
    $self->set_item_position
      ($richtext->GetRange($start,$richtext->GetInsertionPoint),
       $start);
    $richtext->Newline;
    $richtext->EndLeftIndent;

    # Numbers bigger than the indent step are drawn overlapped by the text.
    # Use a plain hanging indent para for now.
    # $richtext->BeginNumberedBullet($self->{'number'},
    #                                $self->{'indent'},
    #                                $self->{'indent_step'});
    # $self->write_text($text,$linenum);
    # $richtext->Newline;
    # $richtext->EndNumberedBullet;

  } else {
    $richtext->BeginLeftIndent($self->{'indent'} + $self->{'indent_step'});
    $self->write_text($text,$linenum);
    $richtext->Newline;
    $richtext->EndLeftIndent;
  }
  return '';
}

sub write_text {
  my ($self, $text, $linenum) = @_;
  $text =~ s/\s+$//;  # trailing newlines and other whitespace
  $self->write_ptree ($self->parse_text({}, $text, $linenum));
}

sub write_ptree {
  my ($self, $ptree) = @_;
  ### write_ptree(): $ptree

  my $richtext = $self->{'richtext'};
  foreach my $child ($ptree->children) {
    if (! ref $child) { # text with no markup
      $child =~ s/[\r\n]/ /sg;  # flow newlines
      if ($self->{'in_S'}) {
        $child =~ tr/ /\xA0/;  # non-breaking space
      }
      $richtext->WriteText($child);
      next;
    }
    my $cmd_name = $child->cmd_name;
    if ($cmd_name eq 'Z' || $cmd_name eq 'X') {

    } elsif ($cmd_name eq 'E') {
      my $e = $child->parse_tree->raw_text; # inside of E<>
      #### E: $e
      if (defined (my $char = Pod::Escapes::e2char($e))) {
        $richtext->WriteText($char);
      } else {
        $richtext->WriteText($child->raw_text); # whole E<foo>
      }

    } elsif ($cmd_name eq 'L') {
      my $raw_text = $child->parse_tree->raw_text;
      ### L: $raw_text
      if ($self->{'within_L'}) {
        $richtext->WriteText($raw_text);
      } else {
        my ($text, $inferred, $name, $section, $type)
          = Pod::ParseLink::parselink ($raw_text);
        ### $text
        ### $inferred
        ### $name
        ### $section
        ### $type
        if ($type eq 'url') {
          $richtext->BeginURL ($name);
          $richtext->BeginUnderline;
          $self->write_text($inferred);
          $richtext->EndUnderline;
          $richtext->EndURL;
        } elsif ($type eq 'pod') {
          my $url = 'pod://';
          if (defined $name) { $url .= $name; }
          if (defined $section) { $url .= "#$section"; }
          $richtext->BeginURL ($url);
          $richtext->BeginUnderline;
          $self->write_text($inferred);
          $richtext->EndUnderline;
          $richtext->EndURL;
        } else {
          $richtext->BeginUnderline;
          $self->write_text($inferred);
          $richtext->EndUnderline;
        }
      }

    } elsif ($cmd_name eq 'B') {
      local $self->{'bold'} = 1;
      $richtext->BeginBold;
      $self->write_ptree($child->parse_tree);
      $richtext->EndBold;

    } elsif ($cmd_name eq 'I' || $cmd_name eq 'F') {
      $richtext->BeginItalic;
      $self->write_ptree($child->parse_tree);
      $richtext->EndItalic;

    } elsif ($cmd_name eq 'C') {
      my $font = ($self->{'code_font'} ||= do {
        my $basic_attrs = $richtext->GetBasicStyle;
        my $basic_font = $basic_attrs->GetFont;
        ### basic font facename: $basic_font->GetFaceName
        my $font = Wx::Font->new ($basic_font);
        $font->SetFamily(Wx::wxFONTFAMILY_TELETYPE());
        my $facename = $font->GetFaceName;
        ### $facename
        $font
      });
      if ($self->{'bold'}) {
        $font->SetWeight (Wx::wxFONTWEIGHT_BOLD());
      }
      $richtext->BeginFont($font);
      $self->write_ptree($child->parse_tree);
      $richtext->EndFont;

      # $richtext->BeginTextColour(Wx::wxRED());
      # $richtext->EndTextColour;

      # my $attr = Wx::RichTextAttr->new;
      # my $facename = $font->GetFaceName;
      # ### $facename
      # $attr->SetFontFaceName($facename);
      # $attr->SetFlags (Wx::wxTEXT_ATTR_FONT_FACE());

      # my $start = $richtext->GetInsertionPoint;
      # $self->write_ptree($child->parse_tree);
      # my $end = $richtext->GetInsertionPoint;
      # $richtext->SetStyle(Wx::RichTextRange->new($start,$end),$attr);

      # $richtext->BeginStyle($attr);
      # #$richtext->BeginFont($font);
      # # $richtext->BeginTextColour(Wx::wxRED());
      # # $richtext->EndTextColour;
      # #$richtext->EndFont;
      # $richtext->EndStyle;

    } elsif ($cmd_name eq 'S') {
      local $self->{'in_S'} = 1;
      $self->write_ptree($child->parse_tree);

    } else {
      # carp "Unknown markup $cmd_name<";
      $richtext->WriteText("$cmd_name<");
      $self->write_ptree($child->parse_tree);
      $richtext->WriteText(">");
    }
  }
}

sub verbatim {
  my ($self, $text, $linenum) = @_;

  if (! $accept_begin{$self->{'in_begin'}}) {
    ### ignore: $self->{'in_begin'}
    return ''
  }

  $text =~ s/\s+$//;    # trailing whitespace
  if ($text eq '') {
    ### collapse empty verbatim ...
    return '';
  }

  $text =~ tr/\n/\x1D/; # Wx::wxRichTextLineBreakChar()

  my $richtext = $self->{'richtext'};
  my $basic_attrs = $richtext->GetBasicStyle;
  my $basic_font = $basic_attrs->GetFont;
  my $font = Wx::Font->new ($basic_font->GetPointSize,
                            Wx::wxFONTFAMILY_TELETYPE(),
                            0,
                            0);
  $richtext->BeginLeftIndent($self->{'indent'} + $self->{'indent_step'});
  $richtext->BeginRightIndent(-10000);

  $richtext->BeginFont($font);
  $richtext->WriteText($text);
  $richtext->EndFont;
  $richtext->Newline;

  # $richtext->BeginTextColour(Wx::wxRED());
  # $richtext->EndTextColour;

  $richtext->EndRightIndent;
  $richtext->EndLeftIndent;
  return '';

  # if (my @lines = split /\n/, $text) {
  #   $richtext->WriteText(shift @lines);
  #   foreach my $line (@lines) {
  #     # $richtext->LineBreak;
  #     $richtext->WriteText(chr(29)); # # Wx::wxRichTextLineBreakChar()));
  #     $richtext->WriteText($line);
  #   }
  # }
}

# set the position of $section to $pos
# if $pos is not given then default to the current insertion point
sub set_section_position {
  my ($self, $section, $pos) = @_;
  $section =~ s/\s+$//; # trailing whitespace
  push @{$self->{'heading_list'}}, $section;
  $self->{'section_positions'}->{$section} = $pos;
  $section = lc($section);
  if (! defined $self->{'section_positions'}->{$section}) {
    $self->{'section_positions'}->{$section} = $pos;
  }
}
sub set_item_position {
  my ($self, $item, $pos) = @_;
  $item =~ s/\s+$//; # trailing whitespace
  foreach my $name ($item,
                 ($item =~ /(\w+)/ ? $1 : ())) { # also just the first word
    $self->{'section_positions'}->{$name} = $pos;
    my $lname = lc($name);
    if (! defined $self->{'section_positions'}->{$lname}) {
      $self->{'section_positions'}->{$lname} = $pos;
    }
  }
}

1;
__END__
