package WiX3::XML::Fragment::CreateFolder;

use 5.008003;
use Moose 2;
use Params::Util qw( _IDENTIFIER );

our $VERSION = '0.011';

with 'WiX3::XML::Role::Fragment';

has _tag => (
	is      => 'ro',
	isa     => 'WiX3::XML::Fragment',
	reader  => '_get_tag',
	handles => [qw(search_file check_duplicates get_directory_id)],
);

#####################################################################
# Constructor for CreateFolderFragment
#
# Parameters: [pairs]
#   id, directory: See Base::Fragment.

sub BUILDARGS {
	my $class = shift;
	my ( $id, $directory_id );

	if ( @_ == 2 && !ref $_[0] ) {
		$id           = $_[0];
		$directory_id = $_[1];
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		my %args = %{ $_[0] };
		$id           = $args{'id'};
		$directory_id = $args{'directory_id'};
	} elsif ( @_ == ( 2 * 2 ) ) {      # 2 pairs.
		my %args = {@_};
		$id           = $args{'id'};
		$directory_id = $args{'directory_id'};
	} else {
		WiX3::Exception::Parameter::Odd->throw();
	}

	if ( not defined $id ) {
		WiX3::Exception::Parameter::Missing->throw('id');
	}

	if ( not defined $directory_id ) {
		WiX3::Exception::Parameter::Missing->throw('directory_id');
	}

	if ( not _IDENTIFIER($id) ) {
		WiX3::Exception::Parameter::Invalid->throw('id');
	}

	if ( not _IDENTIFIER($directory_id) ) {
		WiX3::Exception::Parameter::Invalid->throw('directory_id');
	}

	my $tag1 = WiX3::XML::Fragment->new( id => "Create$id" );
	my $tag2 = WiX3::XML::DirectoryRef->new( id => $directory_id );
	my $tag3 = WiX3::XML::Component->new( id => "Create$id" );
	my $tag4 = WiX3::XML::CreateFolder->new();

	$tag3->add_tag($tag4);
	$tag2->add_tag($tag3);
	$tag1->add_tag($tag2);

	return { '_tag' => $tag1 };
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	my $directory_id = $self->get_directory_id();

	$self->trace_line( 2,
		    'Creating directory creation entry for directory '
		  . "id $directory_id\n" );

	return;
}

sub as_string {
	my $self = shift;

	return $self->_get_tag()->as_string();
}

sub get_namespace {
	return q{xmlns='http://schemas.microsoft.com/wix/2006/wi'};
}

# Needs no regeneration.
sub regenerate {
	return;
}

1;

__END__

=head1 NAME

WiX3::XML::Fragment::CreateFolder - "Shortcut Fragment" containing only a CreateFolder entry.

=head1 VERSION

This document describes WiX3::XML::Fragment::CreateFolder version 0.009100

=head1 SYNOPSIS

	my $fragment1 = WiX3::XML::Fragment::CreateFolder->new(
		id => $id1,
		directory_id = $directory_id1,
	);

	my $fragment2 = WiX3::XML::Fragment::CreateFolder->new({
		id => $id2,
		directory_id = $directory_id2,
	});

	my $fragment3 = WiX3::XML::Fragment::CreateFolder->new(
		$id3, $directory_id3);
	
=head1 DESCRIPTION

This module defines a fragment that contains only a CreateFolder tag and 
the parent tags required to implement it.

=head1 INTERFACE 

All callable routines other than new() are provided by 
L<WiX3::XML::Fragment|WiX3::XML::Fragment>, and are documented there.

=head2 new()

the new() routine has 2 parameters: The id for the fragment, specified as C<id>, and
the id of the directory fragment to create, specified as C<directory_id>.

Parameters can be passed positionally (first the id parameter, and then the 
directory_id parameter) or via hash or hashref, as shown in the L<SYNOPSIS|#SYNOPSIS>.

=head1 DIAGNOSTICS

This module throws WiX3::Exception::Parameter,  
WiX3::Exception::Parameter::Missing, and WiX3::Exception::Parameter::Invalid 
objects, which are documented in L<WiX3::Exceptions|WiX3::Exceptions>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

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

