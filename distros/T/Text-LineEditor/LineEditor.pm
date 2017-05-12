package Text::LineEditor;
#
# ObLegalStuff:
#    Copyright (c) 1998 Bek Oberin. All rights reserved. This program is
#    free software; you can redistribute it and/or modify it under the
#    same terms as Perl itself.
#
# Last updated by gossamer on Sun Sep  6 21:03:23 EST 1998
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

use Term::ReadLine;

@ISA = qw(Exporter);
@EXPORT = qw( line_editor );
@EXPORT_OK = qw();

$VERSION = "0.03";

#
# Constants
#

# When starting editing
my $Initial_Prompt = 
   "Enter your message: ('.' by itself on a line to end, ~h for help)";

# Before each line is input
my $Line_Prompt = "> ";

# Before editor messages
my $Message_Prompt = "*** ";

my $Tempfile_Name = "/tmp/lineeditor.$$";

#
# Function
#

sub find_editor {
   return $ENV{"VISUAL"} || $ENV{"EDITOR"} || "vim" || "vi" || "pico";
}

=head1 NAME

Text::LineEditor - simple line  editor

=head1 SYNOPSIS

   use Text::LineEditor;

   $text = &line_editor();

=head1 DESCRIPTION

C<Text::LineEditor> implements a -very- simple editor like Berkley
mail used to use.

=head1 FUNCTIONS

=item line_editor ();

Returns the text entered.  If the text has been abandoned with
~x it returns an empty string.

=head1 EDITING COMMANDS

To append text, just type.
To end, type '.' by itself on a line.
Tilde commands for editing (by themselves on a line):
   ~h     This help message
   ~e, ~v Edit message using visual editor
   ~w <filename>
          Write current text to file <filename>
   ~p     Print current text using 'lpr'
   ~.     End message as normal
   ~x     Quit, abandon text

=cut
sub line_editor {
   my $text;

   my $finished = 0;

   my $Input = new Term::ReadLine 'LineEditor';

   print $Initial_Prompt . "\n";
   while (!$finished) {

      my $line = $Input->readline($Line_Prompt);  # NB  readline() removes \n

      if ($line =~ m/^\.$/) {
         # dot by itself - end
         $finished++;

      } elsif ($line =~ m/^~(.)(.*)$/) {
         # Something magic

         if ($1 eq 'h') {
            # give help
            print <<"EOT";
To append text, just type.
To end, type '.' by itself on a line.
Tilde commands for editing (by themselves on a line):
   ~h     This help message
   ~e, ~v Edit message using visual editor
   ~w <filename>
          Write current text to file <filename>
   ~p     Print current text using 'lpr'
   ~.     End message as normal
   ~x     Quit, abandon text
EOT
         } elsif ($1 eq '.') {
            # same as regular ending
            $finished++;
         } elsif ($1 eq 'w') {
            # write to a file
            open(OUTFILE, ">$2");
            print OUTFILE $text;
            close(OUTFILE);
         } elsif ($1 eq 'p') {
            # print
            open PRINTER, "| lpr" ||
               warn "Can't open printer: $!\n"; 
            print PRINTER $text; 
            close PRINTER;
         } elsif (($1 eq 'e') || ($1 eq 'v')) {
            # visual editor
            my $editor = &find_editor;
            if ($editor) {
               open(OUTFILE, ">$Tempfile_Name");
               print OUTFILE $text;
               close(OUTFILE);

               system($editor, $Tempfile_Name);

               open(OUTFILE, "<$Tempfile_Name");
               undef $/;
               $text = <OUTFILE>;
               close(OUTFILE);

               #print "DEBUG:  '$text'\n";
            } else {
               print $Message_Prompt . "Can't find an editor to use!\n";
            }

         } elsif ($1 eq 'x') {
            $finished++;
            $text = "";
         } else {
            print $Message_Prompt . "Unknown tilde escape '$line'\n";
         }

      } else {
         # regular line

         $text .= $line . "\n"; 
      }
   }

   return $text;
}

#
# End.
#
1;
