package Text::Cloze;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

use List::Util qw/shuffle/;

my %default = (
    hint => 'blank',
    max => 0,
    regex => '\\S+',
    start => 1,
    stop => 1,
    word => 5,
);

sub new {
    my ($class, %args) = @_;
    $args{start} = $args{stop} = delete $args{sentence} if $args{sentence};
    $args{$_} ||= $default{$_} for keys %default;
    bless sub {
        my ( $pre, $change, $post ) = change( shift , @args{qw/start stop/} );
        my $n = 0;
        my @removed = ();
        $change =~ s{$args{regex}}
                    {++$n % $args{word} ? $& : replace( $removed[@removed] = $&, $args{hint} )}eg;
        s/^\W+//, s/\W+$//, $_ = ucfirst for @removed;
        return ( @removed, $pre.$change.$post );
    }, $class;
}

sub change {
    my ( $text, $start, $stop ) = @_;
    my ( $pre, $change, $post ) = ('') x 3;
    my @sentences = sentences_from( $text );
    for ( my $i = 0; $i < @sentences; $i++ ) {
        $pre .= $sentences[$i], next if $i < $start;
        $post .= $sentences[$i], next if $i >= @sentences - $stop;
        $change .= $sentences[$i];
    }
    return ( $pre, $change, $post );
}

sub sentences_from {
    local $_ = shift;
    return m/
        [(`'"]*             # Beginning punctuation

        .+?                 # Sentence words
        
        (?:
            # End of sentence
            [.?!] [)`'"]*

            (?:
                # slurp rest of whitespace at end of string...
                (?: \s* \Z )
                | # or look ahead to make sure another sentence occurs
                (?= \s+ [(`'"]* [A-Z] )
            )
            | \Z
        )    
    /xmsg;

}

sub replace {
    my ( $word, $hint ) = @_;
    my ( $punct_begin, $punct_end, $return ) = ('') x 3;
    $punct_begin .= $_, $word =~ s/^\W+// for $word =~ m/^\W+/g;
    $punct_end   .= $_, $word =~ s/\W+$// for $word =~ m/\W+$/g;
    $return .= '_' x 15 if $hint =~ /blank/;
    $return  = $punct_begin.$return;
    $return .= '('.( length $word ).')' if $hint =~ /count/;
    $return .= '('.( join '', shuffle(split '', $word) ).')' if $hint =~ /scramble/;
    $return .= $punct_end;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Cloze - Perform Cloze procedure on some text


=head1 VERSION

This document describes Text::Cloze version 0.0.1


=head1 SYNOPSIS

    use Text::Cloze;

    my $cloze = Text::Cloze->new(
        sentence => 1,      # don't worry about the first and last sentence
        word => 7,          # remove every 7th word
        max => 20,          # max number of words to remove
        regex => '\\S+',    # define what a word consists of
        hint => 'count',    # can also be 'blank' or 'scramble'
    );
    my $teacher_copy = $text;
    my $student_copy = $cloze->( $text );

    print "Cloze Activity:", "\n" x 2;
    print $text;

=head1 DESCRIPTION

The Cloze procedure has been researched over the past 50 years after having
been described by W.L. Taylor in 1953. It was initially used to determine the
readability level of a passage, but since then it has been also used to
identify plagiarism and to help with student assessment. Wikipedia provides a
brief description in its "Cloze Test" article.

=head1 SUBROUTINES/METHODS 

=over 8

=item new

Returns a subroutine with the given configuration options set. The
configuration options are as follows:

=over 4

=item hint

The types of hint to provide. If set to 'blank', then 15 underscores will
replace the deleted word. If set to 'count', then it's like 'blank' but has
the number of letters in the word in parentheses after the underscores. If set
to 'scramble', then it's like blank but the letters of the word will be given
in brackets afterwords, shuffled using L<List::Util>. They can also be
combined: 'blank count' will produce "_______________(5)"; 'blank scramble'
will produce "_______________[almbes]". Defaults to 'blank'.

=item max

The maximum number of words to remove from the given text. If set to 0,
then there is no maximum. Defaults to 0.

=item regex

Give a regex that determines what qualifies as a word. Defaults to C<\\S+>.

=item sentence

Given N, it's the short form of C<start => N, stop => N>.

=item start

Which sentence to start removing words in, 0-indexed. Defaults to 1.

=item stop

Which sentence to stop removing words in, 0-indexed from the last sentence. In
order to not remove words from the last sentence, pass in C<sentence_stop =>
1>. Defaults to 1.

=item word

Removes every nth word, given n. Defaults to 4.

=back

=item change

Given a text string, C<start> and C<stop> configuration options, returns an
array consisting of the portion before the text to be clozed, the portion to
be clozed, and the portion after the text to be clozed, in that order.
C<start> and C<stop> options determine which part of the text is to be clozed.

=item replace

Given a word and the value of the C<hint> option, returns the proper
substitute for the word. (See L<#new>)

=item sentences_from

Given a text string, returns an array of the sentences contained in string,
using a regular expression.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Text::Cloze requires no configuration files or environment variables.


=head1 DEPENDENCIES

Test::use::ok
List::Util


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-cloze@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Romano  C<< <unobe@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, David Romano C<< <unobe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
