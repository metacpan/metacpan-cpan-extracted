package WebService::DailyConnect;

use strict;
use warnings;
use 5.010;
use Moose;
use URI;
use Carp ();

# ABSTRACT: Web client to download events from Daily Connect
our $VERSION = '0.03'; # VERSION


has ua => (
  is      => 'ro',
  isa     => 'HTTP::AnyUA',
  lazy    => 1,
  default => sub {
    require HTTP::AnyUA;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(
      cookie_jar => {},
    );
    $ua->env_proxy;
    HTTP::AnyUA->new(
      ua => $ua,
    );
  },
);


has base_url => (
  is      => 'ro',
  isa     => 'URI',
  lazy    => 1,
  default => sub {
    URI->new('https://www.dailyconnect.com/');
  },
);


has req => (
  is => 'rw',
);


has res => (
  is => 'rw',
);

around BUILDARGS => sub {
  my($orig, $class, %args) = @_;

  if(defined $args{ua} && ! eval { $args{ua}->isa('HTTP::AnyUA') })
  {
    require HTTP::AnyUA;
    HTTP::AnyUA->new(ua => $args{ua});
  }

  return $class->$orig(%args);
};

sub _url
{
  my($self, $path) = @_;
  URI->new_abs($path, $self->base_url);
}


sub login
{
  my($self, $email, $pass) = @_;
  Carp::croak("Usage: \$dc->login(\$email, \$pass)") unless $email && $pass;
  my $res = $self->_post('Cmd?cmd=UserAuth', { email => $email, pass => $pass });
  $res->{status} == 302;
}

sub _post
{
  my($self, $path, $form) = @_;
  my $url = $self->_url($path)->as_string;
  my $req = [ $url, $form ];
  $self->req([ 'POST', @$req ]);
  my $res = $self->ua->post_form(@$req);
  $self->res($res);
}

sub _json
{
  my(undef, $json) = @_;
  require JSON::MaybeXS;
  JSON::MaybeXS::decode_json($json);
}

sub _today
{
  my($year,$month,$day) = (localtime(time))[5,4,3];
  $month++;
  $year = $year + 1900 - 2000;
  join('', map { sprintf "%02d", $_ } $year, $month, $day);
}


sub user_info
{
  my($self) = @_;
  my $res = $self->_post('CmdW', { cmd => 'UserInfoW'});
  $res->{status} == 200 ? $self->_json($res->{content}) : ();
}


sub kid_summary
{
  my($self, $kid_id) = @_;
  Carp::croak("Usage: \$dc->kid_summary_by_date(\$kid_id)") unless $kid_id;
  $self->kid_summary_by_date($kid_id, $self->_today);
}


sub kid_summary_by_date
{
  #date: yymmdd
  my($self, $kid_id, $date) = @_;
  Carp::croak("Usage: \$dc->kid_summary_by_date(\$kid_id, \$date)") unless $kid_id && $date;
  my $res = $self->_post('CmdW', { cmd => 'KidGetSummary', Kid => $kid_id, pdt => $date });
  $res->{status} == 200 ? $self->_json($res->{content}) : ();
}


sub kid_status
{
  my($self, $kid_id) = @_;
  Carp::croak("Usage: \$dc->kid_status_by_date(\$kid_id)") unless $kid_id;
  $self->kid_status_by_date($kid_id, $self->_today);
}


sub kid_status_by_date
{
  #date: yymmdd
  my($self, $kid_id, $date) = @_;
  Carp::croak("Usage: \$dc->kid_status_by_date(\$kid_id, \$date)") unless $kid_id && $date;
  my $res = $self->_post('CmdListW', { cmd => 'StatusList', Kid => $kid_id, pdt => $date, fmt => 'long' });
  $res->{status} == 200 ? $self->_json($res->{content}) : ();
}


