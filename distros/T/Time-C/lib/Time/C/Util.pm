use strict;
use warnings;
package Time::C::Util;
$Time::C::Util::VERSION = '0.024';
# ABSTRACT: Utility functions for Time::C and friends.

use Carp qw/ croak /;
use Data::Munge qw/ slurp /;
use File::Share qw/ dist_file /;
use Function::Parameters qw/ :strict /;
use Exporter qw/ import /;
use JSON::MaybeXS;

our @EXPORT_OK = qw/ get_fmt_tok get_locale /;

my $loc_db;

fun get_fmt_tok ($fmt, $pos) {
    return undef if $pos >= length $fmt;

    my $tok_len = substr($fmt, $pos, 1) eq '%' ? 2 : 1;

    my $tok = substr $fmt, $pos, $tok_len;

    while (($tok eq '%O') or ($tok eq '%E') or ($tok eq '%-')) {
        $tok .= substr($fmt, $pos + $tok_len, 1); $tok_len++;
    }

    $_[1] = $pos + $tok_len;
    return $tok;
}

fun get_locale($type, $locale) {
    if (not defined $loc_db) {
        my $fn = dist_file('Time-C', 'locale.db');
        open my $fh, '<', $fn
          or croak "Could not open $fn: $!";
        $loc_db = decode_json slurp $fh;
    }

    my $ret;
    if ($type eq 'weekdays') {
        $ret = $loc_db->{days}->{$locale};
    } elsif ($type eq 'weekdays_abbr') {
        $ret = $loc_db->{days_abbr}->{$locale};
    } elsif ($type eq 'months') {
        $ret = $loc_db->{months}->{$locale};
    } elsif ($type eq 'months_abbr') {
        $ret = $loc_db->{months_abbr}->{$locale};
    } elsif ($type eq 'am_pm') {
        $ret = $loc_db->{am_pm}->{$locale};
    } elsif ($type eq 'datetime') {
        $ret = $loc_db->{d_t_fmt}->{$locale};
    } elsif ($type eq 'date') {
        $ret = $loc_db->{d_fmt}->{$locale};
    } elsif ($type eq 'time') {
        $ret = $loc_db->{t_fmt}->{$locale};
    } elsif ($type eq 'time_ampm') {
        $ret = $loc_db->{r_fmt}->{$locale};
    } elsif ($type eq 'era') {
        $ret = $loc_db->{era}->{$locale} // [];
    } elsif ($type eq 'era_datetime') {
        $ret = $loc_db->{era_d_t_fmt}->{$locale} // $loc_db->{d_t_fmt}->{$locale};
    } elsif ($type eq 'era_time') {
        $ret = $loc_db->{era_t_fmt}->{$locale} // $loc_db->{t_fmt}->{$locale};
    } elsif ($type eq 'era_date') {
        $ret = $loc_db->{era_d_fmt}->{$locale} // $loc_db->{d_fmt}->{$locale};
    } elsif ($type eq 'digits') {
        $ret = $loc_db->{alt_digits}->{$locale} // [];
    } else { croak "Unknown locale type: $type."; }

    croak "Value for locale type $type in locale $locale is undefined."
      if not defined $ret;

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::C::Util - Utility functions for Time::C and friends.

=head1 VERSION

version 0.024

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
