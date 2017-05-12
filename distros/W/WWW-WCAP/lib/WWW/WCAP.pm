# WWW::WCAP
# Access to a WCAP-enabled calendar server
#
# $Id: WCAP.pm,v 0.1 2003/08/04 04:08:46 nate Exp $

=head1 NAME

WWW::WCAP - Access to a WCAP-enabled calendar server

=head1 SYNOPSIS

	# Should be OOP-based, not procedural...
	use WWW::WCAP qw(login do_request parse_ical logout);
	my $session_id = login($username,$password);
	my $ret = do_request($session_id, $wcap_command, @wcap_parameters);
	my $html = parse_ical($ret->content);
	my $ret = logout($session_id);

=head1 DESCRIPTION

Based on documentation provided in Sun ONE Calendar Server Programmer's
Manual, August 2002 (iCS 5.1.1 Programmer's Manual.pdf), see
http://docs.sun.com/prod/s1.s1cals for more details.

=over 4

=cut

package WWW::WCAP;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(login do_request parse_ical logout);

use strict;
use LWP::UserAgent;		# 'Fake' browser
use HTTP::Request::Common;	# For 'GET' primative
use HTTP::Cookies;		# Cookie jar for session
use Data::Dumper;		# For debugging
use Carp;			# For warning
use Date::Calc qw(Add_Delta_DHMS Date_to_Text_Long Today); # For parsing

###########################################################################
# Globals
use constant DEBUG_LOW => 1;		# minimal debug info
use constant DEBUG_MEDIUM => 2;		# moderate debug info
use constant DEBUG_HIGH => 3;		# verbose debug info
use constant DEBUG => DEBUG_MEDIUM;	# Debugging is ON/off
use constant CAL_SERVER => 'yourhost.example.com';
use constant GMT_DELTA => 11; # Don't forget to change for daylight savings :P

# Note -- the default is JavaScript.  You *really* don't want to try to
# parse the JavaScript.
my %response_formats = (
	ical => 'text/calendar',
	xml => 'text/xml',
	javascript => 'text/js',
);

# Response in ical format
my $fmt = 'fmt-out=' . $response_formats{'ical'};

my $ua = new LWP::UserAgent;
$ua->cookie_jar(HTTP::Cookies->new());

###########################################################################
# Methods and internal functions ##########################################
###########################################################################

=item login($username,$password)

Log in to the calendar server.  Returns a session ID.

=cut

sub login($$) {
	my ($user,$pass) = @_;
	my $response = $ua->request(GET 'http://' . CAL_SERVER .
		'/login.wcap?user=' .  $user . '&password= ' .$pass);
	my ($id) = $response->base =~ /id=([^\&]+)/;
	carp "WCAP: Login id is $id" if DEBUG > DEBUG_LOW;
	return $id;
} # end login
##########################################################################

=item do_request($session_id, $wcap_command, @wcap_parameters)

Send a WCAP request.  Returns a hashref of error status and contents.

NOTE: There is a limit to the number of characters that may be passed
in for each parameter. The limit per parameter is 1000 characters.
(p80 Sun ONE Calendar Server Programmer's Manual, August 2002)

=cut

sub do_request {
	my ($id,$command,@args) = @_;
	if (!defined $id || !defined $command) {
		warn "Missing parameter for do_request()" if DEBUG > DEBUG_LOW;
		die @_;
		return undef;
	}
	my $req = 'http://' . CAL_SERVER . '/' . $command . 
		'?id=' . $id;
	push(@args,$fmt); # Cheat for now, and add directly
	if (@args) {
		# Need to encode args...
		$req .= '&' . join('&', @args);
	}
	print "Fetching $req" if DEBUG > DEBUG_LOW;
	my $response = $ua->request(GET $req);
	return {
		status => $response->is_success,
		content => $response->content,
	};
} # end do_request
##########################################################################

=item parse_ical

Parse the iCal data returned (currently dumps it out as HTML).

=cut

sub parse_ical($) {
	my $content = shift;
	my %eventList;
	my @lines = split(/\n/, $content);
	while (my $line = shift @lines) {
		# Should use MIME::Parser, but doesn't seem to save us much...
		next unless $line =~ m/^BEGIN:VEVENT/;
		my %event;
		my $continuing_line = "";
		while (my $line = shift @lines) {
			last if $line =~ m/^END:VEVENT/;
			chomp $line;
			$line =~ s/\r//;
			my $foo = 0;
			$foo = 1 if $line =~ /CAT/;
			if ($line =~ /^ (.*)/) { # A continuing line
				$continuing_line .= $1;
				next;
			}
			if ($continuing_line ne "") { # We don't know if there are continuing
					   # lines until there are/aren't...
				if (my ($field,$data) = $continuing_line =~ /^([A-Z]+):(.*)/) {
					$event{$field} = $data;
				} else {
					#carp "Couldn't understand line: $continuing_line";
				}
			}
			$continuing_line = $line;
		}
		if ($continuing_line ne "") { # Catch the last line
			if (my ($field,$data) = $continuing_line =~ /^([A-Z]+):(.*)/) {
				$event{$field} = $data;
			} else {
				#carp "Couldn't understand line: $continuing_line";
			}
		}
		#use Data::Dumper;
		#print Dumper(\%event);
		my ($date,$start_time,$end_time,$requestor,$status,$description);
		if (my ($yy, $mm, $dd, $hrs, $mins, $secs) = $event{'DTSTART'} =~ /(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z/) {
			my ($year,$month,$day, $hour,$min,$sec) = Add_Delta_DHMS($yy,$mm,$dd, $hrs,$mins,$secs, 0, GMT_DELTA, 0, 0);
			$date = sprintf("%4.4d-%2.2d-%2.2d", $year, $month,$day);
			$start_time = sprintf("%2.2d:%2.2d", $hour, $min);
			if (my ($d_hrs, $d_mins, $d_secs) = $event{'DURATION'} =~ /P0DT(\d+)H(\d+)M(\d+)S/) {
				my ($year,$month,$day, $hour,$min,$sec) = Add_Delta_DHMS($yy,$mm,$dd, $hrs,$mins,$secs, 0, $d_hrs + GMT_DELTA, $d_mins, $d_secs);
				$end_time = sprintf("%2.2d:%2.2d", $hour, $min);
			} else {
				# Daily events don't have durations...
				carp "Couldn't parse duration: ($event{'DURATION'}) for $event{'SUMMARY'}" if $event{'CATEGORIES'} ne 'DAILY NOTE' && $event{'CATEGORIES'} ne 'DAY EVENT'  && $event{'CATEGORIES'} ne 'HOLIDAY';
			}
		} else {
			carp "Couldn't parse date/time: $event{'DTSTART'}";
		}
		carp "Not an appointment, daily note, day event or holiday: $event{'CATEGORIES'}" if $event{'CATEGORIES'} ne "APPOINTMENT" && $event{'CATEGORIES'} ne 'DAILY NOTE' && $event{'CATEGORIES'} ne 'DAY EVENT' && $event{'CATEGORIES'} ne 'HOLIDAY';

		if (my ($first,$last) = $event{'ORGANIZER'} =~ /mailto:(.*)\.(.*)\@/) {
			$requestor = " ($first $last)";
			$requestor = "" if $requestor eq " (Nathan Bailey)";
		} else {
			#carp "Couldn't parse requestor: $event{'ORGANIZER'} for $event{'SUMMARY'}" if $event{'CATEGORIES'} ne 'HOLIDAY';
		}
		# Big time cheat for now...
		if (1 || $event{'CATEGORIES'} eq "APPOINTMENT") {
			#carp "Not confirmed" if $event{'STATUS'} ne "CONFIRMED";
			my $location = "";
			if (defined $event{'LOCATION'} && $event{'LOCATION'} ne "") {
				$location = " [$event{'LOCATION'}]";
				$location =~ s#\\##g;
			}
			$eventList{$date.'_'.$start_time.'_'.$event{'SUMMARY'}} = "($start_time-$end_time) $event{'SUMMARY'}$requestor$location\n";
		} elsif ($event{'CATEGORIES'} eq 'DAILY NOTE') {
			$eventList{$date.'_dailynote_'.$event{'SUMMARY'}} = "<b>Note:</b> $event{'SUMMARY'}$requestor\n";
		}
	}

	my $prev = "";
	my ($t_year,$t_month,$t_day) = Today();
	my $today = 0;
	my @k = keys %eventList;
	print "<p><small>Current as at: ".`/bin/date`."</small></p>" if $#k >= 0;
	foreach my $e (sort @k) {
		my ($date,$start_time,$summary) = split(/_/,$e);
		if ($date ne $prev) {
			print "</ul>\n";
			if ($today) {
				print '</td></tr></table>';
				$today = 0;
			}
			my ($year, $month, $day) = split(/-/,$date);
			my $pretty_day = Date_to_Text_Long($year, $month, $day);
			$pretty_day =~ s/ $year//;
			print "<h3>$pretty_day</h3>\n";
			if (!$today && $day == $t_day && $month == $t_month && $year == $t_year) {
				print '<table><tr><td bgcolor="#00FF00">';
				$today = 1;
			}
			$prev = $date;
			print "<ul>\n";
		}
		print "<li> $eventList{$e}";
	}
	if ($prev eq "") { # Blank calendar...
		print "<h3>No events available</h3>";
	} else {
		print "</ul>\n"
	}
} # end parse_ical
##########################################################################

=item logout($session_id)

Log in to the calendar server.  Returns a session ID.

=cut

sub logout($) {
	my $id = shift;
	return do_request($id,'logout.wcap');
} # end logout
##########################################################################

1;

__END__

=back

=head1 BUGS

None known at this point.

=head1 SEE ALSO

...

=head1 AUTHOR

Nathan Bailey, E<lt>nate@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 Nathan Bailey.  All rights reserved.  This module
is free software you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the
Free Software Foundation either version 1, or (at your option) any
later version.

=cut
