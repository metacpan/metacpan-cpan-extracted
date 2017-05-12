#!/usr/bin/env perl

#########################

use strict;
use Sys::Hostname;
use Test::More tests => 5;
BEGIN {
    use_ok('Traceroute::Similar')
};

#########################
my $example_routes = {
          'google.com' => [
                            { 'name' => 'fritz.box',                     'addr' => '192.168.123.1'  },
                            { 'name' => 'ac2-mdsl.muc1.m-online.net',    'addr' => '82.135.16.21'   },
                            { 'name' => 'gi3-12.r1.muc1.m-online.net',   'addr' => '212.18.6.201'   },
                            { 'name' => 'ge-0-3-0.rt-inxs.m-online.net', 'addr' => '212.18.7.62'    },
                            { 'name' => 'inxs.google.com',               'addr' => '194.59.190.61'  },
                            { 'name' => '66.249.94.88',                  'addr' => '66.249.94.88'   },
                            { 'name' => '72.14.233.107',                 'addr' => '72.14.233.107'  },
                            { 'name' => '72.14.233.104',                 'addr' => '72.14.233.104'  },
                            { 'name' => '216.239.43.90',                 'addr' => '216.239.43.90'  },
                            { 'name' => '72.14.238.136',                 'addr' => '72.14.238.136'  },
                            { 'name' => '72.14.239.131',                 'addr' => '72.14.239.131'  },
                            { 'name' => '209.85.255.194',                'addr' => '209.85.255.194' },
                            { 'name' => 'gw-in-f100.1e100.net',          'addr' => '74.125.67.100'  }
                          ],
          'google.de' => [
                           { 'name' => 'fritz.box',                      'addr' => '192.168.123.1'  },
                           { 'name' => 'ac2-mdsl.muc1.m-online.net',     'addr' => '82.135.16.21'   },
                           { 'name' => 'gi3-12.r1.muc1.m-online.net',    'addr' => '212.18.6.201'   },
                           { 'name' => 'ge-0-3-0.rt-inxs.m-online.net',  'addr' => '212.18.7.62'    },
                           { 'name' => 'inxs.google.com',                'addr' => '194.59.190.61'  },
                           { 'name' => '66.249.94.86',                   'addr' => '66.249.94.86'   },
                           { 'name' => '72.14.238.129',                  'addr' => '72.14.238.129'  },
                           { 'name' => '209.85.250.140',                 'addr' => '209.85.250.140' },
                           { 'name' => '66.249.95.150',                  'addr' => '66.249.95.150'  },
                           { 'name' => '72.14.232.241',                  'addr' => '72.14.232.241'  },
                           { 'name' => '216.239.49.126',                 'addr' => '216.239.49.126' },
                           { 'name' => 'gv-in-f104.1e100.net',           'addr' => '216.239.59.104' }
                         ]
};
my $ts = Traceroute::Similar->new( verbose => 0 );
my $last_common_hop2 = $ts->_calculate_last_common_hop($example_routes);
is($last_common_hop2, '194.59.190.61', 'Example 2');
my $expected_hops = [
                    '192.168.123.1',
                    '82.135.16.21',
                    '212.18.6.201',
                    '212.18.7.62',
                    '194.59.190.61',
                    ];
my $common_hops = $ts->_calculate_common_hops($example_routes);
is_deeply($common_hops, $expected_hops, 'Example 3');

