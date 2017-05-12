package Zabbix::Reporter::Cmd;
{
  $Zabbix::Reporter::Cmd::VERSION = '0.07';
}
BEGIN {
  $Zabbix::Reporter::Cmd::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a CLI to the Zabbix::Reporter

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
extends 'MooseX::App::Cmd';
# has ...
# with ...
# initializers ...

# your code here ...

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zabbix::Reporter::Cmd - a CLI to the Zabbix::Reporter

=head1 NAME

Zabbix::Reporter::Cmd - a CLI to the Zabbix::Reporter

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
