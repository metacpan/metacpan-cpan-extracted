package WebService::LogicMonitor::Entity;

# ABSTRACT: Base class for a LogicMonitor host or group entity

use v5.16.3;
use Log::Any '$log';
use List::Util 1.33 'any';
use Moo;

has id => (is => 'ro', predicate => 1);    # int

# use this instead of displayed_as for hosts?
has name => (is => 'rw', required => 0);    # str

has description => (is => 'rw', predicate => 1);    # str

has created_on => (
    is     => 'ro',
    coerce => sub {
        DateTime->from_epoch(epoch => $_[0]);
    },
);

has type => (is => 'ro');                           # enum HOST|HOSTGROUP

has [qw/alert_enable in_sdt/] => (is => 'rw', default => 0);    # bool

has properties => (
    is        => 'rw',
    lazy      => 1,
    builder   => 1,
    predicate => 1,
    isa       => sub {
        unless (ref $_[0] && ref $_[0] eq 'HASH') {
            die 'properties should be specified as a hashref';
        }
    },
    coerce => sub {
        my $data = shift;
        if (ref $data eq 'ARRAY') {
            my %prop = map {
                if (defined $_->{value} && $_->{value} ne '') {
                    $_->{name} => $_->{value};
                } else {
                    ();
                }
            } @$data;
            $data = \%prop;

        } else {
            for (keys %$data) {
                delete $data->{$_}
                  if (defined $data->{$_} && $data->{$_} eq '');
            }
        }

        # convert certain comma separated strings to arrays
        my @array_keys = (qw/system.categories system.groups/);
        for (@array_keys) {
            next unless exists $data->{$_};
            $data->{$_} = [split ',', $data->{$_}];
        }

        return $data;
    },
);

has is_group => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->type eq 'HOSTGROUP' ? 1 : 0 },
);

has is_host => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->type eq 'HOST' ? 1 : 0 },
);

sub _build_properties {
    my ($self, $only_own) = @_;

    $only_own //= 0;

    $log->debug('Fetching properties');

    my $data;
    if (ref $self eq 'WebService::LogicMonitor::Host') {

        # XXX this seems redundant - properties is always
        # returned by get_hosts, don't need a separate step
        # perhaps useful for refreshing?
        $data =
          $self->_lm->_http_get('getHostProperties', hostId => $self->id,);
    } else {
        $data = $self->_lm->_http_get(
            'getHostGroupProperties',
            hostGroupId       => $self->id,
            onlyOwnProperties => $only_own,
        );
    }

    return $data;
}

sub _format_properties {
    my ($self, $params) = @_;

    # a lot of props starting with system are not settable
    # XXX what about passwords - are they getting set to a literal '*******'?
    my @system_props = (
        qw/
          system.groups system.hostname system.enablenetflow
          system.devicetype system.displayname
          /
    );

    my $i = 0;
    while (my ($k, $v) = each %{$self->properties}) {
        next if $v =~ /^\*+$/;
        next if any { $_ eq $k } @system_props;

        $params->{"propName$i"} = $k;
        if (!ref $v) {
            $params->{"propValue$i"} = $v;
        } elsif (ref $v eq 'ARRAY') {
            $params->{"propValue$i"} = join ',', @$v;
        }
        $i++;

    }

    return;
}

sub set_sdt {
    my $self = shift;

    my $entity;
    if (ref $self eq 'WebService::LogicMonitor::Host') {
        $entity = 'Host';
    } elsif (ref $self eq 'WebService::LogicMonitor::Group') {
        $entity = 'HostGroup';
    } else {
        die 'What am I???';
    }

    return $self->_lm->set_sdt($entity => $self->id, @_);
}

sub set_quick_sdt {
    my $self = shift;

    my $entity;
    if (ref $self eq 'WebService::LogicMonitor::Host') {
        $entity = 'Host';
    } elsif (ref $self eq 'WebService::LogicMonitor::Group') {
        $entity = 'HostGroup';
    } else {
        die 'What am I???';
    }

    return $self->_lm->set_quick_sdt($entity => $self->id, @_);
}


sub add_system_category {
    my ($self, $category) = @_;
    return
      if any { $_ eq $category } @{$self->properties->{'system.categories'}};
    return push @{$self->properties->{'system.categories'}}, $category;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Entity - Base class for a LogicMonitor host or group entity

=head1 VERSION

version 0.211560

=head1 METHODS

=head2 C<add_system_category($category)>

Add another category to the C<system.categories> property. Will not add a
category that is already set.

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
