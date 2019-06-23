package Time::Strptime::Format;
use strict;
use warnings;
use utf8;
use integer;

use B;
use Carp ();
use Time::Local qw/timegm timegm_nocheck/;
use Encode qw/encode_utf8/;
use DateTime::Locale;
use List::MoreUtils qw/uniq/;
use POSIX qw/strftime LC_ALL/;
use Time::Strptime::TimeZone;

use constant DEBUG => exists $ENV{PERL_TIME_STRPTIME_DEBUG} && $ENV{PERL_TIME_STRPTIME_DEBUG};

our $VERSION = 1.04;

our %DEFAULT_HANDLER = (
    A   => [SKIP          => sub {
        my $self = shift;
        my $wide = $self->{locale}->day_format_wide;
        my $abbr = $self->{locale}->day_format_abbreviated;
        return [map quotemeta, uniq map { lc, uc, $_ } map { $wide->[$_], $abbr->[$_] } 0..6];
    }],
    a   => [extend        => q{%A} ],
    B   => [localed_month => sub {
        my $self = shift;

        unless (exists $self->{format_table}{localed_month}) {
            my %format_table;

            my $wide = $self->{locale}->month_format_wide;
            my $abbr = $self->{locale}->month_format_abbreviated;
            for my $month (0..11) {
                for my $key ($wide->[$month], $abbr->[$month]) {
                    $format_table{$key}    = $month + 1;
                    $format_table{lc $key} = $month + 1;
                    $format_table{uc $key} = $month + 1;
                }
            }
            $self->{format_table}{localed_month} = \%format_table;
        }

        return [map quotemeta, keys %{ $self->{format_table}{localed_month} }];
    } ],
    b   => [extend      => q{%B}],
    C   => ['UNSUPPORTED'],
    c   => ['UNSUPPORTED'],
    D   => [extend      => q{%m/%d/%Y}                    ],
    d   => [day         => ['0[1-9]','[12][0-9]','3[01]'] ],
    e   => [day         => [' [1-9]','[12][0-9]','3[01]'] ],
    F   => [extend      => q{%Y-%m-%d} ],
    G   => ['UNSUPPORTED'],
    g   => ['UNSUPPORTED'],
    H   => [hour24      => ['[01][0-9]','2[0-3]'] ],
    h   => [extend      => q{%B}                  ],
    I   => [hour12      => ['0[1-9]', '1[0-2]'] ],
    j   => [day365      => ['00[1-9]', '0[1-9][0-9]', '[12][0-9][0-9]','3[0-5][0-9]','36[0-6]'] ],
    k   => [hour24      => ['[ 1][0-9]','2[0-3]'] ],
    l   => [hour12      => [' [1-9]', '1[0-2]'] ],
    M   => [minute      => q{[0-5][0-9]}          ],
    m   => [month       => ['0[1-9]','1[0-2]']    ],
    n   => [SKIP        => q{\s+}                 ],
    p   => [localed_pm  => sub {
        my $self = shift;
        unless (exists $self->{format_table}{localed_pm}) {
            for my $pm (0, 1) {
                my $key = $self->{locale}->am_pm_abbreviated->[$pm];
                $self->{format_table}{localed_pm}{$key} = $pm;
            }
        }
        return [map quotemeta, keys %{ $self->{format_table}{localed_pm} }];
    }],
    R   => [extend      => q{%H:%M}               ],
    r   => [extend      => q{%I:%M:%S %p}         ],
    S   => [second      => ['[0-5][0-9]','60']    ],
    s   => [epoch       => q{[0-9]+}              ],
    T   => [extend      => q{%H:%M:%S}            ],
    t   => [char        => "\t"                   ],
    U   => ['UNSUPPORTED'],
    u   => ['UNSUPPORTED'],
    V   => ['UNSUPPORTED'],
    v   => [extend      => q{%e-%b-%Y} ],
    W   => ['UNSUPPORTED'],
    w   => ['UNSUPPORTED'],
    X   => ['UNSUPPORTED'],
    x   => ['UNSUPPORTED'],
    Y   => [year        => q{[0-9]{4}}],
    y   => ['UNSUPPORTED'],
    Z   => [timezone    => ['[-A-Z0-9]+', '[A-Z][a-z]+(?:/[A-Z][a-z]+)+']],
    z   => [offset      => ['[-+][0-9]{4}', 'Z']],
);

our %FIXED_OFFSET = (
    GMT => 0,
    UTC => 0,
    Z   => 0,
);

