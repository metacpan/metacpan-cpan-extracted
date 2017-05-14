############################################################################
# Copyright (c) 1998 Enno Derksen
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. 
############################################################################

package XML::XQL::Date;

use vars qw(@ISA);
@ISA = qw( XML::XQL::PrimitiveType );

use strict;
use Carp;

BEGIN
{
    # Date::Manip relies on setting of $TZ. 
    unless (defined $ENV{TZ})
    {
	$ENV{TZ} = "EST5EDT";
	warn "XML::XQL::Date - setting timezone \$ENV{TZ} to EST5EDT (east coast USA.) Set your TZ environment variable to avoid this message.";
    }
}
use Date::Manip;

BEGIN {
    # add date() implementation to XQL engine.
    XML::XQL::defineFunction ("date", \&XML::XQL::Date::date, 1, 1, 1);
};

use overload 
    'fallback' => 1,		# use default operators, if not specified
    '<=>' => \&compare,		# also takes care of <, <=, ==, != etc.
    'cmp' => \&compare,		# also takes care of le, lt, eq, ne, etc.
    '""'  => \&yyyymmddhhmmss;	# conversion to string uses yyyymmddhhmmss

sub new
{
    my $class = shift;

    my (%args);
    if (@_ < 2)
    {
	my $str = @_ ? $_[0] : "";
	%args = (String => $str);
    }
    else
    {
	%args = @_;
    }

    my $self = bless \%args, $class;

    if (@_ < 2)
    {
	my $date = $self->createInternal (@_ ? $_[0] : "now");
	$date = "" unless isValidDate ($date);
	$self->{Internal} = $date;
    }
    $self;
}

sub createInternal
{
    my ($self, $str) = @_;
    Date::Manip::ParseDate ($str);

# From Date::Manip:
#
# 2 digit years fall into the 100 year period given by [ CURR-N,
# CURR+(99-N) ] where N is 0-99.  Default behavior is 89, but other useful
# numbers might be 0 (forced to be this year or later) and 99 (forced to be
# this year or earlier).  It can also be set to "c" (current century) or
# "cNN" (i.e.  c18 forces the year to bet 1800-1899).  Also accepts the
# form cNNNN to give the 100 year period NNNN to NNNN+99.
#$Date::Manip::YYtoYYYY=89;

# Use this to force the current date to be set to this:
#$Date::Manip::ForceDate="";
}

sub isValidDate		# static method
{
    my ($date) = @_;
    return 0 unless defined $date;

    my $year = substr ($date, 0, 4) || 0;

    $year > 1500;
#?? arbitrary limit - years < 100 cause problems in Date::Manip
}

sub ymdhms
{
    my $self = shift;
    if (@_)
    {
	my ($y, $mon, $d, $h, $m, $s) = @;
#?? implement
    }
    else
    {
#?? test: x skips a character. Format: "YYYYMMDDhh:mm::ss"
	return () unless length $self->{Internal};
#	print "ymhds " . $self->{Internal} . "\n";
	unpack ("A4A2A2A2xA2xA2", $self->{Internal});
    }
}

sub yyyymmddhhmmss
{
    my ($self) = @_;
    my ($y, $mon, $d, $h, $m, $s) = $self->ymdhms;
    
    $y ? "$y-$mon-${d}T$h:$m:$s" : "";
    # using Date::Manip::UnixDate is a bit too slow for my liking
#?? could add support for other formats
}

sub xql_toString
{
#?? use $_[0]->{String} or 
    $_[0]->yyyymmddhhmmss;
}

sub xql_compare
{
    my ($self, $other) = @_;
    my $type = ref ($self);
    if (ref ($other) ne $type)
    {
	my $str = $other->xql_toString;
	# Allow users to plug in their own Date class
	$other = eval "new $type (\$str)";
#?? check result?
    }
#print "date::compare self=" . $self->{Internal} . " other=" . $other->{Internal}. "\n";
    $self->{Internal} cmp $other->{Internal};
}

sub xql_setSourceNode
{
    $_[0]->{SourceNode} = $_[1];
}

sub xql_sourceNode
{
    $_[0]->{SourceNode};
}

sub xql_setValue
{
    my ($self, $val) = @_;
    $self->{Internal} = $self->createInternal ($val);
    $self->{String} = $val;
}

# The XQL date() function
sub date	# static method
{
    my ($context, $listref, $text) = @_;

    $text = XML::XQL::toList ($text->solve ($context, $listref));
    my @result = ();
    for my $val (@$text)
    {
	# Using xql_new allows users to plug-in their own Date class
	my $date = XML::XQL::xql_new ("date", $val->xql_toString);
#	print "date $val " . XML::XQL::d($val) . " " . $date->xql_toString . "\n";
	push @result, $date;
    }
    \@result;
}

1; # module return code

__END__

=head1 NAME

XML::XQL::Date - Adds an XQL::Node type for representing and comparing dates and times

=head1 SYNOPSIS

 use XML::XQL;
 use XML::XQL::Date;

 my $query = new XML::XQL::Query (Expr => "doc//timestamp[. < date('12/31/1999')]");
 my @results = $query->solve ($doc);

=head1 DESCRIPTION

This package uses the L<Date::Manip> package to add an XQL node type 
(called XML::XQL::Date) that can be used to represent dates and times. 
The Date::Manip package can parse almost any date or time format imaginable.
(I tested it with Date::Manip 5.33 and I know for sure that it doesn't work 
with 5.20 or lower.)

It also adds the XQL B<date> function which creates an XML::XQL::Date 
object from a string. See L<XML::XQL::Tutorial> for a description of the date()
function.

You can plug in your own Date type, if you don't want to use Date::Manip 
 for some reason. See L<XML::XQL> and the XML::XQL::Date source file for
more details.
