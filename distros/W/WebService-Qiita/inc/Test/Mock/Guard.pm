#line 1
package Test::Mock::Guard;

use strict;
use warnings;

use 5.006001;

use Exporter qw(import);
use Class::Load qw(load_class);
use Scalar::Util qw(blessed refaddr set_prototype);
use List::Util qw(max);
use Carp qw(croak);

our $VERSION = '0.09';
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
            $mocked->{$klass}->{_mocked}->{$method} = $klass->can($method);
            no strict 'refs';
            no warnings qw(redefine prototype);
            *{"$klass\::$method"} = sub { _mocked($method, @_) };
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
    my ($method, $object, @rest) = @_;
    my $klass   = blessed($object);
    my $refaddr = refaddr($object);
    if (exists $mocked->{$klass}->{$refaddr} && exists $mocked->{$klass}->{$refaddr}->{$method}) {
        ++$mocked->{$klass}->{$refaddr}->{$method}->{called_count};
        my $val = $mocked->{$klass}->{$refaddr}->{$method}->{method};
        ref($val) eq 'CODE' ? $val->($object, @rest) : $val;
    } else {
        $mocked->{$klass}->{_mocked}->{$method}->($object, @rest);
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

#line 351
