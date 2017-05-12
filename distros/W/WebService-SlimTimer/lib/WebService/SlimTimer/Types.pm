# ABSTRACT: Defines Moose types used by WebService::SlimTimer.

package WebService::SlimTimer::Types;

use DateTime::Format::RFC3339;
use Moose::Util::TypeConstraints;

use MooseX::Types -declare => [qw(TimeStamp OptionalTimeStamp)];
use MooseX::Types::Moose qw(Str Maybe);

sub _DateTime_from_YAML
{
    # For some reason we have we get spaces between the date and time parts as
    # well as before the time zone in the data returned by SlimTimer and we
    # need to get rid of them before parsing as otherwise it fails.
    s/ /T/; s/ //; DateTime::Format::RFC3339->parse_datetime($_)
}

class_type TimeStamp, { class => 'DateTime' };
coerce TimeStamp,
    from Str,
    via { _DateTime_from_YAML($_) };

subtype OptionalTimeStamp, as Maybe[TimeStamp];
coerce OptionalTimeStamp,
    from Str,
    via { defined $_ ? _DateTime_from_YAML($_) : undef };


__END__
=pod

=head1 NAME

WebService::SlimTimer::Types - Defines Moose types used by WebService::SlimTimer.

=head1 VERSION

version 0.005

=head1 AUTHOR

Vadim Zeitlin <vz-cpan@zeitlins.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Vadim Zeitlin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

