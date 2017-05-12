# 

package WWW::Mechanize::Plugin::FollowMetaRedirect;

use strict;
use warnings;
use vars qw($VERSION);
use HTML::TokeParser;

$VERSION = '0.03';

sub init {
    no strict 'refs';    ## no critic
    *{caller() . '::follow_meta_redirect'} = \&follow_meta_redirect;
}

sub follow_meta_redirect {
    my ($mech, %args) = @_;
    my $waiting = ( defined $args{ignore_wait} and $args{ignore_wait} ) ? 0 : 1;

    my $p = HTML::TokeParser->new( \ $mech->content )
	or return;

    while( my $token = $p->get_token ){
	# the line should emerge before </head>
	last if $token->[0] eq 'E' && $token->[1] eq 'head';
	
	my ($url, $sec) = &_extract( $token );
	next if ! defined $url || $url eq '';
	
	if( $waiting and defined $sec ){
	    sleep int $sec;
	}
	
	return $mech->get( $url );
    }

    return;
}

*WWW::Mechanize::follow_meta_redirect = \&follow_meta_redirect;

sub _extract {
    my $token = shift;

    if( $token->[0] eq 'S' and $token->[1] eq 'meta' ){
	if( defined $token->[2] and ref $token->[2] eq 'HASH' ){
	    if( defined $token->[2]->{'http-equiv'} and $token->[2]->{'http-equiv'} =~ /^refresh$/io ){
		if( defined $token->[2]->{'content'} and $token->[2]->{'content'} =~ m|^(([0-9]+)\s*;\s*)*url\='?([^']+)'?$|io ){
		    return ($3, $2);
		}
	    }
	}
    }

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

WWW::Mechanize::Plugin::FollowMetaRedirect - Follows 'meta refresh' link

=head1 SYNOPSIS

  use WWW::Mechanize;
  use WWW::Mechanize::Plugin::FollowMetaRedirect;

  my $mech = WWW::Mechanize->new;
  $mech->get( $url );
  $mech->follow_meta_redirect;

  # we don't want to emulate waiting time
  $mech->follow_meta_redirect( ignore_wait => 1 );

  # compatible for W::M::Pluggable
  use WWW::Mechanize::Pluggable;

  my $mech = WWW::Mechanize::Pluggable->new;
  ...

=head1 DESCRIPTION

WWW::Mechanize doesn't follow so-called 'meta refresh' link.
This module helps you to find the link and follow it easily.

=head1 METHODS

=head2 $mech->follow_meta_redirect

If $mech->content() has a 'meta refresh' element like this,

  <head>
    <meta http-equiv="Refresh" content="5; URL=/docs/hello.html" />
  </head>

the code below will try to find and follow the link described as url=.

  $mech->follow_meta_redirect;

In this case, the above code is entirely equivalent to:

  sleep 5;
  $mech->get("/docs/hello.html");

When a refresh link was found and successfully followed, HTTP::Response object will be returned (see WWW::Mechanize::get() ), 
otherwise nothing returned.

To sleep specified seconds is default if 'waiting second' was set. You can omit the meddling function by passing ignore_wait true.

  $mech->follow_meta_redirect( ignore_wait => 1 );

=head1 BUGS

Despite there was no efficient links on the document after issuing follow_meta_redirect(),
$mech->is_success will still return true because the method did really nothing, and the former page would be loaded correctly (or why you proceed to follow?).

Only the first link will be picked up when HTML document has more than one 'meta refresh' links (but I think it should be so).

=head1 TO DO

A bit more efficient optimization to suppress extra parsing by limiting job range within <head></head> region.

To implement auto follow feature (like $mech->auto_follow_meta_redirect(1) ) using W::M::Pluggable::post_hook() to W::M::get().

=head1 DEPENDENCY

WWW::Mechanize

=head1 SEE ALSO

WWW::Mechanize, WWW::Mechanize::Pluggable

=head1 REPOSITORY

https://github.com/ryochin/p5-www-mechanize-plugin-followmetaredirect

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
