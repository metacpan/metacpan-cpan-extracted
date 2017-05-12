package WWW::HatenaLogin;

use strict;
use warnings;

use Carp;
use URI;
use WWW::Mechanize;

our $VERSION = '0.03';

my $login_uri  = 'https://www.hatena.ne.jp/login';
my $logout_uri = 'https://www.hatena.ne.jp/logout';

sub new {
    my($class, $args) = @_;
    croak sprintf 'usage: %s->new(hash ref)', __PACKAGE__ unless $args && ref($args) eq 'HASH';

    my $self = bless {
        cookie_domain => '.hatena.ne.jp',
        session_key   => 'rk',
        uri           => {
            login  => URI->new($login_uri),
            logout => URI->new($logout_uri),
        },
        login_form    => {
            username => 'name',
            password => 'password',
        },
    }, $class;
    $self->{$_} = delete $args->{$_} || '' for qw( username password mech );

    my $opt = delete $args->{mech_opt};
    $self->{mech} ||= WWW::Mechanize->new(
        $opt && ref $opt ? %{ $opt } : ()
    );

    if (delete $args->{labo}) {
        $self->{uri}->{login}->host('www.hatelabo.jp');
        $self->{uri}->{logout}->host('www.hatelabo.jp');
        $self->{login_form}->{username} = 'key';
        $self->{cookie_domain}          = '.hatelabo.jp';
        $self->{logout_check}  = sub { shift->{mech}->content !~ m!https://www.hatelabo.jp/login! };
    }
    if (delete $args->{com}) {
        $self->{uri}->{login}->host('www.hatena.com');
        $self->{uri}->{logout}->host('www.hatena.com');
        $self->{cookie_domain} = '.hatena.com';
    }

    my $nologin = delete $args->{nologin};

    $self->login unless $nologin || $self->is_loggedin;
    $self;
}

sub has_metalink {
    my $self = shift;
    my $link;
    ($link) = map { $_->url } $self->{mech}->find_link(tag => 'meta');
    !!$link;
}

sub is_loggedin {
    my $self = shift;
    $self->{mech}->get($self->login_uri);
    $self->has_metalink;
}

sub login_uri { shift->{uri}->{login} }

sub logout_uri { shift->{uri}->{logout} }

sub username {
    my $self = shift;
    $self->{username} = defined $_[0] ? $_[0] : $self->{username};
}

sub login {
    my($self, $args) = @_;

    if ($args) {
        if ($args->{username}) {
            $self->{username} = $args->{username};
        }
        if ($args->{password}) {
            $self->{password} = $args->{password};
        }
    }

    $self->{mech}->get($self->login_uri);
    $self->{mech}->submit_form(
        fields => {
            $self->{login_form}->{username} => $self->{username},
            $self->{login_form}->{password} => $self->{password},
        }
    );

    !!($self->session_id) ||
        croak 'Login failed. Please confirm your username/password';
}

sub logout {
    my $self = shift;
    $self->{mech}->get($self->logout_uri);
    $self->{logout_check} ? $self->{logout_check}->($self) : $self->has_metalink;
}

sub mech { shift->{mech} }

sub cookie_jar { shift->{mech}->cookie_jar }

sub session_id {
    my $self = shift;
    my $rk;

    $self->cookie_jar->scan(sub {
        my($version, $key, $val, $path, $domain, $port,
            $path_spec, $secure, $expires, $discard, $hash) = @_;
        return unless $key eq $self->{session_key} && $domain eq $self->{cookie_domain};
        return if $expires && $expires < time;
        $rk = $val;
    });
    $rk;
}

1;
__END__

=head1 NAME

WWW::HatenaLogin - login/logout interface to Hatena

=head1 SYNOPSIS

  use WWW::HatenaLogin;

  # new login
  my $session = WWW::HatenaLogin->new({
      username => 'username',
      password => 'password',
  });

  # login to hatena.com  (optional)
  my $session = WWW::HatenaLogin->new({
      username => 'username',
      password => 'password',
      com      => 1,
  });

  # login to hatelabo.jp  (optional)
  my $session = WWW::HatenaLogin->new({
      username => 'username',
      password => 'password',
      labo     => 1,
  });

  # do not login with new method
  my $session = WWW::HatenaLogin->new({
      username => 'username',
      password => 'password',
      nologin  => 1,
  });

  # WWW::Mechanize option (optional)
  my $session = WWW::HatenaLogin->new({
      username => 'username',
      password => 'password',
      mech_opt => {
          timeout    => $timeout,
          cookie_jar => HTTP::Cookies->new(...),
      },
  });

  # logout
  $session->logout;

  # login
  $session->login;

  # Check if already logged in to Hatena
  # If you have a valid cookie, you can omit this process
  unless ($session->is_loggedin) {
      $session->login;
  }

  # get session id
  $session->session_id;

  # get cookie_jar
  $session->cookie_jar;

  # get WWW::Mechanize object
  $session->mech;

=head1 DESCRIPTION

WWW::HatenaLogin login and logout interface to Hatena.
this module is very simple.

You can easily recycle login data the following WWW::Mechanize object and Cookie data. Please refer to the mech method and the cookie_jar method.


=head1 AUTHOR

=head2 new ( [I<\%args>] )

=over 4

  my $session = WWW::HatenaLogin->new({
      username => $username,
      password => $password,
      mech_opt => {
          timeout    => $timeout,
          cookie_jar => HTTP::Cookies->new(...),
      },
      com  => 1, # use to hatena.com server
      labo => 1, # use to hatelabo.jp server
      nologin => 1, # do not login with new method
  });

Creates and returns a new WWW::HatenaLogin object. If you have a valid
cookie and pass it into this method as one of C<mech_opt>, you can
omit C<username> and C<password>. Even in that case, you might want to
check if the user agent already logs in to Hatena using
C<is_loggedin> method below.

C<com> field is optional, which will be required if you login to hatena.com.

C<labo> field is optional, which will be required if you login to hatelabo.jp.

C<nologin> field is optional, which will be required if you do not login new method.

C<mech_opt> field is also optional. You can use it to customize the
behavior of this module in the way you like. See the POD of
L<WWW::Mechanize> for more details.

=back

=head2 is_loggedin ()

=over 4

  if(!$session->is_loggedin) {
      ...
  }

Checks if C<$session> object already logs in to Hatena.

=back

=head2 login ( [I<\%args>] )

=over 4

  $diary->login({
      username => $username,
      password => $password,
  });

Logs in to Hatena::Diary using C<username> and C<password>. If either
C<username> or C<password> isn't passed into this method, the values
which are passed into C<new> method above will be used.
 
=back

=head2 logout ()

=over 4

  $session->logout;

Logout by Hatena.

=back

=head2 mech ()

=over 4

  $session->mech;

return to L<WWW::Mechanize> object.

=back

=head2 cookie_jar ()

=over 4

  $session->cookie_jar;

return to L<HTTP::Cookies> object.
this method same to $session->mech->cookie_jar;

=back

=head2 session_id ()

=over 4

  $session->session_id;

return to session id.
key in cookie is a value of rk. 

=back

=head2 login_uri ()

=over 4

  $session->login_uri;

return to login uri.

=back

=head2 logout_uri ()

=over 4

  $session->logout_uri;

return to logout uri.

=back

=head2 username ('username')

=over 4

  $session->username;
  $session->username('new_username');

username accessor

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

=over 4

=item * Hatena

L<http://www.hatena.com/>

=item * L<WWW::Mechanize>

=back

=head1 ACKNOWLEDGMENT

some codes copied from L<WWW::HatenaDiary>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
