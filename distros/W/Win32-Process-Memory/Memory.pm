package Win32::Process::Memory;

use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION   = "0.20";
@EXPORT    = qw();
@EXPORT_OK = qw();

require XSLoader;
XSLoader::load( 'Win32::Process::Memory', $VERSION );

sub new {
	my $class = ref( $_[0] ) || $_[0];
	my $pargs = ref( $_[1] ) ? $_[1] : {};
	my $this = {};
	bless( $this, $class );

	# parser access, default is all
	my $access;
	unless ( defined( $pargs->{access} ) ) {
		$access = 0x0438;
	} else {
		$access = 0;
		$access |= 0x010 if $pargs->{access} =~ /read/;
		$access |= 0x028 if $pargs->{access} =~ /write/;
		$access |= 0x400 if $pargs->{access} =~ /query/;
		$access |= 0x438 if $pargs->{access} =~ /all/;
	}

	# get process handle by command line name
	if ( defined( $pargs->{name} ) ) {
		eval 'use Win32::Process::Info;';
		die "Win32::Process::Info is required to get process by name" if $@;
		$pargs->{name} = lc( $pargs->{name} );
		foreach ( Win32::Process::Info->new( '', 'NT' )->GetProcInfo ) {
			if ( lc( $_->{Name} ) eq $pargs->{name} ) {
				$pargs->{pid} = $_->{ProcessId};
				last;
			}
		}
	}

	# get process handle by pid
	if ( defined( $pargs->{pid} ) ) {
		my $hProcess = _OpenByPid( $pargs->{pid}, $access );
		$this->{hProcess} = $hProcess if $hProcess;
	}

	return $this;
}

sub DESTROY {
	my $this = shift;
	_CloseProcess( $this->{hProcess} ) if defined $this->{hProcess};
}

sub get_memlist { _GetMemoryList( $_[0]->{hProcess} ); }

sub get_memtotal {
	my $this    = shift;
	my %memlist = $this->get_memlist;
	my $sum     = 0;
	$sum += $_ foreach values %memlist;
	return $sum;
}

