# 382C8tQ - Time::Fields.pm created by Pip@CPAN.Org as an abstract base 
#   class for more specialized Time objects (Time::Frame && Time::PT).
# Notz: 
#   timelocal($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
#   Unix epoch 1970-2036 or something
#   PT   epoch 1361-2631
#   potential smaller fields:
#       kink as 60th-of-a-jink? tink as 60th-of-a-kink? ... X as 60th-of-a-Y
#     frame 0.0166666666666667        CYMDhmsfjktbpaz
#     jink  0.000277777777777778               0.3 milliseconds (thousanths)
#     kink  0.00000462962962962963             5   microseconds (millionths)
#     tink  0.0000000771604938271605          77   nano seconds (billionths)
#     blip  0.00000000128600823045267          1   nano second 
#       RealTimeOperatingSystems may need micro or nano second precision
#     pip   0.0000000000214334705075446       21   pico seconds (trillionths)
#     ax    0.000000000000357224508459076      0.4 pico seconds
#           0.00000000000000595374180765127    6   femtoseconds (10e-15)
#           0.0000000000000000992290301275212 99   atto seconds (10e-18)
#           0.00000000000000000165381716879202 2   atto seconds
#           0.000000000000000000027563619479867            27   zepto   -21
#           0.000000000000000000000459393657997783          0.5 zepto
#           0.00000000000000000000000765656096662972        8   yocto   -24
#           0.000000000000000000000000127609349443829       0.1 yocto
#           0.00000000000000000000000000212682249073048     2   harpo   -27
#           0.0000000000000000000000000000354470415121746  35   groucho -30
#           0.000000000000000000000000000000590784025202911 0.6 groucho
#      zepto (10e-21) yocto (10e-24) harpo (10e-27) groucho (10e-30) 
#      zeppo (10e-33) gummo (10e-36) chico (10e-39)

=head1 NAME

Time::Fields - abstract objects to store distinct time fields

=head1 VERSION

This documentation refers to version 1.2.565EHOV of 
Time::Fields, which was released on Sun Jun  5 14:17:24:31 2005.

=head1 SYNOPSIS

  package Time::Fields::NewChildPackageOfTimeFields;
  use base qw(Time::Fields);

  # NewChildPackageOfTimeFields definition...

=head1 DESCRIPTION

Time::Fields defines simple time objects with distinct fields for:

  Century, Year, Month, Day, hour, minute, second, frame, jink, zone

along with methods to manipulate those fields && modify their
default presentation.  Normally, a frame is one 60th-of-a-
second && a jink is one 60th-of-a-frame or about 0.3 milliseconds.
The plural for 'jink' is 'jinx'.  Fields data && methods are 
meant to be inherited by other classes (namely L<Time::Frame> && 
L<Time::PT>) which implement specific useful interpretations of 
individual Time::Fields.

=head1 2DO

=over 2

=item - use_? filters should get auto-set when unused fields get assigned

=item -     What else does Fields need?

=back

=head1 WHY?

The reason I created Fields was that I have grown so enamored with
Base64 representations of everything around me that I was 
compelled to write a simple clock utility ( `pt` ) using Base64.
This demonstrated the benefit to be gained from time objects with
distinct fields && configurable precision.  Thus, Time::Fields
was written to be the abstract base class for:

  Time::Frame  ( creates objects which represent spans    of time )
      && 
  Time::PT     ( creates objects which represent instants in time )

=head1 USAGE

Many of Time::Fields's methods have been patterned after the 
excellent L<Time::Piece> module written by Matt Sergeant 
<matt@sergeant.org> && Jarkko Hietaniemi <jhi@iki.fi>.

=head2 new(<InitType>, <InitData>)

Time::Fields's constructor can be 
called as a class method to create a brand new object or as
an object method to copy an existing object.  Beyond that,
new() can initialize Fields objects the following ways:

  * <packedB64InitStringImplies'str'>
    eg. Time::Fields->new('0123456789');
  * 'str'  => <packedB64InitString>
    eg. Time::Fields->new('str'  => '0123456789');
  * 'list' => <arrayRef>
    eg. Time::Fields->new('list' => [0, 1, 2..9]);
  * 'hash' => <hashRef>
    eg. Time::Fields->new('hash' => {'jink' => 8, 'year' => 2003})

b<*Note*>  If only a valid 'str'-type parameter is given to new 
(but no accompanying initialization value), the parameter 
is interpreted as an implied 'str' value.

    eg. Time::Fields->new('0123456789');

