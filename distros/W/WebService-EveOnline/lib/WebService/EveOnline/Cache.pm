package WebService::EveOnline::Cache;

use strict;
use warnings;

our $VERSION = "0.61";

use DBI;
use Storable qw/freeze thaw/;
use Time::Local;

use Data::Dumper;

=head1 NAME

WebService::EveOnline::Cache -- provide a cache for use by WebService::EveOnline

=cut

=head1 SYNOPSIS

Currently, for use by WebService::EveOnline only. It makes all kinds of hideous assumptions,
and probably only works for SQLite databases. You can override the defaults when you
instantiate the WebService::EveOnline module. It is recommended that you study the source
code (dear no, it burns!) if you feel inclined to do this.

It is mainly used to store the Eve Online skills tree, and cache any calls to the Eve Online
API so we don't keep clobbering the network every time we want to find something out.

=cut

=head2 new

Instantiates the WebService::EveOnline cache. Assuming the type is SQLite (the default) it
attempts to open the db file if it exists.

=cut

sub new {
    my ($class, $params) = @_;
    
    my $type = $params->{cache_type};
    my $dbname = $params->{cache_dbname};
    my $user = $params->{cache_user} || "";
    my $pass = $params->{cache_pass} || "";
    my $uid = $params->{eve_user_id} || "0";

    my ($dbh, $sql);
    
    unless ($type eq "no_cache") {
        if (-f $dbname && $type eq "SQLite") {
            $dbh = DBI->connect("dbi:$type:dbname=$dbname", "", "");
            $sql = {
                get_skill => $dbh->prepare("SELECT * FROM skill_types WHERE typeID=?"),
                retrieve  => $dbh->prepare("SELECT cachedata, cacheuntil FROM eve_cache WHERE cachekey=?"),
                store     => $dbh->prepare("INSERT INTO eve_cache (cachekey, cacheuntil, cachedata) VALUES (?, ?, ?)"),
                map_id    => $dbh->prepare("SELECT * FROM map WHERE systemID = ?"),
                map_name  => $dbh->prepare("SELECT * FROM map WHERE name = ?"),
                delete    => $dbh->prepare("DELETE FROM eve_cache WHERE cachekey = ?"),
            };
        }
    }

    return bless({ _dbh => $dbh, _sql => $sql, _type => $type, _dbname => $dbname, _uid => $uid, _memcache => {} }, $class);
}

=head2 cache_age

Returns the age of the database cache in epoch seconds.  

=cut

sub cache_age {
    my $self = shift;

    my $type = $self->{_type};
    my $dbname = $self->{_dbname};

    my $build_time = 0;

    no strict;

    eval {
        if (-f $dbname && $type eq "SQLite") {
            my $dbh = DBI->connect("dbi:$type:dbname=$dbname", "", "");
            my $bt = $dbh->prepare("SELECT build_epoch FROM last_build");
            $bt->execute;
            $build_time = $bt->fetchrow;
            $bt->finish;
        }
    };
    
    return time - $build_time;
}

=head2 repopulate

Attempts to delete the sqlite database file and rebuild it. It should be called with the
data structure returned from the all_eve_skills method, i.e. the raw datastructure that
XML::Simple spits out. It really does nothing clever at all, and all of this code will
need to be significantly refactored at a later date.

=cut

