package WebService::Windows::LiveID::Auth;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Carp::Clan qw(croak);
use CGI;
use Crypt::Rijndael;
use Digest::SHA ();
use MIME::Base64 ();
use URI;
use URI::QueryParam;
use URI::Escape ();

use WebService::Windows::LiveID::Auth::User;

__PACKAGE__->mk_accessors(qw/
  appid
  algorithm
  _secret_key
  _crypt_key
  _sign_key
/);

my $control_url = 'http://login.live.com/controls/WebAuth.htm';
my $sign_in_url = 'http://login.live.com/wlogin.srf';
my $sign_out_url = 'http://login.live.com/logout.srf';

=head1 NAME

WebService::Windows::LiveID::Auth - Perl implementation of Windows Live ID Web Authentication 1.0

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use WebService::Windows::LiveID::Auth;

  my $appid = '00163FFF80003203';
  my $secret_key = 'ApplicationKey123';
  my $appctx = 'zigorou';

  my $auth = WebService::Windows::LiveID::Auth->new({
    appid => $appid,
    secret_key => $secret_key
  });

  local $\ = "\n";

  print $auth->control_url; ### SignIn, SignOut links page by LiveID. Set this page url to iframe's src attribute.
  print $auth->sign_in_url; ### SignIn page
  print $auth->sign_out_url; ### SignOut page

In the request to "ReturnURL", 

  use CGI;
  use WebService::Windows::LiveID::Auth;

  my $q = CGI->new;

  my $appid = '00163FFF80003203';
  my $secret_key = 'ApplicationKey123';
  my $appctx = 'zigorou';

  my $auth = WebService::Windows::LiveID::Auth->new({
    appid => $appid,
    secret_key => $secret_key
  });

  my $user = eval { $auth->process_token($q->param("stoken"), $appctx); };
  print $q->header;

  unless ($@) {
    print "<p>Login sucsess.</p>\n";
    print "<p>uid: " . $user->uid . "</p>";
  }
  else {
    print "<p>Login failed.</p>";
  }

=head1 METHODS

=head2 new($arguments)

Constructor.
$arguments must be HASH reference.

  ## Constructor parameter sample.
  $arguments = {
    appid => '00163FFF80003203', ## required
    secret_key => 'ApplicationKey123', ## required
    algorithm => 'wsignin1.0' ## optional
  };

=cut

sub new {
    my ($class, $arguments) = @_;

    $arguments->{algorithm} ||= 'wsignin1.0';

    my $args = {};

    for my $prop (qw/appid secret_key algorithm/) {
        if (exists $arguments->{$prop} && $arguments->{$prop}) {
            $args->{$prop} = $arguments->{$prop};
        }
        else {
            croak(qq|$prop is required parameter|);
        }
    }

    my $self = $class->SUPER::new($args);
    $self->secret_key($args->{secret_key});

    return $self;
}

=head2 process_token($stoken, $appctx)

Process and validate stoken value.
If the authentication is sucsess, then this method will return L<WebService::Windows::LiveID::Auth::User> object.
On fail, return undef value.

=cut

sub process_token {
    my ($self, $stoken, $appctx) = @_;

    croak('stoken parameter is required') unless ($stoken);

    $stoken = $self->_uud64($stoken);

    croak('Invalid stoken value') if (!$stoken || (length $stoken) <= 16 || (length $stoken) % 16 != 0);

    my $iv = substr($stoken, 0, 16);
    my $crypted = substr($stoken, 16);

    croak('Invalid iv or crypted value') unless ($iv && $crypted);

    my $cipher = Crypt::Rijndael->new($self->_crypt_key, Crypt::Rijndael::MODE_CBC);
    $cipher->set_iv($iv);

    my $token = $cipher->decrypt($crypted);
    my ($body, $sig) = split(/&sig=/, $token);

    croak('Failed to decrypt token') unless ($body && $sig);
    croak('Invalid signature') if (Digest::SHA::hmac_sha256($body, $self->_sign_key) ne $self->_uud64($sig));

    my $query = CGI->new($token);

    return WebService::Windows::LiveID::Auth::User->new({$query->Vars});
}

