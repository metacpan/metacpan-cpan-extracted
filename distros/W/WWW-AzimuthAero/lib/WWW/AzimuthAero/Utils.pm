package WWW::AzimuthAero::Utils;
$WWW::AzimuthAero::Utils::VERSION = '0.31';

# ABSTRACT: functions that can be used outside WWW::AzimuthAero::* packages


use strict;
use warnings;
use feature 'say';
use Carp;
use Data::Dumper;

use List::Util qw/uniq/;
use JavaScript::V8;
use DateTime;
use DateTime::Format::Strptime;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
  get_next_dow_date
  get_next_dow_date_dmy
  get_dates_from_dows
  get_dates_from_range
  filter_dates
  sort_dates
  extract_js_glob_var
  iata_pairwise
  fix_html_string
);

# TO-DO: to_dt and from_dt methods

our %EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );


sub get_next_dow_date {
    my ( $date, $dow, $pattern ) = @_;

    $pattern = '%d.%m.%Y' unless defined $pattern;

    unless ( ref($date) eq 'DateTime' ) {
        $date = DateTime::Format::Strptime->new( pattern => $pattern )
          ->parse_datetime($date);
    }

    my $days_diff = $dow - $date->day_of_week;
    my $dur       = DateTime::Duration->new( days => $days_diff );
    return $date if ( $dur->is_zero );
    return $date->add_duration($dur) if ( $dur->is_positive );
    return $date->add( days => 7 - $dur->days ) if ( $dur->is_negative );
}

sub get_next_dow_date_dmy {
    my ( $date, $dow, $pattern ) = @_;
    get_next_dow_date( $date, $dow, $pattern )->dmy('.');
}


sub get_dates_from_dows {
    my (%params) = @_;

    #warn "get_dates() params : ".Dumper \%params;
    confess "max date is not defined" unless defined $params{max};
    confess "days of week (days variable) are not defined"
      unless defined $params{days};

    my @wdays = split( '', $params{days} );

    #say "wdays: ".Dumper \@wdays;

    # TO-DO: $dt_max: 4 month further
    my $dt_max = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' )
      ->parse_datetime( $params{max} );

    my $dt_min =
      ( defined $params{min} )
      ? ( DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' )
          ->parse_datetime( $params{min} ) )
      : ( DateTime->now->truncate( to => 'day' ) );

    # $dt_min = DateTime->now if ( $dt_min <= DateTime->now );

    my @res = ();
    for my $dow (@wdays) {
        my $next_target_dt = get_next_dow_date( $dt_min, $dow );
        while ( $next_target_dt <= $dt_max ) {

            # push @res, $next_target_dt; # strange behaviour if push datetime
            push @res, $next_target_dt->dmy('.');
            $next_target_dt =
              $next_target_dt + DateTime::Duration->new( weeks => 1 );
        }
    }

    return sort_dates(@res);
}


# This method used for filtering dates when no available_to property

sub get_dates_from_range {
    my (%params) = @_;

    # confess "min date is not defined" unless defined $params{min};
    # confess "max date is not defined" unless defined $params{max};

    my $dt_max =
      ( defined $params{max} )
      ? ( DateTime::Format::Strptime->new( pattern => '%d.%m.%Y' )
          ->parse_datetime( $params{max} ) )
      : ( DateTime->now->truncate( to => 'day' )->add( months => 2 ) );

    # my $dt_max = DateTime::Format::Strptime->new( pattern => '%d.%m.%Y' )
    #->parse_datetime( $params{max} );

    # DateTime->now->truncate include max_day
    my $dt_min =
      ( defined $params{min} )
      ? ( DateTime::Format::Strptime->new( pattern => '%d.%m.%Y' )
          ->parse_datetime( $params{min} ) )
      : ( DateTime->now->truncate( to => 'day' ) );

    my $next_dt = $dt_min;    ### TO-DO: round to midnight, '%Y-%m-%d 00:00:00'
    my @res;

    while ( DateTime->compare( $dt_max, $next_dt ) >= 0 ) {
        push @res, $next_dt->dmy('.');
        $next_dt = $next_dt->add( days => 1 );
    }

    return @res;

}


