#!/usr/bin/perl
# PODNAME: zbx-sapi
# ABSTRACT: Zabbix API Simple CLI
use strict;
use warnings;

use Zabbix::API::Simple::Cmd;

# All the magic is done using MooseX::App::Cmd, App::Cmd and MooseX::Getopt
my $ZbxSpooler = Zabbix::API::Simple::Cmd::->new();
$ZbxSpooler->run();

__END__

=pod

=encoding utf-8

=head1 NAME

zbx-sapi - Zabbix API Simple CLI

=head1 NAME

zbx-sapi - Zabbix::API::Simple CLI

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
