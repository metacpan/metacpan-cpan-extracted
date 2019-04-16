use strict;
use warnings;

package Text::Parser::Multiline 0.917;

# ABSTRACT: Adds multi-line support to the Text::Parser object.

use Exporter 'import';
our (@EXPORT_OK) = ();
our (@EXPORT)    = ();
use Moose::Role;


requires( qw(save_record setting lines_parsed has_aborted __read_file_handle),
    qw(join_last_line is_line_continued) );

use Exception::Class (
    'Text::Parser::Multiline::Error',
    'Text::Parser::Multiline::Error::UnexpectedContinuation' => {
        isa   => 'Text::Parser::Multiline::Error',
        alias => 'throw_unexpected_continuation',
    }
);
use Text::Parser::Errors;

around save_record       => \&__around_save_record;
around is_line_continued => \&__around_is_line_continued;
after __read_file_handle => \&__after__read_file_handle;

my $orig_save_record = sub {
    return;
};

my %save_record_proc = (
    join_last => \&__join_last_proc,
    join_next => \&__join_next_proc,
);

sub __around_save_record {
    my ( $orig, $self ) = ( shift, shift );
    $orig_save_record = $orig;
    my $type = $self->setting('multiline_type');
    $save_record_proc{$type}->( $orig, $self, @_ );
}

sub __around_is_line_continued {
    my ( $orig, $self ) = ( shift, shift );
    my $type = $self->setting('multiline_type');
    return $orig->( $self, @_ ) if $type eq 'join_next';
    __around_is_line_part_of_last( $orig, $self, @_ );
}

sub __around_is_line_part_of_last {
    my ( $orig, $self ) = ( shift, shift );
    return 0 if not $orig->( $self, @_ );
    return 1 if $self->lines_parsed() > 1;
    die unexpected_cont( line => $_[0] );
}

sub __after__read_file_handle {
    my $self = shift;
    return $self->__after_at_eof()
        if $self->setting('multiline_type') eq 'join_next';
    my $last_line = $self->__pop_last_line();
    $orig_save_record->( $self, $last_line ) if defined $last_line;
}

sub __after_at_eof {
    my $self = shift;
    my $last = $self->__pop_last_line();
    return if not defined $last;
    my $lnum = $self->lines_parsed();
    die unexpected_eof( discontd => $last, line_num => $lnum );
}

sub __join_next_proc {
    my ( $orig, $self ) = ( shift, shift );
    $self->__append_last_stash(@_);
    return if $self->is_line_continued(@_);
    $orig->( $self, $self->__pop_last_line() );
}

sub __join_last_proc {
    my ( $orig, $self ) = ( shift, shift );
    return $self->__append_last_stash(@_)
        if $self->is_line_continued(@_);
    my $last_line = $self->__pop_last_line();
    $orig->( $self, $last_line ) if defined $last_line;
    $self->__save_this_line( $orig, @_ );
}

sub __save_this_line {
    my ( $self, $orig ) = ( shift, shift );
    return $self->__append_last_stash(@_)
        if not $self->has_aborted;
}

sub __append_last_stash {
    my ( $self, $line ) = @_;
    my $last_line = $self->__pop_last_line();
    $last_line = $self->__strip_append_line( $line, $last_line );
    $self->__stash_line($last_line);
}

sub __strip_append_line {
    my ( $self, $line, $last ) = ( shift, shift, shift );
    return $line if not defined $last;
    return $self->join_last_line( $last, $line );
}

sub __stash_line {
    my $self = shift;
    $self->{__temp_joined_line} = shift;
}

sub __pop_last_line {
    my $self = shift;
    return if not exists $self->{__temp_joined_line};
    my $last_line = $self->{__temp_joined_line};
    delete $self->{__temp_joined_line};
    return $last_line;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::Multiline - Adds multi-line support to the Text::Parser object.

=head1 VERSION

version 0.917

=head1 SYNOPSIS

    use Text::Parser;

    my $parser = Text::Parser->new(multiline_type => 'join_last');
    $parser->read('filename.txt');
    print $parser->get_records();
    print scalar($parser->get_records()), " records were read although ",
        $parser->lines_parsed(), " lines were parsed.\n";

=head1 RATIONALE

Some text formats allow users to split a single line into multiple lines, with a continuation character in the beginning or in the end, usually to improve human readability.

This extension allows users to use the familiar C<save_record> interface to save records, as if all the multi-line text inputs were joined.

=head1 OVERVIEW

To handle these types of text formats with the native L<Text::Parser> class, the derived class would need to have a C<save_record> method that would:

=over 4

=item *

Detect if the line is continued, and if it is, save it in a temporary location. To detect this, the developer has to implement a function named C<L<is_line_continued|Text::Parser/is_line_continued>>.

=item *

Keep appending (or joining) any continued lines to this temporary location. For this, the developer has to implement a function named C<L<join_last_line|Text::Parser/join_last_line>>.

=item *

Once the line continuation has stopped, create and save a data record. The developer needs to write this the same way as earlier, assuming that the text is already joined properly.

=back

It should also look for the following error conditions (see L<Text::Parser::Errors>):

=over 4

=item *

If the end of file is reached, and the line is expected to be still continued.

=item *

If the first line in a text input happens to be a continuation of a previous line, that is impossible, since it is the first line

=back

To create a multi-line text parser you need to L<determine|Text::Parser/multiline_type> if your parser is a C<'join_next'> type or a C<'join_last'> type.

=head1 METHODS TO BE IMPLEMENTED

These methods must be implemented by the developer. There are default implementations provided in L<Text::Parser> but they do nothing.

=head2 C<< $parser->is_line_continued($line) >>

Takes a string argument as input. Should returns a boolean that indicates if the current line is continued from the previous line, or is continued on the next line (depending on the type of multi-line text format). If parser is a C<'join_next'> parser, then a true value from this routine means that some data is expected to be in the I<next> line which is expected to be joined with this line. If instead the parser is C<'join_last'>, then a true value from this method would mean that the current line is a continuation from the I<previous> line, and the current line should be appended to the content of the previous line.

=head2 C<< $parser->join_last_line($last_line, $current_line) >>

Takes two string arguments. The first is the line previously read which is expected to be continued on this line. You can be certain that the two strings will not be C<undef>. Your method should return a string that has stripped any continuation characters, and joined the current line with the previous line.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://github.com/balajirama/Text-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
