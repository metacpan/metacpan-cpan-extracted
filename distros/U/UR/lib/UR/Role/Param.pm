package UR::Role::Param;

use strict;
use warnings;

use Carp qw();
use Scalar::Util qw(blessed);

our $VERSION = "0.47"; # UR $VERSION;

my %all_params;

sub _constructor {
    my($class, %params) = @_;
    foreach my $param_name ( qw( role_name name varref state ) ) {
        Carp::croak("$param_name is a required param") unless exists $params{$param_name};
    }
    $all_params{$params{role_name}}->{$params{name}} = bless \%params, $class;
}

sub new {
    my $class = shift;
    return $class->_constructor(@_, state => 'unbound');
}
    
sub TIESCALAR {
    my $class = shift;
    return $class->_constructor(@_, state => 'bound');
}

sub name { shift->{name} }
sub role_name { shift->{role_name} }
sub varref { shift->{varref} }
sub state { shift->{state} }

sub FETCH {
    my $self = shift;
    my $param_name = $self->name;

    my $role_instance = $self->_search_for_invocant_role_instance();
    unless ($role_instance) {
        Carp::confess("Role param '$param_name' is not bound to a value in this call frame");
    }
    my $params = $role_instance->role_params();
    return $params->{$param_name};
}

sub STORE {
    my $self = shift;
    my $name = $self->name;
    Carp::croak("Role param '$name' is read-only");
}

sub _search_for_invocant_role_instance {
    my $self = shift;

    local $@;
    for (my $frame = 1; ; $frame++) {
        my($role_package, $invocant) = do {
            package DB;
            my @caller = caller($frame);
            last unless $caller[3];
            my($function_package) = $caller[3] =~ m/^(.*)::\w+$/;
            next unless $function_package;
            eval { ($function_package, $DB::args[0]) };
        };
        my $invocant_class = blessed($invocant) || (!ref($invocant) && $invocant);
        next unless $invocant_class;

        my $role_instance = UR::Role::Instance->get(role_name => $role_package, 'class_name isa' => $invocant_class);
        return $role_instance if $role_instance;
    }
    return;
}

sub clone_self {
    # used by Clone:PP (UR::Util::deep_copy), to prevent recursing into
    # these Param objects.  Otherwise, the cloning done when a Role's
    # property data is cloned before merging it into the class would point
    # this object's varref to an anonymous scalar other than the original
    # variable with The RoleParam attribute, and the cloning process doesn't
    # properly re-tie the RoleParam variables afterward.
    return $_[0];
}

sub param_names_for_role {
    my($class, $role_name) = @_;
    return keys(%{ $all_params{$role_name} });
}

sub replace_unbound_params_in_struct_with_values {
    my($class, $struct, @role_objects) = @_;

    my %role_params = map { $_->role_name => $_->role_params } @role_objects;

    my $replacer = sub {
        my $ref = shift;

        my $self = $$ref;
        my $role_params = $role_params{$self->role_name};
        $$ref = $role_params->{$self->name};  # replaces value in structure

        # replace the role param variable
        my $role_param_ref = $self->varref;
        unless (tied($$role_param_ref)) {
            tie $$role_param_ref, 'UR::Role::Param',
                name => $self->name,
                role_name => $self->role_name,
                varref => $self->varref;
        }
    };

    _visit_params_with_values_in_struct($struct, $replacer);
}

sub _is_unbound_param {
    my $val = shift;
    return (blessed($val) && $val->isa(__PACKAGE__) && $val->state eq 'unbound');
}

sub _visit_params_with_values_in_struct {
    my($struct, $cb) = @_;

    return unless my $reftype = ref($struct);
    if ($reftype eq 'HASH') {
                while(my($key, $val) = each %$struct) {
            if (_is_unbound_param($val)) {
                $cb->(\$struct->{$key});
            } else {
                _visit_params_with_values_in_struct($val, $cb);
            }
        }
    } elsif ($reftype eq 'ARRAY') {
        for(my $i = 0; $i < @$struct; $i++) {
            my $val = $struct->[$i];
            if (_is_unbound_param($val)) {
                $cb->(\$struct->[$i]);
            } else {
                _visit_params_with_values_in_struct($val, $cb);
            }
        }
    } elsif ($reftype eq 'SCALAR') {
        _visit_params_with_values_in_struct($struct, $cb);
    }
}

1;

=pod

=head1 NAME

UR::Role::Param - Role parameters as package variables

=head1 SYNOPSIS

  package ProjectNamespace::LoggingRole;
  use ProjectNamespace;

  our $logging_object : RoleParam(logging_obejct);
  role ProjectNamespace::SomeParameterizedRole { };

  sub log {
      my($self, $message) = @_;
      $logging_object->log($message);
  }

  package ThingThatLogs;
  my $logger = create_a_logging_object();
  class ThingThatLogs {
      roles => [ ProjectNamespace::SomeParameterizedRole->create(logging_object => $logger) ],
  };

=head1 DESCRIPTION

Roles can be configured by declaring variables with the C<RoleParam> attribute.
These variables acquire values by calling C<create()> on the role's name and
giving values for all the role's parameters.  More information about declaring
and using these parameters is described in the "Parameterized Roles" section of
L<UR::Role>.

When the variables are initially declared, their value is initialized to a
reference to a UR::Role::Param.  This represents a placeholder value to be
filled in later.  The value may be used in a role definition or in any
subroutine.

When the role is composed into a class, the placeholder values are replaced
with the actual values given in the C<create()> call on the role's name.  The
original RoleParam variable is then tied to the UR::Role::Param class; it's
C<FETCH> method returns the proper value by searching the call stack for the
first method whose invocant class has composed the role where the FETCH
originated from.  It returns the value given when the role was composed
into the class.

These role param variables are read-only.

Each variable with the RoleParam attribute becomes a required argument when
the role is instantiated .

=head1 SEE ALSO

L<UR::Role>, L<UR::Role::Prototype>, L<UR::Role::Instance>
