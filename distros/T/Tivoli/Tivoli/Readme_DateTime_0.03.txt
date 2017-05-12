NAME
            Tivoli::DateTime - Perl Extension for Tivoli

SYNOPSIS
            use Tivoli::DateTime;

VERSION
            v0.03

LICENSE
            Copyright (c) 2001 Robert Hase.
            All rights reserved.
            This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

DESCRIPTION
                This Package will handle about everything you may need for displaying the date / time.
                If anything has been left out, please contact me at
                kmeltz@cris.com , tivoli.rhase@muc-net.de
                so it can be added.

  DETAILS

            d = dot, s = slash, m = minus

  ROUTINES

            Description of Routines

   YYYYMMDD

    * DESCRIPTION
                Returns YYYYMMDD

    * CALL
                $Var = &YYYYMMDD;

    * SAMPLE
                $Var = &YYYYMMDD;
                $Var = 20010804

   YYYYMMDDHHMMSS

    * DESCRIPTION
                Returns YYYYMMDDHHMMSS

    * CALL
                $Var = &YYYYMMDDHHMMSS;

    * SAMPLE
                $Var = &YYYYMMDDHHMMSS;
                $Var = 20010804134527

   HHdMMdSS

    * DESCRIPTION
                Returns HHdMMdSS

    * CALL
                $Var = &HHdMMdSS;

    * SAMPLE
                $Var = &HHdMMdSS;
                $Var = 13.45.27

   YYYYmMMmDD

    * DESCRIPTION
                Returns YYYYmMMmDD

    * CALL
                $Var = &YYYYmMMmDD;

    * SAMPLE
                $Var = &YYYYmMMmDD;
                $Var = 2001-08-04

   DDdMMdYYYY

    * DESCRIPTION
                Returns DDdMMdYYYY

    * CALL
                $Var = &DDdMMdYYYY;

    * SAMPLE
                $Var = &DDdMMdYYYY;
                $Var = 04.08.2001

   DDmMMmYYYY

    * DESCRIPTION
                Returns DDmMMmYYYY

    * CALL
                $Var = &DDmMMmYYYY;

    * SAMPLE
                $Var = &DDmMMmYYYY;
                $Var = 04-08-2001

   EpocheSS

    * DESCRIPTION
                Returns EpocheSS since 1970-01-01 00:00.00

    * CALL
                $Var = &EpocheSS;

    * SAMPLE
                $Var = &EpocheSS;
                $Var = 78762323109843

   EpocheSS2DdMdYYYY

    * DESCRIPTION
                Converts the given Epoche-Seconds to DdMdYYYY

    * CALL
                $Var = &EpocheSS2DdMdYYYY(78762323109843);

    * SAMPLE
                $Var = &EpocheSS2DdMdYYYY(78762323109843);
                $Var = 04.08.2001

   EpocheSS2DdMdYYYYsHdMdS

    * DESCRIPTION
                Converts the given Epoche-Seconds to DdMdYYYYsHdMdS

    * CALL
                $Var = &EpocheSS2DdMdYYYYsHdMdS(78762323109843);

    * SAMPLE
                $Var = &EpocheSS2DdMdYYYYsHdMdS(78762323109843);
                $Var = 04.08.2001/13.45.27

   date_split_dot

    * DESCRIPTION
                Splits the given Dot-Date 04.08.2001 to 04 08 2001

    * CALL
                $Var = &date_split_dot("04.08.2001");

    * SAMPLE
                @Arr = &date_split_dot("04.08.2001");
                @Arr = qw(04 08 2001);

   date_split_minus

    * DESCRIPTION
                Splits the given Date 04-08-2001 to 04 08 2001

    * CALL
                $Var = &date_split_minus("04-08-2001");

    * SAMPLE
                @Arr = &date_split_minus("04-08-2001");
                @Arr = qw(04 08 2001);

   slash_date

    * DESCRIPTION
                Returns MM/DD/YYYY

    * CALL
                $Var = &slash_date;

    * SAMPLE
                $Var = &slash_date;
                $Var = 04/08/2001;

   longDateTime

    * DESCRIPTION
                Returns long DateTime

    * CALL
                $Var = &longDateTime;

    * SAMPLE
                $Var = &longDateTime;
                $Var = Saturday, 08 04, 2001 at 13:45:27

   longDate

    * DESCRIPTION
                Returns long Date

    * CALL
                $Var = &longDate;

    * SAMPLE
                $Var = &longDate;
                $Var = Saturday, 08 04, 2001

   abr_mon

    * DESCRIPTION
                Returns abbreviation of Month

    * CALL
                $Var = &abr_mon;

    * SAMPLE
                $Var = &abr_mon;
                $Var = Aug

   abr_day

    * DESCRIPTION
                Returns abbreviation of Day

    * CALL
                $Var = &abr_day;

    * SAMPLE
                $Var = &abr_day;
                $Var = Sat

   month

    * DESCRIPTION
                Returns Nr of Month

    * CALL
                $Var = &month;

    * SAMPLE
                $Var = &month;
                $Var = 08

   day

    * DESCRIPTION
                Returns Nr of Day

    * CALL
                $Var = &day;

    * SAMPLE
                $Var = &day;
                $Var = 6

   month_num

    * DESCRIPTION
                Returns Nr of Month

    * CALL
                $Var = &month_num;

    * SAMPLE
                $Var = &month_num;
                $Var = 8

   day_num

    * DESCRIPTION
                Returns Nr of Day

    * CALL
                $Var = &day_num;

    * SAMPLE
                $Var = &day_num;
                $Var = 6

   year

    * DESCRIPTION
                Returns Year

    * CALL
                $Var = &year;

    * SAMPLE
                $Var = &year;
                $Var = 2001

   days_left

    * DESCRIPTION
                Returns days left in year

    * CALL
                $Var = &days_left;

    * SAMPLE
                $Var = &days_left;
                $Var = 236

  Plattforms and Requirements

                Supported Plattforms and Requirements

    * Plattforms
                tested on:

                - w32-ix86 (Win9x, NT4, Windows 2000)
                - aix4-r1 (AIX 4.3)
                - Linux (Kernel 2.2.x)

    * Requirements
            requires Perl v5 or higher

  HISTORY

            VERSION         DATE            AUTHOR          WORK
            ----------------------------------------------------
            0.01            1999            kmeltz          created
            0.02            2000-08         RHase           several Date / Time Formats
            0.03            2001-08-04      RHase           POD-Doku added

AUTHOR
            kmeltz, Robert Hase
            ID      : KMELTZ, RHASE
            eMail   : kmeltz@cris.com, Tivoli.RHase@Muc-Net.de
            Web     : http://www.Muc-Net.de

SEE ALSO
            CPAN
            http://www.perl.com

