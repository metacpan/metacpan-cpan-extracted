package Test2::Tools::URL;

use strict;
use warnings;
use 5.008001;
use Carp                   ();
use Test2::Compare         ();
use Test2::Compare::Hash   ();
use Test2::Compare::String ();
use Test2::Compare::Custom ();
use base qw( Exporter );

our @EXPORT = qw( url url_base url_component url_scheme url_host url_secure url_insecure url_mail_to );

# ABSTRACT: Compare a URL in your Test2 test
our $VERSION = '0.06'; # VERSION


sub url (&)
{
  Test2::Compare::build('Test2::Tools::URL::Check', @_);
}


sub url_base ($)
{
  my($base) = @_;

  my $build = Test2::Compare::get_build();
  if($build)
  { $build->set_base($base) }
  else
  { Test2::Tools::URL::Check->set_global_base($base) }
}


sub url_component ($$)
{
  my($name, $expect, $lc, $check_name) = @_;

  $check_name = 1 unless defined $check_name;
  if($check_name)
  {
    Carp::croak("$name is not a valid URL component")
      unless $name =~ /^(?:scheme|authority|userinfo|hostport|host|port|path|query|fragment|user|password|media_type|data)$/;
  }

  my $build = Test2::Compare::get_build()or Carp::croak("No current build!");
  $build->add_component($name, $expect, $lc);
}


sub url_scheme ($)
{
  unshift @_, 'scheme';
  goto &url_component;
}


sub url_host ($)
{
  @_ = ('host', $_[0], 1);
  goto &url_component;
}


sub url_secure ()
{
  my @caller = caller;
  my $test = Test2::Compare::Custom->new(
    code     => sub { defined $_ && ( ref $_ || $_ ) ? 1 : 0 },
    name     => 'TRUE',
    operator => 'TRUE()',
    file     => $caller[1],
    lines    => [$caller[2]],
  );
  @_ = ('secure', $test, undef, 0);
  goto &url_component;
}


sub url_insecure ()
{
  my @caller = caller;
  my $test = Test2::Compare::Custom->new(
    code => sub { my %p = @_; $p{got} ? 0 : $p{exists} },
    name => 'FALSE',
    operator => 'FALSE()',
    file     => $caller[1],
    lines    => [$caller[2]],
  );
  @_ = ('secure', $test, undef, 0);
  goto &url_component;
}


sub url_mail_to ($)
{
  @_ = ('to', $_[0], undef, 0);
  goto &url_component;
}

package Test2::Tools::URL::Check;

use overload ();
use URI 1.61;
use URI::QueryParam;
use Scalar::Util qw( blessed );
use base qw( Test2::Compare::Base );

sub name { '<URL>' }

my $global_base;

sub _uri
{
  my($self, $url) = @_;
  $self->{base}
    ? URI->new_abs("$url", $self->{base})
    : $global_base
      ? URI->new_abs("$url", $global_base)
      : URI->new("$url");
}

sub verify
{
  my($self, %params) = @_;
  my($got, $exists) = @params{qw/ got exists /};

  return 0 unless $exists;
  return 0 unless $got;
  return 0 if ref($got) && !blessed($got);
  return 0 if ref($got) && !overload::Method($got, '""');

  my $url = eval { $self->_uri($got) };
  return 0 if $@;
  return 0 if ! $url->has_recognized_scheme;

  return 1;
}

sub set_base
{
  my($self, $base) = @_;
  $self->{base} = $base;
}

sub set_global_base
{
  my($self, $base) = @_;
  $global_base = $base;
}

sub add_component
{
  my($self, $name, $expect, $lc) = @_;
  push @{ $self->{component} }, [ $name, $expect, $lc ];
}

sub deltas
{
  my($self, %args) = @_;
  my($got, $convert, $seen) = @args{'got', 'convert', 'seen'};

  my $uri = $self->_uri($got);

  my @deltas;

  foreach my $comp (@{ $self->{component} })
  {
    my($name, $expect, $lc) = @$comp;

    my $method = $name;
    $method = 'host_port' if $method eq 'hostport';
    my $value = $uri->can($method) ? $uri->$method : undef;
    $value = lc $value if $lc && defined $value;
    my $check = $convert->($expect);

    if($^O eq 'MSWin32' && $method eq 'path')
    {
      $value =~ s{/([A-Z]:)}{$1};
    }

    if($method eq 'query' && !$check->isa('Test2::Compare::String'))
    {
      if($check->isa('Test2::Compare::Hash'))
      {
        $value = $uri->query_form_hash;
      }
      elsif($check->isa('Test2::Compare::Array'))
      {
        $value = [ $uri->query_form ];
      }
    }


    push @deltas => $check->run(
      id      => [ HASH => $name ],
      convert => $convert,
      seen    => $seen,
      exists  => defined $value,
      got     => $value,
    );
  }

  @deltas;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::URL - Compare a URL in your Test2 test

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::URL;
 
 is(
   "http://example.com/path1/path2?query=1#fragment",
   url {
     url_scheme             => 'http';
     url_host               => 'example.com';
     url_component path     => '/path1/path2';
     url_component query    => { query => 1 };
     url_component fragment => 'fragment';
   },
   'url is as expected',
 );

=head1 DESCRIPTION

This set of L<Test2> tools helps writing tests against
URLs, represented as either strings, or as objects that
stringify to URLs (such as L<URI> or L<Mojo::URL>).

The idea is that you may be writing tests against URLs,
but you may only care about one or two components, and
you may not want to worry about decoding the URL or breaking
the components up.  The URL may be nested deeply.  This
tool is intended to help!

=head1 FUNCTIONS

=head2 url

 my $check = url {}

Checks that the given string or object is a valid URL.

=head2 url_base

 url {
   url_base $url;
 };

Use the given base URL for relative paths.  If specified outside of a URL,
then it will apply to all url checks.

=head2 url_component

 url {
   url_component $component, $check;
 }

Check that the given URL component matches.

=over 4

=item scheme

Note: scheme I<is> normalized to lower case for this test.

=item authority

=item userinfo

=item hostport

=item host

Note: hostname I<is not> normalized to lower case for this test.  To test the normalized hostname use C<url_host> below.

=item port

=item path

=item query

May be either a string, list or array!

=item fragment

=item user

[version 0.06]

Note: for C<ftp> URLs only.

=item password

[version 0.06]

Note: for C<ftp> URLs only.

=item media_type

[version 0.06]

Note: for C<data> URLs only.

=item data

[version 0.06]

Note: for C<data> URLs only.

=back

=head2 url_scheme

[version 0.06]

 url {
   url_scheme $check;
 }

Check that the given URL scheme matches C<$check>.  Note that the scheme I<is> normalized
to lower case for this test, so it is identical to using C<url_component 'scheme', $check>.

=head2 url_host

[version 0.06]

 url {
   url_host $check;
 }

Check that the given URL host matches C<$check>.  Note that the host I<is> normalized to
lower case for this test, unlike the C<url_component 'host', $check> test described above.

=head2 url_secure

[version 0.06]

 url {
   url_secure();
 }

Check that the given URL is using a secure protocol like C<https> or C<wss>.

=head2 url_insecure

[version 0.06]

 url {
   url_insecure();
 }

Check that the given URL is using an insecure protocol like C<http> or C<ftp>.

=head2 url_mail_to

[version 0.06]

 url {
   url_mail_to $check;
 }

Checks that the email address in the given C<mailto> URL matches the check.
For non-C<mailto> URLs this check will fail.

=head1 SEE ALSO

L<Test2::Suite>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Paul Durden (alabamapaul, PDURDEN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
