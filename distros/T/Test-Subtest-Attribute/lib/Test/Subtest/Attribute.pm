package Test::Subtest::Attribute;

# ABSTRACT: Declare subtests using subroutine attributes

use 5.006;
use strict;
use warnings;


use Attribute::Handlers;
use Test::Builder qw();

use base qw( Exporter );

our @EXPORT_OK = qw(
    subtests
);
our $VERSION = '0.03';

my @subtests;
my $builder;
my $unknown_sub_count = 0;

sub UNIVERSAL::Subtest : ATTR(CODE) {       ## no critic (Capitalization)
    my ( $package, $symbol, $referent, $attr, $data ) = @_;

    my $sub_name;
    if ( ref $symbol ) {
        $sub_name = *{ $symbol }{NAME};
    }

    my @args = ref $data ? @{ $data } : ();
    my ( $name, $append_prepend ) = @args;
    $append_prepend ||= 'append';
    if ( $sub_name && ! $name ) {
        $name = $sub_name;
        $name =~ s/ ^ subtest_ //msx;
    }

    my %args = (
        coderef   => $referent,
        data      => $data,
        name      => $name,
        'package' => $package,
        sub_name  => $sub_name,
        symbol    => $symbol,
        where     => $append_prepend,
    );

    subtests()->add( %args );

    return 1;
}


sub subtests {
    return __PACKAGE__;
}



sub add {
    my ( $self, %args ) = @_;

    $args{name} ||= $args{sub_name};
    if ( ! $args{name} ) {
        $unknown_sub_count++;
        $args{name} = '__unknown_subtest' . $unknown_sub_count;
    }

    # If we have a subtest with the same name as one that's already in our list,
    # replace it.  This allows derived classes to override the subtests in
    # parent classes.
    foreach my $subtest ( @subtests ) {
        if ( $subtest->{name} eq $args{name} ) {
            $subtest = \%args;
            return 1;
        }
    }

    $args{where} ||= 'append';
    if ( $args{where} eq 'prepend' ) {
        unshift @subtests, { %args };
    }
    else {
        push @subtests, { %args };
    }

    return 1;
}


sub prepend {
    my ( $self, %args ) = @_;

    return subtests()->add( %args, where => 'prepend' );
}


sub append {
    my ( $self, %args ) = @_;

    return subtests()->add( %args, where => 'append' );
}


sub remove {
    my ( $self, $which ) = @_;

    return if ! $which;

    my $field = ref $which ? 'coderef' : 'name';
    my @clean = grep { $_->{ $field } ne $which } @subtests;
    @subtests = @clean;

    return 1;
}


sub get_all {
    return @subtests;
}


