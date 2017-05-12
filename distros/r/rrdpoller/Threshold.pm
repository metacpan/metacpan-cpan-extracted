package RRD::Threshold;

use strict;
use RRD::Query qw(isNaN);
use Error qw(:try);

# $Id: Threshold.pm,v 1.9 2004/12/07 12:53:56 rs Exp $
$RRD::Threshold::VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)/g;

=pod

=head1 NAME

RRD::Threshold - Check for thresholds exceeding values in RRD files data

=head1 DESCRIPTION

This Perl module is capable of extracting some RRD information and to
detect if the current value of a datasource is exeeding some
thresholds using different algorithms and the help of past values of
the same or other datasource.

=head1 CONSTRUCTOR

The constructor takes no arguments.

=cut

sub new
{
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $self = bless({}, $class);
    return $self;
}

=pod

=head1 METHODS

=head2 boundaries

    ($value, $bool) = boundaries($rrdfile, $ds, min => $min, max => $max)

This threshold takes too optional values, a minimum and a maximum
value. If the data source strays outside of this interval, it returns
false.

=head3 Options

=over 4

=item rrdfile

The path to the RRD file

=item ds

The name of the datasource. If the datasource contains comat (,), your
datasource will be interpreted as an RPN (Reverse Polish Notation)
expression (see L<Math::RPN>). If the C<Math::RPN> module isn't
loadable, an C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item min

If current value is lower than this argument, the function returns
false.

=item max

If current value is greater than this argument, the function returns
false.

=back

=head3 Throws

=over 4

=item Error::InvalidArgument

If min is greater than max

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub boundaries
{
    my($self, $rrdfile, $ds, %args) = @_;
    my($min, $max) = @args{qw(min max)};

    if(defined $min and defined $max && $min > $max)
    {
        throw Error::InvalidArgument("Min can't be greater than max value");
    }

    my $value;
    my $rrd = new RRD::Query($rrdfile);
    $value = $rrd->fetch($ds);

    if(isNaN($value))
    {
        throw Error::RRD::isNaN("Current value is NaN");
    }

    if(defined $min && $value < $min)
    {
        return($value, 0);
    }

    if(defined $max && $value > $max)
    {
        return($value, 0);
    }

    return($value, 1);
}

=pod

=head2 exact

    ($value, $bool) = exact($rrdfile, $ds, $exact)

This threshold allows you to monitor a datasource for an exact
match. This is useful in cases where an enumerated (or boolean) SNMP
object instruments a condition where a transition to a specific state
requires attention. For example, a datasource might return either
true(1) or false(2), depending on whether or not a power supply has
failed.

=head3 Options

=over 4

=item rrdfile

The path to the RRD file

=item ds

The name of the datasource. If the datasource contains comat (,), your
datasource will be interpreted as an RPN (Reverse Polish Notation)
expression (see L<Math::RPN>). If the C<Math::RPN> module isn't
loadable, an C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item exact

If the current value is different than this argument, the function
will return false.

=back

=head3 Throws

=over 4

=item Error::InvalidArgument

if exact argument isn't given

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub exact
{
    my($self, $rrdfile, $ds, $exact) = @_;

    if(!defined($exact))
    {
        throw Error::InvalidArgument("Missing mandatory option: exact");
    }

    my $rrd = new RRD::Query($rrdfile);
    my $value = $rrd->fetch($ds);

    if(isNaN($value))
    {
        throw Error::RRD::isNaN("Current value is NaN");
    }

    return($value, $exact == $value ? 1 : 0);
}

=pod

=head2 relation

    ($value, $bool) = relation($rrdfile, $ds, $threshold, %args,
                               cmp_rrdfile => $cmp_rrdfile,
                               cmp_ds      => $cmp_ds,
                               cmp_timp    => $cmp_time);


A relation threshold considers the difference between two data sources
(possibly from different RRD files), or alternatively, the difference
between two temporally distinct values for the same data source. The
difference can be expressed as absolute value, or as a percentage of
the second data source (comparison) value. This difference is compared
to a threshold argument with either the greater than (>) or lesser
than (<) operator. The criteria fails when the expression (<absolute
or relative difference> <either greater-than or less-than>
<threshold>) evaluates to false.

=head3 Options

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base datasource. The data source must belong to the
$rrdfile. If the datasource contains comat (,), your datasource will
be interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item threadhold

