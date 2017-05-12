package Try::Tiny::SmartCatch;

use 5.006;
use strict;
use warnings;

use vars qw/@EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION @ISA/;

BEGIN {
    require Exporter;
    @ISA = qw/Exporter/;
}

@EXPORT = qw/try catch_when catch_default then finally/;
@EXPORT_OK = (@EXPORT, qw/throw/);
%EXPORT_TAGS = (
    all => [@EXPORT_OK],
);

++$Carp::Internal{+__PACKAGE__};

$VERSION = '0.5';

sub try($;@) {
    my ($try, @code_refs) = @_;

    my ($catch_default, @catch_when, $code_ref, @finally, $ref_type, $then, $wantarray);

    $wantarray = wantarray ();

    foreach $code_ref (@code_refs) {
        next if (!$code_ref);

        $ref_type = ref($code_ref);

        ## zero or more 'catch_when' blocks
        if ($ref_type eq 'Try::Tiny::SmartCatch::Catch::When') {
            ## we need to save same handler for many different exception types
            push(@catch_when, $code_ref);
        }
        ## zero or one 'catch_default' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Catch::Default') {
            $catch_default = $$code_ref{code}
                if (!defined($catch_default));
        }
        ## zero or more 'finally' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Finally') {
            push(@finally, $$code_ref);
        }
        ## zero or one 'then' blocks
        elsif ($ref_type eq 'Try::Tiny::SmartCatch::Then') {
            $then = $$code_ref
                if (!defined($then));
        }
        ## unknown block type
        else {
            require Carp;
            Carp::confess("Unknown code ref type given '$ref_type'. Check your usage & try again");
        }
    }

    my ($error, $failed, $prev_error, @ret);

    ## save the value of $@ so we can set $@ back to it in the beginning of the eval
    $prev_error = $@;

    {
        ## localize $@ to prevent clobbering of previous value by a successful eval.
        local $@;

        ## failed will be true if the eval dies, because 1 will not be returned from the eval body
        $failed = not eval {
            $@ = $prev_error;

            ## call try block in list context if try subroutine is called in list context, or we have 'then' block
            ## result of 'try' block is passed as arguments to then block, so we need do that in that way
            if ($wantarray || $then) {
                @ret = &$try();
            }
            elsif (defined($wantarray)) {
                $ret[0] = &$try();
            }
            else {
                &$try();
            }

            ## properly set $fail to false
            return 1;
        };

        ## copy $@ to $error; when we leave this scope, local $@ will revert $@
        ## back to its previous value
        $error = $@;
    }

    ## set up a scope guard to invoke the finally block at the end
    my @guards = (
        map {
            Try::Tiny::SmartCatch::ScopeGuard->_new($_, $failed ? $error : ())
        } @finally
    );

    ## at this point $failed contains a true value if the eval died, even if some
    ## destructor overwrote $@ as the eval was unwinding.
    if ($failed) {
        ## if we got an error, invoke the catch block.
        if (scalar(@catch_when) || $catch_default) {

            ## This works like given($error), but is backwards compatible and
            ## sets $_ in the dynamic scope for the body of $catch
            for ($error) {
                my ($catch_data);
                foreach $catch_data (@catch_when) {
                    return &{$$catch_data{code}}($error)
                        if ($catch_data->for_error($error));
                }

                return &$catch_default($error)
                    if ($catch_default);

                die($error);
            }
        }

        return;
    }

    ## no failure, $@ is back to what it was, everything is fine
    else {
        ## do we have then block? if we does, execute it in correct context
        if ($then) {
            if ($wantarray) {
                @ret = &$then(@ret);
            }
            elsif (defined($wantarray)) {
                $ret[0] = &$then(@ret);
            }
            else {
                &$then(@ret);
            }
        }

        return if (!defined($wantarray));
        return $wantarray ? @ret : $ret[0];
    }
}

sub catch_when ($$;@) {
    my ($types, $block) = (shift(@_), shift(@_));

    my $catch = Try::Tiny::SmartCatch::Catch::When->new($block, $types);

    return ($catch, @_);
}

sub catch_default ($;@) {
    my $block = shift(@_);

    my $catch = Try::Tiny::SmartCatch::Catch::Default->new($block);

    return ($catch, @_);
}

