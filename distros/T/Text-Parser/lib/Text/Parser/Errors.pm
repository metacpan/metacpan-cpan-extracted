package Text::Parser::Errors 0.917;
use strict;
use warnings;

use Throwable::SugarFactory;
use Scalar::Util 'looks_like_number';

# ABSTRACT: Exceptions for Text::Parser


exception 'GenericError' => 'a generic error';


exception
    InvalidFilename => 'file does not exist',
    has             => [
    name => (
        is  => 'ro',
        isa => sub {
            die "$_[0] must be a string" if '' ne ref( $_[0] );
        }
    )
    ],
    extends => GenericError();


exception
    FileNotReadable => 'file does not exist',
    has             => [
    name => (
        is  => 'ro',
        isa => sub {
            die "$_[0] must be a string" if '' ne ref( $_[0] );
        }
    )
    ],
    extends => GenericError();


exception
    'CantUndoMultiline' => 'already multiline parser, cannot be undone',
    extends             => GenericError();


exception
    UnexpectedEof => 'join_next cont. character in last line, unexpected EoF',
    has           => [
    discontd => (
        is  => 'ro',
        isa => sub {
            die "$_[0] must be a string" if '' ne ref( $_[0] );
        }
    )
    ],
    has => [
    line_num => (
        is  => 'ro',
        isa => sub {
            die "$_[0] must be a number"
                if ref( $_[0] ) ne ''
                or not looks_like_number( $_[0] );
        }
    )
    ],
    extends => GenericError();


exception
    UnexpectedCont => 'join_last cont. character on first line',
    has            => [
    line => (
        is  => 'ro',
        isa => sub {
            die "$_[0] must be a string" if '' ne ref( $_[0] );
        },
    )
    ],
    extends => GenericError();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::Errors - Exceptions for Text::Parser

=head1 VERSION

version 0.917

=head1 DESCRIPTION

This document contains a manifest of all the exception classes thrown by L<Text::Parser>.

=head1 EXCEPTION CLASSES

All exceptions are derived from C<Text::Parser::Errors::GenericError>. They are all based on L<Throwable::SugarFactory> and so all the exception methods of those, such as C<L<error|Throwable::SugarFactory/error>>, C<L<namespace|Throwable::SugarFactory/namespace>>, etc., will be accessible. Read L<Exceptions> if you don't know about exceptions in Perl 5.

=head2 C<Text::Parser::Errors::InvalidFilename>

Thrown when file name specified to C<L<read|Text::Parser/read>> or C<L<filename|Text::Parser/filename>> is invalid.

=head3 Attributes

=head4 name

A string with the anticipated file name.

=head2 C<Text::Parser::Errors::InvalidFilename>

Thrown when file name specified to C<L<read|Text::Parser/read>> or C<L<filename|Text::Parser/filename>> has no read permissions or is unreadable for any other reason.

=head3 Attributes

=head4 name

A string with the name of the file that could not be read

=head2 C<Text::Parser::Errors::CantUndoMultiline>

Thrown when a multi-line parser is turned back to a non-multiline one.

=head2 C<Text::Parser::Errors::UnexpectedEof>

Thrown when a line continuation character is at the end of a file, indicating that the line is continued on the next line. Since there is no further line, the line continuation is left unterminated and is an error condition. This exception is thrown only for C<join_next> type of multiline parsers.

=head3 Attributes

=head4 discontd

This is a string containing the line which got discontinued by the unexpected EOF.

=head4 line_num

The line at which the unexpected EOF is encountered.

=head2 C<Text::Parser::Errors::UnexpectedCont>

Thrown when a line continuation character is at the beginning of a file, indicating that the previous line should be joined. Since there is no line before the first line, this is an error condition. This is thrown only in C<join_last> type of multiline parsers.

=head3 Attributes

=head4 line

This is a string containing the content of the line with the unexpected continuation character. Given the description, it is obvious that the line number is C<1>.

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser>

=item *

L<Throwable::SugarFactory>

=item *

L<Exceptions>

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
