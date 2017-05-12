package Zabbix::API::Simple::Cmd::Command::hostdel;
{
  $Zabbix::API::Simple::Cmd::Command::hostdel::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::Cmd::Command::hostdel::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: remove a host via the Zabbix API from the CLI

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
extends 'Zabbix::API::Simple::Cmd::Command';
# has ...
has 'name' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'n',
    'documentation' => 'Hostname',
);

has 'group' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 0,
    'traits' => [qw(Getopt)],
    'cmd_aliases' => 'g',
    'documentation' => 'Group',
);
# with ...
# initializers ...

# your code here ...
sub execute {
    my $self = shift;

    my $filter = {};
    if(defined($self->group())) {
        $filter->{'groupids'} = $self->group();
    }

    return $self->sapi()->host_delete($self->name(),$filter);
}

sub abstract {
    return 'Delete an host';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::API::Simple::Cmd::Command::hostdel - remove a host via the Zabbix API from the CLI

=head1 NAME

Zabbix::API::Simple::Cmd::Command::hostdel - remove a host via the Zabbix API from the CLI

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
