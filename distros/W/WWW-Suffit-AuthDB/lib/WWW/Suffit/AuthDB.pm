package WWW::Suffit::AuthDB;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB - Suffit Authorization Database

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB;

    my $authdb = WWW::Suffit::AuthDB->new(
            dsuri => "sqlite:///tmp/auth.db?sqlite_unicode=1"
        );

=head1 DESCRIPTION

Suffit Authorization Database

=head2 new

    my $authdb = WWW::Suffit::AuthDB->new(
            dsuri => "sqlite:///tmp/auth.db?sqlite_unicode=1",
            file => "/tmp/authdb.json"
        );
    die $authdb->error if $authdb->error;

Create new AuthDB object

=head2 access

    $authdb->access(
        controller  => $self, # The Mojo controller object
        username    => $username,
    ) or die "Access denied!";

This method performs access control

    $authdb->access(
        controller  => $self, # The Mojo controller object
        username    => "Bob",
        method      => "GET",
        base        => "https://www.example.com",
        path        => "/foo/bar",
        client_ip   => "192.168.0.123",
        headers     => {
            Accept      => "text/html,text/plain",
            Connection  => "keep-alive",
            Host        => "localhost:8695",
        },
    ) or die "Access denied!";

This method performs access control for outer requests

    $authdb->access(
        controller  => $self, # The Mojo controller object
        username    => "Bob",
        routename   => "index", # or 'route'
        base        => "https://www.example.com",
        client_ip   => "192.168.0.123",
        headers     => {
            Accept      => "text/html,text/plain",
            Connection  => "keep-alive",
            Host        => "localhost:8695",
        },
    ) or die "Access denied!";

... or by routename

