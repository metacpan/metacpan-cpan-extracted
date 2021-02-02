package Tree::Persist::File;

use strict;
use warnings;

use base qw( Tree::Persist::Base );

use Scalar::Util qw( blessed );

our $VERSION = '1.14';

# ----------------------------------------------

sub _init
{
	my($class)         = shift;
	my($opts)          = @_;
	my($self)          = $class -> SUPER::_init( $opts );
	$self->{_filename} = $opts->{filename};

	return $self;

} # End of _init.

# ----------------------------------------------

sub _create
{
	my($self) = shift;

	open my $fh, '>', $self->{_filename}
		or die "Cannot open '$self->{_filename}' for writing: $!\n";

	print $fh $self->_build_string( $self->{_tree} );

	close $fh;

	return $self;

} # End of _create.

# ----------------------------------------------

*_commit = \&_create;

# ----------------------------------------------

1;

__END__

=head1 NAME

Tree::Persist::File - The base class for File plugins for Tree persistence

=head1 SYNOPSIS

See L<Tree::Persist/SYNOPSIS> or scripts/xml.demo.pl for sample code.

=head1 DESCRIPTION

This class is a base class for the Tree::Persist::File::* hierarchy, which
provides File plugins for Tree persistence.

=head1 PARAMETERS

Parameters are used in the call to L<Tree::Persist/connect({%opts})> or L<Tree::Persist/create_datastore({%opts})>.

In addition to any parameters required by its parent L<Tree::Persist::Base>, the following
parameters are used by C<connect()> or C<create_datastore()>:

=over 4

=item * class (optional)

This is the name of a user-supplied class for deflation/inflation.

The C<class> parameter takes precedence over the C<type> parameter.

If C<class> is not provided, C<type> is used, and defaults to 'File'. Then C<class> is determined using:

	$class = $type eq 'File' ? 'Tree::Persist::File::XML' : 'Tree::Persist::DB::SelfReferential';

See t/save_and_load.t for sample code.

=item * filename (required)

This is the filename that will be used as the datastore.

=item * type (optional)

For any File::* plugin to be used, the type must be 'File' (case-sensitive) unless a C<class> is provided.

=back

=head1 METHODS

Tree::Persist::File is a sub-class of L<Tree::Persist::Base>, and inherits all its methods.

=head1 TODO

=over 4

=item *

Currently, the filename parameter isn't checked for validity or existence.

=back

=head1 CODE COVERAGE

Please see the relevant section of L<Tree::Persist>.

=head1 SUPPORT

Please see the relevant section of L<Tree::Persist>.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

Co-maintenance since V 1.01 is by Ron Savage <rsavage@cpan.org>.
Uses of 'I' in previous versions is not me, but will be hereafter.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
