package WebService::Livedoor::Auth;

use warnings;
use strict;
use Carp;
use URI;
use Digest::HMAC_SHA1;
use Scalar::Util qw(blessed);
use Params::Validate qw(:all);
use LWP::UserAgent;
use base qw(Class::Accessor::Fast Class::ErrorHandler);

our $VERSION = '0.01';
our $BASE_URL = 'http://auth.livedoor.com/';
our $DEFAULT_TIMEOUT = 60 * 5;

__PACKAGE__->mk_accessors(qw(app_key secret ver timeout));

# copy from Hatena::API::Auth.
BEGIN {
    use Carp;
    our $HAVE_JSON_SYCK;
    eval { require JSON::Syck; $HAVE_JSON_SYCK = 1 };
    eval { require JSON } unless $HAVE_JSON_SYCK;
    Carp::croak("JSON::Syck or JSON required to use " . __PACKAGE__) if $@;
    *_parse_json =
        $HAVE_JSON_SYCK  ? sub { JSON::Syck::Load($_[1]) }
                         : sub { JSON::jsonToObj($_[1])  };
}

sub new {
    my $class = shift;
    my %p = validate(@_, {
        app_key => { type => SCALAR },
        secret => { type => SCALAR },
        ver => { type => SCALAR, optional => 1, default => '1.0' },
        timeout => { type => SCALAR, optional => 1, 
                     default => 60 * 10, regex => qr/^\d+$/, }
    });
    my $self = bless \%p, $class;
    $self;
}

sub uri_to_login {
    my $self = shift;
    my %p = validate(@_, {
        perms => { optional => 1, type => SCALAR, 
                   regex => qr/^(userhash|id)$/, default => 'userhash', },
        userdata => { optional => 1, type => SCALAR },
        t => { optional => 1, type => SCALAR, regex => qr/^\d+$/ },
    });
    my %query = (
        v => $self->ver,
        app_key => $self->app_key,
        perms => $p{perms},
    );
    $query{t} = $p{t} || time;
    $query{userdata} = $p{userdata} if exists $p{userdata};
    $query{sig} = $self->calc_sig(\%query);
    my $uri = URI->new_abs('/login/', $BASE_URL);
    $uri->query_form(%query);
    $uri;
}

sub validate_response {
    my($self, $q) = @_;
    $q = _normalize_query($q);
    if ($q->{sig} eq $self->calc_sig($q)) {
        if (abs(time - $q->{t}) > $self->timeout) {
            return $self->error('LOCAL TIMEOUT');
        }
        my $user = WebService::Livedoor::Auth::User->new;
        $user->userdata($q->{userdata});
        $user->userhash($q->{userhash});
        $user->token($q->{token});
        return $user;
    }
    else {
        return $self->error('INVALID SIG');
    }
}

sub get_livedoor_id {
    my($self, $user) = @_;
    $self->call_auth_rpc($user) or return $self->error($self->errstr);
    $user->livedoor_id;
}

sub call_auth_rpc {
    my($self, $user) = @_;
    my %query = (
        app_key => $self->app_key,
        v => $self->ver,
        format => 'json',
        token => $user->token,
        t => time,
    );
    $query{sig} = $self->calc_sig(\%query);
    my $uri = URI->new_abs('/rpc/auth', $BASE_URL);
    my $res = $self->ua->post($uri->as_string, \%query);
    return $self->error($res->status_line) unless $res->is_success;
    my $json = $self->_parse_json($res->content);
    if ($json->{error}) {
        return $self->error($json->{message});
    }
    $user->livedoor_id($json->{user}->{livedoor_id});
    return $user;
}


sub calc_sig {
    my($self, $q) = @_;
    my $context = Digest::HMAC_SHA1->new($self->secret);
    $q = _normalize_query($q);
    for my $key(sort { $a cmp $b} keys %{$q}) {
        next if $key eq 'sig';
        $context->add($key);
        $context->add($q->{$key});
    }
    return $context->hexdigest;
}

sub ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->parse_head(0);
    $ua->env_proxy;
    $ua->agent(join '/', ref $self, $VERSION);
    $ua;
}

sub _normalize_query {
    my $q = shift;
    if (blessed $q && $q->can('param')) {
        my %q = map {
            $_ => scalar $q->param($_),
        } $q->param;
        return \%q;
    }
    $q;
}

package WebService::Livedoor::Auth::User;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(token userhash userdata livedoor_id));

1;

__END__

=head1 NAME

WebService::Livedoor::Auth - [One line description of module's purpose here]


=head1 SYNOPSIS

    use WebService::Livedoor::Auth;
    
    my $auth = WebService::Livedoor::Auth->new({
        app_key => '...',
        secret => '...',
    });
    my $uri = $auth->uri_to_login({userdata => '...'});


    use CGI;
    use WebService::Livedoor::Auth;
    
    my $q = CGI->new;
    my $auth = WebService::Livedoor::Auth->new({
        app_key => '...',
        secret => '...',
    });
    my $user = $auth->validate_response($q);
    if($user) {
        my $livedoor_id = $auth->get_livedoor_id($user);
    }
    


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 AUTHOR

Tomohiro IKEBE  C<< <ikebe@shebang.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Tomohiro IKEBE C<< <ikebe@shebang.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