=head2 control_url([$query])

Return control url as L<URI::http> object.
$query parameter is optional, It must be HASH reference.

  ## query parameter sample
  $query = {
    appctx => "zigorou",
    style => "font-family: Times Roman;"
  };

Or

  $query = {
    appctx => "zigorou",
    style => {
      "font-family" => "Verdana",
      "color" => "Grey"
    }
  }

The "style" property allows SCALAR and HASH reference.

=cut

sub control_url {
    my ($self, $query) = @_;
    my $control_url = URI->new($control_url);

    $control_url->query_param('appid', $self->appid);
    $control_url->query_param('alg', $self->algorithm);

    if ($query && ref $query eq 'HASH') {
        $control_url->query_param('appctx', $query->{appctx}) if ($query->{appctx});
        if ($query->{style}) {
            $query->{style} = $self->_style_to_string($query->{style}) if (ref $query->{style} eq "HASH");
            $control_url->query_param('style', $query->{style});
        }
    }

    return $control_url;
}

=head2 sign_in_url([$query])

Return sign-in url as L<URI::http> object.
$query parameter is optional, It must be HASH reference.

  ## query parameter sample
  $query = {
    appctx => "zigorou"
  };

=cut

sub sign_in_url {
    my ($self, $query) = @_;
    my $sign_in_url = URI->new($sign_in_url);

    $sign_in_url->query_param('appid', $self->appid);
    $sign_in_url->query_param('alg', $self->algorithm);
    $sign_in_url->query_param('appctx', $query->{appctx}) if ($query && ref $query eq 'HASH' && $query->{appctx});

    return $sign_in_url;
}

=head2 sign_out_url()

Return sign-out url as L<URI::http> object.

=cut

sub sign_out_url {
    my $self = shift;

    my $sign_out_url = URI->new($sign_out_url);
    $sign_out_url->query_param('appid', $self->appid);

    return $sign_out_url;
}

=head2 appid([$appid])

Application ID

=head2 algorithm([$algorithm])

Algorithm name

=head2 secret_key([$secret_key])

Secret key

=cut

sub secret_key {
    my ($self, $secret_key) = @_;

    if ($secret_key) {
        $self->_secret_key($secret_key);
        $self->_sign_key($self->_derive_key("SIGNATURE"));
        $self->_crypt_key($self->_derive_key("ENCRYPTION"));
    }
    else {
        return $self->_secret_key;
    }
}

=head2 sign_key()

Signature key.

=cut

sub sign_key { shift->_sign_key; }

=head2 crypt_key()

Encryption key

=cut

sub crypt_key { shift->_crypt_key; }

###
### private methods
###

sub _derive_key {
    my ($self, $prefix) = @_;
    return substr(Digest::SHA::sha256($prefix . $self->_secret_key), 0, 16);
}

sub _style_to_string {
    my ($self, $props) = @_;
    my @allow_props = qw(font-family font-weight font-style font-size color background);

    return join(" ", 
         map { join(": ", $_, $props->{$_}) . ";" }
         grep { exists $props->{$_} && $props->{$_} }
         @allow_props
    );
}

sub _uud64 {
    my ($self, $strings) = @_;
    return MIME::Base64::decode_base64(URI::Escape::uri_unescape($strings));
}

=head1 SEE ALSO

=over 4

=item http://go.microsoft.com/fwlink/?linkid=92886

=item http://msdn2.microsoft.com/en-us/library/bb676626.aspx

=item http://dev.live.com/blogs/liveid/archive/2006/05/18/8.aspx

=item http://forums.microsoft.com/MSDN/ShowForum.aspx?ForumID=646&SiteID=1

=item http://www.microsoft.com/downloads/details.aspx?FamilyId=8BA187E5-3630-437D-AFDF-59AB699A483D&displaylang=en

=item http://msdn2.microsoft.com/en-us/library/bb288408.aspx

=item L<Crypt::Rijndael>

=item L<Digest::SHA>

=item L<MIME::Base64>

=item L<URI::Escape>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-windows-liveid-auth@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Windows::LiveID::Auth
