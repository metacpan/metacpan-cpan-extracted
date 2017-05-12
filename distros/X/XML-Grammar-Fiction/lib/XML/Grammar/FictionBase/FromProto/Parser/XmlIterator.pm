package XML::Grammar::FictionBase::FromProto::Parser::XmlIterator;

use strict;
use warnings;

use Carp ();

use MooX 'late';

use XML::Grammar::Fiction::Err;
use XML::Grammar::Fiction::Struct::Tag;
use XML::Grammar::FictionBase::Event;

use XML::Grammar::Fiction::FromProto::Node::WithContent;
use XML::Grammar::Fiction::FromProto::Node::Element;
use XML::Grammar::Fiction::FromProto::Node::List;
use XML::Grammar::Fiction::FromProto::Node::Text;
use XML::Grammar::Fiction::FromProto::Node::Saying;
use XML::Grammar::Fiction::FromProto::Node::Description;
use XML::Grammar::Fiction::FromProto::Node::Paragraph;
use XML::Grammar::Fiction::FromProto::Node::InnerDesc;
use XML::Grammar::Fiction::FromProto::Node::Comment;

extends("XML::Grammar::FictionBase::FromProto::Parser::LineIterator");

has "_tags_stack" =>
(
    isa => "ArrayRef",
    is => "rw",
    default => sub { [] },
);


sub _get_tag
{
    my ($self, $idx) = @_;

    return $self->_tags_stack->[$idx];
}

sub _tags_stack_is_empty
{
    my $self = shift;

    return (! @{$self->_tags_stack});
}

sub _grep_tags_stack
{
    my $self = shift;
    my $cb = shift;

    return grep { $cb->($_) } @{$self->_tags_stack};
}

sub _push_tag
{
    my $self = shift;

    push( @{$self->_tags_stack}, @_);

    return;
}

sub _pop_tag
{
    my $self = shift;

    return pop(@{$self->_tags_stack});
}

has "_events_queue" =>
(
    isa => "ArrayRef",
    # isa => "ArrayRef",
    is => "rw",
    default => sub { []; },
);


sub _clear_events
{
    my $self = shift;

    $self->_events_queue([]);

    return;
}

sub _no_events
{
    my $self = shift;

    return (! @{$self->_events_queue});
}

sub _enqueue_event
{
    my $self = shift;
    my $event = shift;

    if (@_) {
        Carp::confess("More than one argument.");
    }

    push( @{$self->_events_queue}, $event);

    return;
}

sub _extract_event
{
    my $self = shift;

    return shift(@{$self->_events_queue});
}

has '_ret_tag' =>
(
    is => "rw",
    # TODO : add isa.
    predicate => "_has_ret_tag",
    clearer => "_clear_ret_tag",
);

# Whether we are inside a paragraph or not.
has "_in_para" => (isa => "Bool", is => "rw", default => 0,);

has '_tag_names_to_be_handled' =>
(
    is => 'ro',
    isa => 'HashRef[Bool]',
    lazy => 1,
    builder => '_build_tag_names_to_be_handled',
);

sub _build_tag_names_to_be_handled
{
    my $self = shift;

    return { map { $_ => 1 } @{$self->_list_valid_tag_events} };
}

sub _get_id_regex
{
    return qr{[a-zA-Z_\-]+};
}

sub _top_tag
{
    my $self = shift;
    return $self->_get_tag(-1);
}

sub _add_to_top_tag
{
    my ($self, $child) = @_;

    $self->_top_tag->append_child($child);

    return;
}

# TODO : Maybe move to a different sub-class or role.
sub _new_empty_list
{
    my $self = shift;
    return $self->_new_list([]);
}

sub _new_node
{
    my $self = shift;
    my $args = shift;

    # t == type
    my $class =
        "XML::Grammar::Fiction::FromProto::Node::"
        . delete($args->{'t'})
        ;

    return $class->new(%$args);
}


sub _create_elem
{
    my $self = shift;
    my $open = shift;

    my $children = @_ ? shift(@_) : $self->_new_empty_list();

    return
        $self->_new_node(
            {
                t => (
                    $open->name() eq "desc" ? "Description"
                    : $open->name() eq "innerdesc" ? "InnerDesc"
                    : "Element"
                ),
                name => $open->name(),
                children => $children,
                attrs => $open->attrs(),
                open_line => $open->line(),
            }
        );
}

sub _new_list
{
    my $self = shift;
    my $contents = shift;

    return $self->_new_node(
        {
            t => "List",
            contents => $contents,
        }
    );
}