sub new {
    my ($class, $format, $options) = @_;
    $options ||= +{};

    my $self = bless +{
        format    => $format,
        time_zone => Time::Strptime::TimeZone->new($options->{time_zone}),
        locale    => DateTime::Locale->load($options->{locale} || 'C'),
        strict    => $options->{strict} || 0,
        _handler  => +{
            %DEFAULT_HANDLER,
            %{ $options->{handler} || {} },
        },
    } => $class;

    # compile and cache
    $self->_parser();

    return $self;
}

sub parse {
    my $self = shift;
    goto $self->_parser;
}

sub _parser {
    my $self = shift;
    return $self->{_parser} ||= $self->_compile_format;
}

sub _compile_format {
    my $self = shift;
    my $format = $self->{format};

    my $parser = do {
        # setlocale
        my $time_zone = $self->{time_zone};

        # assemble format to regexp
        my $handlers = join '', keys %{ $self->{_handler} };
        my @types;
        $format =~ s{([^%]*)?%([${handlers}])([^%]*)?}{
            my $prefix = quotemeta($1||'');
            my $suffix = quotemeta($3||'');
            $prefix.$self->_assemble_format($2, \@types).$suffix
        }geo;
        my %types_table = map { $_ => 1 } map {
            my $t = $_;
            $t =~ s/^localed_//;
            $t;
        } @types;

        # define vars
        my $vars = join ', ', uniq map { '$'.$_ } map {
            my $t = $_;
            $t =~ s/^localed_// ? ($_, $t) : $_;
        } @types, 'offset', 'epoch';
        my $captures = join ', ', map { '$'.$_ }  @types;

        # generate base src
        local $" = ' ';
        my $parser_src = <<EOD;
my ($vars);
\$offset = 0;
sub {
    ($captures) = \$_[0] =~ m{\\A$format\\z}mo
        or Carp::croak 'cannot parse datetime. text: "'.\$_[0].'", format: '.\%s;
\%s
    (\$epoch, \$offset);
};
EOD

        # generate formatter src
        my $formatter_src = '';
        for my $type (@types) {
            $formatter_src .= $self->_gen_stash_initialize_src($type);
        }
        $formatter_src .= $self->_gen_calc_epoch_src(\%types_table);
        $formatter_src .= $self->_gen_calc_offset_src(\%types_table);

        my $combined_src = sprintf $parser_src, B::perlstring(B::perlstring($self->{format})), $formatter_src;
        $self->{parser_src} = $combined_src;
        warn encode_utf8 "[DEBUG] src: $combined_src" if DEBUG;

        my $format_table = $self->{format_table} || {};
        eval $combined_src; ## no critic
    };
    die $@ if $@;

    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
    my ($type, $val) = @{ $self->{_handler}->{$c} };
    die "unsupported: \%$c. patches welcome :)" if $type eq 'UNSUPPORTED';

    # normalize
    if (ref $val) {
        $val = $self->$val($type) if ref $val eq 'CODE';
        $val = join '|', @$val    if ref $val eq 'ARRAY';
    }

    # assemble to regexp
    if ($type eq 'extend') {
        my $handlers = join '', keys %{ $self->{_handler} };
        $val =~ s{([^%]*)?%([${handlers}])([^%]*)?}{
            my $prefix = quotemeta($1||'');
            my $suffix = quotemeta($3||'');
            $prefix.$self->_assemble_format($2, $types).$suffix
        }ge;
        return $val;
    }
    else {
        return "(?:$val)"     if $type eq 'SKIP';
        return quotemeta $val if $type eq 'char';

        push @$types => $type;
        return "($val)";
    }
}

sub _gen_stash_initialize_src {
    my ($self, $type) = @_;

    if ($type eq 'timezone') {
        return <<'EOD';
    $time_zone->set_timezone($timezone);
EOD
    }
    elsif ($type =~ /^localed_([a-z]+)$/) {
        return <<EOD;
    \$${1} = \$format_table->{localed_${1}}->{\$localed_${1}};
EOD
    }
    else {
        return ''; # default: none
    }
}

sub _gen_calc_epoch_src {
    my ($self, $types_table) = @_;

    my $timegm = $self->{strict} ? 'timegm' : 'timegm_nocheck';

    # hour24&minute&second
    # year&day365 or year&month&day
    my $second        = $types_table->{second} ? '$second' : 0;
    my $minute        = $types_table->{minute} ? '$minute' : 0;
    my $hour          = $self->_gen_calc_hour_src($types_table);
    if ($types_table->{epoch}) {
        return ''; # nothing to do
    }
    elsif ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        return <<EOD;
    \$epoch = $timegm($second, $minute, $hour, \$day, \$month - 1, \$year);
EOD
    }
    elsif ($types_table->{year} && $types_table->{month}) {
        return <<EOD;
    \$epoch = $timegm($second, $minute, $hour, 1, \$month - 1, \$year);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        return <<EOD;
    \$epoch = $timegm($second, $minute, $hour, 1, 0, \$year) + (\$day365 - 1) * 60 * 60 * 24;
EOD
    }

    die 'unknown case. types: '. join ', ', keys %$types_table;
}

