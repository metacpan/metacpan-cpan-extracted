package WWW::Bugzilla::BugTree::Bug;

use strict;
use warnings;
use 5.012;
use Moo;
use XML::Simple qw( XMLin );
use overload '""' => sub { shift->as_string };

# ABSTRACT: A bug tree returned from WWW::Bugzilla::BugTree
our $VERSION = '0.08'; # VERSION


has url => (
  is       => 'ro',
  required => 1,
);


has res => (
  is       => 'ro',
  required => 1,
);


has id => (
  is       => 'ro',
  required => 1,
);

has as_hashref => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    no warnings;
    XMLin(shift->res->decoded_content);
  },
);


has children => (
  is       => 'ro',
  init_arg => undef,
  default  => sub { [] },
);


sub as_string
{
  my($self) = @_;
  my $id         = $self->id;
  my $status     = $self->as_hashref->{bug}->{bug_status};
  my $subject    = $self->as_hashref->{bug}->{short_desc};
  my $resolution = $self->as_hashref->{bug}->{resolution};
  undef $resolution if ref $resolution;
  $resolution ? "$id $status ($resolution) $subject" : "$id $status $subject";
}

# undocumented function
sub summary_tree
{
  my($self) = @_;
  
  [ $self->as_string, @{ $self->children } > 0 ? map { $_->summary_tree } @{ $self->children } : () ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Bugzilla::BugTree::Bug - A bug tree returned from WWW::Bugzilla::BugTree

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This class represents an individual bug returned from L<WWW::Bugzilla::BugTree>'s C<fetch> method.
It is also a tree since it has a C<children> accessor which returns the list of bugs that block
this bug.

=head1 ATTRIBUTES

=head2 url

 my $url = $bug->url;

The URL of the bug.

=head2 res

 my $res = $bug->res;

The raw L<HTTP::Response> object for the bug.

=head2 id

 my $id = $bug->id;

The bug id for the bug.

=head2 children

 my @children = $bug->children->@*;

The list of bugs that are blocking this one.
This is a list of L<WWW::Bugzilla::BugTree::Bug> objects.

=head2 as_string

 my $string = $bug->as_string;
 my $string = "$bug";

Returns a human readable form of the string in the form of

 "id status (resolution) subject"

if it has been resolved, and 

 "id status subject"

otherwise.

=head1 SEE ALSO

L<bug_tree>, L<WWW::Bugzilla::BugTree>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