sub then ($;@) {
    my $block = shift(@_);

    my $then = bless(\$block, 'Try::Tiny::SmartCatch::Then');

    return ($then, @_);
}

sub finally ($;@) {
    my $block = shift(@_);

    my $finally = bless(\$block, 'Try::Tiny::SmartCatch::Finally');

    return ($finally, @_);
}

sub throw {
    return die (@_);
}

package # hide from PAUSE
    Try::Tiny::SmartCatch::ScopeGuard;
{

    sub _new {
        shift(@_);
        return bless([ @_ ]);
    }

    sub DESTROY {
        my ($guts) = @_;

        my $code = shift(@$guts);
        return &$code(@$guts);
    }
}

package Try::Tiny::SmartCatch::Catch::Default;
{
    sub new {
        my ($class, $code) = @_;

        my $self = { code => $code };
        $self    = bless($self, $class);

        return $self;
    }
}

package Try::Tiny::SmartCatch::Catch::When;
{
    use Scalar::Util qw/blessed/;

    sub new {
        my ($class, $code, $types) = @_;

        my $self = {
            code  => $code,
            types => (
                ref($types) eq 'ARRAY' ? $types   :
                defined($types)        ? [$types] :
                                         []
            ),
        };

        return bless($self, $class);
    }

    sub for_error {
        my ($self, $error, $types) = @_;

        $types = $$self{types}
            if (!defined($types));
        $types = [$types]
            if (ref($types) ne 'ARRAY');

        if (blessed($error)) {
            foreach (@$types) {
                return 1 if ($error->isa($_));
            }
        }
        else {
            my $type;
            foreach $type (@$types) {
                return 1 if (
                    (ref($type) eq 'Regexp' && $error =~ /$type/) ||
                    (!ref($type) && index($error, $type) > -1)
                );
            }
        }

        return;
    }

}


1;

__END__

=head1 NAME

Try::Tiny::SmartCatch - lightweight Perl module for powerful exceptions handling

=head1 VERSION

Version 0.5

=head1 SYNOPSIS

    use Try::Tiny::SmartCatch;

    try sub {}, # at least one try block
    catch_when 'ExceptionName' => sub {}, # zero or more catch_when blocks
    catch_when 'exception message' => sub {},
    catch_when qr/exception  message regexp/ => sub {},
    catch_default sub {}, # zero or one catch_default block
    then sub {}, # if no exception is raised, execute then block
    finally sub {}; #zero or more finally blocks
    
    use Try::Tiny::SmartCatch qw/throw/; # import only throw
    # You can import also all function at once:
    # use Try::Tiny::SmartCatch qw/:all/;
    throw('some exception');
    throw(SomeException->new ('message'));

=head1 DESCRIPTION

Goals are mostly the same as L<Try::Tiny> module, but there are few changes
to it's specification. Main difference is possibility to catch just some kinds
of exceptions in place of catching everything. Another one is slightly changed
syntax.

When raised exception is an object, L<Try::Tiny::SmartCatch> will test for
exception type (using C<UNIVERSAL::isa>). When raised exception is just
a text message (like: C<die ('message')>), there can be specified part of
message to test for.

There are also explicit C<sub> blocks. In opposite to C<Try::Tiny>,
every block in C<Try::Tiny::SmartCatch>: C<try>, C<catch_when>, C<catch_default>,
C<then> and C<finally> must have explicit subroutines specified. Thanks to trick
with function prototype, calling C<Try::Tiny::try> or C<Try::Tiny::catch>
creates implicit subroutines:

    sub test_function {
        try {
            # yes, here is implicit subroutine!
            # return statement here exits just from try block,
            # not from test_function!
            return 1;
        };
    
        say 'Hello!';
    }
    
    test_function();

Above snippet produces us text on STDOUT: C<Hello!>

But more obvious would be no output... (by C<return> statement). This is because of
implicit subroutine created with braces: C<{}> after C<try>,
 C<catch> or C<finally> from C<Try::Tiny>. C<Try::Tiny::SmartCatch> is
