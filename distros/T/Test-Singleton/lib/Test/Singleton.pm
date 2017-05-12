package Test::Singleton;

# $Id: Singleton.pm,v 1.4 2006/02/15 20:11:46 toni Exp $

use strict 'vars';
use vars qw($VERSION);

use Test::Builder;
use Test::More;

use vars qw($VERSION);
$VERSION = "1.02";

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    *{$caller.'::is_singleton'} = \&is_singleton;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub is_singleton {

  # get the args
  my ($class, $method1, $method2, $text) = @_;

  # load the class
  require_ok( $class );

  # set a default test name
  $text ||= "is singleton";

  my ( $instance1, $instance2 );

  like ( $instance1 = $class->$method1(),
  	 qr/$class/,
  	 "instance of object created" );

  like ( $instance2 = $class->$method2(),
  	 qr/$class/,
  	 "instance of object created" );

  # are two instaces identical? i.e. is $class a Singleton?
  cmp_ok ( $instance1,  "==", $instance2, $text);

}

=head1 NAME

Test::Singleton - Test for Singleton classes

=head1 SYNOPSIS

    use Test::More tests => 1;
    use Test::Singleton;
    is_singleton( "Some::Class", "new", "instance" );

=head1 DESCRIPTION

** If you are unfamiliar with testing B<read Test::Tutorial> first! **

This is asimple, basic module for checking whether a class is a
Singleton. A Singleton describes an object class that can have only
one instance in any system.  An example of a Singleton might be a
print spooler or system registry, or any kind of central dispatcher.

For a description and discussion of the Singleton class, see 
"Design Patterns", Gamma et al, Addison-Wesley, 1995, ISBN 0-201-63361-2.

=over 4

=back

=head1 SEE ALSO

=over 4

=item L<Class::Singleton>

Implementation of a "Singleton" class.

=item L<Test::Harness>

Interprets the output of your test program.

=back

=head1 AUTHOR

Toni Prug <toni@irational.org>

=head1 COPYRIGHT

Copyright (c) 2006. Toni Prug. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

See L<http://www.gnu.org/licenses/gpl.html>

=cut

1;
