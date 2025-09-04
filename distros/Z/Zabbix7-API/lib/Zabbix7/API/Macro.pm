package Zabbix7::API::Macro;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
use JSON;
extends qw/Zabbix7::API::CRUDE/;

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        if ($self->globalp) {
            $self->data->{globalmacroid} = $value;
            delete $self->data->{hostmacroid};
            Log::Any->get_logger->debug("Set globalmacroid: $value for global macro");
            return $self->data->{globalmacroid};
        } else {
            $self->data->{hostmacroid} = $value;
            delete $self->data->{globalmacroid};
            Log::Any->get_logger->debug("Set hostmacroid: $value for host macro");
            return $self->data->{hostmacroid};
        }
    }
    my $id = $self->globalp ? $self->data->{globalmacroid} : $self->data->{hostmacroid};
    Log::Any->get_logger->debug("Retrieved ID for macro: " . ($id // 'none') . ", global: " . ($self->globalp ? 'yes' : 'no'));
    return $id;
}

sub _readonly_properties {
    return {
        hosts => 1,
        globalmacroid => 1, # Added for Zabbix 7.0 (read-only for updates)
        hostmacroid => 1,  # Added for Zabbix 7.0 (read-only for updates)
    };
}

sub _prefix {
    my ($self, $suffix) = @_;
    if ($suffix) {
        if ($suffix =~ m/ids?/) {
            return ($self->globalp ? 'globalmacro' : 'hostmacro') . $suffix;
        } elsif ($suffix eq '.delete') {
            return 'usermacro.' . ($self->globalp ? 'deleteglobal' : 'delete');
        } elsif ($suffix eq '.create') {
            return 'usermacro.' . ($self->globalp ? 'createglobal' : 'create');
        } elsif ($suffix eq '.update') {
            return 'usermacro.' . ($self->globalp ? 'updateglobal' : 'update');
        }
        return 'usermacro' . $suffix;
    }
    return 'usermacro';
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Added for Zabbix 7.0 (for host macros)
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{macro} || '???';
    Log::Any->get_logger->debug("Retrieved name for macro ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

sub value {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{value} = $value;
        Log::Any->get_logger->debug("Set value for macro ID: " . ($self->id // 'new') . ": $value");
    }
    my $val = $self->data->{value};
    Log::Any->get_logger->debug("Retrieved value for macro ID: " . ($self->id // 'new') . ": " . ($val // 'none'));
    return $val;
}

sub globalp {
    my $self = shift;
    my $is_global = !exists($self->data->{hostid});
    Log::Any->get_logger->debug("Checked globalp for macro ID: " . ($self->id // 'new') . ": " . ($is_global ? 'global' : 'host'));
    return $is_global;
}

sub pull {
    my $self = shift;
    croak(sprintf(q{Cannot pull data from server into a %s without ID}, $self->short_class))
        unless $self->id;
    my $data = $self->root->query(
        method => $self->_prefix('.get'),
        params => {
            $self->_prefix('ids') => [ $self->id ],
            globalmacro => $self->globalp ? JSON::true : JSON::false,
            $self->_extension
        }
    )->[0];
    croak(sprintf(q{%s class object has a local ID that does not appear to exist on the server},
                  $self->short_class)) unless $data;
    $self->_set_data($data);
    Log::Any->get_logger->debug("Pulled data for $self->short_class ID: " . $self->id);
    return $self;
}

sub exists {
    my $self = shift;
    my $response = $self->root->query(
        method => $self->_prefix('.get'),
        params => {
            $self->_prefix('ids') => [ $self->id ],
            globalmacro => $self->globalp ? JSON::true : JSON::false,
            countOutput => 1,
        }
    );
    Log::Any->get_logger->debug("Checked existence of $self->short_class ID: " . ($self->id // 'none') . ", exists: $response");
    return !!$response;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{globalmacroid}; # Ensure IDs are not sent
    delete $self->data->{hostmacroid};
    Log::Any->get_logger->debug("Preparing to create macro: " . ($self->data->{macro} // 'unknown') . ", global: " . ($self->globalp ? 'yes' : 'no'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{globalmacroid}; # Ensure IDs are not sent
    delete $self->data->{hostmacroid};
    Log::Any->get_logger->debug("Preparing to update macro ID: " . ($self->id // 'new') . ", global: " . ($self->globalp ? 'yes' : 'no'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Macro -- Zabbix usermacro objects

=head1 SYNOPSIS

  # create a new global macro (set its hostid attribute if you need a
  # host macro instead)
  my $macro = Zabbix7::API::Macro->new(root => $zabber,
                                       data => { macro => '{$SUPERMACRO}',
                                                 value => 'ITSABIRD' });
  $macro->create;
  
  # change its value
  $macro->value('ITSAPLANE');
  $macro->update;

=head1 DESCRIPTION

Handles CRUD for Zabbix usermacro objects.

Both global and host macro types are represented by this class.  If
the C<hostid> attribute is undef or empty, then we assume it's a
global macro.

This class' methods work transparently around the weird Zabbix macro
API, which uses different methods on the same object depending on
whether it's a global or host macro... except sometimes, for instance
the C<usermacro.get> method which can be called on both and will
return different keys...  And macros don't seem to have an C<exists>
method.  It's kind of a mess.

=head1 METHODS

=head2 _prefix

This class' C<_prefix> method is B<not> a class method.  The _prefix
returned depends on the type of macro (global or host) which is a
characteristic of an instance.

=head2 globalp

  say $macro->globalp ? 'a global macro' : 'a host macro';

Returns a true value when the macro is global, a false value
otherwise.

=head2 name

  say $macro->name;

Returns the macro's name, which is also how it's referred to in
expressions, e.g. "{$SUPERMACRO}".

=head2 value

  $macro->value('new value');
  say $macro->value;

Mutator for the macro's value.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
