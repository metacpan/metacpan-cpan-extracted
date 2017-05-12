package Win32::Resources;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	LoadResource
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Win32::Resources', $VERSION);

sub LoadResource {
	my $param = $_[0];
	if (not ref $param) { $param = {@_}; }

	$param = _check_param($param);
	return undef unless ($param);

	$param->{language} = defined($param->{language}) ? Win32::Resources::_MakeLangId($param->{language}) : Win32::Resources::_MakeLangId();

	return _LoadResource(
		$param->{filename} || '',
		$param->{type}, 
		$param->{name}, 
		$param->{language},
	);
}

sub _check_param {
	my ($param) = @_;

	if ($param->{file}) {
		open(F, "<$param->{file}") or return undef;
		binmode(F);
		{ local $/; $param->{data} = <F>; }
		close(F);
	}

	if (defined($param->{path})) {
		($param->{type}, $param->{name}, $param->{language}) = split m#/#, $param->{path};
	}

	$param->{type} = _get_rt($param->{type});

	return undef unless ($param->{name});
	return undef unless ($param->{type});

	$param->{name} = uc($param->{name});
	$param->{type} = uc($param->{type});

	if ($param->{name} =~ /^\d+$/) {
		$param->{name} = int($param->{name});
	}
	if ($param->{type} =~ /^\d+$/) {
		$param->{type} = int($param->{type});
	}
	if (defined($param->{language}) and ($param->{language} =~ /^\d+$/)) {
		$param->{language} = int($param->{language});
	}

	return $param;
}

sub _get_rt {
	my ($name) = @_;

	my $rt = {
		RT_CURSOR => 1,
		RT_BITMAP => 2,
		RT_ICON => 3,
		RT_MENU => 4,
		RT_DIALOG => 5,
		RT_STRING => 6,
		RT_FONTDIR => 7,
		RT_FONT => 8,
		RT_ACCELERATOR => 9,
		RT_RCDATA => 10,
		RT_MESSAGETABLE => 11,
		DIFFERENCE => 11,
		RT_GROUP_CURSOR => 12, # (RT_CURSOR + DIFFERENCE)
		RT_GROUP_ICON => 14, # (RT_ICON + DIFFERENCE)
		RT_VERSION => 16,
		RT_DLGINCLUDE => 17,
		RT_PLUGPLAY => 19,
		RT_VXD => 20,
		RT_ANICURSOR => 21,
		RT_ANIICON => 22,
		RT_HTML => 23,
	};

	if (defined($rt->{$name})) {
		return $rt->{$name};
	} elsif (defined($rt->{"RT_$name"})) {
		return $rt->{"RT_$name"};
	} else {
		return $name;
	}
}

1;

__END__

=head1 NAME

Win32::Resources - Manipulate windows executable resources

=head1 SYNOPSIS

  use Win32::Resources;
  my $data = Win32::Resources::LoadResource(
    filename => 'test.exe',
    type => RT_RCDATA,
    name => 'bar',
    language => '0',
  );

=head1 DESCRIPTION

Win32::Resources allows you to deal with windows executable (.exe or .dll) resources
(load, update and delete resources).

Resources can be icons, version information, binary datas, ...

To update resources, please see Win32::Resources::Update.

If you want to add an icon to your exe or change version information,
it is easier with Win32::Exe.

=head2 EXPORT

None by default.

=head1 METHODS

=over 4

=item LoadResource($args)

LoadResource return the content of a resource included in an exe file.

$args is a hash ref with the following parameters:
filename: .exe to load resource from. Can be undef if you want to load a resource from the caller exe
(perl.exe if you launch your script fromcommand line or xxx.exe if you made a PAR executable).
type: type of resource (RT_RCDATA, ...). Can be the string or its integer representation.
For example, you can specify RT_RCDATA, RCDATA or 10 as you wish.
name: resource name.
language: language id (optional).

You can specify a path parameter as a shortcut to the triplet type, name and language in one shot: type/name/language.

The following call is the same:

  LoadResource(path => 'RCDATA/FOO/0');
  LoadResource(type => 'RCDATA', name => 'FOO', language => '0');

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

perl(1), Win32::Exe, Win32::Resources::Update.

=cut
