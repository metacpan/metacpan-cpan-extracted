package WWW::Suffit::AuthDB::Role::AAA;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Role::AAA - Suffit AuthDB methods for AAA

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB;

    my $authdb = WWW::Suffit::AuthDB->with_roles('+AAA')->new( ... );

=head1 DESCRIPTION

The API provided by this module deals with access, authentication and authorization phases

=head1 METHODS

This class extends L<WWW::Suffit::AuthDB> and implements the following new ones methods

=head2 access

    $authdb->access(
        controller  => $self, # The Mojo controller object
        username    => "Bob",
        cachekey    => "d1b919c1",
        base        => "https://www.example.com",
        method      => "GET",
        url         => "https://www.example.com/foo/bar",
        path        => "/foo/bar",
        remote_ip   => "127.0.0.1",
        routename   => "root",
        headers     => {
            Accept      => "text/html,text/plain",
            Connection  => "keep-alive",
            Host        => "localhost:8695",
        },
    ) or die $authdb->error;

...or short syntax:

    $authdb->access(
        c   => $self, # The Mojo controller object
        u   => "Bob",
        k   => "d1b919c1",
        b   => "https://www.example.com",
        m   => "GET",
        url => "https://www.example.com/foo/bar",
        p   => "/foo/bar",
        i   => "127.0.0.1",
        r   => "root",
        h   => {
            Accept      => "text/html,text/plain",
            Connection  => "keep-alive",
            Host        => "localhost:8695",
        },
    ) or die $authdb->error;

This method performs access control

