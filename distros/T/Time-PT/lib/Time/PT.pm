# 2CN4sip - Time::PT.pm (PipTime) created by Pip@CPAN.Org to define 
#   simple objects for storing instants in time.
# Desc: PT describes a simple object which encapsulates 10 fields:
#     Century, Year, Month, Day, hour, minute, second, frame, jink, zone
#   where frame is normally 1/60th-of-a-second && jink is normally 
#   1/60th-of-a-frame.  The objects describe a high-precision time-
#   instant with fields in decending order of precision such that 
#   alphabetic listings will (typically) show time ascension && field 
#   arithmetic can be easily performed.  PT objects can
#   be added to / subtracted from Time::Frame objects to yield 
#   new specific PT instants.
#     The common use of PT is for a simple `pt` utility to 
#   en/decode dates && times using seven (7) Base64 characters.
#     1st: '0A1B2C3'
#     2nd: 'Yd:2003,j:A7_,M:a3I' or 'f:3aL9.eP' 
#     if field name ends with d, value is read as decimal nstd of default b64.
#     Third way is super verbose decimal strings:
#       '15 years, 3 months, 7 weeks, 4 jinx' can use any (or none) sep but :
#     4th is hash
#     Total Jinx possible for PT: 1,680,238,080,000,000 (1.7 quatrillion)
#           JnxPTEpoch -> `pt __nWO0000` -> Midnight Jan. 1 7039 BCE
#              PTEpoch -> `pt  _nWO`     -> Midnight Jan. 1 1361  CE
#   PT members:
#     new inits either with pt-param, expanded, or empty
#
#       epoch_(seconds|frames|jinx)() methods (optional frames/jinx as floats)
#     ptepoch_(seconds|frames|jinx)() methods 
#       (since ptEpoch (`pt _nWO` Midnight, Jan1,1361))
#     settle fields with options (like return new Frame object with only 
#       total secs of old)
#     re-def frame as other than 60th-of-a-second
#     re-def jink  as other than 60th-of-a-frame
#       eg. def f && j limits as 31.6227766016838 (sqrt(1000)) for ms jinx
#           or just def f as 1000 for exactly ms frames
#     allow month/year modes to be set to avg or relative
#
#  My Base64 encoding uses characters: 0-9 A-Z a-z . _  since I don't like
#    having spaces or plusses in my time strings.  I need times to be easy to
#    append to filenames for very precise, consice, time-stamp versioning.
#  Each encoded character represents (normally) just a single date or time 
#    field.  All fields are 0-based except Month && Day.  The fields are:
#      Year-2000, Month, Day, Hour, Minute, Second, Frame (60th-of-a-second)
#  There are three (3) exceptions to the rule that each character only
#    represents one date or time field.  The bits are there so... why not? =)
#  0) Each 12 added to the Month adds  64 to the Year.
#  1)      24 added to the Hour  adds 320 to the Year.
#  2)      31 added to the Day   makes the year negative just before adding 
#            2000.
#  So with all this, any valid pt (of 7 b64 characters) represents a unique 
#    instant (precise down to a Frame [60th-of-a-second]) that occurred or 
#    will occur between the years 1361 && 2639 (eg. New Year's Day of each 
#    of those years would be '_nWO' && '_n1O').  These rules break down as:
# Hour   Day  Month     Year    YearWith2000
# 24-47 32-62 49-60  -639- -576  1361-1424
#             37-48  -575- -512  1425-1488
#             25-36  -511- -448  1489-1552
#             13-24  -447- -384  1553-1616
#              1-12  -383- -320  1617-1680
#  0-23 32-62 49-60  -319- -256  1681-1744
#             37-48  -255- -192  1745-1808
#             25-36  -191- -128  1809-1872
#             13-24  -127-  -64  1873-1936
#              1-12   -63-   -0  1937-2000
#  0-23  1-31  1-12     0-   63  2000-2063
#             13-24    64-  127  2064-2127
#             25-36   128-  191  2128-2191
#             37-48   192-  255  2192-2255
#             49-60   256-  319  2256-2319
# 24-47  1-31  1-12   320-  383  2320-2383
#             13-24   384-  447  2384-2447
#             25-36   448-  511  2448-2511
#             37-48   512-  575  2512-2575
#             49-60   576-  639  2576-2639
# Notz:
#  PT + Frame can become the core of a new input language which accounts
#    for time.  It could be game sequences like a fireball that can be rolled
#    from d->df && df->f only at a certain speed ... but then also later
#    maybe time-sensitive computer input like typematic key repeat rate but
#    configurable... smarter?  The combinatorics on the X-Box Live pswd is
#    8**4 == 4096 (butn: u,d,l,r,x,y,L,R) so even exhausting the search space
#    (assuming you're too wise for a smpl likely 4-char sequence) could be
#    finished manually in about 9 hours if you complete a test cycle each
#    8 seconds.  Automated would need programmable circuit... plug that
#    thang into USB && make an easy sequencer PT+Frame- based IF to perform!
#    So cool!
#  Could create an easy IF to setup any sort of practice scenario,
#    programmable pad behavior, or even store replays as device inputs &&
#    feed them back in... woohoo that's fscking cool!  GameOver specialty =)
#    umm it would basically need the same IF as a fighting game tool hehe =).
#  Don't need Math::BigInt to store pt epoch seconds (pte's) because perl's 
#    floats already have enough precision to store them.  Use the fractional 
#    part of those values to store 60ths && don't use builtin timelocal 
#    functions which only accept 1970-2036 (or whatever limited) epoch 
#    seconds (only 32-bit ints or something =( ).
#  Interaction with other Time modules: 
#    Time::Period  - just have an Epoch export option && Period can use it
#    Time::Avail   - doesn't seem useful to my purposes
#    Time::Piece   - might be nice to mimic this module's object interface
#    Time::Seconds - handy for dealing with lots of seconds but about 60ths?
#  old 5-char pt examples: (update these when there's time)
# Xmpl: `pt 01`        == localtime(975657600) # seconds since Epoch
#     `pt 1L7Mu`       == unpack time (Sun Jan 21 07:22:56 2001)
#     `pt _VNxx`       == localtime(1143878399)
#     `pt pt`          == unpack current pt (akin to `pt `pt``)
#     `pt e`           == localtime  (eg. Thu Jan 21 07:22:56 2001)
#     `pt e e`         == current epoch seconds
#     `pt 1L7Mu e`     == convert from pt to epoch (980090576)
#     `pt 975657600 E` == convert from Epoch seconds to pt (01)
#     `pt Jan 21, 2001 07:22:56`    -> 1L7Mu
#     `pt Sun Jan 21 07:22:56 2001` -> 1L7Mu
#     `pt 1L7Mu cmp FEET0`          -> lt 
#     `pt FEET0 cmp 1L7Mu`          -> gt 
#     `pt 2B cmp 2B`                -> eq
#       timelocal($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)

=head1 NAME

Time::PT - objects to store an instant in time

=head1 VERSION

This documentation refers to version 1.2.565EHOV of 
Time::PT, which was released on Sun Jun  5 14:17:24:31 2005.

=head1 SYNOPSIS

  use Time::PT;
  
  my $f = Time::PT->new();
  
  print "PipTime is: $f\n";
  print 'The Day-of-Week today is: ', $f->dow(), "\n";

=head1 DESCRIPTION

By default, Time::PT stores time descriptions precise to 60ths-
of-a-second (0.016667 seconds).  The groundwork has been laid
for sub-millisecond precision to be included later.

This module has been adapted from the L<Time::Piece> module 
written by Matt Sergeant <matt@sergeant.org> && Jarkko 
Hietaniemi <jhi@iki.fi>.  Time::PT inherits base 
data structure && object methods from L<Time::Fields>.  
PT was written to simplify storage && calculation 
of encoded, yet distinct && human-readable, time data 
objects.

This module (Time::PT) does not replace the standard localtime &&
gmtime functions like L<Time::Piece> but Time::PT objects behave
almost identically to L<Time::Piece> objects otherwise (since it
was adapted from... I said that already =) ).

=head1 2DO

=over 2

=item - mk interoperable w/ Time::Seconds objects

=item - add Time::Zone stuff to use && match zone field reasonably

=item - replace legacy pt() with tested new() wrapper && fix all apps to
          use objs instead of local pt()

=item - flesh out constructor init data parsing && formats supported

=item - consider epoch functions like _epoch([which epoch]) or individuals
          like _jinx_epoch()

=item - mk PT->new able to create from different 'epoch' init types

=item - fix weird 0 month && 0 day problems

=item -     What else does PT need?

=back

=head1 WHY?

