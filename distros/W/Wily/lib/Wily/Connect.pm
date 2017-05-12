package Wily::Connect;

use v5.8;
use strict;
use warnings;
use Carp;

use File::Temp qw/ :POSIX /;
use IO::Socket;
use Fcntl;

our $VERSION = '0.01';

sub connect {
	local *FILE;
	my $tmpfile = tmpnam();
	my $sock = IO::Socket::UNIX->new(Local=>$tmpfile,Type=>SOCK_STREAM, Listen=>1);

	sysopen FILE, wily_fifo_name(), O_WRONLY
		or croak "Unable to open wily fifo: $!";
	print FILE $tmpfile;
	close FILE or croak "Error closing wily fifo: $!";

	my $s = $sock->accept();
	$sock->close();

	unlink $tmpfile or carp "unlink of '$tmpfile' failed: $!";

	return $s;
}

sub wily_fifo_name {
	if (exists $ENV{WILYFIFO}) {
		return $ENV{WILYFIFO};
	}
	if (not exists $ENV{DISPLAY}) {
		croak 'No $DISPLAY set';
	}
	my $tmp = $ENV{TMPDIR} || '/tmp';
	my $login = getlogin || getpwuid($<);
	return "$tmp/wily$login$ENV{DISPLAY}";
}

	

1;
__END__

=head1 NAME

Wily::Connect - Connects to a running Wily text editor.

=head1 SYNOPSIS

  use Wily::Connect;
  my $wily_socket = Wily::Connect::connect();

=head1 DESCRIPTION

The connect sub connects to wily this involves creating a 
unix domain socket, listening on that socket, writing the
name of that socket to the fifo wily is reading from (either
$ENV{WILYFIFO} or if that doesn't exist
/tmp/wily[login]$ENV{DISPLAY}, and then accepting the
connection to the unix domain socket that wily will make.

The functions does all of that and hence may block while
waiting for wily.

=head1 SEE ALSO

perl(1), wily(1), Wily::Message.

http://sam.holden.id.au/software/plwily/

=head1 AUTHOR

Sam Holden E<lt>sam@holden.id.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Sam Holden


This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307, USA or visit their web page on the internet at
http://www.gnu.org/copyleft/gpl.html.

=cut
