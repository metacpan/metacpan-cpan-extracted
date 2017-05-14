package VUser::SOAP;
use warnings;
use strict;

# Copyright (c) 2006 Randy Smith
# $Id: SOAP.pm,v 1.10 2007/09/19 19:16:25 perlstalker Exp $

use Data::Dumper;

use VUser::Log qw(:levels);
use VUser::ExtLib qw(:config);
use VUser::ExtHandler;
use VUser::ACL;
use VUser::Meta;
use Digest::MD5 qw(md5);
my $eh;
my $log;
my $cfg;
my $acl;
my $debug = 0;

my $c_sec = 'vsoapd';

my %sessions = ();

sub init {
    $cfg = shift;
    
    $eh = VUser::ExtHandler->new($cfg);
    $eh->load_extensions(%$cfg);
    
    if (ref $main::log and UNIVERSAL::isa($main::log, 'VUser::Log')) {
        $log = $main::log;
    } else {
        $log = VUser::Log->new($cfg, 'VUser::SOAP');
    }
    
    if (defined $main::DEBUG) {
        $debug = $main::DEBUG;
    }
    
    ## Load up the ACL and auth info
    $acl = new VUser::ACL ($cfg);
    $acl->load_auth_modules($cfg);
    $acl->load_acl_modules($cfg);
    
    return;
}

sub Log { $log->log(@_); }

sub login {
    my $user = shift;
    my $password = shift;
    my $ip = shift;
    
    $log->log(LOG_DEBUG, "In ::SOAP::login");
    
    if (check_bool($cfg->{$c_sec}{'require_authentication'})) {
        if (not $acl->auth_user($cfg, $user, $password, $ip)) {
            if ($debug) {
                $log->log(LOG_NOTICE, "Authentication failed for $user\@$ip [$password]");
            } else {
                $log->log(LOG_NOTICE, "Authentication failed for $user\@$ip");
            }
            return undef;
        }
    }
    
    # Expire old sessions
    clean_sessions();
    
    my ($ticket, $expr);
    
    my $timeout = strip_ws($cfg->{$c_sec}{'ticket lifetime'});
    # Default to 10 minutes if timeout is not a valid number 
    $timeout = 10 unless defined $timeout and $timeout =~ /^\d+(?:\.\d+)$/;

    $log->log(LOG_DEBUG, "Doing login");
    
    $expr = time() + 60 * $timeout;
    $ticket = calculate_ticket($user, $ip, $expr);
    $sessions{$ticket} = {user => $user, ip => $ip, expires => $expr};
    return $ticket;
}

sub check_ticket {
    my $ticket = shift;

    # I need to be able to check the binary ticket as well as the ticket
    # converted to a hex string.
    
    if (not defined $sessions{$ticket}
        or $sessions{$ticket}{expires} > time()
        ) {
        $log->log(LOG_NOTICE, "Invalid ticket");
        delete $sessions{$ticket};
        return 0;
    } else {
        my $timeout = strip_ws($cfg->{$c_sec}{'ticket lifetime'});
        # Default to 10 minutes if timeout is not a valid number 
        $timeout = 10 unless defined $timeout and $timeout =~ /^\d+(?:\.\d+)$/;
        
        $sessions{$ticket}{expires} = time() + 60 * $timeout;
    }
    
    return 1;
}

sub calculate_ticket {
    return md5(join '', $cfg->{$c_sec}{'digest key'}, map { defined $_? $_ : '' } @_);
}

