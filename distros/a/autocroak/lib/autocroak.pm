package autocroak;
$autocroak::VERSION = '0.002';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

my %key_for = (
	pipe          => 'PIPE_OP',
	getsockopt    => 'GSOCKOPT',
	setsockopt    => 'SSOCKOPT',
	opendir       => 'OPEN_DIR',
	do            => 'DOFILE',
	gethostbyaddr => 'GHBYADDR',
	getnetbyaddr  => 'GNBYADDR',

	-R => 'FTRREAD',
	-W => 'FTRWRITE',
	-X => 'FTREXEC',
	-r => 'FTEREAD',
	-w => 'FTEWRITE',
	-x => 'FTEEXEC',

	-e => "FTIS",
	-s => "FTSIZE",
	-M => "FTMTIME",
	-C => "FTCTIME",
	-A => "FTATIME",

	-O => "FTROWNED",
	-o => "FTEOWNED",
	-z => "FTZERO",
	-S => "FTSOCK",
	-c => "FTCHR",
	-b => "FTBLK",
	-f => "FTFILE",
	-d => "FTDIR",
	-p => "FTPIPE",
	-u => "FTSUID",
	-g => "FTSGID",
	-k => "FTSVTX",

	-l => "FTLINK",
	-t => "FTTTY",
	-T => "FTTEXT",
	-B => "FTBINARY",
);

sub import {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	$^H{"autocroak/enabled"} = 1;

	for my $op_name (keys %{ $args{allow} }) {
		my $op_key = $key_for{$op_name} // uc $op_name;
		my $key = "autocroak/$op_key";
		$^H{$key} //= '';
		my $values = $args{allow}{$op_name};
		for my $value (ref $values ? @{ $values } : $values) {
			vec($^H{$key}, $value, 1) = 1;
		}
	}
}

sub unimport {
	my (undef, %args) = @_;
	$^H |= 0x020000;
	delete $^H{$_} for grep m{^autocroak/}, keys %^H;
}

1;

# ABSTRACT: Replace functions with ones that succeed or die with lexical scope

__END__

=pod

=encoding UTF-8

=head1 NAME

autocroak - Replace functions with ones that succeed or die with lexical scope

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use autocroak;
 
 open(my $fh, '<', $filename); # No need to check!
 print "Hello World"; # No need to check either

=head1 DESCRIPTION

The autocroak pragma provides a convenient way to replace functions that normally return false on failure with equivalents that throw an exception on failure.

The autocroak pragma has lexical scope, meaning that functions and subroutines altered with autodie will only change their behaviour until the end of the enclosing block, file, or eval.

Optionally you can pass it an allow hash listing errors that are allowed for certain op:

 use autocroak allow => { unlink => ENOENT };

Note: B<This is an early release, the exception messages as well as types may change in the future, do not depend on this yet>.

=head2 Supported keywords:

=over 4

=item * open

=item * sysopen

=item * close

=item * system

=item * print

=item * flock

=item * truncate

=item * exec

=item * fork

=item * fcntl

=item * binmode

=item * ioctl

=item * pipe

=item * kill

=item * bind

=item * connect

=item * listen

=item * setsockopt

=item * accept

=item * getsockopt

=item * shutdown

=item * sockpair

=item * read

=item * recv

=item * sysread

=item * syswrite

=item * stat

=item * chdir

=item * chown

=item * chroot

=item * unlink

=item * chmod

=item * utime

=item * rename

=item * link

=item * symlink

=item * readlink

=item * mkdir

=item * rmdir

=item * opendir

=item * closedir

=item * select

=item * dbmopen

=item * dbmclose

=item * gethostbyaddr

=item * getnetbyaddr

=item * msgctl

=item * msgget

=item * msgrcv

=item * msgsnd

=item * semctl

=item * semget

=item * semop

=item * shmctl

=item * shmget

=item * shmread

=item * C<-R>

=item * C<-W>

=item * C<-X>

=item * C<-r>

=item * C<-w>

=item * C<-x>

=item * C<-e>

=item * C<-s>

=item * C<-M>

=item * C<-C>

=item * C<-A>

=item * C<-O>

=item * C<-o>

=item * C<-z>

=item * C<-S>

=item * C<-c>

=item * C<-b>

=item * C<-f>

=item * C<-d>

=item * C<-p>

=item * C<-u>

=item * C<-g>

=item * C<-k>

=item * C<-l>

=item * C<-t>

=item * C<-T>

=item * C<-B>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
