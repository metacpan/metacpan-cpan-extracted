package Valiant::Util::Ancestors;

use Moo::Role;

my %injected_role = ();
my $inject_role_if_needed = sub {
  my $class = shift;
  return if $injected_role{$class};
  if(Role::Tiny->is_role($class)) {

    eval qq[
      package ${class}; 
      sub does_roles { shift->maybe::next::method(\@_) }
    ];

    my $around = \&{"${class}::around"};
    $around->(does_roles => sub {
      my ($orig, $self) = @_;
      return ($self->$orig, $class);
    });

    $injected_role{$class} = 1;
  }
};

sub ancestors {
  my $class = shift;
  $class = ref($class) if ref($class);
  $class->$inject_role_if_needed;

  no strict "refs";
  my @ancestors = ();

  push @ancestors, grep {
    Role::Tiny::does_role($_, __PACKAGE__);
  } @{"${class}::ISA"};

  push @ancestors, $class->does_roles
    if $class->can('does_roles');

  return @ancestors;
}

1;

=head1 NAME

Valiant::Util::Ancestors - Detect 'ancestors' of the class (via Roles or Inheritance) 

=head1 SYNOPSIS

    package Example::Object

    use Moo;

    with 'MooX::MetaDescription::Ancestors';

    1;


=head1 DESCRIPTION

This really isn't intended for direct consumption.  Basically it exists because there's not
official way in L<Moo> to get a list of the roles which have been applied to a given class.
Since I need to know this in order to lookup and aggregate meta descriptions from any roles
that have been applied, this is the best hack I could come up with.  It's ugly.  Suggestions
welcomed (or convince MST we need an offical way to get all the applied roles to a L<Moo>
class).

Yes I could translate this whole thing to L<Moose> I suppose and then I could get a real MOP.
Maybe I should do that.  Conversation welcomed.

=head1 METHODS

This component adds the following methods to your result classes.

=head2 ancestors

This returns an array of all the roles and your C<@ISA> list.  There is no promise in the
order given.  You get the C<@ISA> list and the roles are tacked onto the end.  Don't use
this for anything where you care about the order of application of the roles.  Also, this
might change at some point.  I really have no specific need for ordering at this point to
be anything in particular but that could change.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
