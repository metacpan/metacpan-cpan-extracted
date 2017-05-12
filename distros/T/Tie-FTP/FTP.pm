#!/usr/bin/perl

package Tie::FTP;

use strict;
use warnings;

use File::Temp ();
use URI;
use Net::FTP;

our $VERSION = 0.02;

sub TIEHANDLE { # uri object || uri || netftp object, path
	my $pkg = shift || return undef;
	
	my ($tmpfh,$tmpnm) = File::Temp::tmpnam();
	
	my $self = bless { tmpfile => $tmpnm, tmpfh => $tmpfh},$pkg;
	
	$self;
}

sub OPEN {
	my $self = shift;
	
	if (scalar @_ > 1){
		$self->ftp(shift);
		$self->path(shift);
	} else { # uri or uri object
		my $uri = shift;
		$uri = URI->new($uri) unless ref $uri;
		return undef unless $uri->scheme eq 'ftp';
		
		$self->ftp(Net::FTP->new($uri->host));
		$self->ftp->login(split(':',$uri->userinfo));
		$self->path(substr($uri->path,1));
	}
	
	$self->ftp->get($self->path,$self->tmpfile);
}

sub tmpfile { # set to use a tempfile instead of writing and reading via net. overrides cache
	my $self = shift;
	$self->{tmpfile} = shift if @_;
	$self->{tmpfile};
}

sub tmpfh {
	my $self = shift;
	$self->{tmpfh} = shift if @_;
	$self->{tmpfh};
}

sub ftp {
	my $self = shift;
	$self->{ftp} = shift if @_;
	$self->{ftp};
}

sub path {
	my $self = shift;
	$self->{path} = shift if @_;
	$self->{path};
}

sub taint {
	my $self = shift;
	$self->{tainted} = 1;
}

sub tainted {
	my $self = shift;
	$self->{tainted};
}

sub CLOSE {
	goto &UNTIE;
}

sub UNTIE { }

sub DESTROY {
	my $self = shift;
	close $self->tmpfh;
	$self->ftp->put($self->tmpfile,$self->path) if $self->tainted;
	unlink $self->tmpfile;
}


sub WRITE { $_[0]->taint; my $fh = $_[0]{tmpfh}; print $fh substr($_[1],$_[3],$_[2]) }
sub PRINT { $_[0]->taint; my $fh = shift->{tmpfh}; print $fh @_ }
sub PRINTF { $_[0]->taint; my $fh = shift->{tmpfh}; printf $fh @_ }
sub READ { read *{$_[0]{tmpfh}},$_[1],$_[2],$_[3] }
sub READLINE { readline $_[0]{tmpfh} }
sub GETC { getc *{$_[0]{tmpfh}} }
sub BINMODE{ binmode *{$_[0]{tmpfh}} }
sub EOF { eof *{$_[0]{tmpfh}} }
sub TELL { tell *{$_[0]{tmpfh}} }
sub SEEK { seek *{$_[0]{tmpfh}},$_[1],$_[2] }

1; # Keep your mother happy.

__END__

=pod

=head1 NAME

Tie::FTP - A module to open files on FTP servers as filehandles

=head1 SYNOPSIS

	tie *FH,'Tie::FTP';

	open FH,'ftp://user:password@host/file';

	print while (<FH>);

	seek FH,0,0;
	print FH foo;
	close FH;

Or

	tie *FH,'Tie::FTP';
	
	(tied *FH)->taint;
	my $fh = (tied *FH)->tmpfh;
	
	seek $fh,0,0;
	print $fh foo;
	close FH;

=head1 DESCRIPTION

This module downloads a file on an FTP server into a temporary file, and allows editing on that. Upon destroy the object rewrites itself to the server if there were any write operations.

=head1 AVOIDING THE TIE INTERFACE

Since all the operations are actually delegated you're better off tying a gensym, and then using C<my $fh = (tied $ftpfh)-E<gt>tmpfh;>. Just remember to call C<(tied $ftpfh)-E<gt>taint;> if you want to commit changes at DESTROY time.

=head1 METHODS

=over 4

=item TIEHANDLE

This method accepts either a URI string or object, or a logged in Net::FTP object and a path string.

In the former all login credentials are sucked out of the URI, and a Net::FTP object is created. See CAVEATS.

In the latter form the Net::FTP object is assumed to be connected, and the path string is a relative one.

=back

=head1 CAVEATS

The file will be written regardless of wether or not there are write permissions.

You may need to do C<(tied $ftpfh)-E<gt>ftp-E<gt>noop;> every once in a while, to stir things up.

Net::FTP and URI are not used from within the module as you may prefer to pass other types of objects, with a compatible interface.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT


This program is free software licensed under the...

        The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=cut
