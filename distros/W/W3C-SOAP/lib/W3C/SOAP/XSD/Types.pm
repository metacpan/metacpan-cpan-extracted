package W3C::SOAP::XSD::Types;

# Created on: 2012-05-26 23:08:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
BEGIN {
    $W3C::SOAP::XSD::Types::AUTHORITY = 'cpan:IVANWILLS';
}
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use DateTime::Format::Strptime;
use MooseX::Types -declare
    => [qw/
        xsd:duration
        xsd:dateTime
        xsd:time
        xsd:date
        xsd:gYearMonth
        xsd:gYear
        xsd:gMonthDay
        xsd:gDay
        xsd:gMonth
    /];
use DateTime;
use DateTime::Format::Strptime qw/strptime/;
use Math::BigFloat;

our $VERSION = 0.14;

local $SIG{__WARN__} = sub {};

class_type 'DateTime';
class_type 'XML::LibXML::Node';

subtype 'xsd:boolean',
    as 'xs:boolean';
coerce 'xsd:boolean',
    from 'Str'
        => via {
              $_ eq 'true'  ? 1
            : $_ eq 'false' ? undef
            :                 confess "'$_' isn't a xs:boolean!";
        };

subtype 'xsd:double',
    as 'xs:double';
coerce 'xsd:double',
#    from 'Num'
#        => via { Params::Coerce::coerce('xs:double', $_) },
    from 'Str'
        => via { Math::BigFloat->new($_) };

subtype 'xsd:decimal',
    as 'xs:decimal';
coerce 'xsd:decimal',
#    from 'Num'
#        => via { Params::Coerce::coerce('xs:decimal', $_) },
    from 'Str'
        => via { Math::BigFloat->new($_) };

subtype 'xsd:long',
    as 'xs:long';
coerce 'xsd:long',
#    from 'Num'
#        => via { Params::Coerce::coerce('xs:long', $_) },
    from 'Str'
        => via { Math::BigInt->new($_) };

#subtype 'xsd:duration',
#    as 'DateTime';
#coerce 'xsd:duration',
#    from 'Str',
#    via {
#        DateTime::Format::Strptime("", $_)
#    };
#
subtype 'xsd:dateTime',
    as 'DateTime';
coerce 'xsd:dateTime',
    from 'XML::LibXML::Node' =>
        => via { $_->textContent },
    from 'Str',
        => via {
            return strptime("%FT%T", $_) if /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/xms;
            # DateTime expects timezones as [+-]hhmm XMLSchema expects them as [+-]hh:mm
            # also remove any milli seconds
            my $subseconds = /([.]\d+)/;
            s/(?:[.]\d+)? (?: ([+-]\d{2}) : (\d{2}) ) $/$1$2/xms;
            # Dates with timezones are meant to track the begging of the day
            my $dt = /[+-]\d{4}$/xms ? strptime("%FT%T%z", $_) : strptime("%FT%T", $_);
            $dt->set_nanosecond( $subseconds * 1_000_000_000 ) if $subseconds;
            return $dt;
        };

#subtype 'xsd:time',
#    as 'DateTime';
#coerce 'xsd:time',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };

subtype 'xsd:date',
    as 'DateTime';
coerce 'xsd:date',
    from 'XML::LibXML::Node' =>
        => via { $_->textContent },
    from 'Str',
        => via {
            return strptime("%F", $_) if /^\d{4}-\d{2}-\d{2}$/xms;
            # DateTime expects timezones as [+-]hhmm XMLSchema expects them as [+-]hh:mm
            s/([+-]\d{2}):(\d{2})$/$1$2/xms;
            # Dates with timezones are meant to track the begging of the day
            return strptime("%TT%F%z", "00:00:00T$_");
        };

#subtype 'xsd:gYearMonth',
#    as 'DateTime';
#coerce 'xsd:gYearMonth',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };
#
#subtype 'xsd:gYear',
#    as 'DateTime';
#coerce 'xsd:gYear',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };
#
#subtype 'xsd:gMonthDay',
#    as 'DateTime';
#coerce 'xsd:gMonthDay',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };
#
#subtype 'xsd:gDay',
#    as 'DateTime';
#coerce 'xsd:gDay',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };
#
#subtype 'xsd:gMonth',
#    as 'DateTime';
#coerce 'xsd:gMonth',
#    from 'Str',
#    via {
#        DateTime::Format::Striptime("", $_)
#    };

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Types - Moose types to support W3C::SOAP::XSD objects

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Types version 0.14.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Types;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Defines the type library (extended from L<MosseX::Types::XMLSchema>) this
adds extra coercions and in the case of Date/Time objects changes the base
type to L<DateTime>

=head2 Types

=over 4

=item C<xsd:boolean>

=item C<xsd:double>

=item C<xsd:dateTime>

=item C<xsd:date>

=back

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
