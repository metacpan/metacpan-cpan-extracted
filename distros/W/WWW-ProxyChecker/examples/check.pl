#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib  ../lib);
use WWW::ProxyChecker;

my $checker = WWW::ProxyChecker->new( debug => 1 );

for ( @{ $checker->check( _make_data() ) } ) {
    print "$_ is alive\n";
}

sub _make_data {
    my $prox = [
            {
              'country' => 'South Korea',
              'ip' => '221.139.50.83',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Czechoslovakia',
              'ip' => '82.114.70.98',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'China',
              'ip' => '202.116.76.163',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'N/A',
              'ip' => '190.78.95.118',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Argentina',
              'ip' => '200.51.41.29',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Australia',
              'ip' => '165.228.132.10',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'China',
              'ip' => '211.161.128.126',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.179.148.141',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'N/A',
              'ip' => '189.33.153.221',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Romania',
              'ip' => '81.181.45.25',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Japan',
              'ip' => '203.143.116.101',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '80'
            },
            {
              'country' => 'Mexico',
              'ip' => '189.131.235.179',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'South Korea',
              'ip' => '211.119.242.47',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.171.124.197',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Ghana',
              'ip' => '41.204.32.35',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'China',
              'ip' => '219.232.224.35',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'N/A',
              'ip' => '78.39.204.114',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '8080'
            },
            {
              'country' => 'Egypt',
              'ip' => '84.205.98.242',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '8080'
            },
            {
              'country' => 'Romania',
              'ip' => '85.186.159.233',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Iran',
              'ip' => '85.9.83.51',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Great Britain (UK)',
              'ip' => '195.248.254.11',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Indonesia',
              'ip' => '203.190.52.115',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'N/A',
              'ip' => '222.127.228.19',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'Argentina',
              'ip' => '190.3.10.228',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'South Africa',
              'ip' => '196.30.229.162',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '80'
            },
            {
              'country' => 'Ecuador',
              'ip' => '200.125.201.218',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.219.152.9',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'China',
              'ip' => '218.59.164.246',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '143.107.238.188',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'United States',
              'ip' => '209.129.192.52',
              'last_test' => '2008-03-14',
              'type' => 'high anonymity',
              'port' => '80'
            },
            {
              'country' => 'Slovak Republic',
              'ip' => '213.160.169.244',
              'last_test' => '2008-03-14',
              'type' => 'high anonymity',
              'port' => '8080'
            },
            {
              'country' => 'United Arab Emirates',
              'ip' => '195.229.236.106',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '80'
            },
            {
              'country' => 'United States',
              'ip' => '65.213.194.11',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'Turkey',
              'ip' => '212.58.11.72',
              'last_test' => '2008-03-14',
              'type' => 'anonymous',
              'port' => '80'
            },
            {
              'country' => 'Japan',
              'ip' => '219.66.154.224',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Indonesia',
              'ip' => '202.146.129.220',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Great Britain (UK)',
              'ip' => '217.41.27.254',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Thailand',
              'ip' => '203.149.32.4',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.219.152.6',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Philippines',
              'ip' => '124.104.66.27',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Japan',
              'ip' => '202.216.177.18',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.179.148.130',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            },
            {
              'country' => 'Thailand',
              'ip' => '202.29.87.39',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Australia',
              'ip' => '165.228.131.10',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Australia',
              'ip' => '165.228.128.10',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'China',
              'ip' => '218.87.71.138',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'United States',
              'ip' => '63.149.98.82',
              'last_test' => '2008-03-14',
              'type' => 'high anonymity',
              'port' => '80'
            },
            {
              'country' => 'India',
              'ip' => '203.110.81.218',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'Brazil',
              'ip' => '200.242.179.51',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '3128'
            },
            {
              'country' => 'N/A',
              'ip' => '208.72.247.201',
              'last_test' => '2008-03-14',
              'type' => 'high anonymity',
              'port' => '3128'
            },
            {
              'country' => 'United States',
              'ip' => '63.149.98.27',
              'last_test' => '2008-03-14',
              'type' => 'high anonymity',
              'port' => '80'
            },
            {
              'country' => 'Indonesia',
              'ip' => '202.173.23.141',
              'last_test' => '2008-03-14',
              'type' => 'transparent',
              'port' => '8080'
            }
    ];

    my @data;
    for ( @$prox ) {
        push @data, join '', 'http://', join ':', @$_{qw(ip port)};
    }
    return \@data;
}