sub _generic_para_contents_assert
{
    my ($self, $predicate, $message, $contents) = @_;

    if (List::MoreUtils::any { $predicate->($_) } @{$contents || []})
    {
        Carp::confess ($message);
    }

    return;
}

sub _assert_not_contains_saying
{
    my ($self, $contents) = @_;

    return $self->_generic_para_contents_assert(
        sub { ref($_) ne "" && $_->isa("XML::Grammar::Fiction::FromProto::Node::Saying") },
        qq{Para contains a saying.},
        $contents
    );
}

sub _assert_not_contains_undef
{
    my ($self, $contents) = @_;

    return $self->_generic_para_contents_assert(
        sub { !defined($_) },
        qq{Para contains an undef member.},
        $contents
    );
}

sub _new_para
{
    my ($self, $contents) = @_;

    $self->_assert_not_contains_saying($contents);
    $self->_assert_not_contains_undef($contents);

    return $self->_new_node(
        {
            t => "Paragraph",
            children => $self->_new_list($contents),
        }
    );
}

sub _new_text
{
    my $self = shift;
    my $contents = shift;

    return $self->_new_node(
        {
            t => "Text",
            children => $self->_new_list($contents),
        }
    );
}

sub _new_comment
{
    my $self = shift;
    my $text = shift;

    return $self->_new_node(
        {
            t => "Comment",
            text => $text,
        }
    );
}

sub _parse_opening_tag_attrs
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    my @attrs;

    my $id_regex = $self->_get_id_regex();

    while ($$l =~ m{\G\s*($id_regex)="([^"]+)"\s*}cg)
    {
        push @attrs, { 'key' => $1, 'value' => $2, };
    }

    return \@attrs;
}

sub _opening_tag_asserts
{
    my $self = shift;

    if ($self->eof)
    {
        Carp::confess (qq{Reached EOF in _parse_opening_tag.});
    }

    if (!defined($self->curr_pos()))
    {
        Carp::confess (qq{curr_pos is not defined in _parse_opening_tag.});
    }

    return;
}

sub _parse_opening_tag
{
    my $self = shift;

    $self->_opening_tag_asserts;

    my $l = $self->curr_line_ref();

    my $id_regex = $self->_get_id_regex();

    if ($$l !~ m{\G<($id_regex)}cg)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag',
            "Cannot match opening tag.",
        );
    }

    my $id = $1;

    my $attrs = $self->_parse_opening_tag_attrs();

    my $is_standalone = 0;
    if ($$l =~ m{\G\s*/\s*>}cg)
    {
        $is_standalone = 1;
    }
    elsif ($$l !~ m{\G>}g)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::NoRightAngleBracket',
            "Cannot match the \">\" of the opening tag",
        );
    }

    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $id,
        is_standalone => $is_standalone,
        line => $self->line_num(),
        attrs => $attrs,
    );
}

sub _parse_closing_tag
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    my $id_regex = $self->_get_id_regex();

    if ($$l !~ m{\G</($id_regex)>}g)
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::WrongClosingTagSyntax',
            "Cannot match closing tag",
        );
    }

    return XML::Grammar::Fiction::Struct::Tag->new(
        name => $1,
        line => $self->line_num(),
    );
}

sub _check_for_open_tag
{
    my $self = shift;

    if ($self->_tags_stack_is_empty())
    {
        $self->throw_text_error(
            'XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag',
            "Cannot match opening tag.",
        );
    }

    return;
}

sub _is_event_a_saying
{
    my ($self, $event) = @_;

    return $event->is_tag_of_name("saying");
}

sub _is_event_a_para
{
    my ($self, $event) = @_;

    return $event->is_tag_of_name("para");
}

sub _is_event_elem
{
    my ($self, $event) = @_;

    return $event->type() eq "elem";
}

sub _handle_event
{
    my ($self, $event) = @_;

    if ((! $self->_check_and_handle_tag_event($event))
        && $self->_is_event_elem($event)
    )
    {
        $self->_handle_elem_event($event);
    }

    return;
}

sub _handle_specific_tag_event
{
    my ($self, $event) = @_;

    my $tag_name = $event->tag();
    my $type = $event->is_open() ? "open" : "close";

    my $method = "_handle_${type}_${tag_name}";

    $self->$method($event);

    return 1;
}

