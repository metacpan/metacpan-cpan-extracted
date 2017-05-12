package WiX3::XML::Role::TagAllowsChildTags;

use 5.008003;
use Moose::Role 2;
use WiX3::Exceptions;
use WiX3::Types qw(IsTag);
use MooseX::Types::Moose qw(ArrayRef);
use List::MoreUtils qw( uniq );

our $VERSION = '0.011';

with 'WiX3::XML::Role::Tag';

#####################################################################
# Attributes

# A tag can contain other tags.
has 'child_tags' => (
	traits   => ['Array'],
	is       => 'rw',
	isa      => ArrayRef [IsTag],
	init_arg => undef,
	default  => sub { return []; },
	handles  => {
		'get_child_tags'   => 'elements',
		'add_child_tag'    => 'push',
		'get_child_tag'    => 'get',
		'has_child_tags'   => 'count',
		'count_child_tags' => 'count',
		'delete_child_tag' => 'delete',
		'clear_child_tags' => 'clear',
	},
);

# I think you could do method aliasing... with 'Role' => { alias => { 'add_child_tag' => '_add_child_tag' } }
# then implement your own child tag to do validation

#####################################################################
# Methods

sub as_string_children {
	my $self = shift;

	my $string;
	my $count = $self->count_child_tags();

	if ( 0 == $count ) {
		return q{};
	}

	foreach my $tag ( $self->get_child_tags() ) {
		$string .= $tag->as_string();
	}

	return $self->indent( 2, $string );
} ## end sub as_string_children

sub get_namespaces {
	my $self = shift;

	my @namespaces = ( $self->get_namespace() );
	my $count      = $self->count_child_tags();

	if ( 0 == $count ) {
		return @namespaces;
	}

	foreach my $tag ( $self->get_child_tags() ) {
		if ( $tag->does('get_namespaces') ) {
			push @namespaces, $tag->get_namespaces();
		} else {
			push @namespaces, $tag->get_namespace();
		}
	}

	return uniq @namespaces;
} ## end sub get_namespaces

sub count_all_child_tags {
	my $self = shift;

	my $answer = 1;

	foreach my $tag ( $self->get_child_tags() ) {
		if ( $tag->does('count_all_child_tags') ) {
			$answer += $tag->count_all_child_tags();
		} else {
			$answer++;
		}
	}

	return $answer;
} ## end sub count_all_child_tags

no Moose::Role;

1;

__END__

=head1 NAME

WiX3::XML::Role::TagAllowsChildTags - Base role for XML tags that have children.

=head1 VERSION

This document describes WiX3::XML::Role::TagAllowsChildTags version 0.010

=head1 SYNOPSIS

    # use WiX3;

=head1 DESCRIPTION

This is the base role for all WiX3 classes that represent XML tags.

=head1 INTERFACE 

=head2 as_string_children

	$string = $tag->as_string_children();

This routine returns a string of XML that contains the tag defined by this 
object and all child tags, and is used by C<as_string>.

=head1 DIAGNOSTICS

There are no diagnostics for this role, however, other diagnostics may 
be used by classes implementing this role.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-classes@rt.cpan.org>, or through the web interface at
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