sub sort_dates {
    my @dates   = @_;
    my $pattern = '%d.%m.%Y';

    return map { $_->dmy('.') }
      sort { DateTime->compare( $a, $b ) }
      grep { DateTime->compare( $_, DateTime->now ) >= 0 }
      map {
        DateTime::Format::Strptime->new( pattern => $pattern )
          ->parse_datetime($_)
      } @dates;
}


sub filter_dates {
    my ( $dates, %params ) = @_;
    my $pattern = '%d.%m.%Y';

    confess "max date is not defined" unless defined $params{max};

    $params{max} = DateTime::Format::Strptime->new( pattern => $pattern )
      ->parse_datetime( $params{max} );

    carp "max date in past" if ( $params{max} < DateTime->now() );

    $params{min} =
      ( defined $params{min} )
      ? ( DateTime::Format::Strptime->new( pattern => $pattern )
          ->parse_datetime( $params{min} ) )
      : ( DateTime->now() );

    return map { $_->dmy('.') }
      grep { $_ >= $params{min} && $_ <= $params{max} }
      map {
        DateTime::Format::Strptime->new( pattern => $pattern )
          ->parse_datetime($_)
      } @$dates;
}


sub extract_js_glob_var {
    my ( $code_str, $var_name ) = @_;
    my $res;
    my $context = JavaScript::V8::Context->new();
    $context->eval($code_str);
    $context->bind( console_log => sub { $res = $_[0] } );
    $context->eval( 'console_log(' . $var_name . ')' );
    undef $context;
    return $res;
}


sub fix_html_string {
    my ($html_str) = @_;
    my $str = $html_str;
    $str =~ s/[\r\n\t]//g;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    # hack for deleting &nbsp; at flight_num
    $str =~ s/([A-Z1-9]).(\d{3})/$1 $2/;

    return $str;
}


sub iata_pairwise {
    my ($AoA) = @_;
    my @res;
    for my $x (@$AoA) {
        push @res, { from => $x->[0], via => $x->[1], to => $x->[2] };
    }
    return @res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::Utils - functions that can be used outside WWW::AzimuthAero::* packages

=head1 VERSION

version 0.31

=head1 DESCRIPTION

    Some useful date manipulation and filtering functions

=head1 FUNCTIONS

=head2 get_next_dow_date

Get next dow-date following by specified date

By default all input and output dates in '%d.%m.%Y' format, but you can easily specified needed one or deturn DateTime object

    get_next_dow_date( '7.06.2019', 7 )->dmy('.');  # '9.06.2019'
    get_next_dow_date( '7.06.2019', 3 )->dmy('.');  # '12.06.2019'

=head2 get_dates_from_dows

Get particular dates, based on min_date, max_date and days_of_week

min_date and max_date are in '%Y-%m-%d' format by default

    get_dates_from_dows( min => '2019-06-01', max => '2019-10-26', 'days' => '16' );

Return sorted array

TO-DO: carefully check for max day without min day (result may not include it)

=head2 get_dates_from_range

=head2 sort_dates

=head2 filter_dates

Filter dates by max and min dates

    filter_dates( \@dates, max => '15.06.2019' );
    filter_dates( \@dates, max => '15.06.2019', min => '07.06.2019' );

=head2 extract_js_glob_var

Extract global variable value from JavaScript code

=head2 fix_html_string

remove newline symbols, leading and trailing whitespaces

=head2 pairwise

Transform

    [ [ 'ROV', 'MOW', 'LED' ], [ 'ROV', 'KRR', 'LED' ] ]

to

    [ 
        { from => 'ROV', via => 'MOW', to => 'LED' },
        { from => 'ROV', via => 'KRR', to => 'LED' }
    ]

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
