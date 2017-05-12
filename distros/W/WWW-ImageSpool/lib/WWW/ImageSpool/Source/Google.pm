#!perl

package WWW::ImageSpool::Source::Google;

use strict;
use warnings;
use WWW::ImageSpool::Source;
use base qw(WWW::ImageSpool::Source);
use vars qw($LIMIT $SEARCHLIMIT @EXPORT_OK);

use WWW::Google::Images;

@EXPORT_OK = qw($LIMIT);
$LIMIT = 5;
$SEARCHLIMIT = 50;
return 1;

sub new
{
 my $class = shift;
 my %args = @_;
 my %google_args;
 my $self;
 
 $google_args{server} = $args{server}
  if($args{server});
 
 $google_args{proxy} = $args{proxy}
  if($args{proxy});

 $args{limit} ||= $LIMIT;
 $args{searchlimit} ||= $SEARCHLIMIT;
 
 if(my $agent = WWW::Google::Images->new(%google_args))
 {
  $self = bless { args => \%args, google_args => \%google_args, agent => $agent, urls => {} }, $class;
 }
 else
 {
  warn "WWW::ImageSpool::Sources::Google->new(): Failed to initialize WWW::Google::Images object!\n";
  return;
 }

 return $self;
}

sub agent_search 
{
 my($self, $search, $searchlimit) = @_;
 my $count = 0;

 if(!$search)
 {
  return;
 }
 
 if(!$searchlimit)
 {
  $searchlimit = $self->{args}->{searchlimit};
 }
 
 my $result = ($self->{agent}->search($search, limit => $searchlimit));
 my @result;
 my $image;

 while(($count < $searchlimit) && ($image = $result->next()))
 {
  my $url = $image->content_url();
  push(@result, $image->content_url());
  $count++;
 }
 if(scalar(@result))
 {
  if($self->{args}->{verbose} > 2)
  {
   print scalar(@result), "/$searchlimit results for $search.\n";
  }
  return(@result);
 }
 else
 {
  return;
 }
}