This implied 'str'-type initialization will probably be
the most common Time::Fields object creation mechanism
when individual fields do not exceed 64 since this 
efficient representation is why the module was created.

The following methods allow access to individual fields of 
existent Time::Fields objects:

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

Any combination of above single letters can be used as well.  
Following are some common useful examples:

  $t->hms                 # returns list of fields eg. [12, 34, 56]
  $t->hms(12, 56, 34)     # sets fields: h = 12, m = 56, s = 34
  $t->hmsf                # [12, 34, 56, 12]
  $t->hmsfj               # [12, 34, 56, 12, 34]
  $t->hmsfjz              # [12, 34, 56, 12, 34, 16]
  $t->time                # same as $t->hms
  $t->alltime             # same as $t->hmsfjz
  $t->YMD                 # [2000,  2,   29]
  $t->MDY                 # [   2, 29, 2000]
  $t->DMY                 # [  29,  2, 2000]
  $t->CYMD                # [  20,  0,    2, 29]
  $t->date                # same as $t->YMD
  $t->alldate             # same as $t->CYMD
  $t->CYMDhmsfjz          # [  20,  0,    2, 29, 12, 13, 56, 12, 13, 16]
  $t->dt                  # same as $t->CYMDhmsfjz
  $t->all                 # same as $t->CYMDhmsfjz
  "$t"                    # same as $t->CYMDhmsfjz

=head2 Month / minute Exceptions

Fields object method names can be in any case with the following
exceptions.  Special handling exists to resolve ambiguity between
the Month && minute fields.  If a lowercase 'm' is used adjacent to
a 'y' or 'd' of either case, it is interpreted as Month.  Otherwise,
the case of the 'm' distinguishes Month from minute.  An uppercase
'M' is ALWAYS Month.  An adjacent uppercase 'H' or 'S' will not turn
an uppercase 'M' into minute.  Method names which need to specify
Month or minute fields can also optionally be uniquely specified by
their distinguishing vowel ('o' or 'i') instead of 'M' or 'm'.

  $t->ymd                 # same as $t->YMD
  $t->dmy                 # same as $t->DMY
  $t->MmMm                # Month minute Month minute
  $t->HMS                 # hour Month second! NOT same as $t->hms 
  $t->yod                 # same as $t->YMD
  $t->chmod               # Century hour minute Month Day
  $t->FooIsMyJoy          # frame Month Month     minute second
                          #      Month Year     jink Month Year

=head1 NOTES

Whenever individual Time::Fields attributes are going to be 
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

Even though Time::Fields is designed to be an abstract base class,
it has not been written to croak on direct usage && object 
instantiation because simple Fields objects may already be
worthwhile.

I hope you find Time::Fields useful.  Please feel free to e-mail
me any suggestions || coding tips || notes of appreciation 
("app-ree-see-ay-shun").  Thank you.  TTFN.

=head1 CHANGES

Revision history for Perl extension Time::Fields:

=over 4

=item - 1.2.565EHOV  Sun Jun  5 14:17:24:31 2005

* combined Fields, Frame, && PT into one pkg (so see PT CHANGES section
    for updates to Fields or Frame)

=item - 1.0.3CCA4Eh  Fri Dec 12 10:04:14:43 2003

* removed indenting from POD NAME field

=item - 1.0.3CB7Qb0  Thu Dec 11 07:26:37:00 2003

* updated pod && prepared for release

=item - 1.0.3CA8oiI  Wed Dec 10 08:50:44:18 2003

* cleaned up documentation

* implemented use methods

* overloaded for stringification

=item - 1.0.39GHeCl  Tue Sep 16 17:40:12:47 2003

* incorporated stuff learned from ObjectOrientedPerl (Conway)

=item - 1.0.382DLbX  Sat Aug  2 13:21:37:33 2003

* fleshed out documentation && ideas

=item - 1.0.37VG26k  Thu Jul 31 16:02:06:46 2003

* original version

=back

=head1 INSTALL

Please run:

    `perl -MCPAN -e "install Time::PT"`

or uncompress the package && run the standard:

    `perl Makefile.PL; make; make test; make install`

=head1 FILES

Time::Fields requires:

L<Carp>                to allow errors to croak() from calling sub

L<Math::BaseCnv>       to handle number-base conversion

Time::Fields utilizes (if available):

L<Time::HiRes>         to provide sub-second time precision

L<Time::Local>         to provide Unix time conversion options

=head1 SEE ALSO

Time::Frame && Time::PT

=head1 LICENSE

