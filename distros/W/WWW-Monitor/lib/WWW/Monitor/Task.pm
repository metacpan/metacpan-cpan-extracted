#WWW/monitor.pm. Written in 2007 by Yaron Kahanoitch.  This
# source code has been placed in the public domain by the author.
# Please be kind and preserve the documentation.


package WWW::Monitor::Task;


#use 5.008;
use warnings;
use strict;
use HTTP::Response;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Status;
use HTML::TreeBuilder;
#use Carp;



our(@ISA, @EXPORT, @EXPORT_OK, $VERSION);

$VERSION = 0.24;

@ISA = qw(
	  Exporter
	 );
@EXPORT = qw ();
@EXPORT_OK = qw ();

our $HASH_SEPARATOR = "\n";
our $HASH_KEY_PREFIX = "__HASH_KEY__";

=head1 NAME

WWW::Monitor::Task - A Task class for monitoring single web page
against a cached version.

=head1 VERSION

Version 0.1

=cut

=head1 Description

This class is responsible for tracking a single web page and reporting
changes.  This class should be considered as a private asset of
L<WWW::Monitor>.  For details please refer to <WWW::Monitor>

=head1 EXPORT

=head1 FUNCTIONS

=head2 new 

A constructor.

=cut

sub new {
  my $this = shift;
  my %arg;
  unless (@_ % 2) {
    %arg = @_;
  } else {
    carp ("Parameters for WWW::Monitor::Task should be given as pair of 'OPTION'=>'VAL'");
  }
  my  $class = ref($this) || $this;
  my  $self = {};
  carp ("Url is not given") unless exists $arg{URL};
  $self->{url} = $arg{URL};
  $self->{cache} = $arg{CACHE};
  bless($self, $class);
}

=head2 run ( mechanize, carrier, <cache>)

Executes Task.  Parameters:

mechanize - Web mechanize object.

L<WWW::Monitor::Task> assumes that the given object implements or
inherits WWW::mechnize abstraction. See
L<http://search.cpan.org/~petdance/WWW-Mechanize-1.20/lib/WWW/Mechanize.pm>.

carrier- Object which will conduct the notification; see L<WWW::Monitor> for details

cache - optional - A cache class.

=cut

sub run {
  my $self = shift;
  $self->{error} = "";
  my ($mechanize,$carrier) = (shift,shift);
  my $cache = "";
  if (@_) { $cache = shift;}
  my $url_i = $self->{url};
  $self->{cache} = $cache if ($cache);
  my $responses = {};

  #Get Url data. Output data is stored in the hash ref $responses.
  $self->get_url_data($mechanize,$url_i,$responses) or return 0;

  #Compares Pages list with cache.
  my ($url_keys_for_comapre,$old_pages_to_compare,$new_pagets_to_compare,$missing_pages,$added_pages,$existsInCache) = $self->sync_cache($url_i,$responses);

  # if a page does not exist in cache we don't want to notify this
  return 1 unless ($existsInCache);

  #Activate Notification.
  $self->be_notified($carrier,$url_i,$missing_pages,$added_pages,$old_pages_to_compare,$new_pagets_to_compare,$url_keys_for_comapre);
  return 1;
}

=head2 be_notified

(Private method)
Tests if a page has changed. If yes, notification call back is being called.

=cut

sub be_notified {
  my $self = shift;
  my $notify_ind = 0;
  my ($carrier,$url,$missing_pages,$added_pages,$old_pages_to_compare,$new_pages_to_compare,$url_keys_for_comapre) = @_;
  my $cache = $self->{cache};
  my $ret = 1;
  #Extract textual information from missing pages.
  $self->{missing_parts} = $missing_pages;
  my $notify_ind1 = values(%$missing_pages);

  #Extract added information from added pages.
  $self->{added_parts} = $added_pages;
  my $notify_ind2 = values(%$added_pages);
 
  my $index = 0;
  #Go over on all pages that exists in cache and perform textual comparison
  $self->{changed} = {};
  if (@$old_pages_to_compare) {
    while ($index < scalar(@$old_pages_to_compare)) {
      my $t1 = $self->format_html($old_pages_to_compare->[$index]);
      my $t2 = $self->format_html($new_pages_to_compare->[$index]);
      
      if ($$t1 ne $$t2) {
	my $tmp = [$old_pages_to_compare->[$index], $new_pages_to_compare->[$index] ];
	$self->{changed}{$url_keys_for_comapre->[$index]} = $tmp;
	$cache->set($url_keys_for_comapre->[$index],$new_pages_to_compare->[$index]->as_string);
	$notify_ind = 1;
      }
      ++$index;
    }
  }


  #If notification is required, perform it.
  if ($notify_ind or $notify_ind1 or $notify_ind2) {
    $self->{time1} = HTTP::Date::time2str($self->validity($url));
    $self->{time2} = HTTP::Date::time2str(time());
    $self->store_validity($url,time());
    return $carrier->notify($url,$self);
  } else { return 1;}
}

=head2 is_html

(Private method)
Return true if page is html

=cut

sub is_html {
  my $self = shift;
  my $response = shift;
  return $response->header('Content-Type') =~ m%^text/html%;
}

