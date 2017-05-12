# $Id: TvDotNu.pm,v 1.2 2004/03/31 20:28:08 claes Exp $

package WWW::Search::Tv::Sweden::TvDotNu;

use 5.008;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTML::Parser;
use WWW::Search::Tv::Sweden::TvDotNu::DB;
use WWW::Search::Tv::Sweden::TvDotNu::Entry;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::Search::Tv::Sweden::TvDotNu ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.01';

# Always use this user agent
my $UserAgent = LWP::UserAgent->new();

# Month names
my @Months = qw(jan feb mar apr may jun jul aug sep oct nov dec);

# Preloaded methods go here.

sub new {
  my ($class, %args) = @_;
  $class = ref($class) || $class;
  bless {
	 cache => 1,
	 %args
	}, $class;
}

sub get_today {
  my ($self) = @_;
  return $self->get("http://www.tv.nu");
}

sub get_tomorrow {
  my ($self) = @_;
  my ($day, $mon) = (localtime(time))[3,4];
  my $url = "http://show.tv.nu/" . $Months[$mon] . "/" . ($day + 1) . "/";
  return $self->get($url);
}

sub get_full_entry {
  my ($self, $entry) = @_;

  my $request = HTTP::Request->new(GET => $entry->url);
  my $response = $UserAgent->request($request);

  if($response->is_success) {
    $self->_parse_entry($response->content(), $entry);
  }
}

sub get {
  my ($self, $url) = @_;

  my $request = HTTP::Request->new(GET => $url);
  my $response = $UserAgent->request($request);

  if($response->is_success) {
    return $self->_parse_toc($response->content());
  }
}

sub _parse_toc {
  my ($self, $content) = @_;
  
  my $db = WWW::Search::Tv::Sweden::TvDotNu::DB->new();
  
  my $start_h = $self->_toc_start_h($db);
  my $end_h = $self->_toc_end_h($db);
  my $text_h = $self->_toc_text_h($db);

  my $toc_parser = HTML::Parser->new(api_version => 3,
				     start_h => [$start_h, "tagname, attr"],
				     text_h => [$text_h, "dtext"],
				     end_h => [$end_h, "tagname"],
				    );
  
  $toc_parser->parse($content);
  
  return $db;
}

sub _parse_entry {
  my ($self, $content, $entry) = @_;

  my $start_h = $entry->_entry_start_h();
  my $end_h = $entry->_entry_end_h();
  my $text_h = $entry->_entry_text_h();

  my $entry_parser = HTML::Parser->new(api_version => 3,
				       start_h => [$start_h, "tagname, attr"],
				       text_h => [$text_h, "dtext"],
				       end_h => [$end_h, "tagname"],
				      );
  
  $entry_parser->unbroken_text(1);
  $entry_parser->parse($content);
}

