package here::declare;
    use warnings;
    use strict;
    use lib '..';
    use here::install;
    BEGIN {*croak = *here::croak}

    our ($name, $value, $glob);

    sub process_pairs {
        my %args = @_;
        exists $args{$_} or croak "needs $_" for qw(validate transform);
        sub (&@) {
            my $to_source = $args{to_source} || shift;
            my $run = sub {
                if (@_ == 1) {
                   (local $value = $_[0])
                        =~ s/^ \s* (\(? [^)=]+ \)?) \s* = \s* (?=\S)//x
                            or croak 'argument must look like: ... = ...';
                    local $name = $1;
                    local $glob = my $error = 'here::declare::error::flag';
                    (my $perl = $to_source->())
                        =~ /$error/ and croak 'not supported with the single argument syntax';
                    return $perl
                }
                if ($_[0] =~ /^\s* \( ([^)=]+) \) \s*$/x) {
                    my $names = $1;
                    my $re = $names =~ /,/ ? qr/,/ : qr/\s+/;
                    splice @_, 0, 1, [grep {s/^\s+|\s+$//; 1} split $re => $names]
                }
                if (ref $_[0] eq 'ARRAY' and @_ > 2 || ref $_[1] ne 'ARRAY') {
                    @_ = ($_[0], [@_[1 .. $#_]])
                }
                if (@_ == 2 and ref $_[0] eq 'ARRAY'
                            and ref $_[1] eq 'ARRAY') {
                    @_ = map {
                        $_[0][$_] => $_[1][$_]
                    } 0 .. $#{$_[0]}
                }
                @_ % 2 and croak 'even length list expected';
                map {
                   (local $name = $_[$_]) =~ s/^-?(\w)/\$$1/;
                    local ($value, $glob) = ($_[$_+1], substr $name, 1);
                    $args{validate}->();
                    $value = $args{transform}->();
                    $to_source->()
                } map 2*$_ => 0 .. $#_/2
            };
            @_ ? &$run : $run
        }
    }

    BEGIN {
        my %valid = (
            '$' => sub {},
            '@' => sub {ref $value eq 'ARRAY' ? () : "an ARRAY ref"},
            '%' => sub {ref $value eq 'HASH'  ? () : "a HASH ref"},
        );
        *lexical = process_pairs
            validate  => sub {
                $name =~ /^(.)/;
                croak "$name must be set with $_"
                    for ($valid{$1} or croak "type not supported: $name")->()
            },
            transform => sub {
                my $code = here::store($value);
                $name =~ /^([\@\%])/ ? $1."{$code}" : $code
            };

        *const = process_pairs
            validate  => sub {
                $name =~ /^\$/ or croak "const sets scalar variables";
                ref $value    and croak "const values can be numbers or strings, not references";
            },
            transform => sub {
                require Data::Dumper;
                Data::Dumper->new([$value])->Terse(1)->Indent(0)->Dump
            };
    }

    my %can = (
        const  => const {"our $name; BEGIN {*$glob = \\$value}"},
        const2 => const {"sub $glob () {$value} our $name; BEGIN {*$glob = \\$glob}"},
    );
    for my $type (qw(my our state)) {
        $can{$type} = lexical {"$type $name; BEGIN {$name = $value}"}
    }

    my %done;
    sub import {
        shift;
        for (@_ ? @_ : keys %can) {
            $can{lc $_} or map {croak "pragma keys: $_; subroutine keys: \U$_"}
                                join ', ' => sort keys %can;
            if (/[A-Z]/) {
                no strict 'refs';
                *{(caller).'::'.$_} = $can{lc $_};
            }
            else {
                $done{$_}++ and next;
                here::install::->import($_ => $can{$_})
            }
        }
    }

    sub unimport {
        shift;
        for (@_ ? @_ : keys %done) {
            delete $done{$_};
            here::install::->unimport($_)
        }
    }

    our $VERSION = '0.03';


=head1 NAME

here::declare - easily declare compile time variables

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use here::declare;

    use const qw($ONE 1 $TWO 2);

    use my [qw(x y z)] => [$ONE + $TWO, 4, 5];

    use our '@foo' => [$x, $y, $z];

is equivalent to:

    our ($ONE, $TWO);
    BEGIN {
        *ONE = \'1';
        *TWO = \'2';
    }

    my ($x, $y, $z);
    BEGIN {
        ($x, $y, $z) = ($ONE + $TWO, 4, 5);
    }

    our @foo;
    BEGIN {
        @foo = ($x, $y, $z);
    }

without all that tedious typing.

=head1 USE STATEMENTS

all aspects of C< here::declare > must normally be imported using C< use ...; >
statements.

without arguments, an initial C< use here::declare; > line creates all five
pseudo-modules (C< my our state const const2 >).  if you only want some, pass a
list of those.

in the following examples, the C< use my > declaration will be used.  its usage
is equivalent to C< use our > and C< use state >.

=head2 a single argument with C< = >

=over 4

    use my '$x = 1';
    use my '($y, $z) = (2, 3)';

this is the simplest transform, which given an argument matching C< foo = bar >
gets rewritten as:

    my foo; BEGIN {foo = bar}

so the above becomes:

    my $x; BEGIN {$x = 1}
    my ($y, $z); BEGIN {($y, $z) = (2, 3)}

while this version looks the closest to perl's native variable declarations, it
is unable to pass arguments that can not easily be written in a string.

=back

=head2 list of name/value pairs

=over 4

    use my '$say' => sub {print @_, $/};

    use my '@array' => [1, 2, 3], '%hash' => {a => 1, b => 2};

here an arbitrarily long list of name/value pairs is passed to the declarator.

if the name is a C< $scalar > then the corresponding value will be copied into
the newly created variable at compile time.  it is safe to pass any type of
scalar as a value, and it will not be stringified.  C< bareword > and
C< -bareword > names will be interpreted as C< $bareword > which can cut down
on the number of quotes you need to write (C<< use my say => sub {...}; >>)

if the name is an C< @array > or C< %hash > the corresponding values must be
C< ARRAY > or C< HASH > references, which will be dereferenced and copied into
the new variables.

so the above becomes:

    my $say;   BEGIN {$say   =   here::fetch(1)}
    my @array; BEGIN {@array = @{here::fetch(2)}}
    my %hash;  BEGIN {%hash  = %{here::fetch(3)}}

where C< here::fetch > is a subroutine that returns the values passed into the
declarator, which gets around needing to serialize the values.

=back

=head2 [array of names] => list or array of values

=over 4

    use my [qw($x $y $z)] => 1, 2, 3;

    use my [qw($foo @bar %baz)] => ['FOO', [qw(B A R)], {b => 'az'}];

this usage is exactly like the list of name/value pairs usage except the names
and values are passed in separately. the names must be an array reference. the
values can be an array reference or a list.

as a syntactic shortcut, the above two lines could also be written:

    use my '($x, $y, $z)' => 1, 2, 3;

    use my '($foo, @bar, %baz)' => 'FOO', [qw(B A R)], {b => 'az'};

which of course expands to something equivalent to:

    my ($x, $y, $z);
    BEGIN {$x = 1; $y = 2; $z = 3}

    my ($foo, @bar, %baz);
    BEGIN {$foo = 'FOO'; @bar = qw(B A R); %baz = (b => 'az')}

ignoring the complexities of C< here::fetch >

=back

=head2 const and const2

=over 4

    use const '$FOO' => 'BAR';

    use const2 DEBUG => 1;

which expands to:

    our $FOO; BEGIN {*FOO = \'BAR'}

    sub DEBUG () {1} our $DEBUG; BEGIN {*DEBUG = \DEBUG}

these declarations only accept C< $scalar >, C< bareword > or C< -bareword >
names (interchangeably), but otherwise the usage is similar to C< use my ... >

the single argument syntax is not supported with these two declarations.

=back

=head2 cleanup

=over 4

you can remove the pseudo-modules manually:

    no here::declare;

or let the declaration fall out of scope if L<B::Hooks::EndOfScope> is installed:

    {
        use here::declare;
        use my ...; # works
    }
    use my ...; # error

=back

=head1 EXPORT

if you don't like the installation of pseudo-modules, you can pass
C< use here::declare > a list of any of the pseudo-module names each containing
at least one upper case character.  this will cause that name to be exported
into your namespace as a subroutine.

    use here::declare 'MY';

    use here MY [qw($x $y)] => [0, 0];

=head1 SEE ALSO

C< here::declare > is built on top of the L< here > framework.

in writing this module, I was pushed by p5p to make the interface a bit closer
to the native C< my > and C< our > keywords.  I did this with L<Devel::Declare>
in L<Begin::Declare>.  C<Begin::Declare> is certainly closer in usage to the
keywords, but the dependency on C<Devel::Declare> might prevent installation for
some people.  in addition, this module (despite using C<Filter::Util::Call>) is
a little safer to use than C<Begin::Declare> since the C<use> statement required
by this module more clearly delineates the scope of its actions.

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-here at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=here>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

1
