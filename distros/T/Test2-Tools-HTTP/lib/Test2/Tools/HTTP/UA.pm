package Test2::Tools::HTTP::UA;

use strict;
use warnings;
use Carp ();
use File::Spec ();
use Test2::Tools::HTTP::Apps;

# ABSTRACT: User agent wrapper for Test2::Tools::HTTP
our $VERSION = '0.10'; # VERSION


sub _init
{
  foreach my $inc (@INC)
  {
    my $dir = File::Spec->catdir($inc, 'Test2/Tools/HTTP/UA');
    next unless -d $dir;
    my $dh;
    opendir $dh, $dir;
    my @list = sort grep !/^\./, grep /\.pm$/, readdir $dh;
    closedir $dh;
    foreach my $pm (@list)
    {
      eval { require "Test2/Tools/HTTP/UA/$pm"; };
      if(my $error = $@)
      {
        warn $error;
      }
    }
  }
}

my %classes;
my %instance;

sub new
{
  my($class, $ua) = @_;

  if($class eq __PACKAGE__)
  {
    _init();
    my $class;

    if(ref($ua) eq '' && defined $ua)
    {
      ($class) = @{ $classes{$ua} };
    }
    else
    {
      foreach my $try (keys %instance)
      {
        if(eval { $ua->isa($try) })
        {
          ($class) = @{ $instance{$try} };
        }
      }
    }

    if(defined $class)
    {
      return $class->new($ua);
    }
    else
    {
      Carp::croak("user agent @{[ ref $ua ]} not supported ");
    }
  }

  bless {
    ua   => $ua,
  }, $class;
}


sub ua
{
  shift->{ua};
}


sub apps
{
  Test2::Tools::HTTP::Apps->new;
}


sub error
{
  my(undef, $message, $res) = @_;
  my $error = bless { message => $message, res => $res }, 'Test2::Tools::HTTP::UA::Error';
  die $error;
}


sub register
{
  my(undef, $class, $type) = @_;
  my $caller = caller;
  if($type eq 'class')
  {
    push @{ $classes{$class} }, $caller;
  }
  elsif($type eq 'instance')
  {
    push @{ $instance{$class} }, $caller;
  }
  else
  {
    Carp::croak("unknown type for $class: $type");
  }
}

package Test2::Tools::HTTP::UA::Error;

use overload
  '""' => sub { shift->as_string },
  bool => sub { 1 }, fallback => 1;

sub message { shift->{message} }
sub res { shift->{res} }
sub as_string { shift->message }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP::UA - User agent wrapper for Test2::Tools::HTTP

=head1 VERSION

version 0.10

=head1 SYNOPSIS

Use a wrapper:

 my $wrapper = Test2::Tools::HTTP::MyUAWrapper->new($ua);
 
 # returns a HTTP::Response object
 # or throws an error on a connection error
 my $res = $wrapper->request($req);

Write your own wrapper:

 package Test2::Tools::HTTP::UA::MyUAWrapper;
 
 use parent 'Test2::Tools::HTTP::UA';
 
 sub instrument
 {
   my($self) = @_;
   my $ua = $self->ua;  # the user agent object
   my $apps = $self->apps;
 
   # instrument $ua so that when requests
   # made against URLs in $apps the responses
   # come from the apps in $apps.
   ...
 }
 
 sub request
 {
   my $self = shift;
   my $req  = shift;   # this isa HTTP::Request
   my %options = @_;
 
   my $self = $self->ua;
   my $res;
 
   if($options{follow_redirects})
   {
     # make a request using $ua, store
     # result in $res isa HTTP::Response
     # follow any redirects if $ua supports
     # that.
     my $res = eval { ... };
 
     # on a CONNECTION error, you should throw
     # an exception using $self->error.  This should
     # NOT be used for 400 or 500 responses that
     # actually come from the remote server or
     # PSGI app.
     if(my $error = $@)
     {
       $self->error(
        "connection error: " . ($res->decoded_content || $warning),
       );
     }
   }
   else
   {
     # same as the previous block, but should
     # NOT follow any redirects.
     ...
   }
 
   $res;
 }
 
 __PACKAGE__->register('MyUA', 'instance');

=head1 DESCRIPTION

This is the base class for user agent wrappers used
by L<Test2::Tools::HTTP>.  The idea is to allow the
latter to work with multiple user agent classes
without having to change the way your C<.t> file
interacts with L<Test2::Tools::HTTP>.  By default
L<Test2::Tools::HTTP> uses L<LWP::UserAgent> and
in turn uses L<Test2::Tools::HTTP::UA::LWP> as its
user agent wrapper.

=head1 CONSTRUCTOR

=head2 new

 my $wrapper = Test2::Tools::HTTP::UA->new($ua);

Creates a new wrapper.

=head1 METHODS

=head2 ua

 my $ua = $wrapper->ua;

Returns the actual user agent object.  This could be I<any>
user agent object, such as a L<LWP::UserAgent>, L<HTTP::Simple>,
or L<Mojo::UserAgent>, but generally your wrapper only needs
to support ONE user agent class.

=head2 apps

 my $apps = $wrapper->apps;
 my $apps = Test2::Tools::HTTP::UA->apps;

This returns an instance of L<Test2::Tools::HTTP::Apps> used
by your wrapper.  It can be used to lookup PSGI apps by
url.

Because the apps object is a singleton, you may also call this
as a class method.

=head2 error

 $wrapper->error($message);
 $wrapper->error($message, $response);

This throws an exception that L<Test2::Tools::HTTP> understands
to be a connection error.  This is the preferred way to handle
a connection error from within your C<request> method.

The second argument is an optional instance of L<HTTP::Response>.
In the event of a connection error, you won't have a response object
from the actual remote server or PSGI application.  Some user agents
(such as L<LWP::UserAgent>) produce a synthetic response object.
You can stick it here for diagnostic purposes.  You should NOT
create your own synthetic response object though, only use this
argument if your user agent produces a faux response object.

=head2 register

 Test2::Tools::HTTP::UA->register($class, $type);

Register your wrapper class with L<Test2::Tools::HTTP::UA>.
C<$class> is the user agent class.  C<$type> is either
C<class> for classes or C<instance> for instances, meaning
your wrapper works with a class or an instance object.

=head1 SEE ALSO

=over 4

=item L<Test2::Tools::HTTP>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
