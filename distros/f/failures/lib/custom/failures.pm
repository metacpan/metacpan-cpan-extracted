use 5.008001;
use strict;
use warnings;

package custom::failures;
# ABSTRACT: Minimalist, customized exception hierarchy generator
our $VERSION = '0.004'; # VERSION

use parent 'failures';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

custom::failures - Minimalist, customized exception hierarchy generator

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package MyApp::failure;

    use custom::failures qw/io::file io::network/;

    # customize failure methods…

=head1 DESCRIPTION

This module works like L<failures> but lets you define a customized exception
hierarchy if you need a custom namespace, additional attributes, or customized
object behaviors.

Because failure classes have an C<@ISA> chain and Perl by default uses
depth-first-search to resolve method calls, you can override behavior anywhere
in the custom hierarchy and it will take precedence over default C<failure>
behaviors.

There are two methods that might be useful to override:

=over 4

=item *

message

=item *

throw

=back

Both are described further, below.

=head1 USAGE

=head2 Defining a custom failure hierarchy

    package MyApp::failure;

    use custom::failures qw/foo::bar/;

This will define a failure class hierarchy under the calling package's
namespace.  The following diagram show the classes that will be created (arrows
denote 'is-a' relationships):

    MyApp::failure::foo::bar --> failure::foo::bar
           |                        |
           V                        V
    MyApp::failure::foo      --> failure::foo
           |                        |
           V                        V
    MyApp::failure           --> failure

Alternatively, if you want a different namespace for the hierarchy, do it this way:

    use custom::failures 'MyApp::Error' => [ 'foo::bar' ];

That will create the following classes and relationships:

    MyApp::Error::foo::bar --> failure::foo::bar
           |                        |
           V                        V
    MyApp::Error::foo      --> failure::foo
           |                        |
           V                        V
    MyApp::Error           --> failure

By having custom classes also inherit from a standard namespace, you can throw
a custom error class that will still be caught in the standard namespace:

    use Safe::Isa; # for $_isa
    try {
        MyApp::failure::foo::bar->throw;
    }
    catch {
        if ( $_->$_isa( "failure::foo" ) ) {
            # handle it here
        }
    };

=head2 Adding custom attributes

Failure classes are implemented with L<Class::Tiny>, so adding
attributes is trivially easy:

    package MyApp::failure;

    use custom::failures qw/foo::bar/;

    use Class::Tiny qw/user/;

This adds a C<user> attribute to C<MyApp::failure> and
all its subclasses so it can be set in the argument to C<throw>:

    MyApp::failure::foo->throw( { msg => "Ouch!", user => "me" } );

Be sure to load C<Class::Tiny> B<after> you load C<custom::failures>
so that your C<@ISA> is already set up.

=head2 Overriding the C<message> method

Overriding C<message> lets you modify how the error string is produced.
The C<message> method takes a string (typically just the C<msg> field) and
returns a string.  It should not produce or append stack trace information.
That is done during object stringification.

Call C<SUPER::message> if you want the standard error text prepended (C<"Caught
$class: ...">).

For example, if you want to use L<String::Flogger> to render messages:

    package MyApp::failure;

    use custom::failures qw/foo::bar/;
    use String::Flogger qw/flog/;

    sub message {
        my ( $self, $msg ) = @_;
        return $self->SUPER::message( flog($msg) );
    }

Then you can pass strings or array references or code references as the C<msg>
for C<throw>:

    MyApp::failure->throw( "just a string"               );
    MyApp::failure->throw( [ "show some data %s", $ref ] );
    MyApp::failure->throw( sub { call_expensive_sub() }  );

Because the C<message> method is only called during stringification (unless you
call it yourself), the failure class type can be checked before any expensive
rendering is done.

=head2 Overriding the C<throw> method

Overriding C<throw> lets you modify the arguments you can provide or ensure
that a trace is included.  It can take whatever arguments you want and should
call C<SUPER::throw> with a hash reference to actually throw the error.

For example, to capture the filename associated with file errors:

    package MyApp::failure;

    use custom::failures qw/file/;

    use Class::Tiny qw/filename/;

    sub throw {
        my ( $class, $msg, $file ) = @_;
        my $args = {
            msg => $msg,
            filename => $file,
            trace => failures->croak_trace,
        };
        $self->SUPER::throw( $args );
    }

    sub message {
        # do something with 'msg' and 'filename'
    }

Later you could use it like this:

    MyApp::failure::file->throw( opening => $some_file );

=head2 Using BUILD

C<Class::Tiny> supports C<BUILD>, so you can also use that to
do things with failure objects when thrown.  This example
logs exceptions as they are built:

    use Log::Any qw/$log/;

    sub BUILD {
        my ($self) = @_;
        $log->error( $self->message );
    }

By using C<message> instead of stringifying C<$self>, we
log the message but not the trace (if any).

=for Pod::Coverage throw message as_string

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
