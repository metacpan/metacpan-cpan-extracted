use strict;
use warnings;
use Test::More qw(no_plan);
use Win32::IE::SlideShow;
use Win32::OLE;

my @slides;
foreach my $text ( qw( first second third ) ) {
  push @slides, "<html><body><h1>$text slide</h1></body></html>";
}

my $shell = Win32::OLE->new('Shell.Application')
              or die Win32::OLE->LastError;

my $original = $shell->Windows->Count;

# this may or may not be invoked by ::SlideShow
my $first_show  = Win32::IE::SlideShow->new;

if ( $original ) {
  ok !$first_show->{invoked};
}
else {
  ok $first_show->{invoked};
}

$first_show->set( @slides );
while( $first_show->has_next ) {
  $first_show->next;
  sleep 1;
}

# this should not be invoked by ::SlideShow (should be reused)
my $second_show = Win32::IE::SlideShow->new;

ok !$second_show->{invoked};

$second_show->set( @slides );
while( $second_show->has_next ) {
  $second_show->next;
  sleep 1;
}

$second_show->quit;
$first_show->quit;

sleep 3; # wait a bit while IE's going.

# should be the same
ok $shell->Windows->Count == $original;