Examples:

    <% if (has_access(path => url_for('settings')->to_string)) { %> ... <% } %>
    <% if (has_access(route => 'settings') { %> ... <% } %>

=head2 authen

    $authdb->authen("username", "password") or die $authdb->error;

Checks password by specified credential pair (username and password).
This method returns the User object or false status of check

=head2 authz

    $authdb->authz("username") or die $authdb->error;
    $authdb->authz("username", 1) or die $authdb->error;

This method checks authorization status by specified username as first argument.

The second argument defines a scope. This argument can be false or true.
false - determines the fact that internal authorization is being performed
(on Suffit system); true - determines the fact that external
authorization is being performed (on another sites)

The method returns the User object or false status of check

=head2 cache

Get cache instance

=head2 cached_group

    my $group = $authdb->cached_group("manager");

This method returns data of specified groupname as WWW::Suffit::AuthDB::Group object

=head2 cached_realm

    my $realm = $authdb->cached_realm("default");

This method returns data of specified realm name as WWW::Suffit::AuthDB::Realm object

=head2 cached_routes

    my $routes = $authdb->cached_routes("http://localhost/");

Returns hash of routes by base URL

=head2 cached_user

    my $user = $authdb->cached_user("alice");

This method returns data of specified username as WWW::Suffit::AuthDB::User object

=head2 clean

    $authdb->clean;

Cleans state vars on the AuthDB object and returns it

=head2 dump

    print $authdb->dump;

Returns JSON dump of loaded authentication database

=head2 export_data

Export data to JSON file

=head2 group

    my $group = $authdb->group("manager");

This method returns data of specified groupname as WWW::Suffit::AuthDB::Group object

=head2 group_del

    $authdb->group_del( "wheel" ) or die $authdb->error;

Delete group by groupname

=head2 group_enroll

    $authdb->group_enroll(
            groupname => "wheel",
            username => "alice",
        ) or die $authdb->error;

Add user to group members

=head2 group_get

    my %data = $authdb->group_get( "wheel" );
    my @groups = $authdb->group_get;

This method returns group's data or returns all groups as array of hashes

=head2 group_members

    my @members = $authdb->group_members( "wheel" );

This method returns group's members

=head2 group_pure_set

    $authdb->group_pure_set(
            groupname => "wheel",
            description => "Admin group",
        ) or die $authdb->error;

This method adds new group or doing update data of existing group in pure mode

=head2 group_set

    $authdb->group_set(
            groupname => "wheel",
            description => "Admin group",
        ) or die $authdb->error;

This method adds new group or doing update data of existing group

=head2 import_data

Import data from JSON file

=head2 load

    $authdb->load("/tmp/authdb.json");
    die $authdb->error if $authdb->error;

This method performs loading specified filename.

=head2 meta

    $authdb->meta("my.key", "my value") or die $authdb->error;

Sets meta-value by key

    my $val = $authdb->meta("my.key"); # my value
    die $authdb->error if $authdb->error;

Gets meta-value by key

    $authdb->meta("my.key", undef) or die $authdb->error;

Deletes meta-value by key

=head2 model

Get model instance

=head2 raise

    return $authdb->raise("Error string");
    return $authdb->raise("Error %s", "string");
    return $authdb->raise(200 => "Error string");
    return $authdb->raise(200 => "Error %s", "string");

Sets error string and returns false status. Also this method can performs sets the HTTP status code

=head2 realm

    my $realm = $authdb->realm("default");

This method returns data of specified realm name as WWW::Suffit::AuthDB::Realm object

=head2 realm_del

    $authdb->realm_del( "default" ) or die $authdb->error;

Delete realm by realmname

=head2 realm_get

    my %data = $authdb->realm_get( "default" );
    my @realms = $authdb->realm_get;

This method returns realm's data or returns all realms as array of hashes

=head2 realm_pure_set

    $authdb->realm_pure_set(
            realmname => "default",
            realm => "Strict Zone",
            description => "Default realm",
        ) or die $authdb->error;

This method adds new realm or doing update data of existing realm in pure mode

=head2 realm_requirements

    my @requirements = $authdb->realm_requirements( "default" );

This method returns list of realm's requirements

=head2 realm_routes

    my @routes = $authdb->realm_routes( "default" );

This method returns list of realm's routes

=head2 realm_set

    $authdb->realm_set(
            realmname => "default",
            realm => "Strict Zone",
            description => "Default realm",
        ) or die $authdb->error;

This method adds new realm or doing update data of existing realm

=head2 route_del

    $authdb->route_del( "index" ) or die $authdb->error;

Delete route by routename

=head2 route_get

    my %data = $authdb->route_get( "index" );
    my @routes = $authdb->route_get;

This method returns route's data or returns all routes as array of hashes

=head2 route_pure_set

    $authdb->route_pure_set(
            routename => "default",
            route => "Strict Zone",
            description => "Default route",
        ) or die $authdb->error;

This method adds new route or doing update data of existing route in pure mode

=head2 route_search

    my @routes = $authdb->route_search( $text );

This method performs search route by name fragment

=head2 route_set

    $authdb->route_set(
            routename => "default",
            route => "Strict Zone",
            description => "Default route",
        ) or die $authdb->error;

This method adds new route or doing update data of existing route

=head2 save

    $authdb->load();
    die $authdb->error if $authdb->error;

Performs flush database to file that was specified in constructor

    $authdb->load("/tmp/new-authdb.json");
    die $authdb->error if $authdb->error;

Performs flush database to file that specified directly

=head2 token_check

    $authdb->token_check($username, $jti)
        or die "The token is revoked";

This method checks status of the token in database

=head2 token_del

    $authdb->token_del($username, $jti)
        or die $authdb->error;

This method deletes token from database by username and token ID (jti)

=head2 token_get

    my @tokens = $authdb->token_get();
    my %data = $authdb->token_get( 123 );
    my %issued = $authdb->token_get($username, $jti);

Returns the token's metadata by id or pair - username and jti
By default (without specified arguments) this method returns list of all tokens

=head2 token_set

    $authdb->token_set(
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
    ) or die($authdb->error);

Ads new token to database

    $authdb->token_set(
        id          => 123,
        type        => 'api',
        jti         => $jti,
        username    => $username,
        clientid    => 'qwertyuiqwertyui',
        iat         => time,
        exp         => time + 3600,
        address     => '127.0.0.1',
    ) or die($authdb->error);

Performs modify token's data by id

=head2 user

    my $user = $authdb->user("alice");

This method returns data of specified username as WWW::Suffit::AuthDB::User object

=head2 user_del

    $authdb->user_del( "admin" ) or die $authdb->error;

Delete user by username

=head2 user_edit

    $authdb->user_edit(
        username    => $username,
        comment     => $comment,
        email       => $email,
        name        => $name,
        role        => $role,
    ) or вшу($authdb->error);

Edit general user data

=head2 user_get

    my %data = $authdb->user_get( "admin" );
    my @users = $authdb->user_get;

This method returns user's data or returns all users as array of hashes

=head2 user_groups

    my @groups = $authdb->user_groups( "admin" );

This method returns all groups of the user

=head2 user_passwd

    $authdb->user_passwd(
            username => "admin",
            password => "password",
        ) or die $authdb->error;

This method sets password for user

=head2 user_pure_set

    $authdb->user_pure_set(
            username => "admin",
            name => "Test User",
            # . . .
        ) or die $authdb->error;

This method adds new user or doing update data of existing user in pure mode

=head2 user_search

    my @users = $authdb->user_search( $text );

This method performs search user by name fragment

=head2 user_set

    $authdb->user_set(
            username => "admin",
            name => "Test User",
            # . . .
        ) or die $authdb->error;

This method adds new user or doing update data of existing user

=head2 user_setkeys

    $authdb->user_setkeys(
            username => "admin",
            public_key => $public_key,
            private_key => $private_key,
        ) or die $authdb->error;

This method sets keys for user

=head2 user_tokens

    my @tokens = $authdb->user_tokens( $username );

This method returns all tokens of specified user

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

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.00';

use Carp; # $Carp::Verbose = 1;

use Mojo::Base -base;
use Mojo::Util qw/md5_sum decode encode secure_compare/;
use Mojo::File qw/path/;
use Mojo::JSON qw/from_json to_json/;
use Mojo::Cache;
use Mojo::URL;

use Mojolicious::Routes::Pattern;

use Digest::SHA qw/sha1_hex sha224_hex sha256_hex sha384_hex sha512_hex/;

use WWW::Suffit::RefUtil qw/isnt_void is_integer is_array_ref is_hash_ref/;

use WWW::Suffit::AuthDB::Model;
use WWW::Suffit::AuthDB::User;
use WWW::Suffit::AuthDB::Group;
use WWW::Suffit::AuthDB::Realm;

use constant {
    MAX_CACHE_KEYS  => 1024,
    CACHE_EXPIRES   => 60*5, # 5min
    MAX_DISMISS     => 5,
    AUTH_HOLD_TIME  => 60*5, # 5min
    DEFAULT_URL     => 'http://localhost',
};

has data    => '';
has error   => '';
has code    => 200;
has file    => '';
has ds      => ''; # Data Source
has dsuri   => ''; # Data Source URI (= ds)
has address => '127.0.0.1';
has username=> '';

sub raise {
    my $self = shift(@_);
    return 0 unless scalar(@_);
    if (@_ == 1) {
        $self->error(shift(@_));
    } else {
        my $code_or_format = shift @_;
        if (is_integer($code_or_format)) {
            $self->code($code_or_format);
            if (@_ == 1) {
                $self->error(shift(@_));
            } else {
                $self->error(sprintf(shift(@_), @_));
            }
        } else {
            $self->error(sprintf($code_or_format, @_));
        }
    }
    return 0;
}
sub clean {
    my $self = shift;
    $self->error('');
    $self->code(200);
    $self->username('');
    $self->address('127.0.0.1');
    $self->{data} = '';
    return $self;
}
sub cache {
    my $self = shift;
    $self->{cache} ||= Mojo::Cache->new(max_keys => MAX_CACHE_KEYS);
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
    $self->error(""); # Flush error
    if ($file) {
        $self->file($file);
    } else {
        $file = $self->file;
    }
    return $self unless $file;
    $self->error("E1300: Can't load file \"$file\". File not found") && return $self
        unless -e $file;

    # Load data from file
    my $file_path = path($file);
    my $cont = decode('UTF-8', $file_path->slurp) // '';
    if (length($cont)) {
        my $data = eval { from_json($cont) };
        if ($@) {
            $self->error(sprintf("E1301: Can't load data from file \"%s\": %s", $file, $@));
        } elsif (ref($data) ne 'HASH') {
            $self->error(sprintf("E1302: File \"%s\" did not return a JSON object", $file));
        } else {
            $self->{data} = $data;
        }
    }

    return $self;
}
sub save {
    my $self = shift;
    my $file = shift || $self->file;
    return $self unless $file;

    # Save data to file
    my $json = eval { to_json($self->{data}) };
    if ($@) {
        $self->error(sprintf("E1303: Can't serialize data to JSON: %s", $@));
        return $self;
    }
    path($file)->spew(encode('UTF-8', $json));
    $self->error(sprintf("E1304: Can't save data to file \"%s\": %s", $file, ($! // 'unknown error'))) unless -e $file;

    return $self;
}
sub import_data {
    my $self = shift;
    my $file = shift;
    $self->error(""); # Flush error
    my $data = $self->load($file)->{data}; # Perl struct expected!
    return 0 if $self->error;
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;
    my $now = time();

    # Get users
    my $users_array = $data->{"users"} // [];
       $users_array = [] unless is_array_ref($users_array);
    my %grpsusrs = ();
    foreach my $user (@$users_array) {
        next unless is_hash_ref($user);
        my $username = $user->{"username"} // '';
        next unless length($username);

        # Add user to model
        $self->user_pure_set(
            username    => $username,
            name        => $user->{"name"} // '',
            email       => $user->{"email"} // '',
            password    => $user->{"password"} // '',
            algorithm   => $user->{"algorithm"} // '',
            role        => $user->{"role"} // '',
            flags       => $user->{"flags"} || 0,
            created     => $now,
            not_before  => $now,
            not_after   => $user->{"disabled"} ? $now : undef,
            public_key  => $user->{"public_key"} // '',
            private_key => $user->{"private_key"} // '',
            attributes  => $user->{"attributes"} // '',
            comment     => $user->{"comment"} // '',
        ) or return 0;

        # Add groups to grpsusrs
        my $groups = $user->{"groups"} || [];
           $groups = [] unless is_array_ref($groups);
        foreach my $g (@$groups) {
            $grpsusrs{"$g:$username"} = {
                groupname => $g,
                username  => $username,
            };
        }
    }

    # Get groups
    my $groups_array = $data->{"groups"} // [];
       $groups_array = [] unless is_array_ref($groups_array);
    foreach my $group (@$groups_array) {
        next unless is_hash_ref($group);
        my $groupname = $group->{"groupname"} // '';
        next unless length($groupname);

        # Add group to model
        $self->group_pure_set(
            groupname   => $groupname,
            description => $group->{"description"} // '',
        ) or return 0;

        # Add users to grpsusrs
        my $users = $group->{"users"} || [];
           $users = [] unless is_array_ref($users);
        foreach my $u (@$users) {
            $grpsusrs{"$groupname:$u"} = {
                groupname => $groupname,
                username  => $u,
            };
        }
    }

    # Add members to group
    foreach my $member (values %grpsusrs) {
        my %gu = $model->grpusr_get(%$member);
        return $self->raise($model->error) unless $model->status;
        next if $gu{id}; # Exists
        $model->grpusr_add(%$member);
        return $self->raise($model->error) unless $model->status;
    }

    # Get realms
    my $realms_array = $data->{"realms"} // [];
       $realms_array = [] unless is_array_ref($realms_array);
    foreach my $realm (@$realms_array) {
        next unless is_hash_ref($realm);
        my $realmname = $realm->{"realmname"} // '';
        next unless length($realmname);

        # Add realm to model
        $self->realm_pure_set(
            realmname   => $realmname,
            realm       => $realm->{"realm"} // '',
            satisfy     => $realm->{"satisfy"} // '',
            description => $realm->{"description"} // '',
        ) or return 0;

        # Set requirements
        unless ($model->realm_requirement_del($realmname)) {
            return $self->raise($model->error) unless $model->status;
        }
        my $requirements = $realm->{"requirements"} || [];
           $requirements = [] unless is_array_ref($requirements);
        foreach my $r (@$requirements) {
            $model->realm_requirement_add(
                realmname   => $realmname,
                provider    => $r->{"provider"} // '',
                entity      => $r->{"entity"} // '',
                op          => $r->{"op"} // '',
                value       => $r->{"value"} // '',
            );
            return $self->raise($model->error) unless $model->status;
        }

        # Release all routes
        unless ($model->route_release($realmname)) {
            return $self->raise($model->error) unless $model->status;
        }
    }

    # Get routes
    my $routes_array = $data->{"routes"} // [];
       $routes_array = [] unless is_array_ref($routes_array);
    foreach my $route (@$routes_array) {
        next unless is_hash_ref($route);
        my $routename = $route->{"routename"} // '';
        next unless length($routename);

        # Add route to model
        $self->route_pure_set(
            routename   => $routename,
            realmname   => $route->{"realmname"} // '',
            method      => $route->{"method"} // '',
            url         => $route->{"url"} // '',
            base        => $route->{"base"} // '',
            path        => $route->{"path"} // '',
        ) or return 0;
    }

    # Get meta
    my $meta_hash = $data->{"meta"} // {};
       $meta_hash = {} unless is_hash_ref($meta_hash);
    while (my ($k, $v) = each %$meta_hash) {
        last unless (defined($k) && length($k));
        $model->meta_set(key => $k, value => $v);
        return $self->raise($model->error) unless $model->status;
        delete $meta_hash->{$k}; # This is safe
    }

    # Fix to meta
    $model->meta_set(
        key     => "AuthDBSourceFile",
        value   => $self->file,
    );
    return $self->raise($model->error) unless $model->status;

    # Add inited key to meta
    $model->meta_set(
        key     => "meta.inited",
        value   => $now,
    );
    return $self->raise($model->error) unless $model->status;

    return 1;
}
sub export_data {
    my $self = shift;
    my $file = shift;
    $self->error(""); # Flush error
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;
    my $now = time();

    # Get users
    my @users = $self->user_get();
    return 0 if $self->error;
    foreach my $u (@users) {
        my $not_after = $u->{not_after} || 0;
        $u->{disabled} = ($not_after && $not_after < $now) ? \1 : \0;
        delete($u->{$_}) for qw/created id not_before not_after/;
    }

    # Get groups
    my @groups = $self->group_get();
    return 0 if $self->error;
    foreach my $g (@groups) {
        my $groupname = $g->{groupname} // '';
        next unless length $groupname;
        delete($g->{id});

        # Get members
        my @members = $self->group_members($groupname);
        return 0 if $self->error;
        my @usr = ();
        foreach my $m (@members) {
            push @usr, $m->{username};
        }
        $g->{users} = [@usr];
    }

    # Get realms
    my @realms = $self->realm_get();
    return 0 if $self->error;
    foreach my $r (@realms) {
        my $realmname = $r->{realmname} // '';
        next unless length $realmname;
        delete($r->{id});

        # Get requirements
        my @requirements = $self->realm_requirements($realmname);
        return 0 if $self->error;
        my @reqs = ();
        foreach my $q (@requirements) {
            delete($q->{id});
            delete($q->{realmname});
            push @reqs, $q;
        }
        $r->{requirements} = [@reqs];
    }

    # Get routes
    my @routes = $self->route_get();
    return 0 if $self->error;
    foreach my $r (@routes) {
        delete($r->{id});
    }

    # Get meta
    my @metas = $model->meta_get();
    return $self->raise($model->error) unless $model->status;
    my %meta = ();
    foreach my $m (@metas) {
        $meta{$m->{key}} = $m->{value};
    }
    #print Mojo::Util::dumper(\%meta);

    # Return
    $self->{data} = {
        users   => \@users,
        groups  => \@groups,
        realms  => \@realms,
        routes  => \@routes,
        meta    => \%meta,
    };
    $self->save($file);
    return 0 if $self->error;
    return 1;
}

# Interface methods
sub authen {
    my $self = shift;
    my $username = shift // '';
    my $password = shift // '';
    $self->error(""); # Flush error
    $self->code(200); # HTTP_OK

    # Validation username
    return $self->raise(400 => "E1305: No username specified") unless length($username); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1306: The username is too long (1-256 chars required)") unless length($username) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Validation password
    return $self->raise(400 => "E1307: No password specified") unless length($password); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1308: The password is too long (1-256 chars required)") unless length($password) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Get user data from AuthDB
    my $user = $self->cached_user($username);
    if ($self->error) {
        $self->code(500); # HTTP_INTERNAL_SERVER_ERROR
        return 0;
    }

    # Check consistency
    return $self->raise(401 => $user->error) unless $user->is_valid; # HTTP_UNAUTHORIZED

    # Get dismiss and updated by address and username
    my $model = $self->model;
    my %st = $model->stat_get($self->address, $username);
    return $self->raise(500 => $model->error) unless $model->status; # HTTP_INTERNAL_SERVER_ERROR
    my $dismiss = $st{dismiss} || 0;
    my $updated = $st{updated} || 0;
    if (($dismiss >= MAX_DISMISS) && (($updated + AUTH_HOLD_TIME) >= time)) {
        return $self->raise(403 => "E1309: Account is hold on 5 min"); # HTTP_FORBIDDEN
    }

    # Success?
    $password = encode('UTF-8', $password);
    my $h;
    if    ($user->algorithm eq 'MD5')    { $h = md5_sum($password)   }
    elsif ($user->algorithm eq 'SHA1')   { $h = sha1_hex($password)   }
    elsif ($user->algorithm eq 'SHA224') { $h = sha224_hex($password) }
    elsif ($user->algorithm eq 'SHA256') { $h = sha256_hex($password) }
    elsif ($user->algorithm eq 'SHA384') { $h = sha384_hex($password) }
    elsif ($user->algorithm eq 'SHA512') { $h = sha512_hex($password) }
    else {
        return $self->raise(501 => "E1310: Incorrect digest algorithm"); # HTTP_NOT_IMPLEMENTED
    }

    # Check!
    my $rslt = secure_compare($user->password, $h) ? 1 : 0;
    if ($rslt) { # Ok
        unless ($model->stat_set(address => $self->address, username => $username)) {
            return $self->raise(500 => $model->error); # HTTP_INTERNAL_SERVER_ERROR
        }
        return $user;
    }

    # Error
    unless ($model->stat_set(address => $self->address, username => $username, dismiss => ($dismiss + 1))) {
        return $self->raise(500 => $model->error); # HTTP_INTERNAL_SERVER_ERROR
    }

    # Fail
    return $self->raise(401 => "E1311: Wrong username or password"); # HTTP_UNAUTHORIZED
}
sub authz {
    my $self = shift;
    my $username = shift // $self->username // '';
    my $scope = shift || 0;
    $self->error(""); # Flush error
    $self->code(200); # HTTP_OK

    # Validation username
    return $self->raise(400 => "E1312: No username specified") unless length($username); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1313: The username is too long (1-256 chars required)") unless length($username) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Get user data from AuthDB
    my $user = $self->cached_user($username);
    if ($self->error) {
        $self->code(500); # HTTP_INTERNAL_SERVER_ERROR
        return 0;
    }

    # Check consistency
    return $self->raise(401 => $user->error) unless $user->is_valid; # HTTP_UNAUTHORIZED

    # Disabled/Banned
    return $self->raise(403 => "E1314: User is disabled") unless $user->is_enabled; # HTTP_FORBIDDEN

    # Internal or External
    if ($scope) { # External
        return $self->raise(403 => "E1339: External requests is blocked") unless $user->allow_ext; # HTTP_FORBIDDEN
    } else { # Internal (default)
        return $self->raise(403 => "E1340: Internal requests is blocked") unless $user->allow_int; # HTTP_FORBIDDEN
    }

    # Ok
    $user->is_authorized(1); # Set flag 'authorized'
    return $user;
}
sub access {
    my $self = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $controller = $args->{controller} // $args->{c}; # Controller
    croak "No controller specified" unless ref($controller);

    my $url = $args->{url} ? Mojo::URL->new($args->{url}) : $controller->req->url;
    my $username = $args->{username} // $args->{u} // $self->username // $url->to_abs->username // ''; # Username
    my $routename = $args->{routename} // $args->{route} // $controller->current_route // ''; # $self->match->endpoint->name
    my $method = $args->{method} // $controller->req->method // '';
    my $url_path = $args->{path} // $url->path->to_string;
    my $url_base = $args->{base} // $url->base->path_query('/')->to_string // '';
       $url_base =~ s/\/+$//;
    my $remote_ip = $args->{remote_ip} // $args->{client_ip} // $controller->remote_ip;
    my $headers = $args->{headers};
    $self->error(""); # Flush error
    $self->code(200); # HTTP_OK
    #$controller->log->warn($url_base);

    # Get routes list for $url_base
    my $routes = $self->cached_routes($url_base);
    unless ($routes) {
        $self->code(500); # HTTP_INTERNAL_SERVER_ERROR
        return 0;
    }
    my %route = ();
    if (exists($routes->{$routename})) { # By routename
        my $r = $routes->{$routename};
        %route = (%$r, rule => "by routename directly");
    } else { # By method and path
        foreach my $r (values %$routes) {
            my $m = $r->{method};
            next unless $m && (($m eq $method) || ($m eq 'ANY') || ($m eq '*'));
            my $p = $r->{path};
            next unless $p;

            # Search directly (eq)
            if ($p eq $url_path) {
                %route = (%$r, rule => "by method and path ($m $p)");
                last;
            }

            # Search by wildcard (*)
            if ($p =~ s/\*+$//) {
                if (index($url_path, $p) >= 0) {
                    %route = (%$r, rule => "by method and part of path ($m $p)");
                    last;
                } else {
                    next;
                }
            }

            # Match routes (:foo)
            for (qw/foo bar baz quz quux corge grault garply waldo fred plugh xyzzy thud/) {
                $p =~ s/[~]+/(":$_")/e or last
            }
            if (defined(Mojolicious::Routes::Pattern->new($p)->match($url_path))) {
                %route = (%$r, rule => "by method and pattern of path ($m $p)");
                last;
            }
        }
    }
    return 1 unless $route{realmname};
    $controller->log->debug(sprintf("[AuthDB::access] The route \"%s\" was detected %s", $route{routename} // '', $route{rule}));

    # Get realm instance
    my $realm = $self->cached_realm($route{realmname});
    if ($self->error) {
        $self->code(500); # HTTP_INTERNAL_SERVER_ERROR
        return 0;
    }
    return 1 unless $realm->id; # No realm - no authorization :-)
    $controller->log->debug(sprintf("[AuthDB::access] Use realm \"%s\"", $route{realmname})); # $controller->dumper($realm)

    # Get user data
    my $user = $self->cached_user($username);
    if ($self->error) {
        $self->code(500); # HTTP_INTERNAL_SERVER_ERROR
        return 0;
    }

    # Result of checks
    my @checks = ();

    # Check by user or group
    my @grants = ();
    #$controller->log->debug(">>>> Username = $username");
    #$controller->log->debug(sprintf(">>>> Groups   = %s", $controller->dumper($user->groups)));
    #$controller->log->debug($controller->dumper($realm->requirements->{'User/Group'}));
    #$self->requirements->{'User/Group'}
    if (my $s = $realm->_check_by_usergroup($username, $user->groups)) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, sprintf("User/Group (username=%s)", $username);
        }
    } else { push @checks, 0 }
    # Check by ip or host
    if (my $s = $realm->_check_by_host($remote_ip)) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, sprintf("Host (ip=%s)", $remote_ip);
        }
    } else { push @checks, 0 }
    # Check by ENV
    if (my $s = $realm->_check_by_env()) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, "Env";
        }
    } else { push @checks, 0 }
    # Check by Header
    if (my $s = $realm->_check_by_header(sub {
        my $_k = $_[0];
        return $headers->{$_k} if defined($headers) && is_hash_ref($headers);
        return $controller->req->headers->header($_k)
    })) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, "Header";
        }
    } else { push @checks, 0 }

    # Check default
    my $default = $realm->_check_by_default();

    # Result
    my $status = 0; # False by default
    my $sum = 0;
    $sum += $_ for @checks;
    my $satisfy_all = lc($realm->satisfy || "any") eq 'all' ? 1 : 0; # All -- true / Any -- 0 (default)
    if ($satisfy_all) { # All
        $status = 1 if ($sum > 0) && scalar(@checks) == $sum; # All tests is passed
    } else { # Any
        $status = 1 if $sum > 0; # One or more tests is passed
    }

    # Debug
    if ($status) {
        $controller->log->debug(sprintf('[AuthDB::access] Access allowed by %s rule(s). Satisfy=%s',
            join(", ", @grants), $satisfy_all ? 'All' : 'Any'));
    } else {
        $controller->log->debug(sprintf('[AuthDB::access] Access %s by default. Satisfy=%s',
            $default ? 'allowed' : 'denied', $satisfy_all ? 'All' : 'Any'));
    }

    # Summary
    my $summary = $status ? 1 : $default; # True - allowed; False - denied
    unless ($summary) { # HTTP_FORBIDDEN
        $self->code(403);
        return 0; # Access denied
    }

    # Ok
    return 1;
}

