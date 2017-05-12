package Yeb::Plugin::GeoJSON;
BEGIN {
  $Yeb::Plugin::GeoJSON::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for GeoJSON response with Geo::JSON::Simple functions
$Yeb::Plugin::GeoJSON::VERSION = '0.003';
use Moo;
use Geo::JSON::Simple;

has app => ( is => 'ro', required => 1 );

sub BUILD {
  my ( $self ) = @_;
  $self->app->register_function('geojson',sub {
    my $object = shift;
    $self->app->cc->content_type('application/json');
    $self->app->cc->body($object->to_json);
    $self->app->cc->response;
  });
  for my $func (@Geo::JSON::Simple::EXPORT) {
    $self->app->register_function($func,sub { &{\&{$func}}(@_) });
  };
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::GeoJSON - Yeb Plugin for GeoJSON response with Geo::JSON::Simple functions

=head1 VERSION

version 0.003

=head1 SYNOPSIS

See also L<Geo::JSON::Simple>.

=encoding utf8

=head1 FRAMEWORK FUNCTIONS

=head2 geojson

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb-plugin-geojson
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb-plugin-geojson/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