The reason I created PT was that I have grown so enamored with
Base64 representations of everything around me that I was 
compelled to write a simple clock utility ( `pt` ) using Base64.
This demonstrated the benefit to be gained from time objects with
distinct fields && configurable precision.  Thus, L<Time::Fields>
was written to be the abstract base class for:

  Time::Frame  ( creates objects which represent spans    of time )
      && 
  Time::PT     ( creates objects which represent instants in time )

=head2 HOW?

I've made up some silly sentences as mnemonic devices to help me 
remember every 4th uppercase Base64 character:

  Can      12   Noon       MonthOfYear will be less or equal to 'C'.
  Goats    16   4 PM
  Keep     20   8 PM
  Oats     24   Midnight   HourOfDay   will be less than        'O'.
  Some     28  
  Where?   32              DayOfMonth  will be less than        'W'.

  Cool    COW (Month Hour Day thresholds)
  Guys    Girls
  Keep    Keep
  On      On                   Off
  Sayin'  Sayin'      Sippin'  Sea
  Wassup  WeeDoggies  Water    Water

=head1 USAGE

Many of Time::PT's methods have been patterned after the excellent
L<Time::Piece> module written by Matt Sergeant <matt@sergeant.org>
&& Jarkko Hietaniemi <jhi@iki.fi>.

=head2 new(<InitType>, <InitData>)

Time::PT's constructor can be called
as a class method to create a brand new object or as an object 
method to copy an existing object.  Beyond that, new() can 
initialize PT objects 3 different ways:

  * <packedB64InitStringImplies'str'>
    eg. Time::PT->new('3C79jo0');
  * 'str'  => <packedB64InitString>
    eg. Time::PT->new('str'  => '0A1B2C3D4E');
  * 'list' => <arrayRef>
    eg. Time::PT->new('list' => [0, 1, 2..9]);
  * 'hash' => <hashRef>
    eg. Time::PT->new('hash' => {'jink' => 8, 'year' => 2003})

=head2 color(<DestinationColorTypeFormat>)

This is an object member
which will join Base64 representations of each field that has
been specified in use() && joins them with color-codes or color
escape sequences with formats for varied uses.  Currently
available DestinationColorTypeFormats are:

  'ANSI'  # eg. \e[1;32m
  'zsh'   # eg. %{\e[1;33m%}
  'HTML'  # eg. <a href="http://Ax9.Org/pt?"><font color="#FF1B2B">
  '4NT'   # eg. color 09 & 
  'Simp'  # eg. RbobYbGbCbUbPb

=head2 pt

This function is the legacy procedural version of my command-line
PipTime utility.  It will be removed in the near future when the
object methods fully replace all the old behavior && have been 
tested sufficiently.

This function && the following ptcc() are the only functions
exported when Time::PT is used.

=head2 ptcc(<DestinationColorTypeFormat>)

Returns the Simp color code string appropriate for pt (PipTime) data.

  Format   Returned color code string
   'k'     the background will change along with the foreground for standard
             time-of day elements (ie. hms on a dark blue background)
   'f'     color codes for the expanded pt format 
             (eg. color codes corresponding to Sun Jan  4 12:41:48:13 2004)

This function && the previous legacy pt() are the only functions
exported when Time::PT is used.

The following methods allow access to individual fields of 
Time::PT objects:

  $t->C  or  $t->century
  $t->Y  or  $t->year
  $t->M  or  $t->month
  $t->D  or  $t->day
  $t->h  or  $t->hour
  $t->m  or  $t->minute
  $t->s  or  $t->second
  $t->f  or  $t->frame
  $t->j  or  $t->jink
  $t->z  or  $t->zone

Please see L<Time::Fields> for further description of field 
accessor methods.

After importing this module, when you use localtime or gmtime in a
scalar context, you DO NOT get a special Time::PT object like you
would when using L<Time::Piece>.  This module relies on a new() 
constructor instead.  The following methods are available on 
Time::PT objects though && remain as similar to L<Time::Piece>
functionality as makes sense.

  $t->frm                 # also as $t->frame && $t->subsecond
  $t->sec                 # also available as $t->second
  $t->min                 # also available as $t->minute
  $t->hour                # 24 hour
  $t->mday                # also available as $t->day_of_month
  $t->mon                 # 1 = January
  $t->_mon                # 0 = January
  $t->monname             # Feb
  $t->month               # same as $t->mon
                 # *NOTE* The above definition ( of $t->month() ) is 
                 # different from the Time::Piece interface which defines
                 # month() the same as monname() instead of mon().
  $t->fullmonth           # February
  $t->year                # based at 0 (year 0 AD is, of course 1 BC)
  $t->_year               # year minus 1900
  $t->yy                  # 2 digit year
  $t->wday                # 1 = Sunday
  $t->_wday               # 0 = Sunday
  $t->day_of_week         # 0 = Sunday
  $t->wdayname            # Tue
  $t->day                 # same as mday
                 # *NOTE* Similar to month(), I've defined day() 
                 # differently from Time::Piece which makes it the same
                 # as wdayname() instead of mday().
  $t->fullday             # Tuesday
  $t->yday                # also available as $t->day_of_year, 0 = Jan 01
  $t->isdst               # also available as $t->daylight_savings

The following functions return a list of the named fields.  The
return value can be joined with any desirable delimiter like:

  join(':', $t->hms);
  join($t->time_separator, $t->hms);

but the functions also can take a list of parameters to update
the corresponding named fields like:

  $t->YMD( 2003, 12, 8 ) # assigns new date of December 8th, 2003 to $t

Following are some useful functions && comments of sample return values:

  $t->hms                 # [12, 34, 56]
  $t->hmsf                # [12, 34, 56, 12]
  $t->time                # same as $t->hmsf

  $t->ymd                 # [2000,  2, 29]
  $t->date                # same as $t->ymd
  $t->mdy                 # [ 2, 29, 2000]
  $t->dmy                 # [29,  2, 2000]
  $t->datetime            # 2000-02-29T12:34:56            (ISO 8601)
  $t->expand              # Tue Feb 29 12:34:56:12 2000
  $t->cdate               # same as $t->expand
  $t->compress            # 02TCYuC
  "$t"                    # same as $t->compress

  $t->is_leap_year        # true if it is
  $t->month_last_day      # 28-31

  $t->time_separator($s)  # set the default separator (default ":")
  $t->date_separator($s)  # set the default separator (default "-")
  $t->day_list(@days)     # set the default weekdays
  $t->mon_list(@days)     # set the default months

=head2 Local Locales

Both wdayname() && monname() can accept the same list parameter 
as day_list() && mon_list() respectively for temporary help with
simple localization.

  my @days = ( 'Yom Rishone', 'Yom Shayni', 'Yom Shlishi', 'Yom Revi\'i', 
               'Yom Khahmishi', 'Yom Hashishi', 'Shabbat' );

  my $hebrew_day = pt->wdayname(@days);
                 # pt->monname() can be used similarly

To update the global lists, use:

  Time::PT::day_list(@days);
    &&
  Time::PT::mon_list(@months);

=head2 Calculations

PT object strings (both in normal initialization && printing) grow
left-to-right starting from the Year to specify whatever precision
you need while Frame objects grow right-to-left from the frame field.

It's possible to use simple addition and subtraction of objects:

  use Time::Frame;
  
  my $cur_pt       = Time::PT->new();# Dhmsf
  my $one_week     = Time::Frame->new('70000');
  my $one_week_ago = $cur_pt - $one_week;

If a calculation is done with a raw string parameter instead of an
instantiated object, the most likely appropriate object 
constructor is called on it.  These init strings must adhere to
the implied 'str' format for auto-creating objects;  I aim to
support a much wider array of operations && to make this module
smoothly interoperate with both L<Time::Piece> && L<Time::Seconds>
someday but not yet.

  my $cur_pt             = Time::PT->new();
  my $half_hour_from_now = $cur_pt + 'U00';

The following are valid (where $t0 and $t1 are Time::PT objects
&& $f is a Time::Frame object):

  $t0 - $t1;  # returns Time::Frame object
  $t0 - '63'; # returns Time::PT object
  $t0 + $f;   # returns Time::PT object

=head2 Comparisons

All normal numerical && string comparisons should work reasonably on
Time::PT objects: 

  "<",  ">",  "<=", ">=", "<=>", "==" &&  "!="
  "lt", "gt", "le", "ge", "cmp", "eq" and "ne"

=head2 YYYY-MM-DDThh:mm:ss

The ISO 8601 standard defines the date format to be YYYY-MM-DD, and
the time format to be hh:mm:ss (24 hour clock), and if combined,
they should be concatenated with date first and with a capital 'T'
in front of the time.

=head2 Week Number

