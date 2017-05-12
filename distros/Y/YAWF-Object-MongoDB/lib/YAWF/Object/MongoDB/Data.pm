package YAWF::Object::MongoDB::Data;

use 5.006;
use warnings;
use strict;
no strict 'refs';

=head1 NAME

YAWF::Object::MongoDB::Data - Deep Object of a MongoDB document

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 NOTICE

Internal module for YAWF::Object::MongoDB.

=head1 INTERNAL METHODS

Advoid calling them directly unless you really know what you're doing.

=head2 getset_column

Get and set data.

=cut

sub getset_column {
    my $self = shift;
    my $key  = shift;

    if ($#_ > -1) {
        $self->{_data}->{$key} = $_[0];
        $self->{_parent}->changed($self->{_top});
    }

    return $self->{_data}->{$key};
}

1;

=head1 AUTHOR

Sebastian Willing, C<< <sewi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yawf-object-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAWF-Object-MongoDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAWF::Object::MongoDB::Data


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=YAWF-Object-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/YAWF-Object-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/YAWF-Object-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/YAWF-Object-MongoDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sebastian Willing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
