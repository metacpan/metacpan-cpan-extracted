package XML::Grammar::FictionBase::FromProto::Parser::LineIterator;

use strict;
use warnings;

use MooX 'late';

use XML::Grammar::Fiction::Err;

extends("XML::Grammar::Fiction::FromProto::Parser");

has "_curr_line_idx" => (isa => "Int", is => "rw", reader => "line_idx",);
has "_lines" => (isa => "ArrayRef", is => "rw");


our $VERSION = '0.14.11';


sub setup_text
{
    my ($self, $text) = @_;

    # We include the lines trailing newlines for safety.
    $self->_lines([split(/^/, $text)]);

    $self->_curr_line_idx(0);

    ${$self->curr_line_ref()} =~ m{\A}g;

    return;
}


sub curr_line_ref
{
    my $self = shift;

    return \($self->_lines()->[$self->_curr_line_idx()]);
}


sub curr_pos
{
    my $self = shift;

    return pos(${$self->curr_line_ref()});
}


sub at_line_start
{
    my $self = shift;

    return ($self->curr_pos == 0);
}


sub curr_line_and_pos
{
    my $self = shift;

    return ($self->curr_line_ref(), $self->curr_pos());
}


sub curr_line_copy
{
    my $self = shift;

    my $l = ${$self->curr_line_ref()} . "";

    pos($l) = $self->curr_pos();

    return \$l;
}


sub next_line_ref
{
    my $self = shift;

    $self->_curr_line_idx($self->_curr_line_idx()+1);

    if (! $self->eof() ) {
        pos(${$self->curr_line_ref()}) = 0;
    }

    return $self->curr_line_ref();
}


# Skip the whitespace.
sub skip_space
{
    my $self = shift;

    $self->consume(qr{[ \t]});

    return;
}


sub skip_multiline_space
{
    my $self = shift;

    if (${$self->curr_line_ref()} =~ m{\G.*?\S})
    {
        return;
    }

    $self->consume(qr{\s});

    return;
}


sub curr_line_continues_with
{
    my ($self, $re) = @_;

    my $l = $self->curr_line_ref();

    return $$l =~ m{\G$re}cg;
}


sub line_num
{
    my $self = shift;

    return $self->_curr_line_idx()+1;
}


sub _next_line_ref_wo_leading_space
{
    my $self = shift;

    my $l = $self->next_line_ref();

    if (defined($$l))
    {
        $self->_check_if_line_starts_with_whitespace()
    }

    return $l;
}

sub consume
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->curr_line_ref();

    while (defined($$l) && ($$l =~ m[\G(${match_regex}*)\z]cgms))
    {
        $return_value .= $$l;
    }
    continue
    {
        $l = $self->_next_line_ref_wo_leading_space();
    }

    if (defined($$l) && ($$l =~ m[\G(${match_regex}*)]cg))
    {
        $return_value .= $1;
    }

    return $return_value;
}


# TODO : copied and pasted from _consume - abstract
sub consume_up_to
{
    my ($self, $match_regex) = @_;

    my $return_value = "";
    my $l = $self->curr_line_ref();

    LINE_LOOP:
    while (defined($$l))
    {
        # We assign to a scalar for scalar context, but we're not making
        # use of the variable.
        my $verdict = ($$l =~ m[\G(.*?)((?:${match_regex})|\z)]cgms);
        $return_value .= $1;

        # Find if it matched the regex.
        if (length($2) > 0)
        {
            last LINE_LOOP;
        }
    }
    continue
    {
        $l = $self->_next_line_ref_wo_leading_space();
    }

    return $return_value;
}


sub throw_text_error
{
    my ($self, $error_class, $text) = @_;

    return $error_class->throw(
        error => $text,
        line => $self->line_num(),
    );
}


sub _check_if_line_starts_with_whitespace
{
    my $self = shift;

    if (${$self->curr_line_ref()} =~ m{\A[ \t]})
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::LeadingSpace',
            "Leading space detected in the text.",
        );
    }
}


sub eof
{
    my $self = shift;

    return (!defined( ${ $self->curr_line_ref() } ));
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::FictionBase::FromProto::Parser::LineIterator - line iterator base
class for the parser.

B<For internal use only>.

=head1 VERSION

version 0.14.11

=head1 SYNOPSIS

B<TODO:> write one.

=head1 DESCRIPTION

This is a line iterator that is useful to handle text (e.g: out of a file)
and process it incrementally.

=head1 VERSION

Version 0.14.11

=head1 METHODS

=head2 $self->setup_text($multi_line_text)

Use $multi_line_text as the text to process, populate the lines array
with it and reset the other variables.

=head2 $line_ref = $self->curr_line_ref()

Returns a reference to the current line (a string).

For example:

    my $l_ref = $self->curr_line_ref();

    if ($$l_ref !~ m{\G<tag>}g)
    {
        die "Could not match tag.";
    }

=head2 my $pos = $self->curr_pos()

Returns the current position (using pos($$l)) of the current line.

=head2 $self->at_line_start()

Returns if at start of line (curr_pos == 0).

=head2 my ($line_ref, $pos) = $self->curr_line_and_pos();

Convenience method to return the line reference and the position.

For example:

    # Check for a tag.
    my ($l_ref, $p) = $self->curr_line_and_pos();

    my $is_tag_cond = ($$l_ref =~ m{\G<}cg);
    my $is_close = $is_tag_cond && ($$l_ref =~ m{\G/}cg);

    pos($$l) = $p;

    return ($is_tag_cond, $is_close);

=head2 my $line_copy_ref = $self->curr_line_copy()

Returns a reference to a copy of the current line that is allowed to be
tempered with (by assigning to pos() or in a different way.). The line is
returned as a reference so to avoid destroying its pos() value.

For example:

    sub _look_ahead_for_tag
    {
        my $self = shift;

        my $l = $self->curr_line_copy();

        my $is_tag_cond = ($$l =~ m{\G<}cg);
        my $is_close = $is_tag_cond && ($$l =~ m{\G/}cg);

        return ($is_tag_cond, $is_close);
    }

=head2 my $line_ref = $self->next_line_ref()

Advance the line pointer and return the next line.

=head2 $self->skip_space()

Skip whitespace (spaces and tabs) from the current position onwards.

=head2 $self->skip_multiline_space()

Skip multiline space.

=head2 $self->curr_line_continues_with($regex)

Matches the current line with $regex starting from the current position and
returns the result. The position remains at the original position if the
regular expression does not match (using C< qr//cg >).

=head2 my $line_number = $self->line_idx()

Returns the line index as an integer. It starts from 0 for the
first line (like in Perl lines.)

=head2 my $line_number = $self->line_num()

Returns the line number as an integer. It starts from 1 for the
first line (like in file lines.)

=head2 $self->consume($regex)

Consume as much text as $regex matches.

=head2 $self->consume_up_to($regex)

Consume up to the point where $regex matches.

=head2 $self->throw_text_error($exception_class, $text)

Throws the Error class $exception_class with the text $text (and the current
line number.

=head2 eof()

Returns if the parser reached the end of the file.

=head2 $self->meta()

Leftover from Moo.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction or by email to
bug-xml-grammar-fiction@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Grammar::Fiction

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Grammar-Fiction>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Grammar-Fiction>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Grammar-Fiction>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Grammar-Fiction>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Grammar-Fiction>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/XML-Grammar-Fiction>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fiction>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fiction>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fiction>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fiction at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-XML-Grammar-Fiction>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-XML-Grammar-Fiction

=cut
