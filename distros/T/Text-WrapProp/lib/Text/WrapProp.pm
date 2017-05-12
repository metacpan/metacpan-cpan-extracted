package Text::WrapProp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT_OK = qw( wrap_prop );
@EXPORT = qw();

$VERSION = '0.05';

1;

sub wrap_prop {
   my ($text, $width, $ref_width_table) = @_;

   if (not defined $text) {
      return('', 1);
   }
   elsif (not defined $width or $width < 0.0000001) {
      return('', 2);
   }
   elsif (not defined $ref_width_table or ref($ref_width_table) ne 'ARRAY' or scalar(@{$ref_width_table}) <= 1) {
      return('', 3);
   }
   elsif ($text eq '') {
      return('', 0);
   }

   my @width_table = @{$ref_width_table};

   # simplify whitespace, including newlines
   $text =~ s/\s+/ /gs;

   my $c;            # current character
   my $ltext    = length $text;
   my $cursor   = 0; # width so far of line
   my $out      = ''; # output buffer
   my $nextline = '';

   my $i=0;

   while ($i < $ltext) {
         # pop off next character
         $c = substr($text, $i++, 1);
         
         # don't need leading spaces at start of line
         next if $nextline eq '' and $c eq ' ';

         # see if character will fit on line - but don't include if too long
         if ($cursor + $width_table[ord $c] < $width + 0.0000001) {
            # another character fits
            $nextline .= $c;
            $cursor += $width_table[ord $c];
         }
         else {
            # find where we can wrap by checking backwards for separator
            my $j = length($nextline);
            for (split //, reverse $nextline) { # find separator
               $j--;
#               last if /( |:|;|,|\.|-|\(|\)|\/)/o; # separator characters
               last if /[ :;,.()\\\/-]/; # separator characters
            }

            # see if no separator found
            if (!$j) { # no separator, so just truncate line right here
               $i--; # rerun on $c
               $out .= $nextline."\n";
            }
            # 
            else { # separator found, so break line at separator
               $i -= length($nextline) - $j; # rerun characters after separator
               $out .= substr($nextline, 0, $j+1)."\n";
            }

            $nextline = '';
            $cursor = 0;
         }
# print "i=$i, ltext=$ltext, cursor=$cursor, out=$out\n\n";
   }

   return($out.$nextline, 0);
}

__END__

=head1 NAME

Text::WrapProp - proportional line wrapping to form simple paragraphs

=head1 SYNOPSIS 

 use Text::WrapProp qw(wrap_prop);

 my ($output, $status) = wrap_prop($text, $width, $ref_width_table);
 print $output if !$status;

=head1 DESCRIPTION

Text::WrapProp::wrap_prop() is a very simple paragraph formatter
for proportional text. It formats a
single paragraph at a time by breaking lines at word boundries.
You must supply the column width in floating point units which should
be set to the full width of your output device. A reference to a
character width table must also be supplied. The width units
can be any metric you choose, as long as the column width and
the width table use the same metric.

Proportional wrapping is commonly used in the publishing
industry. In HTML, custom proportional wrapping is less often
performed as the browser performs the calculations automatically.

=head1 RETURN VALUES

wrap_prop returns a list: (text string, integer status). For invalid parameters, the empty string '' and a non-zero status.

=head1 EXAMPLES

 use strict;
 use diagnostics;

 use Text::WrapProp qw(wrap_prop);

 my @width_table = (0.05) x 256;
 my ($output, $status) = wrap_prop("This is a bit of text that forms a normal book-style paragraph. Supercajafrajalisticexpialadocious!", 4.00, \@width_table);
 print $output if !$status;

See eg/ for more examples.

=head1 BUGS

It's not clear what the correct behavior should be when WrapProp() is
presented with a word that is longer than a line.  The previous 
behavior was to die.  Now the word is split at line-length.

=head1 AUTHOR

James Briggs E<lt>james.briggs@yahoo.comE<gt>. Styled after Text::Wrap.

=cut