# Methods that returns sub-objects
sub user {
    my $self = shift;
    my $username = shift // '';
    $self->error(""); # Flush error

    # Check username
    return WWW::Suffit::AuthDB::User->new() unless length($username); # No user specified

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::User->new(error => $self->error);
    }

    # Get data from model
    my %data = $model->user_get($username);
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::User->new(error => $self->error);
    }
    return WWW::Suffit::AuthDB::User->new() unless $data{id}; # No user found

    # Get groups list of user
    my @grpusr = $model->grpusr_get( username => $username );
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::User->new(error => $self->error);
    }
    $data{groups} = [sort map {$_->[1]} @grpusr];

    return WWW::Suffit::AuthDB::User->new(%data);
}
sub group {
    my $self = shift;
    my $groupname = shift // '';
    $self->error(""); # Flush error

    # Check username
    return WWW::Suffit::AuthDB::Group->new() unless length($groupname); # No user specified

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::Group->new(error => $self->error);
    }

    # Get data from model
    my %data = $model->group_get($groupname);
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::Group->new(error => $self->error);
    }
    return WWW::Suffit::AuthDB::Group->new() unless $data{id};

    # Get users list of group
    my @grpusr = $model->grpusr_get( groupname => $groupname );
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::Group->new(error => $self->error);
    }
    $data{users} = [sort map {$_->[2]} @grpusr];

    return WWW::Suffit::AuthDB::Group->new(%data);
}
sub realm {
    my $self = shift;
    my $realmname = shift // '';
    $self->error(""); # Flush error

    # Check realmname
    return WWW::Suffit::AuthDB::Realm->new() unless length($realmname); # No realm specified

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::Realm->new(error => $self->error);
    }

    # Get data from model
    my %data = $model->realm_get($realmname);
    unless ($model->status) {
        $self->error($model->error);
        return WWW::Suffit::AuthDB::Realm->new(error => $self->error);
    }
    return WWW::Suffit::AuthDB::Realm->new() unless $data{id}; # No realm found

    # Get requirements
    my @requirements = $model->realm_requirements($realmname);
    unless ($model->status) {
        $self->error($model->error);
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

    return WWW::Suffit::AuthDB::Realm->new(%data);
}