#########################
# Test Output from OSX traceroute
my $test_output1 = q{
traceroute: Warning: google.de has multiple addresses; using 209.85.229.104
traceroute to google.de (209.85.229.104), 64 hops max, 40 byte packets
 1  fritz.box (192.168.123.1)  2.724 ms  3.185 ms  2.847 ms
 2  ppp-default.m-online.net (82.135.16.28)  26.383 ms  26.990 ms  26.057 ms
 3  ten1-4.r1.muc7.m-online.net (82.135.16.161)  26.483 ms  26.746 ms  25.752 ms
 4  ge-0-3-0.rt-inxs.m-online.net (212.18.7.62)  62.181 ms  26.103 ms  26.768 ms
 5  ge-0-3-0.rt-inxs.m-online.net (212.18.7.62)  25.922 ms  26.070 ms  27.002 ms
 6  inxs.google.com (194.59.190.61)  33.836 ms  33.841 ms  34.966 ms
 7  66.249.94.86 (66.249.94.86)  35.200 ms 66.249.94.88 (66.249.94.88)  34.118 ms  33.538 ms
 8  209.85.248.249 (209.85.248.249)  34.597 ms  34.802 ms 72.14.238.129 (72.14.238.129)  35.946 ms
 9  209.85.250.140 (209.85.250.140)  41.551 ms  40.996 ms  40.880 ms
10  72.14.232.130 (72.14.232.130)  47.922 ms  44.720 ms 209.85.255.212 (209.85.255.212)  47.353 ms
11  209.85.252.83 (209.85.252.83)  46.335 ms 209.85.251.231 (209.85.251.231)  47.919 ms 72.14.236.191 (72.14.236.191)  48.256 ms
12  209.85.243.73 (209.85.243.73)  45.197 ms 209.85.243.77 (209.85.243.77)  47.214 ms 209.85.243.73 (209.85.243.73)  53.431 ms
13  ww-in-f104.1e100.net (209.85.229.104)  48.702 ms  51.674 ms  47.806 ms
};
my $expected1 = [
          { 'name' => 'fritz.box',                      'addr' => '192.168.123.1'   },
          { 'name' => 'ppp-default.m-online.net',       'addr' => '82.135.16.28'    },
          { 'name' => 'ten1-4.r1.muc7.m-online.net',    'addr' => '82.135.16.161'   },
          { 'name' => 'ge-0-3-0.rt-inxs.m-online.net',  'addr' => '212.18.7.62'     },
          { 'name' => 'ge-0-3-0.rt-inxs.m-online.net',  'addr' => '212.18.7.62'     },
          { 'name' => 'inxs.google.com',                'addr' => '194.59.190.61'   },
          { 'name' => '66.249.94.86',                   'addr' => '66.249.94.86'    },
          { 'name' => '209.85.248.249',                 'addr' => '209.85.248.249'  },
          { 'name' => '209.85.250.140',                 'addr' => '209.85.250.140'  },
          { 'name' => '72.14.232.130',                  'addr' => '72.14.232.130'   },
          { 'name' => '209.85.252.83',                  'addr' => '209.85.252.83'   },
          { 'name' => '209.85.243.73',                  'addr' => '209.85.243.73'   },
          { 'name' => 'ww-in-f104.1e100.net',           'addr' => '209.85.229.104'  }
        ];
my $test_routes1 = $ts->_extract_routes_from_traceroute($test_output1);
is_deeply($test_routes1, $expected1, 'traceroute output osx');



#########################
# test output from linux traceroute
my $test_output2 = q{
traceroute to nierlein.de (194.246.123.75), 30 hops max, 60 byte packets
 1  fritz.box (192.168.123.1)  1.029 ms  2.109 ms  19.187 ms
 2  ppp-default.m-online.net (82.135.16.28)  28.022 ms  30.277 ms  30.372 ms
 3  ten1-4.r1.muc7.m-online.net (82.135.16.161)  31.660 ms  32.352 ms  33.215 ms
 4  ten1-2.r1.muc1.m-online.net (212.18.7.161)  35.138 ms  36.375 ms  37.751 ms
 5  gi1-0-27.rs12.muc1.m-online.net (88.217.206.34)  39.168 ms  40.515 ms  41.354 ms
 6  gi1-0-24.rs11.muc1.m-online.net (88.217.206.29)  42.842 ms  25.975 ms  27.569 ms
 7  * * *
 8  * * *
 9  * * *
10  * * *
11  * * *
12  * * *
13  * * *
};
my $expected2 = [
          { 'name' => 'fritz.box',                       'addr' => '192.168.123.1' },
          { 'name' => 'ppp-default.m-online.net',        'addr' => '82.135.16.28'  },
          { 'name' => 'ten1-4.r1.muc7.m-online.net',     'addr' => '82.135.16.161' },
          { 'name' => 'ten1-2.r1.muc1.m-online.net',     'addr' => '212.18.7.161'  },
          { 'name' => 'gi1-0-27.rs12.muc1.m-online.net', 'addr' => '88.217.206.34' },
          { 'name' => 'gi1-0-24.rs11.muc1.m-online.net', 'addr' => '88.217.206.29' }
        ];
my $test_routes2 = $ts->_extract_routes_from_traceroute($test_output2);
is_deeply($test_routes2, $expected2, 'traceroute output linux');
