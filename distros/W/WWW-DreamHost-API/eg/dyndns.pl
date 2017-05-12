#!/usr/env perl

# $Id: dyndns.pl 39 2012-03-25 04:20:31Z stro $

use strict;
use warnings;
use Carp;
use English '-no_strict_refs';

use Getopt::Long ();
use LWP::UserAgent;
use WWW::DreamHost::API;

my ($key, $domain);

my $opts = Getopt::Long::GetOptions(
    'key=s'    => \$key,
    'domain=s' => \$domain,
);


if (defined $key and defined $domain) {
    if (my $api = WWW::DreamHost::API->new($key)) {
        my $res = $api->command('api-list_accessible_cmds');
        croak 'Cannot get a list of commands from API' unless $res->{'result'} eq 'success';

        my %commands = map { $_ => 1 } @{ $res->{'data'} };
#       croak 'DNS commands look disabled' unless $commands{'dns-add_record'} and $commands{'dns-remove_record'};

        # Check DNS address for old records

        $res = $api->command('dns-list_records');

        croak 'Cannot get DNS records from API' unless $res->{'result'} eq 'success';

        foreach my $rec (@{ $res->{'data'} }) {
            if ($rec->{'record'} eq $domain) {
                next unless $rec->{'type'} eq 'A';

                croak $domain, ' is not editable' unless $rec->{'editable'};

                # Remove old DNS address

                print 'Remove A record for ', $rec->{'value'}, "\n";

                $res = $api->command('dns-remove_record',
                    'record' => $domain,
                    'type'   => 'A',
                    'value'  => $rec->{'value'},
                );

                croak 'Cannot remove old A value' unless $res->{'result'} eq 'success';

                # last; if you're absolutely sure there's only one A record
            }
        }

        # Find what is our IP address

        my $ua = LWP::UserAgent->new;
        my $response = $ua->get('http://trouchelle.com/perl/ip.pl');

        croak 'Cannot detect our IP' unless $response->is_success;

        my $addr = $response->decoded_content;

        # Create new A record

        $res = $api->command('dns-add_record',
            'record' => $domain,
            'type'   => 'A',
            'value'  => $addr,
        );

        croak 'Cannot create new A value' unless $res->{'result'} eq 'success';

        print 'New record for domain ', $domain, ' is ', $addr, "\n";

    } else {
        croak 'Cannot create API object: ', $EVAL_ERROR;
    }
} else {
    print 'Usage: dyndns.pl key=6SHU5P2HLDAYECUM domain=dyn.trouchelle.com';
}

