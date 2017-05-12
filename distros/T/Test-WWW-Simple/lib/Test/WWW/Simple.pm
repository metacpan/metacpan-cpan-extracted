package Test::WWW::Simple;

use strict;
use warnings;

our $VERSION = '0.34';

use Test::Builder;
use Test::LongString;
use Test::More;
use WWW::Mechanize::Pluggable;

my $Test = Test::Builder->new;  # The Test:: singleton
my $Mech = WWW::Mechanize::Pluggable->new(autocheck => 0); 
                                # The Mech user agent and support methods
my $cache_results = 0;          # default to not caching Mech fetches
our $last_url;                  # last URL fetched successfully by Mech
my %page_cache;                 # saves pages for %%cache; we probably 
                                # will want to change this over to a
                                # tied hash later to allow for disk caching
                                # instead of just memory caching.
my %status_cache;               # ditto

$Test::WWW::display_length = 40; # length for display in error messages

sub import {
    my ($class, %args) = @_;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::page_like_full'}   = \&page_like_full;
    *{$caller.'::page_unlike_full'} = \&page_unlike_full;
    *{$caller.'::text_like'}        = \&text_like;
    *{$caller.'::text_unlike'}      = \&text_unlike;
    *{$caller.'::page_like'}        = \&page_like;
    *{$caller.'::page_unlike'}      = \&page_unlike;
    *{$caller.'::user_agent'}       = \&user_agent;
    *{$caller.'::cache'}            = \&cache;
    *{$caller.'::no_cache'}         = \&no_cache;
    *{$caller.'::mech'}             = \&mech;
    *{$caller.'::last_test'}        = \&last_test;

    $Test->exported_to($caller);

    # Check the 'use' arguments to see if we have either
    # 'agent', 'agent_string', or 'no_agent'.  
    #
    # If we have none of these, assume 'Windows IE 6'.
    if (defined $args{agent}) {
      # This is a string suitable for passing to agent_alias.
      my $alias = $args{agent};
      if (grep { /^$alias\z/ } $Mech->known_agent_aliases()) {
         $Mech->agent_alias($alias);
      }
      else {
        die "'$alias' is not a valid WWW::Mechanize user agent alias\n";
      }
    }
    elsif (defined $args{agent_string}) {
      $Mech->agent('agent_string');
    }
    elsif(!defined $args{no_agent}) {
      $Mech->agent_alias('Windows IE 6');
    }
    else {
      # No action; no_agent was defined,
      # so leave the user agent as "WWW::Mechanize/version".
    }

    if (defined $args{tests}) {
      plan tests => $args{tests};
    }
}

sub _clean_text {
  my $page = $Mech->content(format=>'text');
  $page =~ s/\xa0/ /g;
  return $page;
}

sub text_like($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? like_string(_clean_text(), $regex, $comment)
      : fail "Fetch of $url failed: ".$status_line;
}

sub text_unlike($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? unlike_string(_clean_text(), $regex, $comment) 
      : fail "Fetch of $url failed: ".$status_line;
}

sub page_like($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? like_string($content, $regex, $comment)
      : fail "Fetch of $url failed: ".$status_line;
}

sub page_unlike($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? unlike_string($content, $regex, $comment) 
      : fail "Fetch of $url failed: ".$status_line;
}

sub page_like_full($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? like($content, $regex, $comment)
      : fail "Fetch of $url failed: ".$status_line;
}

sub page_unlike_full($$;$) {
    my($url, $regex, $comment) = @_;
    my ($state, $content, $status_line) = _fetch($url);
    $state 
      ? unlike($content, $regex, $comment) 
      : fail "Fetch of $url failed: ".$status_line;
}

sub _fetch {
  my ($url, $comment) = @_;
  local $Test::Builder::Level = 2;
  my @results;

  if ($cache_results) {
    if (defined $page_cache{$url}) {
      # in cache: return it.
      @results = (1, $page_cache{$url}, $status_cache{$url});
    }
    elsif ($last_url eq $url) {
      # "cached" in Mech object
      @results = (1, 
              $page_cache{$url}   = $Mech->content,
              $status_cache{$url} = $Mech->response->status_line);
    }
    else {
      # not in cache - load and save the page (if any)
      $Mech->get($url);
      @results = ($Mech->success, 
              $page_cache{$url}   = $Mech->content,
              $status_cache{$url} = $Mech->response->status_line);
    }
  }
  else {
   # not caching. Just grab it.
   $Mech->get($url);
   @results = ($Mech->success, $Mech->content, $Mech->response->status_line);
  }
  $last_url = $_[0];
  $page_cache{$url}   = $results[1];
  $status_cache{$url} = $results[2];
  @results;
}

sub _trimmed_url {
    my $url = shift;
    length($url) > $Test::WWW::display_length 
       ? substr($url,0,$Test::WWW::display_length) . "..."
       : $url;
}

