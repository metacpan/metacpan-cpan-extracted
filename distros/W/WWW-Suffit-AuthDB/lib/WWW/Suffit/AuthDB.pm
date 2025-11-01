package WWW::Suffit::AuthDB;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB - Suffit Authorization Database

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB;

    my $authdb = WWW::Suffit::AuthDB->new(
        ds => "sqlite:///tmp/auth.db?sqlite_unicode=1"
    );

=head1 DESCRIPTION

Suffit Authorization Database

=head1 ATTRIBUTES

This class implements the following attributes

=head2 cached

    cached => 1
    cached => 'yes'
    cached => 'on'
    cached => 'enable'

This attribute performs enabling caching while establishing of connection with database

    $authdb = $authdb->cached("On");
    my $cached = $authdb->cached;

Default: false (no caching connection)

=head2 initialized

    initialized => 1
    initialized => 'yes'
    initialized => 'on'
    initialized => 'enable'

This attribute marks the schema as initialized or performs read this status

=head2 code

    code => undef

Read only attribute to get the HTTP code

    my $code = $authdb->code; # 200

=head2 data

    data => undef

Read only attribute to get the current data pool

    my $data = $authdb->data;

=head2 ds, dsuri

    ds => "sqlite:///tmp/auth.db?sqlite_unicode=1"

Data source URI. See L<WWW::Suffit::AuthDB::Model>

    $authdb = $authdb->ds("sqlite:///tmp/auth.db?sqlite_unicode=1");
    my $ds = $authdb->ds;

Default: 'sponge://'

=head2 error

    error => undef

Read only attribute to get the error message

    my $error = $authdb->error;

=head2 expiration

    expiration => 300

The expiration time

    $authdb = $authdb->expiration(60*5);
    my $expiration = $authdb->expiration;

B<NOTE!> This attribute MUST be defined before first calling the cache method

Default: 300 (5 min)

=head2 max_keys

    max_keys => 1024

The maximum keys number in cache

    $authdb = $authdb->max_keys(1024*10);
    my $max_keys = $authdb->max_keys;

B<NOTE!> This attribute MUST be defined before first calling the cache method

Default: 1024*1024 (1`048`576 keys max)

=head2 sourcefile

    sourcefile => '/tmp/authdb.json'

Path to the source file in JSON format

    $authdb = $authdb->sourcefile("/tmp/authdb.json");
    my $sourcefile = $authdb->sourcefile;

Default: none

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 new

    my $authdb = WWW::Suffit::AuthDB->new(
            ds => "sqlite:///tmp/auth.db?sqlite_unicode=1",
            sourcefile => "/tmp/authdb.json"
        );
    die $authdb->error if $authdb->error;

Create new AuthDB object


=head2 cache

    my $cache = $authdb->cache;

Get cache instance

=head2 cached_group

This method is deprecated. See L</group> method

=head2 cached_realm

This method is deprecated. See L</realm> method

=head2 cached_routes

This method is deprecated. See L</routes> method

=head2 cached_user

This method is deprecated. See L</user> method

=head2 checksum

    my $digest = $authdb->checksum("string", "algorithm");

This method generates checksum for string.
Supported algorithms: MD5 (unsafe), SHA1 (unsafe), SHA224, SHA256, SHA384, SHA512
Default algorithm: SHA256

=head2 clean

    $authdb->clean;

Cleans state vars on the AuthDB object and returns it

=head2 connect

    $authdb->connect;
    $authdb->connect('yes'); # cached connection

This method performs regular or cached connection with database. See also L</cached> attribute

=head2 dump

    print $authdb->dump;

Returns JSON dump of loaded authentication database

=head2 group

    my $group = $authdb->group("manager");

This method returns data of specified groupname as L<WWW::Suffit::AuthDB::Group> object

    my $group = $authdb->group("manager", 'd1b919c1');

With this data (with pair of arguments) the method returns cached data of specified groupname
as L<WWW::Suffit::AuthDB::Group> object by cachekey

    my $group = $authdb->group("manager", 'd1b919c1', 1);

The third parameter (ForceUpdate=true) allows you to forcefully get data from the database

=head2 is_connected

    $authdb->connect unless $authdb->is_connected

This method checks connection status

=head2 load

    $authdb->load("/tmp/authdb.json");
    die $authdb->error if $authdb->error;

    $authdb->load(); # from `sourcefile`
    die $authdb->error if $authdb->error;

