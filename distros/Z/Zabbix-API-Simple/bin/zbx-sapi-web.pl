#!/usr/bin/perl
# PODNAME: zbx-sapi-web.pl
# ABSTRACT: Zabbix API Simple CGI Endpoint
use strict;
use warnings;

use Plack::Loader;

my $app = Plack::Util::load_psgi("zbx-sapi-web.psgi");
Plack::Loader::->auto->run($app);

__END__

=pod

=encoding utf-8

=head1 NAME

zbx-sapi-web.pl - Zabbix API Simple CGI Endpoint

=head1 NAME

zbx-sapi-web - Zabbix::API::Simple web endpoint (CGI)

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
