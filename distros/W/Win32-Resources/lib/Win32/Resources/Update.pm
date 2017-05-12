package Win32::Resources::Update;

use strict;
use warnings;
use Win32::Resources;

our $VERSION = '0.02';

sub new {
	my $proto = shift;
	my $class = ref ($proto) || $proto || __PACKAGE__;
	my $self = bless {}, $class;

	my $param = $_[0];
	if (not ref $param) { $param = {@_}; }
	foreach my $key (keys %$param) {
		$self->{$key} = $param->{$key};
	}

	unless ($self->{filename}) { return undef; }

	$self->{_rsrc} = Win32::Resources::_BeginUpdateResource($self->{filename}, 0);

	if ($self->{_rsrc}) {
		return $self;
	} else {
		return undef;
	}
}

sub commit {
	my ($self) = @_;

	# We save paramaters
	my $param;
	foreach my $key (keys %$self) {
		$param->{$key} = $self->{$key};
	}

	# We destroy the old object
	undef($self);

	# We re-create a new object
	return __PACKAGE__->new($param);
}

sub updateResource {
	my $self = shift;

	my $param = $_[0];
	if (not ref $param) { $param = {@_}; }

	$param = Win32::Resources::_check_param($param);
	return undef unless ($param);

	$param->{language} = defined($param->{language}) ? Win32::Resources::_MakeLangId($param->{language}) : Win32::Resources::_MakeLangId();

	no warnings;
	return Win32::Resources::_UpdateResource($self->{_rsrc}, 
		$param->{type}, 
		$param->{name}, 
		$param->{language},
		defined($param->{data}) ? $param->{data} : undef, 
		defined($param->{data}) ? length($param->{data}) : 0, 
	);
}

sub deleteResource {
	my $self = shift;
	
	return $self->updateResource(@_);
}

sub setXPStyleOff {
	my ($self, $desc) = @_;

	return $self->updateResource(
		path => '24/1/1033',
		data => undef,
	);
}

sub setXPStyleOn {
	my ($self, $desc) = @_;

	my $data = qq|<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
      <assemblyIdentity
          processorArchitecture="x86"
          version="5.1.0.0"
          type="win32"
          name="$desc"
      />
      <description>$desc</description>
      <dependency>
          <dependentAssembly>
              <assemblyIdentity
                  type="win32"
                  name="Microsoft.Windows.Common-Controls"        
                  version="6.0.0.0"
                  publicKeyToken="6595b64144ccf1df"
                  language="*"
                  processorArchitecture="x86"
          />
      </dependentAssembly>
      </dependency>
  </assembly>
|;

	return $self->updateResource(
		path => '24/1/1033',
		data => $data,
	);
}

sub DESTROY {
	my ($self) = @_;

	if ($self->{_rsrc}) {
		Win32::Resources::_EndUpdateResource($self->{_rsrc}, 0);
	}
}

1;

__END__

=head1 NAME

Win32::Resources::Update - Update resources in a windows executable

=head1 SYNOPSIS

  use Win32::Resources::Update;

=head1 DESCRIPTION

Win32::Resources::Update can add, update and delete resources in a windows executable (.exe or .dll).

=head1 METHODS

=over 4

=item $exe = Win32::Resources::Update->new(filename)

Returns a new instance of a Win32::Resources::Update object.

filename: the .exe or .dll path

=item $exe->commit()

Commit all the changes and re-open the file to resume updating.

=item $exe->updateResource($args)

Add or replace a resource in the .exe or .dll file.

$args is the same style as in a Win32::Resources::LoadResource call.

There is one more parameter:
data: the data to put in the resource.

=item $exe->deleteResource($args)

Delete a resource.

=item $exe->setXPStyleOn($desc)

Add a XP manifest to the windows executable file.

$desc is the application description to include in the manifest.

=item $exe->setXPStyleOff()

Delete the XP manifest in the exe file.

=back

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system 
at http://rt.cpan.org/ or email to bug-Win32-Resources\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Resources is the RT queue for Win32::Resources.
Please check to see if your bug has already been reported. 

=head1 COPYRIGHT

Copyright 2004

Fabien Potencier, fabpot@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1), Win32::Exe, Win32::Resources.

=cut