This method performs loading file to C<data> pool

=head2 model

    my $model = $authdb->model;

Get model L<WWW::Suffit::AuthDB::Model> instance

=head2 raise

    return $authdb->raise("Error string");
    return $authdb->raise("Error %s", "string");
    return $authdb->raise(200 => "Error string");
    return $authdb->raise(200 => "Error %s", "string");

Sets error string and returns false status (undef). Also this method can performs sets the HTTP status code

=head2 realm

    my $realm = $authdb->realm("default");

This method returns data of specified realm name as L<WWW::Suffit::AuthDB::Realm> object

    my $realm = $authdb->realm("default", 'd1b919c1');

With this data (with pair of arguments) the method returns cached data of specified realm name
as L<WWW::Suffit::AuthDB::Realm> object by cachekey

    my $realm = $authdb->realm("default", 'd1b919c1', 1);

The third parameter (ForceUpdate=true) allows you to forcefully get data from the database

=head2 routes

    my $routes = $authdb->routes("http://localhost/");
    my $routes = $authdb->routes("http://localhost/", 'd1b919c1');
    my $routes = $authdb->routes("http://localhost/", 'd1b919c1', 1);

This method returns hash of routes by base URL and cachekey (optionaly).
With pair of arguments the method returns cached data by cachekey.
The third parameter (ForceUpdate=true) allows you to forcefully get data from the database

=head2 save

    $authdb->save(); # to `sourcefile`
    die $authdb->error if $authdb->error;

Performs flush database to file that was specified in constructor

    $authdb->save("/tmp/new-authdb.json");
    die $authdb->error if $authdb->error;

Performs flush database to file that specified directly

=head2 user

    my $user = $authdb->user("alice");

This method returns data of specified username as L<WWW::Suffit::AuthDB::User> object

    my $user = $authdb->user("alice", 'd1b919c1');

Returns cached data of specified username as L<WWW::Suffit::AuthDB::User> object by cachekey

    my $user = $authdb->user("alice", 'd1b919c1', 1);

The third parameter (ForceUpdate=true) allows you to forcefully get data from the database

=head2 META KEYS

Meta keys define the AuthDB setting parameters

=over 4

=item schema.version

Version of the current schema

=back

=head1 ERROR CODES

List of AuthDB Suffit API error codes

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E1300   [500]   Can't load file. File not found
    E1301   [500]   Can't load data pool from file
    E1302   [500]   File did not return a JSON object
    E1303   [500]   Can't serialize data pool to JSON
    E1304   [500]   Can't save data pool to file
    E1305   [500]   Can't connect to database (model)
    E1306   [500]   Connection failed
    E1307   [500]   The authorization database is not initialized
    E1308   [---]   Reserved
    E1309   [---]   Reserved
    E1310   [ * ]   User not found
    E1311   [ * ]   Incorrect username stored
    E1312   [ * ]   Incorrect password stored
    E1313   [ * ]   The user data is expired
    E1314   [ * ]   Group not found
    E1315   [ * ]   Incorrect groupname stored
    E1316   [ * ]   The group data is expired
    E1317   [403]   External requests is blocked
    E1318   [403]   Internal requests is blocked
    E1319   [403]   Access denied
    E1320   [400]   No username specified
    E1321   [413]   The username is too long (1-256 chars required)
    E1322   [400]   No password specified
    E1323   [413]   The password is too long (1-256 chars required)
    E1324   [403]   Account frozen for 5 min
    E1325   [501]   Incorrect digest algorithm
    E1326   [401]   Incorrect username or password
    E1327   [403]   User is disabled
    E1328   [---]   Reserved
    E1329   [500]   Database request error (meta_get)
    E1330   [400]   No key specified
    E1331   [500]   Database request error (meta_set)
    E1332   [400]   Incorrect digest algorithm
    E1333   [500]   Database request error (user_get)
    E1334   [400]   User already exists
    E1335   [500]   Database request error (user_add)
    E1336   [400]   User not found
    E1337   [500]   Database request error (user_edit)
    E1338   [500]   Database request error (user_getall)
    E1339   [500]   Database request error (meta_del)
    E1340   [500]   Database request error (user_del)
    E1341   [500]   Database request error (grpusr_del)
    E1342   [500]   Database request error (user_search)
    E1343   [500]   Database request error (user_groups)
    E1344   [400]   No password specified
    E1345   [500]   Database request error (user_passwd)
    E1346   [500]   Database request error (user_setkeys)
    E1347   [500]   Database request error (user_tokens)
    E1348   [500]   Database request error (group_get)
    E1349   [400]   Group already exists
    E1350   [500]   Database request error (group_add)
    E1351   [500]   Database request error (user_set)
    E1352   [500]   Database request error (grpusr_add)
    E1353   [500]   Database request error (group_set)
    E1354   [---]   Reserved
    E1355   [500]   Database request error (group_getall)
    E1356   [500]   Database request error (group_del)
    E1357   [500]   Database request error (grpusr_get)
    E1358   [500]   Database request error (group_members)
    E1359   [500]   Database request error (realm_get)
    E1360   [400]   Realm already exists
    E1361   [500]   Database request error (realm_add)
    E1362   [500]   Database request error (route_release)
    E1363   [500]   Database request error (route_assign)
    E1364   [500]   Database request error (realm_requirement_del)
    E1365   [500]   Database request error (realm_requirement_add)
    E1366   [500]   Database request error (realm_set)
    E1367   [500]   Database request error (realm_getall)
    E1368   [500]   Database request error (realm_del)
    E1369   [500]   Database request error (token_add)
    E1370   [500]   Database request error (route_add)
    E1371   [500]   Database request error (realm_requirements)
    E1372   [500]   Database request error (realm_routes)
    E1373   [500]   Database request error (route_get)
    E1374   [400]   Route already exists
    E1375   [500]   Database request error (route_set)
    E1376   [500]   Database request error (route_getall)
    E1377   [500]   Database request error (route_del)
    E1378   [500]   Database request error (route_search)
    E1379   [500]   Database request error (token_del)
    E1380   [500]   Database request error (token_get)
    E1381   [500]   Database request error (token_get_cond)
    E1382   [500]   Database request error (token_set)
    E1383   [500]   Database request error (token_getall)
    E1384   [500]   Database request error (stat_get)
    E1385   [500]   Database request error (stat_set)