Most source code should be Free!
  Code I have lawful authority over is && shall be!
Copyright: (c) 2003-2004, Pip Stuart.
Copyleft : This software is licensed under the GNU General Public
  License (version 2), && as such comes with NO WARRANTY.  Please
  consult the Free Software Foundation (http://FSF.Org) for
  important information about your freedom.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut

package Time::Fields;
use strict;
use vars qw( $AUTOLOAD );
our $VERSION     = '1.2.565EHOV'; # major . minor . PipTimeStamp
our $PTVR        = $VERSION; $PTVR =~ s/^\d+\.\d+\.//; # strip major && minor
# Please see `perldoc Time::PT` for an explanation of $PTVR.
use overload 
  q("") => sub { # anonymous stringify()
             my @fdat = $_[0]->CYMDhmsfjz(); 
             my @attz = $_[0]->_attribute_names();
             my $tstr = '';
             for(my $i=0; $i<@fdat; $i++) {
               $attz[$i] =~ s/^_(.).*/$1/;
               $attz[$i] = uc($attz[$i]) if($i < 4);
               $fdat[$i] = 0 unless(defined($fdat[$i]));
               $tstr .= $attz[$i] . ':' . $fdat[$i];
               $tstr .= ', ' if($i < $#fdat);
             }
             return($tstr);
           };

use Carp;
use Math::BaseCnv qw(:all);
my $locl = eval("use Time::Local; 1") || 0;
my $hirs = eval("use Time::HiRes; 1") || 0;
#my $simp = eval("use Curses::Simp; 1") || 0; # ADD to FILES POD if use Simp!

# ordered attribute names array, match string for regular expressions, &&
#                                default attribute data hash
my @_attrnamz = ();             my %_attrmtch = ();
                                my %_attrdata = ();
# field data
push(@_attrnamz, '_century');      $_attrmtch{$_attrnamz[-1]} = 'C';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_year');         $_attrmtch{$_attrnamz[-1]} = 'Y';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_month');        $_attrmtch{$_attrnamz[-1]} = 'O';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_day');          $_attrmtch{$_attrnamz[-1]} = 'D';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_hour');         $_attrmtch{$_attrnamz[-1]} = 'h';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_minute');       $_attrmtch{$_attrnamz[-1]} = 'i';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_second');       $_attrmtch{$_attrnamz[-1]} = 's';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_frame');        $_attrmtch{$_attrnamz[-1]} = 'f';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_jink');         $_attrmtch{$_attrnamz[-1]} = 'j';
                                   $_attrdata{$_attrnamz[-1]} =     0;
push(@_attrnamz, '_zone');         $_attrmtch{$_attrnamz[-1]} = 'z';
                                   $_attrdata{$_attrnamz[-1]} =     0;
# ratios of frames-per-second && jinx-per-frame
push(@_attrnamz, '__fps');         $_attrdata{$_attrnamz[-1]} = 60;
push(@_attrnamz, '__jpf');         $_attrdata{$_attrnamz[-1]} = 60;
# filter flags for which particular fields should be used by default
push(@_attrnamz, '__use_century'); $_attrdata{$_attrnamz[-1]} = 0;
push(@_attrnamz, '__use_year');    $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_month');   $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_day');     $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_hour');    $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_minute');  $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_second');  $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_frame');   $_attrdata{$_attrnamz[-1]} = 1;
push(@_attrnamz, '__use_jink');    $_attrdata{$_attrnamz[-1]} = 0;
push(@_attrnamz, '__use_zone');    $_attrdata{$_attrnamz[-1]} = 0;
# global field color codes in a hash of arrays
my %_fielclrz = (
     'simp' => ['!r',    # DarkRed    Century
                '!R',    # Red        Year
                '!O',    # Orange     Month
                '!Y',    # Yellow     Day
                '!G',    # Green       hour
                '!C',    # Cyan        minute
                '!U',    # Blue        second
                '!P',    # Purple      frame
                '!p',    # DarkPurple  jink
                '!w'],   # Grey        zone
     'html' => ['7F0B1B',  # DarkRed    Century
                'FF1B2B',  # Red        Year
                'FF7B2B',  # Orange     Month
                'FFFF1B',  # Yellow     Day
                '1BFF3B',  # Green       hour
                '1BFFFF',  # Cyan        minute
                '1B7BFF',  # Blue        second
                'BB1BFF',  # Purple      frame
                '5B0B7F',  # DarkPurple  jink
                '7F7F7F'], # Grey        zone
     'ansi' => ["\e[0;31m",  # DarkRed    Century
                "\e[1;31m",  # Red        Year
                "\e[0;33m",  # Orange     Month
                "\e[1;33m",  # Yellow     Day
                "\e[1;32m",  # Green       hour
                "\e[1;36m",  # Cyan        minute
                "\e[1;34m",  # Blue        second
                "\e[1;35m",  # Purple      frame
                "\e[0;35m",  # DarkPurple  jink
                "\e[0;30m"], # Grey        zone
     '4nt'  => ["04",      # DarkRed    Century
                "0c",      # Red        Year
                "06",      # Orange     Month
                "0e",      # Yellow     Day
                "0a",      # Green       hour
                "0b",      # Cyan        minute
                "09",      # Blue        second
                "0d",      # Purple      frame
                "05",      # DarkPurple  jink
                "07"],     # Grey        zone
); 

