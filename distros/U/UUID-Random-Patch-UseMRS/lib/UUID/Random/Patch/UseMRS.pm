package UUID::Random::Patch::UseMRS;

our $VERSION = '0.01'; # VERSION

require Math::Random::Secure;

# testing
#*UUID::Random::rand = sub { die };

*UUID::Random::rand = \&Math::Random::Secure::rand;

require UUID::Random;

1;
# ABSTRACT: Make UUID::Random use Math::Random::Secure's rand()


__END__
=pod

=head1 NAME

UUID::Random::Patch::UseMRS - Make UUID::Random use Math::Random::Secure's rand()

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use UUID::Random::Patch::UseMRS;
 say UUID::Random::generate();

=head1 DESCRIPTION

This module makes L<UUID::Random> use C<rand()> from L<Math::Random::Secure>
instead of the default C<rand()> that comes with Perl. It is useful for creating
cryptographically secure UUID's. On the other hand, as a note, this makes
generate() around 20 times slower.

After you C<use> this module, use UUID::Random as usual.

=head1 SEE ALSO

L<Math::Random::Secure>

L<UUID::Random>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

