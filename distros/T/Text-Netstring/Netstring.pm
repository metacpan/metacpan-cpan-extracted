package Text::Netstring;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

#
# Copyright (c) 2003-2006 James Raftery <james@now.ie>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# Please submit bug reports, patches and comments to the author.
# Latest information at http://romana.now.ie/
#
# $Id: Netstring.pm,v 1.13 2006/11/20 18:28:49 james Exp $
#
# See the Text::Netstring man page that was installed with this module for
# information on how to use the module.
#

@ISA = qw(Exporter);
# Items to export into caller's namespace by request.
@EXPORT_OK = qw(
	netstring_encode netstring_decode netstring_verify netstring_read
);

$VERSION = '0.07';


sub netstring_encode {

	# is argument a list reference?
	@_ = @{$_[0]} if (scalar(@_)==1 and ref($_[0]) eq "ARRAY");

	my @enc = map { length($_).":${_}," } @_;
	wantarray ? @enc : join("", @enc);
}

sub netstring_decode {

	# is argument a list reference?
	@_ = @{$_[0]} if (scalar(@_)==1 and ref($_[0]) eq "ARRAY");

	my @dec = map { /^(\d+):(.*),$/s and length($2)==$1 ? $2 : "" } @_;
	wantarray ? @dec : join("", @dec);
}

sub netstring_verify {

	# is argument a list reference?
	@_ = @{$_[0]} if (scalar(@_)== 1 and ref($_[0]) eq "ARRAY");

	my @ver = map { /^(\d+):(.*),$/s and length($2)==$1 } @_;
	wantarray ? @ver : do { my $i=shift(@ver); foreach (@ver) {$i &&= $_}; $i };
}

sub netstring_read {
	my $sock = shift or return undef;

	my($r, $ns);
	my $s = "";
	my $len = 0;

	# read the length
	for (;;) {
		defined($r = read($sock, $s, 1)) or return undef;

		return "" if !$r;
		last if $s eq ":";
		return undef if $s !~ /^[0-9]$/;

		$len = 10 * $len + $s;
		return undef if $len > 200000000;
	}

	$ns = $len . ":";
	$s = "";

	# read the string 'body'
	defined($r = read($sock, $s, $len)) or return undef;
	return "" if (!$r and $len != 0);	# zero length is OK
	$ns .= $s;

	# read the trailing comma
	defined($r = read($sock, $s, 1)) or return undef;
	return "" if !$r;
	return undef if $s ne ",";
	$ns .= $s;

	return $ns;
}

1;

__END__

=head1 NAME

Text::Netstring - Perl module for manipulation of netstrings

=head1 SYNOPSIS

 use Text::Netstring qw(netstring_encode netstring_decode
 	netstring_verify netstring_read);

 $ns = netstring_encode($text);
 @ns = netstring_encode(@text);
 $ns = netstring_encode(@text);

 $text = netstring_decode($ns);
 @text = netstring_decode(@ns);
 $text = netstring_decode(@ns);

 $valid = netstring_verify($string);
 @valid = netstring_verify(@string);
 $valid = netstring_verify(@string);

 $ns = netstring_read($socket);

=head1 DESCRIPTION

This module is a collection of functions to make use of netstrings in
your perl programs. A I<netstring> is a string encoding used by, at
least, the QMTP and QMQP email protocols.

=over 4

=item netstring_encode()

Encode the argument string, list of strings, or referenced list of
strings as a netstring.

Supplying a scalar argument in a scalar context, or a list or list
reference argument in list context, does what you'd expect; encoding the
scalar or each element of the list as appropriate. Supplying a list or
list reference argument in a scalar context, however, returns a single
scalar which is the concatenation of each element of the list encoded as
a netstring.

=item netstring_decode()

Decode the argument netstring, list of netstrings, or referenced list of
netstrings returning the I<interpretation> of each. You should use 
C<netstring_verify()> over any data before you try to decode it. An
invalid netstring will be returned as an empty string.

The same scalar/list context handling as for netstring_encode() applies.

=item netstring_verify()

Check the validity of the supplied netstring, list of netstrings or
referenced list of netstrings. Returns a C<TRUE> or C<FALSE> value, or
list of same, as appropriate. Supplying a list argument in a scalar
context will return a single boolean value which is C<TRUE> if and only
if each element of the argument list was successfully verified,
otherwise it's C<FALSE>.

=item netstring_read()

Read the next netstring from a socket reference supplied as an argument.
The function returns a scalar which is the netstring read from the
socket. You will need to use netstring_decode() on the return value to
obtain the string I<interpretation>. Returns undef in case of an error,
or an empty string ("") if a premature EOF was encountered.

This function will regard a netstring claiming to be larger than
200,000,000 characters as an error, yielding undef.

=back

=head1 EXAMPLES

 use Text::Netstring qw(netstring_encode netstring_decode);

 @s = ("foo", "bar");
 $t = netstring_encode( scalar netstring_encode(@s) );

C<12:3:foo,3:bar,,> is the value of C<$t>

 $s = ["5:whizz," , "4:bang,"];
 $t = netstring_decode($s);

C<whizzbang> is the value of C<$t>

=head1 NOTES

The format of a netstring is described in http://cr.yp.to/proto/qmtp.txt

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. (Being a speaker of British english,
I'd call it a "licence" though)

=head1 AUTHOR

James Raftery <james@now.ie>.

=cut