# methods
sub _default_value   { my ($self, $attr) = @_; $_attrdata{$attr}; } # Dflt vals
sub _attribute_match { my ($self, $attr) = @_; $_attrmtch{$attr}; } # matching
sub _attribute_names { @_attrnamz; } # attribute names
sub _Time_Local  { $locl; } # can Time::Local be used?
sub _Time_HiRes  { $hirs; } # can Time::HiRes be used?
#sub _Curses_Simp { $simp; } # can Curses::Simp be used?

# Time::Fields object constructor as class method or copy as object method.
# First param can be ref to copy.  Not including optional ref from 
#   copy, default is no params to create a new empty Fields object.
# If params are supplied, they must be a single key && a single value.
# The key must be one of the following 3 types of constructor 
#   initialization mechanisms:
#     0) 'str'  => <packedB64InitString>  (eg. 'str'  => '0123456789')
#     1) 'list' => <arrayRef>             (eg. 'list' => [0, 1, 2..9])
#     2) 'hash' => <hashRef>              (eg. 'hash' => {'jink' => 8})
sub new { 
  my ($nvkr, $ityp, $idat) = @_; 
  my $nobj = ref($nvkr);
  my $clas = $ityp;
  $clas = $nobj || $nvkr if(!defined($ityp) || $ityp !~ /::/);
  my $self = bless({}, $clas);
  foreach my $attr ( $self->_attribute_names() ) { 
    $self->{$attr} = $self->_default_value($attr); # init defaults
    $self->{$attr} = $nvkr->{$attr} if($nobj);     #  && copy if supposed to
  }
  # there were init params with no colon (classname)
  if(defined($ityp) && $ityp !~ /::/) { 
    ($ityp, $idat) = ('str', $ityp) unless(defined($idat));
    foreach my $attr ( $self->_attribute_names() ) {
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
        croak "!*EROR*! Time::Fields::new initialization type: $ityp did not match 'str', 'list', or 'hash'!\n";
      }
    }
  }
  return($self);
}

sub _field_colors { # return the color code array associated with a type
  my $self = shift; my $type = shift;
  $type = 'ansi' unless(defined($type) && exists($_fielclrz{lc($type)}));
  return($_fielclrz{ lc($type) });
}

