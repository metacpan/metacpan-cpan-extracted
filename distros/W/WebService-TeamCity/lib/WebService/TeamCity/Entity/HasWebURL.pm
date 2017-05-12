package WebService::TeamCity::Entity::HasWebURL;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.03';

use Types::Standard qw( Str );

use Moo::Role;

has web_url => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

# ABSTRACT: Role for any REST API object with a web URL

__END__

=pod

=head1 NAME

WebService::TeamCity::Entity::HasWebURL - Role for any REST API object with a web URL

=head1 VERSION

version 0.03

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
