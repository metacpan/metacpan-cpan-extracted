package Thorium::Types;
{
  $Thorium::Types::VERSION = '0.510';
}
BEGIN {
  $Thorium::Types::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Custom types

use Thorium::Protection;

# yes, this is a little ugly, but this is how it works
use MooseX::Types -declare => [
    qw(
          ApacheAccessLog
          ApacheErrorLog
          ApacheListen
          ApacheLogLevel
          Environment
          Hostname
          HostnameAndPort
          HostnameOrIP
          IPv4Address
          Port
          UnixDirectory
          UnixExecutableFile
          UnixFilename
          URLHTTP
  )
];

# import builtin types
use MooseX::Types::Moose qw(Str Int);

# core
use Cwd;
use Sys::Hostname qw();

# CPAN
use Regexp::Common;

our @environment_names = qw(development qa1 qa2 qa3 mqa staging production);
our @apache_log_levels = qw(emerg alert crit error warn notice info debug);

# Generic
## Network
subtype IPv4Address,
    as Str,
    where { m/^$RE{net}{IPv4}$/ },
    message { 'Examples: 192.170.2.1, 10.1.101.191, 127.0.0.1' };

subtype Port,
    as Int,
    where { $_ > 0 && $_ < 2**16 - 1 },
    message { 'A port is an integer: > 0 and < ' . (2**16 - 1) };

subtype Hostname,
    as Str,
    where { m/^$RE{net}{domain}$/ },
    message { "$_ is not a valid domain hostname" };

subtype HostnameAndPort,
    as Str,
    where {
        my ($host, $port) = split(':', $_);
        return (is_Hostname($host) || is_IPv4Address($host)) && is_Port($port);
    },
    message { 'Must be either a valid hostname or IP (v4) with a port. e.g. somewhere:80, 0.0.0.0:80' };

subtype HostnameOrIP,
    as Str,
    where {
        my $host = $_;
        return (is_Hostname($host) || is_IPv4Address($host));
    },
    message { 'Must be either a valid hostname or IP (v4). e.g. someplace, 192.168.0.1' };

### HTTP
subtype URLHTTP,
    as Str,
    where { m/^$RE{URI}{HTTP}$/ },
    message { 'Must be a valid HTTP URL. e.g. http://localhost:8888/over/there' };

## File system
subtype UnixDirectory,
    as Str,
    where { -e -d $_ },
    message { "$_ is not an existing directory" };

subtype UnixFilename,
    as Str,
    where { m/[\0|\/]/ },
    message { "$_ is not a valid Unix file name" };

subtype UnixExecutableFile,
    as Str,
    where { ((m/[\0|\/]/) && (-e -r -x $_)) },
    message { "$_ is not a valid executable" };

# Apache
subtype ApacheListen,
    as Str,
    where {
        my ($ip, $port) = split(':', $_);
        return is_IPv4Address($ip) && is_Port($port);
    },
    message { "$_ is not valid Apache2 Listen directive syntax" };

subtype ApacheLogLevel,
    as Str,
    where { $_ ~~ @apache_log_levels },
    message { "$_ is not a valid Apache2 log level. Must be one of " . join(', ', @apache_log_levels) };

1;

__END__
=pod

=head1 NAME

Thorium::Types - Custom types

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

