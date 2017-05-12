package WiX3::XML::Component;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _STRING _IDENTIFIER );
use WiX3::Types qw( YesNoType ComponentGuidType );
use WiX3::XML::TagTypes qw( ComponentChildTag );
use MooseX::Types::Moose qw( Str Maybe Int ArrayRef Undef );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_component.htm

with qw(WiX3::XML::Role::TagAllowsChildTags
  WiX3::XML::Role::GeneratesGUID
  WiX3::Role::Traceable
);

## Environment, File, RegistryKey, RegistryValue, RemoveFolder, Shortcut
## are ComponentChildTags at the moment.

has '+child_tags' => ( isa => ArrayRef [ComponentChildTag] );

## Allows lots of children: Choice of elements AppId, Category, Class,
## Condition, CopyFile, CreateFolder, Environment, Extension, File, IniFile,
## Interface, IsolateComponent, ODBCDataSource, ODBCDriver, ODBCTranslator,
## ProgId, Registry, RegistryKey, RegistryValue, RemoveFile, RemoveFolder,
## RemoveRegistryKey, RemoveRegistryValue, ReserveCost, ServiceConfig,
## ServiceConfigFailureActions, ServiceControl, ServiceInstall, Shortcut,
## SymbolPath, TypeLib

#####################################################################
# Accessors:

has id => (
	is      => 'ro',
	isa     => Str,
	reader  => 'get_id',
	builder => 'id_build',
	lazy    => 1,
);

has complusflags => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_complusflags',
	default => undef,
);

has directory => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_directory',
	default => undef,
);

# DisableRegistryReflection requires Windows Installer 4.0

has disableregistryreflection => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_disableregistryreflection',
	default => undef,
	coerce  => 1,
);

has diskid => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_diskid',
	default => undef,
);

has feature => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_feature',
	default => undef,
);

has guid => (
	is       => 'ro',
	isa      => ComponentGuidType,
	reader   => 'get_guid',
	lazy     => 1,
	init_arg => undef,
	builder  => 'guid_build',
);

has keypath => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_keypath',
	default => undef,
	coerce  => 1,
);

has location => (
	is      => 'ro',
	isa     => Maybe [Str],            # Enum: 'local', 'source', 'network'
	reader  => '_get_location',
	default => undef,
);

has neveroverwrite => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_neveroverwrite',
	default => undef,
	coerce  => 1,
);

has path => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => 'get_path',
	default => undef,
);

has permanent => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_permanent',
	default => undef,
	coerce  => 1,
);

# Shared requires Windows Installer 4.5

has shared => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_shared',
	default => undef,
	coerce  => 1,
);

has shareddllrefcount => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_shareddllrefcount',
	default => undef,
	coerce  => 1,
);

has transitive => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_transitive',
	default => undef,
	coerce  => 1,
);

# UninstallWhenSuperceded requires Windows Installer 4.5

has uninstallwhensuperceded => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_uninstallwhensuperceded',
	default => undef,
	coerce  => 1,
);

has win64 => (
	is      => 'ro',
	isa     => YesNoType | Undef,
	reader  => '_get_win64',
	default => undef,
	coerce  => 1,
);

#####################################################################
# Methods to implement the Tag role.

sub BUILDARGS {
	my $class = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = @_;
	} else {
		WiX3::Exception::Parameter::Odd->throw("$class->new");
	}

	if ( defined $args{'guid'} ) {

		# TODO: Throw exception.
	}

	if ( not( defined $args{'id'} or defined $args{'path'} ) ) {
		WiX3::Exception::Parameter->throw(
			"Either id or path required in $class->new");
	}

	if ( defined $args{id} and not defined _IDENTIFIER("C_$args{id}") ) {
		print "Invalid ID: $args{id}\n";
		WiX3::Exception::Parameter::Invalid->throw('id');
	}


	return \%args;
} ## end sub BUILDARGS

sub as_string {
	my $self = shift;

	my $children     = $self->has_child_tags();
	my $child_string = $self->as_string_children();
	my $id           = 'C_' . $self->get_id();


	my $string;
	$string = '<Component';

	my @attribute = (
		[ 'Id'           => $id, ],
		[ 'Guid'         => $self->get_guid(), ],
		[ 'ComPlusFlags' => $self->_get_complusflags(), ],
		[ 'Directory'    => $self->_get_directory(), ],
		[   'DisableRegistryReflection' =>
			  $self->_get_disableregistryreflection(),
		],
		[ 'DiskId'            => $self->_get_diskid(), ],
		[ 'Feature'           => $self->_get_feature(), ],
		[ 'Keypath'           => $self->_get_keypath(), ],
		[ 'Location'          => $self->_get_location(), ],
		[ 'NeverOverwrite'    => $self->_get_neveroverwrite(), ],
		[ 'Permanent'         => $self->_get_permanent(), ],
		[ 'Shared'            => $self->_get_shared(), ],
		[ 'SharedDllRefCount' => $self->_get_shareddllrefcount(), ],
		[ 'Transitive'        => $self->_get_transitive(), ],
		[   'UninstallWhenSuperceded' =>
			  $self->_get_uninstallwhensuperceded(),
		],
		[ 'Win64' => $self->_get_win64(), ],
	);

	my ( $k, $v );

	foreach my $ref (@attribute) {
		( $k, $v ) = @{$ref};
		$string .= $self->print_attribute( $k, $v );
	}

	if ($children) {
		$string .= qq{>\n$child_string\n</Component>\n};
	} else {
		$string .= qq{ />\n};
	}

	return $string;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

#####################################################################
# Other methods.

sub get_directory_id {
	my $self = shift;
	my $id   = $self->get_id();

	if ( $self->noprefix() ) {
		return $id;
	} else {
		return "D_$id";
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WiX3::XML::Component - Defines a Component tag.

=head1 VERSION

This document describes WiX3::XML::Component version 0.009100

=head1 SYNOPSIS

	my $component = new WiX3::XML::Component(
		id => 'MyComponent',
		
	);

  
=head1 DESCRIPTION

TODO

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

TODO

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://wix.sourceforge.net/>

=head1 LICENCE AND COPYRIGHT

Copyright 2009, 2010 Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.1 itself. See L<perlartistic|perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

