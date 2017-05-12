package Text::TOC::HTML;
{
  $Text::TOC::HTML::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean 0.12;

use Text::TOC::InputHandler::HTML;
use Text::TOC::OutputHandler::HTML;
use Text::TOC::Types qw( Filter HashRef );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has _input_handler => (
    is       => 'ro',
    isa      => 'Text::TOC::InputHandler::HTML',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_input_handler',
    handles  => [ 'add_file' ],
);

has _input_handler_args => (
    is       => 'rw',
    isa      => HashRef,
    init_arg => undef,
);

has _output_handler => (
    is       => 'ro',
    isa      => 'Text::TOC::OutputHandler::HTML',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_output_handler',
);

has _output_handler_args => (
    is       => 'rw',
    isa      => HashRef,
    init_arg => undef,
);

has _toc_document => (
    is       => 'ro',
    isa      => 'HTML::DOM',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_toc_document',
);

my $single_filter = sub { $_[0]->tagName() =~ /^h[2-4]$/i };
my $multi_filter  = sub { $_[0]->tagName() =~ /^h[1-4]$/i };

my $single_link_generator = sub { return q{#} . $_[0]->anchor_name() };
my $multi_link_generator = sub {
    return 'file://' . $_[0]->source_file() . q{#} . $_[0]->anchor_name();
};

sub BUILD {
    my $self = shift;
    my $p    = shift;

    my %ih;
    my %oh;

    if ( delete $p->{multi} ) {
        $ih{filter} = delete $p->{filter} || $multi_filter;
        $oh{link_generator} = delete $p->{link_generator} || $multi_link_generator;
    }
    else {
        $ih{filter} = delete $p->{filter} || $single_filter;
        $oh{link_generator} = delete $p->{link_generator} || $single_link_generator;
    }

    $oh{style} = delete $p->{style}
        if exists $p->{style};

    $self->_set_input_handler_args(\%ih);
    $self->_set_output_handler_args(\%oh);

    return;
}

sub _build_input_handler {
    my $self = shift;

    return Text::TOC::InputHandler::HTML->new( $self->_input_handler_args() );
}

sub _build_output_handler {
    my $self = shift;

    return Text::TOC::OutputHandler::HTML->new(
        $self->_output_handler_args() );
}

sub html_for_toc {
    my $self = shift;

    return $self->_toc_document()->innerHTML();
}

sub _build_toc_document {
    my $self = shift;

    return $self->_output_handler()
        ->process_node_list( $self->_input_handler()->nodes() );
}

sub html_for_document {
    my $self = shift;
    my $path = shift;

    # Building this also updates the original document with the target nodes.
    $self->_toc_document();

    my $doc = $self->_input_handler()->document($path);

    return unless $doc;

    return $doc->innerHTML();
}

sub html_for_document_body {
    my $self = shift;
    my $path = shift;

    # Building this also updates the original document with the target nodes.
    $self->_toc_document();

    my $doc = $self->_input_handler()->document($path);

    return unless $doc;

    my $html = $doc->innerHTML();

    $html =~ s{.+<body>}{}s;
    $html =~ s{</body>.+}{}s;

    return $html;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Build a table contents for one or more HTML documents


__END__
=pod

=head1 NAME

Text::TOC::HTML - Build a table contents for one or more HTML documents

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  my $toc = Text::TOC::HTML->new();

  $toc->add_file( file => 'path/to/file' );

  print $toc->html_for_toc();
  print $toc->html_for_document('path/to/file');
  print $toc->html_for_document_body('path/to/file');

=head1 DESCRIPTION

This class provides a high-level API for generating a table of contents for
one or more HTML documents.

As each file is processed, it will be altered in order to add anchors for the
table of contents. The end result is a single blob of HTML for the table of
contents itself, and new HTML for each document.

=for Pod::Coverage BUILD

=head1 METHODS

This class provides the following methods:

=head2 Text::TOC::HTML->new()

The constructor accepts several named parameters:

=over 4

=item * C<multi>

This is a boolean indicating whether or not you want to build a multi-document
table of contents. This is based on the I<output>, not the input. In other
words, if you want the table of contents to link to multiple documents, set
this to true.

By default, this class assumes that you are just going to output a single
document.

The single vs multi choice affects the default filter for "interesting" nodes
in a document, as well as link generation.

The single-document filter looks for second- through fourth-level
headings. The multi-document filter looks for first- through fourth-level
headings.

The single-document link generator simply generates a fragment link like
"#foo". The multi-document link generator defaults to using the source file's
file name as part of a "file://" URI. However, for multi-document output
you'll almost certainly want to provide your own link generation.

=item * C<link_generator>

This is an optional subroutine reference that will be used to generate links
in the table of contents. See above for a description of the defaults.

This subroutine will be passed a single L<Text::TOC::Node::HTML> object, and
is expected to return a string containing a URI.

=item * C<style>

This can be either "ordered" or "unordered". It determines the list tag used
when creating HTML for the table of contents. The default is "unordered".

=item * C<filter>

You can provide a custom subroutine reference for filtering nodes. It will be
called with one argument, an L<HTML::DOM::Node> object. It should return true
if the node should be included in the table of contents, false otherwise.

=back

=head2 $toc->add_file( file => $file, ... )

This method adds a file to the table of contents. The file can be given as a
string or as a L<Path::Class::File> object.

This file will be read and processed for the table of contents.

You can also provide an optional C<content> parameter, which contains the
file's content. If this is provided, the file won't be read. This is useful if
there is some pre-processing done to the file (for example, if it is a
template of some sort).

=head2 $toc->html_for_toc()

Returns a blob of HTML that represents the table of contents for all the
documents which have been processed.

=head2 $toc->html_for_document($path)

Given a path to a file which has been processed, this method returns the HTML
for that document. The HTML will include the anchors added to support the
table of contents.

=head2 $toc->html_for_document_body($path)

Given a path to a file which has been processed, this method returns the HTML
body for that document. This is all the HTML between the C<< <body> >> and C<<
</body> >> tags. The HTML will include the anchors added to support the table
of contents.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

