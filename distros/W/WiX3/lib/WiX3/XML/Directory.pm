package WiX3::XML::Directory;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use MooseX::Types::Moose qw( Int Str Maybe ArrayRef );
use WiX3::Types qw( ComponentGuidType );
use WiX3::XML::TagTypes qw( DirectoryChildTag );
use WiX3::Util::StrictConstructor;
use Params::Util qw( _IDENTIFIER _STRING );
use File::Spec::Functions qw( catdir );

our $VERSION = '0.011';

with qw(WiX3::XML::Role::TagAllowsChildTags
  WiX3::XML::Role::GeneratesGUID
  WiX3::Role::Traceable
);

## Allows Component, Directory, Merge, and SymbolPath as children.
## SymbolPath will need added later.

has '+child_tags' => ( isa => ArrayRef [DirectoryChildTag] );


#####################################################################
# Accessors:
#   None.

has id => (
	is      => 'ro',
	isa     => Str,
	reader  => 'get_id',
	builder => 'id_build',
	lazy    => 1,
);

# Path helps us in path searching.
has path => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => 'get_path',
	default => undef,
);

has noprefix => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_noprefix',
	default => undef,
);

has diskid => (
	is       => 'ro',
	isa      => Maybe [Int],
	reader   => '_get_diskid',
	init_arg => 'diskid',
	default  => undef,
);

has filesource => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_filesource',
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

has name => (
	is      => 'ro',
	isa     => Maybe [Str],            # LongFileNameType
	reader  => 'get_name',
	default => undef,
);

has sourcename => (
	is      => 'ro',
	isa     => Maybe [Str],            # LongFileNameType
	reader  => '_get_sourcename',
	default => undef,
);

has _shortname => (
	is       => 'ro',
	isa      => Maybe [Str],           # ShortFileNameType
	reader   => '_get_shortname',
	init_arg => 'shortname',
	default  => undef,
);

has _shortsourcename => (
	is       => 'ro',
	isa      => Maybe [Str],           # ShortFileNameType
	reader   => '_get_shortsourcename',
	init_arg => 'shortsourcename',
	default  => undef,
);

# Since we generate GUID's when none is included,
# ComponentGuidGenerationSeed is not needed.

#####################################################################
# Constructor for Directory
#

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

	if (    not exists $args{'path'}
		and exists $args{'name'}
		and exists $args{'parent'} )
	{

		# Create our path off our parent's path.
		my $parent_path = $args{'parent'}->get_path();
		if ( defined $parent_path ) {
			$args{'path'} = catdir( $parent_path, $args{'name'} );
		}

		delete $args{'parent'};
	} ## end if ( not exists $args{...})

	if ( defined $args{'id'} and not defined _IDENTIFIER( $args{'id'} ) ) {
		WiX3::Exception::Parameter::Invalid->throw('id');
	}

	return \%args;
} ## end sub BUILDARGS

sub get_directory_id {
	my $self = shift;
	my $id   = $self->get_id();

	if ( $self->_get_noprefix() ) {
		return $id;
	} else {
		return "D_$id";
	}
}

sub add_directory {
	my $self  = shift;
	my $class = ref $self;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} elsif ( 0 == @_ % 2 ) {
		%args = @_;
	} else {
		WiX3::Exception::Parameter::Odd->throw();
	}

	my $name = $args{name};
	## no critic(ProhibitMagicNumbers)
	$self->trace_line( 3, "Adding directory $name\n" ) if defined $name;

	# We make a new $class, rather than a new WiX3::XML::Directory,
	# so subclasses can create more of themselves without
	# having to override this routine.
	my $new_dir = $class->new(

#		parent => $self,
		%args
	);
	$self->add_child_tag($new_dir);

	return $new_dir;
} ## end sub add_directory



#####################################################################
# Methods to implement the Tag role.

sub as_string {
	my $self = shift;

	my $children = $self->has_child_tags();
	my $tags;
	$tags = $self->print_attribute( 'Id', $self->get_directory_id() );
	$tags .= $self->print_attribute( 'Name',      $self->get_name() );
	$tags .= $self->print_attribute( 'ShortName', $self->_get_shortname() );
	$tags .=
	  $self->print_attribute( 'SourceName', $self->_get_sourcename() );
	$tags .=
	  $self->print_attribute( 'ShortSourceName',
		$self->_get_shortsourcename() );
	$tags .= $self->print_attribute( 'DiskId', $self->_get_diskid() );
	$tags .=
	  $self->print_attribute( 'FileSource', $self->_get_filesource() );

	if ($children) {
		my $child_string = $self->as_string_children();
		return qq{<Directory$tags>\n$child_string\n</Directory>\n};
	} else {
		return qq{<Directory$tags />\n};
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

WiX3::XML::Directory - Class representing a Directory tag.

=head1 VERSION

This document describes WiX3::XML::Directory version 0.009100

=head1 SYNOPSIS

    my $tag = WiX3::XML::Directory->new(
	  name => 'Test';
	  path => 'ProgramFilesDir\Test';
	);
  
=head1 DESCRIPTION

This class represents a Directory tag and takes most non-deprecated 
attributes that the tag has (ComponentGuidGenerationSeed is the exception)
as parameters.

If an C<id> parameter is not passed, one will be generated using the C<path> parameter.

All attributes are lowercased when passed as a parameter.

=head1 INTERFACE 

This class implementes all methods of the 
L<XML::WiX3::Classes::Role::Tag|XML::WiX3::Classes::Role::Tag> role.

=head2 Other parameters to new

These parameters will not go into the XML output, although they may affect it.

=head3 path

This is a path that will be used when searching for this directory.

To easily implement this when using standard directories, just use the 
standard directory name as the root.

=head3 noprefix

The Id printed in the XML that this class generates will have a prefix of 
C<D_> unless this is set to true.

This is used for standard directories.

=head2 get_directory_id

Returns the ID of the directory as it will be printed out in the XML file.

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head1 DIAGNOSTICS

This module throws an WiX3::Exception::Parameter::Odd object upon build if 
the parameter count is incorrect.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://wix.sourceforge.net/manual-wix3/wix_xsd_directory.htm>

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

