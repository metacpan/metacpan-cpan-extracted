#!/usr/bin/env perl
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

# Style note: Hungarian prefixes are used on scalars:
#   "hr" (hash ref), "lr" (list ref), "sr" (string ref), "nr" (numeric ref),
#   "dr" ("do," i.e., block ref), "ref" (unspecified ref),
#   "b" or "is" (boolean), "s" (string)

package XML::Axk::Preparse;
use XML::Axk::Base qw(:all);

use Data::Dumper;

=encoding UTF-8

=head1 NAME

XML::Axk::Preparse - preparser for axk

=head1 SPECIFYING THE AXK LANGUAGE

An axk script can include a C<-Ln> pragma that specifies the axk
language in use.  For example, C<-L1> (or, C<-L 1>, C<-L01>,
C<-L001>, ...) calls for language 1 (defined in
C<XML::Axk::L::L1>).

Similarly, a C<-Bn> pragma specifies the axk backend to use.

An axk script on disk without a C<-Ln> pragma is an error.  This means
that the language version must be specified in the C<-Ln> form, not as
a direct C<use ...::Ln;> statement.  This is so that C<-Ln> can expand
to something different depending on the language version, if
necessary.  However, you can say `use...Ln` manually _in addition to_
the pragma (e.g., in a different package).

Multiple C<-Ln> pragmas are allowed in a file.  This is so you can use
different language versions in different packages if you want to.
However, you do so at your own risk!

Command-line scripts without a C<-Ln> pragma use the latest version
automatically.  That is, the behaviour is like perl's C<-E> rather than perl's
C<-e>.  That risks breakage of inline scripts, but makes it easier to use axk
from the command line.  If you are using axk in a shell script, specify the
C<-Ln> pragma at the beginning of your script or on the axk command line.
This is consistent with the requirement to list the version in your source
files.

=head2 Language formats

Languages can either be:

=over

=item C<[0-9]+>

A numeric language has leading 0s stripped from its name.  E.g., C<-L012>
tries to use language C<12>.

Languages 1-9 are reserved for axk's use.

=item C<[a-zA-Z][a-zA-Z0-9\.]*>

An alphabetic language name is used as is, except that C<.> characters are
converted to C<::> module separators.

Language names that are all upper case, and that have no C<.> characters,
are reserved for axk's use.

=cut

=head1 ROUTINES

=head2 pieces

Split the given source text into language-specific pieces.  Usage:

    my $lrPieces = pieces(\$source_text[, $hrInitialPragmas]);
    my ($lrPieces, $hasLang) = pieces(\$source_text[, $hrInitialPragmas]);

In the second form, it also tells you whether any Ln pragma is present
in the source text.

If you specify a C<$hrInitialPragma>, it will govern any lines before the
first pragma in the source text.

=cut

sub pieces {
    my @retval;

    my $srText = shift or croak('Need source text');
    croak 'Need a source reference' unless ref $srText eq 'SCALAR';

    # Initial pragmas, if any
    if(@_) {
        push @retval, { text => '', start => 1, pragmas => (shift) };
    }

    my $hasLang = false;

    # Regex to match a pragma line.  A pragma line can include up to two
    # -L/-B items, generally one -L and one -B.
    my $RE_Pragma_Item = q{
        -(?<kind>[BL]|-backend|-language)\h*
        (?:
                0*(?<digits>\d+)     # digit form
            |   (?<name>[a-zA-Z][a-zA-Z0-9\.]*) # alpha form, e.g., -Lfoo.bar.
        )
        \b
    };

    my $hrPragmas;
    my $RE_Pragma = qr{
        ^
        # Leader: on a #! line, or first thing on any line
        (?#!\H*\h.*?)?
        (($RE_Pragma_Item)(?{
            my $kind = $+{kind};
            $kind = 'B' if $kind eq '-backend';
            $kind = 'L' if $kind eq '-language';
            $hrPragmas->{$kind} = { digits => $+{digits}, name => $+{name} };
        })){1,2}
    }mx;

    # Main loop
    open my $fh, '<', $srText;
    LINE: while(<$fh>) {

        MAYBE_PRAGMA: { if(/^(?:#!|-)/) {     # fast bail
            $hrPragmas = {};
            last MAYBE_PRAGMA unless /$RE_Pragma/;

            #say "Saw pragma";
            $hrPragmas->{name} =~ s/\./::/g if $hrPragmas->{name};
            push @retval, { text => '' , start => $.+1, pragmas => $hrPragmas };
            $hasLang = true if $hrPragmas->{L};
            next LINE;
        }}

        # Otherwise, normal line.
        # TODO permit the caller to say what to do with lines before the first pragma
        unless(/^\h*(#|$)/) {   # Ignore blanks and comments before the
                                # first Ln.
            die "Source text can't come before a pragma line" unless @retval;
        }
        $retval[-1]->{text} .= $_;
        #say "Stashed $_";
    }
    close $fh;

    return \@retval, $hasLang if wantarray;
    return \@retval;
} #pieces()

=head2 assemble

Assemble a script for C<eval> based on the results of a call to pieces().
Usage:

    my $srNewText = assemble($filename, $lrPieces);

=cut

sub assemble {
    my ($filename, $lrPieces) = @_ or croak("Need filename, pieces");
    croak "Need pieces as a reference" unless ref $lrPieces eq 'ARRAY';

    $filename =~ s{"}{-}g;
        # as far as I can tell, #line can't handle embedded quotes.

    my $retval = '';
    foreach my $hrPiece (@$lrPieces) {

        die "-B not yet implemented" if $hrPiece->{pragmas}->{B};

        # Which language?
        my $lang = ($hrPiece->{pragmas}->{L}->{digits} //
                    $hrPiece->{pragmas}->{L}->{name});
        unless(defined $lang) {
            $retval .= $hrPiece->{text};
            next;
        }
        my $lang_module = "XML::Axk::L::L$lang";

        # Does this language parse the source text itself?
        my $want_text;
        eval "require $lang_module";
        die "Can't find language $lang: $@" if $@;
        do {
            no strict 'refs';
            $want_text = ${"${lang_module}::C_WANT_TEXT"};
        };

        unless($want_text) {    # Easy case: the script's code is still Perl
            $retval .= "use $lang_module;\n";
            $retval .= "#line $hrPiece->{start} \"$filename\"\n";
            $retval .= $hrPiece->{text};

        } else {                # Harder case: give the Ln the source text
            my $trailer =
                "AXK_EMBEDDED_SOURCE_DO_NOT_TYPE_THIS_YOURSELF_OR_ELSE";

            $retval .=
                "use $lang_module \"$filename\", $hrPiece->{start}, " .
                "<<'$trailer';\n";
            $retval .= $hrPiece->{text};
            $retval .= "\n$trailer\n";
            # Don't need a #line because the next language will take care of it
        }
    }

    return \$retval;
} #assemble()

=head2 preparse

Invokes pieces() and assemble().  Usage:

    my $srTextOut = preparse($filename, $textIn);

C<textIn> can be a string or a string ref.

=cut

sub preparse {
    my $filename = $_[0] or croak('Need filename');
    my $srTextIn = $_[1] or croak('Need text');
    $srTextIn = \$_[1] unless ref $srTextIn eq 'SCALAR';

    my $lrPieces = pieces($srTextIn);
    my $srTextOut = assemble($filename, $lrPieces);
    return $srTextOut;
} #preparse()

1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
