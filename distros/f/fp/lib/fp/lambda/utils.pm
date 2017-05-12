
package fp::lambda::utils;

use strict;
use warnings;

our $VERSION = '0.01';

BEGIN {
    require fp;
    *import = \&fp::import;
}

sub church_numeral_to_int {
    my $numeral = shift;
    $numeral->(sub { 1 + $_[0] })->(0)
}

1;

__END__

=pod

=head1 NAME

fp::lambda::utils

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item church_numeral_to_int

=item print_list

=back

=head1 BUGS

None that I am currently aware of. Of course, that does not mean that they do not exist, so if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the C<CODE COVERAGE> section of B<fp> for this information.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut