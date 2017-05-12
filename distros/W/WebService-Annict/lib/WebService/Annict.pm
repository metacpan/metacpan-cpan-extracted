package WebService::Annict;
use 5.008001;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;

use WebService::Annict::Works;
use WebService::Annict::Episodes;
use WebService::Annict::Records;

our $VERSION = "0.02";

sub new {
  my ($class, %args) = @_;
  my $access_token = $args{access_token};
  my $ua = LWP::UserAgent->new(
    agent => "Perl5 WebService::Annict/$VERSION",
    default_headers => HTTP::Headers->new(
      "Content-Type" => "application/json",
      Accept         => "application/json",
      Authorization  => "Bearer $access_token",
    ),
  );

  bless {
    works => WebService::Annict::Works->new($ua),
  }, $class;
}



1;
__END__

=encoding utf-8

=head1 NAME

WebService::Annict - Annict API interface

=head1 SYNOPSIS

    use WebService::Annict;

=head1 DESCRIPTION

WebService::Annict is Annict API interface


=head1 LICENSE

Copyright (C) nukosuke.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nukosuke E<lt>nukosuke@cpan.orgE<gt>

=cut
