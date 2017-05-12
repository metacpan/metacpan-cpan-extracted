package ex::override;
# $Id: override.pm,v 1.1 2003/03/14 14:58:53 cwest Exp $
use strict;
use warnings;
use Carp;

use vars qw[$VERSION @ISA];
$VERSION = (qw$Revision: 1.1 $)[1];

@ISA = qw[ex::override::functions];

sub import {
  my $self = shift;

  return unless @_;

  my %functions = @_;

  my $caller  = caller(0);

  foreach ( keys %functions ) {
    if ( s/^GLOBAL_// ) {
      $caller  = 'CORE::GLOBAL';
      $functions{$_} = $functions{'GLOBAL_'.$_};
    }
    unless ( prototype "CORE::$_" ) {
      croak "$_ cannot be overriden because it doesn't have a prototype";
    }
    no strict 'refs';
    *{'ex::override::functions::'.$_} = \&{$functions{$_}};
    *{$caller.'::'.$_} = \&{'ex::override::functions::'.$_};
  }
}

sub unimport {
  my $self = shift;

  my @remove = ( @_ ? @_ : keys %ex::override::functions:: );

  my $caller = caller(0);
  
  foreach ( @remove ) {
    s/^GLOBAL_//;
    delete $CORE::GLOBAL{$_};
    eval 'delete $'.$caller."::{$_}";
  }
}

1;
__END__

=head1 NAME

ex::override - Perl pragma to override core functions

=head1 SYNOPSIS

  use ex::override ucfirst => sub {
                                   # make sure only the first
                                   # letter is uppercased
                                   ucfirst( lc( shift ) );
                                  };

  ucfirst( 'MAKE THIS RIGHT' );
  # Make this right

  no ex::override 'ucfirst';

  ucfirst( 'MAKE THIS RIGHT' );
  # MAKE THIS RIGHT


=head1 DESCRIPTION

"ex::override" is an easy way to override core perl functions.

=head2 Overriding a function

  use ex::override
    length => \&mylength,
    open   => \&myopen;

Overriding a core function happens at compile time.
Arguments are passed to "ex::override" in a name based, or
hash style.  The key is the name of the core function to
override, the value is your subroutine to replace the
core's.

=head2 Using an overriden funtion

Nothing changes on the surface.  If you override "stat",
then you still use "stat" the same way.

B<NOTE:> This is only true if you are keeping the same
prototype as the function you've overriden.  To do this,
you must define your prototype:

  use ex::override values => sub (\%) { values %{+shift} };

If you don't use this same prototype or force yourself to
use the function the same, you can extend the
functionality of a core function:

  # length of all arguments passed to length()
  use ex::override length => sub { length join '', @_ };

=head2 Overriding a function globaly

B<Don't do this without a very good reason!>

"ex::override" allows you the ability to override core
functions globaly.  Any packages that inherit from yours
will use your function override.  There are good reasons
for doing this, if you think you need to, make sure you
have a good reason.

  use ex::override
    GLOBAL_length => sub {
                          # prevent someone from passing a list
                          croak "Don't do that!" if @_ > 1;
                          length shift
                         };

B<NOTE:> If you globaly override a function in a package,
only that package can remove it.

=head2 Removing your override

This works the same way that "no strict" works.

  no ex::override; # remove _all_ overrides

  no ex::override 'values';

  no ex::override 'GLOABL_length';


=head1 TIPS

=over 4

=item Get a list of overrideable function

If you have the Perl source laying around, go to it's
root dir and try this:

  perl -lne 'print /_(\w+)/ if /return -K/' toke.c

You'll have to weed out which ones are functions ( vs.
operators, etc. ).

=item Get a functions prototype

  perl -lwe 'print prototype "CORE::length"'

This prints the prototype, or "Use of uninitialized
variable..." if there isn't one.

=back


=head1 TODO

Find a way to preserve prototypes so the user doesn't have
to know them.


=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>


=head1 COPYRIGHT

Copyright (c) 2000 Casey West <casey@geeknest.com>.  All
rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

