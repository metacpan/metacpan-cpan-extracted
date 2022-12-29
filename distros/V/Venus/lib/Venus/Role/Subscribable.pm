package Venus::Role::Subscribable;

use 5.018;

use strict;
use warnings;

use Venus::Role 'with';

# METHODS

sub name {
  my ($name) = @_;

  $name = lc $name =~ s/\W+/_/gr if $name;

  return $name;
}

sub publish {
  my ($self, $name, @args) = @_;

  $name = name($name) or return $self;

  &$_(@args) for @{subscriptions($self)->{$name}};

  return $self;
}

sub subscribe {
  my ($self, $name, $code) = @_;

  $name = name($name) or return $self;

  push @{subscriptions($self)->{$name}}, $code;

  return $self;
}

sub subscribers {
  my ($self, $name) = @_;

  $name = name($name) or return 0;

  if (exists subscriptions($self)->{$name}) {
    return 0+@{subscriptions($self)->{$name}};
  }
  else {
    return 0;
  }
}

sub subscriptions {
  my ($self) = @_;

  return $self->{'$subscriptions'} ||= {};
}

sub unsubscribe {
  my ($self, $name, $code) = @_;

  $name = name($name) or return $self;

  if ($code) {
    subscriptions($self)->{$name} = [
      grep { $code ne $_ } @{subscriptions($self)->{$name}}
    ];
  }
  else {
    delete subscriptions($self)->{$name};
  }

  delete subscriptions($self)->{$name} if !$self->subscribers($name);

  return $self;
}

# EXPORTS

sub EXPORT {
  ['publish', 'subscribe', 'subscribers', 'unsubscribe']
}

1;



=head1 NAME

Venus::Role::Subscribable - Subscribable Role

=cut

=head1 ABSTRACT

Subscribable Role for Perl 5

=cut

=head1 SYNOPSIS

  package Example;

  use Venus::Class;

  with 'Venus::Role::Subscribable';

  sub execute {
    $_[0]->publish('on.execute');
  }

  package main;

  my $example = Example->new;

  # $example->subscribe('on.execute', sub{...});

  # bless(..., 'Example')

  # $example->publish('on.execute');

  # bless(..., 'Example')

=cut

=head1 DESCRIPTION

This package provides a mechanism for publishing and subscribing to events.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 publish

  publish(Str $name, Any @args) (Self)

The publish method notifies all subscribers for a given event and returns the
invocant.

I<Since C<1.75>>

=over 4

=item publish example 1

  # given: synopsis

  package main;

  $example = $example->publish;

  # bless(..., 'Example')

=back

=over 4

=item publish example 2

  # given: synopsis

  package main;

  $example = $example->publish('on.execute');

  # bless(..., 'Example')

=back

=over 4

=item publish example 3

  # given: synopsis

  package main;

  $example->subscribe('on.execute', sub {$example->{emitted} = [@_]});

  $example = $example->publish('on.execute');

  # bless(..., 'Example')

=back

=over 4

=item publish example 4

  # given: synopsis

  package main;

  $example->subscribe('on.execute', sub {$example->{emitted} = [@_]});

  $example = $example->publish('on.execute', [1..4]);

  # bless(..., 'Example')

=back

=cut

=head2 subscribe

  subscribe(Str $name, CodeRef $code) (Self)

The subscribe method registers a subscribers (i.e. callbacks) for a given event,
and returns the invocant.

I<Since C<1.75>>

=over 4

=item subscribe example 1

  # given: synopsis

  package main;

  $example = $example->subscribe('on.execute', sub {$example->{emitted} = [@_]});

  # bless(..., 'Example')

=back

=over 4

=item subscribe example 2

  # given: synopsis

  package main;

  $example = $example->subscribe('on.execute', sub {$example->{emitted_1} = [@_]});

  # bless(..., 'Example')

  $example = $example->subscribe('on.execute', sub {$example->{emitted_2} = [@_]});

  # bless(..., 'Example')

  $example = $example->subscribe('on.execute', sub {$example->{emitted_3} = [@_]});

  # bless(..., 'Example')

  # $example->publish('on.execute');

  # bless(..., 'Example')

=back

=cut

=head2 subscribers

  subscribers(Str $name) (Int)

The subscribers method returns the number of subscribers (i.e. callbacks) for a
given event.

I<Since C<1.75>>

=over 4

=item subscribers example 1

  # given: synopsis

  package main;

  $example = $example->subscribers;

  # 0

=back

=over 4

=item subscribers example 2

  # given: synopsis

  package main;

  $example = $example->subscribers('on.execute');

  # 0

=back

=over 4

=item subscribers example 3

  # given: synopsis

  package main;

  $example = $example->subscribe('on.execute', sub {$example->{emitted_1} = [@_]});

  $example = $example->subscribe('on.execute', sub {$example->{emitted_2} = [@_]});

  $example = $example->subscribe('on.execute', sub {$example->{emitted_3} = [@_]});

  $example = $example->subscribers('on.execute');

  # 3

=back

=cut

=head2 unsubscribe

  unsubscribe(Str $name, CodeRef $code) (Self)

The unsubscribe method deregisters all subscribers (i.e. callbacks) for a given
event, or a specific callback if provided, and returns the invocant.

I<Since C<1.75>>

=over 4

=item unsubscribe example 1

  # given: synopsis

  package main;

  $example = $example->unsubscribe;

  # bless(..., 'Example')

=back

=over 4

=item unsubscribe example 2

  # given: synopsis

  package main;

  $example = $example->unsubscribe('on.execute');

  # bless(..., 'Example')

=back

=over 4

=item unsubscribe example 3

  # given: synopsis

  package main;

  $example = $example->subscribe('on.execute', sub {$example->{emitted_1} = [@_]});

  $example = $example->subscribe('on.execute', sub {$example->{emitted_2} = [@_]});

  $example = $example->subscribe('on.execute', sub {$example->{emitted_3} = [@_]});

  $example = $example->unsubscribe('on.execute');

  # bless(..., 'Example')

=back

=over 4

=item unsubscribe example 4

  # given: synopsis

  package main;

  my $execute = sub {$example->{execute} = [@_]};

  $example = $example->subscribe('on.execute', $execute);

  $example = $example->unsubscribe('on.execute', $execute);

  # bless(..., 'Example')

=back

=cut