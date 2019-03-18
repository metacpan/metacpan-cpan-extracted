package Text::Amuse::Preprocessor::Parser;

use utf8;
use strict;
use warnings;

=head1 NAME

Text::Amuse::Preprocessor::Parser - Stripped down Muse parser for Text::Amuse::Preprocessor

=head2 FUNCTIONS

=over 4

=item parse_text($body)

Parse the string provided as argument and return a list of hashrefs
with this structure:

  {
   type => "markup" || "text",
   string => $chunk
  }

the concatenation of the C<string> values is equal to the original
body (without carriage returns and null bytes, tabs normalized and
final newline appended if missing).

=back

=cut

sub parse_text {
    my $string = shift;
    $string =~ s/[\r\0]//g;
    $string =~ s/\t/    /g;
    if ($string !~ m/\n\z/s) {
        $string .= "\n";
    }
    my @list;
    my $last_position = 0;
    pos($string) = $last_position;
    while ($string =~ m{\G # last match
                        (?<text>.*?) # something not greedy, even nothing
                        (?<markup>
                            (?<example>^\{\{\{     \x{20}*?\n .*? \n\}\}\}\n) |
                            (?<example>^\<example\>\x{20}*?\n .*? \n\</example\>\n) |
                            (?<newparagraph> \n\n+?) |
                            (?<verbatim>      \<verbatim\> .*? \<\/verbatim\>      ) |
                            (?<verbatim_code> \<code\>     .*? \<\/code\>          ) |
                            (?<verbatim_code> (?<![[:alnum:]])\=(?=\S)  .+? (?<=\S)\=(?![[:alnum:]]) )
                        )}gcxms) {
        my %captures = %+;
        if (length($captures{text})) {
            my @lines = split(/(\n)/, $captures{text});
            push @list, map { +{ type => 'text', string => $_ } } grep { length($_) } @lines;
        }
        push @list, {
                     type => 'markup',
                     string => $captures{markup},
                    };
        $last_position = pos($string);
    }
    my $last_chunk = substr $string, $last_position;
    if (length($last_chunk)) {
        my @lines = split(/(\n)/, $last_chunk);
        push @list, map { +{ type => 'text', string => $_  } } grep { length($_) } @lines;
    }
    my $full = join('', map { $_->{string} } @list);
    die "Chunks lost during processing <$string> vs. <$full>" unless $string eq $full;
    return @list;
}

1;
