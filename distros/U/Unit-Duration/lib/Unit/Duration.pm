package Unit::Duration;
# ABSTRACT: Work-time unit duration conversion and canonicalization

use 5.010;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '1.05'; # VERSION

my $duration_element_re = qr/(?<expr>[-+*\/\d]+)\s*(?<unit>[A-z]+)\s*/;

sub new {
    my ( $self, %params ) = @_;
    my $params = {%params};

    my $name  = delete $params->{name};
    my $table = delete $params->{table};

    croak('must provide both "name" and "table" or neither to new()')
        if ( $name and not $table or $table and not $name );

    $params->{intra_space} //= ' ';
    $params->{extra_space} //= ', ';
    $params->{pluralize}   //= 1;
    $params->{unit_type}   //= 'short';
    $params->{compress}    //= 0;

    $self = bless( $params, $self );

    $self->set_table( default => q{
        y | yr  | year    = 4 qtrs
        q | qtr | quarter = 3 mons
        o | mon | month   = 4 wks
        w | wk  | week    = 5 days
        d | day           = 8 hrs
        h | hr  | hour    = 60 mins
        m | min | minute  = 60 secs
        s | sec | second
    } );

    $self->set_table( $name, $table ) if ( $name and $table );

    return $self;
}

sub set_table {
    my ( $self, $name, $table ) = @_;
    croak('no name provided to set_table()') unless ($name);
    $self->_parse_table( $name, $table );
    return $self;
}

sub get_table_string {
    my ( $self, $name ) = @_;
    croak('no name provided to get_table_string()') unless ($name);
    return $self->{_tables}{$name}{string};
}

sub get_table_structure {
    my ( $self, $name ) = @_;
    croak('no name provided to get_table_structure()') unless ($name);
    return $self->{_tables}{$name}{structure};
}

sub canonicalize {
    my ( $self, $duration, $settings, $table ) = @_;

    $settings->{compress} //= $self->{compress};

    my $units = $self->_get_units_for_table($table);
    my $duration_elements = $self->_merge_duration_elements( $self->_parse_duration( $duration, $units ) );

    if ( $settings->{compress} and not $settings->{_as} ) {
        $duration_elements = $self->_compress_duration_elements( $duration_elements, $units );
    }
    elsif ( $settings->{_as} ) {
        return $self->_total_duration_as( $duration_elements, $units, $settings->{_as} );
    }

    return $self->_render_duration( $duration_elements, $settings );
}

sub sum_as {
    my ( $self, $unit_name, $duration, $table ) = @_;
    return $self->canonicalize( $duration, { _as => $unit_name }, $table );
}

