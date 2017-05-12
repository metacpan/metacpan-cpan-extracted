package WWW::IndexParser;
use warnings;
use strict;
use LWP::UserAgent;
use HTML::Parser;
use Time::Local;
use WWW::IndexParser::Entry;
use URI;
use Carp;

BEGIN {
  our $VERSION = "0.91";
}

our $months = {
  Jan => 0, January => 0, 
  Feb => 1, February => 1, 
  Mar => 2, March => 2,
  Apr => 3, April => 3,
  May => 4, 
  Jun => 5, June => 5,
  Jul => 6, July => 6,
  Aug => 7, August => 7,
  Sep => 8, September => 8,
  Oct => 9, October => 9,
  Nov => 10, November => 10,
  Dec => 11, December => 11 };




sub new {
 my $proto = shift;
 my $class = ref($proto)||$proto;
 my $self = {};
 bless $self, $class;
 my %args = @_;
 $self->{ua} = LWP::UserAgent->new;
 $self->{ua}->agent('PerlIndexParser/0.1');
 if (defined $args{timeout}) {
   if ($args{timeout} =~ /^\d+/) {
     $self->{ua}->timeout($args{timeout});
   } else {
     carp "Invalid timeout: " . $args{timeout};
     return;
   }
 } else {
   $self->{ua}->timeout(10);
 }
 if (defined $args{proxy}) {
   $self->{ua}->proxy('http', $args{proxy});
 }
 if (defined $args{debug}) {
   $self->{debug} = $args{debug};
 } else {
   $self->{debug} = 0;
 }
 $self->{parser} = HTML::Parser->new( api_version => 3);
 $self->{parser}->{debug} = $self->{debug};
 if (defined $args{url}) {
   $self->_url($args{url});
   return @{$self->{files}} if defined $self->{files};
   return;
 }
 return $self;
}



sub _url {
  my $self = shift;
  if (@_) {
    my $new_url = shift;
    warn "The URL was $new_url" if $self->{debug};

    $self->{url} = $new_url;
    if ($new_url =~ /^([^:]+):\/\/([^:\/]+)(:(\d+))?/) {
      $self->{server} = $2;
      $self->{protocol} = $1;
      $self->{port} = $4 if defined $4;
      $self->{req} = HTTP::Request->new(GET => $new_url);
      $self->{res} = $self->{ua}->request($self->{req});
      if (not $self->{res}->is_success) {
        carp "Cannot fetch for $new_url: " . $self->{res}->status_line if $self->{debug};
        return;
      }
    } else {
      warn "Invalid URL " . $new_url;
      return;
    }

    if (ref($self->{res}->headers->{'content-type'}) eq "ARRAY") {
      my $found_html = 0;
      foreach (@{$self->{res}->headers->{'content-type'}}) {
        $found_html = 1 if /^text\/html/;
      }
      if (not $found_html) {
        warn "Not an HTML page " . $self->{res}->headers->{'content-type'};
        return;
      }
    } elsif ($self->{res}->headers->{'content-type'} !~ /^text\/html/) {
     warn "Not an HTML page " . $self->{res}->headers->{'content-type'};
     return;
   }

    if ($self->{res}->headers->{server} =~ /^Apache-Coyote/) {
      warn "Server is Tomcat Coyote" if $self->{debug};
      $self->{parser}->handler( start => \&_parse_html_tomcat, "self, tagname, attr, attrseq, text");
      $self->{parser}->handler( text => \&_parse_html_tomcat, "self, tagname, attr, attrseq, text");
    } elsif ($self->{res}->headers->{server} =~ /^Apache/) {
      warn "Server is Apache" if $self->{debug};
      $self->{parser}->handler( start => \&_parse_html_apache, "self, tagname, attr, attrseq, text");
      $self->{parser}->handler( text => \&_parse_html_apache, "self, tagname, attr, attrseq, text");
    } elsif ($self->{res}->headers->{server} =~ /^Microsoft-IIS/) {
      warn "Server is IIS" if $self->{debug};
      $self->{parser}->handler( start => \&_parse_html_iis, "self, tagname, attr, attrseq, text");
      $self->{parser}->handler( text => \&_parse_html_iis, "self, tagname, attr, attrseq, text");
    } elsif ($self->{res}->headers->{server} =~ m!^lighttpd/!) {
      warn "Server is lighttpd" if $self->{debug};
      $self->{parser}->handler( start => \&_parse_html_lighttpd, "self, tagname, attr, attrseq, text");
      $self->{parser}->handler( text => \&_parse_html_lighttpd, "self, tagname, attr, attrseq, text");
    } else {
      warn "Unknown web server" if $self->{debug};
      return;
    }

    $self->{parser}->parse($self->{res}->content);
    $self->{parser}->eof();

    # Add the URL to each HASH for ease of use
    foreach my $entry (@{$self->{parser}->{files}}) {
      if ($entry->filename =~ /^\//) {
        $entry->url($self->{protocol} . "://" . $self->{server} . 
	   (defined $self->{port}?':' . $self->{port}:'') . 
	   $entry->filename);
      } else {
        $entry->url( URI->new_abs($entry->filename, $self->{url}) );
      }
    }
    # Get this back from the parser object.
    $self->{files} = $self->{parser}->{files};
  }
  return $self->{url};
}

