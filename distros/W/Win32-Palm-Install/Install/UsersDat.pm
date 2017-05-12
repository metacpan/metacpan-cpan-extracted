package Win32::Palm::Install::UsersDat;
use Carp;
use strict;
use Win32::Palm::Install::UsersDat::UserEntry;
use vars qw( $DEBUG );

# $DEBUG++;

=head1 NAME

Win32::Palm::Install::UsersDat - Parser for the users.dat file for Palm

=cut

sub new {
	my $proto = shift;
	my (@args) = @_;
	my $class = ref($proto) || $proto;

	my $self = { 
		_Filename 	=> $args[0],
		_UserEntries 	=> [],
		_UserCount	=> 0
		  };

	bless $self, $class;
	$self->_parse();
	return $self;
}

sub get_UserCount {
	return $_[0]->{_UserCount};
}

sub set_UserCount {
	$_[0]->{_UserCount} = $_[1];
}

sub get_Filename {
	return $_[0]->{_Filename};
}

sub add_UserEntry {
	my $self = shift;

	my $ue = Win32::Palm::Install::UsersDat::UserEntry->new( @_ );
	
	push @{$self->{_UserEntries}}, $ue;

	return $ue;
}

sub get_UserEntry {
	my ($self, $index) = @_;

	return wantarray?@{$self->{_UserEntries}}:${$self->{_UserEntries}}[$index];
}

sub _parse {
	my $self = shift;
	my ($buffer, $readlen);

	# Open up file
	local *F;
	open F, $self->get_Filename() or croak "No such file ... ($!)";
	binmode F;

	# Get user count
	$buffer = "";
	$readlen = read(F, $buffer, 2 );
	croak "Error on user count" if $readlen != 2;

	my $usercount = unpack "S", $buffer;
	$DEBUG && print "usercount : $usercount\n";
	$self->set_UserCount( $usercount );

	# Skip class entry if nesessary
	$buffer = "";
	$readlen = read(F, $buffer, 2 );
	croak "Error on class flag" if $readlen != 2;
	
	if ( unpack( "S", $buffer ) == 0xffff ) {
		$buffer = "";
		$readlen = read(F, $buffer, 2);
		$readlen = read(F, $buffer, 2);	
		my $len = unpack "S", $buffer;
		$readlen = read(F, $buffer, $len);	
	}

	for (my $i=0; $i<$self->get_UserCount(); $i++) {
		# hotsync ID
		$buffer = "";
		read( F, $buffer, 4 );
		my $hotsyncid = unpack "L", $buffer;
		$DEBUG && printf("hotsyncid: %x\n", $hotsyncid);	

		# full name
		$buffer = "";
		read( F, $buffer, 1 );
		my $len = unpack "C", $buffer;
		$DEBUG && print "$len\n";
		$buffer = "";
		read( F, $buffer, $len );
		my $longname = $buffer;
		$DEBUG && print "longname : $longname\n";		

		# dir name
		$buffer = "";
		read( F, $buffer, 1 );
		$len = unpack "C", $buffer;
		$buffer = "";
		read( F, $buffer, $len );
		my $dirname = $buffer;
		$DEBUG && print "dirname : $dirname\n";

		# Active
		$buffer = "";
		read( F, $buffer, 2);
		my $active = unpack "S", $buffer;
		$DEBUG && print "active: $active\n";

		# password
		$buffer = "";
		read( F, $buffer, 2 );
		$len = unpack "S", $buffer;
		read( F, $buffer, 2 );
		$buffer = "";
		read( F, $buffer, $len );
		my $password = $buffer;
		$DEBUG && print "password: $password\n";
		read( F, $buffer, 2 );

		read( F, $buffer, 2 );
		my $type = unpack "S", $buffer;
		# Class entry, no more data or conduit entries
		$DEBUG && print ":: $type\n";

		if ( $type == 0xffff ) {
			# skip constant
			$buffer = "";
			read(F, $buffer, 2 );
			# read length of classname
			$buffer = "";
			read(F, $buffer, 2 );
			my $len = unpack "S", $buffer;
			# read in classname
			$buffer= "";
			read(F, $buffer, $len ); 
			$DEBUG && print "classname : $buffer\n";
			
		}
		#  skip until 0x8001 or EOF
		$buffer = "";
		do {
			$readlen = read( F, $buffer, 2 );
		} while ( $readlen && unpack("S", $buffer) != 0x8001 );

		$self->add_UserEntry(	-HotsyncID 	=> $hotsyncid,
					-LongName	=> $longname,
					-DirName	=> $dirname,
					-Active		=> $active,
					-Password	=> $password
					);
	}

	# Close file
	close F;	
}

1;

=head1 VERSION

This document refers to version 0.2 of Win32::Palm::Install::UsersDat,
released 25 september 2001.

=head1 SYNOPSIS

	use Win32::Palm::Install::UsersDat;
	my $ud = Win32::Palm::Install::UsersDat->new( 'c:\Palm\users.dat' );

	foreach my $ue ( $ud->get_UserEntry() ) {
		print $ue->get_LongName . "\n";
		map {
			my $func = "get_$_";
			print "\t" . lc($_) . ": " . $ue->$func() . "\n";
		} qw( HotsyncID DirName Active Password );
	}

=head1 DESCRIPTION

Based upon the text found on: 
 http://www.geocities.com/Heartland/Acres/3216/users_dat.htm

Will parse a users.dat file and extract some information out of it.
Only user information is extracted for the moment!

=head2 Constructor and initialisation

	Win32::Palm::Install::UserDat->new( $filename );

=head2 Class and Object methods

	my $ud = Win32::Palm::Install::UserDat->new( $filename );

	$ud->get_UserCount()
	
	@UserEntries = $ud->get_UserEntry()
	$UserEntry = $ud->get_UserEntry($index)

=head1 FILES

	Win32::Palm::Install::UsersDat::UserEntry

=head1 AUTHOR

Johan Van den Brande
<johan@vandenbrande.com>

=head1 COPYRIGHT

Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