# Methods that returns cached sub-objects (cached methods)
sub cached_routes {
    my $self = shift;
    my $url = _url_fix_localhost(shift(@_)); # Base URL (fixed!)
    $self->error(""); # Flush error

    # Get from cache
    my $key = sprintf('routes.%s', $url // '__default');
    my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    my $val = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    return $val->{data} if $val && is_hash_ref($val) && $val->{exp} < time;

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get routes list
    my @routes = $model->route_getall;
    return $self->raise($model->error) unless $model->status;

    my $ret = {};
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

    $self->cache->set($key, {data => $ret, exp => time + CACHE_EXPIRES});
    return $ret;
}
sub cached_user {
    my $self = shift;
    my $username = shift // '';

    # Get from cache
    my $key = sprintf('user.%s', $username // '__anonymous');
    my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    my $ret = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    return $ret if $ret && $ret->isa("WWW::Suffit::AuthDB::User") && $ret->is_valid && $ret->mark;

    # Get real object
    $ret = $self->user($username);
    return $ret if $self->error;

    # Set expires time
    $ret->expires(time + CACHE_EXPIRES);
    $self->cache->set($key, $ret) if $ret->is_valid;

    # Return object
    return $ret;
}
sub cached_group {
    my $self = shift;
    my $groupname = shift // '';

    # Get from cache
    my $key = sprintf('group.%s', $groupname // '__default');
    my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    my $ret = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    return $ret if $ret && $ret->isa("WWW::Suffit::AuthDB::Group") && $ret->is_valid && $ret->mark;

    # Get real object
    $ret = $self->group($groupname);
    return $ret if $self->error;

    # Set expires time
    $ret->expires(time + CACHE_EXPIRES);
    $self->cache->set($key, $ret) if $ret->is_valid;

    # Return object
    return $ret;
}
sub cached_realm {
    my $self = shift;
    my $realmname = shift // '';

    # Get from cache
    my $key = sprintf('realm.%s', $realmname // '__default');
    my $upd = $self->meta(sprintf("%s.updated", $key)) // 0;
    my $ret = (($upd + CACHE_EXPIRES) < time) ? $self->cache->get($key) : undef;
    return $ret if $ret && $ret->isa("WWW::Suffit::AuthDB::Realm") && $ret->is_valid && $ret->mark;

    # Get real object
    $ret = $self->realm($realmname);
    return $ret if $self->error;

    # Set expires time
    $ret->expires(time + CACHE_EXPIRES);
    $self->cache->set($key, $ret) if $ret->is_valid;

    # Return object
    return $ret;
}

# Users CRUD
sub user_search {
    my $self = shift;
    my $username = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get data from model
    my @table = $model->user_search($username);
    $self->error($model->error) unless $model->status;

    return @table;
}
sub user_get {
    my $self = shift;
    my $username = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get all users
    unless (length($username)) {
        my @table = $model->user_getall;
        $self->error($model->error) unless $model->status;
        return @table;
    }

    # Get user data
    my %data = $model->user_get($username);
    $self->error($model->error) unless $model->status;
    return %data;
}
sub user_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error
    my $now = time();

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get password
    if (my $password = $data{password}) {
        $password = encode('UTF-8', $password);
        my $alg = $data{algorithm} // '';
        my $h = '';
        if    ($alg eq 'MD5')    { $h = md5_sum($password)   }
        elsif ($alg eq 'SHA1')   { $h = sha1_hex($password)   }
        elsif ($alg eq 'SHA224') { $h = sha224_hex($password) }
        elsif ($alg eq 'SHA256') { $h = sha256_hex($password) }
        elsif ($alg eq 'SHA384') { $h = sha384_hex($password) }
        elsif ($alg eq 'SHA512') { $h = sha512_hex($password) }
        else {
            return $self->raise("E1315: Incorrect digest algorithm");
        }
        $data{password} = $h;
    }

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise($model->error) unless $model->status;

    # Set or add
    $data{not_after} ||= 0;
    if ($data{id}) { # Update (Set)
        $data{password} ||= $old{password};
        $model->user_set(%data);
    } else { # Insert (Add)
        if ($old{id}) {
            $self->error("E1316: User already exists");
            return 0;
        }
        $data{created} = $now;
        $data{not_before} = $now;
        $model->user_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $data{username}), $now);
}
sub user_pure_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get current data from model
    my %cur = $model->user_get($data{username});
    return $self->raise($model->error) unless $model->status;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->user_set(%data);
    } else { # Insert (Add)
        $model->user_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $data{username}), time);
}
sub user_del {
    my $self = shift;
    my $username = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Delete user
    unless ($model->user_del($username)) {
        return $self->raise($model->error);
    }

    # Delete all group relations
    unless ($model->grpusr_del(username => $username)) {
        return $self->raise($model->error);
    }

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $username), time);
    return 1;
}
sub user_groups {
    my $self = shift;
    my $username = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get groups list of user
    my @groups = $model->user_groups( $username );
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    return @groups;
}
sub user_passwd {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise($model->error) unless $model->status;
    return $self->raise("E1317: No user found") unless $old{id};

    # Get password
    if (my $password = $data{password}) {
        $password = encode('UTF-8', $password);
        my $alg = $old{algorithm} // '';
        my $h = '';
        if    ($alg eq 'MD5')    { $h = md5_sum($password)   }
        elsif ($alg eq 'SHA1')   { $h = sha1_hex($password)   }
        elsif ($alg eq 'SHA224') { $h = sha224_hex($password) }
        elsif ($alg eq 'SHA256') { $h = sha256_hex($password) }
        elsif ($alg eq 'SHA384') { $h = sha384_hex($password) }
        elsif ($alg eq 'SHA512') { $h = sha512_hex($password) }
        else {
            return $self->raise("E1318: Incorrect digest algorithm");
        }
        $data{password} = $h;
    } else {
        return $self->raise("E1319: No password specified");
    }

    # Set new password
    $model->user_passwd(%data);

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $data{username}), time);
}
sub user_edit {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise($model->error) unless $model->status;
    return $self->raise("E1320: No user found") unless $old{id};

    # Set new data
    $model->user_edit(%data, id => $old{id});

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $data{username}), time);
}
sub user_setkeys {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise($model->error) unless $model->status;
    return $self->raise("E1321: No user found") unless $old{id};

    # Set new keys
    $model->user_setkeys(%data, id => $old{id});

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("user.%s.updated", $data{username}), time);
}
sub user_tokens {
    my $self = shift;
    my $username = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get user tokens
    my @table = $model->user_tokens($username);
    $self->error($model->error) unless $model->status;

    return @table;
}

