package WWW::Suffit::AuthDB::Role::CRUD;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Role::CRUD - Suffit AuthDB methods for CRUD

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB;

    my $authdb = WWW::Suffit::AuthDB->with_roles('+CRUD')->new( ... );

=head1 DESCRIPTION

Suffit AuthDB methods for CRUD

=head1 METHODS

This class extends L<WWW::Suffit::AuthDB> and implements the following new ones methods

=head2 export_data

    $authdb->export_data->save; # to `sourcefile`
    $authdb->export_data("/tmp/authdb.json");

Export all data to JSON file

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

=head2 group_pset

    $authdb->group_pset(
            groupname => "wheel",
            description => "Admin group",
        ) or die $authdb->error;

This method adds new group or doing update data of existing group in pure mode

=head2 group_pure_set

This method is deprecated! See L</group_pset>

=head2 group_set

    $authdb->group_set(
            groupname => "wheel",
            description => "Admin group",
        ) or die $authdb->error;

This method adds new group or doing update data of existing group

=head2 import_data

    $authdb->load->import_data; # from `sourcefile` preloaded data
    $authdb->import_data("/tmp/authdb.json");

Import all data from JSON file

=head2 meta

    $authdb->meta("my.key", "my value") or die $authdb->error;

Sets meta-value by key

    my $val = $authdb->meta("my.key"); # my value
    die $authdb->error if $authdb->error;

Gets meta-value by key

    $authdb->meta("my.key", undef) or die $authdb->error;

Deletes meta-value by key

=head2 realm_del

    $authdb->realm_del( "default" ) or die $authdb->error;

Delete realm by realmname

=head2 realm_get

    my %data = $authdb->realm_get( "default" );
    my @realms = $authdb->realm_get;

This method returns realm's data or returns all realms as array of hashes

=head2 realm_pset

    $authdb->realm_pset(
            realmname => "default",
            realm => "Strict Zone",
            description => "Default realm",
        ) or die $authdb->error;

This method adds new realm or doing update data of existing realm in pure mode

=head2 realm_pure_set

This method is deprecated! See L</realm_pset>

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

    $authdb->route_del( "root" ) or die $authdb->error;

Delete route by routename

=head2 route_get

    my %data = $authdb->route_get( "root" );
    my @routes = $authdb->route_get;

This method returns route's data or returns all routes as array of hashes

=head2 route_pset

    $authdb->route_pset(
            realmname   => "default",
            routename   => "root",
            method      => "GET",
            url         => "https://localhost:8695/",
            base        => "https://localhost:8695/",
            path        => "/",
        ) or die $authdb->error;

This method adds new route or doing update data of existing route in pure mode

=head2 route_pure_set

This method is deprecated! See L</route_pset>

=head2 route_search

    my @routes = $authdb->route_search( $text );

This method performs search route by name fragment

=head2 route_set

    $authdb->route_set(
            realmname   => "default",
            routename   => "root",
            method      => "GET",
            url         => "https://localhost:8695/",
            base        => "https://localhost:8695/",
            path        => "/",
        ) or die $authdb->error;

This method adds new route or doing update data of existing route

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

Adds new token to database

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

Updates token's data by id

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
    ) or die($authdb->error);

Edit general user data only

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

=head2 user_pset

    $authdb->user_pset(
            username => "foo",
            name => "Test User",
            email       => 'test@localhost',
            password    => "098f6bcd4621d373cade4e832627b4f6",
            algorithm   => "MD5",
            role        => "Test user",
            flags       => 0,
            not_before  => time(),
            not_after   => undef,
            public_key  => "",
            private_key => "",
            attributes  => qq/{"disabled": 0}/,
            comment     => "This user added for test",
        ) or die $authdb->error;

This method adds new user or doing update data of existing user in pure mode

=head2 user_pure_set

This method is deprecated! See L</user_pset>

=head2 user_search

    my @users = $authdb->user_search( $text );

This method performs search user by name fragment

=head2 user_set

    $authdb->user_set(
            username    => "foo",
            name        => "Test User",
            email       => 'test@localhost',
            password    => "MyPassword", # Unsafe password
            algorithm   => "SHA256",
            role        => "Test user",
            flags       => 0,
            not_before  => time(),
            not_after   => undef,
            public_key  => "",
            private_key => "",
            attributes  => qq/{"disabled": 0}/,
            comment     => "This user added for test",
        ) or die $authdb->error;

