package Yeb::Plugin::Locale::Simple;
BEGIN {
  $Yeb::Plugin::Locale::Simple::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for Locale::Simple connection
$Yeb::Plugin::Locale::Simple::VERSION = '0.002';
use Moo;
use Locale::Simple;

has app => ( is => 'ro', required => 1 );

has locales => (
	is => 'ro',
	predicate => 1,
);

sub BUILD {
  my ( $self ) = @_;
  for my $func (@Locale::Simple::EXPORT) {
    $self->app->register_function($func,sub { &{\&{$func}}(@_) });
  };
  l_dir($self->locales) if $self->has_locales;
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::Locale::Simple - Yeb Plugin for Locale::Simple connection

=head1 VERSION

version 0.002

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