The threshold number, optionally preceded by the greater than (>) or
less than (<) symbol, and optionally followed by the symbol percent
(%). If omitted, greater than is used by default and the expression,
difference > threshold, is evaluated. "<10%", ">1000", "50%", and
"500" are all examples of valid thresholds.

=item cmp_rrdfile

The path of the comparison RRD file. This argument is optional and if
omitted the first RRD file is also taken as the comparison target.

=item cmp_ds

The name of the comparison data source. This data source must belong
to the comparison RRD file. This argument is optional and if omitted
the first data source name is also taken as the comparison data source
name.  If the value is a number, the value is considered as a fix
value and is taked for the comparison.

If the datasource contains comat (,), your datasource will be
interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>, C<10023>, C<-243.23>.

=item cmp_time

The temporal offset to go back in the RRD file that is being fetched
from for comparison from the current value. Note that a data source
value must exist in the RRD file for that exact offset. If This
argument is optional and if omitted, it is set to 0.

=back

=head3 Throws

=over 4

=item Error::InvalidArgument

on argument error

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub relation
{
    shift->_relation(0, @_);
}

=pod

=head2 quotient

    ($value, $bool) = quotient($rrdfile, $ds, $threshold, %args,
                               cmp_rrdfile => $cmp_rrdfile,
                               cmp_ds      => $cmp_ds,
                               cmp_timp    => $cmp_time);

Quotient thresholds are similar to relation thresholds, except that
they consider the quotient of two data sources, or alternatively, the
same data source at two different time points. For a quotient monitor
threshold, the value of the first data source is computed as a
percentage of the second data source value (such as 10 (first
datasource) is 50% of 20 (second datasource)). This percentage is then
compared to a threshold argument with either the greater than (>) or
less than (<) operator. The criteria fails when the expression
(<percentage> <either greater-than or less-than> <threshold>)
evaluates to false.

=head3 Options

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base datasource. The data source must belong to the
$rrdfile. If the datasource contains comat (,), your datasource will
be interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item threadhold

The threshold number, optionally preceded by the greater than (>) or
less than (<) symbol and followed by the symbol percent (%). If
omitted, greater than is used by default and the expression,
difference > threshold, is evaluated. "<10%" and "50%" are examples of
valid thresholds.

=item cmp_rrdfile

The path of the comparison RRD file. This argument is optional and if
omitted the first RRD file is also taken as the comparison target.

=item cmp_ds

The name of the comparison data source. This data source must belong
to the comparison RRD file. This argument is optional and if omitted
the first data source name is also taken as the comparison data source
name.  If the value is a number, the value is considered as a fix
value and is taked for the comparison.

If the datasource contains comat (,), your datasource will be
interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>, C<10023>, C<-243.23>.

=item cmp_time

The temporal offset to go back in the RRD file that is being fetched
from for comparison from the current value. Note that a data source
value must exist in the RRD file for that exact offset. If This
argument is optional and if omitted, it is set to 0.

=back

=head3 Throws

=over 4

=item Error::InvalidArgument

on argument error

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub quotient
{
    shift->_relation(1, @_);
}

sub _relation
{
    my($self, $quotient, $rrdfile, $ds, $threshold, %args) = @_;
    my($cmp_rrdfile, $cmp_ds, $cmp_time) =
      @args{qw(cmp_rrdfile cmp_ds cmp_time)};

    if(!defined($threshold) || !($threshold =~ s/^([<>]?)\s*(\d+)\s*(%?)$/$2/))
    {
        throw Error::InvalidArgument("Threshold argument syntax error: $threshold");
    }

    my $cmp = $1 || '>';
    my $pct = $3 ? 1 : 0;

    if($quotient)
    {
        if(!$pct)
        {
            throw Error::InvalidArgument("Threshold have to be a percentage");
        }
    }

    $cmp_rrdfile ||= $rrdfile;
    $cmp_ds ||= $ds;
    $cmp_time ||= 0;

    my $rrd = new RRD::Query($rrdfile);
    my $value = $rrd->fetch($ds);

    if(isNaN($value))
    {
        throw Error::Simple("Current value is NaN");
    }

    # Test if the comp_ds is a straight comparison value or should be fetched
    # as a DS
    my $cmp_value;
    if($cmp_ds =~ /^[+-]?\d*\.?\d+$/)
    {
        $cmp_value = $cmp_ds;
    }
    else
    {
        my $rrd = new RRD::Query($cmp_rrdfile);
        $cmp_value = $rrd->fetch($cmp_ds, cf => 'AVERAGE', offset => $cmp_time);

        if(isNaN($cmp_value))
        {
            throw Error::RRD::isNaN("Comparison value is NaN");
        }
    }

    my $difference = abs($cmp_value - $value);

    # threshold is a percentage
    if($pct)
    {
        # avoid division by 0
        if($cmp_value == 0)
        {
            if($difference == 0 && $cmp eq ($quotient ? '>' : '<'))
            {
                return($value, 1);
            }
            else
            {
                return($value, 0);
            }
        }

        if($quotient)
        {
            $difference = $difference / abs($cmp_value) * 100;
        }
        else
        {
            $difference = abs($value / $cmp_value) * 100;
        }
    }

    if($cmp eq '<')
    {
        return($value, $difference < $threshold ? 0 : 1);
    }
    else
    {
        return($value, $difference > $threshold ? 0 : 1);
    }
}

