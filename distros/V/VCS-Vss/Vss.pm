package VCS::Vss;

use strict;
use vars qw($VERSION);
use VCS::Vss::Dir;
use VCS::Vss::File;
use VCS::Vss::Version;

$VERSION = '0.20';

my $vss;

sub _open_vss_db {
	my($self) = @_;

	my $vss = new Win32::OLE("SourceSafe.0");
	my $srcsafe_ini = $self->srcsafe_ini();
	$srcsafe_ini =~ s|/|\\|g;
 	$vss->Open($srcsafe_ini);

	if (!$vss->{SrcSafeIni}) {
		die "Couldn't open VSS database at: " . $self->srcsafe_ini() . "\n" . Win32::OLE::LastError;
	}

	$self->{vss} = $vss;
	return 1;
}

sub _vss_conn {
	my($self) = @_;
	unless($self->{vss}) {
		$self->_open_vss_db();
	}
	$vss = $self->{vss};
	return $self->{vss};
}

sub _fix_path {
	my ($self) = @_;
	my $new_path;
	
	# Remove ignored query portion of path
	$self->{PATH} =~ s/\?.+//;
	$self->{URL} =~ s/\?.+//;
	
	# Patch provided by Tim Hood <timhood40@yahoo.com> to handle spaces in URLs (taken from CGI unescape function)
	$self->{PATH} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

	($self->{SRCSAFE_INI}, $new_path) = $self->{PATH} =~ m|^/(.+)srcsafe.ini/(.+)|;
	if ($self->{SRCSAFE_INI}) {
		$self->{PATH} = '$/' . $new_path;
		$self->{SRCSAFE_INI} .= 'srcsafe.ini';
	}
	else {
		$self->{PATH} =~ s|^/||;
		$self->{PATH} = '$/' . $self->{PATH}; 
		$self->{SRCSAFE_INI} = $ENV{VSSROOT} . "/srcsafe.ini";
	}
    die ref($self) . "->new: " . $self->srcsafe_ini . " not a VSS ini file: $!"
        unless -f $self->srcsafe_ini;
	return 1;
}

sub _get_vss_item {
	my ($self) = @_;
	my $vss_item = $self->_vss_conn->VSSItem($self->path);
	if (!$vss_item) {
		die ref($self) . "->new: " . $self->path . " is not a valid VSS path for this database";
	}
	return $vss_item;
}

sub vss_object {
	my ($self) = @_;
	if (ref($self) eq 'VCS::Vss') {
		return $self->_vss_conn();
	}
	return $self->{vss_object} if $self->{vss_object};
	$self->{vss_object} = $self->_get_vss_item($self->path);
	return $self->{vss_object};
}

sub cleanup {
	$vss->Quit() if $vss;
}

sub srcsafe_ini {
	my ($self) = @_;
	return $self->{SRCSAFE_INI};
}

1;


__END__

=head1 NAME

VCS::Vss - notes for the Visual Source Safe implementation

=head1 ABSTRACT

Provides VCS-compatible interfaces that encapsulate Visual Source Safe Win32::OLE objects

=head1 SYNOPSIS

    $ENV{VSSROOT} = 'c:/vss/';
    use VCS;
    $file = VCS::File->new('vcs://localhost/VCS::Vss/source/project/Makefile');

=head1 DESCRIPTION

The system uses Win32::OLE to access the VSS repository, which means that this 
system will likely only ever run on Windows.  Each object has a special attribute 
named $object->{vss_object} that will give you access to the actual OLE objects 
that are encapsulated in the classes.

If you don't set the VSSROOT environment variable in Perl or in your shell, you 
can still pass it in as part of the url like this:

$file = VCS::File->new('vcs://localhost/VCS::Vss/c:/myVSS/srcsafe.ini/source/project/Makefile');

Consider this format as having an additional piece of information in the path that 
points the system to the correct database when there is no default.  You can also 
override the VSSROOT value by using this format.

=head1 AVAILABILITY

VCS::Vss is not currently part of the main VCS distribution.  You have to download it 
from CPAN separately.

=head1 COPYRIGHT

Copyright (c) 2002 James Tillman <jtillman@bigfoot.com>. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<VCS>.

=cut