sub user_agent {
   my $agent = shift || "Windows IE 6";
   $Mech->agent_alias($agent);
}    

sub mech {
  my ($self) = @_;
  return $Mech;
}

sub last_test {
  my($self) = @_;
  return ($Test->details)[-1];
}

sub cache (;$) { 
  my $comment = shift;
  $Test->diag($comment) if defined $comment;
  $last_url = "";
  $cache_results = 1;
  1;
}

sub no_cache (;$) { 
  my $comment = shift;
  $Test->diag($comment) if defined $comment;
  $last_url = "";
  $cache_results = 0;
  1;
}


1;

__END__

=head1 NAME

Test::WWW::Simple - Test Web applications using TAP

=head1 SYNOPSIS

  use Test::WWW::Simple;
  # This is the default user agent.
  user_agent('Windows IE 6');
  page_like("http://yahoo.com",      qr/.../, "check for expected text");
  page_unlike("http://my.yahoo.com", qr/.../, "check for undesirable text");
  user_agent('Mac Safari');
  ...

=head1 DESCRIPTION

C<Test::WWW::Simple> is a very basic class for testing Web applications and 
Web pages. It uses L<WWW::Mechanize> to fetch pages, and L<Test::Builder> to 
implement TAP (Test Anything Protocol) for the actual testing.

Since we use L<Test::Builder> for the C<page_like> and C<page_unlike> routines, these
can be integrated with the other standard L<Test::Builder>-based modules
as just more tests.

=head1 MOTIVATION

This class provides a really, really simple way to do very basic page validation.
If you can pattern match it, you can check it. It is therefore not suitable for
complex page checking (are all my links good? is this page valid XHTML? etc.),
but work great for those little things (is my copyright notification on the page?
did I get all of the "font" tagging off this page? etc.).

The function is deliberately limited to make it easier to remember what you 
can do.

=head1 SUBROUTINES

=head2 page_like

Does a pattern match vs. the page at the specified URL and succeeds if
the pattern matches.  Uses C<Test::LongString> for the comparison to get 
short diagnostics in case of a match failure.

=head2 page_unlike

Does a pattern match vs. the page at the specified URL and succeeds if
the pattern does I<not> match. Uses C<Test::LongString> for the 
comparison to get short diagnostics in case of a match failure.

=head2 text_like

Does a pattern match vs. the I<visible text> on the page and succeeds if
the pattern matches.  Uses C<Test::LongString> for the comparison to get 
short diagnostics in case of a match failure.

=head2 text_unlike

Does a pattern match vs. the I<visible text> at the specified URL and succeeds if
the pattern does I<not> match. Uses C<Test::LongString> for the comparison to get 
short diagnostics in case of a match failure.

=head2 page_like_full

Does a pattern match vs. the page at the specified URL and succeeds if
the pattern matches. Uses C<Test::More> to get a complete dump of the page
if the comparison fails.

=head2 page_unlike_full

Does a pattern match vs. the page at the specified URL and succeeds if
the pattern does I<not> match. Uses C<Test::More> to get a complete dump 
of the page if the comparison fails.

=head2 cache

Turns cacheing of URLS on. Subsequent requests for the same URL will 
return the page initially fetched. Can greatly speed up execution in
cases where the pages are essentially identical (or differ in ways that
you don't care to test) on every access.

=head2 no_cache

Turns the page cache off. Every request will refetch the page at the
specified URL. Slows down execution, but guarantees that you are seeing
any transient changes on the pages that are detectable via a refetch.

=head2 user_agent

Lets you set the current user agent using the C<WWW::Mechanize>
user-agent abbreviations. See C<WWW::Mechanize> for a list.

=head2 mech

Returns the underlying C<WWW::Mechanize::Pluggable> object to
allow you to access its other functions. This is here to allow 
later versions of C<simple_scan> to be able to access them as well.

=head2 last_test

Returns the details of the last test run. Useful if you want to 
selectively execute some more code after a test has run (e.g.,
print the content if a test has failed).

The details are reference to a hash, containing:

=over 4 

=item * ok - true if test is considered a pass

=item * actual_ok  - true if it literally said 'ok'

=item * name - name of the test (if any)

=item * type - type of test (if any)

=item * reason - reason for the above (if any)

=back


=head1 SEE ALSO

L<WWW::Mechanize> for a description of how the simulated browser works; 
L<Test::Builder> to see how a test module works.

You may also want to look at L<Test::WWW::Mechanize> if you want to write 
more precise tests ("is the title of this page like the pattern?" or
"are all the page links ok?").

The C<simple_scan> utility provided with this module demonstrates a
possible use of C<Test::WWW::Simple>; do a C<perldoc simple_scan> for
details on this program.

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@yahoo-inc.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Yahoo!

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
