package Zabbix::API::Macro;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Zabbix::API::CRUDE/;

use Scalar::Util qw/reftype/;
use Zabbix::API::Host;

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        if ($self->globalp) {

            $self->data->{globalmacroid} = $value;

            delete $self->data->{hostmacroid};

            return $self->data->{globalmacroid};

        } else {

            $self->data->{hostmacroid} = $value;

            delete $self->data->{globalmacroid};

            return $self->data->{hostmacroid};

        }

    } else {

        if ($self->globalp) {

            return $self->data->{globalmacroid};

        } else {

            return $self->data->{hostmacroid};

        }

    }

}

sub prefix {

    my ($self, $suffix) = @_;

    if ($suffix) {

        if ($suffix =~ m/ids?/) {

            return ($self->globalp?'globalmacro':'hostmacro').$suffix;

        } elsif ($suffix eq '.delete') {

            return 'usermacro.'.($self->globalp?'deleteGlobal':'deleteHostMacro');

        }

        return 'usermacro'.$suffix;

    } else {

        return 'usermacro';

    }

}

sub extension {

    return ( output => 'extend',
             select_hosts => 'shorten' );

}

sub collides {

    my $self = shift;

    if ($self->globalp) {

        return @{$self->{root}->query(method => $self->prefix('.get'),
                                      params => { filter => { macro => $self->data->{macro},
                                                              globalmacro => 1 } })};

    } else {

        return @{$self->{root}->query(method => $self->prefix('.get'),
                                      params => { filter => { macro => $self->data->{macro} },
                                                  hostids => [ $self->host->id ] })};
    }

}

sub name {

    my $self = shift;
    return $self->data->{macro};

}

sub globalp {

    my $self = shift;

    return (!defined $self->host);

}

sub host {

    ## mutator for host

    my ($self, $value) = @_;

    if (defined $value) {

        my $type = reftype $value;

        if (eval { $value->isa('Zabbix::API::Host') }) {

            if ($value->created) {

                $value->pull;

            } else {

                $value->push;

            }

        } elsif (defined $type and $type eq 'HASH') {

            $value = $self->{root}->fetch('Host', params => { filter => { hostid => $value->{hostid} } })->[0];

        } else {

            croak 'Type mismatch: Expected hashref or Zabbix::API::Host instance';

        }

        $self->data->{hosts} = [ $value ];
        return $self->data->{hosts}[0];

    } else {

        return $self->data->{hosts}[0];

    }

}

sub pull {

    # override CRUDE's pull()

    my ($self, $data) = @_;

    if (defined $data) {

        $self->{data} = $data;

    } else {

        # this happens to work because usermacro.get works for both types of
        # macros...
        $self->SUPER::pull;

        $self->host($self->data->{hosts}->[0]);

    }

    return $self;

}

sub push {

    my ($self, $data) = @_;

    $data //= $self->data;

    my $method;
    my $parameters;

    my @colliders;

    if ($self->id
        and $self->created) {

        say sprintf('Updating %s %s', $self->prefix, $self->id)
            if $self->{root}->{verbosity};

        if ($self->globalp) {

            $method = '.updateGlobal';

            $parameters = { macro => $self->data->{macro},
                            value => $self->data->{value} };

        } else {

            $method = '.massUpdate';

            $parameters = { macros => [
                                { macro => $self->data->{macro},
                                  value => $self->data->{value} }
                                ],
                            hosts => [ { hostid => $self->host->id } ]};

        }

        $self->{root}->query(method => $self->prefix($method),
                             params => $parameters);

        $self->pull;

    } elsif ($self->id) {

        croak sprintf('%s has a %s but does not exist on server', $self->id, $self->prefix('id'));

    } elsif (@colliders = $self->collides and $colliders[0]) {

        say sprintf('Updating %s (match by collisions)', $self->prefix)
            if $self->{root}->{verbosity};

        if (@colliders > 1) {

            croak sprintf('Cannot push %s: too many possible targets', $self->prefix);

        }

        my $class = ref $self;

        # not referenced! and that's the way we want it
        my $collider = $class->new(root => $self->{root}, data => $colliders[0]);
        $collider->host($self->data->{hosts}->[0]);

        $self->id($collider->id);

        $self->host->push if $self->host;

        if ($self->globalp) {

            $method = '.updateGlobal';

            $parameters = { macro => $self->data->{macro},
                            value => $self->data->{value} };

        } else {

            $method = '.massUpdate';

            $parameters = { macros => [
                                { macro => $self->data->{macro},
                                  value => $self->data->{value} }
                                ],
                            hosts => [ { hostid => $self->host->id } ] };

        }

        $self->{root}->query(method => $self->prefix($method),
                             params => $parameters);

        $self->pull;

    } else {

        say 'Creating '.$self->prefix
            if $self->{root}->{verbosity};

        if ($self->globalp) {

            $method = '.createGlobal';

            $parameters = { macro => $self->data->{macro},
                            value => $self->data->{value} };

        } else {

            $method = '.massAdd';

            $parameters = { macros => [
                                { macro => $self->data->{macro},
                                  value => $self->data->{value} }
                                ],
                            hosts => [ { hostid => $self->host->id } ] };

        }

        my $id = $self->{root}->query(method => $self->prefix($method),
                                      params => $parameters)->{$self->prefix('ids')}->[0];

        $self->id($id);

        $self->pull;

    }

    return $self;

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Macro -- Zabbix usermacro objects

=head1 SYNOPSIS

  use Zabbix::API::Macro;

  # TODO write the rest

=head1 DESCRIPTION

Handles CRUD for Zabbix usermacro objects.

Both global and host macro types are represented by this class.  If the C<hosts>
arrayref attribute is undef or empty, then we assume it's a global macro.

This class' methods work transparently around the weird Zabbix macro API, which
uses different methods on the same object depending on whether it's a global or
host macro... except sometimes, for instance the C<usermacro.get> method which
can be called on both and will return different keys...  And macros don't seem
to have an C<exists> method.  It's kind of a mess.

The various massFoo methods have not been implemented at all because I did not
have a use for their "mass" functionality, despite their being the only way to
CRUD host macros.

=head1 METHODS

=over 4

=item prefix([SUFFIX])

This class' C<prefix> method is B<not> a class method.  The prefix returned
depends on the type of macro (global or host) which is a characteristic of an
instance.

=item host([HOST])

Mutator for the macro's host.  C<HOST> should be a C<Host> instance or a hashref
with a C<hostid> key.

=item globalp()

Return a true value when the macro is global, a false value otherwise.

=back

=head1 SEE ALSO

TODO links to other pods and documentation

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
