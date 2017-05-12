package WiX3::XML::File;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use WiX3::Types qw( YesNoType PositiveInt NonNegativeInt );
use WiX3::XML::TagTypes qw( ShortcutTag );
use MooseX::Types::Moose qw( Str Maybe Int ArrayRef );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

with 'WiX3::XML::Role::TagAllowsChildTags';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_file.htm

# Allows child tags (WiX namespace:) AppId, AssemblyName, Class, CopyFile,
# ODBCDriver, ODBCTranslator, Permission, PermissionEx, Shortcut, SymbolPath,
# TypeLib

has '+child_tags' => ( isa => ArrayRef [ShortcutTag] );


#####################################################################
# Attributes:

has _assembly => (
	is       => 'ro',
	isa      => Maybe [Str],           # '.net', 'no', or 'win32'
	reader   => '_get_assembly',
	init_arg => 'assembly',
	default  => undef,
);

has _assemblyapplication => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_assemblyapplication',
	init_arg => 'assemblyapplication',
	default  => undef,
);

has _assemblymanifest => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_assemblymanifest',
	init_arg => 'assemblymanifest',
	default  => undef,
);

has _bindpath => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_bindpath',
	init_arg => 'bindpath',
	default  => undef,
);

has _checksum => (
	is       => 'ro',
	isa      => Maybe [YesNoType],     # Becomes yes/no.
	reader   => '_get_checksum',
	init_arg => 'checksum',
	default  => undef,
);

has _companionfile => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_companionfile',
	init_arg => 'companionfile',
	default  => undef,
);

has _compressed => (
	is       => 'ro',
	isa      => Maybe [Str],           #'yes', 'no', or 'default'
	reader   => '_get_compressed',
	init_arg => 'compressed',
	default  => undef,
);

has _defaultlanguage => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_defaultlanguage',
	init_arg => 'defaultlanguage',
	default  => undef,
);

has _defaultsize => (
	is       => 'ro',
	isa      => Maybe [NonNegativeInt],
	reader   => '_get_defaultsize',
	init_arg => 'defaultsize',
	default  => undef,
);

has _defaultversion => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_defaultversion',
	init_arg => 'defaultversion',
	default  => undef,
);

has _diskid => (
	is       => 'ro',
	isa      => Maybe [PositiveInt],
	reader   => '_get_diskid',
	init_arg => 'diskid',
	default  => undef,
);

has _fonttitle => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_fonttitle',
	init_arg => 'fonttitle',
	default  => undef,
);

has _hidden => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_hidden',
	init_arg => 'hidden',
	default  => undef,
);

has id => (
	is      => 'ro',
	isa     => Str,
	reader  => 'get_id',
	default => undef,
);

has _keypath => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_keypath',
	init_arg => 'keypath',
	default  => undef,
);

has name => (
	is      => 'ro',
	isa     => Maybe [Str],            # LongNameFileType
	reader  => 'get_name',
	default => undef,
);

has _patchallowignoreonerror => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_patchallowignoreonerror',
	init_arg => 'patchallowignoreonerror',
	default  => undef,
);

has _patchignore => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_patchignore',
	init_arg => 'patchignore',
	default  => undef,
);

has _patchwholefile => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_patchwholefile',
	init_arg => 'patchwholefile',
	default  => undef,
);

has _patchgroup => (
	is       => 'ro',
	isa      => Maybe [PositiveInt],
	reader   => '_get_patchgroup',
	init_arg => 'patchgroup',
	default  => undef,
);

has _processorarchitecture => (
	is     => 'ro',
	isa    => Maybe [Str],             # 'msil', 'x86', 'x64', or 'ia64'
	reader => '_get_processorarchitecture',
	init_arg => 'processorarchitecture',
	default  => undef,
);

has _readonly => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_readonly',
	init_arg => 'readonly',
	default  => undef,
);

has _selfregcost => (
	is       => 'ro',
	isa      => Maybe [Int],
	reader   => '_get_selfregcost',
	init_arg => 'selfregcost',
	default  => undef,
);