B<*> -- this code will be defined later on the interface side

See also list of common Suffit API error codes in L<WWW::Suffit::API/"ERROR CODES">

=head1 EXAMPLE

Example of default authdb.json

See C<src/authdb.json>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.06';

use Mojo::Base -base;
use Mojo::Util qw/md5_sum decode encode steady_time deprecated/;
use Mojo::File qw/path/;
use Mojo::JSON qw/from_json to_json/;
use Mojo::URL;

use Digest::SHA qw/sha1_hex sha224_hex sha256_hex sha384_hex sha512_hex/;

use Acrux::RefUtil qw/is_integer is_hash_ref is_true_flag is_void isnt_void/;

use WWW::Suffit::Cache;

use WWW::Suffit::AuthDB::Model;
use WWW::Suffit::AuthDB::User;
use WWW::Suffit::AuthDB::Group;
use WWW::Suffit::AuthDB::Realm;

use constant {
    DEFAULT_URL         => 'http://localhost',
    DEFAULT_ALGORITHM   => 'SHA256',
    MAX_CACHE_KEYS      => 1024*1024, # 1`048`576 keys max
    CACHE_EXPIRES       => 60*5, # 5min
};

has data        => '';
has error       => '';
has code        => 200;
has sourcefile  => ''; # JSON source file
has ds          => ''; # Data Source URI
has dsuri       => ''; # Data Source URI (= ds)
has max_keys    => MAX_CACHE_KEYS;
has expiration  => CACHE_EXPIRES;
has cached      => 0;
has initialized => 0;

