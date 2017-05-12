
package XML::SRS::TimeStamp::Role;
BEGIN {
  $XML::SRS::TimeStamp::Role::VERSION = '0.09';
}

use 5.010;
use XML::SRS::Date;
use XML::SRS::Time;
use Moose::Role;
use MooseX::Params::Validate;

use MooseX::Timestamp qw();
use MooseX::TimestampTZ
	timestamptz => { -as => "_timestamptz" },
	epoch => { -as => "_epoch" },
	;

has 'timestamp' =>
	is => "rw",
	isa => "Timestamp",
	coerce => 1,
	lazy => 1,
	default => sub {
	my $self = shift;
	sprintf(
		"%.4d-%.2d-%.2d %.2d:%.2d:%.2d",
		$self->year, $self->month, $self->day,
		$self->hour, $self->minute, $self->second//0,
	);
	},
	;

sub buildargs_timestamp {
    my $inv = shift;
    my ( $timestamp ) = pos_validated_list(
        \@_,
        { isa => 'Timestamp', coerce => 1 },
    );    
    
	my ($date, $time) = split " ", $timestamp;
	($inv->buildargs_time($time), $inv->buildargs_date($date));
}

sub buildargs_timestamptz {
    my $inv = shift;
    my ( $timestamptz ) = pos_validated_list(
        \@_,
        { isa => 'TimestampTZ', coerce => 1 },
    );    
    
	$timestamptz =~ m{
		(?<ymd>\d+-\d+-\d+)
		\s(?<hms>\d+:\d+:\d+)
		(?: (?<utc>Z) | (?<offset> [+-]\d{2} (?::?\d{2})? )
		)}x or warn "$timestamptz didn't match";
	my $hms = $+{hms};
	my $ymd = $+{ymd};
	my $offset = $+{utc} ? "+00:00" : $+{offset};
	(   $inv->buildargs_time($hms, $offset),
		$inv->buildargs_date($ymd)
	);
}

sub buildargs_epoch {
    my $inv = shift;
    my ( $epoch ) = pos_validated_list(
        \@_,
        { isa => 'time_t', coerce => 1 },
    );    
    
	$inv->buildargs_timestamptz(_timestamptz $epoch);
}

has 'timestamptz' =>
	is => "rw",
	isa => "TimestampTZ",
	coerce => 1,
	lazy => 1,
	default => sub {
	my $self = shift;
	sprintf(
		"%.4d-%.2d-%.2d %.2d:%.2d:%.2d%s",
		$self->year, $self->month, $self->day,
		$self->hour, $self->minute, $self->second//0,
		$self->tz_offset//"",
	);
	},
	;

has 'epoch' =>
	is => "rw",
	isa => "time_t",
	coerce => 1,
	lazy => 1,
	default => sub {
	my $self = shift;
	_epoch $self->timestamptz;
	},
	;

with 'XML::SRS::Date', 'XML::SRS::Time';

1;

__END__

=head1 NAME

XML::SRS::TimeStamp::Role - composable timestamp attributes

=head1 SYNOPSIS

 package XML::SRS::Some::Class;
 use Moose;

 with 'XML::SRS::TimeStamp::Role', 'XML::SRS::Node';


=head1 DESCRIPTION

Sometimes, in the SRS schema, a timestamp is represented with its own
node, C<E<lt>TimeStampE<gt>>;

  <TimeStamp Hour="12" Minute="24" Second="0"
             Day="31" Month="1" Year="2010"
             TZOffset="+12:00" />

For this purpose, the concrete class L<XML::SRS::TimeStamp> is used.

However, when the attributes which represent the also appear alongside
other child elements or attributes, a concrete class would not be
appropriate to re-use.  In that case, the role
L<XML::SRS::TimeStamp::Role> must be composed.

An example of this is the L<XML::SRS::Domain::Transferred> class, as
in:

  <DomainTransfer
             Hour="12" Minute="24" Second="0"
             Day="31" Month="1" Year="2010"
             TZOffset="+12:00">
    <TransferredDomain>foo.co.nz</TransferredDomain>
  </DomainTransfer>

To avoid repetition, this class exists.

It also adds various properties and psuedo-properties for convenience,
such as:

=over

=item B<timestamptz>

(cached, derived, psuedo) this is a psuedo-property, which returns the value
of the timestamp within as an ISO-8601 timestamp, without the T, and
with a timezone offset (defaulting to the offset of this time
according to local rules).  The L<XML::SRS::TimeStamp> class has a
BUILDARGS class method which allows this to be a "psuedo-property";
you can pass it to C<XML::SRS::TimeStamp-E<gt>new>, and it will fill
in all the other required accessors.

eg

   XML::SRS::TimeStamp->new(
        timestamptz => "2010-12-12 12:12:12+12:00",
   );

Will create an object:

   bless(
       {
           'hour' => '12',
           'month' => '12',
           'second' => '12',
           'tz_offset' => '+1200',
           'minute' => '12',
           'day' => '12',
           'timestamptz' => '2010-12-12 12:12:12+1200',
           'year' => '2010'
       },
       'XML::SRS::TimeStamp'
   );

=item B<timestamp>

(cached, derived, psuedo) Like B<timestamp>, but you don't end up
setting the C<tz_offset> property if passed in for construction, and
it does not have a time zone.

=item B<epoch>

(cached, derived, psuedo) Like B<timestamptz>, but the time is
expressed as a unix epoch time without a timezone.

in construction it will also use the local time rules:

    perl -MXML::SRS::TimeStamp -MYAML -E 'say XML::SRS::TimeStamp->new(
            epoch => time(),
       )->dump;'
    $VAR1 = bless( {
                     'hour' => '21',
                     'epoch' => 1283200164,
                     'month' => '08',
                     'second' => '24',
                     'tz_offset' => '+0100',
                     'minute' => '29',
                     'day' => '30',
                     'year' => '2010'
                   }, 'XML::SRS::TimeStamp' );

(Above is a summer time time)

   perl -MXML::SRS::TimeStamp -MYAML -E 'say XML::SRS::TimeStamp->new(
           epoch => time()+6*30*86400,
      )->dump;'
   $VAR1 = bless( {
                    'hour' => '20',
                    'epoch' => 1298752226,
                    'month' => '02',
                    'second' => '26',
                    'tz_offset' => '+0000',
                    'minute' => '30',
                    'day' => '26',
                    'year' => '2011'
                  }, 'XML::SRS::TimeStamp' );

(and for comparison, a non-daylight savings time)

=back

=head1 XML::SRS::Time and XML::SRS::Date

These roles contain the component parts of Date and Time, to keep them
independent.  C<XML::SRS::TimeStamp::Role> composes both of these.
They are not used by any other classes.

=head1 SEE ALSO

L<XML::SRS>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut
