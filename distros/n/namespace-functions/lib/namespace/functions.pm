#!/usr/bin/perl -c

package namespace::functions;

=head1 NAME

namespace::functions - Keep package's namespace clean

=head1 SYNOPSIS

  package My::Class;

  # import some function
  use Scalar::Util 'looks_like_number';

  # collect the names of all previously created functions
  use namespace::functions;

  # our function uses imported function
  sub is_num {
      my ($self, $val) = @_;
      return looks_like_number("$val");
  }

  # delete all previously collected functions
  no namespace::functions;

  # our package doesn't provide imported function anymore!

=head1 DESCRIPTION

This pragma allows to collect all functions existing in package's
namespace and finally delete them.

The problem is that any function which is imported to your
package, stays a part of public API of this package. I.e.:

  package My::PollutedClass;
  use Scalar::Util 'looks_like_number';

  sub is_num {
      my ($val) = @_;
      return looks_like_number("$val");
  }

  package main;
  print My::PollutedClass->can('looks_like_number');  # true

Deleting imported function from package's stash is a solution, because the
function will be not available at run-time:

  delete {\%My::PoorSolutionClass::}->{looks_like_number};

The C<namespace::functions> collects the function names and finally deletes
them from package's namespace.

=for readme stop

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0101';


use Symbol::Util ();


# Store collected functions in this hash
my %Functions = ();


# Collect functions
sub import {
    my (undef, @args) = @_;
    my $caller = caller;

    my %except = do {
        my @except;
        while (my $arg = shift @args) {
            if ($arg eq '-except') {
                my $what = shift @args;
                push @except, (ref $what||'') eq 'ARRAY' ? @$what : $what;
            };
        };
        map { $_ => 1 } @except;
    };

    my @functions = grep { defined Symbol::Util::fetch_glob("${caller}::$_", 'CODE') }
                    grep { not $except{$_} }
                    keys %{ Symbol::Util::stash($caller) };

    $Functions{$caller} = \@functions;

    return;
};


# Delete functions
sub unimport {
    my (undef, @args) = @_;
    my $caller = caller;

    my @also;
    while (my $arg = shift @args) {
        if ($arg eq '-also') {
            my $what = shift @args;
            push @also, (ref $what||'') eq 'ARRAY' ? @$what : $what;
        };
    };

    my @functions = grep { defined Symbol::Util::fetch_glob("${caller}::$_", 'CODE') }
                    @{ $Functions{$caller} }, @also;

    foreach my $function (@functions) {
        Symbol::Util::delete_sub("${caller}::$function");
    };

    return;
};


1;


__END__

=head1 IMPORTS

=over

=item use namespace::functions;

Collects all functions from our namespace.

=item use namespace::functions -except => 'func';

=item use namespace::functions -except => ['func1', 'func2'];

Collects all functions from our namespace without listed functions.

=item no namespace::functions;

Deletes all previously collected functions from our namespace.

=item use namespace::functions -also => 'func';

=item use namespace::functions -also => ['func1', 'func2'];

Deletes all previously collected functions and also additional functions from
our namespace.

=back

=head1 OVERVIEW

This pragma needs to be placed in the right order: after last C<use> which
imports some unwanted functions and before first C<sub>.

  package My::Example;

  use Carp 'confess';
  use Scalar::Util 'blessed'

  use namespace::functions;

  sub some_method {
      my ($self) = @_;
      confess("Call as a method") if not blessed($self);
      # ...
  };

  no namespace::functions;

You can check if your package is clean with L<Class::Inspector> module and
its methods: C<functions> and C<methods>.

  use My::Example;
  use Class::Inspector;
  use YAML;
  print Dump ( {
        functions => [Class::Inspector->functions("My::Example")],
        methods   => [Class::Inspector->methods("My::Example")],
  } );

=head2 Moose

L<Moose> keywords can be unexported with C<no Moose> statement.  Even that,
L<Moose> imports following functions: C<blessed>, C<confess>, C<meta>.  The
C<meta> method is required by Moose framework and should be unchanged.  The
others can be deleted safely.

  package My::MooseClass;

  use Moose;

  use namespace::functions -except => 'meta';

  sub my_method {
      my ($self, $arg) = @_;
      return blessed $self;
  };

  no namespace::functions;

  # The My::MooseClass now provides "my_method" and "meta" only.

=head1 SEE ALSO

This module is inspired by L<namespace::clean> module but it doesn't require
compiled XS modules.  It also doesn't work lexically so C<unimport> method
have to be called explicitly.

See also: L<namespace::clean>, L<Class::Inspector>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=namespace-functions>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2011 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