has _shortname => (
	is       => 'ro',
	isa      => Maybe [Str],           # ShortFileNameType
	reader   => '_get_shortname',
	init_arg => 'shortname',
	default  => undef,
);

has _source => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_source',
	init_arg => 'source',
	default  => undef,
);

has _system => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_system',
	init_arg => 'system',
	default  => undef,
);
has _truetype => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_truetype',
	init_arg => 'truetype',
	default  => undef,
);

has _vital => (
	is       => 'ro',
	isa      => Maybe [YesNoType],
	reader   => '_get_vital',
	init_arg => 'vital',
	default  => undef,
);

#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $children = $self->has_child_tags();
	my $tags;
	$tags = $self->print_attribute( 'Id', 'F_' . $self->get_id() );
	$tags .= $self->print_attribute( 'Name',     $self->get_name() );
	$tags .= $self->print_attribute( 'DiskId',   $self->_get_diskid() );
	$tags .= $self->print_attribute( 'Assembly', $self->_get_assembly() );
	$tags .=
	  $self->print_attribute( 'AssemblyApplication',
		$self->_get_assemblyapplication() );
	$tags .=
	  $self->print_attribute( 'AssemblyManifest',
		$self->_get_assemblymanifest() );
	$tags .= $self->print_attribute( 'BindPath', $self->_get_bindpath() );
	$tags .= $self->print_attribute( 'Checksum', $self->_get_checksum() );
	$tags .=
	  $self->print_attribute( 'CompanionFile',
		$self->_get_companionfile() );
	$tags .=
	  $self->print_attribute( 'Compressed', $self->_get_compressed() );
	$tags .=
	  $self->print_attribute( 'DefaultLanguage',
		$self->_get_defaultlanguage() );
	$tags .=
	  $self->print_attribute( 'DefaultSize', $self->_get_defaultsize() );
	$tags .=
	  $self->print_attribute( 'DefaultVersion',
		$self->_get_defaultversion() );
	$tags .= $self->print_attribute( 'FontTitle', $self->_get_fonttitle() );
	$tags .= $self->print_attribute( 'Hidden',    $self->_get_hidden() );
	$tags .= $self->print_attribute( 'KeyPath',   $self->_get_keypath() );
	$tags .=
	  $self->print_attribute( 'PatchAllowIgnoreOnError',
		$self->_get_patchallowignoreonerror() );
	$tags .=
	  $self->print_attribute( 'PatchIgnore', $self->_get_patchignore() );
	$tags .=
	  $self->print_attribute( 'PatchWholeFile',
		$self->_get_patchwholefile() );
	$tags .=
	  $self->print_attribute( 'PatchGroup', $self->_get_patchgroup() );
	$tags .=
	  $self->print_attribute( 'ProcessorArchitecture',
		$self->_get_processorarchitecture() );
	$tags .= $self->print_attribute( 'ReadOnly', $self->_get_readonly() );
	$tags .=
	  $self->print_attribute( 'SelfRegCost', $self->_get_selfregcost() );
	$tags .= $self->print_attribute( 'ShortName', $self->_get_shortname() );
	$tags .= $self->print_attribute( 'Source',    $self->_get_source() );
	$tags .= $self->print_attribute( 'System',    $self->_get_system() );
	$tags .= $self->print_attribute( 'TrueType',  $self->_get_truetype() );
	$tags .= $self->print_attribute( 'Vital',     $self->_get_vital() );

	if ($children) {
		my $child_string = $self->as_string_children();
		return qq{<File$tags>\n$child_string</File>\n};
	} else {
		return qq{<File$tags />\n};
	}
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

WiX3::XML::File - TODO.

=head1 VERSION

This document describes WiX3::XML::File version 0.009100

=head1 SYNOPSIS

TODO.
  
=head1 DESCRIPTION

TODO.

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

TODO.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<Exception::Class|Exception::Class>

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