# Groups CRUD
sub group_get {
    my $self = shift;
    my $groupname = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get all groups
    unless (length($groupname)) {
        my @table = $model->group_getall;
        $self->error($model->error) unless $model->status;
        return @table;
    }

    # Get group data
    my %data = $model->group_get($groupname);
    $self->error($model->error) unless $model->status;

    return %data;
}
sub group_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->group_get($data{groupname});
    return $self->raise($model->error) unless $model->status;

    # Set or add group data
    if ($data{id}) { # Update (Set)
        $model->group_set(%data);
    } else { # Insert (Add)
        return $self->raise("E1322: Group already exists") if $old{id};
        $model->group_add(%data);
    }

    # Set users
    my $users = $data{users} || [];
    unless ($model->grpusr_del( groupname => $data{groupname} )) {
        return $self->raise($model->error);
    }
    foreach my $username (@$users) {
        unless ($model->grpusr_add(groupname => $data{groupname}, username => $username)) {
            return $self->raise($model->error);
        }
        $self->meta(sprintf("user.%s.updated", $username), time);
    }
    $model->group_set(%data);

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("group.%s.updated", $data{groupname}), time);
}
sub group_pure_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get current data from model
    my %cur = $model->group_get($data{groupname});
    return $self->raise($model->error) unless $model->status;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->group_set(%data);
    } else { # Insert (Add)
        $model->group_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("group.%s.updated", $data{groupname}), time);
}
sub group_del {
    my $self = shift;
    my $groupname = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Delete group
    unless ($model->group_del($groupname)) {
        return $self->raise($model->error);
    }

    # Delete all user relations
    unless ($model->grpusr_del(groupname => $groupname)) {
        return $self->raise($model->error);
    }

    # Sets up the updated tag
    return $self->meta(sprintf("group.%s.updated", $groupname), time);
}
sub group_members {
    my $self = shift;
    my $groupname = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get users list of group
    my @members = $model->group_members( $groupname );
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    return @members;
}
sub group_enroll {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get existed relation
    my %old = $model->grpusr_get(%data);
    return $self->raise($model->error) unless $model->status;
    return 1 if $old{id};

    # Enroll
    unless ($model->grpusr_add(%data)) {
        return $self->raise($model->error);
    }

    # Sets up the updated tag
    $self->meta(sprintf("user.%s.updated", $data{username}), time);
    return 0 unless $model->status;
    $self->meta(sprintf("group.%s.updated", $data{groupname}), time);
    return 0 unless $model->status;

    return 1;
}

