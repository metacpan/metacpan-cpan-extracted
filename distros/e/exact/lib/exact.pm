package exact;
# ABSTRACT: Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

use 5.014;
use strict;
use warnings;
use namespace::autoclean;
use Try::Tiny;
use Sub::Util 'set_subname';
use Import::Into;

our $VERSION = '1.13'; # VERSION

use feature    ();
use utf8       ();
use mro        ();
use IO::File   ();
use IO::Handle ();
use Carp       qw( croak carp confess cluck );

my %features = (
    10 => [ qw( say state switch ) ],
    12 => ['unicode_strings'],
    16 => [ qw( unicode_eval evalbytes current_sub fc ) ],
    18 => ['lexical_subs'],
    24 => [ qw( postderef postderef_qq ) ],
    28 => ['bitwise'],
);

my %deprecated = (
    16 => ['array_base'],
);

my %experiments = (
    20 => ['signatures'],
    22 => ['refaliasing'],
    26 => ['declared_refs'],
);

my @function_list = qw(
    nostrict nowarnings noutf8 noc3 nobundle noexperiments noskipexperimentalwarnings noautoclean nocarp notry
);

my @feature_list   = map { @$_ } values %features, values %deprecated, values %experiments;
my ($perl_version) = $^V =~ /^v5\.(\d+)/;

my ( $no_parent, $late_parent );

