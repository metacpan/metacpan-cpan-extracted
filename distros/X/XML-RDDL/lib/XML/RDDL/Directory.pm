
###
# XML::RDDL::Directory - RDDL Directory Interface
# Robin Berjon <robin@knowscape.com>
# 17/10/2001 - v.0.01
###

package XML::RDDL::Directory;
use strict;

use vars qw($VERSION);
$VERSION = $XML::RDDL::VERSION || '0.01';


#-------------------------------------------------------------------#
# constructor
#-------------------------------------------------------------------#
sub new {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    return bless [], $class;
}
#-------------------------------------------------------------------#


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Interface `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# add_resource
#-------------------------------------------------------------------#
sub add_resource {
    my $d   = shift;
    my $res = shift;
    push @$d, $res;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# delete_resource
#-------------------------------------------------------------------#
sub delete_resource {
    my $d   = shift;
    my $res = shift;
    @$d = grep { "$res" ne "$_" } @$d;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# get_resources
#-------------------------------------------------------------------#
sub get_resources {
    my $d   = shift;
    return @$d;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# get_resource_by_id
#-------------------------------------------------------------------#
sub get_resource_by_id {
    my $d   = shift;
    my $id  = shift;
    for my $r (@$d) {
        return $r if $r->get_id eq $id;
    }
    return;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# get_resources_by_nature
#-------------------------------------------------------------------#
sub get_resources_by_nature {
    my $d   = shift;
    my $nat = shift;
    return grep { $nat eq $_->get_nature } @$d;
}
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# get_resources_by_purpose
#-------------------------------------------------------------------#
sub get_resources_by_purpose {
    my $d   = shift;
    my $pur = shift;
    return grep { $pur eq $_->get_purpose } @$d;
}
#-------------------------------------------------------------------#



1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

XML::RDDL::Directory - RDDL Directory Interface

=head1 SYNOPSIS

  use XML::RDDL::Directory;
  # create a new RDDL directory
  my $dir = XML::RDDL::Directory->new;
  # add some resources
  $dir->add_resource($res1);
  $dir->add_resource($res2);
  # delete a resource
  $dir->delete_resource($res1);
  # get resources by various searches
  $res = $dir->get_resource_by_id('foo');
  $res = $dir->get_resources_by_nature('http://foobar/nat');
  $res = $dir->get_resources_by_purpose('http://foobar/purp');

=head1 DESCRIPTION

XML::RDDL::Directory is a container for all the XML::RDDL::Resources
found in one RDDL directory. It has a variety of methods to make
access to those resources easier.

=head1 METHODS

=over 4

=item XML::RDDL::Directory->new

Creates a new Directory

=item add_resource($res1);

Adds a given Resource to the Directory

=item delete_resource($res1);

Deletes a given Resource from the Directory

=item get_resources

Returns a list of all the resources

=item get_resource_by_id('foo');

Returns the Resource in the Directory that has that id (nothing if
there is none)

=item get_resources_by_nature('http://foobar/nat');

Returns a (possibly empty) list of Resources in that Directory that
have the given nature

=item get_resources_by_purpose('http://foobar/purp');

Returns a (possibly empty) list of Resources in that Directory that
have the given purpose

=back

=head1 TODO

  - time will tell if more search methods are needed

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001-2002 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

http://www.rddl.org/, XML::RDDL

=cut
