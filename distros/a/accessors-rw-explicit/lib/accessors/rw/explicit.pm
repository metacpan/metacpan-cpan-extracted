package accessors::rw::explicit;

use warnings::register;
use strict;
use Carp qw/confess carp/;

use base 'accessors';
use constant style => "explicit";
use constant ExportLevel => 1;

=head1 NAME

accessors::rw::explicit - RW object attribute accessors, with explicit semantics

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS


    package Foo;
    use accessors::rw::explicit qw(foo bar baz);

    my $obj = bless {}, 'Foo';

    # always return the current value, even on set:
    $obj->set_foo( 'hello ' ) if $obj->bar( 'world' ) eq 'world';

    print $obj->foo, $obj->bar, $obj->set_baz( "!\n" );
    ...

=head1 DESCRIPTION

ceci n'est pas un Moose

The purpose of this module is to provide very basic 
object instance attribute accessors for basic perl5
blessed hash-reference objects. 

That is a mouthful. Essentially is is just an exercise in
codifying convention, and sensible code reuse. It is not 
an attempt at a complete object system, with flexible
attribute definitions. If you want that, you want Moose, 
end of.

This module will set up attribute accessors for you though, 
and allow you to specify a prefix on your getters and setters. It
denotes itself as explicit, as it defaults to different names 
for the getters and setters, namely prepending "set_" to setters.

so for foo you would get:

  $obj->set_foo( $foo );

and 

  my $foo = $obj->foo;

These prefixes can be changed by providing options on import.

eg:

  use accessors::rw::explicit ({get_prefix => 'you_tell_me_', set_prefix => 'I_tell_you_'}, 'foo');

would provide:

  $obj->I_tell_you_foo( $foo )

and 

  my $foo = $obj->you_tell_me_foo();

=head1 METHODS

=head2 GetPrefix

returns the prefix prepended to getters. Defaults to the empty string.

=cut

my $get_prefix = "";
sub GetPrefix { $get_prefix };

=head2 SetPrefix

returns the prefix prepended to setters. Defaults to "set_".

=cut

my $set_prefix = "set_";
sub SetPrefix { $set_prefix };

=head2 import

As with other accessors modules, this takes a list of the attributes
you want setting up:

  use accessors::rw::explicit qw(foo bar baz);

It can also change the default get and set prefixes by providing an optional 
options hash:

  use accessors::rw::explicit ({get_prefix => 'get_'}, qw/foo bar baz/);

The above would produce accessors that conform to the Perl Best Practice book's
recommendations.

=cut

sub import {
    my $class = shift;
    if ($_[0] && ref $_[0] eq 'HASH') {
        my $opts = shift;
        if (exists $opts->{get_prefix}) {
            $get_prefix = $opts->{get_prefix};
        } 
        if (exists $opts->{set_prefix}) {
            $set_prefix = $opts->{set_prefix};
        }
    }
    $class->SUPER::import(@_);
}

=head2 create_accessors_for

Creates a get accessor of the form
  GetPrefix + AttributeName
and a set accessor of the form 
  SetPrefix + AttributeName

See import for how to define the prefixes and the attribute names.

This overrides a method in the accessors.pm package, 
and should never need to be called directly.

=cut
sub create_accessors_for {
    my $class   = shift;
    my $callpkg = shift;

    warn( 'creating ' . $class->style . ' accessors( ',
      join(' ',@_)," ) in pkg '$callpkg'" ) if $class->Debug;

    foreach my $property (@_) {
        confess( "can't create accessors in $callpkg - '$property' is not a valid name!" )
            unless $class->isa_valid_name( $property );
        warn "Processing $property" if $class->Debug;
        $class->create_explicit_accessors( $callpkg, $property );
    }

    return $class;
}

=head2 create_explicit_accessors

The routine that actually creates the accessors. The body of a getter looks like:

  my $getter = sub {
    return $_[0]->{$property};
  }

and a setter is defined as:

  my $setter = sub {
    $_[0]->{$property} = $_[1];
    return $_[0]->{$property};
  }

Where $property is defined to be 

  "-" . $attribute_name</code>. 

=cut

sub create_explicit_accessors {
    my ($class, $pkg, $property) = @_;
    my $get_accessor = $pkg . '::' . $class->GetPrefix . $property;
    my $set_accessor = $pkg . '::' . $class->SetPrefix . $property;
    $property = "-$property";
    no strict 'refs';
    warn( "creating " . $class->style . " accessor: $get_accessor\n" ) if
        $class->Debug;
    *{$get_accessor} = sub {
        return $_[0]->{$property};
    };
    warn( "creating " . $class->style . " accessor: $set_accessor\n" ) if
        $class->Debug;
    *{$set_accessor} = sub {
        $_[0]->{$property} = $_[1];
        return $_[0]->{$property};
    }
}


=head1 AUTHOR

Alex Kalderimis, C<< <alex dot kalderimis at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-accessors-rw-explicit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=accessors-rw-explicit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc accessors::rw::explicit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=accessors-rw-explicit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/accessors-rw-explicit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/accessors-rw-explicit>

=item * Search CPAN

L<http://search.cpan.org/dist/accessors-rw-explicit/>

=back


=head1 ACKNOWLEDGEMENTS

Steve Purkis for writing accessors.pm L<http://search.cpan.org/dist/accessors/>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alex Kalderimis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of accessors::rw::explicit