sub run_tasks {
    my $ticket = shift;
    my $keyword = shift;
    my $action = shift;
    my $env = pop;
    my $body = $env->body;
    #use Data::Dumper; print Dumper $body;
    my %opts = ();
    if (defined  $body->{$keyword.'_'.$action}
        and ref $body->{$keyword.'_'.$action} eq 'HASH'
        ) {
        %opts = %{ $body->{$keyword.'_'.$action} };
    }
   
    my $user = $sessions{$ticket}{user};
    my $ip = $sessions{$ticket}{ip};
    
    # We need to translate the SOAP::Data params into a hash
    # suitable for ::ExtHandler->run_tasks.
    #my %opts = build_opts(@params);
    
    $log->log(LOG_DEBUG, '%opts => '.Dumper(\%opts));
    
    if (check_bool($cfg->{$c_sec}{'require authentication'})) {
        # Do all of the ACL checks.
        eval {check_acls($cfg, $user, $ip, $keyword, $action, \%opts) };
        # FAULT if a check fails
        # VUser::ACL logs the reason so we don't need to log it here.
        die SOAP::Failt
            ->faultcode('Server.Custom')
            ->faultstring('Permission denied') if $@;
    }
    
    # We've passed all of the ACL checks. Run the task.
    my $rs = [];
    $log->log(LOG_NOTICE, "%s\@%s running %s | %s",
	      defined $user? $user : 'undef',
	      defined $ip? $ip : 'undef',
	      defined $keyword? $keyword : 'undef',
	      defined $action? $action : 'undef');
    eval { $rs = $eh->run_tasks($keyword, $action, $cfg, %opts); };
    if ($@) {
	   die SOAP::Fault
	       ->faultcode('Server.Custom')
	       ->faultstring($@)
	       ;
    }

    return $rs;
};

sub clean_sessions {
    my $now = time();
    foreach my $ticket (keys %sessions) {
        if (defined $sessions{$ticket}{expires}
	    and $sessions{$ticket}{expires} > $now)
	{
	    delete $sessions{$ticket} 
	}
    }
}

sub check_acls {
    my $user = shift;
    my $ip = shift;
    my $keyword = shift;
    my $action = shift;
    my $opts = shift;

    # Check ACLs
    if (not $acl->check_acls($cfg, $user, $ip, $keyword)) {
	   $log->log(LOG_NOTICE, "Permission denined for %s: %s",
		         $user, $keyword);
	   die "Permission denied for $user on $keyword";
    }

    if ($action
	    and not $acl->check_acls($cfg, $user, $ip, $keyword, $action)) {
	   $log->log(LOG_NOTICE, "Permission denied for %s: %s %s",
		         $user, $keyword, $action);
	   die "Permission denied for $user on $keyword - $action";
    }

    if ($action and $opts) {
	   foreach my $key (keys %$opts) {
	       if (not $acl->check_acls($cfg,
			                	    $user, $ip,
				                    $keyword, $action,
				                    $key, $opts->{$key}
				                    )
			   ) {
                $log->log(LOG_NOTICE, "Permission denied for %s: %s %s - %s",
			                 $user, $keyword, $action, $key);
		        die "Permission denied for $user on $keyword - $action - $key";
            }
        }
    }

    return 1;
}

sub get_keywords {
    my $authinfo = shift;
    
    my @keywords = ();
    foreach my $key ($eh->get_keywords()) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg, $authinfo->{'user'}, $authinfo->{'ip'}, $key); };
            next if ($@);
        }
        if ($key eq 'config' || $key eq 'help' || $key eq 'man') {
            next;
        }
        push @keywords, { keyword => $key,
                          description => $eh->get_description($key) };
    }
    #print "Keywords: "; use Data::Dumper; print Dumper \@keywords;
    return @keywords;
}

sub get_actions {
    my $authinfo = shift;
    my $keyword = shift;
    
    my @actions = ();
    foreach my $act ($eh->get_actions($keyword)) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg, $authinfo->{'user'}, $authinfo->{'ip'}, $keyword, $act); };
            next if ($@);
        }
        
        push @actions, {action => $act,
                        description => $eh->get_description($keyword, $act) };
    }
    
    return @actions;
}

sub get_options {
    my $authinfo = shift;
    my $keyword = shift;
    my $action = shift;
    
    my @options = ();
    $log->log(LOG_DEBUG, "Getting options for %s | %s", $keyword, $action);
    foreach my $opt ($eh->get_options($keyword, $action)) {
        if (check_bool($cfg->{$c_sec}{'require authentication'})) {
            eval { $acl->check_acls($cfg,
                                    $authinfo->{'user'},
                                    $authinfo->{'ip'},
                                    $keyword, $action, $opt); };
            next if $@;
        }
        
        $log->log(LOG_DEBUG, "Sending option $opt");
        
        my @meta = $eh->get_meta($keyword, $opt);
        push @options, { option => $opt,
                         description => $eh->get_description($keyword, $action, $opt),
                         required => $eh->is_required($keyword, $action, $opt),
                         type => $meta[0]->type() };
    }
    #use Data::Dumper; print Dumper \@options;
    return @options;
}

