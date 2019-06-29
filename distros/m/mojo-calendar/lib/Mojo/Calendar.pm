package Mojo::Calendar;
use Mojo::Base 'DateTime';

our $VERSION = '0.0.5';

use DateTime::Format::Flexible;

sub new {
    my $class = shift;
    my $args = @_;

    if (@_ > 1) {
        $args = { @_ };
    } else {
        if (ref $_[0] eq 'HASH') {
            $args = $_[0];
        } else {
            $args = { from => $_[0] };
        }
    }

    my $datetime;

    $args->{ locale } ||= 'en_gb';
    $args->{ time_zone } ||= 'Europe/London';

    if (my $from = delete($args->{ from })) {
        $datetime = DateTime::Format::Flexible->parse_datetime($from);
    }

    if (!$datetime) {
        $datetime = $class->SUPER::new(%$args);
    }

    my $self = $class->SUPER::new(
        year        => $datetime->year,
        month       => $datetime->month,
        day         => $datetime->day,
        hour        => $datetime->hour,
        minute      => $datetime->minute,
        second      => $datetime->second,
        nanosecond  => $datetime->nanosecond,
        locale      => $args->{ locale },
        time_zone   => $args->{ time_zone },
    );
    
    return $self;
}

sub days_ago {
    return shift
        ->clone
        ->subtract(days => shift);
}

sub days_from_now {
    return shift
        ->clone
        ->add(days => shift);
}

sub first_day_of_next_month {
    return shift
        ->clone
        ->set_day(1)
        ->months_from_now(1);
}

sub first_day_of_prev_month {
    return shift
        ->set_day(1)
        ->months_ago(1);
}

sub months_ago {
    return shift
        ->clone
        ->subtract(months => shift);
}

sub months_from_now {
    return shift
        ->clone
        ->add(months => shift);
}

sub today {
    return shift->clone;
}

sub tomorrow {
    return shift->days_from_now(1);
}

sub yesterday {
    return shift->days_ago(1);
}

1;

=encoding utf8

=head1 NAME

Mojo::Calendar - Extended DateTime manipulator

=head1 SYNOPSIS

    use Mojo::Calendar;

    # Calendar with default date being now
    my $calendar = Mojo::Calendar->new;

    say $calendar->ymd;
    say $calendar->his;

    say $calendar->tomorrow->ymd;

    # Calendar with default date being now
    my $calendar = Mojo::Calendar->new;

    say $calendar->ymd;
    say $calendar->his;

    # Calendar with default date being 2019-03-28 15:29:00
    my $calendar = Mojo::Calendar->new('2019-03-28 15:29:00');

    say $calendar->ymd;
    say $calendar->his;

=head1 DESCRIPTION

L<Mojo::Calendar> is a DateTime manipulator which includes humman readable methods.

=head1 ATTRIBUTES

L<Mojo::Calendar> inherits all attributes from L<DateTime>.

=head1 METHODS

L<Mojo::Calendar> inherits all methods from L<DateTime> and implements
the following new ones.

=head2 new

    my $datetime = Mojo::Calendar->new;

Calendar object.

=head2 days_ago

    my $datetime = $calendar->days_ago(2);

2 days since initial datetime.

=head2 days_from_now

    my $datetime = $calendar->days_from_now(2);

2 days from initial datetime.

=head2 first_day_of_next_month

    my $datetime = $calendar->first_day_of_next_month;

First day of next month from initial datetime.

=head2 first_day_of_prev_month

    my $datetime = $calendar->first_day_of_prev_month;

First day of previous month from initial datetime.

=head2 months_ago

    my $datetime = $calendar->months_ago(3);

3 months since initial datetime.

=head2 months_from_now

    my $datetime = $calendar->months_from_now(3);

3 months from initial datetime.

=head2 today

    my $datetime = $calendar->today;

today based on initial datetime.

=head2 tomorrow

    my $datetime = $calendar->tomorrow;

tomorrow based on initial datetime.

=head2 yesterday

    my $datetime = $calendar->yesterday;

yesterday based on initial datetime.

=head1 SEE ALSO

L<DateTime>, L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
