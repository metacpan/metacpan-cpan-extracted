package Zabbix::Cli::Monitor;

use strict;
use warnings;
use v5.10;
our $VERSION = '0.01';

use Zabbix::API;
use JSON;
use Term::ANSIColor;

use MooseX::App::Simple qw(Color ConfigHome);

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

has zabbix => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    unless (
        $self->_config_data->{api_url} &&
        $self->_config_data->{user} &&
        $self->_config_data->{password}
        ) {
        say "No valid config file found. Please ensure config file exists and has required fields defined. Example:";
        say <<EOF;
~/.zabmon/config.yaml
---
user: api_user
api_url: http://your.zabbix.url/api_jsonrpc.php
password: imal33thaxx0r
EOF
        exit 1;
        }


    my $zabbix = Zabbix::API->new(
        server => $self->_config_data->{api_url},
        verbosity => 0
        );

    eval {
        $zabbix->login(
            user => $self->_config_data->{user},
            password => $self->_config_data->{password}
        );
    };

    die "could not authenticate\n$@" if $@;

    $self->zabbix($zabbix);
}

sub get_current_triggers {
    my ($self) = @_;

    my $resp = $self->zabbix->raw_query(
        method => 'trigger.get',
        params => {
            output => 'extend', # Helpfully(?) you don't get the description by default
            monitored => 1,     # Helpfully(?) unmonitored hosts are included by default
            selectHosts => 1,   # Helpfully(?) the trigger's host is not included by default
            filter => {         # Filter to triggers that are still happening
                value => 1
            }
        }
    );
    # Returns the data as a JSON string in _content,
    # get it into a useful data structure:
    my $content = from_json($resp->{_content});
    return $content->{result};
}

sub get_host_list {
    my ($self, $hosts) = @_;

    my $resp = $self->zabbix->fetch(
        'Host',
        params => { hostids => $hosts }
    );
    return map {
        $_->data->{hostid}, { name => $_->data->{name}, host => $_->data->{host} }
        } @{$resp};
}

sub say_current_issues {
    my ($self) = @_;

    my $triggers = $self->get_current_triggers();

    unless ( scalar @$triggers ) {
        print color 'green';
        say "No current issues";
        print color 'reset'
    }

    # Get host name data to map to triggers
    my @trigger_hosts = map { $_->{hosts}[0]{hostid} } @$triggers;
    my %hostnames = $self->get_host_list( \@trigger_hosts );

    # Print out summary of triggered hosts
    for my $trigger (@$triggers) {
        my $hn = $hostnames{ $trigger->{hosts}[0]{hostid} };
        my $host = $hn->{host};
        my $name = $hn->{name};
        my $desc = $trigger->{description};

        $desc =~ s/\{HOST\.NAME\}/$name/; # Parse Zabbixy stuff

        print color 'cyan';
        say "$host";
        print color 'red';
        say "\t$desc\n";
        print color 'reset';
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Zabbix::Cli::Monitor - Keep up-to-date with Zabbix from the command line

=head1 SYNOPSIS

  use Zabbix::Cli::Monitor;

=head1 DESCRIPTION

Zabbix::Cli::Monitor is a simple application that uses the Zabbix API to get details
of any hosts that have problems. More stuff to come. Probably. Just run the 'zabmon'
script.

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
