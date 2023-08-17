use strict;
use warnings;
package MooseX::SetOnce 0.203;
# ABSTRACT: write-once, read-many attributes for Moose

#pod =head1 SYNOPSIS
#pod
#pod Add the "SetOnce" trait to attributes:
#pod
#pod   package Class;
#pod   use Moose;
#pod   use MooseX::SetOnce;
#pod
#pod   has some_attr => (
#pod     is     => 'rw',
#pod     traits => [ qw(SetOnce) ],
#pod   );
#pod
#pod ...and then you can only set them once:
#pod
#pod   my $object = Class->new;
#pod
#pod   $object->some_attr(10);  # works fine
#pod   $object->some_attr(20);  # throws an exception: it's already set!
#pod
#pod =head1 DESCRIPTION
#pod
#pod The 'SetOnce' attribute lets your class have attributes that are not lazy and
#pod not set, but that cannot be altered once set.
#pod
#pod The logic is very simple:  if you try to alter the value of an attribute with
#pod the SetOnce trait, either by accessor or writer, and the attribute has a value,
#pod it will throw an exception.
#pod
#pod If the attribute has a clearer, you may clear the attribute and set it again.
#pod
#pod =cut

package MooseX::SetOnce::Attribute 0.203;
use Moose::Role 0.90;

before set_value => sub { $_[0]->_ensure_unset($_[1]) };

around _inline_set_value => sub {
  my $orig = shift;
  my $self = shift;
  my ($instance) = @_;

  my @source = $self->$orig(@_);

  return (
    'Class::MOP::class_of(' . $instance . ')->find_attribute_by_name(',
      '\'' . quotemeta($self->name) . '\'',
    ')->_ensure_unset(' . $instance . ');',
    @source,
  );
} if $Moose::VERSION >= 1.9900;

sub _ensure_unset {
  my ($self, $instance) = @_;
  Carp::confess("cannot change value of SetOnce attribute " . $self->name)
    if $self->has_value($instance);
}

around accessor_metaclass => sub {
  my ($orig, $self, @rest) = @_;

  return Moose::Meta::Class->create_anon_class(
    superclasses => [ $self->$orig(@_) ],
    roles => [ 'MooseX::SetOnce::Accessor' ],
    cache => 1
  )->name
} if $Moose::VERSION < 1.9900;

package MooseX::SetOnce::Accessor 0.203;
use Moose::Role 0.90;

around _inline_store => sub {
  my ($orig, $self, $instance, $value) = @_;

  my $code = $self->$orig($instance, $value);
  $code = sprintf qq[%s->meta->find_attribute_by_name("%s")->_ensure_unset(%s);\n%s],
    $instance,
    quotemeta($self->associated_attribute->name),
    $instance,
    $code;

  return $code;
};

package Moose::Meta::Attribute::Custom::Trait::SetOnce 0.203;
sub register_implementation { 'MooseX::SetOnce::Attribute' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SetOnce - write-once, read-many attributes for Moose

=head1 VERSION

version 0.203

=head1 SYNOPSIS

Add the "SetOnce" trait to attributes:

  package Class;
  use Moose;
  use MooseX::SetOnce;

  has some_attr => (
    is     => 'rw',
    traits => [ qw(SetOnce) ],
  );

...and then you can only set them once:

  my $object = Class->new;

  $object->some_attr(10);  # works fine
  $object->some_attr(20);  # throws an exception: it's already set!

=head1 DESCRIPTION

The 'SetOnce' attribute lets your class have attributes that are not lazy and
not set, but that cannot be altered once set.

The logic is very simple:  if you try to alter the value of an attribute with
the SetOnce trait, either by accessor or writer, and the attribute has a value,
it will throw an exception.

If the attribute has a clearer, you may clear the attribute and set it again.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Jesse Luehrs Karen Etheridge Kent Fredric Ricardo Signes

=over 4

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
