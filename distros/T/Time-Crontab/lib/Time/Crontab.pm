package Time::Crontab;

use 5.008005;
use strict;
use warnings;
use Carp qw/croak/;
use List::MoreUtils qw/all any uniq firstidx/;
use Set::Crontab;

our $VERSION = "0.04";

my @keys = qw/minute hour day month day_of_week/;
my @ranges = (
    [0..59], #minute
    [0..23], #hour
    [1..31], #day
    [1..12], #month
    [0..7], #day of week
);
my %month_strs = (
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct => 10,
    nov => 11,
    dec => 12,
);
my %dow_strs = (
    sun => 0,
    mon => 1,
    tue => 2,
    wed => 3,
    thu => 4,
    fri => 5,
    sat => 6,
);

sub includes {
    my ($list,$include) = @_;
    my %include = map {
        $_ => 1
    } @$include;
    all { exists $include{$_} } @$list;
}

sub new {
    my ($class,$str) = @_;
    my $self = bless {}, $class;
    $self->_compile($str);
    $self;
}

sub _compile {
    my ($self, $str) = @_;

    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;
    my @rules = split /\s+/, $str;
    croak 'incorrect cron field:'.$str if @rules != 5;
    my %rules;
    my $i=0;
    for my $rule_o ( @rules ) {
        my $rule = $rule_o;
        my $key = $keys[$i];
        my $range = $ranges[$i];
        if ( $key eq 'month' ) {
            my $replace = sub {
                my $month = lc(shift);
                exists $month_strs{$month} ? $month_strs{$month} : $month;
            };
            $rule =~ s!^([a-z]{3})$!$replace->($1);!ie;
        }
        if ( $key eq 'day_of_week' ) {
            my $replace = sub {
                my $dow = lc(shift);
                exists $dow_strs{$dow} ? $dow_strs{$dow} : $dow;
            };
            $rule =~ s!^([a-z]{3})$!$replace->($1)!ie;
        }
        my $set_crontab = Set::Crontab->new($rule, $range);
        my @expand = $set_crontab->list();
        croak "bad format $key: $rule_o($rule)" unless @expand;
        croak "bad range $key: $rule_o($rule)" unless includes(\@expand, $range);
        if ( $key eq 'day_of_week' ) {
            #day of week
            if ( any { $_ == 7 } @expand ) {
                unshift @expand, 0;
            }
            @expand = uniq @expand;
        }
        $rules{$key} = \@expand;
        $i++;
    }

    $self->{rules} = \%rules;
}

sub _contains {
    my ($self, $key, $num) = @_;
    any { $_ == $num  } @{$self->{rules}->{$key}};
}

sub _contains_any {
    my ($self, $key) = @_;
    my $key_i = firstidx { $_ eq $key} @keys;
    my $range = $ranges[$key_i];
    my $rule = $self->{rules}->{$key};

    if (@$range != @$rule) {
        return 0;
    }
    for my $idx (0..$#{$range}) {
        if ($range->[$idx] != $rule->[$idx]) {
            return 0;
        }
    }
    return 1;
}

sub match {
    my $self = shift;
    my @lt = localtime($_[0]);
    if ( $self->_contains('minute', $lt[1]) 
      && $self->_contains('hour', $lt[2])
      && $self->_contains('month', $lt[4]+1) ) {
        # dow and dom is a bit complicated
        if (
          $self->_contains_any('day') && $self->_contains_any('day_of_week')
          ||
          $self->_contains_any('day') && $self->_contains('day_of_week', $lt[6])
          ||
          $self->_contains('day', $lt[3]) && $self->_contains_any('day_of_week')
          ||
          ! $self->_contains_any('day') && ! $self->_contains_any('day_of_week') && (
          $self->_contains('day', $lt[3]) || $self->_contains('day_of_week', $lt[6]) )
         ) {
            return 1;
        }
        return;
    }
    return;
}

sub dump {
    shift->{rules};
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Crontab - parser for crontab date and time field

=head1 SYNOPSIS

    use Time::Crontab;

    my $time_cron = Time::Crontab->new('0 0 1 * *');
    if ( $time_cron->match(time()) ) {
        do_cron_job();
    }

=head1 DESCRIPTION

Time::Crontab is a parser for crontab date and time field. And 
it provides simple matcher.

=head1 METHOD

=over 4

=item new($crontab:Str)

Returns Time::Crontab object. If incorrect crontab string was given, Time::Crontab dies.

=item match($unix_timestamp:Num)

Returns whether or not the given unix timestamp matches the crontab
Timestamps are truncated to minute resolution.

=back

=head1 SUPPORTED SPECS

  Field name   Allowed values  Allowed special characters
  Minutes      0-59            * / , -
  Hours        0-23            * / , -
  Day of month 1-31            * / , -
  Month        1-12 or JAN-DEC * / , -
  Day of week  0-6 or SUN-SAT  * / , -

Predefined scheduling definitions are not supported. 
In month and day_of_week fields, Able to use the first three letters of day or month. But 
does not support range or list of the names.

=head1 RELATED MODULES

=over 4

=item L<DateTime::Event::Cron>

DateTime::Event::Cron that depends on DateTime. 
Time::Crontab does not require DateTime or Time::Piece.

=item L<Algorithm::Cron>

Algorithm::Cron also does not require DateTime. 
It's provides `next_time` method, Time::Crontab provides `match` method.

=back

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

