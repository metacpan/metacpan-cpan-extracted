package WWW::Webrobot::MyUserAgent;
use strict;
use warnings;
use base "LWP::UserAgent";

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class -> SUPER::new();
    $self->{_basic_realm} = {};
    $self->{obj_follow} = undef;
    bless ($self, $class);
    return $self;
}


sub client_302_bug {
    my $self = shift;
    return $self->{_client_302_bug} if !@_;
    die "Can only set client_302_bug, can't unset" if !$_[0];
    if (! $self->{_client_302_bug}) {
        $self->{_client_302_bug} = 1;
        push @{$self -> requests_redirectable}, 'POST';
    }
}

sub set_basic_realm {
    my ($self, $realm) = @_;
    $self -> {_basic_realm} = $realm || {};
}

sub get_basic_credentials { # INHERITED
    my ($self, $realm, $uri, $proxy) = @_;
    #print ">>REALM: $realm\nURI  : $uri\n>>PROXY: $proxy\n";
    my $ret = $self -> {_basic_realm} -> {$realm};
    return $ret ? @$ret : undef;
}

sub set_redirect_ok {
    my ($self, $recurse) = @_;
    return $self -> {obj_follow} = $recurse;
}

sub clear_redirect_fail {
    my ($self) = @_;
    $self -> {redirect_fail} = 0;
}

sub is_redirect_fail {
    my ($self) = @_;
    return $self -> {redirect_fail};
}

sub redirect_ok { # INHERITED
    my $self = shift;
    my ($r, $prev_response) = @_;
    # !!! Note that the interface of this function has changed in libwww-perl-5.76!
    # !!! Call SUPER in a generic way!

    # $r is of type HTTP::Request
    if ($self->client_302_bug &&
            $r->method eq 'POST' &&
            $r->content_type eq "application/x-www-form-urlencoded") {
        $r->method('GET');
        $r->content('');
        $r->remove_header('content-length');
        $r->remove_header('content-type');
    }
    return $self -> SUPER::redirect_ok(@_) if !defined $self -> {obj_follow};
    $self -> {redirect_fail} = 1 if ! $self -> {obj_follow} -> allowed($r->{_uri});
    return ! $self -> {redirect_fail};
}

sub enable_referrer {
    my ($self, $value) = @_;
    $self->{_enable_referrer} = $value if defined $value;
    $self->{_referrer} = undef if ! $self->{_enable_referrer};
    return $self->{_enable_referrer};
}

sub referrer {
    my ($self, $value) = @_;
    $self->{_referrer} = $value if $self->{_enable_referrer} && defined $value;
    return $self->{_referrer};
}

1;


=head1 NAME

WWW::Webrobot::MyUserAgent - specialized user agent

=head1 SYNOPSIS

 my $ua = WWW::Webrobot::MyUserAgent -> new


=head1 DESCRIPTION

This class inherits L<LWP::UserAgent>.
Additional features:

=over

=item basic authentification

=item aborting redirects

=back


=head1 METHODS

=over

=item my $agent = WWW::Webrobot::MyUserAgent -> new

Create user agent.

=item $agent -> set_basic_realm ($realm)

Set a realm for basic authentification

    $realm = {
        "realm1" => ["login1", "password1"],
        "realm2" => ["login2", "password2"],
    };


=item $ua -> get_basic_credentials

inherited from L<LWP::UserAgent>

=item $ua -> set_redirect_ok ($recurse)

Set an object that allows recursion over the resulting responses.
For C<$recurse> see L<WWW::Webrobot::pod::Recur>.
I<Affects> L<redirect_ok>.

=item $ua -> clear_redirect_fail

Clear the redirect_fail flag.
This flag may be set in L<redirect_ok>.

=item $ua -> is_redirect_fail

Get the value of the redirect_fail flag.
This flag indicates that a redirection was aborted.

=item $ua -> redirect_ok

inherited from L<LWP::UserAgent>

=item $ua -> client_302_bug

 $ua->client_302_bug(1)
     Behave like 302-buggy browser, no method to unset available.
 $ua->client_302_bug
     return whether value is set

Most popular browsers don't implemenent HTTP response 302 correctly,
see  [RFC 2616] http://www.ietf.org/rfc/rfc2616.txt
page 61, section 10.3.3, title "302 Found". In short:

        - bug 1: browser redirects POST without user interaction
        - bug 2: browser changes method from POST to GET

You should better correct your server instead of using this method:
return 303 instead of 302.

=item $ua -> enable_referrer($value)

Enable (1) or disable the HTTP referrer (which spells 'Referer')

=item $ua -> referrer($value)

Set/get the referrer value if referrers have been enabled by enable_referrer.

=back

=cut
