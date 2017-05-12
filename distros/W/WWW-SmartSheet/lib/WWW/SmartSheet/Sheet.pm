package WWW::SmartSheet::Sheet;
{
  $WWW::SmartSheet::Sheet::VERSION = '0.01';
}
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

=head1 NAME

WWW::SmartSheet::Sheet

=head1 VERSION

version 0.01

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
