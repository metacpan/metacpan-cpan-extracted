package WiX3::XML::Feature;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _IDENTIFIER _STRING );
use WiX3::Types qw( YesNoType );
use MooseX::Types::Moose qw( Str Int Maybe ArrayRef );
use WiX3::XML::TagTypes qw( FeatureChildTag );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_feature.htm

with 'WiX3::XML::Role::TagAllowsChildTags';

# Child tags allowed:
# Component, ComponentGroupRef, ComponentRef, Condition, Feature,
# FeatureGroupRef, FeatureRef, MergeRef

## FeatureChildTag allows Component, ComponentRef, Feature, FeatureRef,
## and MergeRef at the moment.

has '+child_tags' => ( isa => ArrayRef [FeatureChildTag] );

#####################################################################
# Accessors:
#   see new.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has _absent => (
	is       => 'ro',
	isa      => Maybe [Str],           # enum
	reader   => '_get_absent',
	init_arg => 'absent',
	default  => undef,
);

has _allow_advertise => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_allow_advertise',
	init_arg => 'allow_advertise',
	default  => undef,
);


has _configurable_directory => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_configurable_directory',
	init_arg => 'configurable_directory',
	default  => undef,
);

has _description => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_description',
	init_arg => 'description',
	default  => undef,
);

has _display => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_display',
	init_arg => 'display',
	default  => undef,
);

has _install_default => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_install_default',
	init_arg => 'install_default',
	default  => undef,
);

has _level => (
	is       => 'ro',
	isa      => Maybe [Int],
	reader   => '_get_level',
	init_arg => 'level',
	default  => undef,
);

has _title => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_title',
	init_arg => 'title',
	default  => undef,
);

has _typical_default => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_typical_default',
	init_arg => '_typical_default',
	default  => undef,
);

#####################################################################
# Main Methods

########################################
# as_string
# Parameters:
#   None.
# Returns:
#   String containing <Fragment> tag defined by this object.

sub as_string {
	my $self = shift;

	my $children = $self->has_child_tags();
	my $tags;

	# Print tag.
	$tags .= $self->print_attribute( 'Id',     'Feat_' . $self->get_id() );
	$tags .= $self->print_attribute( 'Absent', $self->_get_absent() );
	$tags .=
	  $self->print_attribute( 'AllowAdvertise',
		$self->_get_allow_advertise() );
	$tags .=
	  $self->print_attribute( 'ConfigurableDirectory',
		$self->_get_configurable_directory() );
	$tags .=
	  $self->print_attribute( 'Description', $self->_get_description() );
	$tags .= $self->print_attribute( 'Display', $self->_get_display() );
	$tags .=
	  $self->print_attribute( 'InstallDefault',
		$self->_get_install_default() );
	$tags .= $self->print_attribute( 'Level', $self->_get_level() );
	$tags .= $self->print_attribute( 'Title', $self->_get_title() );
	$tags .=
	  $self->print_attribute( 'TypicalDefault',
		$self->_get_typical_default() );

	if ($children) {
		my $child_string = $self->as_string_children();
		return qq{<Feature$tags>\n$child_string\n</Feature>\n};
	} else {
		return qq{<Feature$tags />\n};
	}
} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WiX3::XML::Feature - Defines a Feature tag.

=head1 VERSION

This document describes WiX3::XML::Feature version 0.009100

=head1 SYNOPSIS

TODO
  
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

