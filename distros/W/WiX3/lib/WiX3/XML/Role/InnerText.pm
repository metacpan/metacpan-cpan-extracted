package WiX3::XML::Role::InnerText;

use 5.008003;
use Moose::Role 2;
use MooseX::Types::Moose qw( Maybe Str );

our $VERSION = '0.011';

has inner_text => (
	is      => 'ro',
	isa     => Maybe [Str],
	reader  => '_get_inner_text',
	default => undef,
);

#####################################################################
# Methods

sub inner_text_as_string {
	my $self = shift;
	my $tag  = shift;

	my $value = $self->_get_inner_text();
	if ( defined $value ) {
		return qq{>$value</$tag>\n};
	} else {
		return qq{ />\n};
	}
}

no Moose::Role;

1;

__END__

=head1 NAME

WiX3::XML::Role::InnerText - Provides inner text for tags that allow it.

=head1 VERSION

This document describes WiX3::XML::Role::InnerText version 0.010

=head1 SYNOPSIS

	# This is composed in to other tag classes.

=head1 DESCRIPTION

TODO.

=head1 INTERFACE 

=head2 inner_text_as_string

	$tag .= $self->inner_text_as_string('Tag');

This prints out the end of a tag correctly, whether it has 
inner text or not, as long as the tag does not have children.

=head1 DIAGNOSTICS

There are no diagnostics for this role, however, other diagnostics may 
be used by classes implementing this role.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010 Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.1 itself. See 
L<perlartistic|perlartistic> and L<perlgpl|perlgpl>.

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