This method adds new user or doing update data of existing user

=head2 user_setkeys

    $authdb->user_setkeys(
            username => "foo",
            public_key => $public_key,
            private_key => $private_key,
        ) or die $authdb->error;

This method sets keys for user

=head2 user_tokens

    my @tokens = $authdb->user_tokens( $username );

This method returns all tokens of specified user

=head2 ERROR CODES

List of error codes describes in L<WWW::Suffit::AuthDB>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>, L<Role::Tiny>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base -role;

use Acrux::RefUtil qw/is_hash_ref is_array_ref is_true_flag/;

use Mojo::Util qw/deprecated/;

# Meta CRUD
sub meta {
    my $self = shift;
    my $i = scalar(@_);
    my $key = shift // '';
    my $val = shift;
    $self->clean; # Flush error

    # No key specified
    return $self->raise(400 => "E1330: No key specified") unless length($key);

    # Get model
    my $model = $self->model;

    # get/set/del
    if ($i == 1) { # get
        my %kv = $model->meta_get($key);
        return $self->raise(500 => "E1329: %s", $model->error) if $model->error;
        return $kv{"value"};
    } elsif ($i > 1) {
        if (defined($val)) { # set
            $model->meta_set(key => $key, value => $val)
                or return $self->raise(500 => "E1331: %s", $model->error || 'Database request error (meta_set)');
        } else { # del
            $model->meta_del($key)
                or return $self->raise(500 => "E1339: %s", $model->error || 'Database request error (meta_del)');
        }
    }

    # Ok
    return 1;
}

# User CRUD
sub user_set {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error
    my $now = time();

    # Get model
    my $model = $self->model;

    # Get password
    if (my $password = $data{password}) {
        my $digest = $self->checksum($password, $data{algorithm} // '');
        return $self->raise(400 => "E1332: Incorrect digest algorithm") unless $digest;
        $data{password} = $digest;
    }

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise(500 => "E1333: %s", $model->error) if $model->error;

    # Set or add
    $data{not_after} ||= 0;
    if ($data{id}) { # Update (Set)
        $data{password} ||= $old{password};
        $model->user_set(%data)
            or return $self->raise(500 => "E1351: %s", $model->error || 'Database request error (user_set)');
    } else { # Insert (Add)
        return $self->raise(400 => "E1334: User already exists") if $old{id};
        $data{created} = $now;
        $data{not_before} = $now;
        $model->user_add(%data)
            or return $self->raise(500 => "E1335: %s", $model->error || 'Database request error (user_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $data{username}), $now);

    # Ok
    return 1;
}
sub user_pset {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get current data from model
    my %cur = $model->user_get($data{username});
    return $self->raise(500 => "E1333: %s", $model->error) if $model->error;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->user_set(%data)
            or return $self->raise(500 => "E1351: %s", $model->error || 'Database request error (user_set)');
    } else { # Insert (Add)
        $model->user_add(%data)
            or return $self->raise(500 => "E1335: %s", $model->error || 'Database request error (user_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $data{username}), time);

    # Ok
    return 1;
}
sub user_edit {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise(500 => "E1333: %s", $model->error) if $model->error;
    return $self->raise(400 => "E1336: User not found") unless $old{id};

    # Set new data
    $model->user_edit(%data, id => $old{id})
        or return $self->raise(500 => "E1337: %s", $model->error || 'Database request error (user_edit)');

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $data{username}), time);

    # Ok
    return 1;
}
sub user_get {
    my $self = shift;
    my $username = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get all users
    unless (length($username)) {
        my @table = $model->user_getall;
        $self->raise(500 => "E1338: %s", $model->error) if $model->error;
        return @table;
    }

    # Get user data
    my %data = $model->user_get($username);
    $self->raise(500 => "E1333: %s", $model->error) if $model->error;
    return %data;
}
sub user_del {
    my $self = shift;
    my $username = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Delete user
    $model->user_del($username)
        or return $self->raise(500 => "E1340: %s", $model->error || 'Database request error (user_del)');

    # Delete all group relations
    $model->grpusr_del(username => $username)
        or return $self->raise(500 => "E1341: %s", $model->error || 'Database request error (grpusr_del)');

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $username), time);

    # Ok
    return 1;
}
sub user_search {
    my $self = shift;
    my $username = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get data from model
    my @table = $model->user_search($username);
    $self->raise(500 => "E1342: %s", $model->error) if $model->error;
    return @table;
}
sub user_groups {
    my $self = shift;
    my $username = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get groups list of user
    my @groups = $model->user_groups( $username );
    $self->raise(500 => "E1343: %s", $model->error) if $model->error;

    return @groups;
}
sub user_passwd {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise(500 => "E1333: %s", $model->error) if $model->error;
    return $self->raise(400 => "E1336: User not found") unless $old{id};

    # Get password
    if (my $password = $data{password}) {
        my $digest = $self->checksum($password, $old{algorithm});
        return $self->raise(400 => "E1332: Incorrect digest algorithm") unless $digest;
        $data{password} = $digest;
    } else {
        return $self->raise(400 => "E1344: No password specified");
    }

    # Set new password
    $model->user_passwd(%data)
        or return $self->raise(500 => "E1345: %s", $model->error || 'Database request error (user_passwd)');

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $data{username}), time);

    # Ok
    return 1;
}
sub user_setkeys {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->user_get($data{username});
    return $self->raise(500 => "E1333: %s", $model->error) if $model->error;
    return $self->raise(400 => "E1336: User not found") unless $old{id};

    # Set new keys
    $model->user_setkeys(%data, id => $old{id})
        or return $self->raise(500 => "E1346: %s", $model->error || 'Database request error (user_setkeys)');

    # Sets up the updated tag
    #return $self->meta(sprintf("user.%s.updated", $data{username}), time);

    # Ok
    return 1;
}
sub user_tokens {
    my $self = shift;
    my $username = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get user tokens
    my @table = $model->user_tokens($username);
    $self->raise(500 => "E1347: %s", $model->error) if $model->error;

    return @table;
}

