package Text::Quoted;
our $VERSION = "2.09";
use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(extract);
our @EXPORT_OK = qw(set_quote_characters combine_hunks);

# Provides either the 'Hang' package -- or, on since version 1.69 of
# Text::Autoformat, the 'Text::Autoformat::Hang' package.
use Text::Autoformat();
my $hang_package = Hang->can('new') ? "Hang" : "Text::Autoformat::Hang";

use Text::Tabs();

=head1 NAME

Text::Quoted - Extract the structure of a quoted mail message

=head1 SYNOPSIS

    use Text::Quoted;
    my $structure = extract($text);

    # Optionally, customize recognized quote characters:
    Text::Quoted::set_quote_characters( qr/[:]/ );

=head1 DESCRIPTION

C<Text::Quoted> examines the structure of some text which may contain
multiple different levels of quoting, and turns the text into a nested
data structure.

The structure is an array reference containing hash references for each
paragraph belonging to the same author. Each level of quoting
recursively adds another list reference. So for instance, this:

    > foo
    > # Bar
    > baz

    quux

turns into:

    [
      [
        { text => 'foo', quoter => '>', raw => '> foo' },
        [
            { text => 'Bar', quoter => '> #', raw => '> # Bar' }
        ],
        { text => 'baz', quoter => '>', raw => '> baz' }
      ],

      { empty => 1 },
      { text => 'quux', quoter => '', raw => 'quux' }
    ];

This also tells you about what's in the hash references: C<raw> is the
paragraph of text as it appeared in the original input; C<text> is what
it looked like when we stripped off the quotation characters, and
C<quoter> is the quotation string.

=head1 FUNCTIONS

=head2 extract

Takes a single string argument which is the text to extract quote
structure from.  Returns a nested datastructure as described above.

Exported by default.

=cut

sub extract {
    return _organize( "", _classify( @_ ) );
}

sub _organize {
    my $top_level = shift;
    my @todo      = @_;
    $top_level = '' unless defined $top_level;

    my @ret;

    # Recursively form a data structure which reflects the quoting
    # structure of the list.
    while (my $line = shift @todo) {
        my $q = defined $line->{quoter}? $line->{quoter}: '';
        if ( $q eq $top_level ) {

            # Just append lines at "my" level.
            push @ret, $line
              if exists $line->{quoter}
              or exists $line->{empty};
        }
        elsif ( $q =~ /^\Q$top_level\E./ ) {

            # Find all the lines at a quoting level "below" me.
            my $newquoter = _find_below( $top_level, $line, @todo );
            my @next = $line;
            push @next, shift @todo while defined $todo[0]->{quoter}
              and $todo[0]->{quoter} =~ /^\Q$newquoter/;

            # And pass them on to _organize()!
            push @ret, _organize( $newquoter, @next );
        }
    }
    return \@ret;
}

# Given, say:
#   X
#   > > hello
#   > foo bar
#   Stuff
#
# After "X", we're moving to another level of quoting - but which one?
# Naively, you'd pick out the prefix of the next line, "> >", but this
# is incorrect - "> >" is actually a "sub-quote" of ">". This routine
# works out which is the next level below us.

sub _find_below {
    my ( $top_level, @stuff ) = @_;

    # Find the prefixes, shortest first; return the first one which is
    # "below" where we are right now but is a proper subset of the next
    # line.
    return (
        sort { length $a <=> length $b }
        grep $_ && /^\Q$top_level\E./ && $stuff[0]->{quoter} =~ /^\Q$_\E/,
        map $_->{quoter},
        @stuff
    )[0];
}

# BITS OF A TEXT LINE

=head2 set_quote_characters

Takes a regex (C<qr//>) matching characters that should indicate a
quoted line.  By default, a very liberal set is used:

    set_quote_characters(qr/[!#%=|:]/);

The character C<< E<gt> >> is always recognized as a quoting character.

If C<undef> is provided instead of a regex, only C<< E<gt> >> will
remain as a quote character.

Not exported by default, but exportable.

=cut

my $separator = qr/[-_]{2,} | [=#*]{3,} | [+~]{4,}/x;
my ($quotechar, $quotechunk, $quoter);

set_quote_characters(qr/[!#%=|:]/);

sub set_quote_characters {
    $quotechar  = shift;
    $quotechunk = $quotechar
        ? qr/(?!$separator *\z)(?:$quotechar(?!\w)|\w*>+)/
        : qr/(?!$separator *\z)\w*>+/;
    $quoter     = qr/$quotechunk(?:[ \t]*$quotechunk)*/;
}

=head2 combine_hunks

  my $text = combine_hunks( $arrayref_of_hunks );

Takes the output of C<extract> and turns it back into text.

Not exported by default, but exportable.

=cut

sub combine_hunks {
    my ($hunks) = @_;

    join "",
      map {; ref $_ eq 'HASH' ? "$_->{raw}\n" : combine_hunks($_) } @$hunks;
}

sub _classify {
    my $text = shift;
    return { raw => undef, text => undef, quoter => undef }
        unless defined $text && length $text;
    # If the user passes in a null string, we really want to end up with _something_

    # DETABIFY
    my @lines = Text::Tabs::expand( split /\n/, $text );

    # PARSE EACH LINE
    foreach (splice @lines) {
        my %line = ( raw => $_ );
        @line{'quoter', 'text'} = (/\A *($quoter?) *(.*?)\s*\Z/);
        $line{hang}      = $hang_package->new( $line{'text'} );
        $line{empty}     = 1 if $line{hang}->empty() && $line{'text'} !~ /\S/;
        $line{separator} = 1 if $line{text} =~ /\A *$separator *\Z/o;
        push @lines, \%line;
    }

    # SUBDIVIDE DOCUMENT INTO COHERENT SUBSECTIONS

    my @chunks;
    push @chunks, [ shift @lines ];
    foreach my $line (@lines) {
        if ( $line->{separator}
            || $line->{quoter} ne $chunks[-1][-1]->{quoter}
            || $line->{empty}
            || $chunks[-1][-1]->{empty} )
        {
            push @chunks, [$line];
        }
        else {
            push @{ $chunks[-1] }, $line;
        }
    }

    # REDIVIDE INTO PARAGRAPHS

    my @paras;
    foreach my $chunk (@chunks) {
        my $first = 1;
        my $firstfrom;
        foreach my $line ( @{$chunk} ) {
            if ( $first
                || $line->{quoter} ne $paras[-1]->{quoter}
                || $paras[-1]->{separator} )
            {
                push @paras, $line;
                $first     = 0;
                # We get warnings from undefined raw and text values if we don't supply alternates
                $firstfrom = length( $line->{raw} ||'' ) - length( $line->{text} || '');
            }
            else {
                my $extraspace =
                  length( $line->{raw} ) - length( $line->{text} ) - $firstfrom;
                $paras[-1]->{text} .= "\n" . q{ } x $extraspace . $line->{text};
                $paras[-1]->{raw} .= "\n" . $line->{raw};
            }
        }
    }

    # Reapply hangs
    for (grep $_->{'hang'}, @paras) {
        next unless my $str = (delete $_->{hang})->stringify;
        $_->{text} = $str . " " . $_->{text};
    }
    return @paras;
}

=head1 CREDITS

Most of the heavy lifting is done by a modified version of Damian
Conway's C<Text::Autoformat>.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2004-2015 by Best Practical Solutions, LLC

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