=head2 missing_parts

Return hash reference which includes parts that exists only in old cached version. Every entry in the returned list is a reference to HTTP::REsponse object.

=cut

sub missing_parts {
  my $self = shift;
  return $self->{missing_parts};
}

=head2 added_parts

Return hash reference which includes parts that exists only in the new cached version.Every entry in the returned list is a reference to HTTP::REsponse object.

=cut

sub added_parts {
  my $self = shift;
  return $self->{added_parts};
}

=head2 old_version_time_stamp

Return the time when the url was previously cached. Time is returned in seconds since epoch.

=cut

sub old_version_time_stamp {
  my $self = shift;
  return $self->{time1};
}

=head2 new_version_time_stamp

Return the time when the url was queried. Time is returned in seconds since epoch.

=cut

sub new_version_time_stamp {
  my $self = shift;
  return $self->{time2};
}

=head2 changed_parts

Return a list that consists of all changed parts.

=cut

sub changed_parts {
  my $self = shift;
  return keys %{$self->{changed}};
}

=head2 get_old_new_pair [ urls key ]

Return a list of two elements. The first one is the old cached version and the second one is the new version.
The given url key must be one of the keys returned by changed_parts method.
Each of the pair two pairs is a reference to L<HTTP::Response> object.



=cut

sub get_old_new_pair {
  my $self = shift;
  my $url_key = shift;
  if (exists $self->{changed}{$url_key}) {
    return @{$self->{changed}{$url_key}};
  } else {
    return 0;
  }
}

=head2 format_html [ leftmargin, rightmargin]

Return a textual version of HTML
left and right margins set the margin for the returned data.

=cut

sub format_html {
  my $self = shift;
  my $response_ref = shift;
  my $leftmargin = 0;
  my $rightmargin = 120;

  if (@_) {
    $leftmargin = shift;
    $rightmargin = shift;
  }
  
  my $reftype = ref($response_ref);
  if (($reftype ne 'REF') and $self->is_html($response_ref)) {
    my $tree = HTML::TreeBuilder->new->parse($response_ref->content);
    my $formatter = HTML::FormatText->new(leftmargin => $leftmargin, rightmargin => $rightmargin);
    my $ret = $formatter->format($tree);
    return \$ret;
  } elsif ($reftype eq 'REF') { #Backward compatibility case to ver 0.126
    my $tree = HTML::TreeBuilder->new->parse($response_ref);
    my $formatter = HTML::FormatText->new(leftmargin => $leftmargin, rightmargin => $rightmargin);
    my $ret = $formatter->format($tree);
    return \$ret;
  } else { #We have non html data
    my $content = $response_ref->content;
    return \$content;
  }
}

=head2 get_hash_cache_key

(Private method)
Return a hash key that stores information about the entire visible part or the URL.

=cut

sub get_hash_cache_key {
  my $self = shift;
  my $url = shift;
  return $HASH_KEY_PREFIX.$url;
}

=head2 get_cache_hash

(Private Method)
Returns all urls which were last cached.
return true if the url was previously hashed.

=cut

sub get_cache_hash {
  my ($self,$url,$is_cached_site) = @_;
  my $cache = $self->{cache};
  my $ret = {};
  $$is_cached_site = 1;
  my $hash_key = $self->get_hash_cache_key($url);
  $cache->exists($hash_key) or do { $$is_cached_site = 0;return 0;};
  foreach $hash_key (split($HASH_SEPARATOR, $cache->get($hash_key))) {
    my $tmp = $cache->get($hash_key);
    my $tmp2 = HTTP::Response->parse( $tmp );
    if ($tmp2) {
      $ret->{$hash_key} = $tmp2;
    } else { #Backward compatibility to version 0.126
      $ret->{$hash_key} = \$tmp;
    }
  }
  return $ret;
}

=head2 store_validity

(Private method)
Store current time in the main hash key

=cut

sub store_validity {
  my ($self,$url) = (@_);
  my $cache = $self->{cache};
  my $hash_key = $self->get_hash_cache_key($url);
  $cache->set_validity($hash_key,time()) if ($cache->exists($hash_key));
  return 1;
  
}

=head2 validity

(private method)
Retreive date validity of per stores url

=cut

sub validity {
  my ($self,$url) = (@_);
  my $cache = $self->{cache};
  my $hash_key = $self->get_hash_cache_key($url);
  if ($cache->exists($hash_key)) {
    return $cache->validity($hash_key);
  } 
  return 0; 
}

=head2 store_cache_hash

Store General information of a web address, including all frames and dates.

=cut

sub store_cache_hash {
  my ($self,$url,$data,$added_data,$deleted_data) = (@_);
  my $cache = $self->{cache};
  my $hash_key = $self->get_hash_cache_key($url);
  my $header = join($HASH_SEPARATOR,keys %$data);
  $cache->set($hash_key,join($HASH_SEPARATOR,keys %$data));
  while (my ($key,$value) = each %$added_data) {
    $cache->set($key,$value->as_string);
    $cache->set_validity($key,time());
  }
  while (my ($key2,$value2) = each %$deleted_data) {
    $cache->purge($key2,$value2);
  }
  return 1;
}

