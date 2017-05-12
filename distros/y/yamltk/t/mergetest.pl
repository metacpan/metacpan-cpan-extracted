#!/usr/bin/perl
use strict;
use YAML;
use Smart::Comments '###';


my @streams;




=pod
my @stream_now;

while (my $line = <>){

   if ( ($line eq "---\n") ){
      @stream_now   
         and ( push @streams, [@stream_now] )
         and ( @stream_now = () );
   }
   push @stream_now, $line;
}
=cut

my $streams;
my $delim="---\n";

while (my $line = <>){
   $streams.=$line;
}



for (
   grep { /\w/ } split ( /\Q$delim\E+/, $streams )
){   
   push @streams, $delim . $_ ;
}







### @streams

# merge them all
my %data;

for (@streams){
   my $data = YAML::Load( $_ );

   map { $data{$_} = $data->{$_} } keys %$data;
}

print YAML::Dump(\%data);