sub raise {
    my $self = shift(@_);
    return undef unless scalar(@_);
    if (@_ == 1) { # "message"
        $self->error(shift(@_));
    } else { # ("code", "message") || ("code", "format", "message") || ("format", "message")
        my $code_or_format = shift @_; # Get fisrt arg
        if (is_integer($code_or_format)) { # first is "code"
            $self->code($code_or_format);
            if (@_ == 1) { # second is "message"
                $self->error(shift(@_));
            } else { # "format", "message", ...
                $self->error(sprintf(shift(@_), @_));
            }
        } else { # first is "format"
            $self->error(sprintf($code_or_format, @_));
        }
    }
    return undef;
}
sub clean {
    my $self = shift;

    # Flush session variables
    $self->error('');
    $self->code(200);
    return $self;
}
sub cache {
    my $self = shift;
    $self->{cache} ||= WWW::Suffit::Cache->new(
            max_keys    => $self->max_keys // MAX_CACHE_KEYS,
            expiration  => $self->expiration // CACHE_EXPIRES,
        );
    return $self->{cache};
}
sub model {
    my $self = shift;
    $self->{model} ||= WWW::Suffit::AuthDB::Model->new($self->dsuri || $self->ds);
    return $self->{model};
}
sub dump {
    my $self = shift;
    to_json($self->{data});
}
sub load {
    my $self = shift;
    my $file = shift;
    $self->clean; # Flush error first
    if ($file) {
        $self->sourcefile($file) unless $self->sourcefile;
    } else {
        $file = $self->sourcefile;
    }
    return $self unless $file;
    $self->raise(500 => "E1300: Can't load file \"$file\". File not found") && return $self
        unless -e $file;

    # Load data pool from file
    my $file_path = path($file);
    my $cont = decode('UTF-8', $file_path->slurp) // '';
    if (length($cont)) {
        my $data = eval { from_json($cont) };
        if ($@) {
            $self->raise(500 => "E1301: Can't load data pool from file \"%s\": %s", $file, $@);
        } elsif (ref($data) ne 'HASH') {
            $self->raise(500 => "E1302: File \"%s\" did not return a JSON object", $file);
        } else {
            $self->{data} = $data;
        }
    }

    return $self;
}
sub save {
    my $self = shift;
    my $file = shift || $self->sourcefile;
    $self->clean; # Flush error first
    return $self unless $file;

    # Save data pool to file
    my $json = eval { to_json($self->{data}) };
    if ($@) {
        $self->raise(500 => "E1303: Can't serialize data pool to JSON: %s", $@);
        return $self;
    }
    path($file)->spew(encode('UTF-8', $json));
    $self->raise(500 => "E1304: Can't save data pool to file \"%s\": %s", $file, ($! // 'unknown error')) unless -e $file;

    return $self;
}
sub connect {
    my $self = shift;
    $self->clean; # Flush error first

    # Connect
    my $cached = is_true_flag(shift // $self->cached);
    my $model = $self->model;
    if ($cached) {
        $model->connect_cached;
    } else {
        $model->connect unless $model->dbh && $model->ping;
    }
    if ($model->error) {
        $self->raise(500 => "E1305: %s", $model->error);
        return $self;
    } elsif (!$model->ping) {
        $self->raise(500 => "E1306: %s", "Connection failed");
        return $self;
    }

    # Check initialize status
    unless (is_true_flag($self->initialized)) { # if NOT initialized
        if ($model->is_initialized) {
            $self->initialized(1); # On
        } else {
            # The authorization database is not inialized
            $self->raise(500 => "E1307: %s", $model->error) if $model->error;
        }
    }

    return $self;
}
sub is_connected {
    my $self = shift;
    my $model = $self->model;
    return 0 unless $model;
    return 1 if $model->dbh;
    return 0;
}
sub checksum {
    my $self = shift;
    my $str = shift // '';
    my $alg = uc(shift // DEFAULT_ALGORITHM);
    return '' unless length $str;
    my $enc_str = encode('UTF-8', $str);
    my $h = '';
    if    ($alg eq 'MD5')    { $h = md5_sum($enc_str)    }
    elsif ($alg eq 'SHA1')   { $h = sha1_hex($enc_str)   }
    elsif ($alg eq 'SHA224') { $h = sha224_hex($enc_str) }
    elsif ($alg eq 'SHA256') { $h = sha256_hex($enc_str) }
    elsif ($alg eq 'SHA384') { $h = sha384_hex($enc_str) }
    elsif ($alg eq 'SHA512') { $h = sha512_hex($enc_str) }
    return $h;
}

# Methods that returns sub-objects and hashes
sub user {
    my $self = shift;
    my $username = shift // '';
    my $cachekey = shift // '';
       $cachekey =~ s/[^a-z0-9]/?/gi;
    my $forceupdate = shift || 0;
    my $key = $cachekey ? sprintf('u.%s.%s', $username || '__anonymous', $cachekey) : '';
    $self->clean; # Flush errors

    # Check username
    return WWW::Suffit::AuthDB::User->new() unless length($username); # No user specified

    # Get cached data
    my $cached_data = $key ? $self->cache->get($key) : {};
    my %data = ();
    if (isnt_void($cached_data) && !$forceupdate) { # Data from cache unless defined $forceupdate
        %data = isnt_void($cached_data) ? (%$cached_data) : ();
    } else { # Data from model
        # Get model
        my $model = $self->model;

        # Get data from model
        %data = $model->user_get($username);
        if ($model->error) {
            $self->raise(500 => "E1333: %s", $model->error);
            return WWW::Suffit::AuthDB::User->new(error => $self->error);
        }
        return WWW::Suffit::AuthDB::User->new() unless $data{id}; # No user found - empty user data, no errors

        # Get groups list of user
        my @grpusr = $model->grpusr_get( username => $username );
        if ($model->error) {
            $self->raise(500 => "E1357: %s", $model->error);
            return WWW::Suffit::AuthDB::User->new(error => $self->error);
        }
        $data{groups} = [sort map {$_->{groupname}} @grpusr];

        # Set data from database to cache
        if ($key) {
            $data{is_cached} = 1;
            $data{cached} = steady_time();
            $data{cachekey} = $cachekey;
            $self->cache->set($key, {%data});
        }
    }

    # Return User instance with %data
    return WWW::Suffit::AuthDB::User->new(%data);
}
sub group {
    my $self = shift;
    my $groupname = shift // '';
    my $cachekey = shift // '';
       $cachekey =~ s/[^a-z0-9]/?/gi;
    my $forceupdate = shift || 0;
    my $key = $cachekey ? sprintf('g.%s.%s', $groupname || '__default', $cachekey) : '';
    $self->clean; # Flush errors

    # Check groupname
    return WWW::Suffit::AuthDB::Group->new() unless length($groupname); # No group specified

    # Get cached data
    my $cached_data = $key ? $self->cache->get($key) : {};
    my %data = ();
    if (isnt_void($cached_data) && !$forceupdate) { # Data from cache unless defined $forceupdate
        %data = isnt_void($cached_data) ? (%$cached_data) : ();
    } else { # Data from model
        # Get model
        my $model = $self->model;

        # Get data from model
        %data = $model->group_get($groupname);
        if ($model->error) {
            $self->raise(500 => "E1348: %s", $model->error);
            return WWW::Suffit::AuthDB::Group->new(error => $self->error);
        }
        return WWW::Suffit::AuthDB::Group->new() unless $data{id}; # No group found - empty group data, no errors

        # Get users list of group
        my @grpusr = $model->grpusr_get( groupname => $groupname );
        if ($model->error) {
            $self->raise(500 => "E1357: %s", $model->error);
            return WWW::Suffit::AuthDB::Group->new(error => $self->error);
        }
        $data{users} = [sort map {$_->{username}} @grpusr];

        # Set data from database to cache
        if ($key) {
            $data{is_cached} = 1;
            $data{cached} = steady_time();
            $data{cachekey} = $cachekey;
            $self->cache->set($key, {%data});
        }
    }

    # Return Group instance with %data
    return WWW::Suffit::AuthDB::Group->new(%data);
}
sub realm {
    my $self = shift;
    my $realmname = shift // '';
    my $cachekey = shift // '';
       $cachekey =~ s/[^a-z0-9]/?/gi;
    my $forceupdate = shift || 0;
    my $key = $cachekey ? sprintf('r.%s.%s', $realmname || '__default', $cachekey) : '';
    $self->clean; # Flush error

    # Check realmname
    return WWW::Suffit::AuthDB::Realm->new() unless length($realmname); # No realm specified

    # Get cached data
    my $cached_data = $key ? $self->cache->get($key) : {};
    my %data = ();
    if (isnt_void($cached_data) && !$forceupdate) { # Data from cache unless defined $forceupdate
        %data = isnt_void($cached_data) ? (%$cached_data) : ();
    } else { # Data from model
        # Get model
        my $model = $self->model;

        # Get data from model
        %data = $model->realm_get($realmname);

        if ($model->error) {
            $self->raise(500 => "E1359: %s", $model->error);
            return WWW::Suffit::AuthDB::Realm->new(error => $self->error);
        }
        return WWW::Suffit::AuthDB::Realm->new() unless $data{id}; # No realm found - empty realm data, no errors

        # Get requirements
        my @requirements = $model->realm_requirements($realmname);
        if ($model->error) {
            $self->raise(500 => "E1371: %s", $model->error);
            return WWW::Suffit::AuthDB::Realm->new(error => $self->error);
        }

        # Segregate by provider
        my %providers;
        foreach my $rec (@requirements) {
            my $prov = $rec->{provider} or next;
            my $box = ($providers{$prov} //= []);
            push @$box, {
                entity  => $rec->{entity} // '',
                op      => lc($rec->{op} // ''),
                value   => $rec->{value} // '',
            };
        }

        # Set as requirements
        $data{requirements} = {%providers};

        # Set data from database to cache
        if ($key) {
            $data{is_cached} = 1;
            $data{cached} = steady_time();
            $data{cachekey} = $cachekey;
            $self->cache->set($key, {%data});
        }
    }

    # Return Realm instance with %data
    return WWW::Suffit::AuthDB::Realm->new(%data);
}
sub routes {
    my $self = shift;
    my $url = _url_fix_localhost(shift(@_)); # Base URL (fixed!)
    my $cachekey = shift // '';
       $cachekey =~ s/[^a-z0-9]/?/gi;
    my $forceupdate = shift || 0;
    my $key = $cachekey ? sprintf('rts.%s.%s', $url || '__default', $cachekey) : '';
    my $now = time;
    $self->clean; # Flush error

    # Get cached data
    my $cached_data = $key ? $self->cache->get($key) : {};
    $cached_data = {} if is_hash_ref($cached_data)
        && is_hash_ref($cached_data->{data})
        && $cached_data->{expires} < $now;

    my %data = ();
    if (isnt_void($cached_data) && !$forceupdate) { # Data from cache unless defined $forceupdate
        %data = isnt_void($cached_data) ? (%$cached_data) : ();
    } else { # Data from model
        # Get model
        my $model = $self->model;

        # Get routes list
        my @routes = $model->route_getall;
        return $self->raise(500 => "E1376: %s", $model->error) if $model->error;

        # Convert to hash
        my $ret = {}; # `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
        foreach my $r (@routes) {
            my $base_url_fixed = _url_fix_localhost($r->{base});
            next unless $r->{realmname} && $base_url_fixed eq $url;
            $ret->{$r->{routename}} = {
                routename   => $r->{routename},
                realmname   => $r->{realmname},
                method      => $r->{method},
                path        => $r->{path},
            };
        }

        # Set result data hash
        %data = (
            data        => $ret,
            is_cached   => 0,
            cached      => 0,
            expires     => 0,
            cachekey    => '',
        );

        # Set data from database to cache
        if ($key) {
            $data{is_cached}= 1;
            $data{cached}   = steady_time();
            $data{cachekey} = $cachekey;
            $data{expires}  = $now + ($self->expiration // CACHE_EXPIRES),
            $self->cache->set($key, {%data});
        }
    }

    # Return data only!
    return $data{data};
}

# Methods that returns cached sub-objects (cached methods)
sub cached_user {
    deprecated 'The "WWW::Suffit::AuthDB::cached_user" is deprecated in favor of "user"';
    goto &user;

    #    my $self = shift;
    #    my $username = shift // '';
    #    my $cachekey = shift // '';
    #    my $now = time;
    #
    #    # Get user object from cache by key
    #    $cachekey =~ s/[^a-z0-9]/?/gi;
    #    my $key = $cachekey
    #        ? sprintf('user.%s.%s', $cachekey, $username || '__anonymous')
    #        : sprintf('user.%s', $username // '__anonymous');
    #    #my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    #    #my $obj = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    #    my $obj = $self->cache->get($key);
    #    return $obj if $obj && $obj->is_valid; # Return user object from cache if exists
    #
    #    # Get real object (not cached) otherwise
    #    $obj = $self->user($username);
    #    return $obj if $self->error;
    #
    #    # Set expires time and marks object as cached
    #    $obj->expires($now + $self->expiration)->mark(steady_time);
    #    $obj->cachekey($cachekey) if $cachekey;
    #    $self->cache->set($key, $obj) if $obj->is_valid;
    #
    #    # Return object
    #    return $obj;
}
sub cached_group {
    deprecated 'The "WWW::Suffit::AuthDB::cached_group" is deprecated in favor of "group"';
    goto &group;

    #    my $self = shift;
    #    my $groupname = shift // '';
    #    my $cachekey = shift // '';
    #    my $now = time;
    #
    #    # Get group object from cache by key
    #    $cachekey =~ s/[^a-z0-9]/?/gi;
    #    my $key = $cachekey
    #        ? sprintf('group.%s.%s', $cachekey, $groupname // '__default')
    #        : sprintf('group.%s', $groupname // '__default');
    #    #my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    #    #my $obj = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    #    my $obj = $self->cache->get($key);
    #    return $obj if $obj && $obj->is_valid; # Return group object from cache if exists
    #
    #    # Get real object (not cached) otherwise
    #    $obj = $self->group($groupname);
    #    return $obj if $self->error;
    #
    #    # Set expires time
    #    $obj->expires($now + $self->expiration)->mark(steady_time);
    #    $obj->cachekey($cachekey) if $cachekey;
    #    $self->cache->set($key, $obj) if $obj->is_valid;
    #
    #    # Return object
    #    return $obj;
}
sub cached_realm {
    deprecated 'The "WWW::Suffit::AuthDB::cached_realm" is deprecated in favor of "realm"';
    goto &realm;

    #    my $self = shift;
    #    my $realmname = shift // '';
    #    my $cachekey = shift // '';
    #    my $now = time;
    #
    #    # Get realm object from cache by key
    #    $cachekey =~ s/[^a-z0-9]/?/gi;
    #    my $key = $cachekey
    #        ? sprintf('realm.%s.%s', $cachekey, $realmname // '__default')
    #        : sprintf('realm.%s', $realmname // '__default');
    #    #my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    #    #my $obj = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    #    my $obj = $self->cache->get($key);
    #    return $obj if $obj && $obj->is_valid; # Return realm object from cache if exists
    #
    #    # Get real object (not cached) otherwise
    #    $obj = $self->realm($realmname);
    #    return $obj if $self->error;
    #
    #    # Set expires time
    #    $obj->expires($now + $self->expiration)->mark(steady_time);
    #    $obj->cachekey($cachekey) if $cachekey;
    #    $self->cache->set($key, $obj) if $obj->is_valid;
    #
    #    # Return object
    #    return $obj;
}
sub cached_routes {
    deprecated 'The "WWW::Suffit::AuthDB::cached_routes" is deprecated in favor of "routes"';
    goto &routes;

    #    my $self = shift;
    #    my $url = _url_fix_localhost(shift(@_)); # Base URL (fixed!)
    #    my $cachekey = shift // '';
    #    my $now = time;
    #    $self->clean; # Flush error
    #
    #    # Get from cache
    #    $cachekey =~ s/[^a-z0-9]/?/gi;
    #    my $key = $cachekey
    #        ? sprintf('routes.%s.%s', $cachekey, $url // '__default')
    #        : sprintf('routes.%s', $url // '__default');
    #
    #    #my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    #    #my $val = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    #    my $val = $self->cache->get($key);
    #    return $val->{data} if $val && is_hash_ref($val) && $val->{exp} < $now;
    #
    #    # Get model
    #    my $model = $self->model;
    #
    #    # Get routes list
    #    my @routes = $model->route_getall;
    #    return $self->raise(500 => "E1376: %s", $model->error) if $model->error;
    #
    #    my $ret = {}; # `id`,`realmname`,`routename`,`method`,`url`,`base`,`path`
    #    foreach my $r (@routes) {
    #        my $base_url_fixed = _url_fix_localhost($r->{base});
    #        next unless $r->{realmname} && $base_url_fixed eq $url;
    #        $ret->{$r->{routename}} = {
    #            routename   => $r->{routename},
    #            realmname   => $r->{realmname},
    #            method      => $r->{method},
    #            path        => $r->{path},
    #        };
    #    }
    #
    #    # Set cache record
    #    $self->cache->set($key, {
    #        data        => $ret,
    #        exp         => $now + $self->expiration,
    #        cached      => steady_time,
    #        cachekey    => $cachekey,
    #    });
    #
    #    # Return data only!
    #    return $ret;
}

sub _url_fix_localhost {
    my $url = shift || DEFAULT_URL;
    my $uri = Mojo::URL->new($url);
    my $host = $uri->host // 'localhost';
    if ($host =~ /^(((\w+\.)*localhost)|(127\.0\.0\.1)|(ip6-(localhost|loopback))|(\[?\:{2,}1\]?))$/) {
        $uri->scheme('http')->host('localhost')->port(undef);
    }
    return $uri->to_string;
}

1;

__END__
