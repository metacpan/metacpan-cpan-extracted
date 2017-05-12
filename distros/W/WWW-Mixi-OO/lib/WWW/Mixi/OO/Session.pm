# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: Session.pm 103 2005-02-05 06:07:57Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/Session.pm $
package WWW::Mixi::OO::Session;
use strict;
use warnings;
use Carp;
use URI;
use URI::QueryParam;
use File::Basename;
use HTTP::Cookies;
use HTTP::Request::Common;
#use base qw(LWP::RobotUA);
use base qw(LWP::UserAgent);
use base qw(WWW::Mixi::OO::Util);

use WWW::Mixi::OO;
use constant base_class => 'WWW::Mixi::OO';
use constant base_uri => 'http://mixi.jp/';

use WWW::Mixi::OO::I18N;
use constant i18n_base_class => 'WWW::Mixi::OO::I18N';
use constant web_charset => 'euc-jp';

=head1 NAME

WWW::Mixi::OO::Session - WWW::Mixi::OO's session class

=head1 SYNOPSIS

  use WWW::Mixi::OO::Session;
  my $mixi = WWW::Mixi::OO::Session->new(
      email => 'foo@example.com',
      password => 'password');
  $mixi->login;
  my @friends = $mixi->page('list_friend')->fetch;
  # ...

=head1 DESCRIPTION

WWW::Mixi::OO::Session is WWW::Mixi::OO session class.


=head1 METHODS

=over 4

=cut

=item new

  my $mixi = WWW::Mixi::OO::Session->new(
      email => $email,
      password => $password,
      encoding => $encoding,
      [rewriter => sub { WWW::Mixi::OO::Util->rewrite(shift); }],
     );

WWW::Mixi::OO constructor.

=over 4

=item email

mixi email address.

=item password

mixi password.

=item encoding

internal encoding (necessary!)

=item rewriter

coderef to rewriter, into text

=back

=cut

sub new {
    my ($class, %opt) = @_;

    my $base_class = $class->base_class;
    (my $name = lc("lib$base_class-perl")) =~ s/::/-/g;
    $name .= '/' . $base_class->VERSION;
    my $this = $class->SUPER::new(
	agent => $name,
	from => 'www-mixi-oo@example.com');
    $this->delay(1/60) if $this->can('delay');
    $this->cookie_jar({});

    # set private variables
    $this->{mixi} = {
	response => undef,
	content => undef,
	cache => undef,
	rewriter => \&_rewriter_default,
	timeout => 1,
    };

    foreach (qw(email password rewriter encoding)) {
	$this->$_($opt{$_}) if exists $opt{$_};
    }

    # set default
    foreach (qw(UTF-8 EUC-JP)) {
	last if defined $this->encoding;
	$this->encoding($_) if $this->i18n_base_class->is_supported($_);
    }

    return $this;
}

=item email

  $mixi->email('foo@example.com');
  my $email = $mixi->email;

set/get mixi email address

=cut

sub email {
    my $this = shift;

    if (@_ > 0) {
	my $value = shift;
	$this->{mixi}->{email} = $value;
	$this->from($value);
    }
    $this->{mixi}->{email};
}

=item password

  $mixi->password('foobar');
  my $email = $mixi->password;

set/get mixi password

=cut

sub password {
    my $this = shift;

    if (@_ > 0) {
	my $value = shift;
	$this->{mixi}->{password} = $value;
    }
    $this->{mixi}->{password};
}

=item rewriter

  $mixi->rewriter->('<foo>bar</foo>');

get/set rewriter (into text).

=cut

sub rewriter {
    my $this = shift;

    if (@_ > 0) {
	my $value = shift;
	if (defined $value and (ref($value) eq 'CODE')) {
	    $this->{mixi}->{rewriter} = $value;
	} else {
	    croak 'please specify valid coderef';
	}
    }
    $this->{mixi}->{rewriter};
}

=item encoding

  $mixi->encoding('euc-jp');

get/set internal encoding.

see also L<WWW::Mixi::OO::I18N>.

=cut

sub encoding {
    my $this = shift;

    if (@_ > 0) {
	my $value = shift;
	if ($this->i18n_base_class->is_supported($value)) {
	    $this->{mixi}->{i18n_class} =
		$this->i18n_base_class->get_processor($value);
	} else {
	    croak "not suported internal encoding: $value";
	}
	# remove cache
	if (defined $this->response) {
	    $this->response($this->response);
	}
    }
    $this->{mixi}->{i18n_class};
}

