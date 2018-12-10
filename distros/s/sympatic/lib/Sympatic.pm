package Sympatic;
our $VERSION = '0.1';
use strict;
use warnings;
require Import::Into;

sub import {

    my $to = caller;
    my %feature = qw<
        utf8all .
        utf8    .
        utf8io  .
        oo      .
        path    .
    >;

    English->import::into($to, qw<  -no_match_vars >);
    feature->import::into($to, qw< say state >);
    strict->import::into($to);
    warnings->import::into($to);
    Function::Parameters->import::into($to);

    shift; # 'Sympatic', the package name

    while (@_) {

        # disable default features
        if ( $_[0] =~
            /- (?<feature>
            utf8all |
            utf8    |
            utf8io  |
            oo      |
            path    )/x
        ) {
            delete $feature{ $+{feature} };
            shift;
            next;
        }

        ...

    }

    $feature{path} and do { Path::Tiny->import::into($to) };
    $feature{oo} and do {
        Moo->import::into($to);
        MooX::LvalueAttribute->import::into($to);
    };

    $feature{utf8all} and do {
         utf8::all->import::into($to);
         delete $feature{$_} for qw<  utf8 utf8io >;
    };

    $feature{utf8} and do {
        utf8->import::into($to);
        feature->import::into($to, qw< unicode_strings >);
    };

    $feature{utf8io} and do { 'open'->import::into($to,qw< :UTF-8 :std >) };

    # see https://github.com/pjf/autodie/commit/6ff9ff2b463af3083a02a7b5a2d727b8a224b970
    # TODO: is there a case when caller > 1 ?

    # $feature{autodie} and do {
    #      autodie->import::into(1);
    # }

}

1;

=encoding utf8

=head1 NAME

Sympatic - A more producive perl thanks to CPAN

=head1 STATUS

=for HTML
<a href="http://travis-ci.org/sympa-community/p5-sympatic/">
<img src="https://travis-ci.org/sympa-community/p5-sympatic.svg?branch=master">
</a>

=head1 SYNOPSIS

    package Counter;
    use Sympatic;

    use Types::Standard qw< Int >;

    has qw( value is rw )
    , default => 0
    , lvalue  => 1
    , isa     => Int;

    method next { ++$self->value }
    method ( Int $add ) { $self->value += $add }

see L<usage|usage> section for more details.

=head1 DESCRIPTION

This document is an introduction to Sympatic Perl,

L<project|http://www.sympa.org> developers community focus on

The default behavior of L<Perl|http://www.perl.org> could be significantly
improved by the pragmas and CPAN modules so it can fit the expectations
of a community of developers and help them to enforce what they consider
as the best practices. For decades, the minimal boilerplate seems to be

    use strict;
    use warnings;

This boilerplate can evolve over the time be much more larger. Fortunately, it
can be embedded into a module.

Sympatic is the boilerplate module for the L<Sympa project|http://www.sympa.org>
project.

Some of the recommendations are inspired by the L<Perl Best
Practices|http://shop.oreilly.com/product/9780596001735.do> book from L<Damian
Conway|http://damian.conway.org/>. We refer to this book as PBP in this document.

=head2 the goals behind Sympatic

This section describes the goals that leads to the choices made for Sympatic and
the coding style recommendations.

=head3 balance between old servers and modern tools

As we try to keep noone left behind, we also need to think about the future.

As some sympa servers run on quiet old unix systems, we try to make our code
running on old versions of the perl interpreters. However, this should not
take us away from features of recent versions of perl that really helps
performances, stability or good coding practices.

We are currently supporting all the versions of perl since perl 5.16
(released the 2012-May-2). That's the best we can afford. Please contact us
if you need support of older Perl.

=head3 reduce infrastructure code

As perl emphasize freedom, it leaves you on your own with minimal tooling
to write such simple and standard things most of us don't want to write by
hand anymore (like object properties getters and setters, function parameter
checkings, ...). This code is described by Damian Conway as "the infrastructure
code".

CPAN provide very good modules to make those disapear and we picked the ones
we think to be the most relevant. Putting them all together provides the ability
to write very expressive code without sacrifying the power of Perl.

=head3 make perl more familiar for newcommers