more explicit - you must always use C<sub> when defining blocks (look
at [Syntax](#Syntax) above).

An exception object or message is passed to defined blocks in two ways:
* in C<$_> variable
* as function arguments, so through C<@_> array.

L<Try::Tiny::SmartCatch> defines also C<throw> function (not imported
by default). Currently it is an alias for C<die>, but is more explicit then C<die> :)

It can be imported separately:

    use Try::Tiny::SmartCatch qw/throw/;

Or with rest of functions:

    use Try::Tiny::SmartCatch qw/:all/;

=head1 EXPORT

By default exported are functions:

=over

=item try

=item catch_when

=item catch_default

=item then

=item finally

=back

You can also explicit import C<throw> function:

    use Try::Tiny::SmartCatch qw/throw/;

Or all functions at all:

    use Try::Tiny::SmartCatch qw/:all/;

=head1 SUBROUTINES/METHODS

=head2 try($;@)

Works like L<Try::Tiny> C<try> subroutine, here is nothing to add :)

The only difference is that here must be given evident sub reference, not anonymous block:

    try sub {
        # some code
    };

=head2 catch_when($$;@)

Intended to be used in the second argument position of C<try>.

Works similarly to L<Try::Tiny> C<catch> subroutine, but have a little different syntax:

    try sub {
        # some code
    },
    catch_when 'Exception1' => sub {
        # catch only Exception1 exception
    },
    catch_when ['Exception1', 'Exception2'] => sub {
        # catch Exception2 or Exception3 exceptions
    };

If raised exception is a blessed reference (or object), C<Exception1> means that exception
class has to be or inherits from C<Exception1> class. In other case, it search for given
string in exception message (using C<index> function or regular expressions - depending on
type of given operator). For example:

    try sub {
        throw('some exception message');
    },
    catch_when 'exception' => sub {
        say 'exception caught!';
    };

Other case:

    try sub {
        throw('some exception3 message');
    },
    catch_when qr/exception\d/ => sub {
        say 'exception caught!';
    };

Or:

    try sub {
        # ValueError extends RuntimeError
        throw(ValueError->new ('Some error message'));
    },
    catch_when 'RuntimeError' => sub {
        say 'RuntimeError exception caught!';
    };

=head2 catch_default($;@)

Works exactly like L<Try::Tiny> C<catch> function (OK, there is difference:
need to specify evident sub block instead of anonymous block):

    try sub {
        # some code
    },
    catch_default sub {
        say 'caught every exception';
    };

=head2 then($;@)

C<then> block is executed after C<try> clause, if none of C<catch_when> or
C<catch_default> blocks was executed (it means, if no exception occured).
It's executed before C<finally> blocks.

    try sub {
        # some code
    },
    catch_when 'MyException' => sub {
        say 'caught MyException exception';
    },
    then sub {
        say 'No exception was raised';
    },
    finally sub {
        say 'executed always';
    };

=head2 finally($;@)

Works exactly like L<Try::Tiny> C<finally> function (OK, again, explicit sub
instead of implicit):

    try sub {
        # some code
    },
    finally sub {
        say 'executed always';
    };

=head2 throw

Currently it's an alias to C<die> function, but C<throw> is more obvious then C<die> when working with exceptions :)

In future it also can do more then just call C<die>.

It's not exported by default (see: L</EXPORT>)

=head1 SEE ALSO

=over 4

=item L<https://github.com/mysz/try-tiny-smartcatch>

Try::Tiny::SmartCatch home.

=item L<Try::Tiny>

Minimal try/catch with proper localization of $@, base of L<Try::Tiny::SmartCatch>

=item L<TryCatch>

First class try catch semantics for Perl, without source filters.

=back

=head1 AUTHOR

Marcin Sztolcman, C<< <marcin at urzenia.net> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://github.com/mysz/try-tiny-smartcatch/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Try::Tiny::SmartCatch

You can also look for information at:

=over 4

=item * Try::Tiny::SmartCatch home & source code

L<http://github.com/mysz/try-tiny-smartcatch>

=item * Issue tracker (report bugs here)

L<http://github.com/mysz/try-tiny-smartcatch/issues>

=item * Search CPAN

L<http://search.cpan.org/dist/Try-Tiny-SmartCatch/>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item Yuval Kogman

for his L<Try::Tiny> module

=item mst - Matt S Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

for good package name and few great features

=back

=head1 LICENSE AND COPYRIGHT

    Copyright (c) 2012-2013 Marcin Sztolcman. All rights reserved.

    Base code is borrowed from Yuval Kogman L<Try::Tiny> module,
    released under MIT License.

    This program is free software; you can redistribute
    it and/or modify it under the terms of the MIT license.

=cut
