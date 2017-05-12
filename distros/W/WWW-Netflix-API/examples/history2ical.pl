#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;
use Date::Calc qw/ Localtime /;
use Data::ICal;
use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

my $netflix = WWW::Netflix::API->new({
	do('./vars.inc'),
	content_filter => sub { XMLin(@_) },
});

$netflix->REST->Users->Rental_History;
$netflix->Get( max_results => 500 ) or die $netflix->content_error;

my %events;
my $items = $netflix->content->{rental_history_item};
while( my ($k, $v) = each %$items ){
  next unless $k =~ m#/rental_history/(watched|shipped|returned)/(\d+)$#;
  my ($which, $id) = ($1, $2);
  $events{$id} ||= {
	id => $id,
	title => $v->{title}->{regular},
  };
  if(     $which eq 'shipped' ){
    $events{$id}->{start_date} = $v->{shipped_date} + 24*60*60;
    $events{$id}->{end_date} ||= time;
  }elsif( $which eq 'returned' ){
    $events{$id}->{end_date}   = $v->{returned_date};
  }elsif( $which eq 'watched' ){
    $events{$id}->{start_date} = $v->{watched_date};
    $events{$id}->{end_date}   = $v->{watched_date};
  }
}


my $calendar = Data::ICal->new();
$calendar->add_properties(
	'VERSION'	=>	'2.0',
	'PRODID'	=>	'-//Mozilla.org/NONSGML Mozilla Calendar V1.0//EN',
	'CALSCALE'	=>	'GREGORIAN',
	'X-WR-CALNAME'	=>	'My Netflix Movies',
	'X-WR-CALDESC'	=>	'My Netflix history',
);

foreach my $row ( values %events ){
    my $vevent = Data::ICal::Entry::Event->new();
    $vevent->add_properties(
	summary => $row->{title},
    );
    my (%dt, $dt);
    @dt{ qw/year month day/ } = (Localtime($row->{start_date}))[0,1,2];
    $dt = DateTime->new( %dt );
    $vevent->start($dt);
    if( $row->{end_date} ){
      @dt{ qw/year month day/ } = (Localtime($row->{end_date}))[0,1,2];
      $dt = DateTime->new( %dt );
      $vevent->end($dt);
    }
    $vevent->all_day(1);
    $calendar->add_entry($vevent);
}

my $s = $calendar->as_string;
$s =~ s/(?<=\d{8})T000000$//mg;
print $s;

