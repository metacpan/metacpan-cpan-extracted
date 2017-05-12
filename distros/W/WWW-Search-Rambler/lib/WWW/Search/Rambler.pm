# Rambler.pm
#
# Copyright (C) 2004 by Artur Penttinen
# $Id: Rambler.pm,v 1.2 2010/08/23 12:29:15 artur Exp artur $
#
# Complete copyright notice follows below.

package WWW::Search::Rambler;

use strict;

use base "WWW::Search";

use WWW::SearchResult;
use Encode qw( from_to );
use Encode::Byte;
use URI;
use URI::Escape;
use HTML::TreeBuilder;
use HTTP::Cookies;

our $VERSION = qw$Revision: 1.2 $[1];
our $MAINTAINER = 'Artur Penttinen <artur+perl@niif.spb.su>';

our $iMustPause = 1;

sub native_setup_search ($$$) {
    my ( $self,$query,$opt ) = @_;

    printf STDERR " + native_setup_search('%s','%s')\n",$query,$opt || ""
      if ($self->{'_debug'});

    unless ($self->{'charset'} =~ m#utf-?8#i) {
	from_to ($query,$self->{'charset'},"utf8");
    }

    $self->{'native_query'} = uri_escape ($query);
    $self->{'_next_to_retrieve'} = 0;

    $self->{'agent_name'} = "Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)";
    $self->{'agent_e_mail'} = "nobody\@niif.spb.su";

    $self->{'search_base_url'} ||= "http://nova.rambler.ru";
    $self->{'search_base_path'} = "/search";

    $self->cookie_jar (new HTTP::Cookies);

    unless (defined ($self->{'_options'})) {
	# We do not clobber the existing _options hash, if there is one;
	# e.g. if gui_search () was already called on this object
	$self->{'_options'} = { 'words' => $self->{'native_query'},
				'where' => "1",
				'noglue' => "1",
				# 'n' => $self->{_hits_per_page},
				# 'b' => $self->{_next_to_retrieve}-1
			      };
    }

    my $opts = $self->{'_options'};

    foreach my $key (keys %$opt) {

	if (WWW::Search::generic_option ($key)) {
	    $self->{$key} = $opts->{$key} if (exists ($opts->{$key}));
	    delete $opts->{$key};
	}
	else {
	    $opts->{$key} = $opt->{$key} if (exists ($opt->{$key}));
	}

    }

    $self->{'_next_url'} = $self->{'search_base_url'} .
      $self->{'search_base_path'} .'?'.
	$self->hash_to_cgi_string ($opts);

    return;
}