sub repopulate {
    my ($self, $hr_data) = @_;

    my $type ||= $self->{_type};
    my $dbname ||= $self->{_dbname};
    my ($dbh, $db_exists);

    if (-f $dbname) {
        $db_exists = 1;
    }    
    
    eval {
        $dbh = DBI->connect("dbi:$type:dbname=$dbname", "", "");
    };
    
    unless ($dbh) {
        warn "Problem creating cache: $@\n";
        $self->{_type} = "no_cache";
    }

    return 0 unless $dbh;

    if ($db_exists) {
        foreach my $table (qw/ skill_groups skill_types skill_dependencies map last_build /) {
           eval {
               $dbh->do("DROP TABLE $table;");
           };
        }
        eval {
            $dbh->do("DROP INDEX map_idx;");
        };
    } else {
        $dbh->do("CREATE TABLE eve_cache (cachekey varchar(255) not null primary key, cacheuntil int not null, cachedata text);");
    }

    $dbh->do("CREATE TABLE skill_groups (groupID int not null primary key, groupName varchar(255));");
    $dbh->do("CREATE TABLE skill_types (typeID int not null primary key, groupID int not null, typeName varchar(255), rank int, description text);");
    $dbh->do("CREATE TABLE skill_dependencies (depID int primary key not null, typeID int not null, deptypeID int not null, level int);");
    $dbh->do("CREATE TABLE last_build (build_epoch int not null);");   
    $dbh->do("CREATE TABLE map (systemID int not null primary key, allianceID int, constallationSovereignty int, sovereigntyLevel int, factionID int, name varchar(255));");
    $dbh->do("CREATE INDEX map_idx ON map (name);");   
    
    # this is lazy -- a cut and paste from the new sub. TODO: refactor
    my $esql = {
        get_skill => $dbh->prepare("SELECT * FROM skill_types WHERE typeID=?"),
        retrieve  => $dbh->prepare("SELECT cachedata, cacheuntil FROM eve_cache WHERE cachekey=?"),
        store     => $dbh->prepare("INSERT INTO eve_cache (cachekey, cacheuntil, cachedata) VALUES (?, ?, ?)"),
        map_id    => $dbh->prepare("SELECT * FROM map WHERE systemID = ?"),
        map_name  => $dbh->prepare("SELECT * FROM map WHERE name = ?"),
        delete    => $dbh->prepare("DELETE FROM eve_cache WHERE cachekey = ?"),
    };
    
    my $sql = {
        group => $dbh->prepare("INSERT INTO skill_groups VALUES (?, ?)"),
        type => $dbh->prepare("INSERT INTO skill_types VALUES (?, ?, ?, ?, ?)"),
        dep => $dbh->prepare("INSERT INTO skill_dependencies VALUES (?, ?, ?, ?)"),
        lb => $dbh->prepare("INSERT INTO last_build VALUES (?)"),
        map => $dbh->prepare("INSERT INTO map VALUES (?, ?, ?, ?, ?, ?)"),
    };

    my $depid = 1;

    $dbh->begin_work;
    foreach my $result (@{$hr_data->{skills}->{result}->{rowset}->{row}}) {
        $sql->{group}->execute($result->{groupID}, $result->{groupName});
        foreach my $row (@{$result->{rowset}->{row}}) {
            $sql->{type}->execute($row->{typeID}, $result->{groupID}, $row->{typeName}, $row->{rank}, $row->{description});

            my $req = $row->{rowset}->{requiredSkills}->{row};
            if ($req) {
                if (ref($req) eq "ARRAY") {
                    foreach my $skill (@{$req}) {
                        $sql->{dep}->execute($depid++, $row->{typeID}, $skill->{typeID}, $skill->{skillLevel});
                    }
                } else {
                    $sql->{dep}->execute($depid++, $row->{typeID}, $req->{typeID}, $req->{skillLevel});
                }       
            }
        }
    }
    $dbh->commit;    
    $dbh->begin_work;

    foreach my $result (@{$hr_data->{map}->{result}->{rowset}->{row}}) {
        $sql->{map}->execute($result->{solarSystemID}, $result->{allianceID}, $result->{constellationSovereignity}, 
                             $result->{sovereignityLevel}, $result->{factionID}, $result->{solarSystemName});
    
    }
    $sql->{lb}->execute(time);
    $dbh->commit;    
    
    $self->{_dbh} = $dbh;
    $self->{_sql} = $esql;
    
    return 1; 
}

=head2 get_skill
 
Returns skill data based on a typeID.

=cut 

sub get_skill {
    my ($self, $id) = @_;
    return undef if $self->{type} && $self->{type} eq "no_cache";
    my $sql = $self->{_sql};

    $sql->{get_skill}->execute($id);
    return $sql->{get_skill}->fetchrow_hashref();
}

=head2 retrieve

Retrieves a previously-run command from the cache. It checks the
age of the cache. It will return no data if the cache has expired,
or if the command has not been run before.

=cut

sub retrieve {
    my ($self, $details) = @_;
    
    my $data = undef;
    my $tempdata = undef;
    my $until = time - 1; # pretend cache has already expired
    my $now = time;
    
    my $cachekey =  $self->{_uid} . ":" . $details->{command} . ":" . $details->{params};

    if ($self->{_dbh}) {
        $self->{_sql}->{retrieve}->execute($cachekey);
        ($tempdata, $until) = $self->{_sql}->{retrieve}->fetchrow;
        $self->{_sql}->{retrieve}->finish;
        if ($tempdata && ($until >= $now)) {
            $data = thaw($tempdata);
        } else {
            $self->{_sql}->{delete}->execute($cachekey);
            $self->{_sql}->{delete}->finish;
        } 
    } else {
        $self->{_memcache}->{$cachekey} ||= [];
        ($tempdata, $until) = @{$self->{_memcache}->{$cachekey}};
        if ($tempdata && ($until >= $now)) {
            $data = $tempdata;
        } else {
            $self->{_memcache}->{$cachekey} = [];
        }       
    }
    
    # $data will only be returned if it exists and the cache on it hasn't expired
    return $data;

}

=head2 store

Stores the result of a command in the database cache. Returns whatever datastructure
is passed to it. The data is stored in Storable format.

=cut

sub store {
    my ($self, $details) = @_;
    my $cachekey = $self->{_uid} . ":" . $details->{command} . ":" . $details->{params};

    my $cache_until = _evedate_to_epoch($details->{cache_until});

    # The cache times we get back from Eve are usually set to 1 hour. Some things
    # we want to cache for longer (like sex, race, etc.), and other things for
    # shorter (account balance). So we can override it here:

    $cache_until = time + $details->{max_cache} if $details->{max_cache};
    
    if ($self->{_dbh}) {
        # just to be safe, delete before insert
        $self->{_sql}->{delete}->execute($cachekey);
        $self->{_sql}->{delete}->finish;
        
        $self->{_sql}->{store}->execute($cachekey, $cache_until, freeze($details->{data}));
        $self->{_sql}->{store}->finish;
    } else {
        $self->{_memcache}->{$cachekey} = [ $details->{data}, $cache_until ];
    }

    return $details->{data};
}

sub _evedate_to_epoch {
    my ($date, $time) = split(' ', $_[0]);
    my ($yr, $mo, $dy) = split('-', $date);
    my ($hr, $mn, $se) = split(':', $time);
    
    if ($_[1]) {
        return timelocal($se, $mn, $hr, $dy, --$mo, $yr);
    } else {
        return timegm($se, $mn, $hr, $dy, --$mo, $yr);
    }
}

qq/and they call it "puppy love"/;
