#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::Utils;
    our $VERSION = '4.5';
    use base qw/Exporter/;
	use Time::localtime;

    our @EXPORT = qw/&date2sql &sql2date &isDate &isNumber &P2array &P2hash/;

############################################################################
# Convert dd.mm.yyyy to yyyy-mm-dd hh:mm:ss
sub date2sql($)	{	#06/09/00 12:34
############################################################################
	my $date = shift;
	$date =~ s/^(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1 00:00:00/;
	return $date
}##date2sql

############################################################################
# Convert yyyy-mm-dd hh:mm:ss to dd.mm.yyyy
sub sql2date($)	{	#06/09/00 12:35
############################################################################
	my $date = shift;
	$date =~ s/^(\d\d\d\d)-(\d\d)-(\d\d)(.*)$/$3.$2.$1/;
	return $date
}##sql2date

############################################################################
sub isDate($)  {   #25.01.99 16:54
############################################################################
    my $date = shift;
    #             J  F  M  A  M  Y  Y  A  S  O  N  D
    my @dates = (31,28,31,30,31,30,31,31,30,31,30,31);

	if ($date eq 'now') {
    	return sprintf('%02d.%02d.%04d', localtime->mday(), 1+localtime->mon(), 1900+localtime->year());
	}

    # ÿÌŞÂŞÊŞ ÄÅÊŞÅË ÃŞËÅÌØ ÄÊÚ ÎÏÕÁÅÄÅÌÕÚ É ÉŞÌÍÌÕÂÅßÉÍËÑ ÁÕÄÑ
    $date =~ tr|,-/|...|;
    my($xday, $xmonth, $xyear) = split '\.', $date;

    # íÀÏŞÀÍĞÉŞ ÖÍÄŞ
    $xyear = localtime->year()+1900 if ($xyear eq '');
    $xyear += 1900 if ($xyear>37 and $xyear<=99);
    $xyear += 2000 if ($xyear<=37);

    # íÀÏŞÀÍĞÉŞ ËÅßÚÆŞ
    return undef if ($xmonth <= 0 or $xmonth > 12 );

    # íÀÏŞÀÍĞÉŞ ÄÌÚ ËÅßÚÆŞ
    return undef if ($xday <= 0);
    if (($xmonth == 2) and ($xyear % 4 == 0)) {
        return undef if($xday > 29);
    } else {
		return undef if($xday > $dates[$xmonth-1]);
    }

    return sprintf('%02d.%02d.%04d', $xday, $xmonth, $xyear);
}##isDate

############################################################################
sub isNumber($)    {   #25.01.99 16:55
############################################################################
    my $number = shift;

    $number =~ tr/,/./;
    $number =~ tr/ [^01234567890\.-]//d;

    return $number*1;
}##isNumber

1;

