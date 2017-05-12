#!perl

package WWW::ImageSpool::Source;
use strict;
use Exporter;
use base qw(Exporter);

return 1;

sub search
{
 my($self, $search, $limit, $searchlimit) = @_;
 $limit ||= $self->{args}->{limit};
 $searchlimit ||= $self->{args}->{searchlimit};
 my $count = 0;
 my(@result) = ($self->agent_search($search, $searchlimit));
 my(@rv);
 my $returned = scalar(@result);

 while(($count < $limit) && (scalar(@result)))
 {
  push(@rv, splice(@result, int(rand(@result)), 1));
  $count++;
 }
 
 if($self->{args}->{verbose} > 1)
 {
  print "Picked ", scalar(@rv), "/$returned results from \"$search\".\n";
 }
 
 return(@rv);
}
