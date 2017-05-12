package WWW::OpenSearch::Image;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( height width type url ) );

=head1 NAME

WWW::OpenSearch::Image - Object to represent an image

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( [%options] )

=head1 ACCESSORS

=over 4

=item * height

=item * width

=item * type

=item * url

=back

=head1 AUTHOR

=over 4

=item * Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2013 by Tatsuhiko Miyagawa and Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
