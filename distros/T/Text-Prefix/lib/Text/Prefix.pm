package Text::Prefix;

# ABSTRACT: Prepend strings with timestamps and potentially other contextually-relevant information.

use strict;
use warnings;

use Sys::Hostname;
use File::Valet qw(rd_f wr_f ap_f);
use Time::HiRes;
use Time::TAI::Simple;

use vars qw(@EXPORT @EXPORT_OK @ISA $VERSION);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    $VERSION = '1.00';
    @EXPORT = @EXPORT_OK = ();
}

sub new {
    my ($class, %opt_hr) = @_;
    my $self = {
        opt_hr   => \%opt_hr
    };
    bless ($self, $class);

    foreach my $k0 (keys %{$self->{opt_hr}}) {
        my $k1 = join('_', split(/-/, $k0));
        next if ($k0 eq $k1);
        $self->{opt_hr}->{$k1} = $self->{opt_hr}->{$k0};
        delete $self->{opt_hr}->{$k0};
    }

    $self->{data_label} = $self->opt('label', 'd');
    $self->{format}     = $self->opt('format','space');
    $self->{format}     = 'kvp' if ($self->opt('kvp'));
    $self->{host}       = hostname();
    $self->{host}       = $1 if ($self->{host} =~ /(.+?)\./);
    if (my $mask = $self->opt('host_sans')) {
        $self->{host}   = $1 if ($self->{host} =~ /(.+?)$mask$/);
    }
    $self->{perlcode}   = $self->opt('perl', '');
    if (my $pf = $self->opt('perlf')) {
        die "no such file (passed via perlf): '$pf'" unless (-e $pf);
        $self->{perlcode}   = File::Valet::rd_f($pf);
    }
    $ENV{HOSTNAME} = $ENV{HOST} = $self->{host} if ($self->{perlcode} ne '');
    if ($self->opt('order')) {
        $self->{order_ar} = [split(/\s*,\s*/, $self->opt('order'))];
    } else {
        my @order_list;
        push @order_list, 'lt' unless ($self->opt('no_date') || $self->opt('no_time') || $self->opt('no_human_date'));
        push @order_list, 'tm' unless ($self->opt('no_date') || $self->opt('no_time') || $self->opt('no_epoch'));
        push @order_list, 'hn' if     ($self->opt('host')    || $self->opt('host_sans'));
        push @order_list, 'st' if     ($self->opt('with'));
        push @order_list, 'pl' if     ($self->opt('perl')    || $self->opt('perlf'));
        push @order_list, $self->{data_label};
        $self->{order_ar} = \@order_list;
    }

    if (my $tai = $self->opt('tai')) {
        my $tai_mode = 'tai10';
        $tai_mode = 'tai35' if ($tai eq '35');
        $tai_mode = 'tai'   if ($tai eq '0');
        $self->{tai_or} = Time::TAI::Simple->new(mode => $tai_mode);
    }

    return $self;
}

sub prefix {
    my ($self, $s) = @_;
    ap_f($self->opt('pretee'), $s) if ($self->opt('pretee'));
    chomp($s);
    my $pl = '';
    $pl = join(' ', split(/[\r\n]+/, eval($self->{perlcode}))) if ($self->{perlcode} ne '');
    my $hr = {$self->{data_label} => $s};
    $hr->{tm} = $self->_tm() unless ($self->opt('no_date') || $self->opt('no_epoch'));
    $hr->{lt} = $self->_lt() unless ($self->opt('no_date') || $self->opt('no_human_date'));
    $hr->{hn} = $self->{host} if ($self->opt('host') || $self->opt('host_sans'));
    $hr->{st} = $self->opt('with') if ($self->opt('with'));
    $hr->{pl} = $pl if ($self->opt('perl') || $self->opt('perlf'));
    my $output = '';
    my $pad = $self->opt('no_space') ? '' : ' ';
    foreach my $k (@{$self->{order_ar}}) {
        next unless(defined($hr->{$k}));
        my $v = $hr->{$k};
        if ($self->{format} eq 'kvp') {
            $output .= "$k=$v\t";
        }
        elsif ($self->{format} eq 'csv') {
            $output .= "\"$v\",";
        }
        elsif ($self->{format} eq 'tab') {
            $output .= "$v\t";
        }
        else { # assume 'space'
            $output .= "$v$pad";
        }
    }
    chop($output) if ($pad);
    ap_f($self->opt('tee'), "$output\n") if ($self->opt('tee'));
    return $output;
}

