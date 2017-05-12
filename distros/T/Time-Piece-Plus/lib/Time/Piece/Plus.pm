package Time::Piece::Plus;
use strict;
use warnings;
use 5.010_001;

our $VERSION = '0.05';

use parent qw/Time::Piece/;

use Scalar::Util ();

sub import {
    my $class  = shift;
    my $caller = caller;
    for my $method (qw(localtime gmtime)) {
        my $code = sub {
            my $invocant = $_[0] && Scalar::Util::blessed($_[0]) ? shift : $class;
            $invocant->$method(@_)
        };
        {
            no strict 'refs';
            *{"$caller\::$method"} = $code; ## no critic
        }
    }
}

use Time::Seconds;
use Data::Validator;

sub get_object {
    my $invocant = shift;

    my $object = ref $invocant ? $invocant : $invocant->localtime;
    return $object;
}

sub reparse {
    state $validator = Data::Validator->new(
        format_string => {isa => 'Str'},
        parse_string  => {isa => 'Str', default => sub{$_[2]->{format_string}}},
    )->with(qw(Method));
    my ($self, $args) = $validator->validate(@_);

    $self->strptime($self->strftime($args->{format_string}), $args->{parse_string});
}

sub get_is_local {
    my $invocant = shift;

    return ref $invocant ? $invocant->[10] : 1;
}

sub get_time_diff {
    my $self = shift;
    return $self->sec + $self->min * 60 + $self->hour * 3600;
}

sub get_method_name {
    my $invocant = shift;

    return $invocant->get_is_local ? 'localtime' : 'gmtime';
 }

sub yesterday {
    my $invocant = shift;

    my $self   = $invocant->get_object;
    my $epoch  = $self->epoch;
    my $method = $self->get_method_name;

    $self->$method($epoch - ONE_DAY - $self->get_time_diff);
}

sub tomorrow {
    my $invocant = shift;

    my $self   = $invocant->get_object;
    my $epoch  = $self->epoch;
    my $method = $self->get_method_name;

    $invocant->$method($epoch + ONE_DAY - $self->get_time_diff);
}

sub today {
    my $invocant = shift;

    my $self   = $invocant->get_object;
    my $epoch  = $self->epoch;
    my $method = $self->get_method_name;

    $invocant->$method($epoch - $self->get_time_diff);
}

my %TRUNCATE_FORMAT = (
    minute  => '%Y%m%d%H%M00',
    hour    => '%Y%m%d%H0000',
    day     => '%Y%m%d000000',
    month   => '%Y%m01000000',
    year    => '%Y0101000000',
);

use Mouse::Util::TypeConstraints;

enum 'Time::Piece::Plus::ColumTypes' => keys %TRUNCATE_FORMAT;

no Mouse::Util::TypeConstraints;

sub truncate {
    state $validator = Data::Validator->new(
        to => {isa => 'Time::Piece::Plus::ColumTypes'},
    )->with(qw(Method));
    my ($self, $args) = $validator->validate(@_);
    my $format = $TRUNCATE_FORMAT{$args->{to}};
    $self = $self->get_object;
    return $self->reparse(format_string => $format);
}

sub parse_mysql_date {
    state $validator = Data::Validator->new(
        str          => {isa => 'Str'},
        as_localtime => {isa => 'Bool', default => 1},
    )->with(qw(Method));
    my ($class, $args) = $validator->validate(@_);

    return if $args->{str} eq "0000-00-00";

    my $self = $args->{as_localtime} ? $class->localtime() : $class->gmtime();
    my $parsed = $self->strptime($args->{str}, '%Y-%m-%d');

    return $parsed;
}

sub parse_mysql_datetime {
    state $validator = Data::Validator->new(
        str => {isa => 'Str'},
        as_localtime => {isa => 'Bool', default => 1},
    )->with(qw(Method));
    my ($class, $args) = $validator->validate(@_);

    return if $args->{str} eq "0000-00-00 00:00:00";

    my $self = $args->{as_localtime} ? $class->localtime() : $class->gmtime();
    my $parsed = $self->strptime($args->{str}, '%Y-%m-%d %H:%M:%S');

    return $parsed;
}

sub mysql_date {
    my ($self, ) = @_;
    $self = $self->get_object;
    return $self->strftime("%Y-%m-%d");
}
sub mysql_datetime {
    my ($self, ) = @_;
    $self = $self->get_object;
    return $self->strftime("%Y-%m-%d %H:%M:%S");
}

sub add {
    my ($self, @args) = @_;
    return $self->SUPER::add(@args) if @args <= 1;

    my %args = @args;
    my $seconds = $self->_calc_seconds(%args);
    $self = $self->SUPER::add($seconds);

    $self = $self->add_months($args{months}) if $args{months};
    $self = $self->add_years($args{years})   if $args{years};

    $self;
}

sub subtract {
    my ($self, @args) = @_;
    return $self->SUPER::subtract(@args) if @args <= 1;

    my %args = @args;
    my $seconds = $self->_calc_seconds(%args);
    $self = $self->SUPER::subtract($seconds);

    $self = $self->add_months(-1 * $args{months}) if $args{months};
    $self = $self->add_years(-1 * $args{years})   if $args{years};

    $self;
}

