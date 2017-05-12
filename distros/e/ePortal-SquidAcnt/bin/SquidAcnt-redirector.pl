#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------
# Input format:
#   URL ip-address/fqdn ident method
#
# Sample data:
# http://images.rambler.ru/n/search-ie.gif 172.16.222.22/- - GET
# http://ie5.rambler.ru/cgi-bin/query_ie5? 172.16.222.22/- - GET
# http://www.anons.tv/b/mh-1.gif 172.16.222.22/- - GET
# http://www.azot.kuzbass.net/ 172.16.0.2/- - GET
# http://rose.ixbt.com/banner/83/200_3.gif 172.16.222.58/- - GET
# http://rose.ixbt.com/banner/363/chain-1.jpg 172.16.222.58/- - GET
# http://rose.ixbt.com/banner/227/rolsen_r1(120x300)-2.gif 172.16.222.58/- - GET
# http://rose.ixbt.com/banner/190/4-315x60.gif 172.16.222.58/- - GET

BEGIN {
    $| = 1;
    $0 = 'SquidAcnt-redirector.pl';
}

use ePortal::Global;
use ePortal::Server;
use Error qw/:try/;

use URI;

# ------------------------------------------------------------------------
# Global variables
our $DEBUG = 1;
our $REFRESH_MINUTES = 5;
our $WWW_SERVER = undef;        # ePortal host server
our %GROUP = ();                # $GROUP{id}=[redir_type,custom_url]
our %USER  = ();                # $USER{address}=[id,blocked]
our $app;

# ------------------------------------------------------------------------
# Start here
die "Cannot read config" if ! read_config();
main_loop();


############################################################################
sub main_loop   {   #08/08/2003 11:47
############################################################################
    my $self = shift;
    my $last_config_refresh;
    
    while(1) {
        # Do roconfig periodically
        if ($last_config_refresh + $REFRESH_MINUTES*60 < time) {
            read_config();
            $last_config_refresh = time;
        }

        # Get URL
        my $line = <STDIN>;
        last if ! defined $line;

        # Parse URL
        my ($url, $address, $ident, $method) = split (' ', $line, 4);
        $address =~ s|/.*||o;       # remove fqdn part

        # Make decision
        my ($redir_type, $custom_url);
        my $group_id = $app->match_url_group($url);

        if ($group_id) {
            $redir_type = $GROUP{$group_id}[0];
        }

        # make decision about redirect
        my $location = "\n";
        if ($redir_type eq 'allow_local') {
            # allow
            
        } elsif ($redir_type eq 'block_info') {
            # Blocked URL
            if ($url =~ /\.(gif|jpg|jpeg|png)/io) {
                $redir_type = 'white_img';
            } else  {
                $location = "302:$WWW_SERVER/app/SquidAcnt/block_info.htm?block_group=$group_id&user_id=".$USER{$address}[0]."\n";
            }

        } elsif ($redir_type eq 'allow_external') {
            # allow
            
        } elsif ($redir_type eq 'custom') {
            $location = '302:' . $GROUP{$group_id}[1]. "\n";

        } elsif ($redir_type eq 'empty_html') {
            $location = "$WWW_SERVER/app/SquidAcnt/empty.htm\n";
        }
        
        # Default processing
        # URL is not classified. Look for user accessing it
        if ($redir_type eq '') {
            if (exists $USER{$address}[1]) {
                $redir_type = "external_user";
                if ($USER{$address}[1]) {  # blocked
                    $redir_type = 'user_blocked';
                    $location = "302:$WWW_SERVER/app/SquidAcnt/block_info.htm?blocked=1&user_id=".$USER{$address}[0]."\n";
                }

            } else {
                $redir_type = 'internal_user';
                if ($url =~ /\.(gif|jpg|png)/io) {
                    $redir_type = 'white_img';
                } else {
                    $location = "302:$WWW_SERVER/app/SquidAcnt/block_info.htm?internal=1&user_id=".$USER{$address}[0]."\n";
                }
            }
        }

        # Special processing for images    
        if ($redir_type eq 'white_img') {
            $location = "$WWW_SERVER/images/SquidAcnt/1px-trans.gif\n";
        } elsif ($redir_type eq 'black_img') {
            $location = "$WWW_SERVER/images/SquidAcnt/1px-black.gif\n";
        }    

        print STDERR "$address: $url => $redir_type\n" if $DEBUG;

        # Do redirect
        print $location;
    }
}##main_loop


############################################################################
sub read_config {   #08/08/2003 11:49
############################################################################
    my $self = shift;

    $dbh = try {
        $ePortal = new ePortal::Server if ! $ePortal;
        $ePortal->initialize;
        $ePortal->DBConnect;
    } catch ePortal::Exception::DBI with {
        undef;
    };
    return undef if ! $dbh;

    $app = $ePortal->Application('SquidAcnt') if ! ref($app);

    # --------------------------------------------------------------------
    $WWW_SERVER = $ePortal->www_server;
    $WWW_SERVER =~ s|/$||;                  # remove trailing slash
    throw ePortal::Exception::Fatal(-text => 'www_server configuration parameter is not defined')
        unless $WWW_SERVER;

    # --------------------------------------------------------------------
    # Groups
    # $GROUP{id}=[redir_type,custom_url]
    my $g = new ePortal::App::SquidAcnt::SAurl_group;
    $g->restore_all;
    %GROUP = ();
    while($g->restore_next) {
        $GROUP{$g->id} = [$g->redir_type, $g->redir_url];
    }
    
    # --------------------------------------------------------------------
    # $USER{address}=[id,blocked]
    my $u = new ePortal::App::SquidAcnt::SAuser;
    $u->restore_all;
    %USER = ();
    while($u->restore_next) {
        $USER{$u->address} = [$u->id, $u->blocked];
    }    

    # --------------------------------------------------------------------
    # Load SAurl cache
    $app->match_url_group('reconfig');

    # --------------------------------------------------------------------
    # disconnect from MySQL
    $dbh->disconnect;
    $app->dbh->disconnect;

    print STDERR "SquidAcnt-redirector reconfigured\n" if $DEBUG;

    1;
}##read_config

__END__