sub _check_and_handle_tag_event
{
    my ($self, $event) = @_;

    if ($event->tag && exists($self->_tag_names_to_be_handled->{$event->tag}))
    {
        return $self->_handle_specific_tag_event($event);
    }
    else
    {
        return;
    }
}

sub _handle_para_event
{
    my ($self, $event) = @_;

    return
          $event->is_open()
        ? $self->_handle_open_para($event)
        : $self->_handle_close_para($event)
        ;
}

sub _handle_elem_event
{
    my ($self, $event) = @_;

    $self->_add_to_top_tag( $event->elem());

    return;
}

sub _handle_non_tag_text
{
    my $self = shift;

    $self->_check_for_open_tag();

    my $contents = $self->_parse_text();

    foreach my $event (@$contents)
    {
        $self->_handle_event($event);
    }

    return;
}


sub _look_for_and_handle_tag
{
    my $self = shift;

    my ($is_tag_cond, $is_close) = $self->_look_ahead_for_tag();

    # Check if it's a closing tag.
    if ($is_close)
    {
        return $self->_handle_close_tag();
    }
    elsif ($is_tag_cond)
    {
        $self->_handle_open_tag();
    }
    else
    {
        $self->_handle_non_tag_text();
    }
    return;
}

sub _merge_tag
{
    my $self = shift;
    my $open_tag = shift;

    my $new_elem =
        $self->_create_elem(
            $open_tag,
            $self->_new_list($open_tag->detach_children()),
        );

    if (! $self->_tags_stack_is_empty())
    {
        $self->_add_to_top_tag($new_elem);
        return;
    }
    else
    {
        return $new_elem;
    }
}

sub _handle_close_tag
{
    my $self = shift;

    my $close = $self->_parse_closing_tag();

    my $open = $self->_pop_tag();

    if ($open->name() ne $close->name())
    {
        XML::Grammar::Fiction::Err::Parse::TagsMismatch->throw(
            error => "Tags do not match",
            opening_tag => $open,
            closing_tag => $close,
        );
    }

    return $self->_merge_tag($open);
}

sub _look_ahead_for_comment
{
    my $self = shift;

    if ($self->curr_line_continues_with(qr{<!--}))
    {
        my $text = $self->consume_up_to(qr{-->});

        $self->_add_to_top_tag(
            $self->_new_comment($text),
        );

        return 1;
    }
    else
    {
        return;
    }
}

