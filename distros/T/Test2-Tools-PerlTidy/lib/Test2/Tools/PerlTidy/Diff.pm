package Test2::Tools::PerlTidy::Diff;

use strict;
use warnings;

# ABSTRACT: Perl tidiness class for tracking the tidiness of Perl files.
our $VERSION = '0.01'; # VERSION

require Test2::Tools::PerlTidy;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PerlTidy::Diff - Perl tidiness class for tracking the tidiness of Perl files.

=head1 VERSION

version 0.01

=head1 PROPERTIES

=head2 code_to_tidy

=head2 diff

=head2 errorfile

=head2 file_to_tidy

=head2 is_tidy

=head2 logfile

=head2 perltidyrc

=head2 stderr

=head2 tidied_code

=head1 CAVEATS

This class is a new and experimental part of L<Test2::Tools::PerlTidy>,
and as such the interface may change.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
