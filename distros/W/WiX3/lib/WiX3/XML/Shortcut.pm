package WiX3::XML::Shortcut;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _STRING  );
use MooseX::Types::Moose qw( Str Int Maybe );
use WiX3::Types qw( YesNoType );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

# http://wix.sourceforge.net/manual-wix3/wix_xsd_shortcut.htm

with 'WiX3::XML::Role::Tag';

## Allows no child tags.

has id => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_id',
	required => 1,
);

has advertise => (
	is      => 'ro',
	isa     => Maybe [YesNoType],
	reader  => '_get_advertise',
	default => undef,
);

has arguments => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_arguments',
	default => undef,
);

has description => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_description',
	default => undef,
);

has descriptionresourcedll => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_descriptionresourcedll',
	default => undef,
);

has descriptionresourceid => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_descriptionresourceid',
	default => undef,
);

has directory => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_directory',
	default => undef,
);

has displayresourcedll => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_displayresourcedll',
	default => undef,
);

has displayresourceid => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_displayresourceid',
	default => undef,
);

has hotkey => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_hotkey',
	default => undef,
);

has icon => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_icon',
	default => undef,
);

has iconindex => (
	is      => 'ro',
	isa     => Maybe [Int],
	reader  => '_get_iconindex',
	default => undef,
);

has name => (
	is       => 'ro',
	isa      => Maybe [Str],
	reader   => '_get_name',
	required => 1,
);

has shortname => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_shortname',
	default => undef,
);

has show => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_show',
	default => undef,
);

has target => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_target',
	default => undef,
);

has workingdirectory => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_workingdirectory',
	default => undef,
);

#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $id = 'S_' . $self->get_id();

	my $string;
	$string = '<Shortcut';

	my @attribute = (
		[ 'Id'          => $id, ],
		[ 'Advertise'   => $self->_get_advertise(), ],
		[ 'Arguments'   => $self->_get_arguments(), ],
		[ 'Description' => $self->_get_description(), ],
		[   'DescriptionResourceDll' =>
			  $self->_get_descriptionresourcedll(),
		],
		[ 'DescriptionResourceId' => $self->_get_descriptionresourceid(), ],
		[ 'Directory'             => $self->_get_directory(), ],
		[ 'DisplayResourceDll'    => $self->_get_displayresourcedll(), ],
		[ 'DisplayResourceId'     => $self->_get_displayresourceid(), ],
		[ 'Hotkey'                => $self->_get_hotkey(), ],
		[ 'Icon'                  => $self->_get_icon(), ],
		[ 'IconIndex'             => $self->_get_iconindex(), ],
		[ 'Name'                  => $self->_get_name(), ],
		[ 'ShortName'             => $self->_get_shortname(), ],
		[ 'Show'                  => $self->_get_show(), ],
		[ 'Target'                => $self->_get_target(), ],
		[ 'WorkingDirectory'      => $self->_get_workingdirectory(), ],
	);

	my ( $k, $v );

	foreach my $ref (@attribute) {
		( $k, $v ) = @{$ref};
		$string .= $self->print_attribute( $k, $v );
	}

	$string .= qq{ />\n};

	return $string;

} ## end sub as_string

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WiX3::XML::Shortcut - Defines a Shortcut tag.

=head1 VERSION

This document describes WiX3::XML::Shortcut version 0.009100

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

