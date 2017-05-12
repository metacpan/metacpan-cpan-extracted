package VUser::Firewall::iptables;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: iptables.pm,v 1.1 2006/01/04 18:45:40 perlstalker Exp $

use File::Temp;
use File::Copy;
use VUser::ExtLib qw(:config :ssh :files);
use VUser::Log qw(:levels);

my $log;
my %meta;

my $VERSION = '0.1.0';
my $c_sec = 'Extension Firewall::iptables';

my $def_chain; # Default chain to operate on
my %hosts;     # List of hosts

sub depends { return qw(Firewall); }

sub init
{
    my $eh = shift;
    my %cfg = @_;

    %meta = %VUser::Firewall::meta;
    $log = $main::log;

    $def_chain = strip_ws($cfg{$c_sec}{'default chain'}) || 'FIREWALL';
    $log->log(LOG_DEBUG, "Setting default chain to %s", $def_chain);

    $meta{'chain'} = VUser::Meta->new('name' => 'chain',
				      'type' => 'string',
				      'description' => sprintf('Chain to add rules to. Default: %s', $def_chain)
				      );

    foreach my $section (grep { /^$c_sec-(.+)$/o } keys %cfg) {
	my $host = $section;
	$host =~ s/^$c_sec-(.+)$/$1/;
	$log->log(LOG_DEBUG, "Checking section: %s. Host=%s", $section, $host);
	next if check_bool($cfg{$section}{skip});
	$hosts{$host} = {};
	foreach my $key ('file', 'host', 'user', 'ssh key',
			 'restart') {
	    my $tmp = strip_ws($cfg{$section}{$key});
	    $hosts{$host}{$key} = $tmp if $tmp;
	}

	if (not $hosts{$host}{file}) {
	    $log->log(LOG_NOTICE, "No file specified for $host. Skipping.");
	    delete $hosts{$host};
	}
    }

    foreach my $action ('block', 'unblock', 'allow', 'unallow') {
	$eh->register_option('firewall', $action, $meta{'chain'});
    }

    $eh->register_task('firewall', 'block', \&fw_blockallow);
    $eh->register_task('firewall', 'allow', \&fw_blockallow);
    $eh->register_task('firewall', 'unblock', \&fw_unblockallow);
    $eh->register_task('firewall', 'unallow', \&fw_unblockallow);
    $eh->register_task('firewall', 'restart', \&fw_restart);

    if (check_bool($cfg{$VUser::Firewall::c_sec}{'auto restart'})) {
	foreach my $action ('block', 'unblock', 'allow', 'unallow') {
	    $eh->register_task('firewall', $action, \&fw_restart);
	}
    }
}

sub fw_blockallow
{
    my ($cfg, $opts, $action, $eh) = @_;

    if (not $opts->{source}
	and not $opts->{sport}
	and not $opts->{destination}
	and not $opts->{dport}
	) {
	die "One of source, destination, sport or dport must be sepcified.\n";
    }

    my $cmd = 'iptables';

    $cmd .= sprintf(' -A %s', $opts->{chain}? $opts->{chain} : $def_chain);
    $cmd .= sprintf(' -s %s', $opts->{source}) if ($opts->{source});
    $cmd .= sprintf(' --sport %s', $opts->{sport}) if ($opts->{sport});
    $cmd .= sprintf(' -d %s', $opts->{destination}) if ($opts->{destination});
    $cmd .= sprintf(' --dport %s', $opts->{dport}) if ($opts->{dport});
    $cmd .= sprintf(' -p %s', $opts->{protocol}) if $opts->{protocol};
    if ($action eq 'allow') {
	$cmd .= ' -j ACCEPT';
    } elsif ($action eq 'block') {
	$cmd .= ' -j REJECT';
    }

    $log->log(LOG_NOTICE, "Sending %s", $cmd);

    foreach my $host (keys %hosts) {
	$log->log(LOG_NOTICE, "Updating firewall on %s", $host);
    
	my $file = $hosts{$host}->{file};
	$file =~ s!/?([^/]+)$!$1!; # Rip the path off the file name

	my $local_file = File::Temp::tempnam('/tmp', 'VUser-Firewall-iptables-');
	$log->log(LOG_DEBUG, "Tmp file is %s", $local_file);
	if ($hosts{$host}->{host}) {
	    get_file_scp($hosts{$host}->{user},
			 $hosts{$host}->{host},
			 $hosts{$host}->{'ssh key'},
			 $hosts{$host}->{file},
			 $local_file);
	} else {
	    copy($hosts{$host}->{file}, $local_file);
	    touch($local_file) unless (-e $local_file);
	}

	add_line_to_file($local_file, $cmd);

	if ($hosts{$host}->{user}) {
	    send_file_scp($hosts{$host}->{user},
			  $hosts{$host}->{host},
			  $hosts{$host}->{'ssh key'},
			  $local_file,
			  $hosts{$host}->{file}
			  );
	} else {
	    copy($local_file, $hosts{$host}->{file});
	}

	unlink $local_file;
    }
}

