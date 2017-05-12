package Yukki::Web::Plugin;
{
  $Yukki::Web::Plugin::VERSION = '0.140290';
}
use 5.12.1;
use Moose;
# ABSTRACT:  base class for Yukki plugins


has app => (
    is          => 'ro',
    isa         => 'Yukki::Web',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin - base class for Yukki plugins

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  package MyPlugins::LowerCase;
  use 5.12.1;
  use Moose;

  extends 'Yukki::Web::Plugin';

  has format_helpers => (
      is          => 'ro',
      isa         => 'HashRef[CodeRef]',
      default     => sub { +{
          'lc' => \&lc_helper,
      } },
  );

  with 'Yukki::Web::Plugin::Role::FormatHelper';

  sub lc_helper { 
      my ($params) = @_;
      return lc $params->{arg};
  }

=head1 DESCRIPTION

This is the base class for Yukki plugins. It doesn't do much but allow your plugin access to the application singleton and its configuration. For your plugin to actually do something, you must implement a plugin role. See these roles for details:

=over

=item *

L<Yukki::Web::Plugin::Role::Formatter>. Formats a file for output as HTML.

=item *

L<Yukki::Web::Plugin::Role::FormatHelper>. This gives you the ability to create quick helpers in your yukkitext using the C<{{helper:...}}> notation.

=back

=head1 ATTRIBUTES

=head2 app

This is the L<Yukki::Web> singleton. All the methods required in L<Yukki::Role::App> will be delegated.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