sub parse_tree ($$) {
    my ( $self,$oTree ) = @_;

    print STDERR " + ::Rambler got a tree $oTree\n"
      if ($self->{'_debug'} >= 2);

    # Every time we get a page from rambler.ru, we have to pause before
    # fetching another.
    $iMustPause++;

    my $hits_found = 0;

    # Only try to parse the hit count if we haven't done so already:
    printf STDERR " + start, approx_h_c is ==%d==\n",
      $self->approximate_hit_count() if ($self->{'_debug'} >= 2);

    if ($self->approximate_hit_count () < 1) {
      return $hits_found;
    } # if

    my @aoDIV = $oTree->look_down ('_tag' => "div",
				  sub { $_[0]->attr ('class') &&
					$_[0]->attr ('class') =~ m#^search-results# }) or return 0;

    my @aoLI = $aoDIV[0]->look_down ('_tag' => "li");

  LI_TAG:
    foreach my $oLI (@aoLI) {
	# Sanity check:
	next LI_TAG unless (ref ($oLI));

	my @aoA = $oLI->look_down ('_tag' => "a");
	my $oA = shift @aoA;
	next LI_TAG unless (ref $oA);

	my $sTitle = $oA->as_text || "";
	my $sURL = $oA->attr ("href") || "";
	my $sNOTE = $oLI->look_down ('_tag' => "div",
				     sub { $_[0]->attr ("class") eq "note" });

	next LI_TAG unless ($sURL ne "");

	print STDERR " +   raw     URL is ==$sURL==\n"
	  if ($self->{'_debug'} >= 2);

	my $hit = new WWW::SearchResult;
	$hit->add_url ($sURL);
	$sTitle = $self->strip ($sTitle);
	$sNOTE = $self->strip ($sNOTE->as_HTML);
	$hit->title ($sTitle);
	$hit->description ($sNOTE);

	push @{ $self->{'cache'} },$hit;
	$hits_found++;
    } # foreach LI_TAG

    # Now try to find the "next page" link:
    my @aoA = $oTree->look_down ('_tag' => "a",
				 sub { ( $_[0]->attr ("class") || "" ) =~ m#^n_pager_$iMustPause$# });	#

  NEXT_A:
    foreach my $oA (@aoA) {
	next NEXT_A unless (ref $oA);
	my $sAhtml = $oA->as_HTML ();

	printf STDERR " +   next A ==%s==\n", $sAhtml
	  if ($self->{'_debug'} >= 2);

	if ($self->_a_is_next_link ($oA)) {
	    my $sURL = $oA->attr ("href");
	    $self->{'_next_url'} = $self->absurl ($self->{'_prev_url'},$sURL);
	    last NEXT_A;
	} # if
    } # foreach NEXT_A

    return $hits_found;
}

sub native_retrieve_some ($) {
    my ( $self ) = @_;

    printf STDERR " +   %s::native_retrieve_some ()\n",__PACKAGE__
      if ($self->{'_debug'});

    # Fast exit if already done:
    return unless (defined ($self->{'_next_url'}));

    # If this is not the first page of results, sleep so as to not
    # overload the server:
    $self->user_agent_delay () if ($self->{'_next_to_retrieve'} > 1 ||
				   $self->need_to_delay ());

    # Get one page of results:
    printf STDERR " +   submitting URL (%s)\n",$self->{'_next_url'}
      if ($self->{'_debug'});

    my $response = $self->http_request ($self->http_method (),
					$self->{'_next_url'});

    printf STDERR " +     got response\n%s\n", $response
      if ($self->{'_debug'} >= 2);

    $self->{'_prev_url'} = $self->{'_next_url'};

    # Assume there are no more results, unless we find out otherwise
    # when we parse the html:
    $self->{'_next_url'} = undef;
    $self->{'response'} = $response;

    printf STDERR " --- HTTP response is:%s\n", $response->as_string ()
      if ($self->{'_debug'} >= 5);

    unless ($response->is_success ()) {
	printf STDERR " --- HTTP request failed, response is:\n%s",
	  $response->as_string if ($self->{'_debug'});
	return undef;
    } # if

    # Pre-process the output:
    my $sPage = $self->preprocess_results_page ($response->content ());

    # Parse the output:
    my $tree;
    if (ref ($self->{'_treebuilder'})) {
	print STDERR " +   using existing _treebuilder\n"
	  if ($self->{_debug} >= 2);
	# Assume that the backend has installed their own TreeBuilder
	$tree = $self->{'_treebuilder'};
    }
    else {
	print STDERR " +   creating new _treebuilder\n" if ($self->{_debug});
	$tree = new HTML::TreeBuilder ();	# use all default options
	$tree->store_comments ('yes');
	$self->{'_treebuilder'} = $tree;
    }

    # If a reset() method becomes available in HTML::TreeBuilder,
    # we can change this:
    $tree->www_search_reset ();
    # print STDERR " +   parsing content, tree is ", Dumper(\$tree)
    #   if ($self->{'_debug'} >= 2);

    $tree->parse ($sPage);
    print STDERR " +   done parsing content.\n" if ($self->{'_debug'} >= 2);
    $tree->eof ();

    print STDERR " +   calling parse_tree...\n" if ($self->{'_debug'} >= 2);
    return $self->parse_tree ($tree);
}

sub http_request ($$$) {
    my ( $self,$method,$url ) = @_;
    my $response;

    if ($self->{'_debug'} >= 50) {
	eval q{ use LWP::Debug qw(+) };
    }

    if (defined $self->{'search_from_file'}) {
	$response = $self->_http_request_from_file ($url);
    }
    else {
	# fetch it
	my $ua = $self->user_agent ($self->{'agent_name'});

	unless (exists ($self->{'_prev_url'})) {
	    # Get cookie from first page
	    my $request = new HTTP::Request ($method,"http://www.rambler.ru");
	    $self->{'_cookie_jar'}->add_cookie_header ($request);
	    my $resp = $ua->request($request);
	    $self->{'_http_referer'} = "http://www.rambler.ru";
	    my $cookie = $resp->header ("Set-Cookie");
	    if (defined ($cookie) && $cookie =~ m#ruid=(\S+);#) {
		$self->{'_cookie_ruid'} = $1;
	    }

	    printf STDERR "+  got cookie: %s\n",$self->{'_cookie_ruid'} || "(none)"
		if ($self->{'_debug'});

	    sleep 2;	# we will enter request :)
	}

	my $request = new HTTP::Request ($method,$url);
	$request->header ("Content-Type","text/html; charset=utf8");
	$request->header ("Cookie",sprintf "ruid=%s",$self->{'_cookie_ruid'})
	  if (exists $self->{'_cookie_ruid'});

	$request->proxy_authorization_basic ($self->http_proxy_user,
					     $self->http_proxy_pwd)
	  if ($self->is_http_proxy_auth_data ());

	$self->{'_cookie_jar'}->add_cookie_header ($request)
	  if (exists ($self->{'_cookie_jar'}));

	if ($self->{'_http_referer'} && $self->{'_http_referer'} ne "") {
	    # my $s = uri_escape ($self->{'_http_referer'});
	    my $s = $self->{'_http_referer'};
	    printf STDERR " +    referer(%s), ref(s) = %s\n",$s,ref($s)
	      if ($self->{'_debug'});
	    $s = $s->as_string () if (ref ($s) =~ m#URI#);
	    $request->referer ($s);
	} # if referer

	printf STDERR " +   original HTTP::Request is:\n%s\n",
	  $request->as_string () if ($self->{'_debug'} >= 3);

      TRY_GET:
	while (1) {
	    $response = $ua->request ($request);

	    printf STDERR " +   got HTTP::Response (code=%d):\n%s",
	      $response->code (),$response->headers ()->as_string ()
		if ($self->{'_debug'} >= 3);

	    if (exists ($self->{'_cookie_jar'})) {
		$self->{'_cookie_jar'}->extract_cookies ($response);
		$self->{'_cookie_jar'}->save ()
		  if ($self->{'_cookie_jar_we_save'});
		print STDERR " + WWW::Search just extracted cookies\n"
		    if ($self->{'_debug'} > 2);
		print STDERR $self->{'_cookie_jar'}->as_string ()
		    if ($self->{'_debug'} > 2);
		# print STDERR Dumper($self->{'_cookie_jar'}) if DEBUG_COOKIES;
	    } # if

	    if ($self->{'search_to_file'} && $response->is_success ()) {
		$self->_http_request_to_file ($url,$response);
	    } # if

	    last TRY_GET if ($response->is_success ());
	    last TRY_GET if ($response->is_error ());
	    last TRY_GET if ($response->headers ()->header ("Client-Warning") =~ m#redirect loop detected#i);

	    if ($response->is_redirect () ||
		$response->message =~ m#Object moved#i) {

		my $sURL = $response->request->uri->as_string;
		my $sURLredir = $response->headers->header ("Location");

		# Low-level loop detection:
		last TRY_GET if ($sURLredir eq $sURL);
		print STDERR " +   'Object moved' from $sURL to $sURLredir\n"
		  if ($self->{'_debug'} >= 2);
		# Follow the redirect:
		$request = new HTTP::Request("GET",
					     URI->new_abs($sURLredir, $sURL));
		$request->referer ($sURL);
		$self->{'_cookie_jar'}->add_cookie_header ($request)
		  if (ref($self->{'_cookie_jar'}));

		print STDERR " +   'Object moved', new HTTP::Request is:\n",
		  $request->as_string () if ($self->{'_debug'} >= 3);
		# Go back and try again
	    } # if
	} # while infinite
    } # if not from_file

    return $response;
} # http_request


sub strip ($$) {
    my ( $self,$s ) = @_;
    $s = WWW::Search::strip_tags ($s);
    $s =~ s#\A[\240\t\r\n ]+  ##x;
    $s =~ s#  [\240\t\r\n ]+\Z##x;
    return $s;
}

sub _a_is_next_link ($;$) {
    my ( $self,$oA ) = @_;
    return 0 unless (defined $oA);
    return $oA->attr ("class") =~ m#^n_pager_\d+#;
}

sub preprocess_results_page ($$) {
    my ( $self,$text ) = @_;

    unless ($self->{'charset'} =~ m#utf-?8#) {
	from_to ($text,"utf8",$self->{'charset'});
    }

    return $text;
}

sub approximate_result_count ($) {
    my ( $self ) = @_;

    if ($self->response->content =~ m#<div class="info">.+?(\d+).+?</div>#sm) {
	return $1;
    }
    else {
	return 0;
    }
}

1;

__END__

=head1 NAME

WWW::Search::Rambler - class for searching F<http://www.rambler.ru>.

=head1 SYNOPSIS

  use WWW::Search;
  my $search = new WWW::Search ("Rambler");
  $search->native_query ("Test page");
  while (my $r = $search->next_result ()) {
      printf "%s <URL:%s>\n\t%s\n",$r->title,$r->url,$r->description;
  }

=head1 DESCRIPTION

This class is an Rambler specialization of WWW::Search.
It handles making and interpreting Rambler searches
F<http://www.rambler.ru>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

As example for building my module I using C<WWW::Search::AltaVista>
and C<WWW::Search::Yahoo>.

=head1 SEE ALSO

C<WWW::Search>.

=head1 AUTHOR

Artur Penttinen, E<lt>artur+perl@niif.spb.suE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Artur Penttinen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.x or,
at your option, any later version of Perl 5 you may have available.

=cut

# That's all, folks!
