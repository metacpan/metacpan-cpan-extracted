use strict;
use warnings;

package Text::Parser::Multiline 0.925;

# ABSTRACT: Adds multi-line support to the Text::Parser object.

use Moose::Role;


requires(
    qw(save_record multiline_type lines_parsed __read_file_handle),
    qw(join_last_line is_line_continued _set_this_line this_line)
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
    return $orig->( $self, @_ ) if not defined $self->multiline_type;
    my $type = $self->multiline_type;
    $save_record_proc{$type}->( $orig, $self, @_ );
}

sub __around_is_line_continued {
    my ( $orig, $self, $line ) = ( shift, shift, shift );
    return $orig->( $self, $line )
        if not defined $self->multiline_type
        or $self->multiline_type eq 'join_next';
    return 0 if not $orig->( $self, $line );
    return 1 if $self->lines_parsed() > 1;
    die unexpected_cont( line => $line );
}

sub __after__read_file_handle {
    my $self = shift;
    return if not defined $self->multiline_type;
    return $self->__test_safe_eof()
        if $self->multiline_type eq 'join_next';
    $self->_set_this_line( $self->__pop_last_line );
    $orig_save_record->( $self, $self->this_line );
}

sub __test_safe_eof {
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
    $self->__call_orig_save_rec($orig);
}

sub __call_orig_save_rec {
    my $self = shift;
    my $orig = shift;
    $self->_set_this_line( $self->__pop_last_line );
    $orig->( $self, $self->this_line );
}

sub __join_last_proc {
    my ( $orig, $self ) = ( shift, shift );
    return $self->__append_last_stash(@_) if $self->__more_may_join_last(@_);
    $self->__call_orig_save_rec($orig);
    $self->__append_last_stash(@_);
}

sub __more_may_join_last {
    my $self = shift;
    $self->is_line_continued(@_) or not defined $self->_joined_line;
}

has _joined_line => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => undef,
    clearer => '_delete_joined_line',
);

sub __append_last_stash {
    my ( $self, $line ) = @_;
    return $self->_joined_line($line) if not defined $self->_joined_line;
    my $joined_line = $self->join_last_line( $self->__pop_last_line, $line );
    $self->_joined_line($joined_line);
}

sub __pop_last_line {
    my $self      = shift;
    my $last_line = $self->_joined_line();
    $self->_delete_joined_line;
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

version 0.925

=head1 SYNOPSIS

    use Text::Parser;

    my $parser = Text::Parser->new(multiline_type => 'join_last');
    $parser->read('filename.txt');
    print $parser->get_records();
    print scalar($parser->get_records()), " records were read although ",
        $parser->lines_parsed(), " lines were parsed.\n";

=head1 RATIONALE

Some text formats allow line-wrapping with a continuation character, usually to improve human readability. To handle these types of text formats with the native L<Text::Parser> class, the derived class would need to have a C<save_record> method that would:

=over 4

=item *

Detect if the line is wrapped or is part of a wrapped line. To do this the developer has to implement a function named C<L<is_line_continued|Text::Parser/is_line_continued>>.

=item *

Join any wrapped lines to form a single line. For this, the developer has to implement a function named C<L<join_last_line|Text::Parser/join_last_line>>.

=back

With these two things, the developer can implement their C<L<save_record|Text::Parser/save_record>> assuming that the line is already unwrapped.

=head1 OVERVIEW

This role may be composed into an object of the L<Text::Parser> class. To use this role, just set the C<L<multiline_type|Text::Parser/multiline_type>> attribute. A derived class may set this in their constructor (or C<BUILDARGS> if you use L<Moose>). If this option is set, the developer should re-define the C<is_line_continued> and C<join_last_line> methods.

=head1 ERRORS AND EXCEPTIONS

It should also look for the following error conditions (see L<Text::Parser::Errors>):

=over 4

=item *

If the end of file is reached, and the line is expected to be still continued, an exception of C<L<Text::Parser::Errors::UnexpectedEof|Text::Parser::Errors/"Text::Parser::Errors::UnexpectedEof">> is thrown.

=item *

It is impossible for the first line in a text input to be wrapped from a previous line. So if this condition occurs, an exception of C<L<Text::Parser::Errors::UnexpectedCont|Text::Parser::Errors/"Text::Parser::Errors::UnexpectedCont">> is thrown.

=back

=head1 METHODS TO BE IMPLEMENTED

These methods must be implemented by the developer in the derived class. There are default implementations provided in L<Text::Parser> but they may not handle your target text format.

=head2 C<< $parser->is_line_continued($line) >>

Takes a string argument containing the current line (also available through the C<this_line> method) as input. Your implementation should return a boolean that indicates if the current line is wrapped.

    sub is_line_continued {
        my ($self, $line) = @_;
        chomp $line;
        $line =~ /\\\s*$/;
    }

The above example method checks if a line is being continued by using a back-slash character (C<\>).

=head2 C<< $parser->join_last_line($last_line, $current_line) >>

Takes two string arguments. The first is the previously read line which is wrapped in the next line (the second argument). The second argument should be identical to the return value of C<L<this_line|Text::Parser/"this_line">>. Neither argument will be C<undef>. Your implementation should join the two strings stripping any continuation character(s), and return the resultant string.

Here is an example implementation that joins the previous line terminated by a back-slash (C<\>) with the present line:

    sub join_last_line {
        my $self = shift;
        my ($last, $line) = (shift, shift);
        $last =~ s/\\\s*$//g;
        return "$last $line";
    }

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser>

=item *

L<Text::Parser::Errors>

=back

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