sub _parse_html_tomcat {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

  if (not defined $tagname) {
    return unless $self->{parser_state};

    if ($self->{parser_state} == 2) {
      warn "The title is: $origtext" if $self->{debug};
      if ($origtext =~ /^Directory Listing For (.+)$/) {
        $self->{directory} = $1;
      }
      $self->{parser_state} = 1;
      return;
    }
    if ($self->{parser_state} == 1 && $origtext =~ /^([\d\.]+)(\s+(\w+))?/) {

      $self->{current_file}->{size} = $1;
      $self->{current_file}->{size_units} = $3 if defined $3;
    }
    if ($self->{parser_state} == 1 && $origtext =~ /^\w+,\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\w+)/) {
      my $time = timelocal($6, $5, $4, $1, $months->{$2}, $3-1900);
      $self->{current_file}->{time} = $time;
    }
  } elsif ($tagname eq 'title') {
    $self->{parser_state} = 2;
  } elsif ($tagname eq "hr" && $self->{parser_state} && defined $self->{current_file}) {
      my $entry = WWW::IndexParser::Entry->new;
      $entry->filename($self->{current_file}->{filename}) if defined $self->{current_file}->{filename};
      $entry->time($self->{current_file}->{time}) if defined $self->{current_file}->{time};
      $entry->size($self->{current_file}->{size}) if defined $self->{current_file}->{size};
      $entry->size_units($self->{current_file}->{size_units}) if defined $self->{current_file}->{size_units};
      push @{$self->{files}}, $entry;
      delete $self->{current_file};
    #$self->{parser_state} = 1;
  } elsif ($tagname eq "tr" && defined $self->{parser_state}) {
    if (defined $self->{current_file}) {
      my $entry = WWW::IndexParser::Entry->new;
      $entry->filename($self->{current_file}->{filename}) if defined $self->{current_file}->{filename};
      $entry->time($self->{current_file}->{time}) if defined $self->{current_file}->{time};
      $entry->size($self->{current_file}->{size}) if defined $self->{current_file}->{size};
      $entry->size_units($self->{current_file}->{size_units}) if defined $self->{current_file}->{size_units};
      push @{$self->{files}}, $entry;
      delete $self->{current_file};
    }
    $self->{parser_state} = 1;
  } elsif ($tagname eq "a" && defined $self->{parser_state}) {
    warn "  file name = " .  $attr->{href} if $self->{debug};
    $self->{current_file}->{filename} = $attr->{href} if $attr->{href};
    $self->{parser_state} = 1;
  }
}


