# Pod::Lyx -- Convert POD data to a Lyx file.
#
# Copyright 2000 by Richard Jackson <richardj@1gig.net>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# This module is intended to convert Pod to Lyx format ( the Latex WYSIWYM
# editor ).
#

################################################################################
# Modules and declarations
################################################################################

package Pod::Lyx;

require 5.004;

#use Carp qw(carp croak);
use Pod::Parser;
use Text::Tabs;
use locale;

use strict;
use vars qw(@ISA %ESCAPES $VERSION %LyxCodes $VERSION);
$VERSION = 0.25;        # current module version.
@ISA = qw(Pod::Parser);

################################################################################
# Table of supported E<> escapes
################################################################################
# This table was taken from an example pod2lyx converted supplied by
# Amir Karger. And boy am I glad I didn't have to figure this stuff out.
#

%ESCAPES = (
   'amp'       => '&',              #   ampersand
   'lt'        => '<',              #   left chevron, less-than
   'gt'        => '>',              #   right chevron, greater-than
   'quot'      => '"',              #   double quote

   "Aacute"    => "\\i \\'{A}\n",   #   capital A, acute accent
   "aacute"    => "\\i \\'{a}\n",   #   small a, acute accent
   "Acirc"     => "\\i \\^{A}\n",   #   capital A, circumflex accent
   "acirc"     => "\\i \\^{a}\n",   #   sma a, circumflex accent
   "Agrave"    => "\\i \\`{A}\n",   #   capital A, grave accent
   "agrave"    => "\\i \\`{a}\n",   #   small a, grave accent
   "Aring"     => '\\i \\u{A}\n',   #   capital A, ring
   "aring"     => '\\i \\u{a}\n',   #   small a, ring
   "Atilde"    => '\\i \\~{A}\n',   #   capital A, tilde
   "atilde"    => '\\i \\~{a}\n',   #   small a, tilde
   "Auml"      => '\\i \\"{A}\n',   #   capital A, dieresis or umlaut mark
   "auml"      => '\\i \\"{a}\n',   #   small a, dieresis or umlaut mark
   "Ccedil"    => '\\i \\c{C}\n',   #   capital C, cedilla
   "ccedil"    => '\\i \\c{c}\n',   #   small c, cedilla
   "Eacute"    => "\\i \\'{E}\n",   #   capital E, acute accent
   "eacute"    => "\\i \\'{e}\n",   #   small e, acute accent
   "Ecirc"     => "\\i \\^{E}\n",   #   capital E, circumflex accent
   "ecirc"     => "\\i \\^{e}\n",   #   small e, circumflex accent
   "Egrave"    => "\\i \\`{E}\n",   #   capital E, grave accent
   "egrave"    => "\\i \\`{e}\n",   #   small e, grave accent
   "Euml"      => '\\i \\"{E}\n',   #   capital E, dieresis or umlaut mark
   "euml"      => '\\i \\"{e}\n',   #   small e, dieresis or umlaut mark
   "Iacute"    => "\\i \\'{I}\n",   #   capital I, acute accent
   "iacute"    => "\\i \\'{i}\n",   #   small i, acute accent
   "Icirc"     => "\\i \\^{I}\n",   #   capital I, circumflex accent
   "icirc"     => "\\i \\^{i}\n",   #   small i, circumflex accent
   "Igrave"    => "\\i \\`{I}\n",   #   capital I, grave accent
   "igrave"    => "\\i \\`{i}\n",   #   small i, grave accent
   "Iuml"      => '\\i \\"{I}\n',   #   capital I, dieresis or umlaut mark
   "iuml"      => '\\i \\"{i}\n',   #   small i, dieresis or umlaut mark
   "Ntilde"    => '\\i \\~{N}\n',   #   capital N, tilde
   "ntilde"    => '\\i \\~{n}\n',   #   small n, tilde
   "Oacute"    => "\\i \\'{O}\n",   #   capital O, acute accent
   "oacute"    => "\\i \\'{o}\n",   #   small o, acute accent
   "Ocirc"     => "\\i \\^{O}\n",   #   capital O, circumflex accent
   "ocirc"     => "\\i \\^{o}\n",   #   small o, circumflex accent
   "Ograve"    => "\\i \\`{O}\n",   #   capital O, grave accent
   "ograve"    => "\\i \\`{o}\n",   #   small o, grave accent
   "Otilde"    => "\\i \\~{O}\n",   #   capital O, tilde
   "otilde"    => "\\i \\~{o}\n",   #   small o, tilde
   "Ouml"      => '\\i \\"{O}\n',   #   capital O, dieresis or umlaut mark
   "ouml"      => '\\i \\"{o}\n',   #   small o, dieresis or umlaut mark
   "Uacute"    => "\\i \\'{U}\n",   #   capital U, acute accent
   "uacute"    => "\\i \\'{u}\n",   #   small u, acute accent
   "Ucirc"     => "\\i \\^{U}\n",   #   capital U, circumflex accent
   "ucirc"     => "\\i \\^{u}\n",   #   small u, circumflex accent
   "Ugrave"    => "\\i \\`{U}\n",   #   capital U, grave accent
   "ugrave"    => "\\i \\`{u}\n",   #   small u, grave accent
   "Uuml"      => '\\i \\"{U}\n',   #   capital U, dieresis or umlaut mark
   "uuml"      => '\\i \\"{u}\n',   #   small u, dieresis or umlaut mark
   "Yacute"    => "\\i \\'{Y}\n",   #   capital Y, acute accent
   "yacute"    => "\\i \\'{y}\n",   #   small y, acute accent
   "yuml"      => '\\i \\"{y}\n',   #   small y, dieresis or umlaut mark
#TODO how to do ligatures in LyX? Use latin1?
#  "AElig"     => '\\AE',           #   capital AE diphthong (ligature)
#  "aelig"     => '\\ae',           #   small ae diphthong (ligature)
#  "ETH"       => '\\OE',           #   capital Eth, Icelandic
#  "eth"       => '\\oe',           #   small eth, Icelandic
#  "Oslash"    => "\\O",            #   capital O, slash
#  "oslash"    => "\\o",            #   small o, slash
#  "szlig"     => '\\ss{}',         #   small sharp s, German (sz ligature)
#  "THORN"     => '\\L',            #   capital THORN, Icelandic
#  "thorn"     => '\\l',,           #   small thorn, Icelandic
);

