package WWW::SmartSheet::Sheet;

our $VERSION = '0.06';

use Moo;
use MooX::late;

has accessLevel => (is => 'ro');
has columns     => (is => 'ro', isa => 'ArrayRef');
has id          => (is => 'ro');
has name        => (is => 'ro');
has permalink   => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::SmartSheet::Sheet - Represent 'sheet' object.

=head1 VERSION

version 0.06

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
