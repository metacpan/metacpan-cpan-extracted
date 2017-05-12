package Yukki::Model;
{
  $Yukki::Model::VERSION = '0.140290';
}
use Moose;

# ABSTRACT: Base class for model objects


has app => (
    is          => 'ro',
    isa         => 'Yukki',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);

1;

__END__

=pod

=head1 NAME

Yukki::Model - Base class for model objects

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

This is the base class used for model objects.

=head1 ATTRIBUTES

=head2 app

This is the L<Yukki> application instance.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
