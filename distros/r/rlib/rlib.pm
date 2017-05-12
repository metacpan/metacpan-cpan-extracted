package rlib;

use strict;
use vars qw($VERSION @ISA);
use lib ();
use File::Basename qw(dirname);
use File::Spec;

$VERSION = "0.02";
@ISA = qw(lib);

sub _dirs {
    my($pkg,$file) = (caller(1))[0,1];
    my @rel = @_ ? @_ : qw(../lib lib);
    my $dir;

    # if called from package main then assume we were called
    # by a script not a module

    if($pkg eq 'main') {
	require FindBin;
	# hide "used only once" warning
	$dir = ($FindBin::Bin,$FindBin::Bin)[0];
    }
    else {
	require Cwd;
	$dir = Cwd::abs_path(dirname($file));
    }

    # If we were called by a package then traverse upwards
    # to root of lib

    while($pkg =~ /::/g) {
	$dir = dirname($dir);
    }

    if($^O eq 'VMS') {
	require VMS::Filespec;
	@rel = map { VMS::Filespec::unixify($_) } @rel;
    }

    map { File::Spec->catdir($dir,$_) } @rel;
}

sub import {
    shift->SUPER::import( _dirs(@_) );
}

sub unimport {
    shift->SUPER::unimport( _dirs(@_) );
}

1;

__END__

=head1 NAME

rlib - manipulate @INC at compile time with relative paths

=head1 SYNOPSIS

    use rlib LIST;

    no rlib LIST;

=head1 DESCRIPTION

rlib works in the same way as lib, except that all paths in C<LIST>
are treated as relative paths.

If rlib is used from the C<main> package then the paths in C<LIST>
are assumed to be relative to where the current script C<$0> is
located. This is done by using the FindBin package.

If rlib is used from within any package other tha C<main> then the
paths in C<LIST> are assumed to be relative to the root of the library
where the file for that package was found.

If C<LIST> is empty then C<"../lib","lib"> is assumed.

=head1 SEE ALSO

lib - module which adds paths to @INC

FindBin - module for locating script bin directory

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=cut
