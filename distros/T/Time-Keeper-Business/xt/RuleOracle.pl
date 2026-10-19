package Time::Keeper::Business::RuleOracle;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper;

my %KEYS = map { $_ => 1 } qw(kind month day day_of_week n offset orthodox rule days members name observed weekend from to only_if);
my %FORMS = map { $_ => 1 } qw(none next_business_day nearest_business_day next_monday);

sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub _is_rule {
    my $x = shift;
    return ref $x && eval { $x->isa(__PACKAGE__) } ? 1 : 0;
}

sub _new {
    my ($class, %a) = @_;
    my $what = "Time::Keeper::Business::Rule->$a{kind}";
    for my $k (keys %a) {
        _croak("$what: unknown argument '$k'") unless $KEYS{$k};
    }
    return bless {%a}, ref $class || $class;
}

sub _int {
    my ($what, $key, $v, $lo, $hi) = @_;
    _croak("$what: $key is needed") unless defined $v;
    _croak("$what: $key must be a whole number") if ref $v || $v !~ /\A-?\d+\z/;
    _croak("$what: $key must be $lo to $hi") if $v < $lo || $v > $hi;
    return $v + 0;
}

sub fixed {
    my ($class, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->fixed';
    my $m = _int($what, 'month', $a{month}, 1, 12);
    my $d = _int($what, 'day', $a{day}, 1, 31);
    _croak(sprintf '%s: --%02d-%02d is not a date', $what, $m, $d)
        unless Time::Keeper::Date->try_new(year => 2000, month => $m, day => $d);
    return $class->_new(%a, kind => 'fixed', month => $m, day => $d);
}

sub nth {
    my ($class, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->nth';
    my $m = _int($what, 'month', $a{month}, 1, 12);
    my $dow = _int($what, 'day_of_week', $a{day_of_week}, 1, 7);
    my $n = _int($what, 'n', $a{n}, -1, 5);
    _croak("$what: n is 1 to 5, or -1 for the last") if $n == 0;
    return $class->_new(%a, kind => 'nth', month => $m, day_of_week => $dow, n => $n);
}

sub easter {
    my ($class, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->easter';
    my $offset = _int($what, 'offset', $a{offset} // 0, -366, 366);
    return $class->_new(%a, kind => 'easter', offset => $offset, orthodox => $a{orthodox} ? 1 : 0);
}

sub relative {
    my ($class, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->relative';
    _croak("$what: rule must be a Time::Keeper::Business::Rule")
        unless _is_rule($a{rule});
    _croak("$what: rule must not be a set") if $a{rule}{kind} eq 'set';
    my $days = _int($what, 'days', $a{days}, -366, 366);
    return $class->_new(%a, kind => 'relative', days => $days);
}

sub set {
    my $class = shift;
    my $what = 'Time::Keeper::Business::Rule->set';
    my (@members, %a);
    while (@_) {
        my $x = shift;
        if (_is_rule($x)) {
            push @members, $x;
        }
        else {
            _croak("$what: a member is a rule, or a key with its value") if ref $x || !@_;
            $a{$x} = shift;
        }
    }
    _croak("$what: a set needs at least one rule") unless @members;
    return $class->_new(%a, kind => 'set', members => \@members);
}

sub _with {
    my ($self, %c) = @_;
    my $new = bless { %$self, %c }, ref $self;
    delete @{$new}{qw(memo weekend_set)};
    return $new;
}

sub observed {
    my ($self, $form, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->observed';
    _croak("$what: the form is none, next_business_day, nearest_business_day, next_monday or a code ref")
        unless defined $form && (ref $form eq 'CODE' || (!ref $form && $FORMS{$form}));
    for my $k (keys %a) {
        _croak("$what: unknown argument '$k'") unless $k eq 'weekend';
    }
    if (exists $a{weekend}) {
        _croak("$what: weekend is a list of days, 1 to 7") unless ref $a{weekend} eq 'ARRAY';
        _int($what, 'a weekend day', $_, 1, 7) for @{ $a{weekend} };
    }
    return $self->_with(observed => $form, (exists $a{weekend} ? (weekend => [ @{ $a{weekend} } ]) : ()));
}

sub between {
    my ($self, %a) = @_;
    my $what = 'Time::Keeper::Business::Rule->between';
    for my $k (keys %a) {
        _croak("$what: unknown argument '$k'") unless $k eq 'from' || $k eq 'to';
    }
    my %c;
    for my $k (qw(from to)) {
        $c{$k} = defined $a{$k} ? _int($what, $k, $a{$k}, -999999999, 999999999) : undef;
    }
    return $self->_with(%c);
}

sub only_if {
    my ($self, $code) = @_;
    _croak('Time::Keeper::Business::Rule->only_if: needs a code ref') unless ref $code eq 'CODE';
    return $self->_with(only_if => $code);
}

sub name { $_[0]{name} }

sub holidays {
    my $self = shift;
    my $what = 'Time::Keeper::Business::Rule->holidays';
    _croak("$what: takes year => \$y") if @_ % 2;
    my %a = @_;
    for my $k (keys %a) {
        _croak("$what: unknown argument '$k'") unless $k eq 'year';
    }
    my $year = _int($what, 'year', $a{year}, -999999999, 999999999);
    my $memo = $self->{memo}{$year} //= [ $self->_holidays($year) ];
    return map { [ @$_ ] } @$memo;
}

sub _holidays {
    my ($self, $year) = @_;
    my @out = $self->_compute($year);
    for my $y ($year - 1, $year + 1) {
        next unless grep { $_->{observed} } $self->_leaves($y);
        for my $pair ($self->_compute($y)) {
            push @out, $pair if $pair->[0]->year == $year;
        }
    }
    return sort { $a->[0] <=> $b->[0] } grep { $_->[0]->year == $year } @out;
}

sub _applies {
    my ($self, $year) = @_;
    return 0 if defined $self->{from} && $year < $self->{from};
    return 0 if defined $self->{to} && $year > $self->{to};
    return 0 if $self->{only_if} && !$self->{only_if}->($year);
    return 1;
}

sub _leaves {
    my ($self, $year) = @_;
    return () unless $self->_applies($year);
    return ($self) unless $self->{kind} eq 'set';
    return map { $_->_leaves($year) } @{ $self->{members} };
}

sub _weekend {
    my $self = shift;
    return $self->{weekend_set} ||= { map { $_ => 1 } @{ $self->{weekend} || [ 6, 7 ] } };
}

sub _compute {
    my ($self, $year) = @_;
    my $weekend = $self->_weekend;
    my (@rows, %taken, @out);
    for my $m ($self->_leaves($year)) {
        my $d = $m->_base($year) // next;
        push @rows, [ $m, $d ];
    }
    for my $r (@rows) {
        $taken{ $r->[1]->epoch_days } = 1 unless $r->[0]->_moves($r->[1], $weekend);
    }
    for my $r (@rows) {
        my ($m, $d) = @$r;
        if ($m->_moves($d, $weekend)) {
            $d = $m->_move($d, \%taken, $weekend) // next;
            $taken{ $d->epoch_days } = 1;
        }
        push @out, [ $d, $m->{name} ];
    }
    return @out;
}

sub _moves {
    my ($self, $d, $weekend) = @_;
    my $o = $self->{observed} // 'none';
    return 0 if $o eq 'none';
    return 1 if ref $o eq 'CODE';
    return $weekend->{ $d->day_of_week } ? 1 : 0;
}

sub _move {
    my ($self, $d, $taken, $weekend) = @_;
    my $o = $self->{observed};
    if (ref $o eq 'CODE') {
        my $r = $o->($d);
        _croak('Time::Keeper::Business::Rule: an observed code ref must give a Time::Keeper::Date or undef')
            if defined $r && !(ref $r && eval { $r->isa('Time::Keeper::Date') });
        return $r;
    }
    if ($o eq 'next_business_day') {
        do { $d = $d->plus(days => 1) } while $weekend->{ $d->day_of_week } || $taken->{ $d->epoch_days };
        return $d;
    }
    if ($o eq 'next_monday') {
        return $d->next(day_of_week => 1);
    }
    my ($back, $fwd) = ($d, $d);
    my ($nb, $nf) = (0, 0);
    do { $back = $back->plus(days => -1); $nb++ } while $weekend->{ $back->day_of_week };
    do { $fwd = $fwd->plus(days => 1); $nf++ } while $weekend->{ $fwd->day_of_week };
    return $nf < $nb ? $fwd : $back;
}

sub _base {
    my ($self, $year) = @_;
    my $kind = $self->{kind};
    if ($kind eq 'fixed') {
        return Time::Keeper::Date->try_new(year => $year, month => $self->{month}, day => $self->{day});
    }
    if ($kind eq 'nth') {
        my $first = Time::Keeper::Date->new(year => $year, month => $self->{month}, day => 1);
        return $first->last_in_month(day_of_week => $self->{day_of_week}) if $self->{n} == -1;
        return eval { $first->nth_in_month(day_of_week => $self->{day_of_week}, n => $self->{n}) };
    }
    if ($kind eq 'easter') {
        my $e = $self->{orthodox} ? _julian_easter($year) : _gregorian_easter($year);
        return $self->{offset} ? $e->plus(days => $self->{offset}) : $e;
    }
    if ($kind eq 'relative') {
        my $base = $self->{rule}->_base($year) // return undef;
        return $base->plus(days => $self->{days});
    }
    _croak("Time::Keeper::Business::Rule: a set has no date of its own");
}

sub _gregorian_easter {
    my $y = shift;
    my $a = $y % 19;
    my $b = int($y / 100);
    my $c = $y % 100;
    my $d = int($b / 4);
    my $e = $b % 4;
    my $f = int(($b + 8) / 25);
    my $g = int(($b - $f + 1) / 3);
    my $h = (19 * $a + $b - $d - $g + 15) % 30;
    my $i = int($c / 4);
    my $k = $c % 4;
    my $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7;
    my $m = int(($a + 11 * $h + 22 * $l) / 451);
    my $month = int(($h + $l - 7 * $m + 114) / 31);
    my $day = (($h + $l - 7 * $m + 114) % 31) + 1;
    return Time::Keeper::Date->new(year => $y, month => $month, day => $day);
}

sub _julian_easter {
    my $y = shift;
    my $a = $y % 4;
    my $b = $y % 7;
    my $c = $y % 19;
    my $d = (19 * $c + 15) % 30;
    my $e = (2 * $a + 4 * $b - $d + 34) % 7;
    my $month = int(($d + $e + 114) / 31);
    my $day = (($d + $e + 114) % 31) + 1;
    my $shift = int((14 - $month) / 12);
    my $yy = $y + 4800 - $shift;
    my $mm = $month + 12 * $shift - 3;
    my $jdn = $day + int((153 * $mm + 2) / 5) + 365 * $yy + int($yy / 4) - 32083;
    return Time::Keeper::Date->from_epoch_days($jdn - 2440588);
}

sub uk {
    my $class = shift;
    return $class->set(
        $class->fixed(month => 1, day => 1, name => "New Year's Day")->observed('next_business_day'),
        $class->easter(offset => -2, name => 'Good Friday'),
        $class->easter(offset => 1, name => 'Easter Monday'),
        $class->nth(month => 5, day_of_week => 1, n => 1, name => 'Early May bank holiday'),
        $class->nth(month => 5, day_of_week => 1, n => -1, name => 'Spring bank holiday'),
        $class->nth(month => 8, day_of_week => 1, n => -1, name => 'Summer bank holiday'),
        $class->fixed(month => 12, day => 25, name => 'Christmas Day')->observed('next_business_day'),
        $class->fixed(month => 12, day => 26, name => 'Boxing Day')->observed('next_business_day'),
        name => 'England and Wales',
    )->between(from => 2024);
}

sub us_federal {
    my $class = shift;
    return $class->set(
        $class->fixed(month => 1, day => 1, name => "New Year's Day")->observed('nearest_business_day'),
        $class->nth(month => 1, day_of_week => 1, n => 3, name => 'Birthday of Martin Luther King, Jr.')->between(from => 1986),
        $class->nth(month => 2, day_of_week => 1, n => 3, name => "Washington's Birthday"),
        $class->nth(month => 5, day_of_week => 1, n => -1, name => 'Memorial Day'),
        $class->fixed(month => 6, day => 19, name => 'Juneteenth National Independence Day')->observed('nearest_business_day')->between(from => 2021),
        $class->fixed(month => 7, day => 4, name => 'Independence Day')->observed('nearest_business_day'),
        $class->nth(month => 9, day_of_week => 1, n => 1, name => 'Labor Day'),
        $class->nth(month => 10, day_of_week => 1, n => 2, name => 'Columbus Day'),
        $class->fixed(month => 11, day => 11, name => 'Veterans Day')->observed('nearest_business_day'),
        $class->nth(month => 11, day_of_week => 4, n => 4, name => 'Thanksgiving Day'),
        $class->fixed(month => 12, day => 25, name => 'Christmas Day')->observed('nearest_business_day'),
        name => 'United States federal',
    )->between(from => 1971);
}

sub target2 {
    my $class = shift;
    return $class->set(
        $class->fixed(month => 1, day => 1, name => "New Year's Day"),
        $class->easter(offset => -2, name => 'Good Friday'),
        $class->easter(offset => 1, name => 'Easter Monday'),
        $class->fixed(month => 5, day => 1, name => 'Labour Day'),
        $class->fixed(month => 12, day => 25, name => 'Christmas Day'),
        $class->fixed(month => 12, day => 26, name => 'Christmas Holiday'),
        name => 'TARGET2',
    )->between(from => 2002);
}

1;

1;