# these are LyX codes that can be embeded into a paragraph.
# note the value means that another word follows the current match.
# A 1 means one word follows a 2 means two words follow ect...

%LyxCodes = (
   "\\protected_separator"    => 0,    # a protected separator
   "\\series"                 => 1,    # the begining of a series change..
   "\\shape"                  => 1,    # a shape change
   "\\family"                 => 1,    # a change in font family
   "\\backslash"              => 0,    # a backslash
   # their are more codes but these are the ones we are using for now.
);


################################################################################
# Initialization
################################################################################
# Initialize the object. Must be sure to call our parent initializer...
#
sub initialize {
   my $self = shift;

   # by default use the article textclass..
   $$self{textclass}    = "article" unless defined $$self{textclass};
   $$self{alt}          = 0 unless defined $$self{alt};
   $$self{indent}       = 0;
   $$self{tab}          = 4 unless defined $$self{tab};
   $$self{MODE}         = "";    # the current translation mode we are in.
   $$self{ListLevel}    = 0;     # the current list level
   $$self{listdata}     = "";    # used to hold a list data item...
   $$self{outbuff}      = "";    # used to hold the output buffer.
   $$self{deeper}       = 0;     # used to indicate that we have forced a
                                 # to a deeper indention level.
   $$self{verbatimspace} = 0 unless defined $$self{verbatimspace};
   $$self{over}         = 0;     # indicates wheter or not we have output a
                                 # over command.
   $$self{paragraph}    = 0;     # How many paragraphs have we output while in
                                 # a list/enumerate/itimize context.

   $self->SUPER::initialize;

}

################################################################################
#===============================================================================
# Core overrides
#===============================================================================
################################################################################

################################################################################
# command
################################################################################
# Called for each command paragraph. Gets the command, the associated paragraph,
# the line number, and a Pod::Paragraph object.
#
# Just dispatches the command to a method named the same as the command. =cut
# is handled internally by Pod::Parser.