sub _parse_html_apache {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

  if (not defined $tagname) {
    return unless $self->{parser_state};

    if ($self->{parser_state} == 2) {
      warn "The title is: $origtext" if $self->{debug};
      if ($origtext =~ /^Index of (.+)$/) {
        $self->{directory} = $1;
      }
      $self->{parser_state} = 1;
      return;
    }
    if ($origtext =~ /(\d\d)-(\w\w\w)-(\d{4}) (\d\d):(\d\d)\s+([\d\.]+)(\w)?/) {
      my $time = timelocal(0, $5, $4, $1, $months->{$2}, $3-1900);
      $self->{current_file}->{time} = $time;
      $self->{current_file}->{size} = $6;
      $self->{current_file}->{size_units} = $7 if defined $7;
    } elsif ($origtext =~ /(\d\d)-(\w\w\w)-(\d{4}) (\d\d):(\d\d)/) {
      my $time = timelocal(0, $5, $4, $1, $months->{$2}, $3-1900);
      $self->{current_file}->{time} = $time;
      warn " Found time (using Apache 2.2+ check)" if $self->{debug};
    } elsif ($origtext =~ /^(\d[\d\.]+)(\w)?/) {
      warn " Found size (using Apache 2.2+ check)" if $self->{debug};
      $self->{current_file}->{size} = $1;
      $self->{current_file}->{size_units} = $2 if defined $2;
    }
  } elsif ($tagname eq 'title') {
    $self->{parser_state} = 2;
  } elsif ($tagname eq "pre") {
    $self->{parser_state} = 1;
  } elsif (($tagname eq "img" || $tagname eq "hr") && defined $self->{parser_state}) {
    if (defined $self->{current_file} && $self->{current_file}->{filename} !~ /^\?/ && $self->{current_file}->{type} !~ /Icon/) {
      my $entry = WWW::IndexParser::Entry->new;
      $entry->filename($self->{current_file}->{filename}) if defined $self->{current_file}->{filename};
      $entry->time($self->{current_file}->{time}) if defined $self->{current_file}->{time};
      $entry->type($self->{current_file}->{type}) if defined $self->{current_file}->{type};
      $entry->size($self->{current_file}->{size}) if defined $self->{current_file}->{size};
      $entry->size_units($self->{current_file}->{size_units}) if defined $self->{current_file}->{size_units};
      push @{$self->{files}}, $entry;
      warn "Added " . $self->{current_file}->{filename} if $self->{debug};
      delete $self->{current_file};
    }
    if (defined $attr->{alt}) {
      warn "Possible new file:" . $attr->{alt} if $self->{debug};
      $self->{current_file}->{type} = $attr->{alt};
    }
  } elsif ($tagname eq "a" && defined $self->{parser_state}) {
    warn "  file name = " .  $attr->{href} if $self->{debug};
    $self->{current_file}->{filename} = $attr->{href} if defined $attr->{href};
  } else {
    warn $tagname if $self->{debug};
  }
}






sub _parse_html_iis {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

  if (not defined $tagname) {
    return unless $self->{parser_state};

    if ($self->{parser_state} == 2) {
      if ($origtext =~ /- (.+)$/) {
        $self->{directory} = $1;
      }
      $self->{parser_state} = 1;
      return;
    }
    if ($origtext =~ /\s*(\w+),\s+(\w+)\s+(\d+),\s+(\d{4})\s+(\d{1,2}):(\d\d) (AM|PM)\s+([\d\.]+)/) {
      my $hour_of_day = $5;
      $hour_of_day = 0 if ($7 eq 'AM' && $hour_of_day eq 12);
      $hour_of_day += 12 if ($7 eq 'PM' && $hour_of_day ne 12);
      my $time = timelocal(0, $6, $hour_of_day, $3, $months->{$2}, $4-1900);
      $self->{current_file}->{time} = $time;
      $self->{current_file}->{size} = $8;
    }
  } elsif ($tagname eq 'title') {
    $self->{parser_state} = 2;
  } elsif ($tagname eq "pre") {
    $self->{parser_state} = 1;
  } elsif ($tagname eq "br" && defined $self->{parser_state}) {
    if (defined $self->{current_file}) {
      my $entry = WWW::IndexParser::Entry->new;
      $entry->filename($self->{current_file}->{filename}) if defined $self->{current_file}->{filename};
      $entry->time($self->{current_file}->{time}) if defined $self->{current_file}->{time};
      $entry->size($self->{current_file}->{size}) if defined $self->{current_file}->{size};
      $entry->size_units($self->{current_file}->{size_units}) if defined $self->{current_file}->{size_units};
      push @{$self->{files}}, $entry;
      delete $self->{current_file};
    }
  } elsif ($tagname eq "a" && defined $self->{parser_state}) {
    warn "  file name = " .  $attr->{href} if $self->{debug};
    $self->{current_file}->{filename} = $attr->{href} if defined $attr->{href};
  }
}


