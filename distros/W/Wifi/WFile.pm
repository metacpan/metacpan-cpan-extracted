package Wifi::WFile;
use strict;

my @listConfigNet = qw(IFCONFIG IWCONFIG ROUTE DEV ESSID RATE CHANNEL KEY ALG IP NETMASK GATEWAY);

my @listConfigMod = qw(MODULE FIRMWARE DEBUG INSMOD RMMOD LSMOD);

sub new{
	my($class) = shift;
	my($self) = {};
	
	bless($self,$class);

	if(@_){
		my(%arg) = @_;
		$self->{FICHIER} = $arg{'file'} if exists $arg{'file'};
	}
	
	$self->{CONFIGNET} = {};
	$self->{CONFIGMOD} = {};
	
	#INIT VALUE
	foreach(@listConfigNet){
		$self->{CONFIGNET}{$_} = undef;
	}
	foreach(@listConfigMod){
		$self->{CONFIGMOD}{$_} = undef;
	}
	return $self;
}

sub load{
	my($self) = @_;
	my(@ligne);
	
	open(FICHIER,$self->{FICHIER}) || die "Impossbile d'ouvrir $self->{FICHIER} : $!";

	while(<FICHIER>){
		@ligne = split(/\s+/);
		if($#ligne > 0){
			foreach(@listConfigNet){
				if($ligne[0] =~ /^$_\b/){
					$self->{CONFIGNET}{$_} = $ligne[1];
				}
			}
			foreach(@listConfigMod){
				if($ligne[0] =~ /^$_\b/){
					$self->{CONFIGMOD}{$_} = $ligne[1];
				}
			}
		}
	}
	
	#foreach(@listConfig){
	#	print "$_ : $self->{CONFIG}{$_}\n";
	#}
	
	print "+ Chargement $self->{FICHIER}\n";
	close(FICHIER);
}
1;

=head1 NAME 

Wifi::WFile - A class for parsing a file config

=head1 SYNOPSIS

use Wifi::WFile;

$config = Wifi::WFile->new("PATH_FILE");

$config->load;

=head1 DESCRIPTION

Wifi::WFile is used by Wifi::Manage for parsing files config

=head1 METHOD DESCRIPTIONS 

This sections contains only the methods in WFile.pm itself.

=over

=item *

load();

Load the config file

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