sub _parse_table {
    my ( $self, $name, $table ) = @_;
    croak('no table data provided to set_table()') unless ($table);

    my $units = ( ref $table ) ? [ map { {%$_} } @$table ] : do {
        $table =~ s/#.*//g;
        $table =~ s/(?:^\s+|\s+$)//g;
        $table =~ s/\v+/\n/g;
        $table =~ s/\h+//g;
        $table =~ s/[^\-\+\*\/\dA-z\n,;]+/\|/g;

        [ map {
            my @parts = split(/\|/);
            my $unit;

            my @elements = grep { /$duration_element_re/ } @parts;
            croak(qq{>1 duration element on line of duration table: "$_"}) if ( @elements > 1 );

            $unit->{duration} = pop @parts if (@elements);
            $unit->{letter}   = shift @parts;
            $unit->{short}    = shift @parts;
            $unit->{long}     = shift @parts // $unit->{short};

            $unit;
        } split( /\n/, $table ) ];
    };

    croak('not exactly 1 unit in duration table with no duration')
        if ( scalar( grep { not $_->{duration} } @$units ) != 1 );

    for my $unit (@$units) {
        $unit->{long} //= $unit->{short};
        my $match = '(' . join( '', map { $_ . '?' } split( '', $unit->{long} ) ) . ')';
        $unit->{match} = qr/$match/i;
    }

    $_->{duration} = $self->_parse_duration( $_->{duration}, $units )
        for ( grep { $_->{duration} } @$units );

    eval {
        local $SIG{__WARN__} = sub { die @_ };

        my $flatten;
        $flatten = sub {
            for my $unit (@_) {
                $flatten->(@_) if ( @_ = map { $_->{unit} } @{ $unit->{duration} || [] } );
                unless ( $unit->{amount} ) {
                    my %amount;
                    $amount{ $_->{unit}{long} } += $_->{int} * ( $_->{unit}{amount} // 1 )
                        for ( @{ $unit->{duration} || [] } );
                    my ($amount) = map { $amount{$_} } keys %amount;
                    $unit->{amount} += $amount if ($amount);
                    $unit->{amount} //= 1;
                }
            }
        };
        $flatten->(@$units);
    };
    if ($@) {
        croak('unable to properly interpret duration table');
    }

    $units = [ sort { $b->{amount} <=> $a->{amount} } @$units ];

    my $structure = [
        map {
            my $unit = {
                letter => $_->{letter},
                short  => $_->{short},
                long   => $_->{long},
            };

            delete $unit->{long} if ( $unit->{long} eq $unit->{short} );

            $unit->{duration} = join(
                ' ', map { $_->{int} . ' ' . $_->{unit}{short} } @{ $_->{duration} }
            ) if ( $_->{duration} );

            $unit;
        } @$units
    ];

    my $string = join( "\n", map {
        my $unit = $_;
        my $line = join( ' | ', grep { defined } map { $unit->{$_} } qw( letter short long ) );
        $line .= ' = ' . $unit->{duration} if ( exists $unit->{duration} );
        $line;
    } @$structure );

    $self->{_tables}{$name} = {
        structure => $structure,
        string    => $string,
        units     => $units,
    } if ($name);

    return $units;
}

sub _parse_duration {
    my ( $self, $duration, $units ) = @_;

    $duration //= '';
    $duration =~ s/(\d+)\s*:\s*(\d+)(?:\s*:\s*(\d+))?/
        $1 . 'h' . $2 . 'm' . ( ($3) ? $3 . 's' : '' )
    /ge;

    $duration =~ s/[^\-\+\*\/\dA-z]+//g;
    croak('unable to parse duration string') unless ( $duration =~ /^\s*(?:$duration_element_re)+$/ );

    my @elements;
    while ( $duration =~ /$duration_element_re/g ) {
        my $element = { map { $_ => $+{$_} } qw( expr unit ) };

        $element->{int}  = eval delete $element->{expr};
        $element->{unit} = $self->_match_unit_type( $element->{unit}, $units );

        push( @elements, $element );
    }

    return \@elements;
}

sub _match_unit_type {
    my ( $self, $unit_name, $units ) = @_;

    unless ($unit_name) {
        my ($unit) = grep { not $_->{duration} } @$units;
        return $unit;
    }

    $unit_name =~ s/s+$//i;
    my ($matched_unit) = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map {
        [
            $_,
            (
                $unit_name eq $_->{letter} or
                $unit_name eq $_->{short} or
                $unit_name eq $_->{long}
            ) ? 100 : do {
                $unit_name =~ $_->{match};
                length $1;
            },
        ];
    } @$units;
    return $matched_unit;
}

sub _get_units_for_table {
    my ( $self, $table ) = @_;

    if ( not defined $table ) {
        if ( exists $self->{_tables}{default} ) {
            return $self->{_tables}{default}{units};
        }
        else {
            croak('failure due to default table not defined');
        }
    }
    elsif ( exists $self->{_tables}{$table} ) {
        return $self->{_tables}{$table}{units};
    }
    else {
        return $self->_parse_table( undef, $table );
    }
}

sub _merge_duration_elements {
    my ( $self, $elements ) = @_;

    my %elements;
    for my $element (@$elements) {
        $element->{int} += $elements{ $element->{unit}{long} }{int}
            if ( exists $elements{ $element->{unit}{long} } );
        $elements{ $element->{unit}{long} } = $element;
    }

    return [
        sort { $b->{unit}{amount} <=> $a->{unit}{amount} }
        map { $elements{$_} }
        keys %elements
    ];
}

sub _render_duration {
    my ( $self, $duration_elements, $settings ) = @_;
    $settings->{$_} //= $self->{$_} for ( qw( intra_space extra_space pluralize unit_type ) );

    return join(
        $settings->{extra_space},
        map {
            $_->{int}
                . $settings->{intra_space}
                . $_->{unit}{ $settings->{unit_type} }
                . ( ( $settings->{pluralize} and $_->{int} != 1 ) ? 's' : '' )
        } @$duration_elements
    );
}

sub _compress_duration_elements {
    my ( $self, $duration_elements, $units ) = @_;

    my $total_seconds = $self->_total_duration_as( $duration_elements, $units );

    my @compressed_elements;
    for my $unit (@$units) {
        my $count = int( $total_seconds / $unit->{amount} );
        if ( $count >= 1 ) {
            push(
                @compressed_elements,
                {
                    int  => $count,
                    unit => $unit,
                },
            );
            $total_seconds -= $count * $unit->{amount};
        }
        last unless ($total_seconds);
    }

    return \@compressed_elements;
}

sub _total_duration_as {
    my ( $self, $duration_elements, $units, $unit_type ) = @_;

    my $total_seconds;
    $total_seconds += $_ for ( map { $_->{int} * $_->{unit}{amount} } @$duration_elements );
    return $total_seconds unless ($unit_type);

    my $unit = $self->_match_unit_type( $unit_type, $units );
    return $total_seconds / $unit->{amount};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Unit::Duration - Work-time unit duration conversion and canonicalization

=head1 VERSION

version 1.05

=for markdown [![test](https://github.com/gryphonshafer/Unit-Duration/workflows/test/badge.svg)](https://github.com/gryphonshafer/Unit-Duration/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Unit-Duration/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Unit-Duration)

=head1 SYNOPSIS

    use Unit::Duration;

    my $ud = Unit::Duration->new;

    my $x = $ud->canonicalize('4d 6h 4d 3h');
    # $x eq '8 days, 9 hrs'

    my $y = $ud->canonicalize( '4d 6h 4d 3h', { compress => 1 } );
    # $y eq '1 wk, 4 days, 1 hr'

    my $z = $ud->canonicalize(
        '4d 6h 4d 3h',
        {
            intra_space => '',
            extra_space => ' ',
            pluralize   => 0,
            unit_type   => 'letter',
            compress    => 1,
        },
    );
    # $z eq '1w 4d 1h'

    my $hours = $ud->sum_as( hours => '2 days -6h' );
    # $hours == 10

    my $ud_fully_described_with_defaults = Unit::Duration->new(
        name  => 'default',
        table => q{
            y | yr  | year    =  4 qtrs
            q | qtr | quarter =  3 mons
            o | mon | month   =  4 wks
            w | wk  | week    =  5 days
            d | day           =  8 hrs
            h | hr  | hour    = 60 mins
            m | min | minute  = 60 secs
            s | sec | second
        },
        intra_space => ' ',
        extra_space => ', ',
        pluralize   => 1,
        unit_type   => 'short',
        compress    => 0,
    );

    my $canonical_table_string    = $ud->get_table_string('default');
    my $canonical_table_structure = $ud->get_table_structure('default');

    $ud->set_table( default => $canonical_table_string );
    $ud->set_table(
        partial_default => [
            {
                letter   => 'd',
                short    => 'day',
                long     => 'day',
                duration => '8 hrs',
            },
            {
                letter   => 'h',
                short    => 'hr',
                long     => 'hour',
            },
        ],
    );

    my $duration_string = $ud->canonicalize(
        '3d 6h 1d 2h',
        {
            intra_space => ' ',
            extra_space => ', ',
            pluralize   => 1,
            unit_type   => 'short',
            compress    => 0,
        },
        'default', # table name or table string or table structure
    );

    my $hours_by_table = $ud->sum_as( hours => '2 days -6h', 'default' );

=head1 DESCRIPTION

This class provides the ability to "canonicalize" time durations based on custom
time units and their relationships to each other.

As an illustrative example, let's say you're a project manager dealing with
work-time duration estimates for a set of tasks. These might be weeks, days,
hours, or some combination of these units and/or other units. In the context of
work-time duration, 1 day does not equal 24 hours. The standard convention is  1
day equals 8 hours and 1 week equals 5 days. However, this is not universal. In
France, for example, the work week is typically 35 hours, not 40.

Assuming the default/typical case, though, let's say you have a task that's
estimated to take 12 hours. You can represent that duration as "12 hours" or
"12 hrs" or "1 day, 4 hours" or "1.5 days" or "1d 4h" or any number of other
ways.

=head1 TABLES

Exactly how many hours constitute a day and that "hrs" is the canonical
shortened form of "hours" is all setup with a duration table. A duration table
consists of rows of units and columns of data types. The following is the
default table (in string form):

    y | yr  | year    =  4 qtrs
    q | qtr | quarter =  3 mons
    o | mon | month   =  4 wks
    w | wk  | week    =  5 days
    d | day           =  8 hrs
    h | hr  | hour    = 60 mins
    m | min | minute  = 60 secs
    s | sec | second

Each unit must have a "letter" and "short" form and may have an optional "long"
form. Any unit without a "long" form will use its "short" form as such. (See
"day" for an example.) Each unit must conclude with a duration, which should
define the unit's duration relative to some lower unit. Ultimately, there needs
to be 1 and only 1 unit that is the "base" unit. In the default table, this is
"second".

For tables in string form, the separation of columns can be done using any
non-digit, non-letter character other than commas and semicolons. All spacing
is ignored. Tables in data form are an arrayref of hashrefs where each hashref
contains C<letter>, C<short>, optionally a C<long>, and a C<duration>.

    {
        letter   => 'd',
        short    => 'day',
        long     => 'day',
        duration => '8 hrs',
    }

Tables are parsed and stored by name. The default table is stored as "default".

=head1 METHODS

=head2 new

This method instantiates a Unit::Duration object. It requires no inputs, but it
can be supplied with a table (using the C<name> and C<table> keys) and any
number of settings. See L</"SETTINGS"> below.

    my $ud = Unit::Duration->new;

    my $ud_fully_described_with_defaults = Unit::Duration->new(
        name  => 'default',
        table => q{
            y | yr  | year    =  4 qtrs
            q | qtr | quarter =  3 mons
            o | mon | month   =  4 wks
            w | wk  | week    =  5 days
            d | day           =  8 hrs
            h | hr  | hour    = 60 mins
            m | min | minute  = 60 secs
            s | sec | second
        },
        intra_space => ' ',
        extra_space => ', ',
        pluralize   => 1,
        unit_type   => 'short',
        compress    => 0,
    );

=head2 canonicalize

This method requires a duration string to parse. It will return a canonicalized
string based on the settings and table used.

    my $x = $ud->canonicalize('4d 6h 4d 3h');
    # $x eq '8 days, 9 hrs'

It can optionally can accept settings overrides in a hashref. See
L</"SETTINGS"> below.

    my $y = $ud->canonicalize( '4d 6h 4d 3h', { compress => 1 } );
    # $y eq '1 wk, 4 days, 1 hr'

    my $z = $ud->canonicalize(
        '4d 6h 4d 3h',
        {
            compress    => 1,
            unit_type   => 'letter',
            intra_space => '',
            extra_space => ' ',
        },
    );
    # $z eq '1w 4d 1h'

It can also optionally be provided a table by name or as a string or data
structure.

    my $duration_string = $ud->canonicalize(
        '3d 6h 1d 2h',
        {
            intra_space => ' ',
            extra_space => ', ',
            pluralize   => 1,
            unit_type   => 'short',
            compress    => 0,
        },
        'default', # table name or table string or table structure
    );

=head2 sum_as

Thie method accepts a unit label and a duration string. It will return a number
representing the value of the duration as the unit.

    my $hours = $ud->sum_as( hours => '2 days -6h' );
    # $hours == 10

It can also optionally be provided a table by name or as a string or data
structure.

    my $hours = $ud->sum_as( hours => '2 days -6h', 'default' );

=head2 set_table

This method sets a table for later use. It requires a name string, which will
be used to label the table, and the table data as either a string or a data
structure.

    $ud->set_table( default => $canonical_table_string );
    $ud->set_table(
        partial_default => [
            {
                letter   => 'd',
                short    => 'day',
                long     => 'day',
                duration => [ 8, 'hrs' ],
            },
            {
                letter   => 'h',
                short    => 'hr',
                long     => 'hour',
            },
        ],
    );

=head2 get_table_string

This method returns a "canonical" table string for a given table label.

    my $canonical_table_string = $ud->get_table_string('default');

The "canonical" table string is not necessarily exactly the same as the input
string used to create the table. It's a uniform string, but it can be fed back
into C<set_table> and other methods if desired.

=head2 get_table_structure

This method returns a table as a data structure: an arrayref of hashrefs.

    my $canonical_table_structure = $ud->get_table_structure('default');

=head1 SETTINGS

Settings affect the way C<canonicalize> formats its output.

=head2 intra_space

This is a string and represents the space between a unit's numeric value and its
text label.

=head2 extra_space

This is a string and represents the space between different units.

=head2 pluralize

This is a boolean that sets whether units should be "pluralized" when they don't
have the value of 1. For example, if you input "2h", that will become "2 hrs"
if C<pluralize> is true or "2 hr" if C<pluralize> is false.

=head2 unit_type

This is the unit type to use for the unit label. This will be either "letter",
"short", or "long".

=head2 compress

By default, if you provide C<canonicalize> a string with repeated same units,
it will merge these values, but it will not shift values between units. For
example:

    my $x = $ud->canonicalize('4d 6h 4d 3h');
    # $x eq '8 days, 9 hrs'

By setting C<compress> to a true value, C<canonicalize> will shift values
between units. For example:

    my $y = $ud->canonicalize( '4d 6h 4d 3h', { compress => 1 } );
    # $y eq '1 week, 2 days, 1 hrs'

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Unit-Duration>

=item *

L<MetaCPAN|https://metacpan.org/pod/Unit::Duration>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Unit-Duration/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Unit-Duration>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Unit-Duration>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/U/Unit-Duration.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
