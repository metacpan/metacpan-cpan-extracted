package Zabbix::API::Simple::Web::Plugin::AddHostDerived;
{
  $Zabbix::API::Simple::Web::Plugin::AddHostDerived::VERSION = '0.01';
}
BEGIN {
  $Zabbix::API::Simple::Web::Plugin::AddHostDerived::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Example plugin to add an host via alias

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
extends 'Zabbix::API::Simple::Web::Plugin::AddHostSimple';
# has ...
# with ...
# initializers ...
sub _init_alias { return 'add_host_derived'; }

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::API::Simple::Web::Plugin::AddHostDerived - Example plugin to add an host via alias

=head1 DESCRIPTION

This plugin demonstrates the use of an dervied plugin class as an alias.

The purpose of this class is to serve as an alias to its baseclass. It will
inherit the behaviour but can be equiped with a whole different configuration.

=head1 NAME

Zabbix::API::Simple::Web::Plugin::AddHostDerived - Derived alias example

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