sub build_opts {
    my $env;
    if (ref $_[-1] and UNIVERSAL::isa($_[-1], "SOAP::SOM")) {
        $env = pop @_;
    }
    my @params = @_;
    my %opts = ();
    
    foreach my $param (@params) {
        $opts{$param->name()} = $param->value();
	$log->log(LOG_DEBUG, "Param: %s => %s", $param->name(),
		  defined ($param->value())? $param->value() : 'undef');
    }
    
    return %opts;
}

sub cleanup {
    eval { $eh->cleanup($cfg); };
}

sub conf {
    my $section = shift;
    my $key = shift;
    return $cfg->{$section}{$key};
}

sub rs2soap {
    my @result_sets = shift;
    
    my @records = ();
    foreach my $record (@result_sets) {
        
        my @soap_rs = ();
        foreach my $rs (@$record) {
            my @meta = $rs->get_metadata();
            my (@cols, @types); 
            foreach my $meta (@meta) {
                push @cols, $meta->name();
                push @types, $meta->type();
            }
            ## Set columns
            # It would be really nice to set the name space globally.
            my $columns = SOAP::Data->name('columns' =>
                \SOAP::Data->name('item' => @cols)->type('string')
                );
            $log->log(LOG_DEBUG, "Creating ColumnArray");
            $columns->type('tns:ColumnArray');
            #$columns->type('ArrayOf_string');
            
            ## Set types
            my $types = SOAP::Data->name('types' =>
                \SOAP::Data->name('item' => @types)->type('string')
                );
            $log->log(LOG_DEBUG, "Creating TypeArray");
            $types->type('tns:TypeArray');
            #$types->type('ArrayOf_string');
            
            ## Set values            
            my @table = $rs->results();
            my @vals = ();
            $log->log(LOG_DEBUG, "Creating ValueArray");
            foreach my $row (@table) {
                # Force conversion of values to strings
                #my @entries = map { SOAP::Data->value($_)->type('string'); } @$row;
                
                # Put strings is a 'ValueArray'
                #push @vals, SOAP::Data->value(@entries)->type('tns:ValueArray');
                # Convert undefs to ''
                my @clean_row = map { defined $_? $_ : 'undef'; } @$row;
                push @vals, SOAP::Data->value(
                    \SOAP::Data->name('item' => @clean_row)->type('string')
                    );
            }
            my $values = SOAP::Data->name('values' =>
                \SOAP::Data->name('item' => @vals)->type('tns:ValueArray')
                );
            $log->log(LOG_DEBUG, "Creating DataArray");
            $values->type('tns:DataArray');
            
            my $result_set = SOAP::Data->name('ResultSet' => 
                \SOAP::Data->value($columns, $types, $values)
                );
            $log->log(LOG_DEBUG, "Creating ResultSet");
            $result_set->type('tns:ResultSet');
            push @soap_rs, $result_set; 
        }
        
        ## Record
        $log->log(LOG_DEBUG, "Creating Record");
        my $record = SOAP::Data->name('results' => 
            \SOAP::Data->name('item' => @soap_rs)->type('tns:ResultSet')
            );
        $record->type('tns:Record');
        push @records, $record;
    }
    
    ## RecordArray
    $log->log(LOG_DEBUG, "Creating RecordArray");
    my $soap_results = SOAP::Data->name('results' => 
        \SOAP::Data->name('item' => @records)->type('tns:Record')
        )->type('tns:RecordArray');
    if ($debug) {
	$log->log(LOG_DEBUG, '$soap_results => '. Dumper($soap_results));
    }
    return $soap_results;
}

1;

__END__

=head1 NAME

VUser::SOAP - SOAP handling for vsoapd

=head1 DESCRIPTION

Provides all of the utilites for handling vuser actions via SOAP.

=head1 BUGS

Sessions information is all kept in memory. This may lead to problems if there
are a large number of different users using the service. It may be better to
move this to a database at some point.

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vsoapd.
 
 vsoapd is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vsoapd is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vsoapd; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