sub import {
    my ( $self, $caller ) = ( shift, caller() );
    my ( @bundles, @functions, @features, @classes );

    for (@_) {
        ( my $opt = $_ ) =~ s/^\-//;

        if ( grep { $_ eq $opt } @feature_list ) {
            push( @features, $opt );
        }
        elsif ( grep { $_ eq $opt } @function_list ) {
            push( @functions, $opt );
        }
        elsif ( $opt =~ /^:?v?5?\.?(\d+)/ and $1 >= 10 ) {
            push( @bundles, $1 );
        }
        else {
            push( @classes, $opt );
        }
    }

    strict->import unless ( grep { $_ eq 'nostrict' } @functions );
    warnings->import unless ( grep { $_ eq 'nowarnings' } @functions );

    unless ( grep { $_ eq 'noutf8' } @functions ) {
        utf8->import;
        binmode( $_, ':utf8' ) for ( *STDIN, *STDERR, *STDOUT );
        'open'->import::into( $caller, ':std', ':utf8' );
    }

    mro::set_mro( $caller, 'c3' ) unless ( grep { $_ eq 'noc3' } @functions );

    if (@bundles) {
        my ($bundle) = sort { $b <=> $a } @bundles;
        feature->import( ':5.' . $bundle );
    }
    elsif ( not grep { $_ eq 'nobundle' } @functions ) {
        feature->import( ':5.' . $perl_version );
    }

    try {
        feature->import($_) for (@features);
        my @experiments = map { @{ $experiments{$_} } } grep { $_ <= $perl_version } keys %experiments;
        feature->import(@experiments) unless ( not @experiments or grep { $_ eq 'noexperiments' } @functions );
    }
    catch {
        my $err = $_;
        $err =~ s/\s*at .+? line \d+\.\s+//;
        croak("$err via use of exact");
    };

    monkey_patch( $self, $caller, ( map { $_ => \&{ 'Carp::' . $_ } } qw( croak carp confess cluck ) ) )
        unless ( grep { $_ eq 'nocarp' } @functions );

    eval qq{
        package $caller {
            use Try::Tiny;
        };
    } unless ( grep { $_ eq 'notry' } @functions );

    my @late_parents = ();

    my $use = sub {
        my ( $class, $pm, $caller, $params ) = @_;

        my $failed_require;
        try {
            require "$pm" unless ( do {
                no strict 'refs';
                no warnings 'once';
                ${"${caller}::INC"}{$pm};
            } );
        }
        catch {
            croak($_) unless ( index( $_, q{Can't locate } ) == 0 );
            $failed_require = 1;
        };
        return 0 if $failed_require;

        ( $no_parent, $late_parent ) = ( undef, undef );

        "$class"->import( $caller, @$params ) if ( "$class"->can('import') );

        if ($late_parent) {
            push( @late_parents, [ $class, $caller ] );
        }
        elsif ( not $no_parent and index( $class, 'exact::' ) != 0 ) {
            $self->add_isa( $class, $caller );
        }

        return 1;
    };

    for my $class (@classes) {
        my $params = ( $class =~ s/\(([^\)]+)\)// ) ? [$1] : [];
        ( my $pm = $class ) =~ s{::|'}{/}g;
        $pm .= '.pm';

        $use->(
            'exact::' . $class,
            'exact/' . $pm,
            $caller,
            $params,
        ) or $use->(
            $class,
            $pm,
            $caller,
            $params,
        ) or croak(
            "Can't locate exact/$pm or $pm in \@INC " .
            "(you may need to install the exact::$class or $class module)" .
            '(@INC contains: ' . join( ' ', @INC ) . ')'
        );
    }

    $self->add_isa(@$_) for @late_parents;

    warnings->unimport('experimental')
        unless ( $perl_version < 18 or grep { $_ eq 'noskipexperimentalwarnings' } @functions );

    namespace::autoclean->import( -cleanee => $caller ) unless ( grep { $_ eq 'noautoclean' } @functions );
}

sub monkey_patch {
    my ( $self, $class, %patch ) = @_;
    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${class}::$_"} = set_subname( "${class}::$_", $patch{$_} ) for ( keys %patch );
    }
    return;
}

sub add_isa {
    my ( $self, $parent, $child ) = @_;
    {
        no strict 'refs';
        push( @{"${child}::ISA"}, $parent ) unless ( grep { $_ eq $parent } @{"${child}::ISA"} );
    }
    return;
}

sub no_parent {
    $no_parent = 1;
    return;
}

sub late_parent {
    $late_parent = 1;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact - Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

=head1 VERSION

version 1.13

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/exact.svg)](https://travis-ci.org/gryphonshafer/exact)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact/badge.png)](https://coveralls.io/r/gryphonshafer/exact)

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use utf8;
    use open ':std', ':utf8';
    use feature ':5.23';
    use feature qw( signatures refaliasing bitwise );
    use mro 'c3';
    use IO::File;
    use IO::Handle;
    use namespace::autoclean;
    use Carp qw( croak carp confess cluck );
    use Try::Tiny;

    no warnings "experimental::signatures";
    no warnings "experimental::refaliasing";
    no warnings "experimental::bitwise";

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact -noexperiments, -fc, -signatures;
    use exact 5.16, -nostrict, -nowarnings, -noc3, -noutf8, -noautoclean;
    use exact '5.20';

=head1 DESCRIPTION

L<exact> is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods along with a lot of other things, plus allow for easy
extension via C<exact::*> classes. The goal is to reduce header boilerplate,
assuming defaults that seem to make sense but allowing overrides easily.

By default, L<exact> will:

=over 4

=item *

enable L<strictures> (version 2)

=item *

load the latest L<feature> bundle supported by the current Perl version

=item *

load all experimental L<feature>s and switch off experimental warnings

=item *

set C3 style of L<mro>

=item *

use utf8 in the source code context and set STDIN, STROUT, and STRERR to handle UTF8

=item *

enable methods on filehandles

=item *

import L<Carp>'s 4 methods

=item *

import L<Try::Tiny> (kinda)

=back

=head1 IMPORT FLAGS

L<exact> supports the following import flags:

=head2 C<nostrict>

This skips turning on the L<strict> pragma.

=head2 C<nowarnings>

This skips turning on the L<warnings> pragma.

=head2 C<noutf8>

This skips turning on UTF8 in the source code context. Also skips setting
STDIN, STDOUT, and STDERR to expect UTF8.

=head2 C<noc3>

This skips setting C3 L<mro>.

=head2 C<nobundle>

Normally, L<exact> will look at your current version and find the highest
supported L<feature> bundle and enable it. Applying C<nobundle> causes this
behavior to be skipped. You can still explicitly set bundles yourself.

=head2 C<noexperiments>

This skips enabling all features currently labled experimental by L<feature>.

=head2 C<noskipexperimentalwarnings>

Normally, L<exact> will disable experimental warnings. This skips that
disabling step.

=head2 C<noautoclean>

This skips using L<namespace::autoclean>.

=head2 C<nocarp>

This skips importing the 4 L<Carp> methods: C<croak>, C<carp>, C<confess>,
C<cluck>.

=head2 C<notry>

This skips importing the functionality of L<Try::Tiny>.

=head1 BUNDLES

You can always provide a list of explicit features and bundles from L<feature>.
If provided, these will be enabled regardless of the other import flags set.

    use exact -noexperiments, -fc, -signatures;

Bundles provided can be exactly like those described in L<feature> or in a
variety of obvious forms:

=over 4

=item *

:5.26

=item *

5.26

=item *

v5.26

=item *

26

=back

=head1 EXTENSIONS

It's possible to write extensions or plugins for L<exact> to provide
context-specific behavior, provided you are using Perl version 5.14 or newer.
To activate these extensions, you need to provide their named suffix as a
parameter to the C<use> of L<exact>.

    # will load "exact" and "exact::class";
    use exact -class;

    # will load "exact" and "exact::role" and turn off UTF8 features;
    use exact -role, -noutf8;

It's possible to provide parameters to the C<import> method of the extension.

    # will load "exact" and "exact::answer" and pass "42" to the import method
    use exact 'answer(42)';

=head2 Writing Extensions

An extension may but is not required to have an C<import> method. If such a
method does exist, it will be passed: the package name, the name of the caller
of L<exact>, and any parameters passed.

    package exact::example;
    use exact;

    sub import {
        my ( $self, $caller, $params ) = @_;
        exact->monkey_patch( $caller, 'example' => \&example );
    }

    sub example {
        say 42;
    }

    1;

=head1 PARENTS

You can use C<exact> to setup inheritance as follows:

    use exact 'SomeModule', 'SomeOtherModule';

This is roughly equivalent to:

    use exact;
    use parent 'SomeModule', 'SomeOtherModule';

See also the C<no_parent> method.

=head1 METHODS

=head2 C<monkey_patch>

Monkey patch functions into a given package.

    exact->monkey_patch( 'PackageName', add => sub { return $_[0] + $_[1] } );
    exact->monkey_patch(
        'PackageName',
        one   => sub { return 1 },
        two   => sub { return 2 },
        three => sub { return 3 },
    );

=head2 C<add_isa>

This method will add a given parent to the @ISA of a given child.

    exact->add_isa( 'SuperClassParent', 'SubClassChild' );

=head2 C<no_parent>

Normally, if you specify a parent, it'll be added as a parent by inclusion in
C<@INC>. If you don't want to skip C<@INC> inclusion, you can call C<no_parent>
in the C<import> of the module being specified as a parent.

    sub import {
        exact->no_parent;
    }

=head2 C<late_parent>

There may be a situation where you need an included parent to be listed last in
C<@INC> (at least relative to other parents). Normally, you'd do this by putting
the name last in the list of modules. However, if for some reason you can't do
that, you can call C<late_parent> from the C<import> of the parent that should
be delayed in C<@INC> inclusion.

    sub import {
        exact->late_parent;
    }

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/exact>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/exact>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/exact.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