The ISO 8601 standard specifies that weeks begin on Monday and the first
week of the year is the one that includes both January 4th and the
first Thursday of the year.  In other words, if the first Monday of
January is the 2nd, 3rd, or 4th, the preceding days are part of the 
final week of the prior year.  Week numbers range from 1 to 53.

=head1 NOTES

Whenever individual Time::PT attributes are going to be 
printed or an entire object can be printed with multi-colors,
the following mapping should be employed whenever possible:

           D      Century -> DarkRed
           A      Year    -> Red
           T      Month   -> Orange
           E      Day     -> Yellow
                   hour   -> Green
            t      minute -> Cyan
            i      second -> Blue
            m      frame  -> Purple
            e      jink   -> DarkPurple
                   zone   -> Grey or White

Please see the color() member function in the USAGE section.

There's some weird behavior for PipTimes created with a zero month
or day field since both are 1-based.  I aim to fix all these bugs
but be warned that this issue may be causing math errors for a bit.

I hope you find Time::PT useful.  Please feel free to e-mail
me any suggestions || coding tips || notes of appreciation 
("app-ree-see-ay-shun").  Thank you.  TTFN.

=head1 CHANGES

Revision history for Perl extension Time::PT:

=over 4

=item - 1.2.565EHOV  Sun Jun  5 14:17:24:31 2005

* updated test.pl to work properly with Build.PL as well as Makefile.PL

* updated License, minor version, && precision description

=item - 1.0.42M3ChX  Sun Feb 22 03:12:43:33 2004

* added 4NT option to color codes in Fields && color() members in Frame && PT

* updated POD links && CHANGES chronology

=item - 1.0.41M4cZH  Thu Jan 22 04:38:35:17 2004

* moved pt, fpt, && lspt into bin/ for packaging as EXE_FILES

* added Time::Frame::total_frames method

=item - 1.0.418BGcv  Thu Jan  8 11:16:38:57 2004

* moved Curses::Simp::ptCC into Time::PT::ptcc for PipTime-specific Simp
    Color Codes

* created Time::Fields::_field_colors (centralized base class color codes)
    && updated Frame && PT _color_fields

* added HOW? POD section for mnemonics

=item - 1.0.3CVL3V4  Wed Dec 31 21:03:31:04 2003

* changed PREREQ to not have lib files from this pkg

=item - 1.0.3CQ8ibf  Fri Dec 26 08:44:37:41 2003

* fixed typo && hardcoded path in VERSION_FROM of gen'd Makefile.PL

=item - 1.0.3CNNQHc  Tue Dec 23 23:26:17:38 2003

* combined Fields, Frame, && PT into one pkg

=item - 1.0.3CCA2VC  Fri Dec 12 10:02:31:12 2003

* removed indenting from POD NAME section

=item - 1.0.3CBIQv7  Thu Dec 11 18:26:57:07 2003

* updated test.pl to use normal comments

=item - 1.0.3CB7Vxh  Thu Dec 11 07:31:59:43 2003

* added HTML color option && prepared for release

=item - 1.0.3CA8ipi  Wed Dec 10 08:44:51:44 2003

* built class to inherit from Time::Fields && mimic Time::Piece

=item - 1.0.37VG26k  Thu Jul 31 16:02:06:46 2003

* original version

=back

=head1 INSTALL

Please run:

    `perl -MCPAN -e "install Time::PT"`

or uncompress the package && run the standard:

    `perl Makefile.PL; make; make test; make install`

=head1 FILES

Time::PT requires:

L<Carp>                to allow errors to croak() from calling sub

L<Math::BaseCnv>       to handle simple number-base conversion

L<Time::DayOfWeek>       also stores global day && month names

L<Time::DaysInMonth>   

L<Time::Fields>        to provide underlying object structure

L<Time::Frame>         to represent spans of time

Time::PT uses (if available):

L<Time::HiRes>         to provide subsecond time precision

L<Time::Local>         to turn epoch seconds back into a real date

L<Time::Zone>           not utilized yet

=head1 SEE ALSO

L<Time::Frame>

=head1 LICENSE

Most source code should be Free!
  Code I have lawful authority over is && shall be!