sub run {
    my ( $self, %args ) = @_;

    $builder ||= $args{builder} || Test::Builder->new();

    foreach my $subtest ( @subtests ) {
        my $invocant = $args{invocant} || $subtest->{package} || 'main';
        my $name     = $subtest->{name} || '(unknown)';
        if ( $args{verbose_names} ) {
            my $sub_name     = $subtest->{sub_name} || '(unknown sub)';
            my $package_name = $subtest->{package};
            my $verbose_name = ( $package_name && $package_name ne 'main' )
                ? "${package_name}::${sub_name}"
                : $sub_name;
            $name .= " [$verbose_name]";
        }

        my $subref = $subtest->{coderef};
        if ( $subtest->{sub_name} && ! $subref ) {
            $subref = $invocant->can( $subtest->{sub_name} );
        }
        if ( $subref && ref $subref eq 'CODE' ) {
            $builder->subtest( $name, sub { return $invocant->$subref(); } );
        }
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Subtest::Attribute - Declare subtests using subroutine attributes

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Test::More;
  use Test::Subtest::Attribute qw( subtests );
  
  sub subtest_foo :Subtest {
      ok( 1, 'foo is OK' );
      return 1;
  }
  
  sub subtest_bar :Subtest( 'name for bar' ) {
      ok( 1, 'bar is OK' );
      return 1;
  }

  subtests()->run();
  done_testing();

=head1 DESCRIPTION

This module provides a simple way, using a subroutine attribute called C<:Subtest>, to declare normal subroutines to be subtests in a test script.

Subtests are typically declared using a call to the C<subtest()> function from L<Test::More>, in one of the two following ways:

  subtest 'name1'  => sub { ... };  # An anonymous sub
  subtest 'name 2' => \&some_named_sub;

The first way can quickly lead to long anonymous subs that can present issues when looking at stacktraces for debugging, profiling, logging, etc.
The second way usually leads to repeating the same, or similar, names for each subtest subroutine, in addition to declaring the sub itself, e.g.:

  subtest 'test_this' => \&test_this;
  subtest 'test_that' => \&test_that;
  ...
  sub test_this { ... }
  sub test_that { ... }
  ...

This module lets you declare those subtests without calls to the C<subtest()> function, by simply adding a C<:Subtest> attribute to any
subroutine that you'd like to have executed as a subtest, like so:

  sub subtest_name1 :Subtest {
    ...
  }

That declares a subtest named 'name1' (the subtest_ part of the name, if present, is automatically stripped off).

If you'd like to specify the name of the subtest explicitly, which is handy if you'd like to use a name that includes characters. such as spaces,
that aren't allowed in bareword identifiers, you can do so by providing an argument to the C<:Subtest> attribute like so:

  sub some_named_sub :Subtest('name 2') {
    ...
  }

When you're done declaring subtests, you run all the ones you've queued up by calling C<subtests()->run()>.

From this module, most test scripts will only need to use the C<:Subtest> attribute and the C<run()> method described below.
Most of the other methods described below are for more advanced usage, such as in test modules that might want to conditionally
add, remove, or otherwise manipulate the subtests managed herein.

=head1 METHODS

=head2 add

  subtests()->add( coderef => \%my_sub );

Adds a subroutine to the current queue of subtests.
This method can accept a number of named arguments.

=over

=item name

Indicates the name of this particular subtest.
If the name isn't  unique, it will replace the previously declared subtest with the same name.

=item where

A value of 'prepend' indicates the subtest should be added to the head of the queue of subtests.
A value of 'append' indicates the subtest should be added to the end of the queue of subtests.
If not given, the default is to append the subtest.

=item coderef

A reference to the subroutine (named or anonymous) to eventually call for this subtest.

=item package

The package from which the subtest should be invoked.
Typically, this would be the package that the subroutine lives in.
Calling the C<run()> method with an C<invocant> argument takes precedence over this.
It also appears in the fully qualified subroutine name, if C<run()> is called in verbose mode.
Defaults to C<main> if not given.

=item sub_name

The name of the subroutine to call for this subtest.
If C<coderef> is defined, this is only needed for display purposes.
If C<coderef> is not defined, the C<run()> method will attempt to find a sub with this name that can be called
via the C<invocant> or C<package> arguments.

=back

=head2 prepend

  subtests()->prepend( coderef => \%my_sub );

Adds a subtest to the head of the current queue of subtests.
Takes the same arguments as the C<add()> method, and sets the C<where> param to C<prepend>.

=head2 append

  subtests()->append( coderef => \%my_sub );

Adds a subtest to the end of the current queue of subtests.
Takes the same arguments as the C<add()> method, and sets the C<where> param to C<append>.

=head2 remove

  subtests()->remove( $name_or_coderef );

Removes the indicated subtest(s) from the queue.
The argument can either be the name or the coderef associated with the subtest.

=head2 get_all

  subtests()->get_all();

Returns a list of all of the subtests currently in the queue.

=head2 run

  subtests()->run( %args );

Runs all of the subtests that are currently in the queue.

This method can be called with any of the following arguments:

=over

=item builder

The test builder to use.  If none is given, a new L<Test::Builder> instance will be created.

=item invocant

If given, the subtest subroutines will be invoked via this reference.

NOTE: When the C<:Subtest> attribute is used, the name of the package that the subroutine appears in will be remembered in the subtest
metadata, and that package name will be used if no C<invocant> argument is given explicitly when calling this method.
If that value happens to be undefined for any reason, the package name C<main> is the default instead.

=item verbose_names

When given, and set to a true value, subtest names will be displayed with C< [sub name]> appended.
If the package name can be determined, and is not C<main>, the sub name will be fully qualified with such.

=back

=head1 FUNCTIONS

=head2 subtests

Returns a handle that can be used to invoke the methods in this module.
As such, this is the only function exported by this module.

Currently, this just returns the name of this package, but, in the future, it could return an object instance.

=head1 SEE ALSO

L<Attribute::Handlers>
L<Test::Builder>

=head1 AUTHOR

Ben Marcotte <bmarcotte NOSPAM cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ben Marcotte.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
