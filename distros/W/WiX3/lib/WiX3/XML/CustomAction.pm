package WiX3::XML::CustomAction;

####################################################################
# WiX3::XML::CustomAction - Object that represents a <CustomAction> tag.
#
# Copyright 2009, 2010 Curtis Jewell
#
# License is the same as perl. See WiX3.pm for details.
#
use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _IDENTIFIER _STRING );
use WiX3::Types qw( YesNoType );
use MooseX::Types::Moose qw( Str Maybe );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_customaction.htm

with qw(WiX3::XML::Role::Tag WiX3::XML::Role::InnerText);

# No child tags allowed.

#####################################################################
# Accessors:
#   see new.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has binarykey => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_binarykey',
	default => undef,
);

has directory => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_directory',
	default => undef,
);

has dllentry => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_dllentry',
	default => undef,
);

has error => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_error',
	default => undef,
);

has execommand => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_execommand',
	default => undef,
);

# TODO: Enum
has execute => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_execute',
	default => undef,
);

has filekey => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_filekey',
	default => undef,
);

has hidetarget => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_hidetarget',
	default => undef,
);

has impersonate => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_impersonate',
	default => undef,
);

has jscriptcall => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_jscriptcall',
	default => undef,
);

has patchuninstall => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_patchuninstall',
	default => undef,
);

has property => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_property',
	default => undef,
);

# TODO: Enum
has return => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_return',
	default => undef,
);

# TODO: Enum
has script => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_script',
	default => undef,
);

has suppressmodularization => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_suppressmodularization',
	default => undef,
);

has terminalserveraware => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_terminalserveraware',
	default => undef,
);

has value => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_value',
	default => undef,
);

has vbscriptcall => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_vbscriptcall',
	default => undef,
);

has win64 => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_win64',
	default => undef,
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Environment> tag defined by this object.

sub as_string {
	my $self = shift;

	my $id = 'CA_' . $self->get_id();

	my $string;
	$string = '<CustomAction';

	my @attribute = (
		[ 'Id'             => $id, ],
		[ 'BinaryKey'      => $self->_get_binarykey(), ],
		[ 'Directory'      => $self->_get_directory(), ],
		[ 'DllEntry'       => $self->_get_dllentry(), ],
		[ 'ExeCommand'     => $self->_get_execommand(), ],
		[ 'Execute'        => $self->_get_execute(), ],
		[ 'FileKey'        => $self->_get_filekey(), ],
		[ 'HideTarget'     => $self->_get_hidetarget(), ],
		[ 'Impersonate'    => $self->_get_impersonate(), ],
		[ 'JScriptCall'    => $self->_get_jscriptcall(), ],
		[ 'PatchUninstall' => $self->_get_patchuninstall(), ],
		[ 'Property'       => $self->_get_property(), ],
		[ 'Return'         => $self->_get_return(), ],
		[ 'Script'         => $self->_get_script(), ],
		[   'SuppressModularization' =>
			  $self->_get_suppressmodularization(),
		],
		[ 'TerminalServerAware' => $self->_get_terminalserveraware(), ],
		[ 'Value'               => $self->_get_value(), ],
		[ 'VBScriptCall'        => $self->_get_vbscriptcall(), ],
		[ 'Win64'               => $self->_get_win64(), ],
	);

	my ( $k, $v );

	foreach my $ref (@attribute) {
		( $k, $v ) = @{$ref};
		$string .= $self->print_attribute( $k, $v );
	}

	$string .= $self->inner_text_as_string();

	return $string;
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
