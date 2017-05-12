# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: OO.pm 110 2005-02-05 10:48:57Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO.pm $
package WWW::Mixi::OO;
use strict;
use warnings;
use WWW::Mixi::OO::Session;
use constant session_class => 'WWW::Mixi::OO::Session';
our $VERSION = 0.03;

=head1 NAME

WWW::Mixi::OO - LWP::UserAgent based Mixi Access Helper Module
(WWW::Mixi compatible class)

=head1 SYNOPSIS

  use WWW::Mixi::OO;
  my $mixi = WWW::Mixi::OO->new('foo@example.com', 'password');
  $mixi->login;
  my $res = $mixi->page('home');
  print $res->content;
  my @friends = $mixi->page('list_friend')->fetch;

=head1 DESCRIPTION

mixi (L<http://mixi.jp/>) is a social network service in Japan.

This module provides L<WWW::Mixi> compatible interface.
use L<WWW::Mixi::OO::Session> for real L<WWW::Mixi::OO>'s interface.

=head1 METHODS

=over 4

=cut

# WWW::Mixi's methods
# parse_*, get_*
#     => WWW::Mixi::OO::*, isa WWW::Mixi::OO::Page
# rewrite(callback_rewrite), escape, unescape, remove_tag,
# convert_login_time, absolute_url
#     => WWW::Mixi::OO::Util
# save_cookies, load_cookies, login, is_logined, is_login_required, session,
# new, absolute_linked_url, post, get, set_content
#     => WWW::Mixi::OO::Session
# refresh => not found!


=item new

  my $mixi = WWW::Mixi::OO->new(
                 $email, $password,
                 [-rewrite => \&rewriter]);

WWW::Mixi::OO constructor.

=cut

sub new {
    my ($class, $email, $password, %opt) = @_;

    # necessary parameters
    Carp::croak('WWW::Mixi mail address required') unless $email;
    Carp::croak('WWW::Mixi password required') unless $password;
    $opt{rewriter} = delete $opt{-rewrite} if exists $opt{-rewrite};

    my $session = $class->session_class->new(
	email => $email,
	password => $password,
	encoding => 'euc-jp',
	%opt);

    my $this = {
	session => $session,
    };

    bless $this, $class;
    return $this;
}

sub AUTOLOAD {
    my $this = shift;
    my $session = $this->{session};
    our $AUTOLOAD;
    $_ = $AUTOLOAD;

    # convert name
    s/url/uri/g;

    if (/^(parse|get)_(calendar)(_[^_]+)?$/ or # calendar & calendar_next
	    /^(parse|get)_([^_]+_[^_]+)(_[^_]+)?$/) { # foo_bar & ...
	# parse or get
	my ($main_method, $pagename, $sub_method) = ($1, $2, $3);
	$sub_method = '' unless defined $sub_method;

	if (@_ > 0) {
	    if ($main_method eq 'get') {
		my $url = shift;
		if ($url eq 'refresh') {
		    $session->refresh_content;
		} else {
		    $session->set_content($url);
		}
		$main_method = 'parse';
	    } else {
		# has response
		die 'not implemented yet!';
	    }
	}
	if ($sub_method =~ /^(next|previous)$/) {
	    # to navi_{next,prev}
	    $sub_method = 'navi_' . substr($sub_method, 0, 4);
	}
	my $page = $session->page($pagename);
	my $method = "$main_method$sub_method";
	$page->$method(@_);
    } elsif (/^session$/) {
	$session->session_id(@_);
    } else {
	# last resort: send to session
	$session->$_(@_);
    }
}

1;
__END__
=back

=head1 BUGS

This module did not complete yet.

=head1 SEE ALSO

L<WWW::Mixi::OO::Session>

L<WWW::Mixi> (L<http://digit.que.ne.jp/work/index.cgi?Perl%a5%e2%a5%b8%a5%e5%a1%bc%a5%eb%2fWWW%3a%3aMixi> in Japanese)

L<http://mixi.jp/>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
