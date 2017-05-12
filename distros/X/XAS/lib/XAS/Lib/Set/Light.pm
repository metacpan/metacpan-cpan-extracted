package XAS::Lib::Set::Light;

our $VERSION = '0.01';

use base 'Set::Light';

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub items {
    my ($x) = shift;

    return sort keys %$x;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Set::Light - An extennsion to Set::Light

=head1 SYNOPSIS

 use XAS::Lib::Set::Light;

 my $set = XAS::Lib::Set::Light->new();

 $set->insert("item');
 my @items = $set->items();

=head1 DESCRIPTION

This module is an extension of L<Set::Light|https://metacpan.org/pod/Set::Light>.

=head1 METHODS

=head2 items

This method returns all of the elements of the set in sorted order. 

=head1 SEE ALSO

=over 4

=item L<Set::Light|https://metacpan.org/pod/Set::Light>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
