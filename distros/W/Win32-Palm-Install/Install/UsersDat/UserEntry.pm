package Win32::Palm::Install::UsersDat::UserEntry;
$VERSION = 0.1;
use strict;
use Carp;
use vars '$AUTOLOAD';

=head1 NAME

Win32::Palm::Install::UsersDat::UserEntry - Class to hold user information

=cut


{
# Encapsulated class data

	my %attr_data = (
		_HotsyncID	=> 1,
		_LongName	=> 1,
		_DirName	=> 1,
		_Active		=> 1,
		_Password	=> 1
			);	
}

sub new {
	my ($proto, %args) = @_;
	my $class = ref($proto) || $proto;
	
	my $self = {
			_HotsyncID	=> $args{-HotsyncID},
			_LongName	=> $args{-LongName},
			_DirName	=> $args{-DirName},
			_Active		=> $args{-Active},
			_Password	=> $args{-Password}
		   };

	bless $self, $class;
}

sub AUTOLOAD {
	no strict 'refs';
	my ($self, $newval) = @_;

	return if $AUTOLOAD =~ /::DESTROY$/;

	# get_ method
	if ($AUTOLOAD =~ /.*::get(_\w+)/ )
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { return $_[0]->{$attr_name} };
		return $self->{$attr_name};
	}

	# set_ method
	if ($AUTOLOAD =~ /.*::set(_\w+)/ )
	{
		my $attr_name = $1;
		*{$AUTOLOAD} = sub { $_[0]->{$attr_name} = $_[1]; return };
		$self->{$attr_name} = $newval;
		return; 
	}
	croak "No such method: $AUTOLOAD";	
}

1;

=head1 VERSION

This document refers to version 0.2 of Win32::Palm::Install::UsersDat::UserEntry,
released 25 september 2001.

=head1 SYNOPSIS

	use Win32::Palm::Install::UsersDat::UserEntry;

	my $ue = Win32::Palm::Install::UserDat::UserEntry->new(
			-HotsyncID 	=> $hotsyncid,
			-LongName	=> $longname,
			-DirName	=> $dirname,
			-Active		=> $active,
			-Password	=> $password
	);

=head1 DESCRIPTION

A module to hold the information of a UserEntry in a users.dat file.

=head1 Class and Object methods

	get_HotsyncID / set_HotsyncID
	get_LongName / set_LongName
	get_Password / set_Password
	get_DirName / set_DirName
	get_Active / set_Activea

=head1 AUTHOR

Johan Van den Brande
<johan@vandenbrande.com>

=head1 COPYRIGHT

Copyright (c) 2001, Johan Van den Brande. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