sub _decode_entities_in_text
{
    my ($self, $orig_text) = @_;

    my $ret = '';

    # Incrementally parse $text for entities.
    pos($orig_text) = 0;

    while ($orig_text =~ m{\G(.*?)(\&|\z)}msg)
    {
        my ($before, $indicator) = ($1, $2);

        $ret .= $before;

        if ($indicator eq '&')
        {
            if ($orig_text =~ m{\G(\#?\w+;)}cg)
            {
                $ret .= HTML::Entities::decode_entities("&$1");
            }
            else
            {
                Carp::confess(
                    sprintf(
                        "Cannot match entity '%s' at line %d",
                        substr($orig_text, pos($orig_text)-1, 10),
                        $self->line_num(),
                    )
                );
            }
        }
    }

    return $ret;
}

sub _parse_non_tag_text_unit
{
    my $self = shift;

    my $orig_text = $self->consume_up_to(
        $self->_non_tag_text_unit_consume_regex
    );

    my $text = $self->_decode_entities_in_text($orig_text);

    my $l = $self->curr_line_ref();

    my $ret_elem = $self->_new_text([$text]);
    my $is_para_end = 0;

    # Demote the cursor to before the < of the tag.
    #
    if ($self->at_line_start)
    {
        $is_para_end = 1;
    }
    else
    {
        pos($$l)--;
        if (substr($$l, pos($$l), 1) eq "\n")
        {
            $is_para_end = 1;
        }
    }

    if ($text !~ /\S/)
    {
        return;
    }
    else
    {
        return
        {
            elem => $ret_elem,
            para_end => $is_para_end,
        };
    }
}

sub _parse_text_unit
{
    my $self = shift;

    if (defined(my $event = $self->_extract_event()))
    {
        return $event;
    }
    else
    {
        $self->_generate_text_unit_events();
        return $self->_extract_event();
    }
}

sub _flush_events
{
    my $self = shift;

    my @ret = @{$self->_events_queue()};

    $self->_clear_events;

    return \@ret;
}

sub _parse_text
{
    my $self = shift;

    my @ret;

    while (my $unit = $self->_parse_text_unit())
    {
        push @ret, $unit;

        if ($unit->is_open_or_close)
        {
            return [@ret, @{$self->_flush_events()}];
        }
    }

    return \@ret;
}

sub _look_for_tag_opener
{
    my $self = shift;

    my $l = $self->curr_line_ref();

    if ($$l =~ m{\G(<(?:/)?)}cg)
    {
        return $1;
    }
    else
    {
        return;
    }
}

sub _is_closing_tag {
    my $self = shift;
    my $tag_start = shift;

    return $tag_start =~ m{/};
}

sub _generate_tag_event
{
    my $self = shift;

    my $l = $self->curr_line_ref();
    my $orig_pos = pos($$l);

    if (defined(my $tag_start = $self->_look_for_tag_opener()))
    {
        # If it's a tag.

        # TODO : implement the comment handling.
        # We have a tag.

        pos($$l) = $orig_pos;

        $self->_enqueue_event(
            XML::Grammar::FictionBase::Event->new(
                {'type' => ($self->_is_closing_tag($tag_start) ? "close" : "open")}
            ),
        );

        return 1;
    }
    else
    {
        return;
    }
}

sub _handle_open_tag
{
    my $self = shift;

    my $open = $self->_parse_opening_tag();

    $open->children([]);

    # TODO : add the check for is_standalone in XML-Grammar-Fiction
    # too.
    if ($open->is_standalone())
    {
        if (defined($self->_merge_tag($open)))
        {
            Carp::confess ("Top element/tag cannot be standalone.");
        }
        else
        {
            return;
        }
    }
    else
    {
        $self->_push_tag($open);

        return;
    }
}

sub _generate_text_unit_events
{
    my $self = shift;

    # $self->skip_multiline_space();

    if (! $self->_generate_tag_event())
    {
        $self->_generate_non_tag_text_event();
    }

    return;
}

sub _flush_ret_tag
{
    my $self = shift;

    my $ret = $self->_ret_tag();

    $self->_clear_ret_tag();

    return $ret;
}

sub _main_loop
{
    my $self = shift;

    while (! defined($self->_ret_tag()))
    {
        $self->_main_loop_iter();
    }

    return;
}

sub _parse_all
{
    my $self = shift;

    $self->_main_loop();

    return $self->_flush_ret_tag();
}

sub _assert_not_eof
{
    my $self = shift;

    if ($self->eof() && $self->_no_events())
    {
        if (! $self->_tags_stack_is_empty() )
        {
            XML::Grammar::Fiction::Err::Parse::TagNotClosedAtEOF->throw(
                error => "Tag not closed at EOF.",
                opening_tag => $self->_top_tag(),
            );
        }
        else
        {
            Carp::confess (qq{Reached EOF.});
        }
    }

    return;
}

sub _main_loop_iter
{
    my $self = shift;

    $self->_assert_not_eof;

    if ($self->_look_ahead_for_comment)
    {
        return;
    }
    else
    {
        return $self->_main_loop_iter_body;
    }
}

sub _attempt_to_calc_new_ret_tag
{
    my $self = shift;

    $self->_ret_tag(scalar($self->_look_for_and_handle_tag()));

    return;
}

sub _main_loop_iter_body
{
    my $self = shift;

    if ($self->_main_loop_iter_body_prelude())
    {
        $self->_attempt_to_calc_new_ret_tag();
    }

    return;
}


our $VERSION = '0.14.11';


sub process_text
{
    my ($self, $text) = @_;

    $self->setup_text($text);

    return $self->_parse_all();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::FictionBase::FromProto::Parser::XmlIterator - line iterator base
class with some nested XMLisms.

B<For internal use only>.

=head1 VERSION

version 0.14.11

=head1 SYNOPSIS

B<TODO:> write one.

=head1 DESCRIPTION

This is a line iterator with some features for parsing, nested,
XML-like grammars.

=begin Removed # Not supported by Moo / MooX yet.

    traits => ['Array'],
    handles =>
    {
        '_push_tag' => 'push',
        '_grep_tags_stack' => 'grep',
        '_tags_stack_is_empty' => 'is_empty',
        '_pop_tag' => 'pop',
        '_get_tag' => 'get',
    },


=end Removed

=begin Removed # Not supported by Moo / MooX yet.

    traits => ['Array'],
    handles =>
    {
        _enqueue_event => 'push',
        _extract_event => 'shift',
        _no_events => 'is_empty',
        _clear_events => 'clear',
    },


=end Removed

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