sub _isotime {
   my ($self, $tm) = @_;
   $tm = $self->_tm() unless(defined($tm));
   my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($tm);
   my $iso_date = sprintf('%04d-%02d-%02d', $year + 1900, $mon + 1, $mday);
   my $iso_time = sprintf('%02d:%02d:%02d', $hour, $min, $sec);
   $iso_time .= substr($tm-int($tm), 1, 5) if ($self->opt('hires') || $self->opt('tai'));
   return "$iso_date $iso_time";
}

sub _tm {
    my ($self) = @_;
    my $tm;
    $tm = $self->{tai_or}->time() if (defined($self->{tai_or}));
    $tm = Time::HiRes::time() if ($self->opt('hires'));
    $tm = time() unless($tm);
    if ($tm =~ /\.\d+/) {
        if (length($tm) >= 15) {
            $tm  = substr($tm, 0, 15);
        } else {
            $tm .= '0'x(15-length($tm));
        }
    }
    return $tm;
}

sub _lt {
    my ($self, $tm) = @_;
    $tm = $self->_tm() unless(defined($tm));
    return $self->_isotime($tm) if ($self->opt('iso'));
    my $lt = localtime($tm);
    return substr($lt,  4, 15) if ($self->opt('short'));
    return substr($lt, 11,  5) if ($self->opt('shorter'));
    return $lt;
}

sub opt {
    my ($self, $name, $default_value, $alt_hr) = @_;
    return _def($self->{opt_hr}->{$name}, $alt_hr->{$name}, $default_value);
}

sub _def {
    foreach my $v (@_) { return $v if (defined($v)); }
    return undef;
}

1;

=head1 NAME

Text::Prefix - Prepend strings with timestamps and potentially other contextually-relevant information.

=head1 SYNOPSIS

    use Text::Prefix;

    # Simple case: prepend strings with timestamps.
    #
    my $px = Text::Prefix->new(); # default just prepends timestamp
    my $s = $px->prefix("some string");
    #
    # $s is now: "Fri Jun  9 16:45:25 2017 1497051925 some string"

    # More complex case: ISO timestamp, no epoch timestamp, high-resolution
    # TAI-10 time, hostname, and length of string, in CSV format
    #
    my $px = Text::Prefix->new(
        format   => 'csv',
        host     => 1,
        iso      => 1,
        no_epoch => 1,
        perl     => 'length($s)',
        tai      => 1
    );
    my $s = $px->prefix("another string");
    #
    # $s is now: '"2017-06-09 16:50:59.9161","xiombarg","14","another string"'

=head1 DESCRIPTION

B<Text::Prefix> contains the logic implementing the B<prefix(1)> utility (included in this package).  It takes arbitrary strings as 
input and produces output with various contextually-relevant information preceding the string.  A variety of output formats are also 
supported, as well as output field reordering.

This is handy, for instance, when tailing a logfile which does not contain timestamps.  B<prefix> adds a timestamp prefix to each 
line it is given.

=head1 METHODS

There are only two methods provided by this package, C<new> and C<prefix>.

=over 4

=item B<new> (%options)

=over 4

(Class method) Returns a new instance of B<Text::Prefix>.  The object's default attributes are overridden by any options given.

Currently the following attributes may be set:

=over 4

B<format> =E<gt> kvp, tab, csv, space

Format the output as a kvp (tab-delimited "key=value" pairs), tab-delimited, comma-delimited, or space-delimited values.

(default: "space")

B<hires> =E<gt> 0, 1

Set to 1 to use high-resolution timestamps.

(default: 0)

B<host> =E<gt> 0, 1

Set to 1 to prefix output with the local hostname.

