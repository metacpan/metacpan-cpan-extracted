package Test2::Tools::URL;

use strict;
use warnings;
use 5.008001;
use Carp                   ();
use Test2::Compare         ();
use Test2::Compare::Hash   ();
use Test2::Compare::String ();
use base qw( Exporter );

our @EXPORT = qw( url url_base url_component );

# ABSTRACT: Compare a URL in your Test2 test
our $VERSION = '0.05'; # VERSION


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
  my($name, $expect) = @_;
  
  Carp::croak("$name is not a valid URL component")
    unless $name =~ /^(?:scheme|authority|userinfo|hostport|host|port|path|query|fragment)$/;
  
  my $build = Test2::Compare::get_build()or Carp::croak("No current build!");
  $build->add_component($name, $expect);
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
  my($self, $name, $expect) = @_;
  push @{ $self->{component} }, [ $name, $expect ];
}

sub deltas
{
  my($self, %args) = @_;
  my($got, $convert, $seen) = @args{'got', 'convert', 'seen'};

  my $uri = $self->_uri($got);
  
  my @deltas;
  
  foreach my $comp (@{ $self->{component} })
  {
    my($name, $expect) = @$comp;
    
    my $method = $name;
    $method = 'host_port' if $method eq 'hostport';
    my $value = $uri->$method;
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

version 0.05

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::URL;
 
 is(
   "http://example.com/path1/path2?query=1#fragment",
   url {
     url_component scheme   => 'http';
     url_component host     => 'example.com';
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

=item authority

=item userinfo

=item hostport

=item host

=item port

=item path

=item query

May be either a string, list or array!

=item fragment

=back

=head1 SEE ALSO

L<Test2::Suite>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Paul Durden (alabamapaul, PDURDEN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
