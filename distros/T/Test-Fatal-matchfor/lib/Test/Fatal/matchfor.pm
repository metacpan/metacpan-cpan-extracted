use 5.008;
use strict;
use warnings;

use Scalar::Util ();
use Exporter ();

package Test::Fatal::matchfor;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';
our @EXPORT    = qw( matchfor );
our @ISA       = qw( Exporter );

sub matchfor
{
	my @matchers = @_;
	bless \@matchers, do {
		package #
		Test::Fatal::matchfor::Internals::MATCHER;
		use overload
			q[==] => 'match',
			q[eq] => 'match',
			q[""] => 'to_string',
			fallback => 1;
		sub to_string {
			$_[0][0]
		}
		sub match {
			my ($self, $e) = @_;
			my $does = Scalar::Util::blessed($e) ? ($e->can('DOES') || $e->can('isa')) : undef;
			for my $s (@$self) {
				return 1 if  ref($s) && $e =~ $s;
				return 1 if !ref($s) && $does && $e->$does($s);
			}
			return;
		}
		__PACKAGE__;
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Fatal::matchfor - match exceptions by class name or regexp

=head1 SYNOPSIS

Let's say you're testing the following Moose class...

   package Goose {
      use Moose;
      has feather_count => (is => 'rw', isa => 'Int');
   }

In Moose 2.1102 and above, exception objects are thrown, but in earlier
versions of Moose, only string errors are given.

So we might want to test it something like this:

   use Test::More;
   use Test::Fatal;
   
   use Goose;
   
   my $e = exception {
      Goose->new(feather_count => 3.1)
   };
   
   ref($e)
      ? isa_ok($e, 'Moose::Exception::ValidationFailedForTypeConstraint')
      : like($e, qr{does not pass the type constraint})

This module provides a small shortcut for that pattern:

   use Test::More;
   use Test::Fatal;
   use Test::Fatal::matchfor;
   
   use Goose;
   
   my $e = exception {
      Goose->new(feather_count => 3.1)
   };
   
   is(
      $e,
      matchfor(
         'Moose::Exception::ValidationFailedForTypeConstraint',
         qr{does not pass the type constraint},
      ),
   );

=head1 DESCRIPTION

Test::Fatal::matchfor exports the C<matchfor> function which accepts a
list of class/role names and regular expressions, and constructs an
object overloading C<< == >> and C<< eq >> to return true if compared
for equality against a string that matches one of those regular
expressions, or an object that isa/does one of those class/role names.

So for example, to check a type constraint error in Moose, you might
use:

   my $tc_err = matchfor(
      'Moose::Exception::ValidationFailedForTypeConstraint',
      'Moose::Exception::ValidationFailedForInlinedTypeConstraint',
      qr{does not pass the type constraint},
   ),
   
   is($exception, $tc_err, "encountered error as expected");

=begin trustme

=item matchfor

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Test-Fatal-matchfor>.

=head1 SEE ALSO

L<Test::Fatal>, L<Moose::Exception>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

