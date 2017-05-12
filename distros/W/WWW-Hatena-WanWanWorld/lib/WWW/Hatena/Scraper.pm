package WWW::Hatena::Scraper;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use LWP::UserAgent;
use HTTP::Cookies;
use Carp;
use vars qw($canssl);
BEGIN {
    eval {use Crypt::SSLeay;};
    $canssl = $@;
}

use constant LOGIN_URL             => 'http://www.hatena.ne.jp/login';
use constant LABO_LOGIN_URL        => 'http://www.hatelabo.jp/login';
use constant LOGOUT_URL            => 'http://www.hatena.ne.jp/logout';
use constant LABO_LOGOUT_URL       => 'http://www.hatelabo.jp/logout';
use constant USER_CHECK_URL        => 'http://hatena.ne.jp/';
use constant LABO_USER_CHECK_URL   => 'http://hatelabo.jp/';


sub new {
    my $self = shift;

    $self = bless {},$self unless (ref $self);

    my %opts = @_;
    $self->ua(delete $opts{ua});
    $self->user_check_code(delete $opts{user_check_code});
    $self->{'debug'} = delete $opts{debug};
    my $labo = delete $opts{labo};
    $self->user_check_url($opts{user_check_url} ? delete $opts{user_check_url} : $labo ? LABO_USER_CHECK_URL : USER_CHECK_URL);
    $self->logout_url($labo ? LABO_LOGOUT_URL : LOGOUT_URL);
    my $login = $labo ? LABO_LOGIN_URL : LOGIN_URL;
    $login =~ s/^http/https/ if ($canssl);
    $self->login_url($login);

    Carp::croak("Unknown options: " . join(", ", keys %opts)) if %opts;

    return $self;
}
sub rk { &_getset; }
sub user { &_getset; }
sub user_check_code { &_getset; }
sub user_check_url { &_getset; }
sub _ua { &_getset; }
sub login_url { &_getset; }
sub logout_url { &_getset; }
sub _getset {
    my $self = shift;
    my $param = (caller(1))[3];
    $param =~ s/.+:://;

    if (@_) {
        my $val = shift;
        Carp::croak("Too many parameters") if @_;
        $self->{$param} = $val;
    }
    return $self->{$param};
}
sub _fail {
    my $self = shift;
    my ($code, $text) = @_;

    $text ||= {
        'cannot_login' => "Cannot login by this ID/Password.",
        'rk_invalid' => "Cookie value is invalid or expired.",
        'no_url' => "Url is not given.",
        'no_url' => "No urls are given.",
        'no_rk' => "No cookies are given (Maybe not logined)",
    }->{$code};

    $self->{'last_errcode'} = $code;
    $self->{'last_errtext'} = $text;

    $self->_debug("fail($code) $text");
    wantarray ? () : undef;
}
sub _debug {
    my $self = shift;
    return unless $self->{debug};

    if (ref $self->{debug} eq "CODE") {
        $self->{'debug'}->($_[0]);
    } else {
        my $class = ref($self);
        print STDERR "[DEBUG $class] $_[0]\n";
    }
}
sub err {
    my $self = shift;
    $self->{'last_errcode'} . ": " . $self->{'last_errtext'};
}
sub errcode {
    my $self = shift;
    $self->{'last_errcode'};
}
sub errtext {
    my $self = shift;
    $self->{'last_errtext'};
}
sub ua {
    my $self = shift;
    my $ua = shift if @_;
    Carp::croak("Too many parameters") if @_;

    if (!$self->{'_ua'}) {
        $self->{'_ua'} = $ua || LWP::UserAgent->new();
    }
    $self->{'_ua'};
}
sub jar {
    my $self = shift;
    $self->{'_jar'} = HTTP::Cookies->new unless ($self->{_jar});
    $self->{'_jar'};
}

sub parse_rk {
    my $self = shift;
    my $res = shift;
    my $jar = $self->jar;
    $jar->extract_cookies($res);
    $jar->scan(sub{ $self->rk($_[2]) if ($_[1] eq 'rk') });
    $self->rk;
}

sub parse_user {
    my $self = shift;
    my $parser = $self->user_check_code || sub {
        my $self = shift;
        my $content = shift;
        my ($user) = $content =~ /<td\s[^\n]*class=\"username\">[^\n]+<a\shref=\"[^\"]+\">\s*<strong>([^<]+)<\/strong>\s*<\/a>[^\n]+<\/td>/m;
        $self->{'user'} = $user;
    };
    
    my $content = $self->get_content($self->user_check_url) or return;
    return $parser->($self,$content);
}

