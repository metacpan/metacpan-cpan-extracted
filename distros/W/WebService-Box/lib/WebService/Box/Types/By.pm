package WebService::Box::Types::By;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int);

our $VERSION = 0.01;

has [qw/type name login/] => (is => 'ro', isa => Str, required => 1);
has id => (is => 'ro', isa => Int, required => 1);

1;

__END__

=pod

=head1 NAME

WebService::Box::Types::By

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
