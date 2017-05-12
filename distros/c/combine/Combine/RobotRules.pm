# Copyright (c) 2004 Anders Ardö
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# 			    NO WARRANTY
# 
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 

package Combine::RobotRules;

use strict;
use Combine::Config;
use Combine::UA;

sub new {
    my ($class) = @_;
    my $sv = Combine::Config::Get('MySQLhandle');
    my $self = {
        dbcon => $sv,
    };
    $self->{lockNotFound} = Combine::Config::Get('WaitIntervalRrdLockNotFound');
    $self->{lockSuccess} = Combine::Config::Get('WaitIntervalRrdLockSuccess');
    $self->{lockDefault} = Combine::Config::Get('WaitIntervalRrdLockDefault');
    $self->{operEmail} = Combine::Config::Get('Operator-Email');
    # Prepare handles for all SQL statements and save them in %{$self}
    $self->{Put} = $sv->prepare(qq{INSERT INTO robotrules SET netlocid=?, expire=?, rule=?;});
    $self->{Delete} = $sv->prepare(qq{DELETE FROM robotrules WHERE netlocid=?;});
    $self->{Get} = $sv->prepare(qq{SELECT expire,rule FROM robotrules WHERE netlocid=?;});

    bless $self, $class;
    return $self;
}

sub check {
    my ($self, $netlocId, $netlocStr, $urlPath) = @_;
#     print "start checking $netlocStr;$urlPath\n";
    my ($expire, $now);
#    return undef unless $url_str;
#Assumes all parameters correct
#replace with  select expire from robotrules where netlocid=124 AND LOCATE(rule,'/java/manual/test.jar')=1;??

    my @rules = ();
    ($expire,@rules) = get_rules($self, $netlocId);
    $now = time;
#    print "GETR: host=$netlocId; exp=$expire; now=$now\n" . join("\n",@rules);
    if ( defined($expire) && ($expire > $now) ) { 
	return &checkit($urlPath, @rules) . "\n";
    }
    my $url_robots = "http://$netlocStr/robots.txt";
#    print "Fetching $url_robots\n";
    my $ua = Combine::UA::TruncatingUserAgent();
    my $req = new HTTP::Request 'GET' => $url_robots;
    my $resp = $ua->request($req);
    if ($resp->is_success) {
	my $txt = $resp->decoded_content;
#	 print "robots.txt file\n$txt\n";
	@rules = &rule($txt);
	if ( $#rules == -1 ) { @rules = (''); }
	$expire = $now + $self->{lockSuccess};
    } elsif ($resp->code eq "404") {
	@rules = ('');
	$expire = $now + $self->{lockNotFound};
    } else { 
	@rules = ('');
	$expire = $now + $self->{lockDefault};
    }
#    print "PUTR: exp=$expire\n" . join("\n",@rules);
    put_rules($self, $netlocId, $expire, @rules);
    return &checkit($urlPath, @rules);
}

sub rule {
    my ($txt) = @_;
    return undef unless $txt;
    #    print $txt;
    my $ua;
    my $is_me = 0;              # 1 iff this record is for me
    my $is_anon = 0;            # 1 iff this record is for *
    my @me_disallowed = ();     # rules disallowed for me
    my @anon_disallowed = ();   # rules disallowed for *

    # blank lines are significant, so turn CRLF into LF to avoid generating
    # false ones
    $txt =~ s/\015\012/\012/g;

    # split at \012 (LF) or \015 (CR) (Mac text files have just CR for EOL)
    for(split(/[\012\015]/, $txt)) {

        # Lines containing only a comment are discarded completely, and
        # therefore do not indicate a record boundary.
        next if /^\s*\#/;

        s/\s*\#.*//;        # remove comments at end-of-line

        if (/^\s*$/) {      # blank line
            last if $is_me; # That was our record. No need to read the rest.
            $is_anon = 0;
        } elsif (/^\s*User-Agent\s*:\s*(.*)/i) {
            $ua = $1;
            $ua =~ s/\s+$//;
            if ($is_me) {
                # This record already had a User-agent that
                # we matched, so just continue.
            } elsif ($ua eq '*') {
                $is_anon = 1;
            } elsif(index('combine', lc($ua)) >= 0) {
                $is_me = 1;
            }
        } elsif (/^\s*Disallow\s*:?\s*(.*)/i) {
            unless (defined $ua) {
#                warn "RobotRules: Disallow without preceding User-agent\n";
                $is_anon = 1;  # assume that User-agent: * was intended
            }
            my $disallow = $1;
            $disallow =~ s/\s+$//;
            if ($is_me) {
                push(@me_disallowed, $disallow);
            } elsif ($is_anon) {
                push(@anon_disallowed, $disallow);
            }
        } #else { warn "RobotRules: Unexpected line: $_\n"; }
    }

    if ($is_me) {
        return @me_disallowed;
    } else {
        return @anon_disallowed;
    }
}

sub checkit {
    my($path, @rules) = @_; ##
#    $path = "/$path";
#    print "do RR check: $path\n" . join("\n",@rules);
#    if ( $#rules == -1 ) { return 1; } #TRUE
    for my $r (@rules) { 
	next if ( !defined($r) || ($r eq '') ); #uninitialized?
#	 print "check rule: R=$r P=$path\n";
#        if ( /^A:(.*)/ ) {
#	   return "allowed" if index($path, $1) == 0; 
#        } else {
#	   return "disallowed" if index($path, $r) == 0; 
	   return 0 if index($path, $r) == 0;  #FALSE
#        }
    }
#    return "allowed";
    return 1; #TRUE
}

sub get_rules {
    my ($self, $netloc) = @_;
    $self->{Get}->execute($netloc);
    my @rules;
    my ($e, $expire, $r);
    while ( ($e,$r)=$self->{Get}->fetchrow_array ) {
	push(@rules,$r); #Does order matter?
	$expire=$e; #otherwise value get lost
    }
    return ($expire, @rules);
}

sub put_rules {
    my ($self, $netloc, $expire, @rules) = @_;
    $self->{Delete}->execute($netloc);
    if ( $#rules == -1 ) { @rules=(''); }
    foreach my $r (@rules) {
	$self->{Put}->execute($netloc, $expire, $r);
    }
}

1;

__END__

=head1 NAME

RobotRules.pm

=head1 AUTHOR

Anders Ardo version 1.0 2004-02-19

=cut
