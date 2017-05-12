package Tree::File::YAML;

use warnings;
use strict;

use base qw(Tree::File);

use Carp qw(croak);
use File::Basename ();
use File::Path ();
use YAML ();

=head1 NAME

Tree::File::YAML - (DEPRECATED) store a data structure in a file tree (using YAML)

=head1 VERSION

version 0.112

=cut

our $VERSION = '0.112';

=head1 SYNOPSIS

 use Tree::File::YAML;

 my $tree = Tree::File::YAML->new($treerot);

 die "death mandated" if $tree->get("/master/die")

 print "Hello, ", $tree->get("/login/user/name");

 $tree->set("/login/user/lastlogin", time);
 $tree->write;

=head1 DESCRIPTION

This module stores configuration in a series of YAML files spread across a
directory tree, and provides uniform access to the data structure.

It can load a single YAML file or a directory tree containing YAML files as
leaves.  The tree's branches can be returned as data structures or YAML
documents, and the tree can be modified and rewritten.  Directory-based
branches can be collapsed back into files and file-based branches can be
exploded into directories.

For more information, see L<Tree::File>.

=head1 METHODS

=head2 C<< $tree->load_file($filename) >>

This method loads the given filename as YAML, croaks if it contains more than
one section, and otherwise returns the contained data.

=cut

sub load_file {
  my ($class, $filename) = @_;
  my ($head, @tail) = YAML::LoadFile($filename);
  croak "YAML file $filename contains multiple sections" if @tail;
  return $head;
}

=head2 C<< $tree->as_yaml() >>

This method returns the entire tree of data (returned by the C<data> method),
serialized into YAML.

=cut

sub as_yaml {
  my ($self) = @_;
  YAML::Dump($self->data);
}

=head2 C<< $tree->write_file($filename, $data) >>

This method writes the given data, as YAML, to the given filename.

=cut

sub write_file {
  my ($self, $filename, $data) = @_;

  $filename =~ s{//}{/}g;
  $filename =~ s{/\Z}{};

  if (-d $filename) {
    File::Path::rmtree($filename);
    return YAML::DumpFile($filename, $data);
  }

  if (-f $filename) {
    return YAML::DumpFile($filename, $data);
  }

  my $dir = File::Basename::dirname($filename);
  unless (-d $dir) {
    # die "this is the problem" if -f $dir;
    File::Path::mkpath($dir) unless -d $dir;
  }
  return YAML::DumpFile($filename, $data);
}

=head1 TODO

=over

=item * symlinks and references

=back

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-file@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT

Copyright 2005 Ricardo Signes, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
