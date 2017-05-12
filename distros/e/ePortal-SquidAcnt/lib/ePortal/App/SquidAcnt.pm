#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------


package ePortal::App::SquidAcnt;
    our $VERSION = '4.2';

    use base qw/ePortal::Application/;
    use Params::Validate qw/:types/;
    use Error qw/:try/;

    use URI;

    # use system modules
    use ePortal::Global;
    use ePortal::Utils;

    # use internal Application modules
    use ePortal::App::SquidAcnt::SAuser;
    use ePortal::App::SquidAcnt::SAgroup;
    use ePortal::App::SquidAcnt::SAurl_group;
    use ePortal::App::SquidAcnt::SAurl;


############################################################################
sub initialize  {   #09/08/2003 10:10
############################################################################
    my ($self, %p) = @_;
    
    $p{Attributes}{daily_limit} = { dtype => 'Number' };
    $p{Attributes}{daily_limit_t} = {
        type => 'Transient',
        label => {rus => 'Лимит на день', eng => 'Daily limit'},
        default => '-',
        size => 10,
      };
    $p{Attributes}{weekly_limit} = { dtype => 'Number' };
    $p{Attributes}{weekly_limit_t} = {
        type => 'Transient',
        label => {rus => 'Лимит на неделю', eng => 'Weekly limit'},
        default => '-',
        size => 10,
      };
    $p{Attributes}{mon_limit} = { dtype => 'Number' };
    $p{Attributes}{mon_limit_t} = {
        type => 'Transient',
        label => {rus => 'Лимит на месяц', eng => 'Monthly limit'},
        default => '-',
        size => 10,
      };
    $p{Attributes}{daily_alert} = { dtype => 'Number' };
    $p{Attributes}{daily_alert_t} = {
        type => 'Transient',
        label => {rus => 'Порог предупреждения на день', eng => 'Daily threshold limit'},
        default => '-',
        size => 10,
      };

    $p{Attributes}{access_log} = {
          label => {rus => 'Пусть до файла access.log', eng => 'access.log file path'},
          default => '/var/log/squid/access.log',
          size => 50,
      };

    $p{Attributes}{xacl_read} = {
          label => {rus => 'Доступ на просмотр', eng => 'Read access rights'},
          fieldtype => 'xacl',
      };
    $p{Attributes}{xacl_write} = {
          label => {rus => 'Изменение данных', eng => 'Write access rights'},
          fieldtype => 'xacl',
      };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub value_from_req  {   #09/08/2003 10:30
############################################################################
    my ($self, $att, $value) = @_;

    foreach (qw/daily_limit weekly_limit mon_limit daily_alert/) {
        if ($att eq $_.'_t') {
            $self->value($_, $self->NiceUnformat($value));
        }
    }

    $self->SUPER::value_from_req($att, $value);
}##value_from_req


############################################################################
sub config_load {   #09/08/2003 2:29
############################################################################
    my $self = shift;
    
    $self->SUPER::config_load;

    foreach (qw/daily_limit weekly_limit mon_limit daily_alert/) {
        $self->value($_.'_t', $self->NiceFormat($self->value($_)));
    }
}##config_load

############################################################################
sub config_save {   #03/17/03 4:55
############################################################################
    my $self = shift;
    $self->SUPER::config_save;

    # Modify permissions for SquidAcnt Catalog item
    my $C = new ePortal::Catalog;
    if ($C->restore('ePortal-SquidAcnt-link')) {
        $C->xacl_read( $self->xacl_read );
        $C->update;
    }    
}##config_save

############################################################################
sub ProcessAccessLogLine    {   #07/29/2003 11:28
############################################################################
    my $self = shift;
    my $line = shift;

    $self->{users_not_found} = {} if ! exists $self->{users_not_found};

    # --------------------------------------------------------------------
    # Cache users_info
    # $self->{users_info}{address} = user_id
    #
    if ( ! defined($self->{users_info}) ) {
        $self->{users_info} = {};
        my $u = new ePortal::App::SquidAcnt::SAuser;
        $u->restore_all;
        while($u->restore_next) {
            $self->{users_info}{$u->address} = $u->id;
        }
    }

    # --------------------------------------------------------------------
    # Parse access.log line
    my ($sq_time, $sq_duration, $sq_address,
        $sq_result_code, $sq_bytes, $sq_method,
        $sq_url, $sq_frc931, $sq_hierarhy, $sq_type) = split('\s+', $line);
#    $sq_url =~ s|^.*://([^/]+)/.*|$1|o;      # get top level domain name
#    $sq_result_code =~ s|/.*||go;            # remove all after /
#    $sq_url =~ s|:.*||o;                    # remove port number

    # --------------------------------------------------------------------
    # Analyze data
    return 0 if $sq_bytes == 0;      # Zero bytes

    if ($sq_result_code =~ /_HIT/o) {
        $self->{hit_lines} ++;
        return 'cached'
    }

    if ($sq_url eq '' or 
            $sq_url =~ m|^/|o or 
            $sq_result_code =~ m|_MISS/000| or
            $sq_hierarhy =~ m|NONE/| or
            $sq_method eq 'POST' or 
            $sq_result_code !~ /_MISS/o) {
        $self->{ignored_lines} ++;
        return 'ignored';
    }

    # --------------------------------------------------------------------
    # Match URL to url_group
    # 
    my $g = new ePortal::App::SquidAcnt::SAurl_group;
    my $group_id = $self->match_url_group($sq_url);
    my $sq_domain = $self->{last_url_host};

    if ($sq_domain eq '') {
        $self->{ignored_lines} ++;
        return 'ignored';
    }    

    if ($group_id and $g->restore($group_id)) {
        if ($g->redir_type eq 'allow_local') {
            $self->{local_domain_lines} ++;
            return 'local_domain'
        }
    }

    if (! exists $self->{users_info}{$sq_address}) {
        $self->{users_not_found}{$sq_address} ++;
        return 'user_not_found';
    }

    # --------------------------------------------------------------------
    # Save results
    my $dbh = $self->dbh;
    my $log_date = sprintf("%04d-%02d-%02d %02d:00:00",
        (localtime($sq_time))[5] + 1900,    # year
        (localtime($sq_time))[4] + 1,       # month
        (localtime($sq_time))[3],           # day
        (localtime($sq_time))[2]);          # hour

    my $row_count = $dbh->selectrow_array("SELECT count(*) FROM SAtraf
            WHERE domain=? AND user_id=? AND log_date=?",
            undef,
            $sq_domain, $self->{users_info}{$sq_address}, $log_date);
    if ($row_count > 0) {
        $dbh->do("UPDATE SAtraf SET bytes = bytes + ? WHERE domain=? AND user_id=? AND log_date=?",
            undef,
            $sq_bytes, $sq_domain, $self->{users_info}{$sq_address}, $log_date);
    } else {
        $dbh->do("INSERT INTO SAtraf (bytes,domain,user_id,log_date) VALUES( ?,?,?,? )",
            undef,
            $sq_bytes, $sq_domain, $self->{users_info}{$sq_address}, $log_date);
    }
    $self->{processed_lines} ++;
    return $sq_bytes;
}##ProcessAccessLogLine

############################################################################
# Description: Nicely format Kbytes
############################################################################
sub NiceFormat  {   #08/05/2003 11:27
############################################################################
    my $self = shift;
    my $number = shift;

    if ($number eq '') {
        $number = '-';
    } elsif ($number >= 1024*1024*1024) {
        $number = sprintf("%d Gb", $number / 1024/1024/1024);
    } elsif ($number >= 1024*1024) {
        use integer;
        $number = sprintf("%d Mb", $number / 1024/1024);
    } elsif ($number >= 1024) {
        $number = sprintf("%d Kb",$number / 1024);
    }
    return $number;
}##NiceFormat


############################################################################
# Description: Convert nice format into integer
############################################################################
sub NiceUnformat    {   #08/05/2003 11:27
############################################################################
    my $self = shift;
    my $number = shift;

    if ($number eq '' or $number eq '-') {
        return undef;
    } else {
        my $mult = 1;
        $number =~ s/[^\dkmg]//igo;
        $mult = 1024*1024*1024 if $number =~ /\d+G/i;
        $mult = 1024*1024 if $number =~ /\d+M/i;
        $mult = 1024 if $number =~ /\d+K/i;
        return $number*1 * $mult;
    }
}##UnNiceFormat



############################################################################
# Function: match_url_group
# Description: Matches URL for every SAurl to find a SAurl_group.
# 
# Parameters: URL to match
# Returns:
#   SAurl_group->id on match
#   undef if no url matches
# 
# Special processing:
#   if URL eq 'reconfig' then loads the content of SAurl into cache memory
# Returns:
#   1 on ok
#   undef on configuration errors
#
############################################################################
sub match_url_group {   #08/11/2003 10:10
############################################################################
    my $self = shift;
    my $url = shift;

    # --------------------------------------------------------------------
    # Cache SAurl table 
    # $self->{SAurl}{url_title} = [url_type, url_group_id, counter, url_id]
    if (! exists $self->{SAurl} or ($url eq 'reconfig')) {
        my $dbh = $self->dbh;
        my $ur = new ePortal::App::SquidAcnt::SAurl;

        # flush statistics. 
        # This changes ts field to current date/time for URLs with match
        # counter > 0
        if (ref($self->{SAurl}) eq 'HASH') {
            foreach (keys %{$self->{SAurl}}) {
                if ($self->{SAurl}{$_}[2]) {
                    $ur->restore($self->{SAurl}{$_}[3]);
                    $ur->ts(undef);
                    $ur->update;
                    $self->{SAurl}{$_}[2] = 0;
                }
            }
        }

        # load SAurl table into memory
        $ur->restore_all;
        $self->{SAurl} = {};
        while($ur->restore_next) {
            $self->{SAurl}{$ur->title} = [$ur->url_type, $ur->url_group_id, 0, $ur->id];
        }

        return 1 if $url eq 'reconfig';     # just do reconfig
    }    

    # --------------------------------------------------------------------
    # match URL
    my $uri = new URI(lc $url, 'http');
    my ($host, $path) = eval { ($uri->host, $uri->path); };
    return undef if $@;

    # cache for speedup other things
    $self->{last_url_host} = $host;
    $self->{last_url_path} = $path;
    
    foreach my $u (keys %{ $self->{SAurl} }) {
        my $url_type = $self->{SAurl}{$u}[0];
        if ( $url_type eq 'domain_string') {
            if (($host eq $u) or (substr($host, -length($u)) eq $u)) {
                $self->{SAurl}{$u}[2] ++;
                return $self->{SAurl}{$u}[1];
            }
        } elsif ( $url_type eq 'domain_regex') {
            if ($host =~ /$u/i) {
                $self->{SAurl}{$u}[2] ++;
                return $self->{SAurl}{$u}[1];
            }
            
        } elsif ( $url_type eq 'path_string') {
            if (substr($path, 0, length($u)) eq $u) {
                $self->{SAurl}{$u}[2] ++;
                return $self->{SAurl}{$u}[1];
            }

        } elsif ( $url_type eq 'path_regex') {
            if ($path =~ /$u/i) {
                $self->{SAurl}{$u}[2] ++;
                return $self->{SAurl}{$u}[1];
            }
            
        } elsif ( $url_type eq 'regex') {
            if ($url =~ /$u/i) {
                $self->{SAurl}{$u}[2] ++;
                return $self->{SAurl}{$u}[1];
            }
            
        } else {
            die "Unknown url_type " . $self->{SAurl}{$u}[0] . "\n";
        }        
    }

    return undef;
}##match_url_group

############################################################################
sub SAuser_extended {   #08/18/2003 2:02
############################################################################
    my $self = shift;

    my $obj = new ePortal::App::SquidAcnt::SAuser(
    DBISource => 'SquidAcnt',
    SQL => q{SELECT u.*
              ,g.title as group_title
              ,g.id    as group_id
                ,ifnull(u.daily_limit, ifnull(g.daily_limit, ?)) as daily_limit
                ,ifnull(u.weekly_limit, ifnull(g.weekly_limit, ?)) as weekly_limit
                ,ifnull(u.mon_limit, ifnull(g.mon_limit, ?)) as mon_limit
                ,ifnull(u.daily_alert, ifnull(g.daily_alert, ?)) as daily_alert
                ,sum(if(log_date >= current_date, t.bytes, null)) as daily_traf
                ,sum(if(week(log_date) = week(current_date), t.bytes, null)) as weekly_traf
                ,sum(if(month(log_date) = month(current_date), t.bytes, null)) as mon_traf
                ,if(u.end_date <= curdate(), 1, null) as account_expired
            FROM SAuser u
            left join SAgroup g on u.group_id = g.id
            left join SAtraf  t on t.user_id  = u.id and t.log_date >= date_format(current_date, "%Y-%m-00 00:00:00")
            },
    GroupBy => 'u.id',
    Bind => [$self->daily_limit, $self->weekly_limit, $self->mon_limit, $self->daily_alert],
    Attributes => {
        group_title => { label => pick_lang(rus => "Группа", eng => "Group") },
    },    
  );
    
}##SAuser_extended


1;
