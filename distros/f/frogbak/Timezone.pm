
#
# tz2zone() parses the TZ environment variable and returns a timezone
# string suitable for inclusion in date(1) output
#
# tz_local_offset() determins the offset from GMT time in seconds.  It
# only does the calculation once.
#

# 
# TODO: create an interface to the tzset(3) routine.
#

# 
# David Muir Sharnoff <muir@idiom.com>
#

require 5.000;

package Timezone;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(tz2zone tz_local_offset);
@EXPORT_OK = qw();

# This stolen from code by Paul Foley <paul@ascent.com>
sub tz2zone
{
	my($TZ) = @_;
	$TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : ''
	    unless $TZ;
      
	# Hack to deal with 'PST8PDT' format of TZ
	# Note that this can't deal with all the esoteric forms, but it
	# does recognize the most common: [:]STDoff[DST[off][,rule]]
      
	if ($TZ =~ /^
		    ( [^:\d+\-,] {3,} )
		    ( [+-] ?
		      \d {1,2}
		      ( : \d {1,2} ) {0,2} 
		    )
		    ( [^\d+\-,] {3,} )?
		    /x
	    ) {
	    $TZ = $isdst ? $4 : $1;
	}
	return $TZ;
}

# ideas for this stolen from a posting 
# by Ove Ruben R Olsen <buboo@alf.uib.no>
sub tz_local_offset
{
	return $Timezone::tz_local_offset
		if $Timezone::tz_known;
	my @l = localtime(86400);
	my @g = gmtime(86400);

	$Timezone::tz_local_offset = 
		  $l[0] - $g[0] 
		+ ($l[1] - $g[1]) * 60
		+ ($l[2] - $g[2]) * 3600
		+ ($l[7] - $g[7]) * 86400;
	$Timezone::tz_known = 1;
	return $Timezone::tz_local_offset;
}

1;