Copyright: (c) 2002-2005, Pip Stuart.
Copyleft : This software is licensed under the GNU General Public
  License (version 2).  Please consult the Free Software Foundation
  (http://FSF.Org) for important information about your freedom.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut

package Time::PT;
use strict;
require      Time::Fields;
require                   Exporter;
use base qw( Time::Fields Exporter );
use vars qw( $AUTOLOAD );
use Carp;
use Math::BaseCnv qw( :all );
use Time::DayOfWeek;
use Time::DaysInMonth;
use Time::Frame;
my $hirs = eval("use   Time::HiRes; 1") || 0;
my $locl = eval("use   Time::Local; 1") || 0;
my $zown = eval("use   Time::Zone;  1") || 0;
#my $simp = eval("use Curses::Simp;  1") || 0;
our $VERSION     = '1.2.565EHOV'; # major . minor . PipTimeStamp
our $PTVR        = $VERSION; $PTVR =~ s/^\d+\.\d+\.//; # strip major && minor
# Please see `perldoc Time::PT` for an explanation of $PTVR.
our @EXPORT      = qw(pt ptcc);
use overload 
  q("")  => \&_stringify,
  q(<=>) => \&_cmp_num,
  q(cmp) => \&_cmp_str,
  q(+)   => \&_add,
  q(-)   => \&_sub;

sub _stringify { # cat non-zero b64 PT fields
  my @fdat = $_[0]->CYMDhmsfjz(); 
  my @attz = $_[0]->_attribute_names();
  my $tstr = ''; my $toob = 0; # flag designating field too big
  $fdat[1] -= 2000; # Year adjustment
  foreach(@fdat) {
    $toob = 1 if($_ > 63);
  }
# Reverse Year shifts back into fields
#   0) Each 12 added to the Month adds  64 to the Year.
#   1)      24 added to the Hour  adds 320 to the Year.
#   2)      31 added to the Day   makes the year negative just before adding 2k
  if(   $fdat[1] <    0) { $fdat[1] *=  -1; $fdat[3] += 31; }
  if(   $fdat[1] >= 320) { $fdat[1] -= 320; $fdat[4] += 24; }
  while($fdat[1] >=  64) { $fdat[1] -=  64; $fdat[2] += 12; }
  if($toob) {
    for(my $i=0; $i<@fdat; $i++) {
      $attz[$i] =~ s/^_(.).*/$1/;
      $attz[$i] = uc($attz[$i]) if($i < 4 || $i == $#fdat);
      $tstr .= $attz[$i] . ':' . $fdat[$i];
      $tstr .= ', ' if($i < $#fdat);
    }
  } else {
    for(my $i=0; $i<@fdat; $i++) {
      if($fdat[$i]) {
        $tstr .= b64($fdat[$i]);
        while($i < 7) { $tstr .= b64($fdat[++$i]); }
      }
    }
  }
  return($tstr);
}

sub _cmp_num {
  my ($larg, $rarg, $srvr) = @_;
  ($larg, $rarg) = ($rarg, Time::PT->new($larg)) if($srvr); # mk both args PT objects
  $rarg = Time::PT->new($rarg) unless(ref($rarg) && $rarg->isa('Time::PT'));
  if   (($larg->C < $rarg->C) || 
        ($larg->Y < $rarg->Y) || 
        ($larg->O < $rarg->O) || 
        ($larg->D < $rarg->D) || 
        ($larg->h < $rarg->h) || # add z?
        ($larg->i < $rarg->i) || 
        ($larg->s < $rarg->s) || 
        ($larg->f < $rarg->f) || 
        ($larg->j < $rarg->j)) { return(-1); }
  elsif(($larg->C > $rarg->C) || 
        ($larg->Y > $rarg->Y) || 
        ($larg->O > $rarg->O) || 
        ($larg->D > $rarg->D) || 
        ($larg->h > $rarg->h) || # add z?
        ($larg->i > $rarg->i) || 
        ($larg->s > $rarg->s) || 
        ($larg->f > $rarg->f) || 
        ($larg->j > $rarg->j)) { return(1); }
  else                         { return(0); }
}

sub _cmp_str { 
  my $c = _cmp_num(@_);
  ($c < 0) ? return('lt') : ($c) ? return('gt') : return('eq');
}

# PT + Frame = PT
# PT + anything else is not supported yet
sub _add {
  my ($larg, $rarg, $srvr) = @_;
  my $rslt = Time::PT->new('');
  if($srvr) {
    ($larg, $rarg) = ($rarg, Time::Frame->new($larg));
  }
  unless(ref($rarg) && $rarg->isa('Time::Frame')) {
    $rarg = Time::Frame->new($rarg);
  }
  $rslt->{'_zone'}    = $larg->z + $rarg->z;
  $rslt->{'_jink'}    = $larg->j + $rarg->j;
  $rslt->{'_frame'}   = $larg->f + $rarg->f;
  $rslt->{'_second'}  = $larg->s + $rarg->s;
  $rslt->{'_minute'}  = $larg->i + $rarg->i;
  $rslt->{'_hour'}    = $larg->h + $rarg->h;
  $rslt->{'_day'}     = $larg->D + $rarg->D;
  $rslt->{'_month'}   = $larg->O;
  $rslt->{'_year'}    = $larg->Y;
  $rslt->_sift();
  $rslt->{'_month'}   = $larg->O + $rarg->O;
  $rslt->{'_year'}    = $larg->Y + $rarg->Y;
  $rslt->{'_century'} = $larg->C + $rarg->C;
  $rslt->_sift(1);
  return($rslt);
}

# PT - Frame = PT
# PT - PT    = Frame
# PT - anything else is not supported yet
sub _sub {
  my ($larg, $rarg, $srvr) = @_; my $rslt;
  if($srvr) { 
    $larg = Time::PT->new($larg);
  }
  if(ref($rarg) && $rarg->isa('Time::PT')) {
    $rslt = Time::Frame->new();
  } else {
    $rarg = Time::Frame->new($rarg) unless(ref($rarg) && $rarg->isa('Time::Frame'));
    $rslt = Time::PT->new('');
  }
  $rslt->{'_zone'}    = $larg->z - $rarg->z;
  $rslt->{'_jink'}    = $larg->j - $rarg->j;
  $rslt->{'_frame'}   = $larg->f - $rarg->f;
  $rslt->{'_second'}  = $larg->s - $rarg->s;
  $rslt->{'_minute'}  = $larg->i - $rarg->i;
  $rslt->{'_hour'}    = $larg->h - $rarg->h;
  $rslt->{'_day'}     = $larg->D - $rarg->D;
  $rslt->{'_month'}   = $larg->O;
  $rslt->{'_year'}    = $larg->Y;
  $rslt->_sift()  if($rslt->isa('Time::PT'));
  $rslt->{'_month'}   = $larg->O - $rarg->O;
  $rslt->{'_year'}    = $larg->Y - $rarg->Y;
  $rslt->{'_century'} = $larg->C - $rarg->C;
  $rslt->_sift(1) if($rslt->isa('Time::PT'));
  return($rslt);
}

sub _sift { # settles fields into standard ranges (for overflow from add/sub)
  my $self = shift; my $mdon = shift; my $dinf = 0;
  unless($mdon) {
    if($self->{'_jink'} >= $self->{'__jpf'} || 0 > $self->{'_jink'}) {
      $self->{'_jink'}  -= $self->{'__jpf'} if(0 > $self->{'_jink'});
      $self->{'_frame'} += int($self->{'_jink'}  / $self->{'__jpf'});
      $self->{'_jink'}  %= $self->{'__jpf'};
    }
    if($self->{'_frame'} >= $self->{'__fps'} || 0 > $self->{'_frame'}) {
      $self->{'_frame'}  -= $self->{'__fps'} if(0 > $self->{'_frame'});
      $self->{'_second'} += int($self->{'_frame'} / $self->{'__fps'});
      $self->{'_frame'}  %= $self->{'__fps'};
    }
    if($self->{'_second'} >= 60 || 0 > $self->{'_second'}) {
      $self->{'_second'}  -= 60 if(0 > $self->{'_second'});
      $self->{'_minute'}  += int($self->{'_second'} / 60);
      $self->{'_second'}  %= 60;
    }
    if($self->{'_minute'} >= 60 || 0 > $self->{'_minute'}) {
      $self->{'_minute'}  -= 60 if(0 > $self->{'_minute'});
      $self->{'_hour'}    += int($self->{'_minute'} / 60);
      $self->{'_minute'}  %= 60;
    }
    if($self->{'_hour'} >= 24 || 0 > $self->{'_hour'}) {
      $self->{'_hour'}  -= 24 if(0 > $self->{'_hour'});
      $self->{'_day'}   += int($self->{'_hour'} / 24);
      $self->{'_hour'}  %= 24;
    }
    $dinf = 1 unless(defined($self->{'_month'}) && $self->{'_month'});
    $self->{'_month'} = 1 if($dinf);
    while($self->{'_day'} > days_in($self->Y, $self->M) || 0 >  $self->{'_day'}) { 
      if(0 >= $self->{'_day'}) {
        $self->{'_month'}--;
        while($self->{'_month'} < 1) {
          $self->{'_year'}--;
          $self->{'_month'} += 12;
        }
        $self->{'_day'}  += days_in($self->Y, $self->M);
      } else {
        $self->{'_day'}  -= days_in($self->Y, $self->M);
        $self->{'_month'}++;
        while($self->{'_month'} > 12) {
          $self->{'_year'}++;
          $self->{'_month'} -= 12;
        }
      }
    }
    $self->{'_month'}-- if($dinf);
  } else {
    if($self->{'_month'} >  12 || 0 >= $self->{'_month'}) { 
      $self->{'_month'}  -= 12 if(0 > $self->{'_month'});
      $self->{'_year'}   += int($self->{'_month'} / 12);
      $self->{'_month'}  %= 12;
    }
    # if __use_century && _year > 1000...
  }
}

# BEGIN legacy `pt` util code
my $numb; my $rslt; my $temp; 
#my @dayo = qw(Sun Mon Tue Wed Thu Fri Sat Sha);
#my @mnth = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @dayo = Time::DayOfWeek::DayNames();   
my @mnth = Time::DayOfWeek::MonthNames();
foreach(@dayo) { $_ = substr($_, 0, 3) if(length($_) > 3); }
foreach(@mnth) { $_ = substr($_, 0, 3) if(length($_) > 3); }
my %dmap = (); for(my $i=1; $i<=@dayo; $i++) { $dmap{lc($dayo[$i-1])} = $i; }
my %mmap = (); for(my $i=1; $i<=@mnth; $i++) { $mmap{lc($mnth[$i-1])} = $i; }

sub Pt2Epoch { # converts passed val either to epoch or pt depending
  $numb = shift || return(0); my $ptoe = ""; my $yeer = 0; my @prtz = ();
  if     (0 < length($numb) && length($numb) <=  7) {
    @prtz = split(//, $numb); splice(@prtz,7,($#prtz-7)); # chop extras off!
    for(my $i=0; $i<7; $i++) { unless(defined($prtz[$i])) { $prtz[$i] = 0; } }
    $prtz[1]-- if($prtz[1]);
    $prtz[2]  = 1 unless($prtz[2]);
    @prtz = (b10($prtz[5]), b10($prtz[4]), b10($prtz[3]),
      b10($prtz[2]), b10($prtz[1]), b10($prtz[0]));
#print "@prtz \n";
    $ptoe = timelocal(@prtz);
  } elsif(7 < length($numb) && length($numb) <= 12) {
    @prtz = localtime($numb);
    @prtz = (b64(int(($prtz[5]-101)*12)+$prtz[4]+1), b64($prtz[3]),
      b64($prtz[2]), b64($prtz[1]), b64($prtz[0]));
    for(my $i = 0; $i < 6; $i++) { $ptoe .= $prtz[$i] if defined($prtz[$i]); }
  }
  return($ptoe);
}

sub PtCmpPt { # compares two pt's, returns "lt", "eq", "gt", || "ne" if parmerr
# need year logic to handle exceptions to ordered field progression
  my $numa = shift || return("ne"); $numb = shift || return("ne");
  my $prsl = "eq"; my @prta = split(//, $numa); my @prtb = split(//, $numb);
  for (my $i=0; $i<7; $i++) {
    if($prsl eq "eq") {
      if     (($i < @prtb) && (($i == @prta) || 
              (b10($prta[$i]) < b10($prtb[$i])))) {
        $prsl = "lt";
      } elsif(($i < @prta) && (($i == @prtb) || 
              (b10($prta[$i]) > b10($prtb[$i])))) {
        $prsl = "gt";
      }
    }
  }
#if ($numa lt $numb) { $prsl = "lt"; } elsif($numa gt $numb) { $prsl = "gt"; } else { $prsl = "eq"; }
  return($prsl);
}

sub pt {
  my @parm = split(/\s+/, join(' ', @_)); # param
     @parm = split(/\s+/, join(' ', <STDIN>)) if(!@parm && -p STDIN); # pipedin
  my $tout = shift(@parm); my $dayv = shift(@parm); my $dowk; 
  my $colr = 0; my $nwln = 0;
  while(defined($tout) && $tout =~ s/^-+//) {
    if     ($tout =~ /^c/i) {     # escape colored output
      $colr = 1; 
      $colr = 2 if($tout =~ /^cp/); # colored for zshell prompt
    } elsif($tout =~ /^n/i) {     # append newline option
      $nwln = 1;
    } elsif($tout =~ s/^f//i) {   # read input from a file
      if     (length($tout) && -r $tout) { 
        open(INFL, "<$tout");
        @parm = split(/\s+/, join(' ', <INFL>));
        $dayv = shift(@parm);
        close(INFL);
      } elsif(length($dayv) && -r $dayv) { 
        open(INFL, "<$dayv"); $tout = $dayv; $dayv = shift(@parm); 
        @parm = split(/\s+/, join(' ', <INFL>));
        $dayv = shift(@parm);
        close(INFL);
      }
    }
    $tout = $dayv; $dayv = shift(@parm); 
  }
  if (         defined($tout)   && defined($dayv) && 
       exists($dmap{lc($tout)}) && 
      (exists($mmap{lc($dayv)}) || $dayv =~ /^\d\d?$/)) {
    $tout = $dayv; $dayv = shift(@parm); # ignore Day-of-the-Week as first parameter
  }
  my $yerv = shift(@parm); 
  my $horv = shift(@parm); my $minv = shift(@parm); 
  my $secv = shift(@parm); my $frmv = shift(@parm);
  my @lims = ( [ \$horv, 48 ], [ \$minv, 60 ], [ \$secv, 60 ], [ \$frmv, 60 ]);
  if (defined($yerv) && defined($horv) && $yerv =~ /^\d+:\d+(:\d+)?(:\d+)?$/) {
    ($yerv, $horv) = ($horv, $yerv);
  }
  if (defined($dayv) && defined($yerv) &&
    ($dayv =~ /^c(mp)?$/i || $yerv =~ /^c(mp)?$/i)) {
    if ($dayv =~ /^c(mp)?$/i) { $dayv = $yerv; }
    $yerv = "c";
  }
  if(defined($dayv) && defined($yerv) && $dayv =~ /^[+-]$/) {
    $tout .= "$dayv$yerv";
    if(defined($horv)) {
      if   ($horv eq "-e") { $dayv = "-e"; }
      elsif(defined($minv) && $horv =~ /^[+-]$/) {
        $tout .= "$horv$minv";
      }
    }
    if(defined($secv)) {
      if   ($secv eq "-e") { $dayv = "-e"; }
      elsif($secv =~ /^[+-]$/) {
        $temp = shift(@parm);
        if(defined($temp)) { $tout .= "$secv$temp"; }
      }
    }
  }
  my @time = localtime(); @time = @time[0..5]; my @fldz = (); my $year = 0;
  my @stim = (); my $summ = 0; my $oper = 0; my $subs = Time::HiRes::time();
  $subs -= int($subs); $subs = int($subs * 60); unshift(@time, $subs);
  @time = reverse @time;
  if(defined($tout)) {
    $tout = $mmap{lc($tout)} if(exists($mmap{lc($tout)}));
    if($tout =~ /^(\d\d?)([-\/])(\d\d?)\2(\d{1,4})$/) {
      $tout = $1; $dayv = $3; $yerv = $4; # month-day-year
      $yerv =  '0' . $yerv if(length($yerv) == 1);
      $yerv = '20' . $yerv if(length($yerv) == 2);
    }
  }
  if(!defined($tout)) {
    $time[0] -= 100; $time[1]++;
    for(my $i = 0; $i < 7; $i++) { $time[$i] = b64($time[$i]); }
  }
  if((defined($tout) && $tout =~ /^(\w+)([+-].+)$/)) { # add/sub pt
  #print "$tout=";
    $summ = $1; $tout = $2;
    $summ = Pt2Epoch($summ) if (length($summ) <= 7);
    while($tout =~ /^([+-])(\w+)/) {
      $oper = $2; while(length($oper) < 7) { $oper .= "0"; }
      @fldz = split(//, reverse($oper));
      @stim = localtime($summ);
      if ($1 eq "+") {
        $stim[0] += b64($fldz[0]);
        while ($stim[0] > 59) { $stim[1]++; $stim[0] -= 60; }
        $stim[1] += b64($fldz[1]);
        while ($stim[1] > 59) { $stim[2]++; $stim[1] -= 60; }
        $stim[2] += b64($fldz[2]);
        while ($stim[2] > 59) { $stim[3]++; $stim[2] -= 60; }
        $stim[3] += b64($fldz[3]);
        while ($stim[2] > 23) { $stim[3]++; $stim[2] -= 24; }
        $stim[3] += b64($fldz[3]);
        while ($stim[3] > days_in($stim[5], $stim[4])) {
          if ($stim[3] != 29 || $stim[4] != 1 || ($stim[5]%4) != 0) {
            $stim[3] -= days_in($stim[5], $stim[4]); $stim[4]++;
          } elsif ($stim[3] > 29) { # ck leap year
            $stim[3] -= 29; $stim[4]++;
          }
        }
        $stim[4] += (b10($fldz[4])+11)%12 + 1;
        while ($stim[4] > 11) { $stim[4] -= 12; $stim[5]++ if $fldz[4]; }
        $stim[5] += int((b10($fldz[4])-1)/12);
      } else {
        $stim[0] -= b10($fldz[0]);
        while ($stim[0] < 0) { $stim[1]--; $stim[0] += 60; }
        $stim[1] -= b10($fldz[1]);
        while ($stim[1] < 0) { $stim[2]--; $stim[1] += 60; }
        $stim[2] -= b10($fldz[2]);
        while ($stim[2] < 0) { $stim[3]--; $stim[2] += 24; }
        $stim[3] -= b10($fldz[3]);
        while ($stim[3] < 0) {
          if ($stim[4] != 2 || ($stim[5]%4) != 0) {
            $stim[4]--; $stim[3] += days_in($stim[5], $stim[4]);
          } else { # ck leap year
            $stim[4]--; $stim[3] += 29;
          }
        }
        $stim[4] -= (b10($fldz[4])+11)%12 + 1;
        while ($stim[4] < 0) { $stim[4] += 12; $stim[5]-- if $fldz[4]; }
        $stim[5] -= int((b10($fldz[4])-1)/12);
      }
      if (!$stim[3]) { $stim[3]++; } # adding a day to 0-days
      $summ = timelocal(@stim);
      $tout =~ s/^[+-]\w+//;
    }
    if(defined($dayv) && $dayv =~ /^(-e|d)$/) { $rslt = $summ; }
    else                                      { $rslt = Pt2Epoch($summ); }
  #print " ", $summ;
  #print " ", scalar localtime($summ);
  } elsif(defined($tout)) { # turn expanded date parameters into equiv pt
    $tout = $mmap{lc($tout)} if(exists($mmap{lc($tout)}));
    if     ($tout eq "-e" || (defined($dayv) && $dayv eq "-e")) { # cnv pt2ep
  #    ($tout, $dayv) = ($dayv, $tout) if(defined $dayv && $dayv eq "-e");
      if   ($tout eq "pt" || $tout eq "-e") { $rslt = scalar Time::HiRes::time(); }
      elsif(length($tout) > 7)              { $rslt = scalar localtime($tout); }
      else                                  { $rslt = Pt2Epoch($tout); }
    } elsif($tout eq "pt") {
      $dowk = Time::DayOfWeek::Dow($time[0] + 1900, $time[1] + 1, $time[2]);
      $rslt = sprintf("%s %s %2s %02d:%02d:%02d:%02d %4d", 
                  $dowk, $mnth[($time[1] % @mnth)], $time[2], $time[3], 
                  $time[4], $time[5], $time[6], $time[0] + 1900);
    } elsif(defined($dayv) && length($dayv) && length($tout) &&
      defined($yerv) && $yerv eq "c") {                    # compare two pt's
      $rslt = PtCmpPt($tout, $dayv);
    } else {                                               # normal pt decoding
      @time = split(//, $tout); @time = @time[0..6]; # chop extras off!
      for(my $i=0; $i<7; $i++) { 
        if(defined($time[$i])) { $time[$i] = b10($time[$i]); } 
        else                   { $time[$i] = 0; } 
      }
#  0) Each 12 added to the Month adds  64 to the Year.
#  1)      24 added to the Hour  adds 320 to the Year.
#  2)      31 added to the Day   makes the year negative just before adding 2k
      $time[1]-- if($time[1]);     # 0-base month
      $time[2]++ unless($time[2]); # 1-base day
      $time[1] %= 60; # 5 month blocks go 0-59  (0-11,12-23,24-35,36-47,48-59)
      $time[2] = 1 if($time[2] > 62); # day  blocks go 1..62  (1..31, 32..62)
      $time[3] %= 48;                 # hour blocks go 0..47  (0..23, 24..47)
      $time[4] %= 60; $time[5] %= 60; $time[6] %= 60; # min,sec,60th all 0..59
      while($time[1] > 11) { $time[0] +=  64; $time[1] -= 12; }
      if   ($time[3] > 23) { $time[0] += 320; $time[3] -= 24; }
      if   ($time[2] > 31) { $time[0] *=  -1; $time[2] -= 31; }
#print "tout:$tout\ntime:@time\n";
      $time[0] += 100;
      $dowk = Time::DayOfWeek::Dow($time[0] + 1900, $time[1] + 1, $time[2]);
      $rslt = sprintf("%s %s %2s %02d:%02d:%02d:%02d %4d", 
                  $dowk, $mnth[($time[1] % @mnth)], $time[2], $time[3], 
                  $time[4], $time[5], $time[6], $time[0] + 1900);
    }
  } else {                                                 # normal pt encoding
    if($colr) {
      if($colr == 2) {
        $rslt = "%{\e[1;31m%}$time[0]" . 
                "%{\e[0;33m%}$time[1]" . 
                "%{\e[1;33m%}$time[2]" . 
                "%{\e[32m%}$time[3]"   . 
                "%{\e[36m%}$time[4]"   . 
                "%{\e[34m%}$time[5]"   . 
                "%{\e[35m%}$time[6]";
      } else {
        $rslt = "\e[1;31m$time[0]" . 
                "\e[0;33m$time[1]" . 
                "\e[1;33m$time[2]" . 
                "\e[32m$time[3]"   . 
                "\e[36m$time[4]"   . 
                "\e[34m$time[5]"   . 
                "\e[35m$time[6]";
      }
    } else {
      $rslt = join('', @time);
    }
  #$temp = join('', @time); print "\n", `cnv $temp 64 128`, "\n", `cnv $temp 64 10`;
  } # print "\n"; # hmmm...
  $rslt .= "\n" if($nwln);
  return($rslt);
}
# END legacy `pt` util code

sub ptcc { # Generic PipTime Curses::Simp Color Code strings as class method
  my $frmt = shift || 0; my $ptst;
  if     ($frmt =~ /^-*f/i) {
    $ptst = '!YYY OOO YY GGWCCWUUWPP RRRR';
    #`pt pt`->Wed Jul 16 00:03:31:30 2003
  } elsif($frmt =~ /^-*k/i) {
    $ptst = '!ROYuX3GCUP'; # same as below but with 'hms' in blue bkgrnd
  } else {
    $ptst = '!ROYGCUP';    #'.bROYGCUP.';
    # `pt`->  YMDhmsf          YMDhmsf   
  }
  return($ptst); 
}

# returns a PT object's expanded string form
sub expand {
  my $self = shift; 
  return(sprintf("%3s %3s %2d %02d:%02d:%02d:%02d %4d", 
#    Time::DayOfWeek::Dow($self->YMD), 
                         $self->Dow(),
                   $mnth[$self->month() - 1],
                         $self->day(),
                         $self->hour(),
                         $self->minute(),
                         $self->second(),
                         $self->frame(),
                         $self->year()));
}

# adds color codes corresponding to each field according to ColorTYPe
#   (/^s/i) ? Curses::Simp color codes
# : (/^h/i) ? HTML links && font color tag delimiters
# : (/^4/i) ? 4NT verbose color codes
# : ANSI color escapes (/^z/i) ? wrapped in zsh delimiters;
sub _color_fields {
  my $self = shift;
  my $fstr = shift || ' ' x 10; $fstr =~ s/0+$// if(length($fstr) <= 7);
  my $ctyp = shift || 'ANSI';
  my @clrz = (); my $coun = 0; my $rstr = '';
  if     ($ctyp =~ /^s/i) { # simp color codes
    @clrz = @{$self->_field_colors('simp')};
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun++]; }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(1 + $coun++)]; }
    }
  } elsif($ctyp =~ /^h/i) { # HTML link && font color tag delimiters
    @clrz = @{$self->_field_colors('html')};
    $_    = '<font color="#' . $_ . '">' foreach(@clrz);
    $rstr = '<a href="http://Ax9.Org/pt?' . $fstr . '">';
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun] . substr($fstr, $coun++, 1) . '</font>'; }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(1 + $coun)] . substr($fstr, $coun++, 1) . '</font>'; }
    }
    $rstr .= '</a>';
  } elsif($ctyp =~ /^4/i) { # 4NT prompt needs verbose color codes
    @clrz = @{$self->_field_colors('4nt')};
    for(my $i=0; $i<@clrz; $i++) {
      $clrz[$i] = ' & color ' . $clrz[$i] . ' & echos ';
    }
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun] . substr($fstr, $coun++, 1); }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(1 + $coun)] . substr($fstr, $coun++, 1); }
    }
  } else { # ANSI escapes
    @clrz = @{$self->_field_colors('ansi')};
    if($ctyp =~ /^z/i) { # zsh prompt needs delimited %{ ANSI %}
      for(my $i=0; $i<@clrz; $i++) { $clrz[$i] = '%{' . $clrz[$i] . '%}'; }
    }
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun] . substr($fstr, $coun++, 1); }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(1 + $coun)] . substr($fstr, $coun++, 1); }
    }
  }
  return($rstr);
}