sub fw_unblockallow
{
    my ($cfg, $opts, $action, $eh) = @_;

    if (not $opts->{source}
	and not $opts->{sport}
	and not $opts->{destination}
	and not $opts->{dport}
	) {
	die "One of source, destination, sport or dport must be sepcified.\n";
    }

    foreach my $host (keys %hosts) {
	$log->log(LOG_NOTICE, "Updating firewall on %s", $host);
    
	my $file = $hosts{$host}->{file};
	$file =~ s!/?([^/]+)$!$1!; # Rip the path off the file name

	my $local_file = File::Temp::tempnam('/tmp', 'VUser-Firewall-iptables-');

	if ($hosts{$host}->{host}) {
	    get_file_scp($hosts{$host}->{user},
			 $hosts{$host}->{host},
			 $hosts{$host}->{'ssh key'},
			 $hosts{$host}->{file},
			 $local_file);
	} else {
	    copy($hosts{$host}{file}, $local_file);
	}

	# Pull the rule(s) out of the file
	open ORIG, $local_file or die "Can't open $local_file: $!\n";
	open NEW, ">$local_file.new" or die "Can't open $local_file.new: $!\n";

	while (my $line = <ORIG>) {
	    chomp $line;

	    my $match = 0;
	    my $test = 0;
	    if ($opts->{source}) {
		$test++;
		$log->log(LOG_DEBUG, "Testing source ($test)");
		if ($line =~ m{\s(?:-s|--source)        # source flag
				   [ =]?\s*             # spaces or =
				   \Q$opts->{source}\E  # The addr to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches source %d/%d",
			      $match, $test);
		}
	    }

	    if ($opts->{destination}) {
		$test++;
		$log->log(LOG_DEBUG, "Testing dest");
		if ($line =~ m{\s(?:-d|-destination)    # dst flag
				   [ =]?\s*             # spaces or =
				   \Q$opts->{source}\E  # The addr to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches dest %d/%d",
			      $match, $test);
		}
	    }

	    if ($opts->{sport}) {
		$test++;
		$log->log(LOG_DEBUG, "Testing sport");
		if ($line =~ m{\s(?:--sport|--source-port)
				   [ =]?\s*             # spaces or =
				   \Q$opts->{sport}\E   # The addr to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches sport %d/%d",
			      $match, $test);
		}
	    }

	    if ($opts->{dport}) {
		$test++;
		$log->log(LOG_DEBUG, "Testing dport");
		if ($line =~ m{\s(?:--dport|--destination-port)
				   [ =]?\s*             # spaces or =
				   \Q$opts->{dport}\E   # The addr to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches dport %d/%d",
			      $match, $test);
		}
	    }

	    if ($opts->{protocol}) {
		$test++;
		$log->log(LOG_DEBUG, "Testing protocol");
		if ($line =~ m{\s(?:-p|--protocol)      # source flag
				   [ =]?\s*             # spaces or =
				   \Q$opts->{protocol}\E# The proto to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches protocol %d/%d",
			      $match, $test);
		}
	    }

	    if ($action eq 'block'
		or $action eq 'unblock'
		) {
		$test++;
		$log->log(LOG_DEBUG, "Testing REJECT");
		if ($line =~ m{\s(?:-j|--jump)
				   [ =]?\s*             # spaces or =
				   REJECT               # The rule to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches REJECT %d/%d",
			      $match, $test);
		}
	    }

	    if ($action eq 'accept'
		or $action eq 'unaccept'
		) {
		$test++;
		$log->log(LOG_DEBUG, "Testing ACCEPT");
		if ($line =~ m{\s(?:-j|--jump)
				   [ =]?\s*             # spaces or =
				   ACCEPT               # The rule to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches ACCEPT %d/%d",
			      $match, $test);
		}
	    }

	    my $chain = $opts->{chain} || $def_chain;

	    if ($chain) {
		$test++;
		$log->log(LOG_DEBUG, "Testing chain %s", $chain);
		if ($line =~ m{\s(?:-A|--append)        # source flag
				   [ =]?\s*             # spaces or =
				   \Q$chain\E           # The chain to match
				   (?:\s|$ )            # end of pattern
			       }x
		    ) {
		    $match++;
		    $log->log(LOG_DEBUG, "Rule matches chain %d/%d",
			      $match, $test);
		}
	    }

	    $log->log(LOG_DEBUG, "Line (%d/%d): %s", $match, $test, $line);

	    # The line didn't match in all the tests, let it through.
	    print NEW "$line\n" if $match != $test;
	    #print STDERR "Printing matches\n";
	    #print STDERR "$line\n" if $match != $test;
	}

	close NEW;
	close ORIG;

	rename("$local_file.new", $local_file);

	if ($hosts{$host}{user}) {
	    send_file_scp($hosts{$host}->{user},
			  $hosts{$host}->{host},
			  $hosts{$host}->{'ssh key'},
			  $local_file,
			  $hosts{$host}->{file}
			  );
	} else {
	    copy($local_file, $hosts{$host}{file});
	}

	if ($main::DEBUG) {
	    $log->log(LOG_DEBUG, "Debug mode: preserving $local_file.new\n");
	} else {
	    unlink $local_file, "$local_file.new";
	}
    }
}

