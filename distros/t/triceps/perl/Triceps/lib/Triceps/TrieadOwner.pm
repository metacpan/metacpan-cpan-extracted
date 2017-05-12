#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the TrieadOwner class.

package Triceps::TrieadOwner;

our $VERSION = 'v2.0.1';

use Carp;

use strict;

# Remember a file that has been just opened. This file will be revoked when
# the thread is requested dead.
# @param $file - the file glob object (such as *STDIN or one returned by IO::Socket::INET->new())
sub track(*) # ($self, $file)
{
	my $fd = fileno($_[1]) or confess "Triceps::TrieadOwner::open(): can not get the file descriptor";
	$_[0]->trackFd($fd);
}

# Forget a file before it gets closed. If this function is not called properly before
# closing a file descriptor, the thread shutdown will corrupt a random file descriptor
# that happens to have the same id. Better yet, use the TrieadOwner::close().
# @param $file - the file glob object (such as *STDIN or one returned by IO::Socket::INET->new())
sub forget(*) # ($self, $file)
{
	my $fd = fileno($_[1]) or confess "Triceps::TrieadOwner::forget(): can not get the file descriptor";
	$_[0]->forgetFd($fd);
}

# Forget a file and close it conveniently.
# @param $file - the file glob object (such as *STDIN or one returned by IO::Socket::INET->new())
sub close(*) # ($self, $file)
{
	my $fd = fileno($_[1]) or confess "Triceps::TrieadOwner::forget(): can not get the file descriptor";
	$_[0]->forgetFd($fd);
	close($_[1]);
}

# Track a file, and return a TrackedFile
# that will automatically make this TrieadOwner forget the file
# descriptor and then close and dereference the handle when the
# TrackedFile is destroyed.
#
# Make sure to keep a variable with the file handle if you're
# to start more threads, or Perl will leak the variables.
#
# Confesses on any errors.
#
# @param self - the TrieadOwner object
# @param file - the file handle to track
sub makeTrackedFile # ($self, $file)
{
	my $self = shift;
	my $file = shift;
	my $fd = fileno($file);
	
	confess "TrieadOwned::makeTrackedFile: the file argument must be a file handle, fileno() for it returned an undef"
		if (!defined $fd);
	return $self->makeTrackedFileFd($file, $fd);
}

# Load an file from the App, track it, and return a TrackedFile
# that will automatically make this TrieadOwner forget the file
# descriptor and then close and dereference the handle when the
# TrackedFile is destroyed.
#
# Keep the file handle in a variable (not just the tracking 
# object) if you're to start more threads, or Perl will leak the 
# variables.
#
# Confesses on any errors.
#
# @param self - the TrieadOwner object
# @param name - the storage name of the file descriptor
# @param mode - the file opening mode (either in r/w/a/r+/w+/a+
#        or </>/>>/+</+>/+>> format)
# @param class - class name to import the descriptor to
# @return - a pair of (TrackedFile object, file handle)
sub trackDupClass # ($self, $name, $mode, $class)
{
	my ($self, $name, $mode, $class) = @_;

	my ($fd, $fdclass) = $self->app()->loadDupFd($name);
	# XXX this could leak the $fd if new_from_fd() fails
	my $file = $class->new_from_fd($fd, $mode);
	return ($self->makeTrackedFileFd($file, $fd), $file);
}

# Same as trackDupClass(), but also closes the original
# file descriptor in the App, thus completely moving the
# descriptor here.
sub trackGetClass # ($self, $name, $mode, $class)
{
	my ($self, $name, $mode, $class) = @_;
	my ($tfd, $file) = trackDupClass(@_);
	$self->app()->closeFd($name);
	return ($tfd, $file);
}

# Load a file and its class name from the App, track it, and return a TrackedFile
# that will automatically make this TrieadOwner forget the file
# descriptor and then close and dereference the handle when the
# TrackedFile is destroyed.
#
# Keep the file handle in a variable (not just the tracking 
# object) if you're to start more threads, or Perl will leak the 
# variables.
#
# @param self - the TrieadOwner object
# @param name - the storage name of the file descriptor
# @param mode - the file opening mode (either in r/w/a/r+/w+/a+
#        or </>/>>/+</+>/+>> format)
# @return - a pair of (TrackedFile object, file handle)
sub trackDupFile # ($self, $name, $mode)
{
	my ($self, $name, $mode) = @_;

	my ($fd, $class) = $self->app()->loadDupFd($name);
	$class = "IO::Handle" unless $class; # default is a plain file, since ref(*FILE) returns an empty string
	# XXX this could leak the $fd if new_from_fd() fails
	my $file = $class->new_from_fd($fd, $mode);
	return ($self->makeTrackedFileFd($file, $fd), $file);
}

# Same as trackDupFile(), but also closes the original
# file descriptor in the App, thus completely moving the
# descriptor here.
sub trackGetFile # ($self, $name, $mode)
{
	my ($self, $name, $mode) = @_;
	my ($tfd, $file) = trackDupFile(@_);
	$self->app()->closeFd($name);
	return ($tfd, $file);
}

1;