sub command {
   my $self = shift;
   my $command = shift;
   return if $command eq 'pod';  # don't need to process the pod command...
   $command = 'cmd_' . $command;
   $self->$command(@_);
}

################################################################################
# verbatim
################################################################################
# Called for verbatim paragraph. Gets the paragraph, the line number, and a
# Pod::Paragraph object.
# NOTES:
#  1. We use Lyx-Code for verbatim text.
#  2. Our incomming paragraph has to be reformated such that multiple spaces
#     must be converted into protected spaces.
#  3. If there is a blank line following a line of code it will be included
#     in the paragraph so we must catch this so a protected newline can be
#     inserted. One problem with this is we end up with extra lines in the
#     document that don't need to be there. I have an idea how to fix this
#     But I haven't implemented it yet.
#

sub verbatim {
   my $self = shift;
   return if $$self{EXCLUDE};
   local $_ = shift;
   my($temp);
   my($newlines) = 0;   # number of newlines to insert after a line of verbatim
                        # code...
   my(@tArray);         # temp array holder...
   my(@lines);          # paragraph lines

   # see if this is our first line of verbatam text...
   if ( !($$self{MODE} eq "verbatim" ) ) {
      $self->mode_switch("verbatim");     # call switching code..
      # on a first pass we need to see what the indention level is on the
      # source code or verbatim paragraph...
      # LyX automaticly indents verbatim paragraphs so we are going to
      # remove any leading spaces..
      $$self{indent} = 0;  # zero our indent setting...
      ###################################################################
      # if the pod only contains code in verbatim blocks we may want to
      # reformat it so that it looks nice.

      if (defined( $$self{vcode} ) ) {
         my @chars = split(//, $_); # split the line so we can count the leading
                                    # spaces...
         while ( $chars[$$self{indent}] eq ' ' ) {
            $$self{indent}++;
         }
      }
      else {
         # set our indent level to the current tab stop
         $$self{indent} = $$self{tab}; # this is so it looks ok under LyX....
      }

   } else {
      if ( !($$self{outbuff} eq "" )) {
         $self->output($$self{outbuff});
         $$self{outbuff} = "";
      }
   }

   # Before we do any thing else we need to see how many newlines are at the
   # end of the paragraph so we can format it correctly..
   $temp = length($_);     # Note is will cause problems if the string is
                           # in a multibyte encoding
   $temp--;                # zero base the length...
   @tArray = split(//, $_);   # split the line up so we can take a look at it..
   while ( ( $tArray[$temp] eq "\n" ) and ( $temp >= 0 ) ) {
      $newlines++;
      $temp--;
   }
   $newlines--;   # The end of paragraph will have at least one new line so
                  # we don't want to count it..

   # Ok we now know how many blank lines follow the paragraph.
   # now we need to format it.

   # first we need to split the paragraph up into lines
   @lines = split(/\n/, $_ );

   foreach ( @lines ) {
      # First remove the leading spaces from the line. The max
      # number of spaces removed will be the indent value we got earler on..
      #### forgot to add tab expantion :( NOTE: According to Perlpod tabs are
      # to be assumed to be 8 char's in length. But if you take a look at
      # Text.pm it assumes a 4 char tab!!! :( Which do I use? Hell I'm gona
      # use the 4 chars that Text.pm uses because the output looks right.
      # I need to make this an option...
      $tabstop = $$self{tab};
      $_ = expand($_);

      $temp = $$self{indent};
      # Now remove indent number of spaces...
      # I know this doesn't look good but we can't hard code the indent value
      # as I've run across some pod's that use 3 spaces and some that use 4 spaces
      # and we only want to remove the indented value and no more!
      while ( $temp > 0 ) {
         $_ =~ s/^\s//;
         $temp--;
      }
      # now output the Lyx command to have this data look right..
      $self->output("\\layout LyX-Code\n\n");

      # now pull any newlines off the end of the line..
      s/\n+//;    # we only want 1 newline so lets make sure we only have one.
      s/\\/\n\\backslash \n/g;      # must replace backslases note the space
                                    # before the newline needs to be there.
      s/\s/\n\\protected_separator \n/g;  # replace all spaces
      $self->output($_ . "\n");
   }

   # output any extra newlines that we need. Note: we don't actual out put
   # this here we just format the output line
   if ($newlines) {
      while ($newlines > 0 ) {
         $$self{outbuff} .= "\\newline \n \n"; # LyX puts a space after newline
         $newlines--;                     # not sure why but it does...so we
      }                                   # are going to as well...
   }

}

################################################################################
# textblock
################################################################################
# Called for regular text block. Gets the paragraph, the line number, and
# a Pod::Paragraph object. Perform interpolation and output the results.
#

sub textblock {
   my $self = shift;
   return if $$self{EXCLUDE};

   local $_ = shift;
   my $line = shift;
   my @input_lines;
   my $buffer;

   # before we do anything else check for \ and replace it...
   s/\\/\n\\backslash \n/g;

   if ( !( $$self{MODE} eq "textblock") ) {
      # ok we have to determin how this was called which can be a little tricky.
      # and we have to make some assumptions about certin things...
      # for all list type items we just dumb the paragraph..
      if ( ( $$self{MODE} eq "itemize" ) or ( $$self{MODE} eq "enumerate") ) {
         $_ = $self->interpolate($_, $line);
         $_ = $self->wrap( $_ );
         $self->output( $_ );
         $$self{paragraph}++;
         $$self{MODE} = "";      # must unset the mode.
         return;
      }
      if ( $$self{MODE} eq "list" ) {  # lists must be handled differantly..
         # Ok I ran across an issue where the list name had multiple words
         # in it which would cause the output to not look right. So we need
         # to account for it.
         # $_ = $$self{listdata} . " " . $_;
         # $$self{listdata} = "";
         $_ = $self->interpolate($_, $line);
         $buffer = $self->wrap( $_ );
         # now lets handle the case where their may be more than one word in
         # the list name.
         $_ = $$self{listdata};
         if ( /\\/ ) {  # if there are any back slashes that means their is more
                        # more than one word...
            $_ = $self->interpolate($_, $line);
            $self->output( $_ . "\n "); # note the space is important.
            $self->output($buffer);
         } else {
            $_ = $self->interpolate($_, $line);
            $self->output( $_ . " " . $buffer);
         }

         $$self{paragraph}++;
         $$self{MODE} = "";      # must unset the mode.
         $$self{listdata} = "";  # must unset the list data.
         return;
      }

      $self->mode_switch("textblock");

   }

   #Now actually interpolate and output the paragraph.
   $_ = $self->interpolate($_, $line);
   $_ = $self->wrap( $_ );
   $self->output( "\\layout Standard\n\n" . $_ );

}

################################################################################
# interior_sequence
################################################################################
# Called for interior sequence. Gets the command, argument, and a
# Pod::InteriorSequence object and is expected to return the resulting text.
# Calls code, bold, italic, file, and link to handle those types of
# sequences, and handles S<>, E<>, X<>, and Z<> directly.

sub interior_sequence {
   my $self = shift;
   my $command = shift;
   local $_ = shift;

   # before we continue we need to reconize certin cases that can cause problems
   # in particular putting bold text on one of the =head1 or =head2 lines.
   # in these cases we just return the text with no modifications...
   if ( ($$self{MODE} eq "head1") or ($$self{MODE} eq "head2") ) {
      return $_;
   }

   # first lets deal with the most common cases..
   #### BOLD #########
   if ( $command eq 'B' ) {
      return ( "\n\\series bold \n" . $_ . "\n\\series default \n");
   }

   #### ITALICS ############
   if ( $command eq 'I') {
      return ( "\n\\shape italic \n" . $_ . "\n\\shape default \n");
   }

   ###### CODE OR TYPEWRITER TEXT ######
   if ( $command eq 'C') {    # ran across a issue where the typewritertext
                              # included a \ in it so we need to check for it.
      #s/\\/\n\\backslash \n/g;   # replace \ with the command "\backslash\n"
      return ( "\n\\family typewriter \n" . $_ . "\n\\family default \n");
   }

   #### NON BREAKING SPACES ##########
   if ( $command eq 'S' ) {
      return cmd_space($_);
   }

   ##### LINK OR CROSS REFERENCE ##########
   if ( $command eq 'L' ) {
      return cmd_link($_);     # for now do nothing. I intend to come back to this
                     # once basic functions are working.
   }

   #### FILE NAME #################
   if ( $command eq 'F' ) {
      return $_;     # for now do nothing. I intend to come back to this
                     # at a later date.
   }

   ##### INDEX ################
   if ( $command eq 'I' ) {
      return;        # for now do nothing. I intend to come back to this.
   }


}

################################################################################
#===============================================================================
# Optional overrides..
#===============================================================================
################################################################################

################################################################################
# begin_pod
################################################################################
# This sub is invoked at the beginning of processing for each POD document that
# is encountered in the input.
#
# This is being overriden so that we can write the LyX header information into
# the output file.
#

sub begin_pod {
   my $self = shift;
   my $out_fh = $self->output_handle();
   my $buffer;

   print $out_fh "#pod2lyx created this file on: " . localtime()  . "\n";
   print $out_fh <<HEAR_DOC;
#LyX 1.1 (C) 1995-2000 Matthias Ettrich and the LyX Team
#For more information on LyX see http://www.lyx.org/
#For more information on pod2lyx see http://.....
\\lyxformat 2.15
\\textclass $$self{textclass}
\\language default
\\inputencoding latin1
\\fontscheme default
\\graphics default
\\paperfontsize default
\\spacing single
\\papersize Default
\\paperpackage a4
\\use_geometry 1
\\use_amsmath 0
\\paperorientation portrait
\\leftmargin 17mm
\\topmargin 12mm
\\rightmargin 17mm
\\bottommargin 12mm
\\secnumdepth 3
\\tocdepth 3
\\paragraph_separation indent
\\defskip medskip
\\quotes_language english
\\quotes_times 2
\\papercolumns 1
\\papersides 1
\\paperpagestyle defualt

HEAR_DOC

   # ok the main preamble is done now lets set the title...
   # note lyx_title is set by the class user when they create the class..
   if (defined $$self{lyx_title} ) {
      print $out_fh "\\layout Title\n\n" . $$self{lyx_title} . "\n";
      if ( (defined $$self{footnote}) and !($$self{footnote}) ) {
         print $out_fh "\\begin_float footnote \n\\layout Standard\n\n";
         $buffer = "Generated by pod2lyx V" . $VERSION . " from " . $$self{podfile};
         # Ok I don't know why this is but if the line wrapping mode for foot
         # notes is differant than every thing else. Basicly if $buffer is
         # greater than 82 char's long then the document doesn't look right
         # in LyX also the page break will not be reconized either.
         my $test = length($buffer);
         if ( length($buffer) > 83 ) {
            substr($buffer, 82, 0) = "\n";
         }
         print $out_fh $buffer . "\n\\end_float \n";
      }
      print $out_fh "\\layout Standard\n";
   }

   # insert a page break if the class user asked for it...
   if (defined $$self{lyx_index_break} and $$self{lyx_index_break} ) {
      print $out_fh "\\pagebreak_bottom ";
   }

   # insert a index if the class user asked for it...
   if ( (defined $$self{lyx_index} ) and $$self{lyx_index} ) {
      # do we want an index?
      print $out_fh "\n\n\\begin_inset LatexCommand \\tableofcontents{}\n\n\\end_inset \n\n\n";
   }


# note the blank line needs to be there...

}

################################################################################
# end_pod
################################################################################
# This method is invoked at the end of processing for each POD document.
# we mearly need to output the LyX end code....

sub end_pod {
   my $self = shift;

   $self->output("\\the_end");
}


################################################################################
#
# Addtional methods specific to Lyx.
#
################################################################################

################################################################################
# output
################################################################################
# Used to output or write the file....
#

sub output {
   my $self = shift;
   my $out_fh = $self->output_handle();

   if( defined($_) ) {
      print $out_fh @_;
   }

}


################################################################################
# cmd_head1
################################################################################
# First level heading paragraph...
# This outputs the heading and generates a label so we can do cross referances
# later on in the code...
#

sub cmd_head1 {
   my $self = shift;
   return if $$self{EXCLUDE};

   local $_ = shift;
   my $label = $_;

   $$self{MODE} = "head1";

   $_ = $self->interpolate($_, shift);

   # if the heading is blank return...
   if( $_ =~ /^\n+/ ) {
      return;
   }

   s/\n+//; # srip the newlines off the end so we don't get multiple
            # blank lines in the output stream... We only one one newline
            # so we force it to that...
   $self->output("\\layout Section\n\n" . $_ . "\n");

   $label =~ s/\n//g;
   $label =~ s/\s/_/g;
   $label = "\L$label";    # convert the section name to lower case.
   $self->output("\\begin_inset LatexCommand \\label{sec:" . $label . "}\n\n\\end_inset \n\n\n");

}

################################################################################
# cmd_head2
################################################################################
# Second Level heading
#

sub cmd_head2 {
   my $self = shift;
   return if $$self{EXCLUDE};

   local $_ = shift;
   my $label = $_;

   $$self{MODE} = "head2";

   $_ = $self->interpolate($_, shift);

   if( $_ =~ /^\n+/ ) {
      return;
   }

   s/\n+//; # srip the newlines off the end. We only want one newline so
            # we force the issue...
   $self->output("\\layout Subsection\n\n" . $_ . "\n");

   $label =~ s/\n//g;
   $label =~ s/\s/_/g;
   $label = "\L$label";    # convert the section name to lower case.
   $self->output("\\begin_inset LatexCommand \\label{sec:" . $label . "}\n\n\\end_inset \n\n\n");

}

################################################################################
# cmd_over
################################################################################
# Start a list!!!
# We need to keep track of the nesting level of lists. We don't realy need
# to worry about how much to indent it but we do need to know the lists level
# for cases of lists of lists.

sub cmd_over {
   my $self = shift;
   $$self{ListLevel}++;    # increase our list level...

   if ( $$self{ListLevel} > 1 ) {
      $self->output("\\begin_deeper\n");
   }
}

################################################################################
# cmd_back
################################################################################
# End a list....
# We need to keep track of the nesting level of lists. All we are doing
# here is decrimenting our list level holder..

sub cmd_back {
   my $self = shift;
   $$self{ListLevel}--; ## decriment out list level..
   # we also have to output the command to LyX to know that we are backing out
   # one level..
   if ($$self{ListLevel} > 0 ) {
      $self->output("\\end_deeper\n");
      $$self{MODE} = "";      # this will wipe out a list context..
   }
   if ($$self{over}) {
      $self->output("\\end_deeper\n");
   }

}

###############################################################################
# cmd_item
###############################################################################
# An individual list item...
#
# The problem: Pod::Parser pases each =item into this procedure so we must
# determin what type of item this is. The types we must determin are:
# * which means a built list
# # where # equals sum number means a numberd list
# [a-z] equals some list item...
# so we have three modes we need to account for
# 1) a numbered list or enumerate in LyX speek.
# 2) a bullet list or itemize in LyX speek.
# 3) a word list. or list in LyX speek.

sub cmd_item {
   my $self = shift;
   local $_ = shift;
   my $tempbuff = "";   # temp buffer

   s/^item //;          # strip the item section off the command. Notice the
                        # space we want that gone as well.
   s/\s+$//;            # strip all trailing spaces and newlines

   if ( $_ eq "*" ) {      # we have a bullet list
      if (!( $$self{MODE} eq "itemize") ) {
         $self->mode_switch("itemize");
      }
      $self->output("\\layout Itemize\n\n"); # note the data for the item will
                                             # be handled by the standard
                                             # paragraph handler...
      $$self{paragraph} = 0;  # reset our paragraph counter..
      return;
   }

   if ( /^\d+/ ) { # we have a numbered list...
      if ( !( $$self{MODE} eq "enumerate") ) {
         $self->mode_switch("enumerate");
      }
      $self->output("\\layout Enumerate\n\n");
      $$self{paragraph} = 0;
      return;
   }

   if ( /\w+/ ) { # do we have a list? NOTE the test for a number list must come
                  # first or this will not work correctly...
      if (!($$self{MODE} eq "list" )) {
         $self->mode_switch("list");
      }
      # Ok I ran into another bug :( Where a list would not have an assiated
      # paragraph so we must take care of it here..
      if ( !( $$self{listdata} eq "") ) {
         $tempbuff = $self->interpolate( $$self{listdata} , 0);
         $self->output( $tempbuff . "\n");
      }

      $self->output("\\layout List\n\\labelwidthstring 00.00.0000\n\n");
      # I'm not sure what the labelwidthstring does but it is needed.
      # also if the list head has spaces in it we must escape them...
      s/\s/\n\\protected_separator\n/g;
      $$self{listdata} = $_;
      $$self{paragraph} = 0;
      return;
   }

}

###############################################################################
# cmd_begin
###############################################################################
# Begin a block for a particular translator. Setting VERBATIM triggers
# special handling in textblock().
# What this does is eliminate __PRIVATE__ text blocks...

sub cmd_begin {
   my $self = shift;
   local $_ = shift;

   my($kind) = /^(\S+)/ or return;
   if ($kind eq 'text') {
      $$self{VERBATIM} = 1;
   } else {
      $$self{EXCLUDE} = 1;
   }

}

################################################################################
# cmd_end
################################################################################
# End a block for a particular translator. We assume that all =begin/=end
# pairs are properly closed..
#

sub cmd_end {
   my $self = shift;
   $$self{EXCLUDE} = 0;
   $$self{VERBATIM} = 0;
}

################################################################################
# cmd_for
################################################################################
# Special format sections: for now we just ignore them.
# But we need a place holder so Pod::Parser won't complain :)
#

sub cmd_for {
   return;
}

################################################################################
# wrap
################################################################################
# This function wraps a paragraph such that LyX will understand it correctly..
#
# If I could use Text::Wrap for this I would but the problem is that the
# paragraph can have embeded control seqences that must be formated correctly
# or we will have problems.
# Actualy Text::Wrap works with the current LyX parser but that is no guantee
# that it will work in the future. So I'm writing this to be on the safe side.
#
# Found a bug in this code in that LyX formats a paragraph such that each line
# will wrap at around 78 not 80 and a sentance ends the wraping. NOTE: I call
# this a bug because LyX does somthing differant when savaing a file than what
# I'm doing here. So I'm trying to fixit such that they match as much as
# posable.

sub wrap {
   my $self = shift;
   local $_ = shift;

   my $cols = 80;    # line length
   my @words;        # array of words
   my $output;       # our output paragraph formated correctly.
   my $val;          # current word we are working on.
   my $curlen = 0;   # the current line length.
   my $code = 0;     # are we processing a LyX code?
   my $lines = 0;        # how many lines have we output?


   # all kinds of stuff can be embeded into a paragraph so we need to make sure
   # to catch it all if possible...
   @words = split( /\s+/, $_ );

   foreach $val (@words) {
      # process key words...
      if ( ( defined( $LyxCodes{$val} ) ) or $code ) {
         if ( $code ) {                # are we in a keyword pair?
            $output .= $val . "\n";   # yes so stick the next key word on the end.
            $code = 0;                 # reset our code value.
            $curlen = 0;               # reset our line length..
            next;                      # go back to the top.
         }
         if ( $LyxCodes{$val} == 0 ) { # is this a single key word?
            if ( $curlen > 0 ) {
               chop $output;           # remove trailing space..
               $lines++;               # increment the line counter
                                       # only if there is already part of a line
                                       # in the output stream...
            }
            $output .= "\n" . $val . "\n";    # yes so dump it...
            $curlen = 0;               # reset our line length..
            next;
         } else {                      # has to be a multiword pair
            if ($curlen > 0) {
               chop $output;           # remove trailing space.
               $lines++;
            }
            $output .= "\n" . $val . " ";
            $code = 1;
            next;
         }
      }
      # Ok this is not a key word so we need to process it...
      # Note this section of code will puke when the input has double byte
      # chars in it...After I get the single byte stuff working I'll look
      # into doing double byte chars..if users ask for it that is.

      # I ran into a case where a control sequance starts a paragraph
      # that a space and or a \n just will get through
      # split so we need to check for it... Well actualy after some work
      # what gets through is '' which if this wasn't here
      # whould put a space into the stream :( So I removed the checkes
      # for \n and ' ' but put a check in for '' so we don't add a space
      # into the output stream.
      if ( $val eq '' ) {
         next;    # don't process it....
      }

      if ( ( $curlen + length($val) + 1 ) > $cols ) {
         chop $output;
         $output .= "\n " . $val . " ";
         $curlen = length($val) + 1;
         $lines++;                  # note control lines don't count!
         if ( $val =~ /\.$/ ) {
            $output .= "\n ";
            $lines++;
         }
      } else {
         if ( ( $curlen == 0 ) and ( $lines > 0 ) ) {
            $output .= " " . $val . " ";
            $curlen += length($val) + 2;
         } else {
            if ( $val =~ /\.$/ ) {    # is this an end of sentance?
               $output .= $val . "\n ";
               $curlen = 1;      # the space...
               $lines++;
               next;
            }
            $output .= $val . " ";
            $curlen += length($val) + 1;
         }
      }


   }
   chop $output;
   $output .= "\n";
   return $output;
}

################################################################################
# cmd_space
################################################################################
# this function handles the S<> interer item..
# the problem is that S<> can contain other commands embeded in it so we need
# to watch out for it. Also what we are doing is replacing spaces which makes
# this a little more dificult because we end up having to process this thing
# one char at a time to make it work :( I'm sure a regular expresion guru could
# make this work better but I'm not their yet...

sub cmd_space {
   local $_ = shift;
   my @lines;        # array of chars...
   my $output = '';  # our output formated correctly.

   @lines = split( /\n/, $_ );      # break the input up into lines....

   foreach (@lines) {
      if ( /^\\/ ) {
         $output .= "\n" . $_ . "\n";
      } else {
         s/\s/ \n\\protected_separator \n/g;
         $output .= $_ . "\n";
      }
   }
   return($output);
}

################################################################################
# cmd_link
################################################################################
# This function handles the L<> interer item..
# Links come in mainly two forms:
# 1) links to items contained in this document
# 2) Links to items outside this document.
#
# We are going to try to handle both of these cases.

sub cmd_link {
   local $_ = shift;
   my $manpage;         # manpage link
   my $section;         # section ref.

   my $output = '';     # out output formated correctly...

   # if the pod contained some text for use to output use it...
   if ( /\|/ ) {
      ($output, $manpage) = split(/\|/, $_, 2);
      return $output;
   }
   # Ok the pod did not provide any link text so lests figure out what we need
   # to do..

   # leading and trailing whitespace isn't important; get rid of it..
   #s/^\s+//;
   #s/\s+$//;



   return $_;
}


################################################################################
# mode_switch
################################################################################
# this function is used when switching modes from one type of paragraph to
# another. It handles a few things that need to be cleaned up when switching
# modes...It also sets the current mode when it needs to be set...
#

sub mode_switch {
   my $self = shift;
   my $Caller = shift;     # who called this function....

   if ($$self{MODE} eq "verbatim" ) {
      # what we are doing here is removing trailing newlines so we get a more
      # compact document. We allow the user of this module to set wether or
      # not we do this..
      if ( $$self{verbatimspace} ) {
         $self->output($$self{outbuff});
      }
      $$self{outbuff} = "";
   }

   if ( ($Caller eq "verbatim") and ( ($$self{MODE} eq "list") or
                                      ($$self{MODE} eq "itemize") or
                                      ($$self{MODE} eq "enumerate")) ) {
      if (!($$self{listdata} eq "" ) ) {
         $self->output("$$self{listdata} \n");
      }

   }

   if ( $$self{ListLevel} ) {
      # We are inside a list so we need to take the apropriate acction..
      # NOTE this function does not get called for the first paragraph in a
      # list.
      # if one of the lists is calling us we don't need to worry about it.
      if ( ($Caller eq "list") or ($Caller eq "itemize") or
           ($Caller eq "enumerate") ) {
         if ( $$self{over} ) {
            $self->output("\\end_deeper\n");
            $$self{over} = 0;
         }
         $$self{MODE} = $Caller;
         return;
      }
      if ( $$self{over} ) {      # have we already moved over?
         $self->output("\\end_deeper\n"); # move back...
         # now we know that this is not in a list context so what we have
         # is another paragraph inside the list so we need to also move it
         # over as well...
         $self->output("\\begin_deeper\n");
         $$self{over} = 1;
         $$self{MODE} = $Caller;
         return;
      }
      # other wise we need to fix some things up..
      $self->output("\\begin_deeper\n");
      $$self{over}++;
      $$self{MODE} = $Caller;
      return;
   }

   $$self{MODE} = $Caller;


}

1;

