# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-NationalRail.t'

use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 18;

BEGIN { use_ok('WWW::NationalRail') };

my ($rail, $outward_summary, $return_summary, $outward_detail, $return_detail,
    $expect);

my $tomorrow = sprintf (
	"%02d/%02d/%02d", sub {($_[3]+1, $_[4]+1, $_[5]%100)}->(localtime)
);

can_ok("WWW::NationalRail", qw(from to via out_date out_type out_hour
    out_minute ret_date ret_type ret_hour ret_minute outward_summary
    return_summary outward_detail return_detail error));

# tests against the live system
# one-way
ok ( $rail = WWW::NationalRail->new({
	from		=> 'London',
	to			=> 'Cambridge',
	out_date	=> $tomorrow,
	out_type	=> 'depart',
	out_hour	=> 9,
	out_minute	=> 0,
}), "constuctor");

$rail->_no_form_warnings();

$rail->{_summary} = readfile ("t/data/oneway_summary.html");
$rail->_parseSummary();
$rail->{_detail} = readfile ("t/data/oneway_detail.html"),
$rail->_parseDetail();

ok ($outward_summary = $rail->outward_summary, "outward summary");
is ($rail->return_summary, undef, "return summary");
ok ($outward_detail = $rail->outward_detail, "outward detail");
is ($rail->return_detail, undef, "return detail");

$expect = [
    {
        'changes' => '0',
        'depart' => '09:06',
        'duration' => '1:19',
        'arrive' => '10:25'
    },
    {
        'changes' => '0',
        'depart' => '09:15',
        'duration' => '0:46',
        'arrive' => '10:01'
    },
    {
        'changes' => '0',
        'depart' => '09:19',
        'duration' => '1:18',
        'arrive' => '10:37'
    },
    {
        'changes' => '0',
        'depart' => '09:45',
        'duration' => '0:45',
        'arrive' => '10:30'
    },
    {
        'changes' => '0',
        'depart' => '09:51',
        'duration' => '1:01',
        'arrive' => '10:52'
    }
];
is_deeply($outward_summary, $expect, "outward summary matches expected return value");

$expect = [
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:06',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:25'
                        }
                      ],
            'duration' => '1:19'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:15',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:01'
                        }
                      ],
            'duration' => '0:46'
          },
          {
            'legs' => [
                        {
                          'operator' => 'ONE RAILWAY',
                          'station' => 'LONDON LIVERPOOL STREET',
                          'travelby' => 'Train',
                          'depart' => '09:19',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:37'
                        }
                      ],
            'duration' => '1:18'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:45',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:30'
                        }
                      ],
            'duration' => '0:45'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:51',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:52'
                        }
                      ],
            'duration' => '1:01'
          }
        ];
is_deeply($outward_detail, $expect, "outward detail matches expected return value");

# return
ok ( $rail = WWW::NationalRail->new({
	from		=> 'London',
	to			=> 'Cambridge',
	out_date	=> $tomorrow,
	out_type	=> 'depart',
	out_hour	=> 9,
	out_minute	=> 0,
	ret_date	=> $tomorrow,
	ret_type	=> 'depart',
	ret_hour	=> 17,
	ret_minute	=> 0,
}), "constuctor");

$rail->{_summary} = readfile ("t/data/return_summary.html");
$rail->_parseSummary();
$rail->{_detail} = readfile ("t/data/return_detail.html"),
$rail->_parseDetail();

ok ($outward_summary = $rail->outward_summary, "outward summary");
ok ($return_summary = $rail->return_summary, "return summary");
ok ($outward_detail = $rail->outward_detail, "outward detail");
ok ($return_detail = $rail->return_detail, "return detail");

$expect = [
          {
            'changes' => '0',
            'depart' => '09:06',
            'duration' => '1:19',
            'arrive' => '10:25'
          },
          {
            'changes' => '0',
            'depart' => '09:15',
            'duration' => '0:46',
            'arrive' => '10:01'
          },
          {
            'changes' => '0',
            'depart' => '09:19',
            'duration' => '1:18',
            'arrive' => '10:37'
          },
          {
            'changes' => '0',
            'depart' => '09:45',
            'duration' => '0:45',
            'arrive' => '10:30'
          },
          {
            'changes' => '0',
            'depart' => '09:51',
            'duration' => '1:01',
            'arrive' => '10:52'
          }
        ];
is_deeply($outward_summary, $expect, "outward summary matches expected return value");
$expect = [
          {
            'changes' => '0',
            'depart' => '17:05',
            'duration' => '1:09',
            'arrive' => '18:14'
          },
          {
            'changes' => '0',
            'depart' => '17:15',
            'duration' => '0:48',
            'arrive' => '18:03'
          },
          {
            'changes' => '0',
            'depart' => '17:31',
            'duration' => '1:00',
            'arrive' => '18:31'
          },
          {
            'changes' => '0',
            'depart' => '17:34',
            'duration' => '1:21',
            'arrive' => '18:55'
          },
          {
            'changes' => '0',
            'depart' => '17:45',
            'duration' => '0:49',
            'arrive' => '18:34'
          }
        ];
is_deeply($return_summary, $expect, "return summary matches expected value");
$expect = [
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:06',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:25'
                        }
                      ],
            'duration' => '1:19'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:15',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:01'
                        }
                      ],
            'duration' => '0:46'
          },
          {
            'legs' => [
                        {
                          'operator' => 'ONE RAILWAY',
                          'station' => 'LONDON LIVERPOOL STREET',
                          'travelby' => 'Train',
                          'depart' => '09:19',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:37'
                        }
                      ],
            'duration' => '1:18'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:45',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:30'
                        }
                      ],
            'duration' => '0:45'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => 'Train',
                          'depart' => '09:51',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '10:52'
                        }
                      ],
            'duration' => '1:01'
          }
        ];
is_deeply($outward_detail, $expect, "outward detail matches expected value");
$expect = [
          {
            'legs' => [
                        {
                          'operator' => 'ONE RAILWAY',
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => 'Train',
                          'depart' => '17:05',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'LONDON LIVERPOOL STREET',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '18:14'
                        }
                      ],
            'duration' => '1:09'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => 'Train',
                          'depart' => '17:15',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '18:03'
                        }
                      ],
            'duration' => '0:48'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => 'Train',
                          'depart' => '17:31',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '18:31'
                        }
                      ],
            'duration' => '1:00'
          },
          {
            'legs' => [
                        {
                          'operator' => 'ONE RAILWAY',
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => 'Train',
                          'depart' => '17:34',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'LONDON LIVERPOOL STREET',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '18:55'
                        }
                      ],
            'duration' => '1:21'
          },
          {
            'legs' => [
                        {
                          'operator' => 'WAGN RAIL',
                          'station' => 'CAMBRIDGE STATION',
                          'travelby' => 'Train',
                          'depart' => '17:45',
                          'arrive' => undef
                        },
                        {
                          'operator' => undef,
                          'station' => 'LONDON KINGS CROSS',
                          'travelby' => undef,
                          'depart' => undef,
                          'arrive' => '18:34'
                        }
                      ],
            'duration' => '0:49'
          }
        ];
is_deeply($return_detail, $expect, "return detail matches expected value");

sub readfile {
    my ($filename) = shift;
    local $/ = undef;
    open FILE, $filename or die "can't open '$filename' for read: $!";
    my $content = <FILE>;
    close FILE;
    return $content;
}

# vim:ft=perl