# Group CRUD
sub group_set {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->group_get($data{groupname});
    return $self->raise(500 => "E1348: %s", $model->error) if $model->error;

    # Set or add group data
    if ($data{id}) { # Update (Set)
        $model->group_set(%data)
            or return $self->raise(500 => "E1353: %s", $model->error || 'Database request error (group_set)');
    } else { # Insert (Add)
        return $self->raise(400 => "E1349: Group already exists") if $old{id};
        $model->group_add(%data)
            or return $self->raise(500 => "E1350: %s", $model->error || 'Database request error (group_add)');
    }

    # Set users
    my $users = $data{users} || [];
    $model->grpusr_del( groupname => $data{groupname} )
        or return $self->raise(500 => "E1341: %s", $model->error || 'Database request error (grpusr_del)');
    foreach my $username (@$users) {
        $model->grpusr_add(groupname => $data{groupname}, username => $username)
            or return $self->raise(500 => "E1352: %s", $model->error || 'Database request error (grpusr_add)');
        #$self->meta(sprintf("user.%s.updated", $username), time);
    }
    $model->group_set(%data)
        or return $self->raise(500 => "E1353: %s", $model->error || 'Database request error (group_set)');

    # Sets up the updated tag
    #return $self->meta(sprintf("group.%s.updated", $data{groupname}), time);

    # Ok
    return 1;
}
sub group_pset {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get current data from model
    my %cur = $model->group_get($data{groupname});
    return $self->raise(500 => "E1348: %s", $model->error) if $model->error;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->group_set(%data)
            or return $self->raise(500 => "E1353: %s", $model->error || 'Database request error (group_set)');
    } else { # Insert (Add)
        $model->group_add(%data)
            or return $self->raise(500 => "E1350: %s", $model->error || 'Database request error (group_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("group.%s.updated", $data{groupname}), time);

    # Ok
    return 1;
}
sub group_get {
    my $self = shift;
    my $groupname = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get all groups
    unless (length($groupname)) {
        my @table = $model->group_getall;
        $self->raise(500 => "E1355: %s", $model->error) if $model->error;
        return @table;
    }

    # Get group data
    my %data = $model->group_get($groupname);
    $self->raise(500 => "E1348: %s", $model->error) if $model->error;
    return %data;
}
sub group_del {
    my $self = shift;
    my $groupname = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Delete group
    $model->group_del($groupname)
        or return $self->raise(500 => "E1356: %s", $model->error || 'Database request error (group_del)');

    # Delete all user relations
    $model->grpusr_del(groupname => $groupname)
        or return $self->raise(500 => "E1341: %s", $model->error || 'Database request error (grpusr_del)');

    # Sets up the updated tag
    #return $self->meta(sprintf("group.%s.updated", $groupname), time);

    # Ok
    return 1;
}
sub group_enroll {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get existed relation
    my %old = $model->grpusr_get(%data);
    return $self->raise(500 => "E1357: %s", $model->error) if $model->error;
    return 1 if $old{id};

    # Enroll
    $model->grpusr_add(%data)
        or return $self->raise(500 => "E1352: %s", $model->error || 'Database request error (grpusr_add)');

    # Sets up the updated tag
    #$self->meta(sprintf("user.%s.updated", $data{username}), time);
    #return 0 unless $model->status;
    #$self->meta(sprintf("group.%s.updated", $data{groupname}), time);
    #return 0 unless $model->status;

    # Ok
    return 1;
}
sub group_members {
    my $self = shift;
    my $groupname = shift;
    $self->clean; # Flush error

     # Get model
    my $model = $self->model;

    # Get users list of group
    my @members = $model->group_members( $groupname );
    $self->raise(500 => "E1358: %s", $model->error) if $model->error;

    return @members;
}

# Realm CRUD
sub realm_set {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->realm_get($data{realmname});
    return $self->raise(500 => "E1359: %s", $model->error) if $model->error;

    # Set or add realm data
    if ($data{id}) { # Update (Set)
        $model->realm_set(%data)
            or return $self->raise(500 => "E1366: %s", $model->error || 'Database request error (realm_set)');
    } else { # Insert (Add)
        return $self->raise(400 => "E1360: Realm already exists") if $old{id};
        $model->realm_add(%data)
            or return $self->raise(500 => "E1361: %s", $model->error || 'Database request error (realm_add)');
    }

    # Set routes
    my $routes = $data{routes} || [];
    $model->route_release( $data{realmname} )
        or return $self->raise(500 => "E1362: %s", $model->error || 'Database request error (route_release)');
    foreach my $routename (@$routes) {
        $model->route_assign(routename => $routename, realmname => $data{realmname})
            or return $self->raise(500 => "E1363: %s", $model->error || 'Database request error (route_assign)');
    }

    # Set requirements
    my $requirements = $data{requirements} || [];
    $model->realm_requirement_del( $data{realmname} )
        or return $self->raise(500 => "E1364: %s", $model->error || 'Database request error (realm_requirement_del)');
    foreach my $req (@$requirements) {
        next unless is_hash_ref($req);
        $model->realm_requirement_add(%$req, realmname => $data{realmname})
            or return $self->raise(500 => "E1365: %s", $model->error || 'Database request error (realm_requirement_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("realm.%s.updated", $data{realmname}), time);

    # Ok
    return 1;
}
sub realm_pset {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get current data from model
    my %cur = $model->realm_get($data{realmname});
    return $self->raise(500 => "E1359: %s", $model->error) if $model->error;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $model->realm_set(%data)
            or return $self->raise(500 => "E1366: %s", $model->error || 'Database request error (realm_set)');
    } else { # Insert (Add)
        $model->realm_add(%data)
            or return $self->raise(500 => "E1361: %s", $model->error || 'Database request error (realm_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("realm.%s.updated", $data{realmname}), time);

    # Ok
    return 1;
}
sub realm_get {
    my $self = shift;
    my $realmname = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get all realms
    unless (length($realmname)) {
        my @table = $model->realm_getall;
        $self->raise(500 => "E1367: %s", $model->error) if $model->error;
        return @table;
    }

    # Get realm data
    my %data = $model->realm_get($realmname);
    $self->raise(500 => "E1359: %s", $model->error) if $model->error;

    return %data;
}
sub realm_del {
    my $self = shift;
    my $realmname = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Delete realm
    $model->realm_del($realmname)
        or return $self->raise(500 => "E1368: %s", $model->error || 'Database request error (realm_del)');

    # Delete realm's requirements
    $model->realm_requirement_del($realmname)
        or return $self->raise(500 => "E1364: %s", $model->error || 'Database request error (realm_requirement_del)');

    # Release all related routes
    $model->route_release($realmname)
        or return $self->raise(500 => "E1362: %s", $model->error || 'Database request error (route_release)');

    # Sets up the updated tag
    #return $self->meta(sprintf("realm.%s.updated", $realmname), time);

    # Ok
    return 1;
}
sub realm_requirements {
    my $self = shift;
    my $realmname = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get realm requirements
    my @table = $model->realm_requirements($realmname);
    $self->raise(500 => "E1371: %s", $model->error) if $model->error;

    return @table;
}
sub realm_routes {
    my $self = shift;
    my $realmname = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get realm routes
    my @table = $model->realm_routes($realmname);
    $self->raise(500 => "E1372: %s", $model->error) if $model->error;

    return @table;
}

# Route CRUD
sub route_set {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get old data from model
    my %old = $model->route_get($data{routename});
    return $self->raise(500 => "E1373: %s", $model->error) if $model->error;

    # Set or add route data
    if ($data{id}) { # Update (Set)
        $model->route_set(%data)
            or return $self->raise(500 => "E1375: %s", $model->error || 'Database request error (route_set)');
    } else { # Insert (Add)
        return $self->raise(400 => "E1374: Route already exists") if $old{id};
        $model->route_add(%data)
            or return $self->raise(500 => "E1370: %s", $model->error || 'Database request error (route_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("routes.%s.updated", $data{base} // '__default'), time);

    # Ok
    return 1;
}
sub route_pset {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get current data from model
    my %cur = $model->route_get($data{routename});
    return $self->raise(500 => "E1373: %s", $model->error) if $model->error;

    # Set or add
    if ($cur{id}) { # Update (Set)
        $data{id} = $cur{id};
        $model->route_set(%data)
            or return $self->raise(500 => "E1375: %s", $model->error || 'Database request error (route_set)');
    } else { # Insert (Add)
        $model->route_add(%data)
            or return $self->raise(500 => "E1370: %s", $model->error || 'Database request error (route_add)');
    }

    # Sets up the updated tag
    #return $self->meta(sprintf("routes.%s.updated", $data{base} // '__default'), time);

    # Ok
    return 1;
}
sub route_get {
    my $self = shift;
    my $routename = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get all routes
    unless (length($routename)) {
        my @table = $model->route_getall();
        $self->raise(500 => "E1376: %s", $model->error) if $model->error;
        return @table;
    }

    # Get route data
    my %data = $model->route_get($routename);
    $self->raise(500 => "E1373: %s", $model->error) if $model->error;

    return %data;
}
sub route_del {
    my $self = shift;
    my $routename = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Delete route
    $model->route_del($routename)
        or return $self->raise(500 => "E1377: %s", $model->error || 'Database request error (route_del)');

    # Ok
    return 1;
}
sub route_search {
    my $self = shift;
    my $text = shift;
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get data from model
    my @table = $model->route_search($text);
    $self->raise(500 => "E1378: %s", $model->error) if $model->error;

    return @table;
}

# Token CRUD
sub token_set {
    my $self = shift;
    my %data = @_;
    $self->clean; # Flush error
    $data{type} //= 'session';

    # Get model
    my $model = $self->model;

    # Delete expired tokens
    $model->token_del
        or return $self->raise(500 => "E1379: %s", $model->error || 'Database request error (token_del)');

    # Get old data from model
    my %old;
    if ($data{id}) {
        %old = $model->token_get($data{id});
        return $self->raise(500 => "E1380: %s", $model->error) if $model->error;
    } elsif ($data{type} eq 'session') {
        %old = $model->token_get_cond('session', %data);
        return $self->raise(500 => "E1381: %s", $model->error) if $model->error;
    }

    # Set or add data
    if ($old{id}) { # Update (Set)
        $data{id} = $old{id};
        $model->token_set(%data)
            or return $self->raise(500 => "E1382: %s", $model->error || 'Database request error (token_set)');
    } else { # Insert (Add)
        $model->token_add(%data)
            or return $self->raise(500 => "E1369: %s", $model->error || 'Database request error (token_add)');
    }

    # Ok
    return 1;
}
sub token_get {
    my $self = shift;
    my ($id, $username, $jti);
    if (scalar(@_) == 1) { $id = shift }
    elsif (scalar(@_) == 2) {($username, $jti) = @_}
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get data from model
    my @data = ();
    if ($id) {
        @data = $model->token_get($id); # hash returs
        $self->raise(500 => "E1380: %s", $model->error) if $model->error;
    } elsif ($jti) {
        @data = $model->token_get_cond('api', username => $username, jti => $jti); # hash returs
        $self->raise(500 => "E1381: %s", $model->error) if $model->error;
    } else {
        @data = $model->token_getall(); # table returs
        $self->raise(500 => "E1383: %s", $model->error) if $model->error;
    }

    return @data;
}
sub token_del {
    my $self = shift;
    my $username = shift // '';
    my $jti = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get data from model
    my %data = $model->token_get_cond('api', username => $username, jti => $jti);
    return $self->raise(500 => "E1381: %s", $model->error) if $model->error;
    return 1 unless $data{id};

    # Delete token
    $model->token_del($data{id})
        or return $self->raise(500 => "E1379: %s", $model->error || 'Database request error (token_del)');

    # Ok
    return 1;
}
sub token_check {
    my $self = shift;
    my $username = shift // '';
    my $jti = shift // '';
    $self->clean; # Flush error

    # Get model
    my $model = $self->model;

    # Get data from model
    my %data = $model->token_get_cond('api', username => $username, jti => $jti);
    return $self->raise(500 => "E1381: %s", $model->error) // 0 if $model->error;

    # Check
    return 1 if $data{id};
    return 0;
}

# Working with dumps
sub import_data {
    my $self = shift;
    my $file = shift;
    $self->clean; # Flush error
    my $model = $self->model;
    my $now = time();

    # Get data struct from file
    if ($file) {
        $self->load($file);
        if ($self->error) {
            $self->code(500);
            return;
        }
    }
    my $data = $self->data; # Perl struct expected!

    # Get users
    my $users_array = $data->{"users"} // [];
       $users_array = [] unless is_array_ref($users_array);
    my %grpsusrs = ();
    foreach my $user (@$users_array) {
        next unless is_hash_ref($user);
        my $username = $user->{"username"} // '';
        next unless length($username);

        # Add user
        $self->user_pset(
            username    => $username,
            name        => $user->{"name"} // '',
            email       => $user->{"email"} // '',
            password    => $user->{"password"} // '',
            algorithm   => $user->{"algorithm"} // '',
            role        => $user->{"role"} // '',
            flags       => $user->{"flags"} || 0,
            created     => $now,
            not_before  => $now,
            not_after   => is_true_flag($user->{"disabled"}) ? $now : undef,
            public_key  => $user->{"public_key"} // '',
            private_key => $user->{"private_key"} // '',
            attributes  => $user->{"attributes"} // '',
            comment     => $user->{"comment"} // '',
        ) or return;

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

        # Add group
        $self->group_pset(
            groupname   => $groupname,
            description => $group->{"description"} // '',
        ) or return;

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
        $self->group_enroll(%$member) or return;
    }

    # Get realms
    my $realms_array = $data->{"realms"} // [];
       $realms_array = [] unless is_array_ref($realms_array);
    foreach my $realm (@$realms_array) {
        next unless is_hash_ref($realm);
        my $realmname = $realm->{"realmname"} // '';
        next unless length($realmname);

        # Add realm
        $self->realm_pset(
            realmname   => $realmname,
            realm       => $realm->{"realm"} // '',
            satisfy     => $realm->{"satisfy"} // '',
            description => $realm->{"description"} // '',
        ) or return;

        # Delete all current requirements from realm
        $model->realm_requirement_del($realmname)
            or return $self->raise(500 => "E1364: %s", $model->error || 'Database request error (realm_requirement_del)');

        # Set requirements
        my $requirements = $realm->{"requirements"} || [];
           $requirements = [] unless is_array_ref($requirements);
        foreach my $req (@$requirements) {
            next unless is_hash_ref($req);
            $model->realm_requirement_add(%$req, realmname => $realmname)
                or return $self->raise(500 => "E1365: %s", $model->error || 'Database request error (realm_requirement_add)');
        }

        # Release all routes for realm
        $model->route_release($realmname)
            or return $self->raise(500 => "E1362: %s", $model->error || 'Database request error (route_release)');
    }

    # Get routes
    my $routes_array = $data->{"routes"} // [];
       $routes_array = [] unless is_array_ref($routes_array);
    foreach my $route (@$routes_array) {
        next unless is_hash_ref($route);
        my $routename = $route->{"routename"} // '';
        next unless length($routename);

        # Add route
        $self->route_pset(
            routename   => $routename,
            realmname   => $route->{"realmname"} // '',
            method      => $route->{"method"} // '',
            url         => $route->{"url"} // '',
            base        => $route->{"base"} // '',
            path        => $route->{"path"} // '',
        ) or return;
    }

    # Get meta
    my $meta_hash = $data->{"meta"} // {};
       $meta_hash = {} unless is_hash_ref($meta_hash);
    while (my ($k, $v) = each %$meta_hash) {
        last unless (defined($k) && length($k));
        $self->meta($k, $v) or return;
        delete $meta_hash->{$k}; # This is safe
    }

    # Save status data to meta
    $self->meta("data.file" => $file || $self->sourcefile) or return;
    $self->meta("data.inited" => $now) or return;

    # Ok
    return 1;
}
sub export_data {
    my $self = shift;
    my $file = shift;
    $self->clean; # Flush error
    my $model = $self->model;
    my $now = time();

    # Get users
    my @users = $self->user_get();
    return if $self->error;
    foreach my $u (@users) {
        my $not_after = $u->{not_after} || 0;
        $u->{disabled} = ($not_after && $not_after < $now) ? 'yes' : 'no';
        delete($u->{$_}) for qw/created id not_before not_after/;
    }

    # Get groups
    my @groups = $self->group_get();
    return if $self->error;
    foreach my $g (@groups) {
        my $groupname = $g->{groupname} // '';
        next unless length $groupname;
        delete($g->{id});

        # Get members
        my @members = $self->group_members($groupname);
        return if $self->error;
        my @usr = ();
        foreach my $m (@members) {
            push @usr, $m->{username};
        }
        $g->{users} = [@usr];
    }

    # Get realms
    my @realms = $self->realm_get();
    return if $self->error;
    foreach my $r (@realms) {
        my $realmname = $r->{realmname} // '';
        next unless length $realmname;
        delete($r->{id});

        # Get requirements
        my @requirements = $self->realm_requirements($realmname);
        return if $self->error;
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
    return if $self->error;
    foreach my $r (@routes) {
        delete($r->{id});
    }

    # Get meta
    my @metas = $model->meta_get();
    return $self->raise(500 => "E1329: %s", $model->error) if $model->error;
    my %meta = ();
    foreach my $m (@metas) {
        $meta{$m->{key}} = $m->{value};
    }
    #print Mojo::Util::dumper(\%meta);

    # Store data
    $self->data({
        users   => \@users,
        groups  => \@groups,
        realms  => \@realms,
        routes  => \@routes,
        meta    => \%meta,
    });
    if ($file) {
        $self->save($file);
        if ($self->error) {
            $self->code(500);
            return;
        }
    }

    # Ok
    return 1;
}

# Deprecated methods
sub user_pure_set {
    deprecated 'The "WWW::Suffit::AuthDB::user_pure_set" is deprecated in favor of "user_pset"';
    goto &user_pset;
}
sub group_pure_set {
    deprecated 'The "WWW::Suffit::AuthDB::group_pure_set" is deprecated in favor of "group_pset"';
    goto &group_pset;
}
sub realm_pure_set {
    deprecated 'The "WWW::Suffit::AuthDB::realm_pure_set" is deprecated in favor of "realm_pset"';
    goto &realm_pset;
}
sub route_pure_set {
    deprecated 'The "WWW::Suffit::AuthDB::route_pure_set" is deprecated in favor of "route_pset"';
    goto &route_pset;
}

1;

__END__
