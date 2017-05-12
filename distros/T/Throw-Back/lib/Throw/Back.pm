package Throw::Back;

use strict;
use warnings;

$Throw::Back::VERSION = '0.01';

use overload fallback => 1, '""' => sub {
    my ($exc) = @_;
    my $call_stack = '';
    if ( exists $exc->{call_stack} ) {
        for my $frame ( @{ $exc->{call_stack} } ) {
            my $func = $frame->[3];
            $func =~ s/^$frame->[0]\:://;
            $call_stack .= "    : $func() (file: $frame->[1], line: $frame->[2])\n";
        }
    }

    return $exc->{string} =~ m/\n$/ ? "$exc->{string}$call_stack" : "$exc->{string} (file: $exc->{file}, line: $exc->{line})\n$call_stack";
};

use Module::Want 0.6 ();

sub throw::back {
    my ( $class, @args ) = @_;

    # hack for no args:
    if ( ref($class) eq 'Throw::Back::_arg' ) {
        push @args, $class;
        $class = undef;
    }

    my $_arg = ref( $args[-1] ) eq 'Throw::Back::_arg' ? pop(@args) : bless( {}, 'Throw::Back::_arg' );
    my %obj = %{$_arg};
    if ( ref $class eq 'Throw::Back::_arg' ) {
        %obj = %{$class};
    }

    my $cn = 0;
    my $caller;
    my @stack_trace;
    while ( my @caller = caller($cn) ) {
        $caller = \@caller;
        unshift( @{ $obj{call_stack} }, $caller ) if exists $obj{call_stack};
        $cn++;
    }

    $obj{file} = $caller->[1];
    $obj{line} = $caller->[2];

    $obj{'previous_exception'} = $@ if defined $@ && ( ref($@) || length($@) );
    local $@;

    if ( defined $class ) {
        if ( !ref($class) && Module::Want::is_ns($class) ) {    # a one word message is pointless so don’t do that!
            $obj{type} = $class;

            # TODO ? $class->can('throw') ?

            if ( Module::Want::have_mod($class) && $class->can('new') ) {
                $obj{exception} = $class->new(@args);
                $obj{string} ||= eval { $obj{exception}->to_string } || "$class Exception Thrown";
            }
            else {
                $obj{string} ||= defined $args[0] && length $args[0] ? $args[0] : "$class Exception Thrown";
            }
        }
        else {
            if ( my $type = ref($class) ) {
                $obj{type}      = $type;
                $obj{exception} = $class;
                $obj{string} ||= defined $args[0] && length $args[0] ? $args[0] : "$type Exception Thrown";
            }
            else {
                $obj{string} ||= $class;
            }
        }
    }
    else {
        $obj{string} ||= defined $args[0] && length $args[0] ? $args[0] : "Exception Thrown";
    }

    $obj{type} ||= __PACKAGE__;

    if ( defined wantarray ) {
        return bless \%obj, __PACKAGE__;
    }
    else {
        die bless \%obj, __PACKAGE__;
    }
    return;
}

sub throw::stack {
    push @_, bless( { 'call_stack' => [] }, 'Throw::Back::_arg' );
    goto &throw::back;
}

sub throw::text {
    my ( $class, $phrase, @args ) = ref( $_[0] ) || Module::Want::is_ns( $_[0] ) ? @_ : ( undef, @_ );    # a one word message is pointless so don’t do that!
    my $phrase_args = ref( $args[0] ) eq 'ARRAY' ? shift @args : [];

    my $_arg = ref( $args[-1] ) eq 'Throw::Back::_arg' ? pop(@args) : bless( {}, 'Throw::Back::_arg' );

    if ( defined $class ) {
        my $lh = $class->can('locale') ? $class->locale : $class;                                         # lazy façade baby, lazy façade!
        if ( $lh->can('makevar') && $lh->can('makethis_base') ) {
            $_arg->{string} = $lh->makevar( $phrase, @{$phrase_args} );                                   # parser knows throw::text() so makevar is good
            $_arg->{string_not_localized} = $lh->makethis_base( $phrase, @{$phrase_args} );
        }
        elsif ( $class->can('maketext') ) {                                                               ## no extract maketext
            $_arg->{string} = $class->maketext( $phrase, @{$phrase_args} );                               ## no extract maketext (i.e. no makevar)
        }
    }

    if ( !exists $_arg->{string} ) {
        $_arg->{phrase}      = $phrase;
        $_arg->{phrase_args} = $phrase_args;
    }

    @_ = ( $class, @args, $_arg );
    goto &throw::back;
}

