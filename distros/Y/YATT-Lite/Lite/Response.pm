package YATT::Lite::Response; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

use parent qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/status headers body/;

require Encode;

#========================================
# Constructors
#========================================

# Wrap a PSGI response (ARRAY triple, or delayed/streaming CODE)
# into a YATT::Lite::Response.
sub from_psgi {
  my ($pack, $res) = @_;
  if (ref $res eq 'CODE') {
    $res = $pack->_run_streaming($res);
  }
  unless (ref $res eq 'ARRAY' and @$res >= 2) {
    croak "Invalid PSGI response: ".(defined $res ? $res : '(undef)');
  }
  my ($status, $headers, $body) = @$res;
  $pack->new(status => $status
	     , headers => ($headers ? [@$headers] : [])
	     , body => $pack->_collect_body($body));
}

sub _run_streaming {
  my ($pack, $app) = @_;
  my ($status, $headers, $body, @chunks);
  $app->(sub {
	   my ($tuple) = @_;
	   ($status, $headers) = @$tuple[0, 1];
	   if (@$tuple >= 3) {
	     $body = $tuple->[2];
	     return;
	   }
	   $body = \@chunks;
	   return MY."::Writer"->new(\@chunks);
	 });
  [$status, $headers, $body];
}

sub _collect_body {
  my ($pack, $body) = @_;
  if (not defined $body) {
    [];
  } elsif (ref $body eq 'ARRAY') {
    [@$body];
  } else {
    # IO::Handle-ish body (including real filehandles).
    require Plack::Util;
    my @chunks;
    Plack::Util::foreach($body, sub {push @chunks, $_[0]});
    \@chunks;
  }
}

#========================================
# Accessors
#========================================

sub status {
  (my MY $self) = @_;
  $self->{status};
}

sub is_success {
  (my MY $self) = @_;
  my $status = $self->{status} // 0;
  $status >= 200 && $status < 300;
}

sub headers {
  (my MY $self) = @_;
  my $list = $self->{headers} // [];
  wantarray ? @$list : $list;
}

sub header {
  (my MY $self, my $name) = @_;
  my $list = $self->{headers} // [];
  my @found;
  for (my $i = 0; $i + 1 <= $#$list; $i += 2) {
    push @found, $list->[$i+1] if lc($list->[$i]) eq lc($name);
  }
  wantarray ? @found : $found[0];
}

# Raw body: list of chunks in list context, joined octets in scalar context.
sub body {
  (my MY $self) = @_;
  my $list = $self->{body} // [];
  wantarray ? @$list : join('', grep {defined} @$list);
}

# Decoded text (utf-8 unless already decoded).
sub content {
  (my MY $self) = @_;
  my $raw = join '', grep {defined} @{$self->{body} // []};
  utf8::is_utf8($raw) ? $raw : Encode::decode(utf8 => $raw);
}

#========================================
# Minimal writer for streaming PSGI responses.
#========================================
{
  package YATT::Lite::Response::Writer;
  sub new {
    my ($pack, $chunks) = @_;
    bless [$chunks], $pack;
  }
  sub write {
    my $self = shift;
    push @{$self->[0]}, @_;
  }
  sub close {}
}

1;