sub fw_restart
{
    my ($cfg, $opts, $action, $eh) = @_;

    foreach my $host (keys %hosts) {
	$log->log(LOG_NOTICE, "Restarting firewall on %s", $host);
	run_cmd_ssh($hosts{$host}->{user}, $hosts{$host}->{host}, $hosts{$host}->{'ssh key'},
		    $hosts{$host}->{restart});
    }
}

1;

__END__


=head1 NAME

VUser::Firewall::iptables - vuser extension for modifying iptables

=head1 DESCRIPTION

Writes a script containing given iptables rules. This script is not run
unless the I<firewall|reload> action is given or
I<Extension Firewall:auto reload> is set.

=head1 CONFIGURATION

 [vuser]
 extensions = Firewall::iptables
 
 [Extension Firewall::iptables]
 # Update multiple hosts in parellel
 fork = yes
 
 # The default chain to work on.
 default chain = FIREWALL
 
 [Extension Firewall::iptables-firewall1]
 # Skip this firewall
 skip = no
 
 # The path to the script to write.
 file = /etc/rc.d/rc.firewall
 
 # IP (or hostname) of the firewall to update. Comment out to modify
 # a local firewall.
 host = 192.168.1.1

 # SSH user to connect as. This user must also have permissions to write
 # the firewall script ('file' above) on the firewall
 user = root
 
 # The user's private ssh key. The public key must be added to the user's
 # .ssh/authorized_keys file.
 ssh key = /path/to/private_id.dsa

 # Restart command. The user specified above must have permission to run
 # this command. 
 restart = /etc/rc.d/rc.firewall
 
=cut

 # If you have other rules that you don't
 # want vuser to trample on, you can use a template that contains those
 # rules or you can include the given file in your main script.
 file = ...

 # Use a template for this host.
 # Template variables are:
 #  $warning                   - do not edit warning
 #  @rules                     - the generated firewall rules
 #  @rules_hash                - a list of rules with attributes split out
 #                               for easy use in writing custom rules
 use template = no
 template = /path/to/template

=pod 

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

