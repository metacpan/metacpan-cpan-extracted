package Test::Mock::Guard;

use strict;
use warnings;

use 5.006001;

use Exporter qw(import);
use Class::Load qw(load_class);
use Scalar::Util qw(blessed refaddr set_prototype);
use List::Util qw(max);
use Carp qw(croak);

our $VERSION = '0.10';
our @EXPORT = qw(mock_guard);

sub mock_guard {
    return Test::Mock::Guard->new(@_);
}

my $stash = {};
sub new {
    my ($class, @args) = @_;
    croak 'must be specified key-value pair' unless @args && @args % 2 == 0;
    my $restore = {};
    my $object  = {};
    while (@args) {
        my ($class_name, $method_defs) = splice @args, 0, 2;
        croak 'Usage: mock_guard($class_or_objct, $methods_hashref)'
            unless defined $class_name && ref $method_defs eq 'HASH';

        # object section
        if (my $klass = blessed $class_name) {
            my $refaddr = refaddr $class_name;
            my $guard = Test::Mock::Guard::Instance->new($class_name, $method_defs);
            $object->{"$klass#$refaddr"} = $guard;
            next;
        }

        # Class::Name section
        load_class $class_name;
        $stash->{$class_name} ||= {};
        $restore->{$class_name} = {};

        for my $method_name (keys %$method_defs) {
            $class->_stash($class_name, $method_name, $restore);
            my $mocked_method = ref $method_defs->{$method_name} eq 'CODE'
                ? $method_defs->{$method_name}
                : sub { $method_defs->{$method_name} };

            my $fully_qualified_method_name = "$class_name\::$method_name";
            my $prototype = prototype($fully_qualified_method_name);

            no strict 'refs';
            no warnings 'redefine';

            *{$fully_qualified_method_name} = set_prototype(sub {
                ++$stash->{$class_name}->{$method_name}->{called_count};
                &$mocked_method;
            }, $prototype);
        }
    }
    return bless { restore => $restore, object => $object } => $class;
}

sub call_count {
    my ($self, $klass, $method_name) = @_;

    if (my $class_name = blessed $klass) {
        # object
        my $refaddr = refaddr $klass;
        my $guard = $self->{object}->{"$class_name#$refaddr"}
            || return undef; ## no critic
        return $guard->call_count($method_name);
    }
    else {
        # class
        my $class_name = $klass;
        return unless exists $stash->{$class_name}->{$method_name};
        return $stash->{$class_name}->{$method_name}->{called_count};
    }
}

sub reset {
    my ($self, @args) = @_;
    croak 'must be specified key-value pair' unless @args && @args % 2 == 0;
    while (@args) {
        my ($class_name, $methods) = splice @args, 0, 2;
        croak 'Usage: $guard->reset($class_or_objct, $methods_arrayref)'
            unless defined $class_name && ref $methods eq 'ARRAY';
        for my $method (@$methods) {
            if (my $klass = blessed $class_name) {
                my $refaddr = refaddr $class_name;
                my $restore = $self->{object}{"$klass#$refaddr"} || next;
                $restore->reset($method);
                next;
            }
            $self->_restore($class_name, $method);
        }
    }
}

sub _stash {
    my ($class, $class_name, $method_name, $restore) = @_;
    $stash->{$class_name}{$method_name} ||= {
        counter      => 0,
        restore      => {},
        delete_flags => {},
        called_count => 0,
    };
    my $index = ++$stash->{$class_name}{$method_name}{counter};
    $stash->{$class_name}{$method_name}{restore}{$index} = $class_name->can($method_name);
    $restore->{$class_name}{$method_name} = $index;
}

sub _restore {
    my ($self, $class_name, $method_name) = @_;

    my $index = delete $self->{restore}{$class_name}{$method_name} || return;
    my $stuff = $stash->{$class_name}{$method_name};
    if ($index < (max(keys %{$stuff->{restore}}) || 0)) {
        $stuff->{delete_flags}{$index} = 1; # fix: destraction problem
    }
    else {
        my $orig_method = delete $stuff->{restore}{$index}; # current restore method

        # restored old mocked method
        for my $index (sort { $b <=> $a } keys %{$stuff->{delete_flags}}) {
            delete $stuff->{delete_flags}{$index};
            $orig_method = delete $stuff->{restore}{$index};
        }

        # cleanup
        unless (keys %{$stuff->{restore}}) {
            delete $stash->{$class_name}{$method_name};
        }

        no strict 'refs';
        no warnings qw(redefine prototype);
        *{"$class_name\::$method_name"} = $orig_method
            || *{"$class_name\::$method_name is unregistered"}; # black magic!
    }
}

sub DESTROY {
    my $self = shift;
    while (my ($class_name, $method_defs) = each %{$self->{restore}}) {
        for my $method_name (keys %$method_defs) {
            $self->_restore($class_name, $method_name);
        }
    }
}

# taken from cho45's code
package
    Test::Mock::Guard::Instance;

