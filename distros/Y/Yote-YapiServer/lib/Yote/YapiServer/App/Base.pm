package Yote::YapiServer::App::Base;

use strict;
use warnings;
use base 'Yote::YapiServer::BaseObj';

# Database column definitions - subclasses can add more
our %cols = (
    app_name    => 'VARCHAR(64)',
    created     => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    description => 'VARCHAR(64)',
    settings    => '*HASH<64>_Text',
    app_version => 'INTEGER',
);

# Class-level app version. Subclasses override this to
# indicate a new version of their app schema/logic.
our $app_version = 1;

# Method access control - subclasses should override
# Format: method_name => { public => 1, auth => 1, owner_only => 1, admin_only => 1 }
our %METHODS = ();

# Field visibility - subclasses should override
our %FIELD_ACCESS = (
    app_name => { public => 1 },
    created  => { public => 1 },
    settings => { admin_only => 1 },
);

# Public vars exposed on connect - subclasses should override
our %PUBLIC_VARS = ();

#----------------------------------------------------------------------
# App-specific accessor (PUBLIC_VARS is app-only, not in BaseObj)
#----------------------------------------------------------------------

sub public_vars {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    return \%{"${class}::PUBLIC_VARS"};
}

# Returns the class-level app version (from $app_version package variable).
# Subclasses override $app_version to bump their version.
sub version {
    my $class = ref($_[0]) || $_[0];
    no strict 'refs';
    return ${"${class}::app_version"} // 1;
}

#----------------------------------------------------------------------
# Method authorization
#----------------------------------------------------------------------

sub authorize_method {
    my ($self, $method, $session, $user) = @_;

    my $methods = $self->method_defs;
    my $method_def = $methods->{$method};

    return (0, "unknown method: $method") unless $method_def;

    # Public methods - no auth required
    return (1) if $method_def->{public};

    # All other methods require authentication
    return (0, "authentication required") unless $session && $user;

    # Admin-only methods
    if ($method_def->{admin_only}) {
        return (0, "admin access required") unless $user->get_is_admin;
    }

    return (1);
}

#----------------------------------------------------------------------
# Object-level authorization (for methods called on specific objects)
#----------------------------------------------------------------------

sub authorize_object_method {
    my ($self, $target_obj, $method, $session, $user) = @_;

    # First check if object is in session's exposed set
    return (0, "object not accessible") unless $session->can_access($target_obj);

    # Get method definition from the target object's class
    my $methods = $target_obj->method_defs;
    my $method_def = $methods->{$method};

    return (0, "unknown method: $method") unless $method_def;
    return (1) if $method_def->{public};
    return (0, "authentication required") unless $session && $user;

    # Owner-only: object must belong to calling user
    if ($method_def->{owner_only}) {
        if ($target_obj->can('get_owner')) {
            my $owner = $target_obj->get_owner;
            return (0, "owner access required")
                unless $owner && $owner->id eq $user->id;
        } elsif ($target_obj->isa('Yote::YapiServer::User')) {
            # User objects - owner is self
            return (0, "owner access required")
                unless $target_obj->id eq $user->id;
        }
    }

    # Admin-only
    if ($method_def->{admin_only}) {
        return (0, "admin access required") unless $user->get_is_admin;
    }

    return (1);
}


#----------------------------------------------------------------------
# Connection metadata (what client receives on connect)
#----------------------------------------------------------------------

sub connect_info_methods {
    my ($self, $session, $user) = @_;

    my $methods = $self->method_defs;
    my @available_methods;

    for my $method (sort keys %$methods) {
        my $def = $methods->{$method};

        # Include public methods always
        if ($def->{public}) {
            push @available_methods, $method;
            next;
        }

        # Include auth methods if user is logged in
        if ($user && ($def->{auth} || $def->{owner_only})) {
            push @available_methods, $method;
            next;
        }

        # Include admin methods if user is admin
        if ($user && $user->get_is_admin && $def->{admin_only}) {
            push @available_methods, $method;
        }
    }

    return \@available_methods;
}

1;

__END__

=head1 NAME

Yote::YapiServer::App::Base - Base class for Yapi applications

=head1 DESCRIPTION

Provides the foundation for building yapi server-side applications.
Handles method authorization and capability tracking.
Inherits serialization from Yote::YapiServer::BaseObj.

=head1 SUBCLASSING

    package Yote::YapiServer::App::MyApp;
    use base 'Yote::YapiServer::App::Base';

    our %cols = (
        %Yote::YapiServer::App::Base::cols,
        my_field => 'VARCHAR(255)',
    );

    our %METHODS = (
        hello      => { public => 1 },
        getUserData => { auth => 1 },
        adminAction => { admin_only => 1 },
    );

    our %PUBLIC_VARS = (
        appVersion => '1.0',
    );

    sub hello {
        my ($self, $args, $session) = @_;
        return 1, "Hello, " . ($args->{name} // "World") . "!";
    }

=cut