sub _toc_start_h {
  my ($self, $db) = @_;
  
  return sub {
    my ($tagname, $attr) = @_;
    
    if($tagname eq 'a') {
      if(exists $attr->{href} && $attr->{href} =~ /^javascript:p(.*)$/) {
	my ($url, $channel, 
	    $start_hour, $start_min, 
	    $end_hour, $end_min) = $1 =~ m{
					   ^\(\'
					   (.*)\/
					   (.*)\/
					   (\d\d)(\d\d)-(\d\d)(\d\d)
					   \.html\'}x;
	
	next unless($url && $channel && "$start_hour$start_min" && "$end_hour$end_min");
	$url = join("", $url, "/", $channel, "/", $start_hour, $start_min, "-", $end_hour, $end_min, ".html");
      
	my $entry = WWW::Search::Tv::Sweden::TvDotNu::Entry->new(url => $url,
								 channel => $channel,
								 start_time => [
										$start_hour + 0,
										$start_min + 0
									       ],
								 end_time => [
									    $end_hour + 0,
									      $end_min + 0
									     ],
								 title => "",
								);
	
	$db->add($entry);
	$self->{open_a} = 1;
      }
    }
  };
}

sub _toc_text_h {
  my ($self, $db) = @_;
 
  return sub {
    my ($text) = @_;

    if($self->{open_a}) {
      $db->last->title($text);
    }
  }
}
sub _toc_end_h {
  my ($self) = @_;

  return sub {
    my ($tagname) = @_;
    if($tagname eq 'a') {
      $self->{open_a} = 0;
    }
  }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::Search::Tv::Sweden::TvDotNu - Perl extension for fetching television program from swedish site http://www.tv.nu

=head1 SYNOPSIS

  use WWW::Search::Tv::Sweden::TvDotNu;

  my $tv = WWW::Search::Tv::Sweden::TvDotNu->new();

  my $today = $tv->get_today();

  foreach my $entry ($today->for_channel('svt1')->entires) {
    print $entry->start_time, ": ", $entry->title, "\n";
    if($entry->title =~  /Kultur/) {
      $tv->get_full_entry($entry);
      print "\t", $entry->description, "\n"\n";
    }
  }

=head1 DESCRIPTION

The WWW::Search::Tv::Sweden::TvDotNu module provides an object-oriented API for retrival and searching of television table of contents from the swedish site http://www.tw.nu. The site provides todays and tomorrows program for the following channels. The abrivated name used internally by the module and which must (should) be used when searching the record set is written within ().

SVT 1 (svt1), SVT 2 (svt2), 
TV 3 (tv3), TV 4 (tv4), 
Kanal 5 (kanal5), TV 8 (tv8), TV 6 (tv6),
ZTV (ztv), ViaSat Sport (viasatsport), EuroSport (eurosport),
Discovery (discovery), Discovery Mix (discomix), National Geographics (ng),
Hallmark (hallmark), TV 1000 (tv1000), Cinema (cinema), 
Canal Plus (cplus), Canal Plus Yellow (cplusgul), Canal Plus Blue (cplusbla)

=head1 EXPORT

None.

=head1 WWW::Search::Tv::Sweden::TvDotNu

This object is the base of all TOC and information retrival. Create one by using B<new> and then one of the object methods
 
=head2 new

Creates a new WWW::Search::Tv::Sweden::TvDotNu object

=head2 get_today

Fetches todays TOC and returns a B<WWW::Search::Tv::Sweden::TvDotNu::DB> object that holds todays entries.

=head2 get_tomorrow

Fetches tomorrows TOC and returns a B<WWW::Search::Tv::Sweden::TvDotNu::DB> object that holds tomorrows entries.

=head2 get_full_entry($entry)

Fetches more information for B<$entry> and fills it up. Returns nothing.

=head1 WWW::Search::Tv::Sweden::TvDotNu::DB

Each TOC consists of a database of this class. The database itself contains numerous B<WWW::Search::Tv::Sweden::TvDotNu::Entry> object that holds information about each show. The database class provides the following methods for searching the TOC.

=head2 channels

Returns a list of abriviated channel names currently in TOC. See above for list.

=head2 for_channel(@channels);

Given a list of abriviated channel names, it returns a new database containing only those entries matching the channel search.

=head2 between($starth,$startm,$endh,$endm)

Does a match on start time for program. Returns a new database with those entries that starts within the specified times.

=head2 entries

Returns a list of the entries in the database.

=head1 WWW::Search::Tv::Sweden::TvDotNu::Entry

Each program is a entry object of this class. It contains the following methods:

=head2 title

Get the title of the program.

=head2 channel

Get the name of the channel the program is showing on.

=head2 url

Get the URL to http://www.tv.nu/ site where more info can be found.

=head2 showview

Get the ShowView number for programming videos or other recodings with.

=head2 description

Get a longer description about the program.

=head2 imdb

Get a search link to http://www.imdb.com/ for searching for the program.

=head2 start_time 

Get the starting time for the program formated as HH:MM

=head2 end_time

Get the ending time for the program formated as HH::MM

=head1 SEE ALSO

http://www.tv.nu - For seeing the online version

Todays newspaper should also contain the Television schedule, but it's more fun this way.

=head1 AUTHOR

Claes Jacobsson, claesjac@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
