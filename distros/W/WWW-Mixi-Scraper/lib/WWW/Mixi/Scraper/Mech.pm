package WWW::Mixi::Scraper::Mech;

use strict;
use warnings;
use Encode;
use WWW::Mechanize 1.50;
use WWW::Mixi::Scraper::Utils qw( _uri );
use Time::HiRes qw( sleep );

sub new {
  my ($class, %options) = @_;

  my $email    = delete $options{email};
  my $password = delete $options{password};
  my $next_url = delete $options{next_url};

  $options{agent} ||= "WWW-Mixi-Scraper/$WWW::Mixi::Scraper::VERSION";
  $options{cookie_jar} ||= {};

  my $mech = WWW::Mechanize->new( %options );
  my $self = bless {
    mech  => $mech,
    login => {
      email    => $email,
      password => $password,
      next_url => $next_url,
      sticky   => 'on',
    }
  }, $class;

  $self;
}

sub login {
  my $self = shift;

  sleep(1.0); # intentional delay not to access too frequently

  $self->{mech}->post( 'http://mixi.jp/login.pl' => $self->{login} );

  $self->may_have_errors('Login failed');

  # warn "logged in to mixi";
}

sub logout {
  my $self = shift;

  $self->get('/logout.pl');

  $self->may_have_errors('Failed to logout');
}

sub may_have_errors {
  my $self = shift;

  $self->{mech}->success or $self->_error(@_);
}

sub _error {
  my ($self, $message) = @_;

  $message ||= 'Mech error';

  die "$message: ".$self->{mech}->res->status_line;
}

sub get {
  my ($self, $uri) = @_;

  $uri = _uri($uri) unless ref $uri eq 'URI';

  sleep(1.0); # intentional delay not to access too frequently

  $self->{mech}->get($uri);

  # adapted from Plagger::Plugin::CustomFeed::Mixi
  if ( $self->content =~ /action="(http:\/\/mixi\.jp)?\/?login\.pl/ ) {
    # shouldn't be path but path_query, obviously
    $self->{login}->{next_url} = $uri->path_query;
    $self->login;

    # meta refresh
    if ( $self->content =~ /"0;url=(.*?)"/ ) {
      $self->{mech}->get($1);
    }
  }
  $self->{mech}->success;
}

sub content {
  my $self = shift;

  $self->{mech}->content;
}

sub get_content {
  my ($self, $uri, $encoding) = @_;

  my $content = $self->get($uri) ? $self->content : undef;

  if ( $content && $encoding ) {
    $content = encode( $encoding => $content );
  }
  $content;
}

sub uri {
  my $self = shift;
  $self->{mech}->uri;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Mech

=head1 SYNOPSIS

    use WWW::Mixi::Scraper::Mech;
    my $mech = WWW::Mixi::Scraper::Mech->new;
       $mech->login( 'foo@bar.com' => 'password' );

       $mech->may_have_errors('Cannot login');

    my $html = $mech->get_content('/new_friend_diary.pl');

    $mech->logout;
 
=head1 DESCRIPTION

Mainly used internally.

=head1 METHODS

=head2 new

creates an object. Optional hash is passed to WWW::Mechanize, except for 'email' and 'password' (and 'next_url'), which are used to login.

=head2 get

gets content of the uri.

=head2 content

returns (hopefully decoded) content.

=head2 get_content

As name suggests, this does both 'get' and 'content'. If you pass an additional encoding (which must be Encode-understandable), this returns encoded content.

=head2 login

tries to log in to mixi. As of writing this, password obfuscation and ssl login are not implemented.

=head2 logout

tries to log out from mixi.

=head2 may_have_errors

dies with error message and status code if something is wrong (this may change)

=head2 uri

shortcut for {mech}->uri.

=head1 SEE ALSO

L<WWW::Mechanize>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
