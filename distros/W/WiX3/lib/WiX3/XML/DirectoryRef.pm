package WiX3::XML::DirectoryRef;

use 5.008003;

# Must be done before Moose, or it won't get picked up.
use metaclass (
	metaclass   => 'Moose::Meta::Class',
	error_class => 'WiX3::Util::Error',
);
use Moose 2;
use Params::Util qw( _INSTANCE );
use MooseX::Types::Moose qw( Int Str ArrayRef );
use WiX3::XML::TagTypes qw( DirectoryRefChildTag DirectoryTag );
use WiX3::Util::StrictConstructor;

our $VERSION = '0.011';

with qw(WiX3::XML::Role::TagAllowsChildTags
  WiX3::Role::Traceable
);

## Allows Component, Directory, Merge as children.

has '+child_tags' => ( isa => ArrayRef [DirectoryRefChildTag] );


#####################################################################
# Accessors:
#   None.

has directory_object => (
	is       => 'ro',
	isa      => DirectoryTag,
	reader   => '_get_directory_object',
	required => 1,
	weak_ref => 1,
	handles  => [qw(get_path get_directory_id)],
);

has diskid => (
	is     => 'ro',
	isa    => Int,
	reader => '_get_diskid',
);

has filesource => (
	is     => 'ro',
	isa    => Str,
	reader => '_get_filesource',
);

#####################################################################
# Methods to implement the Tag role.

sub BUILDARGS {
	my $class = shift;

	if ( @_ == 1 && _INSTANCE( $_[0], 'WiX3::XML::Directory' ) ) {
		return { directory_object => $_[0] };
	} else {
		return $class->SUPER::BUILDARGS(@_);
	}
}


sub as_string {
	my $self = shift;

	my $children = $self->has_child_tags();
	my $tags;
	$tags = $self->print_attribute( 'Id', $self->get_directory_id() );
	$tags .= $self->print_attribute( 'DiskId', $self->_get_diskid() );
	$tags .=
	  $self->print_attribute( 'FileSource', $self->_get_filesource() );

	if ($children) {
		my $child_string = $self->as_string_children();
		return qq{<DirectoryRef$tags>\n$child_string\n</DirectoryRef>\n};
	} else {
		return qq{<DirectoryRef$tags />\n};
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

WiX3::XML::DirectoryRef - Class representing a DirectoryRef tag.

=head1 VERSION

This document describes WiX3::XML::DirectoryRef version 0.009100

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