# Realms CRUD
sub realm_get {
    my $self = shift;
    my $realmname = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get all realms
    unless (length($realmname)) {
        my @table = $model->realm_getall;
        $self->error($model->error) unless $model->status;
        return @table;
    }

    # Get realm data
    my %data = $model->realm_get($realmname);
    $self->error($model->error) unless $model->status;

    return %data;
}
sub realm_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->realm_get($data{realmname});
    return $self->raise($model->error) unless $model->status;

    # Set or add realm data
    if ($data{id}) { # Update (Set)
        $model->realm_set(%data);
    } else { # Insert (Add)
        return $self->raise("E1323: Realm already exists") if $old{id};
        $model->realm_add(%data);
    }

    # Set routes
    my $routes = $data{routes} || [];
    unless ($model->route_release( $data{realmname} )) {
        return $self->raise($model->error);
    }
    foreach my $routename (@$routes) {
        unless ($model->route_assign(routename => $routename, realmname => $data{realmname})) {
            return $self->raise($model->error);
        }
    }

    # Set requirements
    my $requirements = $data{requirements} || [];
    unless ($model->realm_requirement_del( $data{realmname} )) {
        return $self->raise($model->error);
    }
    foreach my $req (@$requirements) {
        next unless is_hash_ref($req);
        unless ($model->realm_requirement_add(%$req, realmname => $data{realmname})) {
            return $self->raise($model->error);
        }
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("realm.%s.updated", $data{realmname}), time);
}
sub realm_pure_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get current data from model
    my %cur = $model->realm_get($data{realmname});
    return $self->raise($model->error) unless $model->status;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->realm_set(%data);
    } else { # Insert (Add)
        $model->realm_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("realm.%s.updated", $data{realmname}), time);
}
sub realm_del {
    my $self = shift;
    my $realmname = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Delete realm
    unless ($model->realm_del($realmname)) {
        return $self->raise($model->error);
    }

    # Delete realm's requirements
    unless ($model->realm_requirement_del($realmname)) {
        return $self->raise($model->error);
    }

    # Release all related routes
    unless ($model->route_release($realmname)) {
        return $self->raise($model->error);
    }

    # Sets up the updated tag
    return $self->meta(sprintf("realm.%s.updated", $realmname), time);
}
sub realm_requirements {
    my $self = shift;
    my $realmname = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get realm requirements
    my @table = $model->realm_requirements($realmname);
    $self->error($model->error) unless $model->status;

    return @table;
}
sub realm_routes {
    my $self = shift;
    my $realmname = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get realm routes
    my @table = $model->realm_routes($realmname);
    $self->error($model->error) unless $model->status;

    return @table;
}

