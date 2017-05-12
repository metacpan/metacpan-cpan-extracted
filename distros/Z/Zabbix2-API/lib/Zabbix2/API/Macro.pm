package Zabbix2::API::Macro;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
use JSON;
extends qw/Zabbix2::API::CRUDE/;

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

sub _readonly_properties {
    # so, for some reason, the server returns a "hosts" property, but
    # it complains when that property is sent back.
    return {
        hosts => 1,
    };
}

sub _prefix {
    my ($self, $suffix) = @_;
    if ($suffix) {
        if ($suffix =~ m/ids?/) {
            return ($self->globalp?'globalmacro':'hostmacro').$suffix;
        } elsif ($suffix eq '.delete') {
            return 'usermacro.'.($self->globalp?'deleteglobal':'delete');
        } elsif ($suffix eq '.create') {
            return 'usermacro.'.($self->globalp?'createglobal':'create');
        } elsif ($suffix eq '.update') {
            return 'usermacro.'.($self->globalp?'updateglobal':'update');
        }
        return 'usermacro'.$suffix;
    } else {
        return 'usermacro';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{macro};
}

sub value {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{value} = $value;
    }
    return $self->data->{value};
}

sub globalp {
    my $self = shift;
    return !exists($self->data->{hostid});
}

# overridden from CRUDE to set the globalmacro flag
sub pull {
    my $self = shift;
    croak(sprintf(q{Cannot pull data from server into a %s without ID}, $self->short_class))
        unless $self->id;
    my $data = $self->root->query(method => $self->_prefix('.get'),
                                  params => { $self->_prefix('ids') => [ $self->id ],
                                              globalmacro => $self->globalp ? JSON::true : JSON::false,
                                              $self->_extension })->[0];
    croak(sprintf(q{%s class object has a local ID that does not appear to exist on the server},
                  $self->short_class)) unless $data;
    $self->_set_data($data);
    return $self;
}

sub exists {
    my $self = shift;
    my $response = $self->root->query(method => $self->_prefix('.get'),
                                      params => { $self->_prefix('ids') => [$self->id],
                                                  globalmacro => $self->globalp ? JSON::true : JSON::false,
                                                  countOutput => 1 });
    return !!$response;
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Macro -- Zabbix usermacro objects

=head1 SYNOPSIS

  # create a new global macro (set its hostid attribute if you need a
  # host macro instead)
  my $macro = Zabbix2::API::Macro->new(root => $zabber,
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

L<Zabbix2::API::CRUDE>

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
