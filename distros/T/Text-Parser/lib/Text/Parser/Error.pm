package Text::Parser::Error 1.000;
use strict;
use warnings;

# ABSTRACT: Exceptions for Text::Parser

use Moose;
use Moose::Exporter;
extends 'Throwable::Error';

Moose::Exporter->setup_import_methods( as_is => ['parser_exception'], );


sub parser_exception {
    my $str = shift;
    $str = 'Unknown error from ' . caller() if not defined $str;
    Text::Parser::Error->throw( message => $str );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::Error - Exceptions for Text::Parser

=head1 VERSION

version 1.000

=head1 DESCRIPTION

This class replaces the older C<Text::Parser::Errors> which created hundreds of subclasses. That method seemed very counter-productive and difficult to handle for programmers. There is only one function in this class that is used inside the L<Text::Parser> package. 

Any exceptions thrown by this package will be an instance of L<Text::Parser::Error>. And C<Text::Parser::Error> is a subclass of C<Throwable::Error>. So you can write your code like this:

    use Try::Tiny;

    try {
        my $parser = Text::Parser->new();
        # do something
        $parser->read();
    } catch {
        print $_->as_string, "\n" if $_->isa('Text::Parser::Error');
    };

=head1 FUNCTIONS

=head2 parser_exception

Accepts a single string argument and uses it as the message attribute for the exception thrown.

    parser_exception("Something bad happened") if $something_bad;

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