sub _rewriter_default {
    __PACKAGE__->rewrite(shift);
}

=item response

  my $res = $mixi->response;

get last response

=cut

sub response {
    my $this = shift;

    if (@_ > 0) {
	my $value = shift;
	$this->{mixi}->{response} = $value;
	$this->{mixi}->{content} = $this->convert_from_http_content(
	    $this->web_charset, $value->content);
	$this->{mixi}->{cache} = {}; # clear
    }
    $this->{mixi}->{response};
}

=item content

  my $data = $mixi->content;

get last content

=cut

sub content {
    my $this = shift;

    if (defined $this->{mixi}->{content}) {
	$this->{mixi}->{content};
    } else {
	undef;
    }
}

=item cache

  # call
  my $cache = $mixi->cache(ref($this));
  # or in Page subclass
  my $cache = $page->cache;

get/set cache

=cut

sub cache {
    my ($this, $page) = @_;

    if (defined $this->{mixi}->{cache}) {
	$this->{mixi}->{cache}->{$page} ||= {};
    } else {
	undef;
    }
}

=item login

  $mixi->login

login to mixi.

=cut

sub login {
    my $this = shift;

    croak 'please set email' unless defined $this->email;
    croak 'please set password' unless defined $this->password;

    my $page = $this->page('login');
    $page->do_login;
    return wantarray ? ($this->session_id, $this->response) : $this->session_id;
}

=item page

  $mixi->page($pagename);