Check by routename:

    <% if (has_access(path => url_for('settings')->to_string)) { %> ... <% } %>
    <% if (has_access(route => 'settings') { %> ... <% } %>

=head2 authen

This method is deprecated! See L</authn>

=head2 authn

    $authdb->authn(
        username => "username",
        password => "password",
        address => "127.0.0.1",
        cachekey => "d1b919c1",
    ) or die $authdb->error;

...or short syntax:

    $authdb->authn(
        u => "username",
        p => "password",
        a => "127.0.0.1",
        k => "d1b919c1",
    ) or die $authdb->error;

This method checks password by specified credential pair (username and password) and remote client IP address.

The method returns the User object or undef if errors occurred

=head2 authz

    $authdb->authz(
        username => "username",
        scope => 0, # 0 - internal; 1 - external
        cachekey => "d1b919c1",
    ) or die $authdb->error;

...or short syntax:

    $authdb->authz(
        u => "username",
        s => 0, # 0 - internal; 1 - external
        k => "d1b919c1",
    ) or die $authdb->error;

This method checks authorization status by specified username.

The scope argument can be false or true.
false - determines the fact that internal authorization is being performed
(on Suffit system); true - determines the fact that external
authorization is being performed (on another sites)

The method returns the User object or undef if errors occurred

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

use Carp;

use Mojolicious::Routes::Pattern;

use Mojo::URL;
use Mojo::Util qw/secure_compare deprecated/;

use Acrux::RefUtil qw/isnt_void is_integer is_array_ref is_hash_ref is_true_flag/;

use constant {
    MAX_DISMISS     => 5,
    AUTH_HOLD_TIME  => 60*5, # 5min
};

# Interface methods
sub authn {
    my $self = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $username = $args->{username} // $args->{u} // ''; # Username
    my $password = $args->{password} // $args->{p} // ''; # Password
    my $address = $args->{address} // $args->{a} // ''; # IP address
    my $cachekey = $args->{cachekey} // $args->{k} // ''; # Cachekey
    $self->clean; # Flush session vars
    my $model = $self->model;

    # Validation username
    return $self->raise(400 => "E1320: No username specified") unless length($username); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1321: The username is too long (1-256 chars required)")
        unless length($username) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Validation password
    return $self->raise(400 => "E1322: No password specified") unless length($password); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1323: The password is too long (1-256 chars required)")
        unless length($password) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Get user data from AuthDB
    my $user = $self->user($username, $cachekey);
    return if $self->error;

    # Check consistency
    return $self->raise(401 => $user->error) unless $user->is_valid; # HTTP_UNAUTHORIZED

    # Get dismiss and updated by address and username
    my %st = $model->stat_get($address, $username);
    return $self->raise(500 => "E1384: %s", $model->error) if $model->error; # HTTP_INTERNAL_SERVER_ERROR
    my $dismiss = $st{dismiss} || 0;
    my $updated = $st{updated} || 0;
    if (($dismiss >= MAX_DISMISS) && (($updated + AUTH_HOLD_TIME) >= time)) {
        return $self->raise(403 => "E1324: Account frozen for 5 min"); # HTTP_FORBIDDEN
    }

    # Check password checksum
    my $digest = $self->checksum($password, $user->algorithm);
    return $self->raise(501 => "E1325: Incorrect digest algorithm") unless $digest; # HTTP_NOT_IMPLEMENTED

    # Compare password
    if (secure_compare($user->password, $digest)) { # Ok
        unless ($model->stat_set(address => $address, username => $username)) {
            return $self->raise(500 => "E1385: %s", $model->error || 'Database request error (stat_set)'); # HTTP_INTERNAL_SERVER_ERROR
        }
        return $user;
    }

    # Oops!
    unless ($model->stat_set(address => $address, username => $username, dismiss => ($dismiss + 1))) {
        return $self->raise(500 => "E1385: %s", $model->error || 'Database request error (stat_set)'); # HTTP_INTERNAL_SERVER_ERROR
    }

    # Fail
    return $self->raise(401 => "E1326: Incorrect username or password"); # HTTP_UNAUTHORIZED
}
sub authz {
    my $self = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    my $username = $args->{username} // $args->{u} // ''; # Username
    my $cachekey = $args->{cachekey} // $args->{k} // ''; # Cachekey
    my $scope = $args->{scope} || $args->{s} || 0; # Scope
    $self->clean; # Flush session vars

    # Validation username
    return $self->raise(400 => "E1320: No username specified") unless length($username); # HTTP_BAD_REQUEST
    return $self->raise(413 => "E1321: The username is too long (1-256 chars required)")
        unless length($username) <= 256; # HTTP_REQUEST_ENTITY_TOO_LARGE

    # Get user data from AuthDB
    my $user = $self->user($username, $cachekey);
    return if $self->error;

    # Check consistency
    return $self->raise(401 => $user->error) unless $user->is_valid; # HTTP_UNAUTHORIZED

    # Disabled/Banned
    return $self->raise(403 => "E1327: User is disabled") unless $user->is_enabled; # HTTP_FORBIDDEN

    # Internal or External
    if ($scope) { # External
        return $self->raise(403 => "E1317: External requests is blocked") unless $user->allow_ext; # HTTP_FORBIDDEN
    } else { # Internal (default)
        return $self->raise(403 => "E1318: Internal requests is blocked") unless $user->allow_int; # HTTP_FORBIDDEN
    }

    # Ok
    $user->is_authorized(1); # Set flag 'authorized'
    return $user;
}
sub access {
    my $self = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $self->clean; # Flush session vars

    # Parse arguments
    my $cachekey = $args->{cachekey} // $args->{k} // ''; # Cachekey
    my $controller = $args->{controller} // $args->{c}; # Controller
       croak "No controller specified" unless ref($controller);
    my $url = $args->{url} ? Mojo::URL->new($args->{url}) : $controller->req->url; # URL
    my $username = $args->{username} // $args->{u} // $url->to_abs->username // ''; # Username
    my $routename = $args->{routename} // $args->{r} // $controller->current_route // ''; # Route
    my $method = $args->{method} // $args->{m} // $controller->req->method // '';
    my $url_path = $args->{path} // $args->{p} // $url->path->to_string;
    my $url_base = $args->{base} // $args->{b} // $url->base->path_query('/')->to_string // '';
       $url_base =~ s/\/+$//;
    my $remote_ip = $args->{remote_ip} // $args->{client_ip} // $args->{i} // $controller->remote_ip;
    my $headers = $args->{headers} // $args->{h};
    #$controller->log->warn($url_base);

    # Get routes list for $url_base
    my $routes = $self->routes($url_base, $cachekey);
    return if $self->error;

    # Route based checks
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
    $controller->log->debug(sprintf("[access] The route \"%s\" was detected %s", $route{routename} // '', $route{rule}));

    # Get realm instance
    my $realm = $self->realm($route{realmname}, $cachekey);
    return if $self->error;
    return 1 unless $realm->id; # No realm - no authorization :-)
    $controller->log->debug(sprintf("[access] Use realm \"%s\"", $route{realmname}));

    # Get user data
    my $user = $self->user($username, $cachekey);
    return if $self->error;
    #$controller->log->debug($controller->dumper($user));

    # Result of checks
    my @checks = ();

    # Check by user or group
    my @grants = ();
    #$controller->log->debug(">>>> Username = $username");
    #$controller->log->debug(sprintf(">>>> cachekey=$cachekey; Groups=%s", $controller->dumper($user->groups)));
    #$controller->log->debug($controller->dumper($realm->requirements->{'User/Group'}));
    #$self->requirements->{'User/Group'}
    if (my $s = $realm->_check_by_usergroup($username, $user->groups)) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, sprintf("User/Group (username=%s)", $username);
        }
    } else {
        push @checks, 0;
    }

    # Check by ip or host
    if (my $s = $realm->_check_by_host($remote_ip)) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, sprintf("Host (ip=%s)", $remote_ip);
        }
    } else {
        push @checks, 0;
    }

    # Check by ENV
    if (my $s = $realm->_check_by_env()) {
        if ($s == 1) {
            push @checks, 1;
            push @grants, "Env";
        }
    } else {
        push @checks, 0;
    }

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
    } else {
        push @checks, 0;
    }

    # Check default
    my $default = $realm->_check_by_default();

    # Calc check result by satisfy politic
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
        $controller->log->debug(sprintf('[access] Access allowed by %s rule(s). Satisfy=%s',
            join(", ", @grants), $satisfy_all ? 'All' : 'Any'));
    } else {
        $controller->log->debug(sprintf('[access] Access %s by default. Satisfy=%s',
            $default ? 'allowed' : 'denied', $satisfy_all ? 'All' : 'Any'));
    }

    # Summary
    my $summary = $status ? 1 : $default; # True - allowed; False - denied

    # Access denied
    return $self->raise(403 => "E1319: Access denied") unless $summary; # HTTP_FORBIDDEN

    # Ok
    return 1;
}

# Deprecated methods
sub authen {
    deprecated 'The "WWW::Suffit::AuthDB::authen" is deprecated in favor of "authn"';
    goto &authn;
}

1;

__END__
