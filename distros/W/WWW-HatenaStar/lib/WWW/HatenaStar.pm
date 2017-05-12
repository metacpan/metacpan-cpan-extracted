package WWW::HatenaStar;

use strict;
use 5.8.1;
our $VERSION = '0.04';


use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(error));

use WWW::HatenaLogin;
use URI;
use JSON::Syck 'Load';
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep);

sub new {
    my ($class, $args) = @_;
    my $self = bless {
        %$args,
    }, $class;

    $self;
}


sub _login {
    my $self = shift;

    my $session = eval {
        WWW::HatenaLogin->new({
            username => $self->{config}->{username},
            password => $self->{config}->{password},
            mech_opt => {
                timeout => $self->{config}->{timeout} || 30,
            },
        });
    };
    if ($@) {
        $self->error("WWW::HatenaLogin failed : " . $@);
        return undef;
    }
    unless ($session->is_loggedin) {
        $self->error("not logged in");
        return undef;
    }

    $self->{session} = $session;
}


sub stars {
    my ($self, $data, $opt) = @_;

    if (blessed($data) && $data->isa('URI')) {
        $data = { uri => $data->as_string };
    } elsif (ref($data) ne 'HASH') {
        $self->error("parameter must be HASHREF");
        return undef;
    }

    my $count = exists($data->{count}) ? $data->{count} : 0;

    my $res = $self->_entries_json($data->{uri});
    return undef unless $res;

    if ($count) {
        my $wait = exists($opt->{wait}) ? $opt->{wait} : 0.5;

        my $cur = 0;
        my $max = $count;
        my $callback = ();
        if ($opt && $opt->{callback} && ref($opt->{callback}) eq 'CODE') {
            $callback = $opt->{callback};
            $callback->($cur, $max);
        }

        for ($cur = 1; $cur <= $max; $cur++) {
            $res = $self->_star_add_json($data);
            return undef unless $res;
            sleep($wait);

            $callback->($cur, $max) if $callback;
        }

        $res = $self->_entries_json($data->{uri});
        return undef unless $res;
    }

    $res;
}


sub _get {
    my ($self, $uri) = @_;

    unless ($self->{_logged_in}++) {
        my $loginres = $self->_login;
        return undef unless $loginres;
    }

    my $mech = $self->{session}->mech;
    $mech->get($uri);

    if ($mech->success) {
        $self->error(0);
        return $mech->content;
    } else {
        $self->error("access failed: " . $mech->res->status_line);
        return undef;
    }
}


sub _entries_json {
    my ($self, $url) = @_;

    my $uri = URI->new("http://s.hatena.ne.jp/entries.json");
    $uri->query_form( uri => $url );

    my $res = $self->_get($uri);
    return undef unless $res;

    my $content = Load($res);
    unless (exists($content->{rks})) {
        $self->error("cannot get rks for $url");
        return undef;
    }

    $self->{$url}->{rks} = $content->{rks};

    $content;
}


sub _star_add_json {
    my ($self, $data) = @_;

    my $url = $data->{uri};
    my $uri = URI->new("http://s.hatena.ne.jp/star.add.json");
    my %form;

    for my $key (qw(uri title quote location)) {
        $form{$key} = defined($data->{$key}) ? $data->{$key} : "";
    }
    $form{location} ||= $data->{uri};
    $form{rks} = $self->{$url}->{rks};
    $uri->query_form(\%form);

    my $res = $self->_get($uri);
    return undef unless $res;

    my $content = Load($res);
    if (defined($content->{errors})) {
        $self->error($content->{errors});
        return undef;
    }

    $res;
}

1;
__END__

=head1 NAME

WWW::HatenaStar - perl interface to Hatena::Star

=head1 SYNOPSIS

  use WWW::HatenaStar;

  my $conf = { username => "woremacx", password => "vagina" };
  my $star = WWW::HatenaStar->new({ config => $conf });

  my $uri = "http://blog.woremacx.com/";
  # you will have 5 stars
  my $res = $star->stars({
      uri   => $uri,
      quote => "woremacx++",
      count => 5,
  }, {
      # defualt wait is 0.5
      wait     => 1,

      # will passed $current_count and $max_count to callback
      # example: eg/with_progress.pl
      callback => \&callback,
  });
  unless ($res) {
      die "WWW::HatenaStar complains : " . $star->error;
  }


=head1 DESCRIPTION

WWW::HatenaStar is perl interface to Hatena::Star.

=head1 AUTHOR

woremacx E<lt>woremacx at cpan dot orgE<gt>

otsune

=head1 THANKS

dann (cpanid: kitano)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * Hatena::Star (Japanese)

L<http://s.hatena.ne.jp/>

=item * L<WWW::HatenaLogin>

=cut
