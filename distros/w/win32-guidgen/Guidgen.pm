package Win32::Guidgen;

#require 5.005_62;
require Win32::API;

use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Guidgen ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
create
);
our $VERSION = '0.04';

sub create {
    return _gen();
}

sub gen {
    return _gen();
}

sub generate {
	return _gen();
}

sub _gen {
    my $UuidCreate = new Win32::API('rpcrt4', 'UuidCreate', 'P', 'N');
    die 'Could not load UuidCreate from rpcrt4.dll' unless $UuidCreate;
    
    my $UuidToString = new Win32::API('rpcrt4', 'UuidToString', 'PP', 'N');
    die 'Could not load UuidToString from rpcrt4.dll' unless $UuidToString;
    
    my $RpcStringFree = new Win32::API('rpcrt4', 'RpcStringFree', 'P', 'N');
    die 'Could not load RpcStringFree from rpcrt4.dll' unless $RpcStringFree;
 
    my $uuid = "*" x 16; # Allocate enough space to store the uuid structure
    
    my $ret = $UuidCreate->Call( $uuid );
    die "UuidCreate failed with error: $ret" unless $ret == 0;
 
    my $ptr_str = pack("P",0);
    $ret = $UuidToString->Call( $uuid, $ptr_str );
    die "UuidToString failed with error: $ret" unless $ret == 0;
 
    my $guid_str = unpack( "p", $ptr_str );
 
    $ret = $RpcStringFree->Call( $ptr_str );
    die "RpcStringFree failed with error: $ret" unless $ret == 0;
 
    return '{' . uc($guid_str) . '}';
}

1;
__END__

=head1 NAME

Win32::Guidgen - Perl extension that generates GUID strings.

=head1 SYNOPSIS

	use strict;
	use Win32::Guidgen;

	my $guid = Win32::Guidgen::create();
	print "New GUID is $guid\n";
	
    my $guid = Win32::Guidgen::gen();
	print "New GUID is $guid\n";
	
    my $guid = Win32::Guidgen::generate();
	print "New GUID is $guid\n";

=head1 DESCRIPTION

Win32::Guidgen generate Generates Globally Unique Identifiers (B<GUIDs>).

It exposes 3 methods: C<create()>, C<gen()> and C<generate()>, which all return a string formatted like the following sample:

{C200E360-38C5-11CE-AE62-08002B2B79EF} 

where the successive fields break the B<GUID> into the form C<DWORD>-C<WORD>-C<WORD>-C<WORD>-C<WORD>.C<DWORD> covering the 128-bit B<GUID>. 
The string includes enclosing braces, which are an OLE convention.

=head2 EXPORT

None by default.

=head1 INSTALLATION

You install C<Win32::Guidgen>, as you would install any perl module library,
by running these commands:

	perl Makefile.PL
	make
	make test
	make install


=head1 AUTHOR

C<Win32::Guidgen> was written by Joe P. Hayes I<E<lt>joephayes@_NOSPAM_yahoo.comE<gt>> (Take out '_NOSPAM_', to send.) in 2001.
Neil Hunt I<E<lt>neilh@_NOSPAM_thehunts.id.au<gt>>> contributed a new version of the GUID generator in 2004.

=head1 LICENSE

The C<Win32::Guidgen> module is Copyright (c) 2001 Joe P. Hayes.
All Rights Reserved.

You may distribute under the terms of either the GNU General Public License or the
Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

The C<Win32::Guidgen> module is free software.

B<IT COMES WITHOUT WARRANTY OF ANY KIND.>

Commercial support for Perl can be arranged via The Perl Clinic.
For more details visit:

  http://www.perlclinic.com

=cut
