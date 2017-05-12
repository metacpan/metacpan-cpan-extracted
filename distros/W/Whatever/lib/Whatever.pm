package Whatever;
    use warnings;
    use strict;
    use Carp ();

    sub star (&) {
        my $code = shift;
        bless sub :lvalue {
            goto &$code if @_ < 2;
            my $star = $code;
            {$star = $star->(shift);
                @_ and ref $star eq 'Whatever' ? redo
                       : Carp::croak 'too many arguments for Whatever'}
            $star
        }
    }
    use overload fallback => 1,
        (# infix
            map {
                my $code = /atan2/ ? sub {atan2 $_[0], $_[1]}
                                   : eval "sub {\$_[0] $_ \$_[1]}" or die $@;
                $_ => sub {
                    my ($self, $flip) = @_[0, 2];
                    my $arg2 = \$_[1];
                    star {
                        $code->($flip ? ($$arg2, &$self)
                                      : (&$self, $$arg2))
                    }
                }
            } qw (+ - * / % ** << >> x . & | ^ < <= > >= == != lt le gt
                  ge eq ne <=> cmp atan2), $^V >= 5.010 ? '~~' : ()
        ),
        (# prefix
            map {
                my $code = eval "sub {$_ \$_[0]}" or die $@;
                ($_ eq '-' ? 'neg' : $_) => sub {
                    my $self = $_[0];
                    star {$code->(&$self)}
                }
            } qw (- ! ~)
        ),
        (# functions
            map {
                my $code = eval "sub {$_(\$_[0])}" or die $@;
                $_ => sub {
                    my $self = $_[0];
                    star {$code->(&$self)}
                }
            } qw (cos sin exp abs log sqrt)
        ),
        '@{}' => sub {tie my @ret => 'Whatever::ARRAY', shift; \@ret},
        '%{}' => sub {tie my %ret => 'Whatever::HASH',  shift; \%ret};

    {
        my $star = star sub :lvalue {@_ ? $_[0] : $_};
        my $arg  = star sub :lvalue {$_[0]};
        my $it   = star sub :lvalue {$_};
        ** = sub :lvalue {my $x = $star};
        *@ = sub {$arg};
        *_ = sub {$it};
        ** = \$star;
    }
    eval {Internals::SvREADONLY($*, 1)}
        or warn 'Whatever could not set $* readonly: '.$@;

    my $av_push = eval {
        require Array::RefElem;
        \&Array::RefElem::av_push
    };
    sub AUTOLOAD {
        my $self = shift;
        my $args = \@_;
        my $method = substr our $AUTOLOAD, 2 + length __PACKAGE__;
        star {
            if ($av_push) {
                $av_push->(\@_, $_)
                    for scalar &$self, @$args, @_ = ();
            } else {
                @_ = (scalar &$self, @$args)
            }
            goto &{$_[0]->can($method)}
        }
    } sub DESTROY {}

    {package
        Whatever::ARRAY;
        sub TIEARRAY {bless \\pop}
        sub FETCH {
            my ($self, $key) = @_;
            Whatever::star sub :lvalue {
                (&$$$self ||= [])->[$key - ($key > 2**30 and 2**31-1)]
            }
        }
        sub FETCHSIZE {2**31-1}
        sub AUTOLOAD {Carp::croak our $AUTOLOAD . " unsupported"}
        sub DESTROY {}
    }
    {package
        Whatever::HASH;
        sub TIEHASH {bless \\pop}
        sub FETCH {
            my ($self, $key) = @_;
            Whatever::star sub :lvalue {(&$$$self ||= {})->{$key}}
        }
        sub AUTOLOAD {Carp::croak our $AUTOLOAD . " unsupported"}
        sub DESTROY {}
    }
    delete $Whatever::{star};
    our $VERSION = '0.23';

=head1 NAME

Whatever - a perl6ish whatever-star for perl5

=head1 VERSION

Version 0.23

=head1 SYNOPSIS

this module provides a whatever-star C< * > term for perl 5. since this
module is B<not> a source filter, the name C< &* > or C< $* > is as close as
it's going to get.

    use Whatever;

    my $greet = 'hello, ' . &* . '!';

    say $greet->('world'); # prints 'hello, world!'

what was:

    my $result = $someobj->map(sub{$_ * 2});

can now be:

    my $result = $someobj->map(&* * 2);