sub photo
{
  my($self, $photo_id, $dest) = @_;
  Carp::croak("Usage: \$dc->photo(\$photo_id)") unless $photo_id;
  my $url = $self->_url('GetCmd')->clone;
  $url->query_form(cmd => 'PhotoGet', id => $photo_id, thumb => 0);
  $url = $url->as_string;
  $self->req([ 'GET', $url ]);
  my $res = $self->ua->get($url);
  $self->res($res);
  return unless $res->{headers}->{'content-type'} eq 'image/jpg';
  if(defined $dest)
  {
    if(ref($dest))
    {
      if(eval { $dest->isa('Path::Tiny') })
      {
        $dest->spew_raw($res->{content});
      }
      elsif(eval { $dest->isa('Path::Class::File') })
      {
        $dest->spew(iomode => '>:raw', $res->{content});
      }
      elsif(ref($dest) eq 'SCALAR')
      {
        $$dest = $res->{content};
      }
      else
      {
        Carp::croak("unknown destination type.  Must be one of: scalar, reference to scalar, Path::Tiny, Path::Class::File");
      }
    }
    else
    {
      require Path::Tiny;
      Path::Tiny->new($dest)->spew_raw($res->{content});
    }
    1;
  }
  else
  {
    return $res->{content};
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DailyConnect - Web client to download events from Daily Connect

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use WebService::DailyConnect;
 use Term::Clui qw( ask ask_password );
 use Path::Tiny qw( path );
 
 my $user = ask("email:");
 my $pass = ask_password("pass :");
 
 my $dc = WebService::DailyConnect->new;
 $dc->login($user, $pass) || die "bad email/pass";
 
 my $user_info = $dc->user_info;
 
 foreach my $kid (@{ $dc->user_info->{myKids} })
 {
   my $kid_id = $kid->{Id};
   my $name   = lc $kid->{Name};
   foreach my $photo_id (map { $_->{Photo} || () } @{ $dc->kid_status($kid_id)->{list} })
   {
     my $dest = path("~/Pictures/dc/$name-$photo_id.jpg");
     next if -f $dest;
     print "new photo: $dest\n";
     $dest->parent->mkpath;
     $dc->photo($photo_id, $dest);
   }
 }

=head1 DESCRIPTION

B<NOTE>: I no longer use DailyConnect, and happy to let someone who does need it
maintain it.  This module is otherwise unsupported.

Interface to DailyConnect, which is a service that can provide information about
your kids at daycare.  This is more or less a port of a node API that I found here:

L<https://github.com/Flet/dailyconnect>

I wrote this module for more or less the same reasons as that author, although I
wanted to be able to use it in perl.

It uses L<HTTP::AnyUA>, so should work with any Perl user agent supported by that
layer.

=head1 ATTRIBUTES

=head2 ua

An instance of L<HTTP::AnyUA>.  If a user agent supported by L<HTTP::AnyUA>
(such as L<HTTP::Tiny> or L<LWP::UserAgent>) is provided, a new instance of
L<HTTP::AnyUA> will wrap around that user agent instance.  The only requirement
is that the underlying user agent must support cookies.

If a C<ua> attribute is not provided, then an instance of L<HTTP::AnyUA> will
be created wrapped around a L<LWP::UserAgent> using the default proxy and a
cookie jar.

=head2 base_url

The base URL for daily connect.  The default should be correct.

=head2 req

The most recent request.  The format of the request object is subject to change, and therefore should only be used for debugging.

=head2 res

The most recent response.  The format of the response object is subject to change, and therefore should only be used for debugging.

=head2 METHODS

Beside login, methods typically return a hash or file content depending on the type of object requested.
On error they return C<undef>.  Further details for the failure can be deduced from the response object
stored in C<res> above.

=head2 login

 my $bool = $dc->login($email, $pass);

Login to daily connect using the given email and password.  The remaining methods only work once you have successfully logged in.

=head2 user_info

 my $hash = $dc->user_info;

Get a hash of the user information.

=head2 kid_summary

 my $hash = $dc->kid_summary($kid_id);

Get today's summary for the given kid.

=head2 kid_summary_by_date

 my $hash = $dc->kid_summary_by_date($kid_id, $date);

Get the summary for the given kid on the given day.  C<$date> is in the form YYMMDD.

=head2 kid_status

 my $hash = $dc->kid_status($kid_id);

Get today's status for the given kid.

=head2 kid_status_by_date

 my $hash = $dc->kid_status_by_date($kid_id, $date);

Get the status for the given kid on the given date.  C<$date> is in the form YYMMDD.

=head2 photo

 $dc->photo($photo_id);
 $dc->photo($photo_id, $dest);

Get the photo with the given C<$photo_id>.  If C<$dest> is not provided then the content of the photo in
JPEG format will be returned.  If C<$dest> is a scalar reference, then the content will be stored in that
scalar.  If C<$dest> is a string, then that string will be assumed to be a file, and the photo will be saved
there.  If a L<Path::Tiny> or L<Path::Class::File> object are passed in, then the content will be written
to the files at that location.

=head1 CAVEATS

DailyConnect does not provide a standard RESTful API, so it is entirely possible
they might change the interface of their app, and break this module.

My kiddo is an only child so I haven't been able to test this for more than one
kiddo.  May be a problem if you have twins or septuplets.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018,2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