sub _color_fields { # return a color string for a Fields object
  my $self = shift;
  my $fstr = shift || ' ' x 10; $fstr =~ s/0+$// if(length($fstr) <= 7);
  my $ctyp = shift || 'ansi';
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

sub color { # generic self color method to call overloaded subclass colorfields
  my $self = shift; 
  my $fstr = "$self"; 
  my $ctyp = shift || 'ansi';
  return($self->_color_fields($fstr, $ctyp));
}

sub AUTOLOAD { # methods (created as necessary)
  no strict 'refs';
  my ($self, $nwvl) = @_;

  # normal set_/get_ methods
  if     ($AUTOLOAD =~ /.*::[sg]et(_\w+)/i) {
    my $atnm = lc($1);
    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
    $self->{$atnm} = $nwvl if(@_ > 1);
    return($self->{$atnm});
  # use_??? to set/get field filters
  } elsif($AUTOLOAD =~ /.*::(use_\w+)/i) {
    my $atnm = '__' . lc($1);
    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
    $self->{$atnm} = $nwvl if(@_ > 1);
    return($self->{$atnm});
  # Alias methods which must be detected before sweeps
  } elsif($AUTOLOAD =~ /.*::time$/i) { 
    *{$AUTOLOAD} = sub { return($self->hms()); };
    return($self->hms());
  } elsif($AUTOLOAD =~ /.*::alltime$/i) { 
    *{$AUTOLOAD} = sub { return($self->hmsfjz()); };
    return($self->hmsfjz());
  } elsif($AUTOLOAD =~ /.*::date$/i) { 
    *{$AUTOLOAD} = sub { return($self->YMD()); };
    return($self->YMD());
  } elsif($AUTOLOAD =~ /.*::alldate$/i) { 
    *{$AUTOLOAD} = sub { return($self->CYMD()); };
    return($self->CYMD());
  } elsif($AUTOLOAD =~ /.*::all$/i) { 
    *{$AUTOLOAD} = sub { return($self->CYMDhmsfjz()); };
    return($self->CYMDhmsfjz());
  } elsif($AUTOLOAD =~ /.*::dt$/i) { 
    *{$AUTOLOAD} = sub { return($self->CYMDhmsfjz()); };
    return($self->CYMDhmsfjz());
  } elsif($AUTOLOAD =~ /.*::mday$/i) { my $atnm = '_day';
    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
    $self->{$atnm} = $nwvl if(@_ > 1); return($self->{$atnm});
  # all joint field methods (eg. YMD(), hms(), foo(), etc.
  } elsif($AUTOLOAD =~ /.*::([CYMODhmisfjz][CYMODhmisfjz]+)$/i) { 
    my @fldl = split(//, $1); 
    my ($self, @nval) = @_; my @rval = (); my $atnm = ''; my $rgex;
    # handle Month / minute exceptions
    for(my $i=0; $i<$#fldl; $i++) {
      $fldl[$i + 1] = 'O' if($fldl[$i] =~ /[yd]/i && $fldl[$i + 1] eq 'm');
      $fldl[$i    ] = 'O' if($fldl[$i] eq 'm'     && $fldl[$i + 1] =~ /[yd]/i);
      $fldl[$i    ] = 'O' if($fldl[$i] eq 'M');
      $fldl[$i    ] = 'i' if($fldl[$i] eq 'm');
    }
    *{$AUTOLOAD} = sub { 
      my ($self, @nval) = @_; my @rval = (); 
      for(my $i=0; $i<@fldl; $i++) {
        foreach my $attr ($self->_attribute_names()){
          my $mtch = $self->_attribute_match($attr);
          if(defined($mtch) && $fldl[$i] =~ /^$mtch/i) {
            $self->{$attr} = $nval[$i] if($i < @nval);
            push(@rval, $self->{$attr});
          }
        }
      }
      return(@rval);
    };
    for(my $i=0; $i<@fldl; $i++) {
      foreach my $attr ($self->_attribute_names()){
        my $mtch = $self->_attribute_match($attr);
        if(defined($mtch) && $fldl[$i] =~ /$mtch/i) {
          $self->{$attr} = $nval[$i] if($i < @nval);
          push(@rval, $self->{$attr});
        }
      }
    }
    return(@rval);
  # sweeping matches to handle partial keys
  } elsif($AUTOLOAD =~ /.*::[-_]?([CYMODhmisfjz])(.)?/i) { 
    my ($atl1, $atl2) = ($1, $2); my $atnm;
    $atl1 = 'O' if($atl1 eq 'm' && defined($atl2) && lc($atl2) eq 'o');
    $atl1 = 'i' if($atl1 eq 'M' && defined($atl2) && lc($atl2) eq 'i');
    $atl1 = 'O' if($atl1 eq 'M');
    $atl1 = 'i' if($atl1 eq 'm');
    foreach my $attr ($self->_attribute_names()){
      my $mtch = $self->_attribute_match($attr);
      $atnm = $attr if(defined($mtch) && $atl1 =~ /$mtch/i);
    }
    if($atl1 eq 'O') {
      if($AUTOLOAD =~ /.*::_/) { # 0-based month
        *{$AUTOLOAD} = sub { $_[0]->{$atnm} = ($_[1] + 1) if(@_ > 1); return($_[0]->{$atnm} - 1); };
        $self->{$atnm} = ($nwvl + 1) if(@_ > 1);
        return($self->{$atnm} - 1);
      }
    }
    *{$AUTOLOAD} = sub { $_[0]->{$atnm} = $_[1] if(@_ > 1); return($_[0]->{$atnm}); };
    $self->{$atnm} = $nwvl if(@_ > 1);
    return($self->{$atnm});
  } else {
    croak "No such method: $AUTOLOAD\n";
  }
}

sub DESTROY { } # do nothing but define in case && to calm warning in test.pl

127;
