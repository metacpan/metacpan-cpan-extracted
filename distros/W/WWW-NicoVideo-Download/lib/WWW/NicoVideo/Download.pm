package WWW::NicoVideo::Download;

use strict;
use 5.8.1;
our $VERSION = '0.06';

use Carp;
use LWP::UserAgent;
use CGI::Simple;

use Any::Moose;
has 'email',      is => 'rw', isa => 'Str';
has 'password',   is => 'rw', isa => 'Str';
has 'user_agent', is => 'rw', isa => 'LWP::UserAgent', default => sub {
    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    push @{ $ua->requests_redirectable }, 'POST';
    $ua;
};

sub download {
    my $self = shift;
    my($video_id, @args) = @_;

    my $url = $self->prepare_download($video_id);
    my $res = $self->user_agent->request( HTTP::Request->new( GET => $url ), @args );

    croak "Download failed: ", $res->status_line if $res->is_error;
}

sub prepare_download {
    my($self, $video_id) = @_;

    if ($video_id =~ m!/watch/(\w+)!) {
        $video_id = $1;
    }

    my $ua  = $self->user_agent;
    my $res = $ua->get("http://www.nicovideo.jp/watch/$video_id");

    if ( $self->is_logged_out($res) ) {
        $self->login($video_id);
    }

    if ($video_id =~ m/so\d+/){
	my $u = $res->request->uri->as_string;
	$u =~ m|.+/([^?]+)|;
	$video_id = $1;
    }

    my $time = scalar time;
    $res = $ua->get("http://flapi.nicovideo.jp/api/getflv?v=$video_id&ts=$time&as3=1");
    if ($res->is_error) {
        croak "getflv API error: ", $res->status_line;
    }

    my $params = CGI::Simple->new($res->content);
    my $url = $params->param('url')
        or croak "URL not found in getflv response";

    # Not sure why, but you need to get the page again
    $ua->get("http://www.nicovideo.jp/watch/$video_id");

    return $url;
}

sub is_logged_out {
    my($self, $res) = @_;
    $res->headers->header('x-niconico-authflag') eq '0';
}

sub login {
    my($self, $video_id) = @_;

    my $res = $self->user_agent->post("https://secure.nicovideo.jp/secure/login?site=niconico", {
        next_url => "/watch/$video_id",
        mail     => $self->email,
        password => $self->password,
    });

    if ($res->is_error) {
        croak "Login failed: " . $res->status_line;
    } elsif ( $self->is_logged_out($res) ) {
        croak "Login failed because of bad email and password combination.";
    }

    return 1;
}

1;
__END__

=encoding utf-8

=for stopwords nicovideo.jp Nico Douga API FLV Plagger UserAgent Wada Yusuke login woremacx

=head1 NAME

WWW::NicoVideo::Download - Download FLV/MP4/SWF files from nicovideo.jp

=head1 SYNOPSIS

  use WWW::NicoVideo::Download;

  my $client = WWW::NicoVideo::Download->new(
      email => 'your-email@example.com',
      password => 'PASSWORD',
  );

  $client->download("smNNNNNN", \&callback);

=head1 DESCRIPTION

WWW::NicoVideo::Download is a module to login, request and download video files from Nico Nico Douga.

=head1 METHODS

=over 4

=item new

  $client = WWW::NicoVideo::Download->new(%options);

Creates a new WWW::NicoVideo::Download instance. %options can take the
following parameters and they can also be set and get using accessor
methods.

=item email, password

Sets and gets email and password to login Nico Nico Douga. Required if the User
Agent object doesn't have the valid session or cookie to login to the
site.

=item user_agent

Sets and gets LWP::UserAgent object to use to send HTTP requests to
nicovideo.jp server. If you want to reuse the browser Cookie that has
the signed-in state, you can set the Cookie to the UserAgent object
here.

  # use Safari sesssions
  use HTTP::Cookies::Safari;
  my $cookie_jar = HTTP::Cookies::Safari->new(
      file => "$ENV{HOME}/Library/Cookies/Cookies.plist",
  );
  my $client = WWW::NicoVideo::Download->new;
  $client->user_agent->cookie_jar( $cookie_jar );

=item download

  $client->download($video_id, $file_path);

Prepares the download by logging in and requesting the FLV API, and
then download the video file. The second parameter is passed to
LWP::UserAgent's request() method, so you can pass either local file
path to be saved, or a callback function.

=item prepare_download

  my $url = $client->prepare_download($video_id);

Prepares the download and returns the URL of the actual video. See
I<eg/fetch-video.pl> how to make use of this method.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

Original download code for Plagger was written by Yusuke Wada and the command line tool written by woremacx.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
