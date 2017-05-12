package SAPNW::RFC::FunctionDescriptor;
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
    my @parms = @_;
    my $type = ref($self) || die "cannot autoload in FunctionDescriptor with $self -> $AUTOLOAD\n";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

#   Autoload parameters and tables
    if ( exists $self->{parameters}->{$name} ) {
        return $self->{parameters}->{$name};
    } else {
            #debug(Dumper($self));
        die "Parameter $name does not exist in Interface Descriptor - no autoload";
    };
  }

    sub DESTROY {
        my $self = shift;
        return SAPNW::Connection::destroy_function_descriptor($self);
    }

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
        my ($name) = @_;
        return SAPNW::Connection::create_function_descriptor($name);
    }

    sub name {
      my $self = shift;
        return $self->{name};
    }


    # internal method used to add parameters from within the C extension
  sub addParameter {
    my $self = shift;
    my ($name, $direction, $type, $len, $ulen, $decimals) = @_;
    #debug("parm: $name direction: $direction type: $type len: $len decimals: $decimals\n");
    if (ref($name) eq "SAPNW::RFC::Export" ||
        ref($name) eq "SAPNW::RFC::Import" ||
        ref($name) eq "SAPNW::RFC::Changing" ||
        ref($name) eq "SAPNW::RFC::Table") {
        my $k = $name->name;
        
        # XXX temporary hack to fix Imports that dont work - make then changing
        if (ref($name) eq "SAPNW::RFC::Import") {
            $name->{direction} = RFCCHANGING;
            bless $name, "SAPNW::RFC::Changing";
        }
        $self->{parameters}->{$k} = SAPNW::Connection::add_parameter($self, $name);
        return $self->{parameters}->{$k};
    }
    my $p;
    if ($direction == RFCIMPORT) {
          if (exists $self->{parameters}->{$name} && $self->{parameters}->{$name}->direction == RFCEXPORT) {
              $p = SAPNW::RFC::Changing->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
            } else {
              $p = SAPNW::RFC::Import->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
            }
      } elsif ($direction == RFCEXPORT) {
          if (exists $self->{parameters}->{$name} && $self->{parameters}->{$name}->direction == RFCIMPORT) {
              $p = SAPNW::RFC::Changing->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
            } else {
              $p = SAPNW::RFC::Export->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
            }
      } elsif ($direction == RFCCHANGING) {
              $p = SAPNW::RFC::Changing->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
      } elsif ($direction == RFCTABLES) {
              $p = SAPNW::RFC::Table->new(name => $name, type => $type, len => $len, ulen => $ulen, decimals => $decimals);
      } else {
          die "unknown direction ($name): $direction\n";
      }
    $self->{parameters}->{$p->name} = $p;
        return $p;
  }


    sub parameters {
      my $self = shift;
        return $self->{parameters};
    }


    sub callback {
      my $self = shift;
        $self->{'callback'} = shift if scalar @_ == 1;
      return $self->{'callback'};
    }

    sub make_empty_function_call {
      my $self = shift;
        return SAPNW::RFC::FunctionCall->new($self);
    }


    sub create_function_call {
      my $self = shift;
    #debug("create_function_call: ".Dumper($self));
        return SAPNW::Connection::create_function_call($self);
    }


1;
