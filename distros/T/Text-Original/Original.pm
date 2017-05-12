package Text::Original;
use 5.006; use strict; use warnings;
use Memoize;

=head1 NAME

Text::Original - Find original, non-quoted text in a message

=head1 SYNOPSIS

    use Text::Original;
    my $sentence = first_sentence($email->body);

=head1 FUNCTIONS

=cut


our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( first_lines first_paragraph first_sentence) ] ); 
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '1.5';

=head2 first_lines

    first_lines($text, 20);

Returns the a number of lines after the first non blank, none quoted
line of the body of the email.

It will guess at attribution lines and skip them as well.

It will return super cited lines. This is the super-citers'
fault, not ours.

It won't catch all types of attribution lines;

It can optionally be passed a number of lines to get.

=cut

sub first_lines {
    my $text = shift;
    my $num  = shift || 1;

    return _significant_signal($text, lines => $num);
}


=head2 first_paragraph

Returns the first original paragraph of the message

=cut

sub first_paragraph {
    return _significant_signal(shift, para => 1);
}

=head2 first_sentence

Returns the first original sentence of the message

=cut

sub first_sentence {
    my $text = first_paragraph(shift);
    $text =~ s/(\p{STerm}) .*/$1/s; 
    return $text;
}

# Kudos to Damian Conway for this bit.
my $quotechar = qq{[!#%=|:]};
my $quotechunk = qq{(?:$quotechar(?![a-z])|[a-z]*>+)};
my $quoter = qq{(?:(?i)(?:$quotechunk(?:[ \\t]*$quotechunk)*))};

sub _significant_signal {
    my $text = shift;
    my %opts = @_;

    my $return = "";
    my $lines  = 0;

    # get all the lines from the main part of the body
    my @lines = split /$/m, $text;

    # right, find the start of the original content or quoted
    # content (i.e. skip past the attributation)
    my $not_started = 1;
    while (@lines && $not_started) {
        # next line
        local $_ = shift @lines;
        #print "}}$_";

        # blank lines, euurgh
        next if /^\s*$/;
        # quotes (we don't count quoted From's)
        next if /^\s*>(?!From)/;
        # Other kinds of quoter:
        next if /^\s*$quoter/;
        # skip obvious attribution
        next if /^\s*On (Mon|Tue|Wed|Thu|Fri|Sat|Sun)/i;
        next if /\d{4}-?\w{2,3}-?\d{2}.*\d+:\d+:\d+/i; # Looks like a date
        next if /^\w+(\s\w+)?:$/; # lathos' minimalist attributions. :)
        next if /^\s*.+=? wrote:/i;

        # skip signed messages
        next if /^\s*-----/;
        next if /^Hash:/;

        # annoying hi messages (this won't work with i18n)
        next if /^\s*(?:hello|hi|hey|greetings|salut
                        |good (?:morning|afternoon|day|evening))
                 (?:\W.{0,14})?\s*$/ixs;

        # snips
        next if m~\s*                          # whitespace
                  [<.=-_*+({\[]*?              # opening bracket
                  (?:snip|cut|delete|deleted)  # snip?
                  [^>}\]]*?                    # some words?
                  [>.=-_*+)}\]]*?              # closing bracket
                 \s*$                          # end of the line
                 ~xi;

        # [.. foo ..] or ...foo.. or so on
        next if m~\s*\[?\.\..*?\.\.]?\s*$~;

        # ... or [...]
        next if m~\s*\[?\.\.\.]?\s*$~;

        # if we got this far then we've probably got past the
        # attibutation lines
        unshift @lines, $_;  # undo the shift
        undef $not_started;  # and say we've started.
    }

    # okay, let's _try_ to build up some content then
    foreach (@lines) {
        # are we at the end of a paragraph?
        last if (defined $opts{'para'}  # paragraph mode?
                 && $opts{'para'}==1
                 && $lines>0            # got some lines aready?
                 && /^\s*$/);           # and now we've found a gap?

        # blank lines, euurgh
        next if /^\s*$/;
        # quotes (we don't count quoted From's)
        next if /^\s*>(?!From)/;

        # if we got this far then the line was a useful one
        $lines++;

        # sort of munged Froms
        s/^>From/From/;
        s/^\n+//;
        $return .= "\n" if $lines>1;
        $return .= $_;
        last if (defined $opts{'lines'} && $opts{'lines'}==$lines);
    }
    return $return;
}

memoize('_significant_signal');

1;

=head1 EXPORTS

All of the above.

=head1 AUTHOR

Simon Wistow and the Mariachi project.
See http://siesta.unixbeard.net/

Packaged by Simon Cozens

Currently maintained by Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004 The Siesta Project

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
