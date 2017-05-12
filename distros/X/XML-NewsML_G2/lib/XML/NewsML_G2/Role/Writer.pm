package XML::NewsML_G2::Role::Writer;

use Moose::Role;
use namespace::autoclean;

sub _create_remote_content {
    my ($self, $root, $remote) = @_;

    $root->setAttribute('contenttype', $remote->mimetype) if ($remote->mimetype);
    return;
}

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer - Base role for NewsML-G2 writer classes

=head1 DESCRIPTION

This module serves as a base role for all NewsML-G2 writer classes it
defined the required functions that need to be provided by the
specific writer roles for each news item type

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