=head1 EXPORT

    &*  the whatever-star
    $*  the whatever-star         ($* is deprecated in 5.10+, so I'm taking it)
    &@  the gets-val-from-@_-star
    &_  the gets-val-from-$_-star

like all punctuation variables, the whatever terms are global across all
packages after this module is loaded.

=head1 SUBROUTINES

the C< &* > and C< $* > stars are the most generic terms, which return their
expression as a coderef that will take its argument from C< $_[0] > if it is
available, or C< $_ > otherwise. this allows the terms to dwim in most contexts.
think of the whatever star as C< sub {@_ ? $_[0] : $_} >

the C< &@ > term always uses C< $_[0]>, while the C< &_ > always uses C< $_ >

beyond where they get their eventual argument from, all of the whatever terms
behave the same way.  each is a I<sticky> overloaded object that will bind to
the operators and variables that it interacts with.  at all times the whatever
star is a coderef that will perform the actions it has accumulated when passed
a value to act on.

a few more examples are probably in order:

=over 4

=item hello world

    my $greet = "hello, $*!";  # the $* term interpolates in strings
    say $greet->('world'); # prints 'hello, world!'

    say "hello, $*!"->('world');

=item simple operations

    my $inc = $* + 1;
    say $inc->(5); # prints 6

    my $inc_x2 = $inc * 2;  # whatever code continues to capture operations
    say $inc_x2->(5); # prints 12

    my $inc_inc = $inc->($inc); # and is fine with recursion
    say $inc_inc->(5); # prints 7

    my $repeat = &* x &*;
    my $line = $repeat->('-');
    my $hr = $line . "\n";

    print $hr->(80);  # prints ('-' x 80)."\n"

=item with object oriented code

assuming this simple C< Array > implementation:

    {package Array;
        sub new  {shift; bless [@_]}
        sub map  {new Array map  $_[1]() => @{$_[0]}}
        sub grep {new Array grep $_[1]() => @{$_[0]}}
        sub str  {join ' ' => @{$_[0]}}
    }
    my $array = new Array 1 .. 10;

    say $array->map(&_ * 2)->str;              # '2 4 6 8 10 12 14 16 18 20'
    say $array->map(&_ * 2)->map(&_ + 1)->str; # '3 5 7 9 11 13 15 17 19 21'
    say $array->map(&_ * 2 + 1)->str;          # '3 5 7 9 11 13 15 17 19 21'

=item method calls

    my $str = &*->str;
    say $str->($array); # prints '1 2 3 4 5 6 7 8 9 10'

    my $multi_call = &*->map(&_ * 2 + 1)->grep(&_ % 5)->str;

    say $multi_call->($array); # prints '3 7 9 11 13 17 19 21'

    $some_obj->map(&*->some_method(...));

arguments of method calls are copied by alias if L<Array::RefElem> is installed.
this provides closure like behavior.  otherwise, the values are fixed to
whatever they were at the time of declaration.

=item multiple whatever stars

when working with subs created by combining multiple stars, you can bind
multiple values at once by passing multiple arguments.

    my $join3 = &* . &* . &*;

    say $join3->(1)(2)(3); # prints '123'
    say $join3->(1 .. 3);  # prints '123'

    my $indent = $join3->(' ', ' ');

    say $indent->('xyz'); # prints '  xyz'

=item arrays and hashes

you can dereference a whatever star as an array or hash (of course the star
expects to be passed a suitable reference):

    my $first = &*->[0];
    my $bob   = &*->{bob};

    say $first->([3 .. 5]); # prints '3'
    say $bob->({bob => 5}); # prints '5'

the subroutine returned by the star is a valid lvalue (can be assigned to).
multi-level calls and calls that would normally autovivify behave as expected.

    &*->[0][0]{x}(my $array) = 4;

    say $$array[0][0]{x}; # prints '4'

=item variables

the stars lazily bind to variables, which allows the variable to get its value
after the star is defined, and to change its value between calls.  this is
analogous to an anonymous sub closing over a variable

    my $future;
    my $delorean = $future . (' ' . $* . '!');
     # works like: sub {$future . (' ' . $_[0] . '!')};

    $future = 1.21;
    say $delorean->('gigawatts'); # prints "1.21 gigawatts!"

    $future = &*;
    say $delorean->('folks')->("that's all");  # prints "that's all folks!"

=back

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

this module is new, there are probably some.

please report any bugs or feature requests to C<bug-whatever at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Whatever>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

those behind the perl6 whatever-star

=head1 LICENSE AND COPYRIGHT

copyright 2010 Eric Strom.

this program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require';