sub _parse_html_lighttpd {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;
 
  if (not defined $tagname) {
    return unless $self->{parser_state};
  
    if ($self->{parser_state} eq 'title') {
      warn "The title is: $origtext" if $self->{debug};
      if ($origtext =~ m!^Index of (.+)/$!) {
        $self->{directory} = $1;
      }
      $self->{parser_state} = 1;
      return;
    }

    if ($self->{parser_state} eq 'time') {
      if ($origtext =~ /^(\d{4})-(\w\w\w)-(\d\d) (\d\d):(\d\d):(\d\d)$/) {
        my $time = timelocal(0, $5, $4, $3, $months->{$2}, $1-1900);
        $self->{current_file}->{time} = $time;
      }
    } elsif ($self->{parser_state} eq 'size') {
      if ($origtext =~ /^([\d\.]+)(\w)?/) {
        $self->{current_file}->{size} = $1;
        $self->{current_file}->{size_units} = $2 if defined $2;
      }
    } elsif ($self->{parser_state} eq 'type') {
      if ($origtext =~ /^[\w\-\/]+$/) {
        $self->{current_file}->{type} = $origtext;
      }
    }
  } elsif ($tagname eq 'title') {
    $self->{parser_state} = 'title';
  } elsif ($tagname eq "td") {
    my %class2state = (m => 'time', s => 'size', t => 'type');
    my $class = $attr->{class};
    my $state = $class2state{$class};
    $self->{parser_state} = $state if $state;
  } elsif ($tagname eq 'tr') {
    if (defined $self->{current_file}) {
      my $entry = WWW::IndexParser::Entry->new;
      $entry->filename($self->{current_file}->{filename}) if defined $self->{current_file}->{filename};
      $entry->time($self->{current_file}->{time}) if defined $self->{current_file}->{time};
      $entry->type($self->{current_file}->{type}) if defined $self->{current_file}->{type};
      $entry->size($self->{current_file}->{size}) if defined $self->{current_file}->{size};
      $entry->size_units($self->{current_file}->{size_units}) if defined $self->{current_file}->{size_units};
      push @{$self->{files}}, $entry;
      warn "Added " . $self->{current_file}->{filename} if $self->{debug};
      delete $self->{current_file};
    }
    warn "Possible new file row" if $self->{debug};
    $self->{parser_state} = 1;
  } elsif ($tagname eq "a" && defined $self->{parser_state}) {
    warn "  file name = " .  $attr->{href} if $self->{debug};
    $self->{current_file}->{filename} = $attr->{href} if defined $attr->{href};
  } else {
    warn $tagname if $self->{debug};
  }
}



=head1 NAME

WWW::IndexParser - Fetch and parse the directory index from a web server

=head1 SYNOPSIS

 use WWW::IndexParser;
 my @files = WWW::IndexParser->new(url => 'http://www.example.com/dir/');
 foreach my $entry (@files) {
   printf "%s %s\n", $entry->filename, 
        scalar(localtime($entry->time)||'');
 }

=head1 DESCRIPTION


B<WWW::IndexParser> is a module that uses LWP to fetch a URL from a web 
server. It then atempts to parse this page as if it were an auto generated 
index page.  It returns an array of B<WWW::IndexParser::Entry> objects, one 
per entry in the directory index that it has found. Each Entry has a 
set of methods: filename(), time(), size(), and others if supported 
by the autoindex generated: type() and size_units().

=head1 CONSTRUCTOR

=over 4

=item new ( url => $url, timeout => $seconds, proxy => $proxy_url, debug => 1  )

When called with a URL to examine, this method does not return an object, 
but an array of WWW::IndexParser::Entry obects, one per entry in the 
directory listing that was accessed. 

The options to this are:

=over 4

=item url

The complete URL of the index to fetch.

=item timeout

The timeout for the request to fetch data, default 10 seconds.

=item proxy

A proxy server URL, eg, 'http://proxy:3128/'.

=item debug

Decide if to print parsing debug information. Set to 0 (the default) to 
disable, or anything non-false to print. Recommened you use a digit (ie, 1) 
as this may become a numeric 'level' of debug in the future.

=back


=back


=head1 METHODS

All methods are private in this module. Pass only a URL to the constructor, 
and it does everything for you itself.

=head1 PREREQUISUTES 

This modile depends upon C<LWP>, C<HTML::Parser>, C<Time::Local>.


=head1 OSNAMES

any

=head1 BUGS

Currently only supports Apache, IIS and Tomcat style auto indexes. Send suggestions for new Auto-Indexes to support to the author (along with sample HTML)!

=head1 AUTHOR

James Bromberger E<lt>james@rcpt.toE<gt>

=head1 COPYRIGHT

Copyright (c) 2006 James Bromberger. All rights reserved. All rights 
reserved. This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

1;
