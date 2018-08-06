package Transport::AU::PTV::NoError;
$Transport::AU::PTV::NoError::VERSION = '0.03';
# VERSION
# PODNAME
# ABSTRACT: parent class with C<error> method returning false.

use strict;
use warnings;
use 5.010;


sub error { return 0; }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::NoError - parent class with C<error> method returning false.

=head1 VERSION

version 0.03

=head1 NAME

=head1 METHODS

=head2 error 

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