get page(mixi's class)

=cut

sub page {
    my ($this, $page) = @_;

    my $pkg = $this->page_to_class($page);
    eval "require $pkg";
    if ($@) {
	die "$pkg not found or couldn't load: $@";
    } else {
	$pkg->new($this);
    }
}

=item page_to_class

  $mixi->page_to_class($pagename);

get classname from pagename

=cut

sub page_to_class {
    my ($this, $page) = @_;

    $page =~ s/(?:^|_)(.)/uc($1)/eg; # titleize
    return $this->base_class . '::' . $page;
}

=item class_to_page

  $mixi->class_to_page($classname);

get pagename from classname

=cut

sub class_to_page {
    my ($this, $class) = @_;

    my $base_class = $this->base_class . '::';
    $class =~ s/^\Q$base_class\E//;
    $class =~ s/([[:upper:]])/lc("_$1")/eg; # titleize
    $class =~ s/^_//; # and remove precedence underbar
    return $class;
}

=item save_cookies

  $mixi->save_cookies($file);

save cookies to file

=cut

sub save_cookies {
    my $this = shift;

    croak 'please specify cookie filename to save' if @_ < 1;
    my $file = shift;

    if (!defined $this->cookie_jar) {
	# cookie disabled
	return undef;
    }

    return $this->cookie_jar->save($file);
}

=item load_cookies

  $mixi->load_cookies($file);

load cookies to file

=cut

sub load_cookies {
    my $this = shift;

    croak 'please specify cookie filename to save' if @_ < 1;
    my $file = shift;

    return $this->cookie_jar(HTTP::Cookies->new({})->load($file));
}

=item is_logined

  croak 'please login!' unless $mixi->is_logined;

return true if logined

=cut

sub is_logined { shift->session_id }

=item is_login_required

  croak 'please login before this method' if $mixi->is_login_required;

return true if login required

=cut

sub is_login_required { !shift->is_logined }

=item can_login

  # call (for example only, check_logined method has this code already)
  if ($mixi->is_login_required) {
      if ($mixi->can_login) {
	  $mixi->login;
      } else {
	  croak "Couldn't login to mixi!";
      }
  }

return true if we are able to login to mixi

=cut

sub can_login {
    my $this = shift;

    return (defined $this->email) && (defined $this->password);
}

=item check_logined

  $mixi->check_logined;
  $mixi->get(...);

if didn't login, try login or die.

=cut

sub check_logined {
    my $this = shift;
    if ($this->is_login_required) {
	if ($this->can_login) {
	    $this->login;
	} else {
	    croak "Couldn't login to mixi!";
	}
    }
}

=item session_id

  my $session_id = $mixi->session_id;

return session id

=cut

sub session_id {
    my $this = shift;
    return undef unless defined $this->cookie_jar;
    my $request = HTTP::Request->new(GET => $this->page('login')->uri);
    $this->cookie_jar->add_cookie_header($request);
    my $cookie = $request->header('Cookie');
    if (defined $cookie and $cookie =~ /BF_SESSION=(.*?)(;|$)/) {
	return $1;
    } else {
	return undef;
    }
}

=item set_content

  $mixi->set_content($uri);

set content to specified resource

=cut

sub set_content {
    my ($this, $uri) = @_;
    return undef unless defined $uri;
    return $this->refresh_content if $uri eq 'refresh';
    if (defined $this->response) {
	my $latest_uri = $this->response->request->uri->as_string;
	return 0 if $uri eq $latest_uri and $this->response->is_success;
	return $this->get($uri);
    }
}

=item refresh_content

  $mixi->refresh_content;

refresh content

=cut

sub refresh_content {
    my ($this) = @_;
    if (defined $this->response) {
	my $latest_uri = $this->response->request->uri->as_string;
	return $this->get($latest_uri);
    }
}

=item analyze_uri

  my @options = $mixi->analyze_uri($uri);

analyze URI and return options.

=cut

sub analyze_uri {
    my ($this, $uri) = @_;
    $uri = $this->absolute_uri($uri)->rel($this->base_uri);
    my $path = $uri->path;
    $path =~ s/\.pl$//;
    my $page = eval { $this->page($path) };
    if (defined $page) {
	$page->parse_uri({
	    path => $path,
	    uri => $uri,
	    params => $uri->query_form_hash});
    } else {
	(__warn => "page($path) not found: $@");
    }
}

=item relative_uri

  my $uri = $mixi->relative_uri('http://mixi.jp/login,pl');

generate relative URI from mixi.

=cut

sub relative_uri {
    my ($this, $uri, $base) = @_;
    $base = $this->base_uri unless defined $base;
    $this->SUPER::relative_uri($uri, $base);
}

=item absolute_uri

  my $uri = $mixi->absolute_uri('login');

generate absolute URI from mixi

=cut

sub absolute_uri {
    my ($this, $uri, $base) = @_;
    $base = $this->base_uri unless defined $base;
    if (defined $uri && basename($uri) !~ /[.?]/) {
	$uri .= '.pl';
    }
    $this->SUPER::absolute_uri($uri, $base);
}

=item absolute_linked_uri

  my $uri = $mixi->absolute_linked_uri('foo.pl?bar=baz...');

generate absolute uri from link(or other relative URIs)

=cut

sub absolute_linked_uri {
    my ($this, $uri) = @_;
    my $res = $this->response;
    if (defined $res) {
	$this->absolute_uri($uri, $res->request->uri);
    } else {
	$this->absolute_uri($uri);
    }
}

sub simple_request {
    # wrap simple_request for save response
    my $this = shift;

    return $this->response($this->SUPER::simple_request(@_));
}

=item post

  my $res = $mixi->post('login', foo => bar, baz => qux);

http/post to mixi.

=cut

sub post {
    my $this = shift;
    my $uri = $this->absolute_uri(shift);
    my @form = @_;
    my $req;

    if (grep {ref eq 'ARRAY'} @form) {
	$req = POST($uri, Content_Type => 'form-data',
		    Content => [@form]);
    } else {
	$req = POST($uri, [@form]);
    }

    return $this->request($req);
}

=item get

  my $res = $mixi->get('home');

http/get to mixi.

=cut

sub get {
    my $this = shift;
    my $uri = $this->absolute_uri(shift);

    return $this->request(HTTP::Request->new('GET', $uri));
}

=back

=head1 PROXY METHODS

=over 4

=item convert_from_http_content

=item convert_to_http_content

=item convert_login_time

=item convert_time

see L<WWW::Mixi::OO::I18N>.

=cut

foreach (qw(convert_from_http_content convert_to_http_content
	    convert_login_time convert_time)) {
    eval <<"END";
  sub $_ \{
      shift->{mixi}->{i18n_class}->$_(\@_);
  \}
END
}

1;
__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO>, L<LWP::UserAgent>, L<WWW::Mixi::OO::Util>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
