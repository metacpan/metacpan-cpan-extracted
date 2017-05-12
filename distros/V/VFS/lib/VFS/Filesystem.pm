package VFS::Filesystem;

use strict;
use VFS::File;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	return bless $self, $class;
}

sub open {
	my ($self, $path, $attr) = @_;
	return new VFS::File();
}

sub remove {
	my ($self, $path, $attr) = @_;
	return undef;
}

sub create {
	my ($self, $path, $attr) = @_;
	return new VFS::File();
}

sub link {
	return 1;
}

sub mount {
	my ($self, $fs, $dir, $attr) = @_;
}

sub umount {
	my ($self, $dir) = @_;
}

=head1 NAME

VFS::Filesystem - A virtual filesystem layer for Perl

=head1 SYNOPSIS
	
	Unimplemented.

=head1 DESCRIPTION

An implementation of a virtual file system in Perl. It will allow
creation, reading and writing of files, mounting of systems in other
systems, ...

=cut

1;
__END__;
