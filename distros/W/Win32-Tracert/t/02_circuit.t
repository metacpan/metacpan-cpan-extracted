use strict;
use warnings;
use utf8;


 
use Test::More tests => 5;

use_ok 'Win32::Tracert';

my $tracert_output="./t/trace_tracert.txt";

open my $th, '<:encoding(Windows-1252):crlf', "$tracert_output" or die "Impossible de lire le fichier $tracert_output\n";
my @trace_out=<$th>;
close $th;

my $route = Win32::Tracert->new(circuit => \@trace_out);
isa_ok($route,'Win32::Tracert');

$route->to_trace;

ok($route->found(),"Is route Found");

is ($route->hops(),28,"Hops number to reach destination");

my $path_witness = {
          '68.178.254.85' => {
                             'IPADRESS' => '68.178.254.85',
                             'HOSTNAME' => 'lacuna.com',
                             'HOPS' => [
                                         {
                                           'PACKET3_RT' => '2',
                                           'IPADRESS' => '172.24.11.10',
                                           'PACKET2_RT' => '2',
                                           'PACKET1_RT' => '2',
                                           'HOSTNAME' => 'gwvlan13.si3si.int',
                                           'HOPID' => '1'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '172.18.160.49',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'N/A',
                                           'HOPID' => '2'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '172.25.24.102',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'terre.si3si.int',
                                           'HOPID' => '3'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '192.168.0.12',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'lpb.chouchou.fr',
                                           'HOPID' => '4'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '81.252.161.254',
                                           'PACKET2_RT' => '1',
                                           'PACKET1_RT' => '1',
                                           'HOSTNAME' => '254-161.252-81.static-ip.oleane.fr',
                                           'HOPID' => '5'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '81.54.103.177',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'N/A',
                                           'HOPID' => '6'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '81.52.8.129',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'Ge-3-1-1.LILP1.Lille.raei.transitip.francetelecom.net',
                                           'HOPID' => '7'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '193.253.14.29',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '1',
                                           'HOSTNAME' => 'N/A',
                                           'HOPID' => '8'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '193.253.89.189',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '<1',
                                           'HOSTNAME' => 'ae20-0.nclil101.VilleneuveDascq.francetelecom.net',
                                           'HOPID' => '9'
                                         },
                                         {
                                           'PACKET3_RT' => '<1',
                                           'IPADRESS' => '193.252.100.106',
                                           'PACKET2_RT' => '<1',
                                           'PACKET1_RT' => '1',
                                           'HOSTNAME' => 'ae41-0.nilil101.VilleneuveDascq.francetelecom.net',
                                           'HOPID' => '10'
                                         },
                                         {
                                           'PACKET3_RT' => '6',
                                           'IPADRESS' => '81.253.184.178',
                                           'PACKET2_RT' => '2',
                                           'PACKET1_RT' => '2',
                                           'HOSTNAME' => 'N/A',
                                           'HOPID' => '11'
                                         },
                                         {
                                           'PACKET3_RT' => '2',
                                           'IPADRESS' => '193.251.255.218',
                                           'PACKET2_RT' => '4',
                                           'PACKET1_RT' => '8',
                                           'HOSTNAME' => 'level3-3.GW.opentransit.net',
                                           'HOPID' => '12'
                                         },
                                         {
                                           'PACKET3_RT' => '100',
                                           'IPADRESS' => '4.69.168.126',
                                           'PACKET2_RT' => '109',
                                           'PACKET1_RT' => '85',
                                           'HOSTNAME' => 'ae-70-70.csw2.Paris1.Level3.net',
                                           'HOPID' => '13'
                                         },
                                         {
                                           'PACKET3_RT' => '89',
                                           'IPADRESS' => '4.69.161.97',
                                           'PACKET2_RT' => '78',
                                           'PACKET1_RT' => '70',
                                           'HOSTNAME' => 'ae-72-72.ebr2.Paris1.Level3.net',
                                           'HOPID' => '14'
                                         },
                                         {
                                           'PACKET3_RT' => '68',
                                           'IPADRESS' => '4.69.137.50',
                                           'PACKET2_RT' => '66',
                                           'PACKET1_RT' => '81',
                                           'HOSTNAME' => 'ae-41-41.ebr2.Washington1.Level3.net',
                                           'HOPID' => '15'
                                         },
                                         {
                                           'PACKET3_RT' => '118',
                                           'IPADRESS' => '4.69.134.150',
                                           'PACKET2_RT' => '74',
                                           'PACKET1_RT' => '78',
                                           'HOSTNAME' => 'ae-72-72.csw2.Washington1.Level3.net',
                                           'HOPID' => '16'
                                         },
                                         {
                                           'PACKET3_RT' => '107',
                                           'IPADRESS' => '4.69.134.133',
                                           'PACKET2_RT' => '96',
                                           'PACKET1_RT' => '75',
                                           'HOSTNAME' => 'ae-71-71.ebr1.Washington1.Level3.net',
                                           'HOPID' => '17'
                                         },
                                         {
                                           'PACKET3_RT' => '*',
                                           'IPADRESS' => 'N/A',
                                           'PACKET2_RT' => '*',
                                           'PACKET1_RT' => '*',
                                           'HOSTNAME' => 'N/A',
                                           'HOPID' => '18'
                                         },
                                         {
                                           'PACKET3_RT' => '80',
                                           'IPADRESS' => '4.69.134.21',
                                           'PACKET2_RT' => '77',
                                           'PACKET1_RT' => '77',
                                           'HOSTNAME' => 'ae-7-7.ebr3.Dallas1.Level3.net',
                                           'HOPID' => '19'
                                         },
                                         {
                                           'PACKET3_RT' => '148',
                                           'IPADRESS' => '4.69.151.133',
                                           'PACKET2_RT' => '149',
                                           'PACKET1_RT' => '84',
                                           'HOSTNAME' => 'ae-63-63.csw1.Dallas1.Level3.net',
                                           'HOPID' => '20'
                                         },
                                         {
                                           'PACKET3_RT' => '151',
                                           'IPADRESS' => '4.69.151.126',
                                           'PACKET2_RT' => '152',
                                           'PACKET1_RT' => '152',
                                           'HOSTNAME' => 'ae-61-61.ebr1.Dallas1.Level3.net',
                                           'HOPID' => '21'
                                         },
                                         {
                                           'PACKET3_RT' => '152',
                                           'IPADRESS' => '4.69.133.29',
                                           'PACKET2_RT' => '153',
                                           'PACKET1_RT' => '139',
                                           'HOSTNAME' => 'ae-1-8.bar1.Phoenix1.Level3.net',
                                           'HOPID' => '22'
                                         },
                                         {
                                           'PACKET3_RT' => '124',
                                           'IPADRESS' => '4.53.104.2',
                                           'PACKET2_RT' => '82',
                                           'PACKET1_RT' => '136',
                                           'HOSTNAME' => 'THE-GO-DADD.bar1.Phoenix1.Level3.net',
                                           'HOPID' => '23'
                                         },
                                         {
                                           'PACKET3_RT' => '119',
                                           'IPADRESS' => '184.168.0.113',
                                           'PACKET2_RT' => '120',
                                           'PACKET1_RT' => '110',
                                           'HOSTNAME' => 'ip-184-168-0-113.ip.secureserver.net',
                                           'HOPID' => '24'
                                         },
                                         {
                                           'PACKET3_RT' => '78',
                                           'IPADRESS' => '184.168.0.113',
                                           'PACKET2_RT' => '107',
                                           'PACKET1_RT' => '135',
                                           'HOSTNAME' => 'ip-184-168-0-113.ip.secureserver.net',
                                           'HOPID' => '25'
                                         },
                                         {
                                           'PACKET3_RT' => '77',
                                           'IPADRESS' => '184.168.1.134',
                                           'PACKET2_RT' => '63',
                                           'PACKET1_RT' => '74',
                                           'HOSTNAME' => 'ip-184-168-1-134.ip.secureserver.net',
                                           'HOPID' => '26'
                                         },
                                         {
                                           'PACKET3_RT' => '107',
                                           'IPADRESS' => '68.178.254.85',
                                           'PACKET2_RT' => '79',
                                           'PACKET1_RT' => '62',
                                           'HOSTNAME' => 'p3slh015.shr.phx3.secureserver.net',
                                           'HOPID' => '27'
                                         },
                                         {
                                           'PACKET3_RT' => '75',
                                           'IPADRESS' => '68.178.254.85',
                                           'PACKET2_RT' => '119',
                                           'PACKET1_RT' => '83',
                                           'HOSTNAME' => 'p3slh015.shr.phx3.secureserver.net',
                                           'HOPID' => '28'
                                         }
                                       ]
                           }
        };

is_deeply( $route->path(), $path_witness, 'Path deeply comparison' );