=head2 sync_cache

(Private method)

=cut


#sync_cache (Privatre method) takes newly retrieved data, and stores and compresses it with
# the cache data. That is, It returns as follows:
# might_be_changed - Urls that are included in the retrieved pages and are in the cache.
# Those pages are potentialy changed, and therefore should be examinated by HTML comparison.
# deleted_data - Pages which exist in the cache and not in the new set.
# added_data - Pages which exist only in the new version.
# In addition, the sub purges all deleted pages from cache and stores the added pages.
# Due to performance reasons, all the "might_be_changed" pages are not cached.
# This is left for the caller to do.
sub sync_cache {
  my ($self,$url,$new_data_http) = @_;
  my $cache = $self->{cache};
  my $is_cached_site;
  my $old_data = $self->get_cache_hash($url,\$is_cached_site);
  my ($added_data,$deleted_data) = ({},{});
  my @old_pages_to_compare;
  my @new_pages_to_compare;
  my @url_keys_for_comapre;
  my $index_new = 0;my $index_old = 0;
  my @new_keys = sort (keys %$new_data_http);
  my @old_keys = ($old_data)?(sort(keys %$old_data)):();
#  print "Scalars: ", scalar(@new_keys), "==",scalar(@old_keys),"\n";
  while ($index_new < scalar(@new_keys) and $index_old < scalar(@old_keys)) {
    if ($new_keys[$index_new] eq $old_keys[$index_old]) { 
      if ($new_data_http->{$new_keys[$index_new]}->code() != RC_NOT_MODIFIED) {
	push @old_pages_to_compare, $old_data->{ $old_keys[$index_old]};
	my $a_response = $new_data_http->{$new_keys[$index_new]};
	push @new_pages_to_compare, $a_response;
	push @url_keys_for_comapre,$new_keys[$index_new];
      }
      ++$index_old;++$index_new;next;
    }
    if ($new_keys[$index_new] lt $old_keys[$index_old]) { 
      my $a_response = $new_data_http->{$new_keys[$index_new]};
      $added_data->{$new_keys[$index_new]} = $a_response;
      ++$index_new;
      next;
    }
    $deleted_data->{$old_keys[$index_old]} = $old_data->{$old_keys[$index_old]};
    ++$index_old;next;
  }
  while ($index_new < scalar(@new_keys)) {
    my $a_response = $new_data_http->{$new_keys[$index_new]};
    $added_data->{$new_keys[$index_new]} = $a_response;
    ++$index_new;
  }
  while ($index_old < scalar(@old_keys)) {
    $deleted_data->{$old_keys[$index_old]} = $old_data->{$old_keys[$index_old]};
    ++$index_old;
  }
#  print "Goota cache\n";
  $self->store_cache_hash($url,$new_data_http,$added_data,$deleted_data) or die ("Cannot store $url in cache");
  return (\@url_keys_for_comapre,\@old_pages_to_compare,\@new_pages_to_compare,$deleted_data,$added_data,$is_cached_site);
}

=head2 get_url_data

(Private method)

=cut

# get_url_data recurses over all pages which construct a given web page--including all type
# of included frames and dynamic pages--and retrieves them into a given hash reference
# $response.
sub get_url_data {
  my $self = shift;
  my $mechanize = shift;
  my $url = shift;
  my $responses = shift;
  my $cache = $self->{cache};
  my $r = HTTP::Request->new('GET',$url);
  # Only allow "identity" for the time being
  $r->header( 'Accept-Encoding', 'identity' );
  if ($cache->exists($url)) {
    my $validity = $cache->validity($url);
    $r->header('If-Modified-Since'=>HTTP::Date::time2str($cache->validity($url))) if ($validity);
  }
  my $response = $mechanize->request( $r );
  
  if ($response->code() == 304) {
    $response = HTTP::Response->parse($cache->get($url));
    $mechanize->_update_page($r,$response);
  } elsif(!($self->{status} = $response->is_success())) {
    $self->{error} = $response->status_line;
    return 0;
  }
  $responses->{$url} = $response;
  my $frames = [];
  my $output = $mechanize->find_all_links( tag_regex => qr/^([ia]?frame)$/i);
  push @$frames,@$output if ($output);
  $output = $mechanize->find_all_links( tag_regex => qr/meta/);
  push @$frames,@$output if ($output);

  foreach my $link (@$frames) {
    next unless ($link->url_abs =~ m%^http.*//%);
    unless (exists $responses->{$link->url_abs()}) {
      $self->get_url_data($mechanize,$link->url_abs(),$responses) or return 0;
    }
  }
  return 1;
}

=head2 success 

return true upon success of the last run execution.

=cut

sub success {
  my $self = shift;
  return $self->{status};
}


=head1 AUTHOR

Yaron Kahanovitch, C<< <yaron-helpme at kahanovitch.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-monitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Monitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command. perldoc WWW::Monitor
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Monitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Monitor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Monitor>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Monitor>

=back

=head1 ACKNOWLEDGMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Yaron Kahanovitch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

1;				# End of WWW::Monitor::Task
