package VUser::Radius::Acct::SQL;
use warnings;
use strict;

# Copyright (c) 2007 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.2 2007/04/11 19:59:18 perlstalker Exp $

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ExtLib::SQL;
use VUser::Radius;
use VUser::ResultSet;
use VUser::Meta;

our $VERSION = '0.1.0';

our $log;
our %meta;
our $extlib;
our $c_sec = 'Extension Radius::Acct::SQL';

sub c_sec { return $c_sec; }
sub meta { return %meta; }
sub depends { qw(Radius::Acct); }

sub init {
    my $eh = shift;
    my %cfg = @_;

    %meta = VUser::Radius::Acct::meta();

    if (defined $main::log) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new(\%cfg, 'vuser')
    }
    
    $extlib = VUser::ExtLib::SQL->new(\%cfg,
                                      {'dsn' => $cfg{$c_sec}{'dsn'},
                                       'user' => $cfg{$c_sec}{'username'},
                                       'password' => $cfg{$c_sec}{'password'},
                                       'macros' => { 'u' => 'username',
                                                     'r' => 'realm',
                                                     'start' => 'starttime',
                                                     'end' => 'endtime',
                                       }
                                      }
                                     ); 

    $eh->register_task('radius', 'acct', \&radius_acct);
}

sub unload { };

sub radius_acct {
    my ( $cfg, $opts, $action, $eh ) = @_;

    my $phones = $opts->{'phones'};
    if (defined $phones) {
	$phones = join (',', map { "'$_'" } split(/\s*,\s*/, $phones));
	#$phones = join (',', split(/\s*,\s*/, $phones));

	$log->log(LOG_DEBUG, "Phones: $phones");
    }

    my $params = { 'phones' => $phones,
	       };

    if ($opts->{'report-type'} eq 'records') {
	return radius_acct_type_records($cfg, $opts, $action, $eh, $params);
    } else {
	return radius_acct_type_total_time($cfg, $opts, $action, $eh, $params);
    }
}

sub radius_acct_type_total_time {
    my ( $cfg, $opts, $action, $eh, $params ) = @_;

    my $query = 'acct_total_query';
    if (defined $params->{phones}) {
	$query = 'acct_total_phone_query';
    }

    my $sql = strip_ws($cfg->{$c_sec}{$query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
	$log->log(LOG_ERROR, "Unable to get session time: $@");
	die "Unable to get session time: $@\n";
    }

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'session-time'});
    $rs->add_meta($meta{'input-octets'});
    $rs->add_meta($meta{'output-octets'});

    my @result;
    while (@result = $sth->fetchrow_array) {
	$rs->add_data([@result[0,1,2]]);
    }

    return $rs;
}

sub radius_acct_type_records {
    my ( $cfg, $opts, $action, $eh, $params ) = @_;

    my $query = 'acct_records_query';
    if (defined $params->{phones}) {
	$query = 'acct_records_phone_query';
    }

    my $sql = strip_ws($cfg->{$c_sec}{$query});
    my $sth;
    eval { $sth = $extlib->execute($opts, $sql, $params); };
    if ($@) {
	$log->log(LOG_ERROR, "Unable to get session records: $@");
	die "Unable to get session records: $@\n";
    }

    my $rs = VUser::ResultSet->new();
    $rs->add_meta($meta{'username'});
    $rs->add_meta($meta{'realm'});
    $rs->add_meta($meta{'session-id'});
    $rs->add_meta($meta{'timestamp'});
    $rs->add_meta($meta{'nas-ip-address'});
    $rs->add_meta($meta{'session-time'});
    $rs->add_meta($meta{'input-octets'});
    $rs->add_meta($meta{'output-octets'});
    $rs->add_meta($meta{'framed-ip-address'});
    $rs->add_meta($meta{'called-station-id'});
    $rs->add_meta($meta{'calling-station-id'});

    my @result;
    while (@result = $sth->fetchrow_array) {
	$rs->add_data([@result[0..10]]);
    }

    return $rs;
}

1;


__END__

=head1 NAME

VUser::Radius::Acct::SQL - SQL support for the VUser::Radius::Acct vuser extension

=head1 DESCRIPTION

Adds support for reading RADIUS accounting information from a SQL database.

=head1 CONFIGURATION

 [vuser]
 extensions = Radius::Acct::SQL
 
 [Extension Radius::Acct::SQL]
 # Database driver to use.
 # The DBD::<driver> must exist or vuser will not be able to connect
 # to your database.
 # See perldoc DBD::<driver> for the format of this string for your database.
 dsn = DBI:mysql:database=Accounts;host=lachesis;post=3306
 
 # Database user name
 username = user
 
 # Database password
 # The password may not end with whitespace.
 password = pass
 
 ## SQL Queries
 # Here you define the queries used to add, modify and delete users and
 # attributes. There are a few predefined macros that you can use in your
 # SQL. The values will be quoted and escaped before being inserted into
 # the SQL.
 #  %u => username
 #  %r => realm
 #  %start => start time
 #  %end => end time
 #  %$phones => called station IDs, comma separated and quoted
 #  %-option => This will be replaced by the value of --option passed in
 #              when vuser is run.
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 total session time
 #   2 total input octets
 #   3 total output octets
 acct_total_phone_query = SELECT sum(acct_session_time),sum(acct_input_octets),sum(acct_output_octets) from Radius_sessions where status != 4 and username = %u and event_date_time >= %start and event_date_time <= %end and called_station_id IN (%$phones)
 
 acct_total_query = SELECT sum(acct_session_time),sum(acct_input_octets),sum(acct_output_octets) from Radius_sessions where status != 4 and username = %u and event_date_time >= %start and event_date_time <= %end
 
 # Here, we need a way to map columns to values
 # Fixed columns:
 #   1 username
 #   2 realm
 #   3 session id
 #   4 event timestamp
 #   5 NAS IP address
 #   6 session time
 #   7 input octets
 #   8 output octets
 #   9 framed IP address
 #  10 called station ID
 #  11 calling station ID
 acct_records_query = SELECT username, '', acct_session_id, event_date_time, nas_ip_address, acct_session_time, acct_input_octets, acct_output_octets, framed_ip_address, called_station_id, calling_station_id from Radius_sessions where status != 4 and username = %u and event_date_time >= %start and event_date_time <= %end
 
 acct_records_phone_query = SELECT username, '', acct_session_id, event_date_time, nas_ip_address, acct_session_time, acct_input_octets, acct_output_octets, framed_ip_address, called_station_id, calling_station_id from Radius_sessions where status != 4 and username = %u and event_date_time >= %start and event_date_time <= %end and called_station_id IN (%\phones)

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of VUser-Radius-Acct-SQL.
 
 VUser-Radius-Acct-SQL is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 VUser-Radius-Acct-SQL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with VUser-Radius-Acct-SQL; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