sub _calc_seconds {
    my $self = shift;

    state $validator = Data::Validator->new(
        seconds => {isa => 'Int', optional => 1},
        minutes => {isa => 'Int', optional => 1},
        hours   => {isa => 'Int', optional => 1},
        days    => {isa => 'Int', optional => 1},
        months  => {isa => 'Int', optional => 1},
        years   => {isa => 'Int', optional => 1},
    );
    my $args = $validator->validate(@_);

    my $seconds = 0;
    $seconds += $args->{seconds}              if exists $args->{seconds};
    $seconds += ONE_MINUTE * $args->{minutes} if exists $args->{minutes};
    $seconds += ONE_HOUR   * $args->{hours}   if exists $args->{hours};
    $seconds += ONE_DAY    * $args->{days}    if exists $args->{days};

    $seconds;
}


1;
__END__

=encoding utf-8

=head1 NAME

Time::Piece::Plus - Subclass of Time::Piece with some useful method

=head1 SYNOPSIS

  use Time::Piece::Plus;

  my $now = localtime();
  my $today = Time::Piece::Plus->today;

  #As class method
  my $today     = Time::Piece::Plus->today;
  my $yesterday = Time::Piece::Plus->yesterday;
  my $tomorrow  = Time::Piece::Plus->tomorrow;

  #As instance method
  my $time = Time::Piece::Plus->yesterday;
  my $two_days_ago = $time->yesterday;
  my $today = $time->tomorrow;

  #returns hour truncated object
  $time->truncate(to => 'day');

  #parse MySQL DATE
  my $gm_date    = Time::Piece::Plus->parse_mysql_date(str => "2011-11-26", as_localtime => 0);
  my $local_date = Time::Piece::Plus->parse_mysql_date(str => "2011-11-26", as_localtime => 1);
  #default is localtime
  my $local_date = Time::Piece::Plus->parse_mysql_date(str => "2011-11-26");

  #parse MySQL DATETIME
  my $gm_datetime    = Time::Piece::Plus->parse_mysql_datetime(str => "2011-11-26 23:28:50", as_localtime => 0);
  my $local_datetime = Time::Piece::Plus->parse_mysql_datetime(str => "2011-11-26 23:28:50", as_localtime => 1);
  #default is localtime
  my $datetime       = Time::Piece::Plus->parse_mysql_datetime(str => "2011-11-26 23:28:50");

  #calculete
  my $date = localtime();
  $date = $date->add(10);
  $date = $date->add(Time::Seconds->new(10);
  $date = $date->add(days => 1, hours => 12);
  $date = $date + 3600;

  $date = $date->subtract(10);
  $date = $date->subtract(Time::Seconds->new(10);
  $date = $date->subtrace(days => 1, hours => 12);
  $date = $date - 3600;
  $time_seconds = $date - Time::Piece::Plus->today;

=head1 DESCRIPTION

Time::Piece::Plus is subclass of Time::Piece with some useful method.

=head1 METHODS

=head2 today

If called as a class method returns today.
Also, if called as an instance method returns the day.
And time is cut.

=head2 yesterday

If called as a class method returns yesterday.
Also, if called as an instance method returns the previous day.
And time is cut.

=head2 tomorrow

If called as a class method returns tomorrow.
Also, if called as an instance method returns the next day.
And time is cut.

=head2 truncate

Cut the smaller units than those specified.
For example, "day" if you will cut the time you specify.
2011-11-26 02:13:22 -> 2011-11-26 00:00:00
Each unit is a minimum cut.

=head2 parse_mysql_date

Parse MySQL DATE string like "YYYY-mm-dd".
as_localtime is optional, default is 1.

=head2 parse_mysql_datetime

Parse MySQL DATETIME string like "YYYY-mm-dd HH:MM:SS".
as_localtime is optional, default is 1.

=head2 mysql_date

Format MySQL DATE string like "YYYY-mm-dd".
If you call a class method and returns the format today.
Also, if called as an instance method returns the date and format of the instance.

=head2 mysql_datetime

Format MySQL DATE string like "YYYY-mm-dd HH:MM:SS".
If you call a class method and returns the format now.
Also, if called as an instance method returns the date and format of the instance.

=head2 add(Int|Time::Seconds|Hash)

=head2 subtract(Int|Time::Seconds|Time::Piece|Hash)

Calculate and return new Time::Piece::Plus or Time::Seconds object using specified argument.
If you specify Int, Time::Seconds or Time::Piece(::Plus)?, behavior is same as
original Time::Piece. Operator overload is also available.

If you specify Hash(not HashRef), behavior is similar to L<DateTime>'s these methods.
But, they don't change object itself and returns new object.
Available Hash keys are as follows, and Hash values are Int.

=over

=item seconds

=item hours

=item days

=item months

=item years

=back

=head1 AUTHOR

Nishibayashi Takuji E<lt>takuji {at} senchan.jpE<gt>

=head1 SEE ALSO

L<Time::Piece>,L<Time::Piece::MySQL>,L<DateTime>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