# Time::PT object constructor as class method or copy as object method.
# First param can be ref to copy.  Not including optional ref from 
#   copy, default is no params to create a new empty PT object.
# If params are supplied, they must be a single key && a single value.
# The key must be one of the following 3 types of constructor 
#   initialization mechanisms:
#    -1) <packedB64InitStringImplies'str'>(eg. '3C79jo0')
#     0) 'str'  => <packedB64InitString>  (eg. 'str'  => '0123456789')
#     1) 'list' => <arrayRef>             (eg. 'list' => [0, 1, 2..9])
#     2) 'hash' => <hashRef>              (eg. 'hash' => {'jink' => 8})
sub new { 
  my ($nvkr, $ityp, $idat) = @_; 
  my $nobj = ref($nvkr);
  my $clas = $ityp;
  $clas = $nobj || $nvkr if(!defined($ityp) || $ityp !~ /::/);
  my $self = Time::Fields->new($clas);
  my $rgxs; my $mont; my @attz = $self->_attribute_names();
#       timelocal($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
  my @ltim = localtime(); my $subs = Time::HiRes::time(); $subs -= int($subs); 
  $self->{'_year'}   = $ltim[5] + 1900;
  $self->{'_month'}  = $ltim[4] + 1;
  $self->{'_day'}    = $ltim[3];
  $self->{'_hour'}   = $ltim[2];
  $self->{'_minute'} = $ltim[1];
  $self->{'_second'} = $ltim[0];
  $self->{'_frame'}  = int($subs * $self->{'__fps'});
  #$subs *= $self->{'__fps'}; $subs -= int($subs);
  #$self->{'_jink'}   = int($subs * $self->{'__jpf'});
  $self->{'__time_separator'} = ':';
  $self->{'__date_separator'} = '-';
  foreach my $attr ( @attz ) { 
#    $self->{$attr} = $self->_default_value($attr); # init defaults
    $self->{$attr} = $nvkr->{$attr} if($nobj);     #  && copy if supposed to
  }
  if(defined($ityp) && $ityp !~ /::/) { # there were initialization params
    foreach my $attr ( @attz ) { 
      $self->{$attr} = $self->_default_value($attr); # init defaults
    }
    ($ityp, $idat) = ('str', $ityp) unless(defined($idat));
    if($ityp =~ /^verbose$/i) { # handle 'verbose' differently
      # verbose string param is expanded date &&/or time text
      $rgxs = '^\\s*((' . join('|', @dayo) . ')\\S*)?\\s*(' . 
                          join('|', @mnth) . ')\\S*\\s*(\\d+)' .
               '\\s+(\\d+(\D+(\\d+)){0,4})\\s+(\d+)\\s*$';
      if($idat =~ /$rgxs/i) { 
#print "idat:$idat\nrgxs:$rgxs\nDow?$2 Mon$3 dy$4 hr:mn?:sc?:fr?:jn?$5 YEAR!\n"; 
        $mont                = $3;
        $self->{'_day'}      = $4;
        ($self->{'_hour'}  , 
         $self->{'_minute'}, 
         $self->{'_second'}, 
         $self->{'_frame'} , 
         $self->{'_jink'}  ) = split(/\D+/, $5);
        $self->{'_year'}     = $8;
#print "M:$mont D:$self->{'_day'} h:($self->{'_hour'} m:$self->{'_minute'} s:$self->{'_second'} f:$self->{'_frame'} j:($self->{'_jink'} Y:$self->{'_year'}\n";
      } else {
        $rgxs = '^\\s*((' . join('|', @dayo) . ')\\S*)?\\s*(' . 
                            join('|', @mnth) . ')\\S*\\s*(' .
                '\\d+)\\s*,?\\s*(\\d+)\\s*$';
        if($idat =~ /$rgxs/i) { 
#print "Dow?$2 " if(defined($2)); print "Mon$3 dy$4 YEAR$5!\n"; 
          $mont            = $3;
          $self->{'_day'}  = $4;
          $self->{'_year'} = $5;
        } else {
          $rgxs = '^\\s*(\\d+(\D+(\\d+)){0,4})\\s*$';
          if($idat =~ /$rgxs/i) {
print "hr:mn?:sc?:fr?:jn?!\n"; 
# 2do: continue testing && assigning all acceptable verbose formats
          }
        }
      }
      if(defined($mont)) { # convert named month to proper index number
        for(my $i = 0; $i < @mnth; $i++) { # find which month name
          if(lc($mont) eq lc($mnth[$i])) { # $mont =~ /^$mnth[$i]/i) {
            $self->{'_month'} = ($i + 1); # ($i + 1) for 1-based month field
          }
        }
      }
    } elsif($ityp =~ /^s/i && length($idat) <= 9) { # handle small 'str' differently
      # small str param grows right from year field
      my $ilen = length($idat);
      for(my $i = 1; $i <= $ilen; $i++) {
        if($idat =~ s/^(.)//) {
          $self->{$attz[$i]} = b10($1); # break down str
        }
      }
      $self->{'_year'} += 2000;
    } else {
      foreach my $attr ( @attz ) {
        if     ($ityp =~ /^s/i) {    # 'str'
          $self->{$attr} = b10($1) if($idat =~ s/^(.)//);  # break down string
        } elsif($ityp =~ /^[la]/i) { # 'list' or 'array'
          $self->{$attr} = shift( @{$idat} ) if(@{$idat}); # shift list vals
        } elsif($ityp =~ /^h/i) {    # 'hash'
          # do some searching to find hash key that matches
          foreach(keys(%{$idat})) {
            if($attr =~ /$_/) {
              $self->{$attr} = $idat->{$_};
              delete($idat->{$_});
            }
          }
        } else { # undetected init type
          croak "!*EROR*! PT::new initialization type: $ityp did not match 'str', 'list', or 'hash'!\n";
        }
      }
    }
  }
  foreach my $attr ( @attz ) { # init defaults for any undefined fields
    $self->{$attr} = $self->_default_value($attr) unless(defined($self->{$attr})); 
  }
# Handle Year shifts
    $self->{'_year'} -= 2000;
#   0) Each 12 added to the Month adds  64 to the Year.
#   1)      24 added to the Hour  adds 320 to the Year.
#   2)      31 added to the Day   makes the year negative just before adding 2k
  my $mdec = 0; $mdec = 1 if($self->{'_month'}); 
  $self->{'_month'}-- if($mdec); # 0-base month
  my $dinc = 0; $dinc = 1 unless($self->{'_day'}); 
  $self->{'_day'}++   if($dinc); # 1-base day
  # 5 month blocks go 0..59  (0..11,12..23,24..35,36..47,48..59)
  $self->{'_month'} %= 60; 
  #   day   blocks go 1..62  (1..31, 32..62)
  $self->{'_day'}    = 1 if($self->{'_day'} > 62); 
  #   hour  blocks go 0..47  (0..23, 24..47)
  $self->{'_hour'}  %= 48;  
  # min,sec,frm,jnk all 0..59
  $self->{'_minute'} %= 60; $self->{'_second'} %= 60; 
  $self->{'_frame'}  %= 60; $self->{'_jink'}   %= 60; 
  while($self->{'_month'} > 11) { 
    $self->{'_year'} +=  64; $self->{'_month'} -= 12; 
  }
  if   ($self->{'_hour'}  > 23) { 
    $self->{'_year'} += 320; $self->{'_hour'}  -= 24; 
  }
  if   ($self->{'_day'}   > 31) { 
    $self->{'_year'} *=  -1; $self->{'_day'}   -= 31; 
  }
  $self->{'_day'}--   if($dinc); # 0-base day   again only if inc'd above
  $self->{'_month'}++ if($mdec); # 1-base month again only if dec'd above
  $self->{'_year'} += 2000;
  return($self);
}

sub subsecond { return(frame(@_)); }
sub _mon { # 0-based month
  my ($self, $nwvl) = @_;
  $self->{'_month'} = ($nwvl + 1) if(@_ > 1);
  return($self->{'_month'} - 1);
}
sub fullmonth { # full month string
  my ($self, $nwvl) = @_; my $mtch; my $mret; 
  my @mnmz = Time::DayOfWeek::MonthNames();
  if(@_ > 1) {
    for($mtch=0; $mtch<@mnmz; $mtch++) {
      if($mnmz[$mtch] =~ /^$nwvl/i) {
        $self->{'_month'} = $mtch + 1; last;
      }
    }
  }
  $mret = $mnmz[(($self->{'_month'} - 1) % 12)];
  return($mret);
}
sub monname { # abbreviated month string
  my $monr = $_[0]->fullmonth();
  if   (@_ > 2) { $monr = $_[ $_[0]->M ];          }
  elsif(@_ > 1) { $monr = $_[0]->fullmonth($_[1]); }
  $monr = substr($monr, 0, 3) if(length($monr) > 3);
  return($monr);
}
sub _year { # 1900-based year
  my ($self, $nwvl) = @_;
  $self->{'_year'} = ($nwvl + 1900) if(@_ > 1);
  return($self->{'_year'} - 1900);
}
sub yy { # 2-digit year
  my ($self, $nwvl) = @_; my $yret;
  if(@_ > 1) {
    ($nwvl >= 70) ? $self->{'_year'} = '19' . $nwvl :
                    $self->{'_year'} = '20' . $nwvl;
  }
  $yret = sprintf("%04d", $self->{'_year'});
  return(substr($self->{'_year'}, 2, 2));
}
sub dow { # index of day of week
  my ($self, $nwvl) = @_;
  return(Time::DayOfWeek::DoW($self->YMD));
}
sub Dow { # abbrev. day name
  my ($self, $nwvl) = @_;
  return(Time::DayOfWeek::Dow($self->YMD));
}
sub DayOfWeek { # full day name
  my ($self, $nwvl) = @_;
  return(Time::DayOfWeek::DayOfWeek($self->YMD));
}
*day_of_week = \&dow;
*_wday       = \&dow;
sub wday     { return(dow(@_) + 1);  }
sub wdayname {
  return($_[ $_[0]->wday ]) if(@_ > 2);
  return(Dow(@_));
}
#*day         = \&Dow; # let day be day-of-month rather than Time::Piece wk-day
*fullday     = \&DayOfWeek;
sub   yday      { # day of year
  my ($self, $nwvl) = @_; my $summ = 0;
  if(@_ > 1) {
    for(my $m=1; $m<12; $m++) {
      if(($summ + days_in($self->{'_year'}, $m)) > $nwvl) {
        $self->{'_month'} = $m;
        $self->{'_day'}   = $nwvl - $summ;
        last;
      } else {
        $summ += days_in($self->{'_year'}, $m);
      }
    }
    $summ = $nwvl;
  } else {
    for(my $m=1; $m<$self->{'_month'}; $m++) {
      $summ += days_in($self->{'_year'}, $m);
    }
    $summ += ($self->{'_day'} - 1);
  }
# following compares my yday calculation to localtime's
#my @ltdt = localtime(timelocal($self->smhD, $self->_mon, $self->Y));
#print "!EROR!summ:$summ != ltdt:" . $ltdt[-2] . "\n" if($summ != $ltdt[-2]);
#print join('', $self->smhD) . $self->_mon . ($self->Y - 1900) . "\n" .  join('', @ltdt) . "\n";
  return($summ);
}
*day_of_year = \&yday;
# isdst should be computed by formula when I figure out how so that it 
#   won't be restricted by UTC range that localtime expects.
sub isdst { # Is Daylight Savings Time?
  my ($self, $nwvl) = @_; # need 0-based month as timelocal() param
  my @ltdt = localtime(timelocal($self->smhD, $self->_mon, $self->Y));
  return($ltdt[-1]); 
}
*daylight_savings = \&isdst;
sub    time { return(    hmsf(  @_)); }
sub alltime { return(    hmsfjz(@_)); }
sub    date { return( YMD(      @_)); }
sub alldate { return(CYMD(      @_)); }
sub pt7     { return( YMDhmsf(  @_)); }
sub all     { return(CYMDhmsfjz(@_)); }
*dt = \&all;
sub datetime { #  2000-02-29T12:34:56            (ISO 8601)
  return(sprintf("%04d-%02d-%02dT%02d:%02d:%02d", $_[0]->YMDhms())); 
}
*cdate    = \&expand;
*compress = \&stringify;
# Add these to pod once imp'd
#    $t->epoch               # floating point seconds since the epoch
#    $t->tzoffset            # timezone offset in a Time::Seconds object
#
#    $t->julian_day          # number of days since Julian period began
#    $t->mjd                 # modified Julian date (JD-2400000.5 days)
#
#    $t->week                # week number (ISO 8601)
sub epoch { # floating point seconds since the epoch
  return(0);
}
sub tzoffset { # timezone offset in a Time::Seconds object
  return(0);
}
sub julian_day { # number of days since Julian period began
  return(0);
}
sub mjd { # modified Julian date (JD-2400000.5 days)
  return(0);
}
sub week { # week number (ISO 8601)
  return(0);
}
sub is_leap_year { # true if it its
  return(0);
}
sub month_last_day { # 28-31
  return(days_in($_[0]->YM));
}
sub time_separator { # set the default separator (default ":")
  $_[0]->{'__time_separator'} = $_[1] if(@_ > 1);
  return($_[0]->{'__time_separator'});
}
sub date_separator { # set the default separator (default "-")
  $_[0]->{'__date_separator'} = $_[1] if(@_ > 1);
  return($_[0]->{'__date_separator'});
}
sub day_list { # set the default weekdays
  my $self = shift;
  return(Time::DayOfWeek::DayNames(@_));
}
sub mon_list { # set the default months
  my $self = shift;
  return(Time::DayOfWeek::MonthNames(@_));
}

#sub AUTOLOAD { # methods (created as necessary)
#  no strict 'refs';
#  my ($self, $nwvl) = @_;
#
#  if     ($AUTOLOAD =~ /.*::[-_]?([CYMODhmisfjz])(.)?/i) { 
#    my ($atl1, $atl2) = ($1, $2); my $atnm;
#    my @mnmz = Time::DayOfWeek::MonthNames();
#    $atl1 = 'O' if($atl1 eq 'm' && defined($atl2) && lc($atl2) eq 'o');
#    $atl1 = 'i' if($atl1 eq 'M' && defined($atl2) && lc($atl2) eq 'i');
#    $atl1 = 'O' if($atl1 eq 'M');
#    $atl1 = 'i' if($atl1 eq 'm');
#    $atl1 = 'O' if($AUTOLOAD =~ /.*::fullmon/i);
#    foreach my $attr ($self->_attribute_names()){
#      my $mtch = $self->_attribute_match($attr);
#      $atnm = $attr if(defined($mtch) && $atl1 =~ /$mtch/i);
#    }
#    if($atl1 eq 'O') {
#      if($AUTOLOAD =~ /.*::_/) { # 0-based month
#        *{$AUTOLOAD} = sub { $_[0]->{$atnm} = ($_[1] + 1) if(@_ > 1); return($_[0]->{$atnm} - 1); };
#        $self->{$atnm} = ($nwvl + 1) if(@_ > 1);
#        return($self->{$atnm} - 1);
#      } elsif($AUTOLOAD =~ /.*::(full)?mon(th|n)/i) { # abbrev. Mon Name
#        if(defined $1) { # store fullmon to do the matching
#          *{$AUTOLOAD} = sub { 
#            my $mtch;
#            if(@_ > 1) {
#              foreach($mtch=0; $mtch<@mnmz; $mtch++) {
#                if($mnmz[$mtch] =~ /^$_[1]/i) { 
#                  $_[0]->{$atnm} = $mtch + 1; last; 
#                }
#              }
#            }
#            return($mnmz[(($_[0]->{$atnm} - 1) % 12)]);
#          };
#        } else { # store mon(th|n) as a wrapper that truncs fullmon
#          *{$AUTOLOAD} = sub { 
#            my $monr = $_[0]->fullmonth();
#               $monr = $_[0]->fullmonth($_[1]) if(@_ > 1);
#            $monr = substr($monr, 0, 3) if(length($monr) > 3);
#            return($monr);
#          };
#        }
#        my $mtch; my $mret;
#        if(@_ > 1) {
#          for($mtch=0; $mtch<@mnmz; $mtch++) {
#            if($mnmz[$mtch] =~ /^$nwvl/i) {
#              $self->{$atnm} = $mtch + 1; last;
#            }
#          }
#        }
#        $mret = $mnmz[(($self->{$atnm} - 1) % 12)];
#        if($AUTOLOAD !~ /.*::full/i && length($mret) > 3) {
#          $mret = substr($mret, 0, 3);
#        }
#        return($mret);
#      }
#    }
#  # normal set_/get_ methods
#
#  if     ($AUTOLOAD =~ /.*::[sg]et(_\w+)/i) {
#    my $atnm = lc($1);
#    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
#    $self->{$atnm} = $nwvl if(@_ > 1);
#    return($self->{$atnm});
#  # use_??? to set/get field filters
#  } elsif($AUTOLOAD =~ /.*::(use_\w+)/i) {
#    my $atnm = '__' . lc($1);
#    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
#    $self->{$atnm} = $nwvl if(@_ > 1);
#    return($self->{$atnm});
#  # Alias methods which must be detected before sweeps
#  } elsif($AUTOLOAD =~ /.*::time$/i) { 
#    *{$AUTOLOAD} = sub { return($self->hms()); };
#    return($self->hms());
#  } elsif($AUTOLOAD =~ /.*::dt$/i) { 
#    *{$AUTOLOAD} = sub { return($self->CYMDhmsfjz()); };
#    return($self->CYMDhmsfjz());
#  } elsif($AUTOLOAD =~ /.*::mday$/i) { my $atnm = '_day';
#    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
#    $self->{$atnm} = $nwvl if(@_ > 1); return($self->{$atnm});
#  # all joint field methods (eg. YMD(), hms(), foo(), etc.
#  } elsif($AUTOLOAD =~ /.*::([CYMODhmisfjz][CYMODhmisfjz]+)$/i) { 
#    my @fldl = split(//, $1); 
#    my ($self, @nval) = @_; my @rval = (); my $atnm = ''; my $rgex;
#    # handle Month / minute exceptions
#    for(my $i=0; $i<$#fldl; $i++) {
#      $fldl[$i + 1] = 'O' if($fldl[$i] =~ /[yd]/i && $fldl[$i + 1] eq 'm');
#      $fldl[$i    ] = 'O' if($fldl[$i] eq 'm'     && $fldl[$i + 1] =~ /[yd]/i);$      $fldl[$i    ] = 'O' if($fldl[$i] eq 'M');
#      $fldl[$i    ] = 'i' if($fldl[$i] eq 'm');
#    }
#    *{$AUTOLOAD} = sub { 
#      my ($self, @nval) = @_; my @rval = (); 
#      for(my $i=0; $i<@fldl; $i++) {
#        foreach my $attr ($self->_attribute_names()){
#          my $mtch = $self->_attribute_match($attr);
#          if(defined($mtch) && $fldl[$i] =~ /^$mtch/i) {
#            $self->{$attr} = $nval[$i] if($i < @nval);
#            push(@rval, $self->{$attr});
#          }
#        }
#      }
#      return(@rval);
#    };
#    for(my $i=0; $i<@fldl; $i++) {
#      foreach my $attr ($self->_attribute_names()){
#        my $mtch = $self->_attribute_match($attr);
#        if(defined($mtch) && $fldl[$i] =~ /$mtch/i) {
#          $self->{$attr} = $nval[$i] if($i < @nval);
#          push(@rval, $self->{$attr});
#        }
#      }
#    }
#    return(@rval);
#  # sweeping matches to handle partial keys
#  } elsif($AUTOLOAD =~ /.*::[-_]?([CYMODhmisfjz])(.)?/i) { 
#    my ($atl1, $atl2) = ($1, $2); my $atnm;
#    $atl1 = 'O' if($atl1 eq 'm' && defined($atl2) && lc($atl2) eq 'o');
#    $atl1 = 'i' if($atl1 eq 'M' && defined($atl2) && lc($atl2) eq 'i');
#    $atl1 = 'O' if($atl1 eq 'M');
#    $atl1 = 'i' if($atl1 eq 'm');
#    foreach my $attr ($self->_attribute_names()) {
#      my $mtch = $self->_attribute_match($attr);
#      $atnm = $attr if(defined($mtch) && $atl1 =~ /$mtch/i);
#    }
#    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
#    $self->{$atnm} = $nwvl if(@_ > 1);
#    return($self->{$atnm});
#  } else {
#    my $fnam = $AUTOLOAD;
#    $fnam =~ s/Time::PT::/Time::Fields::/;
#    return(&$fnam);
#    croak "No such method: $AUTOLOAD\n";
#  }
#}

sub DESTROY { } # do nothing but define in case && to calm warning in test.pl

127;