sub hexdump {
	my ( $this, $from, $len ) = @_;
	return "Err: length is too long!" if $len > 65536;

	# read buf
	my $buf;
	$this->get_buf( $from, $len, $buf );

	# caculate address
	my $addr    = $from - $from % 16;
	my $to      = $from + $len;
	my $addr_to = ( $to % 16 ) ? ( $to + 16 - $to % 16 ) : $to;

	# caculate hex string and show string
	my $buf_hex =
		  ( '  ' x ( $from - $addr ) )
		. uc( unpack( 'H*', $buf ) )
		. ( '  ' x ( $addr_to - $to ) );
	$buf_hex =~ s/\G(..)/$1 /g;
	my $buf_show =
		( ' ' x ( $from - $addr ) ) . $buf . ( ' ' x ( $addr_to - $to ) );
	$buf_show =~ s/[^a-z0-9\\|,.<>;:'\@[{\]}#`!"\$%^&*()_+=~?\/ -]/./gi;

	# output
	my $output = '';
	for ( my $offset = 0 ; $addr < $to ; $offset += 16, $addr += 16 ) {
		$output .= sprintf( "%08X : %s: %s\n",
			$addr,
			substr( $buf_hex,  $offset * 3, 48 ),
			substr( $buf_show, $offset,     16 ) );
	}
	return $output;
}

sub get_buf {
	my ( $this, $from, $len ) = ( shift, shift, shift );
	$_[0] = "" unless defined $_[0];
	return 0 unless defined $this->{hProcess};
	return _ReadMemory( $this->{hProcess}, $from, $len, $_[0] );
}

sub set_buf {
	my ( $this, $from ) = ( shift, shift );
	return 0 unless defined( $_[0] ) and defined( $this->{hProcess} );
	return _WriteMemory( $this->{hProcess}, $from, $_[0] );
}

sub get_pack {
	my ( $this, $packtype, $packunit_len, $from, $undef_val ) = @_;
	my $buf;
	$this->get_buf( $from, $packunit_len, $buf )
		? unpack( $packtype, $buf )
		: $undef_val;
}

sub set_pack {
	my ( $this, $packtype, $from ) = ( shift, shift, shift );
	$this->set_buf( $from, pack( $packtype, @_ ) );
}

sub get_packs {
	my ( $this, $packtype, $packunit_len, $from, $pack_nums, $undef_val ) = @_;
	my $buf;
	$pack_nums = 1 unless defined $pack_nums;
	return unpack( $packtype x $pack_nums, $buf )
		if $this->get_buf( $from, $packunit_len * $pack_nums, $buf );
	return wantarray ? () : $undef_val;
}

sub set_packs {
	my ( $this, $pack_type, $from ) = ( shift, shift, shift );
	$this->set_buf( $from, pack( $pack_type x scalar(@_), @_ ) );
}

sub get_i8     { shift->get_packs( "c", 1, @_ ); }
sub get_u8     { shift->get_packs( "C", 1, @_ ); }
sub get_i16    { shift->get_packs( "s", 2, @_ ); }
sub get_u16    { shift->get_packs( "S", 2, @_ ); }
sub get_i32    { shift->get_packs( "l", 4, @_ ); }
sub get_u32    { shift->get_packs( "L", 4, @_ ); }
sub get_float  { shift->get_packs( "f", 4, @_ ); }
sub get_double { shift->get_packs( "d", 8, @_ ); }
sub set_i8     { shift->set_packs( "c", @_ ); }
sub set_u8     { shift->set_packs( "C", @_ ); }
sub set_i16    { shift->set_packs( "s", @_ ); }
sub set_u16    { shift->set_packs( "S", @_ ); }
sub set_i32    { shift->set_packs( "l", @_ ); }
sub set_u32    { shift->set_packs( "L", @_ ); }
sub set_float  { shift->set_packs( "f", @_ ); }
sub set_double { shift->set_packs( "d", @_ ); }

sub search_range_sub {
	my ( $this, $from, $len, $pattern, $searchsub ) = @_;
	return unless defined $pattern;
	my $to      = $from + $len;
	my $step    = 0xE000;
	my $lenstep = $step + length($pattern) - 1;
	my $buf;
	for ( my $offset = $from ; $offset < $to ; $offset += $step ) {
		$len = ( $to - $offset < $lenstep ) ? $to - $offset : $lenstep;
		$this->get_buf( $offset, $len, $buf );
		while ( $buf =~ /$pattern/sg and $-[0] < $step ) {
			&$searchsub( $offset + $-[0] );
		}
	}
}

sub search_sub {
	my ( $this, $pattern, $searchsub ) = @_;
	return unless defined $pattern;
	my %memlist = $this->get_memlist;
	foreach ( sort { $a <=> $b } keys %memlist ) {
		$this->search_range_sub( $_, $memlist{$_}, $pattern, $searchsub );
	}
}

sub search_range_string {
	my @array = ();
	shift->search_range_sub( @_, sub { push @array, $_[0]; } );
	return @array;
}

sub search_range_string_hash {
	my %hash = ();
	shift->search_range_sub( @_, sub { $hash{$1} = $_[0]; } );
	return %hash;
}

sub search_string {
	my @array = ();
	shift->search_sub( @_, sub { push @array, $_[0]; } );
	return @array;
}

sub search_string_hash {
	my %hash = ();
	shift->search_sub( @_, sub { $hash{$1} = $_[0]; } );
	return %hash;
}

sub search_range_pack {
	my ( $this, $packtype, $from, $len ) = ( shift, shift, shift, shift );
	my $pattern = pack( $packtype, @_ );
	$pattern =
		sprintf( "\\x%02X" x length($pattern), unpack( "C*", $pattern ) );
	my @array = ();
	$this->search_range_sub( $from, $len, $pattern,
		sub { push @array, $_[0]; } );
	return @array;
}

sub search_range_packs {
	my ( $this, $packtype ) = ( shift, shift );
	$this->search_range_pack( $packtype x ( scalar(@_) - 1 ), @_ );
}

sub search_pack {
	my ( $this, $packtype ) = ( shift, shift );
	my $pattern = pack( $packtype, @_ );
	$pattern =
		sprintf( "\\x%02X" x length($pattern), unpack( "C*", $pattern ) );
	my @array = ();
	$this->search_sub( $pattern, sub { push @array, $_[0]; } );
	return @array;
}

sub search_packs {
	my ( $this, $packtype ) = ( shift, shift );
	$this->search_pack( $packtype x ( scalar(@_) - 1 ), @_ );
}

sub search_range_i8     { shift->search_range_packs( "c", @_ ); }
sub search_range_u8     { shift->search_range_packs( "C", @_ ); }
sub search_range_i16    { shift->search_range_packs( "s", @_ ); }
sub search_range_u16    { shift->search_range_packs( "S", @_ ); }
sub search_range_i32    { shift->search_range_packs( "l", @_ ); }
sub search_range_u32    { shift->search_range_packs( "L", @_ ); }
sub search_range_float  { shift->search_range_packs( "f", @_ ); }
sub search_range_double { shift->search_range_packs( "d", @_ ); }

sub search_i8     { shift->search_packs( "c", @_ ); }
sub search_u8     { shift->search_packs( "C", @_ ); }
sub search_i16    { shift->search_packs( "s", @_ ); }
sub search_u16    { shift->search_packs( "S", @_ ); }
sub search_i32    { shift->search_packs( "l", @_ ); }
sub search_u32    { shift->search_packs( "L", @_ ); }
sub search_float  { shift->search_packs( "f", @_ ); }
sub search_double { shift->search_packs( "d", @_ ); }

1;
__END__

=head1 NAME

Win32::Process::Memory - read and write memory of other windows process

=head1 SYNOPSIS

  # open process
  my $proc = Win32::Process::Memory->new({ name=>'cmd.exe' });

  # do debug
  printf "\nTotal Memory = 0x%X\n", $proc->get_memtotal;
  print "\nMemory block list:\n";
  my %memlist = $proc->get_memlist;
  printf "  %08X -> %08X : Len=0x%X\n", $_, $_+$memlist{$_}, $memlist{$_}
      foreach (sort {$a <=> $b} keys %memlist);
  print "\nContent of 0x10004 -> 0x10103\n";
  print $proc->hexdump(0x10004, 0x100);

  # search a sequence of unsigned int16
  print "\nFind a sequence of unsinged int16:\n";
  my @results = $proc->search_u16(92, 87, 105, 110, 51, 50);
  print $proc->hexdump($_, 0x32)."\n" foreach @results;

  # read and change value
  printf "\n0x%X [unsigned int16] : %d\n", 0x10004, $proc->get_u16(0x10004);
  printf "0x%X [unsigned int32] : %d\n", 0x10004, $proc->get_u32(0x10004);
  #$proc->set_u32(0x10004, 55); # BE CAREFUL, MAY DAMAGE YOUR SYSTEM

  # close process
  undef $proc;

=head1 DESCRIPTION

read and write memory of other windows process.

=item new

  $proc = Win32::Process::Memory->new({ pid=num, name=>str, access=>'read/write/query/all' });
  $proc = Win32::Process::Memory->new({ pid  => 1522 });
  $proc = Win32::Process::Memory->new({ name => 'cmd.exe' });
  $proc = Win32::Process::Memory->new({ pid  => 1522, access => 'read' });

=item get_memlist

  my %memlist = $proc->get_memlist;
  printf "  %08X -> %08X : Len=0x%X\n", $_, $_+$memlist{$_}, $memlist{$_}
      foreach (sort {$a <=> $b} keys %memlist);

=item get_memtotal

  printf "Commited Memory = %X Bytes\n", $proc->get_memtotal;

=item hexdump

  print $proc->hexdump($from, $len);

=item get

  $getbytes = $proc->get_buf($from, $len, $buf);
               # return 0 if failed
  $getvalue = $proc->get_pack($packtype, $packunit_len, $from, $undef_val);
               # return $undef_val if failed
  $getvalue = $proc->get_packs($packtype, $packunit_len, $from, $pack_nums, $undef_val);
  $getvalue = $proc->get_i8($from, $undef_val);
  $getvalue = $proc->get_u8($from, $undef_val);
  $getvalue = $proc->get_i16($from, $undef_val);
  $getvalue = $proc->get_u16($from, $undef_val);
  $getvalue = $proc->get_i32($from, $undef_val);
  $getvalue = $proc->get_u32($from, $undef_val);
  $getvalue = $proc->get_float($from, $undef_val);
  $getvalue = $proc->get_double($from, $undef_val);

=item set

  $setbytes = $proc->set_buf($from, $buf);
               # return 0 if failed
  $setbytes = $proc->set_pack($packtype, $from, ...);
  $setbytes = $proc->set_packs($packtype, $from, ...);
  $setbytes = $proc->set_i8($from, $undef_val);
  $setbytes = $proc->set_u8($from, $undef_val);
  $setbytes = $proc->set_i16($from, $undef_val);
  $setbytes = $proc->set_u16($from, $undef_val);
  $setbytes = $proc->set_i32($from, $undef_val);
  $setbytes = $proc->set_u32($from, $undef_val);
  $setbytes = $proc->set_float($from, $undef_val);
  $setbytes = $proc->set_double($from, $undef_val);

=item search

  Search all commited area of given process.
  $proc->search_sub($pattern, sub {...});
               # call sub when founded, $_[0] is the starting address of match
  @results = $proc->search_string($pattern);
               # return starting addresses of every match as an array
  %hash    = $proc->search_string_hash($patttern);
               # return hash, which key is $1 of match, and which value is starting address
  @results = $proc->search_pack($packtype, ...);
               # ... is the arguments of pack function
  @results = $proc->search_packs($packtype, ...);
               # ... is a list of 1 arguments of pack function
  @results = $proc->search_i8(48);
  @results = $proc->search_u8(48, 56, ...);
  @results = $proc->search_i16(48, 56, ...);
  @results = $proc->search_u16(48, 56, ...);
  @results = $proc->search_i32(48, 56, ...);
  @results = $proc->search_u32(48, 56, ...);
  @results = $proc->search_float(48, 56, ...);
  @results = $proc->search_double(48, 56, ...);

=item search_range

  Search a specific range ($from, $len). The caller should ensure that the range is valid.
  $proc->search_range_sub($from, $len, $pattern, sub {...});
               # call sub when founded, $_[0] is the start address of match
  @results = $proc->search_range_string($from, $len, $pattern);
               # return starting addresses of every match as an array
  %hash    = $proc->search_range_string_hash($from, $len, $patttern);
               # return hash, which key is $1 of match, and which value is starting address
  @results = $proc->search_range_pack($packtype, ...);
               # ... is the arguments of pack function
  @results = $proc->search_range_packs($packtype, ...);
               # ... is a list of 1 arguments of pack function
  @results = $proc->search_range_i8(48);
  @results = $proc->search_range_u8(48, 56, ...);
  @results = $proc->search_range_i16(48, 56, ...);
  @results = $proc->search_range_u16(48, 56, ...);
  @results = $proc->search_range_i32(48, 56, ...);
  @results = $proc->search_range_u32(48, 56, ...);
  @results = $proc->search_range_float(48, 56, ...);
  @results = $proc->search_range_double(48, 56, ...);

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
L<http://rt.cpan.org/NoAuth/ReportBug.html?Dist=Win32-Process-Memory>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