sub login {
    my $self = shift;
    if (@_ == 1) {
        $self->rk(shift);
    } elsif (@_ == 2) {
        my $id = shift;
        my $pw =shift;

        $self->get_content($self->login_url,"mode=enter&key=${id}&password=${pw}") or return;
        return $self->_fail('cannot_login') unless ($self->rk);
    } elsif (@_ > 2) {
        croak ("Too many parameters");
    }
    $self->parse_user or return $self->_fail('rk_invalid');
}

sub logout {
    my $self = shift;
    my $res = $self->get_content($self->logout_url);
    $self->{rk} = undef;
    $self->{user} = undef;
    return $res;
}

sub get_content {
    my $self = shift;
    my $url = shift;
    my $content = shift;
    croak ("Too many parameters") if (@_);
    return $self->_fail('no_url') unless ($url);
    return $self->_fail('no_rk') if (($url ne $self->login_url) && !($self->rk));

    my $h = HTTP::Headers->new(Cookie => $self->rk ? "rk=".$self->rk : '') ;
    $h->content_type('application/x-www-form-urlencoded') if (defined($content));
    my $r = defined($content) ? HTTP::Request->new("POST",$url,$h,$content) : HTTP::Request->new("GET",$url,$h);
    my $res = $self->ua->request($r);
    return $self->_fail('request_error',$res->message) if (!$res->is_success);

    $self->parse_rk($res);
    return $res->content;
}

1;
__END__
=head1 NAME

WWW::Hatena::Scraper - Base class to scraping Hatena/Hatelabo Web sites

=head1 SYNOPSIS

    use WWW::Hatena::Scraper;

    ## Simple use for.
    my $whs = WWW::Hatena::Scraper->new;
    my $username = $whs->login('username','password') or die "Login failed!";
    my $content = $whs->get_content("http://www.hatena.ne.jp/");

    ## You can get login cookie and re-login later.
    my $rk = $whs->rk;

    my $whs2 = WWW::Hatena::Scraper->new;
    my $username = $whs2->login($rk) or die "Cookie is invalid or expired!";

    ## If you want to access Hatelabo, do like this:
    my $labo = WWW::Hatena::Scraper->new(labo => 1);
    my $username = $labo->login('username','password') or die "Login failed!";
    my $content = $labo->get_content("http://www.hatelabo.jp/");

    ## Logout.
    $whs->logout;
    $whs2->logout;
    $labo->logout;

=head1 DESCRIPTION

I<WWW::Hatena::Scraper> is a client for fetching Hatena and Hatelabo's logined
pages.

=over 4

=item * https login support

If you have I<Crypt::SSLeay> installed, I<WWW::Hatena::Scraper> will 
automatically try to login https based login page.

=back

=head1 CONSTRUCTOR

=over 4

=item C<new>

my $whs = WWW::Hatena::Scraper->new([ %opts ]);

You can set the C<ua> and C<labo> option in constructor.

=over 8

=item ua

If you want to reuse I<LWP::UserAgent> object, set it to this option.

=item labo

If you set this option 1, login to not Hatena(hatena.ne.jp) but Hatelabo
(hatelabo.jp).

=back

=back

=head1 METHODS

=item $whs->B<login>($userid,$password)

=item $whs->B<login>($cookie)

Login to Hatena/Hatelabo web sites.
Return value is Hatena user id, and if undef returns, login failed.

=item $whs->B<get_content>($url,[ $content ])

Fetch $url's web content.
$url must be the page of Hatena/Hatelabo.
$content is optional, if given, use POST method, or use GET method.

=item $whs->B<logout>

Logout from Hatena/Hatelabo web sites.

=item $whs->B<user>

Returns user id if login successed.

=item $whs->B<rk>

Returns login cookie if login successed.
Give this value to login method later, you can relogin, unless it hasn't
expired.

=item $whs->B<err>

Returns the last error, in form "errcode: errtext"

=item $whs->B<errcode>

Returns the last error code.

=item $whs->B<errtext>

Returns the last error text.

=back

=head1 COPYRIGHT

This module is Copyright (c) 2006 OHTSUKA Ko-hei.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.
If you need more liberal licensing terms, please contact the
maintainer.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SEE ALSO

Hatena website:  L<http://hatena.ne.jp/>
Hatelabo website:  L<http://hatelabo.jp/>

L<WWW::Hatena::WanWanWorld> -- part of this module

=head1 AUTHORS

OHTSUKA Ko-hei <nene@kokogiko.net>

=cut
