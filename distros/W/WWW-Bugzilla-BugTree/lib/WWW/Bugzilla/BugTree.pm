package WWW::Bugzilla::BugTree;

use strict;
use warnings;
use Ref::Util qw( is_arrayref );
use 5.012;
use Moo;

# ABSTRACT: Fetch a tree of bugzilla bugs blocking a bug
our $VERSION = '0.08'; # VERSION


has ua => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua;
  },
);


my $default_url = $ENV{BUG_TREE_URL} // "https://landfill.bugzilla.org/bugzilla-4.2-branch";

has url => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    require URI;
    URI->new($default_url);
  },
  coerce  => sub {
    ref $_[0] ? $_[0] : do { require URI; URI->new($_[0] // $default_url) },
  },
);

has _cache => (
  is       => 'ro',
  default  => sub { { } },
  init_arg => undef,  
);


sub fetch
{
  my($self, $bug_id) = @_;
  
  return $self->_cache->{$bug_id}
    if exists $self->_cache->{$bug_id};
  
  my $url = $self->url->clone;
  $url->path((do { my $path = $url->path; $path =~ s{/$}{}; $path }) . "/show_bug.cgi");
  $url->query_form(
    id    => $bug_id,
    ctype => 'xml',
  );
  
  my $res = $self->ua->get($url);  
  
  die $url . " " . $res->status_line
    unless $res->is_success;

  require WWW::Bugzilla::BugTree::Bug;  
  my $b = WWW::Bugzilla::BugTree::Bug->new(
    url => $url,
    res => $res,
    id  => $bug_id,
  );
  
  $self->_cache->{$bug_id} = $b;
  
  my $dependson = $b->as_hashref->{bug}->{dependson};
  $dependson = [] unless defined $dependson;
  $dependson = [ $dependson ]
    unless is_arrayref $dependson;
    
  @{ $b->children } = map { $self->fetch($_) } sort @$dependson;
  
  $b;
}


sub clear_cache
{
  my($self) = @_;
  %{ $self->_cache } = ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Bugzilla::BugTree - Fetch a tree of bugzilla bugs blocking a bug

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 use WWW::Bugzilla::BugTree;
 
 my $tree = WWW::Bugzilla::BugTree->new(
   url => 'http://bugzilla',
 );
 
 # $bug isa WWW::Bugzilla::BugTree::Bug
 my $bug = $tree->fetch(749922);
 print $bug;
 foreach my $subbug (@{ $bug->children })
 {
   print $bug;
 }

=head1 DESCRIPTION

This module provides a way to fetch a tree of dependent bugs from Bugzilla.
You give it a bug id and it returns a tree of all the bugs that bug depends
on (or all the bugs that are blocking your bug).  I wrote this to use the
C<XML> output of Bugzilla's C<show_bug.cgi> page because we are still using
Bugzilla 3.6, which doesn't provide dependency information via its API, which
would probably be faster.

There is also a companion script L<bug_tree> which will print out the tree
for you with pretty colors indicating each bug's status.

=head1 ATTRIBUTES

=head2 ua

 my $lwp = $tree->ua;

Instance of L<LWP::UserAgent> used to fetch information from the
bugzilla server.

=head2 url

 my$url = $tree->url

The URI of the bugzilla server.  You may pass in to the constructor
either a string or a L<URI> object.  If you use a string it will
be converted into a L<URI>.

If not provided it falls back to using the C<BUG_TREE_URL> environment
variable, and if that isn't set it uses this bugzilla provided for
testing:

L<Bugzilla v4.2|https://landfill.bugzilla.org/bugzilla-4.2-branch>

=head1 METHODS

=head2 fetch

 my $bug = $tree->fetch($id);

Fetch the bug tree for the bug specified by the given C<id>.  Returns
an instance of L<WWW::Bugzilla::BugTree::Bug>.

=head2 clear_cache

 $tree->clear_cache;

Clears out the cache.

=head1 SEE ALSO

L<bug_tree>, L<WWW::Bugzilla::BugTree::Bug>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