sub _gen_calc_offset_src {
    my ($self, $types_table) = @_;

    my $src = '';

    my $second = $types_table->{second} ? '$second' : 0;
    my $minute = $types_table->{minute} ? '$minute' : 0;
    my $hour   = $self->_gen_calc_hour_src($types_table);

    my $fixed_offset = $self->_fixed_offset($types_table);
    if (defined $fixed_offset) {
        if ($fixed_offset != 0) {
            $src .= sprintf <<'EOD', $fixed_offset;
    $offset -= %d;
EOD
        }
    }
    elsif ($types_table->{offset}) {
        $src .= <<'EOD';
    $offset = $offset eq 'Z' ? 0 : (abs($offset) == $offset ? 1 : -1) * (60 * 60 * substr($offset, 1, 2) + 60 * substr($offset, 3, 2));
EOD
    }
    else {
        $src .= <<EOD;
    \$offset = \$time_zone->offset(\$epoch);
EOD
    }

    if (!defined $fixed_offset && !$types_table->{epoch}) {
        $src .= <<'EOD'
    $epoch -= $offset;
EOD
    }

    return $src;
}

sub _gen_calc_hour_src {
    my ($self, $types_table) = @_;

    if ($types_table->{hour24}) {
        return '$hour24';
    }
    elsif ($types_table->{hour12} && $types_table->{pm}) {
        return '(0,12)[$pm] + ($hour12 % 12)';
    }
    else {
        return '0';
    }
}

sub _fixed_offset {
    my ($self, $types_table) = @_;
    return if $types_table->{offset};
    return if $types_table->{timezone};
    return if not exists $FIXED_OFFSET{$self->{time_zone}->name};
    return $FIXED_OFFSET{$self->{time_zone}->name};
}

1;
__END__

=encoding utf-8

=for stopwords strptime

=head1 NAME

Time::Strptime::Format - L<strptime(3)> format compiler and parser.

=head1 SYNOPSIS

    use Time::Strptime::Format;

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

This is L<Time::Strptime> engine.

=head1 METHODS

This class offers the following methods.

=head2 Time::Strptime::Format->new($format, \%args)

This methods creates a new format object. It accepts the following arguments:

=over 4

=item * time_zone

The default time zone to use for objects returned from parsing.

=item * locale

The locale to use for objects returned from parsing.

=item * strict

Strict range check for date and time.

Example. C<"2016-02-31"> is wrong date string, but Time::Strptime parses as C<2016-02-31> in default.

=back

=head2 $strptime->parse($string)

Given a string in the pattern specified in the constructor, this method will return the epoch and offset.
If given a string that doesn't match the pattern, the formatter will throw the error.

=head1 STRPTIME PATTERN TOKENS

The following tokens are allowed in the pattern string for strptime:

=over 4

=item * %%

The % character.

=item * %a or %A

The weekday name according to the current locale, in abbreviated form or the full name. (ignored)

=item * %b or %B or %h

The month name according to the current locale, in abbreviated form or the full name.

=item * %d or %e

The day of month (01-31). This will parse single digit numbers as well.

=item * %D

Equivalent to %m/%d/%y. (This is the American style date, very confusing to non-Americans, especially since %d/%m/%y is widely used in Europe. The ISO 8601 standard pattern is %F.)

=item * %F

Equivalent to %Y-%m-%d. (This is the ISO style date)

=item * %H

The hour (00-23). This will parse single digit numbers as well.

=item * %I

The hour on a 12-hour clock (1-12).

=item * %j

The day number in the year (1-366).

=item * %m

The month number (01-12). This will parse single digit numbers as well.

=item * %M

The minute (00-59). This will parse single digit numbers as well.

=item * %n

Arbitrary white-space. (ignored)

=item * %p

The equivalent of AM or PM according to the locale in use. (See L<DateTime::Locale>)

=item * %r

Equivalent to %I:%M:%S %p.

=item * %R

Equivalent to %H:%M.

=item * %s

Number of seconds since the Epoch.

=item * %S

The second (0-60; 60 may occur for leap seconds.).

=item * %t

Tab space. (ignored)

=item * %T

Equivalent to %H:%M:%S.

=item * %Y

A 4-digit year, including century (for example, 1991).

=item * %z

An RFC-822/ISO 8601 standard time zone specification. (e.g. +1100)

=item * %Z

The time zone name. (e.g. EST)

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