Choosing the CPAN modules to reduce infrastructure codes and writing the coding
style recommendation below was made with our friends from the other dynamic langages
in mind. We really expect developers from the ruby, javascript and python provide
a much better experience using Sympatic as it provides some idioms close to the ones
they know in adition of the unique perl features.

=head3 less typing and opt out policy

Sympatic has the ability to provide different sets of features
(see C<features> section) and the ones that are imported by default
are the one that are used in the most common cases. For exemple: as
most of the sympa packages actually are objects, the L<Moo|Moo> keywords
are exported by default.

See the L<features|features> section to learn how to avoid some of them.

=head2 what use Sympatic means?

If you are experimented Perl developers, the simplest way to
introduce Sympatic is to say that

    use Sympatic;

is equivalent to
 
    use strict;
    use warnings;
    use feature qw< unicode_strings say state >;
    use English qw< -no_match_vars >;
    use utf8;
    use Function::Parameters;
    use Moo;

If you're not, we highly recommend the the well written L<Perl
Documentation|http://perldoc.perl.org> (the `*tut` sections).
Here we provide a very short description

The L<utf8|https://perldoc.perl.org/utf8.html> pragma makes perl aware
that the code of your project is encoded in utf8.

The L<strict|https://perldoc.perl.org/strict.html> pragma avoid the
the perl features requiring too much caution. Also the
L<warnings|https://perldoc.perl.org/warnings.html> one provides very
informational messages when perl detects a potential mistake. You can
use L<diagnostics|https://perldoc.perl.org/diagnostics.html> to get a
direct reference to the perl manual when a warning or an error message is
risen.

L<feature|https://metacpan.org/pod/feature> is the Perl pragma to enable new
features from new versions of the perl interpreter. If the perl interpreter
you are using is too old, you will get an explicit message about the missing
feature. Note that we use

    use feature qw< unicode_strings say state >;
    use strict;
    use warnings;

instead of

    use v5.14;

to avoid the use of features related to
L<smart match|https://perldoc.perl.org/perlop.html#Smartmatch-Operator>
like the L<given/when flow control|https://perldoc.perl.org/functions/given.html>
as they were abundantly criticized and will be removed in perl 5.28.

L<English|https://metacpan.org/pod/English> - enable the english (named against
awk variables) names for the variables documented in
L<the perlvar manual|https://metacpan.org/pod/perlvar>.

so basically, using C<Sympatic>, the two following instructions are the same.

    print $(;
    print $GID;

L<Function::Parameters|https://metacpan.org/pod/Function::Parameters> introduce
the keywords C<fun> and C<method> to allow function signatures with gradual typin,
named parameters and other features probably inspired by perl6, python and javascript.
See L<examples|examples> section.

L<Type::Standard|https://metacpan.org/pod/Types::Standard> provide nice generic
way to define types that can be installed used from the C<fun> and C<method>
signatures or the C<isa> contraint of a Moo property declaration.

=head1 USAGE

=head2 declaring functions

In addition to the C<sub> keyword provided by perl (documented in the
L<perlsub|perlsub> manual), Sympatic comes with C<fun> and C<method>
(provided and documented in L<Function::Parameters|Function::Parameters>).

As those two documentations are very well written, the current documentation
only discuss about picking one of them and providing some exemples.

Use C<fun> when you can provide a signature for a function. C<fun> provide
a signature syntax inspired by L<perl6|perl6> so you can use positional and
named parameters, default values, parameter destructuring and gradual typing.
You should use it in most cases.

Here are some examples:

    # positional parameter $x
    fun absolute ( $x ) { $x < 0 ? -$x : $x }

    # typing
    use Types::Standard qw< Int >;
    fun absolute ( Int $x ) { $x < 0 ? -$x : $x }

    # default parameters
    fun point ( $x = 0, $y = 0 ) { "( $x ; $y )" }
    point 12; # ( 12 ; 0 )

    # named parameters
    fun point3D ( :$x = 0, :$y = 0, :$z = 0 ) { "( $x ; $y ; $z )" }
    say point3D x => 12; # ( 12 ; 0 ; 0 )

Use the C<sub> keyword fully variadic functions (the parameters are stored in
the C<@_> array) or to use for example, let's assume you want to write a simple
CSV seriralizer usable like this

    print csv qw( header1 header2 header3 );
    # outputs:
    # header1;header2;header3

this is a naive implementation demonstrating the use of C<@_>


    sub csv { ( join ';', @_ ) , "\n" }


common cases are list reduction or partial application

=head3 default perl signatures, prototypes and attributes

Experienced perl programmers should note that note that we don't use the perl
signatures as documented in L<perlsub|perlsub> for two reasons:

Those signatures are appears as experimental in L<perl5.20|perl5.20> and
are finally L<perl5.26|perl5.26> (as we are bound to L<perl5.16|perl5.16>).
Also, the signatures provided by L<Function::Parameters|Function::Parameters>) are
much more powerful than the core ones (see description above).

