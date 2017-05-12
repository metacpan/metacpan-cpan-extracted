package YAWF::HTTP;

use strict;
use warnings;

use LWP::UserAgent;

sub new {
 my $class = shift;
 
 my $self = bless { _ua => LWP::UserAgent->new},$class;
 
 return $self;
}

sub data_conv { # Data-Hash-Ref
 my $self = shift;

 return '' unless defined($_[0]);
 return $_[0] if ref($_[0]) ne 'HASH';

 return join('&',map {
  my $Val = $_[0]->{$_};
  $Val =~ s/(\W)/"%".uc(unpack("H*",$1))/ge;
  $Val =~ s/\%20/\+/g;
  $_.'='.$Val;
 } (keys(%{$_[0]})));

}

sub get { # URL, \%Daten
 my $self = shift;
 
 my ($url,$daten) = @_;

 my $http_data = $self->data_conv($daten);
 $http_data = '?'.$http_data if defined($http_data);

 my $req = HTTP::Request->new(GET => $url.$http_data);

 my $result = $self->{_ua}->request($req);

 if ($result->is_success) {
  if (wantarray) {
   return $result->content,$result;
  } else {
   return $result->content;
  }
 } else {
  if (wantarray) {
   return undef,$result;
  } else {
   return undef;
  }
 }
}

sub post { # URL, \%Daten
 my $self = shift;

 my ($url,$data) = @_;

 my $req = HTTP::Request->new(POST => $url);
 $req->content_type('application/x-www-form-urlencoded');
 $req->content($self->data_conv($data));

 my $result = $self->{_ua}->request($req);

 if ($result->is_success) {
  if (wantarray) {
   return $result->content,$result;
  } else {
   return $result->content;
  }
 } else {
  if (wantarray) {
   return undef,$result;
  } else {
   return undef;
  }
 }
}

1;
