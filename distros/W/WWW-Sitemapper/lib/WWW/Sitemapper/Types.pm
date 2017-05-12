use strict;
use warnings;
package WWW::Sitemapper::Types;
BEGIN {
  $WWW::Sitemapper::Types::AUTHORITY = 'cpan:AJGB';
}
{
  $WWW::Sitemapper::Types::VERSION = '1.121160';
}
#ABSTRACT: Types used by L<WWW::Sitemapper>.

use URI;
use DateTime;
use DateTime::Duration;

use MooseX::Types -declare => [qw(
    tURI
    tDateTime
    tDateTimeDuration
)];

use MooseX::Types::Moose qw(
    Str
    Int
    Num
);



class_type tURI, { class => 'URI' };

coerce tURI,
    from Str,
        via { URI->new( $_, 'http' ) };


class_type tDateTime, { class => 'DateTime' };

coerce tDateTime,
    from Int,
        via { DateTime->from_epoch( epoch => $_ ) };




class_type tDateTimeDuration, { class => 'DateTime::Duration' };

coerce tDateTimeDuration,
    from Num,
        via { DateTime::Duration->new( minutes => $_ ) };

1;

__END__
=pod

=encoding utf-8

=head1 NAME

WWW::Sitemapper::Types - Types used by L<WWW::Sitemapper>.

=head1 VERSION

version 1.121160

=head1 SYNOPSIS

    use WWW::Sitemapper::Types qw( tURI tDateTime tDateTimeDuration );

=head1 TYPES

=head2 tURI

    has 'uri' => (
        is => 'rw',
        isa => tURI,
        coerce => 1,
    );

L<URI> object.

Coerces from C<Str> via L<URI/new>.

=head2 tDateTime

    has 'datetime' => (
        is => 'rw',
        isa => tDateTime,
        coerce => 1,
    );

L<DateTime> object.

Coerces from C<Int> via L<DateTime>-E<gt>from_epoch( epoch => $_ ).

=head2 tDateTimeDuration

    has 'datetimeduration' => (
        is => 'rw',
        isa => tDateTimeDuration,
        coerce => 1,
    );

L<DateTime::Duration> object.

Coerces from C<Num> via L<DateTime::Duration>-E<gt>new( minutes => $_ ).

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<WWW::Sitemapper|WWW::Sitemapper>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