use Scalar::Util qw(blessed refaddr);

my $mocked = {};
sub new {
    my ($class, $object, $methods) = @_;
    my $klass   = blessed($object);
    my $refaddr = refaddr($object);

    my $methods_map = {};
    $mocked->{$klass}->{_mocked} ||= {};
    for my $method (keys %$methods) {
        $methods_map->{$method} = {
            method       => $methods->{$method},
            called_count => 0,
        };
        unless ($mocked->{$klass}->{_mocked}->{$method}) {
            my $original_method = $klass->can($method);
            $mocked->{$klass}->{_mocked}->{$method} = $original_method;
            no strict 'refs';
            no warnings qw(redefine prototype);
            *{"$klass\::$method"} = sub { _mocked($method, $original_method, @_) };
        }
    }

    $mocked->{$klass}->{$refaddr} = $methods_map;
    bless { object => $object }, $class;
}

sub reset {
    my ($self, $method) = @_;
    my $object  = $self->{object};
    my $klass   = blessed($object);
    my $refaddr = refaddr($object);

    if (exists $mocked->{$klass}{$refaddr} && exists $mocked->{$klass}{$refaddr}{$method}) {
        delete $mocked->{$klass}{$refaddr}{$method};
    }
}

sub call_count {
    my ($self, $method_name) = @_;
    my $klass   = blessed $self->{object};
    my $refaddr = refaddr $self->{object};
    return unless exists $mocked->{$klass}{$refaddr}{$method_name}{called_count};
    return $mocked->{$klass}{$refaddr}{$method_name}{called_count};
}

sub _mocked {
    my ($method, $original, $object, @rest) = @_;
    my $klass   = blessed($object);
    my $refaddr = refaddr($object);
    if ($klass && $refaddr && exists $mocked->{$klass}->{$refaddr} && exists $mocked->{$klass}->{$refaddr}->{$method}) {
        ++$mocked->{$klass}->{$refaddr}->{$method}->{called_count};
        my $val = $mocked->{$klass}->{$refaddr}->{$method}->{method};
        ref($val) eq 'CODE' ? $val->($object, @rest) : $val;
    } else {
        $original->($object, @rest);
    }
}

sub DESTROY {
    my ($self) = @_;
    my $object  = $self->{object};
    my $klass   = blessed($object);
    my $refaddr = refaddr($object);
    delete $mocked->{$klass}->{$refaddr};

    unless (keys %{ $mocked->{$klass} } == 1) {
        my $mocked = delete $mocked->{$klass}->{_mocked};
        for my $method (keys %$mocked) {
            no strict 'refs';
            no warnings qw(redefine prototype);
            *{"$klass\::$method"} = $mocked->{$method};
        }
    }
}

1;

__END__

=head1 NAME

Test::Mock::Guard - Simple mock test library using RAII.

=head1 SYNOPSIS

  use Test::More;
  use Test::Mock::Guard qw(mock_guard);

  package Some::Class;

  sub new { bless {} => shift }
  sub foo { "foo" }
  sub bar { 1; }

  package main;

  {
      my $guard = mock_guard( 'Some::Class', { foo => sub { "bar" }, bar => 10 } );
      my $obj = Some::Class->new;
      is( $obj->foo, "bar" );
      is( $obj->bar, 10 );
  }

  my $obj = Some::Class->new;
  is( $obj->foo, "foo" );
  is( $obj->bar, 1 );

  done_testing;

=head1 DESCRIPTION

Test::Mock::Guard is mock test library using RAII.
This module is able to change method behavior by each scope. See SYNOPSIS's sample code.

=head1 EXPORT FUNCTION

=head2 mock_guard( @class_defs )

@class_defs have the following format.

=over

=item key

Class name or object to mock.

=item value

Hash reference. Keys are method names; values are code references or scalars.
If the value is code reference, it is used as a method.
If the value is a scalar, the method will return the specified value.

=back

You can mock instance methods as well as class methods (this feature was provided by cho45):

  use Test::More;
  use Test::Mock::Guard qw(mock_guard);

  package Some::Class;

  sub new { bless {} => shift }
  sub foo { "foo" }

  package main;

  my $obj1 = Some::Class->new;
  my $obj2 = Some::Class->new;

  {
      my $obj2 = Some::Class->new;
      my $guard = mock_guard( $obj2, { foo => sub { "bar" } } );
      is ($obj1->foo, "foo", "obj1 has not changed" );
      is( $obj2->foo, "bar", "obj2 is mocked" );
  }

  is( $obj1->foo, "foo", "obj1" );
  is( $obj2->foo, "foo", "obj2" );

  done_testing;

=head1 METHODS

=head2 new( @class_defs )

See L</mock_guard> definition.

=head2 call_count( $class_name_or_object, $method_name )

Returns a number of calling of $method_name in $class_name_or_object.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

Yuji Shimada E<lt>xaicron at cpan.orgE<gt>

Masaki Nakagawa E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

L<Test::MockObject>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
