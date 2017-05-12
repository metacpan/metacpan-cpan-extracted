package Web::Dispatch::ParamParser;

use strict;
use warnings FATAL => 'all';

use Encode 'decode_utf8';

sub UNPACKED_QUERY () { __PACKAGE__.'.unpacked_query' }
sub UNPACKED_BODY () { __PACKAGE__.'.unpacked_body' }
sub UNPACKED_BODY_OBJECT () { __PACKAGE__.'.unpacked_body_object' }
sub UNPACKED_UPLOADS () { __PACKAGE__.'.unpacked_uploads' }
sub ORIG_ENV () { 'Web::Dispatch.original_env' }

sub get_unpacked_query_from {
  return ($_[0]->{+ORIG_ENV}||$_[0])->{+UNPACKED_QUERY} ||= do {
    _unpack_params($_[0]->{QUERY_STRING})
  };
}

sub get_unpacked_body_from {
  return ($_[0]->{+ORIG_ENV}||$_[0])->{+UNPACKED_BODY} ||= do {
    my $ct = lc($_[0]->{CONTENT_TYPE}||'');
    if (!$_[0]->{CONTENT_LENGTH}) {
      {}
    } elsif (index($ct, 'application/x-www-form-urlencoded') >= 0) {
      $_[0]->{'psgi.input'}->read(my $buf, $_[0]->{CONTENT_LENGTH});
      _unpack_params($buf);
    } elsif (index($ct, 'multipart/form-data') >= 0) {
      my $p = get_unpacked_body_object_from($_[0])->param;
      # forcible arrayification (functional, $p does not belong to us,
      # do NOT replace this with a side-effect ridden "simpler" version)
      +{
        map +(ref($p->{$_}) eq 'ARRAY'
               ? ($_ => $p->{$_})
               : ($_ => [ $p->{$_} ])
             ), keys %$p
      };
    } else {
      {}
    }
  };
}

sub get_unpacked_body_object_from {
  # we may have no object at all - so use a single element arrayref for ||=
  return (($_[0]->{+ORIG_ENV}||$_[0])->{+UNPACKED_BODY_OBJECT} ||= do {
    if (!$_[0]->{CONTENT_LENGTH}) {
      [ undef ]
    } elsif (index(lc($_[0]->{CONTENT_TYPE}||''),'multipart/form-data')==-1) {
      [ undef ]
    } else {
      [ _make_http_body($_[0]) ]
    }
  })->[0];
}

sub get_unpacked_uploads_from {
  $_[0]->{+UNPACKED_UPLOADS} ||= do {
    require Web::Dispatch::Upload; require HTTP::Headers;
    my ($final, $reason) = (
      {}, "field %s exists with value %s but body was not multipart/form-data"
    );
    if (my $body = get_unpacked_body_object_from($_[0])) {
      my $u = $body->upload;
      $reason = "field %s exists with value %s but was not an upload";
      foreach my $k (keys %$u) {
        foreach my $v (ref($u->{$k}) eq 'ARRAY' ? @{$u->{$k}} : $u->{$k}) {
          push(@{$final->{$k}||=[]}, Web::Dispatch::Upload->new(
            %{$v},
            headers => HTTP::Headers->new($v->{headers})
          ));
        }
      }
    }
    my $b = get_unpacked_body_from($_[0]);
    foreach my $k (keys %$b) {
      next if $final->{$k};
      foreach my $v (@{$b->{$k}}) {
        next unless $v;
        push(@{$final->{$k}||=[]}, Web::Dispatch::NotAnUpload->new(
          filename => $v,
          reason => sprintf($reason, $k, $v)
        ));
      }
    }
    $final;
  };
}

{
  # shamelessly stolen from HTTP::Body::UrlEncoded by Christian Hansen

  my $DECODE = qr/%([0-9a-fA-F]{2})/;

  my %hex_chr;

  foreach my $num ( 0 .. 255 ) {
    my $h = sprintf "%02X", $num;
    $hex_chr{ lc $h } = $hex_chr{ uc $h } = chr $num;
  }

  sub _unpack_params {
    my %unpack;
    (my $params = $_[0]) =~ s/\+/ /g;
    my ($name, $value);
    foreach my $pair (split(/[&;](?:\s+)?/, $params)) {
      $value = 1 unless (($name, $value) = split(/=/, $pair, 2)) == 2;

      s/$DECODE/$hex_chr{$1}/gs for ($name, $value);
      $_ = decode_utf8 $_ for ($name, $value);

      push(@{$unpack{$name}||=[]}, $value);
    }
    \%unpack;
  }
}

{
  # shamelessly stolen from Plack::Request by miyagawa

  sub _make_http_body {

    # Can't actually do this yet, since Plack::Request deletes the
    # header structure out of the uploads in its copy of the body.
    # I suspect I need to supply miyagawa with a failing test.

    #if (my $plack_body = $_[0]->{'plack.request.http.body'}) {
    #  # Plack already constructed one; probably wasteful to do it again
    #  return $plack_body;
    #}

    require HTTP::Body;
    my $body = HTTP::Body->new(@{$_[0]}{qw(CONTENT_TYPE CONTENT_LENGTH)});
    $body->cleanup(1);
    my $spin = 0;
    my $input = $_[0]->{'psgi.input'};
    my $cl = $_[0]->{CONTENT_LENGTH};
    while ($cl) {
      $input->read(my $chunk, $cl < 8192 ? $cl : 8192);
      my $read = length $chunk;
      $cl -= $read;
      $body->add($chunk);

      if ($read == 0 && $spin++ > 2000) {
        require Carp;
        Carp::croak("Bad Content-Length: maybe client disconnect? ($cl bytes remaining)");
      }
    }
    return $body;
  }
}

1;