# Routes CRUD
sub route_get {
    my $self = shift;
    my $routename = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get all routes
    unless (length($routename)) {
        my @table = $model->route_getall();
        $self->error($model->error) unless $model->status;
        return @table;
    }

    # Get route data
    my %data = $model->route_get($routename);
    $self->error($model->error) unless $model->status;

    return %data;
}
sub route_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get old data from model
    my %old = $model->route_get($data{routename});
    return $self->raise($model->error) unless $model->status;

    # Set or add route data
    if ($data{id}) { # Update (Set)
        $model->route_set(%data);
    } else { # Insert (Add)
        return $self->raise("E1324: Route already exists") if $old{id};
        $model->route_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("routes.%s.updated", $data{base} // '__default'), time);
}
sub route_pure_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get current data from model
    my %cur = $model->route_get($data{routename});
    return $self->raise($model->error) unless $model->status;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $data{id} = $cur{id};
        $model->route_set(%data);
    } else { # Insert (Add)
        $model->route_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Sets up the updated tag
    return $self->meta(sprintf("routes.%s.updated", $data{base} // '__default'), time);
}
sub route_del {
    my $self = shift;
    my $routename = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Delete route
    unless ($model->route_del($routename)) {
        return $self->raise($model->error);
    }
}
sub route_search {
    my $self = shift;
    my $text = shift;
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get data from model
    my @table = $model->route_search($text);
    $self->error($model->error) unless $model->status;

    return @table;
}

# Tokens CRUD
sub token_get {
    my $self = shift;
    my ($id, $username, $jti);
    if (scalar(@_) == 1) { $id = shift }
    elsif (scalar(@_) == 2) {($username, $jti) = @_}
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    unless ($model->status) {
        $self->error($model->error);
        return ();
    }

    # Get data from model
    my @data = ();
    if ($id) {
        @data = $model->token_get($id); # hash returs
    } elsif ($jti) {
        @data = $model->token_get_cond('api', username => $username, jti => $jti); # hash returs
    } else {
        @data = $model->token_getall(); # table returs
    }
    $self->error($model->error) unless $model->status;

    return @data;
}
sub token_set {
    my $self = shift;
    my %data = @_;
    $self->error(""); # Flush error
    $data{type} //= 'session';

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Delete expired tokens
    return $self->raise($model->error) unless $model->token_del;

    # Get old data from model
    my %old;
    if ($data{id}) {
        %old = $model->token_get($data{id});
        return $self->raise($model->error) unless $model->status;
    } elsif ($data{type} eq 'session') {
        %old = $model->token_get_cond('session', %data);
        return $self->raise($model->error) unless $model->status;
    }

    # Set or add data
    if ($old{id}) { # Update (Set)
        $data{id} = $old{id};
        $model->token_set(%data);
    } else { # Insert (Add)
        $model->token_add(%data);
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    return 1;
}
sub token_del {
    my $self = shift;
    my $username = shift // '';
    my $jti = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get data from model
    my %data = $model->token_get_cond('api', username => $username, jti => $jti);
    return $self->raise($model->error) unless $model->status;
    return 1 unless $data{id};

    # Delete token
    unless ($model->token_del($data{id})) {
        return $self->raise($model->error);
    }

    return 1;
}
sub token_check {
    my $self = shift;
    my $username = shift // '';
    my $jti = shift // '';
    $self->error(""); # Flush error

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    # Get data from model
    my %data = $model->token_get_cond('api', username => $username, jti => $jti);
    return $self->raise($model->error) unless $model->status;

    # Check
    return 1 if $data{id};
    return 0;
}

# Meta CRUD
sub meta {
    my $self = shift;
    my $i = scalar(@_);
    my $key = shift // '';
    my $val = shift;
    $self->error(""); # Flush error

    # No key specified
    return $self->raise("E1325: No key specified") unless length($key);

    # Get model
    my $model = $self->model;
    return $self->raise($model->error) unless $model->status;

    my $ret;
    if ($i == 1) { # get
        my %kv = $model->meta_get($key);
        $ret = $kv{"value"};
    } elsif ($i > 1) {
        if (defined($val)) { # set
            $ret = $model->meta_set(key => $key, value => $val);
        } else { # del
            $ret = $model->meta_del($key);
        }
    }

    # Error
    return $self->raise($model->error) unless $model->status;

    # Ok
    return $ret;
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
