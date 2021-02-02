package Tree::Persist::DB;

use strict;
use warnings;

use base qw( Tree::Persist::Base );

our $VERSION = '1.14';

# ----------------------------------------------

sub _init
{
	my($class)      = shift;
	my($opts)       = @_;
	my($self)       = $class -> SUPER::_init( $opts );
	$self->{_dbh}   = $opts->{dbh};
	$self->{_table} = $opts->{table};

	return $self;

} # End of _init.

# ----------------------------------------------

1;

__END__

=head1 NAME

Tree::Persist::DB - The base class for DB plugins for Tree persistence

=head1 SYNOPSIS

See L<Tree::Persist/SYNOPSIS> or scripts/xml.demo.pl for sample code.

=head1 DESCRIPTION

This class is the base class for the Tree::Persist::DB::* hierarchy, which
provides DB plugins for Tree persistence through L<Tree::Persist>.

=head1 PARAMETERS

Parameters are used in the call to L<Tree::Persist/connect({%opts})> or L<Tree::Persist/create_datastore({%opts})>.

In addition to any parameters required by its parent L<Tree::Persist::Base>, the
following parameters are used by C<connect()> or C<create_datastore()>:

=over 4

=item * type (required)

For any DB::* plugin to be used, the type must be 'DB' (case-sensitive).

=item * dbh (required)

This is the $dbh that is already connected to the right database and schema
with the appropriate user. This is required.

=item * table (required)

This is the table name that contains the tree. This is required.

=back

=head1 METHODS

Tree::Persist::DB is a sub-class of L<Tree::Persist::Base>, and inherits all its methods.

=head1 TODO

=over 4

=item *

Currently, the dbh and table options aren't checked for existence or validity.

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

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
