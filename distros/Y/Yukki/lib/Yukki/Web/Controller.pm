package Yukki::Web::Controller;
{
  $Yukki::Web::Controller::VERSION = '0.140290';
}
use Moose::Role;

# ABSTRACT: Base class for Yukki::Web controllers


has app => (
    is          => 'ro',
    isa         => 'Yukki::Web',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);


requires 'fire';

1;

__END__

=pod

=head1 NAME

Yukki::Web::Controller - Base class for Yukki::Web controllers

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

All L<Yukki::Web> controllers extend from here.

=head1 ATTRIBUTES

=head2 app

This is the L<Yukki::Web> application.

=head1 REQUIRED METHODS

=head2 fire

  $controller->fire($context);

Controllers must implement this method. This method will be given a
L<Yukki::Web::Context> to work with. It is expected to fill in the
L<Yukki::Web::Response> attached to that context or throw an exception.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
