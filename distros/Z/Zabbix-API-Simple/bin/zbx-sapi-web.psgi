#!/usr/bin/perl
# PODNAME: zbx-sapi-web.psgi
# ABSTRACT: Zabbix API Simple PSGI Endpoint
use strict;
use warnings;

use lib '../lib';

use Zabbix::API::Simple::Web;

my $Frontend = Zabbix::API::Simple::Web::->new();
my $app = sub {
    my $env = shift;

    return $Frontend->run($env);
};

__END__

=pod

=encoding utf-8

=head1 NAME

zbx-sapi-web.psgi - Zabbix API Simple PSGI Endpoint

=head1 NAME

zbx-sapi-web - Zabbix::API::Simple web endpoint (PSGI)

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