Attributes are still available. If you need to declare a prototype, they are available
using the C<:prototype()> attribute as described in the
L<OMGTODOFINDALINK|"signature" section of perlsub>. For exemple

    fun twice ( $block ) :prototype(&) { &$block; &$block }
    twice {say "hello"}
    # outputs:
    # hello
    # hello

=head2 Object Oriented programming

Sympatic imports L<Moo|Moo> and L<Function::Parameters> which means that
you can declare an object using

=over

=item

C<has> to define a new property

=item

C<extends> to inherit from a super class

=item

C<with> to compose your class using roles

=item

C<method> to combine with roles

=back

TODO: that keywords like around, after ?

    use Sympatic;
    use Type::Standard qw< Int >;

    has value
        ( is      => 'rw'
        , isa     => Int
        , lvalue  => 1
        , default => 0 );

    method add ( Int $x ) { $self->value += $x }

Note that the method C<add()> is almost useless when C<$self-&gt;value> is lvalue.

    package Human;
    use Sympatic;
    use Type::Standard qw< InstanceOf Str >;

    has qw( name is rw )
    , isa  => Str;

    method greetings ( (InstanceOf['Human']) $other ) {
        sprintf "hello %s, i'm %s and i want to be a friend of you"
            , $self->name
            , $other->name
    }

=head2 work with the filesystem

the "all in one" C<path> helper from L<Path::Tiny|https://metacpan.org/pod/Path::Tiny>
is exported by Sympatic. refer to the documentation for examples.

=head2 set/unset features

    TODO: describe how to enable/disable features
    TODO: describe the features themselves

=head1 CONTRIBUTE

you are welcome to discuss about the C<Sympatic> style on the Sympa project
developers mailing list. If your proposal is accepted, edit the module the
way you describe, update the documentation and test the whole thing.

    cpanm --installdeps .
    RELEASE_TESTING=1 prove -Ilib t

=head1 Sympa and CPAN

Every line of code that is used in the Sympa project should be carrefully

The CPAN community reduce the cost of maintaining infrastructure code. And
by maintaining it, we mean it the great way: improve, optimize, document,
debug, test in a large number of perl bases, ...

We also want to benefit as much as possible from the experience, ideas and
knowledge of the CPAN members.

So if you want to contribute to Sympa, please concider picking a module on CPAN
that does the job and contributing to it if needed. Push your own stuff if
needed.

=head2 other CPAN modules

=head3 those we also rely on

L<Dancer2|https://metacpan.org/pod/Dancer2> for web developpement,
L<Template Toolkit|https://metacpan.org/pod/Template> for text templating,

=head3 those which can be useful too


L<Curry|https://metacpan.org/pod/Curry> provide ease the creation of
streams and callbacks.

    sub { $self->foo('bar') }

can be written as

    $self->curry::foo('bar')

=head2

L<Perlude|https://metacpan.org/pod/Perlude> is the way to manipulate
and combine streams.

=head1 AUTHORS

thanks for those people who contributed to the sympatic module (by date)

=over

=item Marc Chantreux

=item David Verdin

=item Mohammad S Anwar

=item Stefan Hornburg (Racke)

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Sympa community <F<sympa-developpers@listes.renater.fr>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License subee
(http://www.perl.com/perl/misc/Artistic.html)

=head1 LICENCE

    Copyright (C) 2017,2018 Sympa Community

    Sympatic is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.

    Sympatic is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, see <http://www.gnu.org/licenses/>.

    Authors:
    Marc Chantreux <marc.chantreux@renater.fr>
    Stefan Hornburg (Racke) <racke@linuxia.de>

=cut
