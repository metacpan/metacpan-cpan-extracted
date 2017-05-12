package XML::Grammar::Fiction::FromProto::Parser::QnD;

use strict;
use warnings;

use MooX 'late';

extends("XML::Grammar::FictionBase::FromProto::Parser::XmlIterator");

use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::Fiction::Err;
use XML::Grammar::FictionBase::Event;


our $VERSION = '0.14.11';

sub _non_tag_text_unit_consume_regex {
    return qr{(?:[\<]|^\n?$)}ms;
}

sub _generate_non_tag_text_event
{
    my $self = shift;

    my $is_para = $self->at_line_start;

    my $status = $self->_parse_non_tag_text_unit();

    if (!defined($status))
    {
        return;
    }

    my $elem = $status->{'elem'};
    my $is_para_end = $status->{'para_end'};

    my $in_para = $self->_in_para();
    if ($is_para && !$in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
               { type => "open", tag => "para", }
            ),
        );
        $in_para = 1;
    }

    if (my ($rest) = $elem->get_text() =~ m{\A\+(.*)}ms)
    {
        if ( length($rest) )
        {
            $self->throw_text_error(
                'XML::Grammar::Fiction::Err::Parse::ParaOpenPlusNotFollowedByTag',
                "Got a paragraph opening plus sign not followed by a tag.",
            );
        }
        # Else - do nothing - just ignore the + sign before the
        # style tag.
    }
    else
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {type => "elem", elem => $elem}
            )
        );
    }

    if ($is_para_end && $in_para)
    {
        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                { type => "close", tag => "para" }
            )
        );
        $in_para = 0;
    }

    return;
}

before '_generate_text_unit_events' => sub {
    my $self = shift;

    $self->skip_multiline_space();

    return;
};

sub _calc_open_para
{
    my $self = shift;

    return
        XML::Grammar::Fiction::Struct::Tag::Para->new(
            name => "p",
            is_standalone => 0,
            line => $self->line_num(),
            attrs => [],
            children => [],
        );
}

sub _handle_open_para
{
    my ($self, $event) = @_;

    $self->_push_tag($self->_calc_open_para());

    $self->_in_para(1);

    return;
}

sub _handle_close_para
{
    my ($self, $event) = @_;

    my $open = $self->_pop_tag;

    my $new_elem =
        $self->_new_para(
            $open->detach_children(),
        );

    $self->_add_to_top_tag($new_elem);

    $self->_in_para(0);

    return;
}

sub _list_valid_tag_events
{
    return [qw(para)];
}

before '_handle_close_tag' => sub {
    my $self = shift;

    $self->skip_space();
};

sub _look_ahead_for_tag
{
    my $self = shift;

    my $l = $self->curr_line_copy();

    my $is_tag_cond = ($$l =~ m{\G<}cg);
    my $is_close = $is_tag_cond && ($$l =~ m{\G/}cg);

    return ($is_tag_cond, $is_close);
}

sub _main_loop_iter_body_prelude
{
    my $self = shift;

    # $self->skip_space();

    return 1;
}

before '_parse_all' => sub {
    my $self = shift;

    $self->skip_space();

    return;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fiction::FromProto::Parser::QnD - Quick and Dirty parser
for the Fiction-XML proto-text.

B<For internal use only>.

=head1 VERSION

version 0.14.11

=head1 VERSION

Version 0.14.11

=head1 METHODS

=head2 $self->process_text($string)

Processes the text and returns the parse tree.

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
