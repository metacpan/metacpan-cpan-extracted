package Text::APL;

use strict;
use warnings;

our $VERSION = 0.08;

use Text::APL::Core;
use Text::APL::WithCaching;

sub new {
    my $class = shift;
    my (%options) = @_;

    $options{charset} ||= 'UTF-8';

    $options{reader} ||= $class->_build_reader(charset => $options{charset});

    if (delete $options{cache}) {
        return Text::APL::WithCaching->new(%options);
    }

    return Text::APL::Core->new(%options);
}

sub _build_reader {
    my $self = shift;

    exists $INC{"AnyEvent.pm"}
      ? do {
        require AnyEvent::AIO;
        require Text::APL::Reader::AIO;
        Text::APL::Reader::AIO->new(@_);
      }
      : exists $INC{"IO/AIO.pm"}
      ? do { require Text::APL::Reader::AIO; Text::APL::Reader->AIO->new(@_) }
      : Text::APL::Reader->new(@_);
}

1;
__END__

=pod

=head1 NAME

Text::APL - non-blocking and streaming capable template engine

=head1 SYNOPSIS

=head2 Simple example

    $template->render(
        input  => \$input,
        output => \$output,
        vars   => {foo => 'bar'}
    );

=head2 Streaming example

    $template->render(
        input => sub {
            my ($cb) = @_;

            # Call $cb($data) when data is available
            # Call $cb->() on EOF
        },
        output => sub {
            my ($chunk) = @_;

            # Print $chunk to the needed output
            # $chunk is undef when template is fully rendered
        },
        vars => {foo => 'bar'}
    );

=head1 DESCRIPTION

This is yet another template engine. But compared to others it supports
non-blocking (read/write) and streaming output.

=head2 Reader/Writer

Reader and writer can be a subroutine references reading from any source and
writing output to any destination. Sane default implementations for reading from
a string, a file or file handle and writing to the string, a file or a file
handle are also available.

=head2 Parser

Parser can parse not only full templates but chunk by chunk correctly resolving
any ambiguous leftovers. This allows immediate parsing.

This for example works just fine:

    $parser->parse('<% $hello');
    $parser->parse(' %>');

=head2 Compiler

Compiler compiles templates into Perl code but when evaluating does not create
a Perl string that accumulates all the template output, but rather provides
a special C<print> function that pushes the content as soon as it's available
(streaming).

The generated Perl code can looks like this:

    Hello, <%= $nickname %>!

    # becomes

    __print(q{Hello, });
    __print_escaped(do {$foo});
    __print(q{!});

=head1 SYNTAX

Syntax is borrowed from the template standards shared among several web
framewoks in different languages:

    <% foo() %> # evaluate code
    % foo()

    <%= $foo %> # insert evaluation result
    %= $foo

    <%== $foo %> # insert evaluation result without escaping
    %== %foo

No new template language is provided, just the old Perl.

=head1 METHODS

=head2 C<new>

    my $template = Text::APL->new;

Create new L<Text::APL> instance.

Accepted options:

=over

=item * parser (by default L<Text::APL::Parser>)

=item * translator (by default L<Text::APL::Translator>)

=item * compiler (by default L<Text::APL::Compiler>)

=item * reader (by default L<Text::APL::Reader>)

=item * writer (by default L<Text::APL::Writer>)

=back

=head2 C<render>

    $template->render(
        input   => \$input,
        output  => \$output,
        vars    => {foo => 'bar'},
        helpers => {
            time => sub {time}
        }
    );

C<input> and C<output> can be a filename, a reference to scalar, a file handle
and a reference to subroutine. Read more at L<Text::APL::Reader> and
L<Text::APL::Writer>.

C<vars> are Perl variables available in the template.

C<helpers> are Perl subroutines. available in the template.

=head1 EXAMPLES

For working examples see C<examples/> directory in distribution.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/text-apl

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