(default: 0)

B<host_sans> =E<gt> regular expression string

Set to a string to exclude the matching part of the hostname from prefix.  Implies setting B<host>.

(default: none)

B<iso> =E<gt> 0, 1

Set to 1 to use ISO-8601 formatted timestamps (more or less).

(default: 0)

B<label> =E<gt> string

When output format is "kvp", use the provided string as the key value for the field containing the input string.

(default: "d")

B<no_date> =E<gt> 0, 1

Set to 1 to omit any timestamps from prefixed text (corresponding to output fields "lt" and "tm").

(default: 0)

B<no_human_date> =E<gt> 0, 1

Set to 1 to omit human-readable timestamps from prefixed text (corresponding to output field "lt").

(default: 0)

B<no_epoch> =E<gt> 0, 1

Set to 1 to omit epoch timestamps from prefixed text (corresponding to output field "tm").

(default: 0)

B<order> =E<gt> CSV string

Given a comma-separated list of key names, change the ordering of the named output fields.

Currently supported output fields are:

=over 4

B<lt> - Human-readable timestamp string (mnemonic, "localtime")

B<tm> - Epoch timestamp

B<hn> - Hostname

B<st> - Literal string provided via passing C<with> parameter to C<new>

B<pl> - Value returned by evaluating perl provided via C<perl> or C<perlf> parameters passed to C<new>

B<d> - Original input string, potentially modified via C<perl> or C<perlf> side-effects.  Key may be renamed via C<label> parameter.

=back

(default: "lt, tm, hn, st, pl, d")

B<perl> =E<gt> string containing perl code

The provided string will be C<eval()>'d for every line of input, and its return value included in the output prefix.  The input string is available to this code in the variable "$s".

(default: none)

B<perlf> =E<gt> filename

Just like B<perl> except the perl code is read from the given file.

(default: none)

B<pretee> =E<gt> filename

When provided, input is appended to the file of the given name before C<perl> evaluation or any other reformatting.

(default: none)

B<short> =E<gt> 0, 1

Set to 1 to shorten the human-readable timestamp field somewhat.

(default: 0)

B<shorter> =E<gt> 0, 1

Set to 1 to shorten the human-readable timestamp to only the hour and minute (HH:MM).

(default: 0)

B<tai> =E<gt> 0, 10, 35

When provided, timestamps will reflect TAI-0, TAI-10, or TAI-35 time instead of system time.  If option's value is anything other than 0 or 10 or 35, TAI-10 will be assumed.  See also: L<https://metacpan.org/pod/Time::TAI::Simple>.  TAI time is a high-resolution time, so a fractional second will be included in prefix timestamps.

(default: none)

B<tee> =E<gt> filename

Just like C<pretee>, but the output string will be appended to the named file.

(default: none)

B<with> =E<gt> string

When provided, the output will include the literal string in its prefix.

(default: none)

=back

=back

=item B<prefix> (string)

=over 4

Returns the given string after applying the formatting and prefixing rules passed to C<new>.

=back

=back

=head1 TODO

Since this module was implemented specifically to support the functionality of the C<prefix(1)> tool, it lacks some obvious features which a programmer using the module directly might expect:

=over 4

C<new> should probably take a C<coderef> option, to supplement C<perl> and C<perlf>.

C<new> should support a format option which causes C<prefix> to return a hashref or arrayref instead of a string.

=back

=head1 HISTORY

=over 4

C<prefix(1)> started life in 2001 as an extremely simple throwaway script.  Like many "throwaway" scripts, this one grew haphazardly with little 
regard to best practices.  The author has used it almost every day since then, and was intensely embarrassed by the state of its source code, but
it took him until 2017 to get around to refactoring it into C<Text::Prefix>.

=back

=head1 AUTHORS

=over 4

TTKCIAR <ttk@ciar.org>

=back

=head1 COPYRIGHT AND LICENSE

=over 4

Copyright (C) 2017 Bill "TTK" Moyer.  All rights reserved.

This library is free software.  You may use it, redistribute it and/or modify it under the same terms as Perl itself.

=back