=pod

=head2 hunt

    ($value, $bool) = hunt($rrdfile, $ds, $roll,
                           cmp_rrdfile => $cmp_rrdfile,
                           cmp_ds      => $cmp_ds)

The hunt threshold is designed for the situation where the data source
serves as an overflow for another data source; that is, if one data
source (the parent) is at or near capacity, then traffic will begin to
appear on this (the monitored) data source. One application of hunt
monitor thresholds is to identify premature rollover in a set of modem
banks configured to hunt from one to the next. Specifically, the
criteria of the hunt monitor threshold fails if the value of the
monitored data source is non-zero and the current value of the parent
data source falls below a specified capacity threshold.

=head3 Option

=over 4

=item rrdfile

The path of the base RRD file.

=item ds

The name of the base datasource. The data source must belong to the
$rrdfile. If the datasource contains comat (,), your datasource will
be interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=item roll

The threshold of the parent data source. Generally this should be
slightly less than the maximum capacity of the target.

=item cmp_rrdfile

The path of the parent RRD file. This argument is optional and if
omitted the base RRD file is also taken as the parent.

=item cmp_ds

The name of the comparison data source. This data source must belong
to the parent RRD file. This argument is optional and if omitted the
first data source name is also taken as the comparison data source
name.

If the datasource contains comat (,), your datasource will be
interpreted as an RPN (Reverse Polish Notation) expression (see
L<Math::RPN>). If the C<Math::RPN> module isn't loadable, an
C<Error::RRD::Feature> exception is thrown.

Some valide examples of datasource would be: C<ifError>,
C<high_mem,low_mem,+>.

=back

=head3 Throws

=over 4

=item Error::InvalidArgument

if roll argument isn't given

=item Error::RRDs

on RRDs library error

=item Error::RRD::isNaN

if fetched value is Not a Number

=item Error::RRD::NoSuchDS

if the given datasource can't be found in the RRD file

=back

=cut

sub hunt
{
    my($self, $rrdfile, $ds, $roll, %args) = @_;
    my($cmp_rrdfile, $cmp_ds) = @args{qw(cmp_rrdfile cmp_ds)};

    if(!defined($roll))
    {
        throw Error::InvalidArgument("Missing mandatory option: roll");
    }

    my $cmp_rrdfile ||= $rrdfile;
    my $cmp_ds ||= $ds;

    my $rrd = new RRD::Query($rrdfile);
    my $value = $rrd->fetch($ds);

    if(isNaN($value))
    {
        throw Error::RDD::isNaN("Current value is NaN");
    }

    if($value == 0)
    {
        # no rollover, test succeeded
        return($value, 1);
    }

    my $rrd = new RRD::Query($cmp_rrdfile);
    my $cmp_value = $rrd->fetch($cmp_ds);

    if(isNaN($cmp_value))
    {
        throw Error::RRD::isNaN("Hunted value is NaN");
    }

    return($value, $cmp_value >= $roll);
}

=pod

=head2 failure

Aberrant Behavior Detection failure detection.

not yet implemented

=cut

sub failure
{
}

=pod

=head1 EXCEPTIONS CLASSES

=head2 Error::InvalidArgument

=cut

package Error::InvalidArgument;

use base qw(Error::Simple);

=pod

=head1 AUTHOR

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt>

=head1 LICENCE

RRD::Threshold, checks for thresholds exceeding values in RRD files
data.
Copyright (C) 2004  Olivier Poitrey

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 SEE ALSO

L<RRDs>, L<rrdgraph>, L<RRD::Query>, L<Error>

=cut

1;
