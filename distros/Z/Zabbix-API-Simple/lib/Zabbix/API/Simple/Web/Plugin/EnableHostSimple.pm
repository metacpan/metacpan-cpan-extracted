package Zabbix::API::Simple::Web::Plugin::EnableHostSimple;
{
  $Zabbix::API::Simple::Web::Plugin::EnableHostSimple::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::Web::Plugin::EnableHostSimple::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Example plugin to enable an host

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Zabbix::API::Simple::Web::Plugin';
# has ...
# with ...
# initializers ...
sub _init_fields { return [qw(hostname)]; }

sub _init_alias { return 'enable_host_simple'; }

# your code here ...
sub execute {
    my $self = shift;
    my $request = shift;

    return unless $request->{'hostname'};
    my $hostname = $request->{'hostname'};

    my $data = {};

    $data->{'status'} = 0; # 1 == disabled, i.e. not monitored

    if($self->sapi()->host_update($hostname,$data)) {
        return 1;
    }
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::API::Simple::Web::Plugin::EnableHostSimple - Example plugin to enable an host

=head1 DESCRIPTION

This plugin shows how to enable an existing host.

=head1 NAME

Zabbix::API::Simple::Web::API::Plugin::EnableHostSimple - Enable an host

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
