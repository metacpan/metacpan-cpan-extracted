package SAPNW::RFC::FunctionCall;
=pod

    Copyright (c) 2006 - 2010 Piers Harding.
    All rights reserved.

=cut
use strict;

use SAPNW::Base;
use base qw(SAPNW::Base);

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.37';


  sub AUTOLOAD {

    my $self = shift;
    my $type = ref($self)
            or die "$self is not an Object in autoload of Iface";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

#   Autoload parameters and tables
    if ( exists $self->{parameters}->{$name} ) {
        if (ref($self->{parameters}->{$name}) =~ /SAPNW::RFC::/) {
            return $self->{parameters}->{$name}->value(@_);
        }
        else {
            if (scalar(@_)) {
                return $self->{parameters}->{$name} = shift(@_);
            }
            else {
                return $self->{parameters}->{$name};
            }
        }
    } else {
        die "Parameter $name does not exist in Interface - no autoload";
    };
  }

sub DESTROY {
    my $self = shift;
    return SAPNW::Connection::destroy_function_call($self);
}


    sub name {
      my $self = shift;
        return $self->{name};
    }


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $funcdesc = shift;
    die "Must pass a FunctionDescriptor \n" unless ref($funcdesc) eq "SAPNW::RFC::FunctionDescriptor";
    my $self = {
        name => $funcdesc->name,
        parameters => {},
        handle => undef
    };
    foreach my $p (values %{$funcdesc->parameters}) {
        my $type = ref($p);
        no strict 'refs';
        # my ($funcdesc, $name, $type, $len, $ulen, $decimals, $direction) = @_;
        my $np = &{$type."::new"}($type, 'name', $p->name, 'type', $p->type, 'len', $p->len, 'ulen', $p->ulen, 'decimals', $p->decimals, 'direction', $p->direction);
        $self->{parameters}->{$np->name} = $np;
    }
    bless($self, $class);
    return $self;
}


  sub initialise {
        my $self = shift;
        my $funcdesc = shift;
        $self->{parameters} = {};
        foreach my $p (values %{$funcdesc->parameters}) {
            my $type = ref($p);
            no strict 'refs';
            # my ($funcdesc, $name, $type, $len, $ulen, $decimals, $direction) = @_;
            my $np = &{$type."::new"}($type, 'name', $p->name, 'type', $p->type, 'len', $p->len, 'ulen', $p->ulen, 'decimals', $p->decimals, 'direction', $p->direction);
            $self->{parameters}->{$np->name} = $np;
        }
        return $self;
  }

    sub parameters {
      my $self = shift;
        return $self->{parameters};
    }

    sub parameter {
      my $self = shift;
        my $parameter = shift;
        return exists $self->{parameters}->{$parameter} ? $self->{parameters}->{$parameter} : undef;
    }

    sub invoke {
      my $self = shift;
        return SAPNW::Connection::invoke($self);
  }


1;
