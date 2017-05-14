package WWW::Xunlei;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use JSON;

use File::Basename;
use Term::ANSIColor qw/:constants/;
use Data::Dumper;

use WWW::Xunlei::Downloader;
use WWW::Xunlei::Utils;

our $DEBUG;

use constant URL_LOGIN  => 'http://login.xunlei.com/';
use constant URL_REMOTE => 'http://homecloud.yuancheng.xunlei.com/';
use constant DEFAULT_USER_AGENT =>
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:41.0) "
    . "Gecko/20100101 Firefox/41.0";
use constant URL_LOGIN_REFER => 'http://i.xunlei.com/login/2.5/?r_d=1';
use constant BUSINESS_TYPE   => '113';
use constant V               => '2';
use constant CT              => '0';

sub new {
    my $class = shift;
    my ( $user, $pass, %options ) = @_;
    my $self = {
        'ua'   => undef,
        'json' => undef,
        'user' => $user,
        'pass' => md5pass($pass),
    };

    $self->{'ua'} = LWP::UserAgent->new;
    $self->{'ua'}->cookie_jar( { ignore_discard => 0 } );
    $self->{'ua'}->agent(DEFAULT_USER_AGENT);

    $self->{'json'} = JSON->new->allow_nonref;

    bless $self, $class;
    return $self;
}

sub list_downloaders {
    my $self = shift;

    my $parameters = { 'type' => 0, };

    my $res = $self->_yc_request( 'listPeer', $parameters );

    if ( $res->{'rtn'} != 0 ) {
        die "Unable to get the Downloader List: $@";
    }

    my @downloaders;
    for my $p ( @{ $res->{'peerList'} } ) {
        push @downloaders, WWW::Xunlei::Downloader->new( $self, $p );
    }

    return wantarray ? @downloaders : \@downloaders;
}

sub bind {
    my $self = shift;

    my ( $key, $name ) = @_;

    my $parameters = {
        'boxname' => $name,
        'key'     => $key,
    };

    my $res = $self->_yc_request( 'bind', $parameters );
}

sub unbind {
    my $self = shift;
    my $pid  = shift;

    my $res = $self->_yc_request( 'unbind', { 'pid' => $pid } );
}

sub login {
    my $self        = shift;
    my $verify_code = uc $self->_get_verify_code();
    $self->_debug( "Verify Code: " . $verify_code );
    my $password   = md5_hex( $self->{'pass'} . $verify_code );
    my $parameters = {
        'u'          => $self->{'user'},
        'p'          => $password,
        'verifycode' => $verify_code,
    };

    # $self->{'ua'}->post(join( '/', URL_LOGIN, 'sec2login/'), $parameters);
    $self->_request( 'POST', URL_LOGIN . 'sec2login/', $parameters );

    my $code = $self->_get_cookie('blogresult');
    # Todo: Retry if sever problem.
    die "Login Error: $code" if ( $code != 0 );
    $self->_set_auto_login();
    $self->_delete_temp_cookie();
}

sub _is_login {
    my $self = shift;
    return ($self->_get_cookie('sessionid') && $self->_get_cookie('userid'))
}

sub _get_verify_code {
    my $self       = shift;
    my $parameters = {
        'u'             => $self->{'user'},
        'business_type' => BUSINESS_TYPE,
        'cachetime'     => timestamp(),
    };
    $self->_request( 'GET', URL_LOGIN . 'check/', $parameters );
    my $check_result = $self->_get_cookie('check_result');
    my $verify_code = ( split( ':', $check_result ) )[1];
    return $verify_code;
}

sub _set_auto_login {
    my $self      = shift;
    my $sessionid = $self->_get_cookie('sessionid');
    $self->_set_cookie( '_x_a_', $sessionid, 604800 );
}

sub _delete_temp_cookie {
    my $self = shift;
    my @login_cookie
        = qw/VERIFY_KEY verify_type check_n check_e logindetail result/;
    for my $c (@login_cookie) {
        $self->_delete_cookie($c);
    }
}

sub _get_cookie {
    my $self = shift;
    my ( $key, $domain, $path ) = @_;
    $domain ||= ".xunlei.com";
    $path ||= "/";
    my $cookie_jar = $self->{'ua'}->{'cookie_jar'};
    return $cookie_jar->{'COOKIES'}{$domain}{'/'}{$key}[1];
}

sub _set_cookie {
    my $self = shift;
    my ( $key, $value, $expire, $domain, $path ) = @_;
    $domain ||= ".xunlei.com";
    $path ||= "/";
    $self->{'cookie_jar'}
        ->set_cookie( undef, $key, $value, $path, $domain, undef,
        undef, undef, $expire );
}

sub _delete_cookie {
    my $self = shift;
    my ( $key, $domain, $path ) = @_;
    $domain ||= ".xunlei.com";
    $path   ||= "/";
    my $cookie_jar = $self->{'ua'}->{'cookie_jar'};
    delete $cookie_jar->{'COOKIES'}{$domain}{'/'}{$key};
}

sub _yc_request {
    my $self = shift;
    my ( $action, $parameters, $data ) = @_;

    my $method = $data ? 'POST' : 'GET';
    my $uri = URL_REMOTE . $action;
    $parameters->{'v'}  = V;
    $parameters->{'ct'} = CT;

    return $self->_request( $method, $uri, $parameters, $data );
}

sub _request {
    my $self = shift;
    my ( $method, $uri, $parameters, $postdata ) = @_;
    my ( $form_string, $payload );
    if ($parameters) {
        $form_string = urlencode($parameters);
    }

    if ( $method ne 'GET' && !$postdata ) {

        # use urlencode parameters as post data when posting login form.
        $payload = $form_string;
    }
    else {
        $uri .= '?' . $form_string;
        if ( ref $postdata ) {
            $payload = $self->{'json'}->encode($postdata);
            $payload = urlencode( { 'json' => $payload } );
        }
    }

    my $request = HTTP::Request->new( $method => $uri, undef, $payload );
    $request->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
    $self->_debug($request);
    my $response = $self->{'ua'}->request($request);
    die $response->code . ":" . $response->message
        unless $response->is_success;
    my $content = $response->content;

    $self->_debug($content);

    $content =~ s/\s$//g;
    return "" unless ( length($content) );

    return $self->{'json'}->decode($content) if ( $content =~ /\s*[\[\{\"]/ );
}

sub _debug {
    my $self    = shift;
    my $message = shift;
    if ($DEBUG) {
        if ( ref $message ) { $message = Dumper($message); }
        my $date = strftime( "%Y-%m-%d %H:%M:%S", localtime );

        #$date .= sprintf(".%03f", current_timestamp());
        print BLUE "[ $date ] ", GREEN $message, RESET "\n";
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

WWW::Xunlei - Perl API For Official Xunlei Remote API.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use WWW::Xunlei;
    my $client = WWW::Xunlei->new("username", "password");
    $client->login;
    # use the first downloader;
    my $downloader = $client->list_downloaders()->[0];
    # create a remote task;
    $downloader->create_task("http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz");

=head1 DESCRIPTION

C<WWW::Xunlei> is a Perl Wrapper of Xunlei Remote Downloader API.
L<Official Site of Xunlei Remote|http://yuancheng.xunlei.com>

B<This module is now under deveopment. It's not stable.>

=head1 METHODS

=head2 new( "username", "password")

=head2 login()

=head2 list_downloaders()

=head1 AUTHOR

Zhu Sheng Li <zshengli@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Zhu Sheng Li.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__

# ABSTRACT: Perl API For Official Xunlei Remote API.