sub throw::stack::text {
    push @_, bless( { 'call_stack' => [] }, 'Throw::Back::_arg' );
    goto &throw::text;
}

# TODO ? v0.02 ?:
# sub rethrow {
#     my ($self) = @_;
#     my $caller = [caller(0)];
#
#     $self->{file} = $caller->[1];
#     $self->{line} = $caller->[2];
#     $self->{call_stack} =  __get_stack() if $self->{call_stack};
#
#     goto &__std_lazy_throw;
# }
#
# sub PROPAGATE { # see perldoc -f die
#     my ($self, $file, $line) = @_;
#     $self->{file} = $file;
#     $self->{line} = $line;
#     return $self;
# }

1;

__END__

=encoding utf-8

=head1 NAME

Throw::Back - Throw back exceptions like a boss.

=head1 VERSION

This document describes Throw::Back version 0.01

=head1 SYNOPSIS

    use Try::Tiny;
    use Throw::Back;
    …
    try {
        …
        throw::back("bork bork bork");
        …
        File::Slurp->throw::back("cookie cookie cookie", …);
        …
        $foo->throw::text("You failed [quant,_1,time,times].", [42], …);
        …
    }
    catch {
        my $err = $_;
        if ( $err->{type} eq 'File::Slurp' ){
            die $err->{string}; # not the place to deal w/ FS issues
        }
        elsif ($err->{type} eq ref($foo)) {
            $ak->out->note("FYI Foo complained a bit: $err"); # Foo barfs a lot for no fatal reason, just FYI and let it ride
        }
        else {
            $ak->logger->debug("Unhandled exception: " . $ak->str->dump($err));
        }
    };

=head1 DESCRIPTION

We should be able to throw exceptions without using a keyword, UNIVERSAL::, or other heavy shenanigans.

Depending on the circumstance, we may need to use it as a function, class method, or object method.

Also we absolutely must support localized errors.

Oh and also do all of that with no deps, lets keep it light!

=head1 INTERFACE

In void context: the Throw::Back exception object is thrown right then and there.

In non-void context: the Throw::Back exception object is returned for the caller to handle as they wish.

The Throw::Back exception object stringifies.

The Throw::Back exception object always has these keys:

=over 4

=item string

The exception text.

=item type

Name space of the exception’s type.

=item file

The file where the throw::back occurred.

=item line

The line number where the throw::back occurred.

=item previous_exception

Exists and is set to $@ if $@ contains anything at the time of throwing.

=back

If a class or object is used then “exception” may also be set as documented below under #2 and #3.

=head2 3 ways to throw::back()

=over 4

=item 1. via function

=over 4

=item throw::back;

=item throw::back("Your string here")

=item throw::back({…})

=item throw::back(…)

=back

=item 2. via class method

=over 4

=item Any::Class::Here->throw::back(…);

If 'Any::Class::Here' is loaded or loadable and has a new() method then the exception object’s “exception” key is set to a new object (the arguments to throw::back() get passed to new()).

If it can’t be loaded or does not have a new() method then the type and string keys will reflect that.

=back

=item 3. via object method

The exception object’s “exception” key is set to the object.

=back

=head2 throw::stack

Like throw::back but also includes the call stack in a key called “call_stack”.

When the object is stringified, the stack array gets formatted and included.

=head2 throw::text

Like throw::back but the string given is treated as a maketext format phrase.

If your phrase requires arguments they can be passed in via array ref as the final argument.

If called as a function or the class/object can not process them then the keys “phrase” and “phrase_args” contain the maketext data.

If called w/ class/object that can make it (either has the methods needed or has a façade method called “locale” that has the methods) then “string” is the maketext()d version. “string_not_localized” will also exist if the object has a makethis_base method.

=head2 throw::stack::text

Like throw::stack() but with the behavior of throw::text().

=head1 DIAGNOSTICS

Throw::Back throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Throw::Back requires no configuration files or environment variables.

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported.

=head1 Why Throw::Back?

It made more sense than Throw::Down and was less disturbing than Throw::Up.

=head1 CAVEAT

A one word message is pointless so don’t do that!

It is also ambiguous since there is no way to differentiate between a one word message and a name space thus you’ll get unexpected results, so don’t do that!

=head1 TODO

- clarify interface/POD

- Stack polish (args, pkg, etc).

- More thorough tests.

- Add rethrow()/PROPAGATE() support.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-throw-back@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
