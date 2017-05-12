# 37VG26k - Time::Frame.pm created by Pip@CPAN.Org to make simple
#   objects for frames of time.
# Desc: Frame describes a simple object which encapsulates 10 fields:
#     Century, Year, Month, Day, hour, minute, second, frame, jink, zone
#   where frame is normally 1/60th-of-a-second && jink is normally 
#   1/60th-of-a-frame.  The objects describe a high-precision time-frame 
#   (as in, a duration, a period, a length or span of time).  Frame 
#   objects can be added to / subtracted from Time::PT objects to yield 
#   new specific PT instants.
#     1st: '0A1B2C3'
#     2nd: 'Yd:2003,j:A7_,M:a3I' or 'f:3aL9.eP' 
#     if field name ends with d, value is read as decimal nstd of default b64.
#     Third way is super verbose decimal strings:
#       '15 years, 3 months, 7 weeks, 4 jinx' can use any (or none) sep but :
#     4th is hash
#     Total Jinx possible for PT: 1,680,238,080,000,000 (1.7 quatrillion)
#           JnxPTEpoch -> `pt __nWO0000` -> Midnight Jan. 1 7039 BCE
#              PTEpoch -> `pt  _nWO`     -> Midnight Jan. 1 1361  CE
#   Frame members:
#     new inits either with pt-param, expanded, or empty
#
#     settle fields (like return new Frame object with only total secs of old)
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

=head1 NAME

Time::Frame - objects to store a length of time

=head1 VERSION

This documentation refers to version 1.2.565EHOV of 
Time::Frame, which was released on Sun Jun  5 14:17:24:31 2005.

=head1 SYNOPSIS

  use Time::Frame;
  
  my $f = Time::Frame->new('verbose' => '2 weeks');
  print 'Number of days is ', $f->day(), "\n";

=head1 DESCRIPTION

This module has been adapted from the Time::Seconds module 
written by Matt Sergeant <matt@sergeant.org> && Jarkko 
Hietaniemi <jhi@iki.fi>.  Time::Frame inherits base 
data structure && object methods from Time::Fields.  
Frame was written to simplify storage && calculation 
of encoded, yet distinct && human-readable, time data 
objects.

The title of this Perl module has dual meaning.  Frame
means both the span of time the whole object represents
as well as the (default) smallest unit of measurement.

=head1 2DO

=over 2

=item - copy total_frames into AUTOLOAD for (in|as|total)_(CYMDhmsfj)
          functions which convert to any field

=item - better ways to specify common verbose sizes

=item -     What else does Frame need?

=back

=head1 WHY?

The reason I created Frame was that I have grown so enamored with
Base64 representations of everything around me that I was 
compelled to write a simple clock utility ( `pt` ) using Base64.
This demonstrated the benefit to be gained from time objects with
distinct fields && configurable precision.  Thus, L<Time::Fields>
was written to be the abstract base class for:

    Time::Frame  ( creates objects which represent spans    of time )
        && 
    Time::PT     ( creates objects which represent instants in time )

=head1 USAGE

Many of Time::Frame's methods have been patterned after the excellent
L<Time::Piece> module written by Matt Sergeant <matt@sergeant.org>
&& Jarkko Hietaniemi <jhi@iki.fi>.

=head2 new(<InitType>, <InitData>)

Time::Frame's constructor can be called as a class method to create a
brand new object or as an object method to copy an existing object.
Beyond that, new() can initialize Frame objects in the following ways:

  * <packedB64InitStringImplies'str'>
    eg. Time::Frame->new('0123456789');
  * 'str'  => <packedB64InitString>
    eg. Time::Frame->new('str'  => '0A1B2C3D4E');
  * 'list' => <arrayRef>
    eg. Time::Frame->new('list' => [0, 1, 2..9]);
  * 'hash' => <hashRef>
    eg. Time::Frame->new('hash' => {'jink' => 8, 'year' => 2003})

=head2 total_frames()

total_frames simply returns the total number of frames a Time::Frame
object specifies.

=head2 color(<DestinationColorTypeFormat>)

This is an object member
which will join Base64 representations of each field that has
been specified in use() && joins them with color-codes or color
escape sequences with formats for varied uses.  Currently
available DestinationColorTypeFormats are:

    'ANSI'  # eg. \e[1;32m
    'zsh'   # eg. %{\e[1;33m%}
    'HTML'  # eg. <a href="http://Ax9.Org/pt?"><font color="#FF1B2B">
    'Simp'  # eg. RbobYbGbCbUbPb

The following methods allow access to individual fields of 
Time::Frame objects:

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

Please see L<Time::Fields> for a more thorough description of field
accessor methods.

=head1 NOTES

Whenever individual Time::Frame attributes are going to be 
printed or an entire object can be printed with multi-colors,
the following mapping should be employed whenever possible:

          D       Century -> DarkRed
          A       Year    -> Red
          T       Month   -> Orange
          E       Day     -> Yellow
                   hour   -> Green
           t       minute -> Cyan
           i       second -> Blue
           m       frame  -> Purple
           e       jink   -> DarkPurple
                   zone   -> Grey or White

Please see the color() member function in the USAGE section.

I hope you find Time::Frame useful.  Please feel free to e-mail
me any suggestions || coding tips || notes of appreciation 
("app-ree-see-ay-shun").  Thank you.  TTFN.

=head1 CHANGES

Revision history for Perl extension Time::Frame:

=over 4

=item - 1.2.565EHOV  Sun Jun  5 14:17:24:31 2005

* combined Fields, Frame, && PT into one pkg (so see PT CHANGES section
    for updates to Fields or Frame)

=item - 1.0.3CCA3bG  Fri Dec 12 10:03:37:16 2003

* removed indenting from POD NAME field

=item - 1.0.3CB7RLu  Thu Dec 11 07:27:21:56 2003

* added HTML color option && prepared for release

=item - 1.0.3CA8thM  Wed Dec 10 08:55:43:22 2003

* built class to inherit from Time::Fields

=item - 1.0.37VG26k  Thu Jul 31 16:02:06:46 2003

* original version

=back

=head1 INSTALL

Please run:

      `perl -MCPAN -e "install Time::PT"`

or uncompress the package && run the standard:

      `perl Makefile.PL; make; make test; make install`

=head1 FILES

Time::Frame requires:

L<Carp>                to allow errors to croak() from calling sub

L<Math::BaseCnv>       to handle number-base conversion

L<Time::Fields>        to provide underlying object structure

=head1 SEE ALSO

L<Time::PT>

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

package Time::Frame;
use strict;
require      Time::Fields;
use base qw( Time::Fields );
use vars qw( $AUTOLOAD );
use Carp;
use Math::BaseCnv qw( :all );
our $VERSION     = '1.2.565EHOV'; # major . minor . PipTimeStamp
our $PTVR        = $VERSION; $PTVR =~ s/^\d+\.\d+\.//; # strip major && minor
# Please see `perldoc Time::PT` for an explanation of $PTVR.
use constant ONE_MINUTE          => '1 min';                  #         60;
use constant ONE_HOUR            => '1 hour';                 #      3_600;
use constant ONE_DAY             => '1 day';                  #     86_400;
use constant ONE_WEEK            => '1 week';                 #    604_800;
use constant ONE_REAL_MONTH      => '1 month';                #        '1M';
use constant ONE_REAL_YEAR       => '1 year';                 #        '1Y';
use constant ONE_MONTH           => '1 average month';        #  2_629_744;
                                                               # ONE_YEAR / 12
use constant ONE_FINANCIAL_MONTH => '1 financial month';      #  2_592_000;
                                                               # 30 days
use constant ONE_YEAR            => '1 average year';         # 31_556_930;
                                                               # 365.24225 days
use constant LEAP_YEAR           => '1 leap year';            # 31_622_400;
                                                               # 366 * ONE_DAY
use constant NON_LEAP_YEAR       => '1 nonleap year';         # 31_536_000;
                                                               # 365 * ONE_DAY

use overload 
  q("")  => \&_stringify,
  q(<=>) => \&_cmp_num,
  q(cmp) => \&_cmp_str,
  q(+)   => \&_add,
  q(-)   => \&_sub;

sub _stringify { # cat non-zero b64 fields down to frame or should just be used fields
  my @fdat = $_[0]->CYMDhmsfjz(); 
  my @attz = $_[0]->_attribute_names();
  my $tstr = ''; my $toob = 0; # flag designating field too big
  foreach(@fdat) {
    $toob = 1 if($_ > 63);
  }
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
  ($larg, $rarg) = ($rarg, Time::Frame->new($larg)) if($srvr); # mk both args Frame objects
  # maybe compare _total_jinx() or something
  return(0);
}

sub _cmp_str { 
  my $r = _cmp_num(@_); 
  ($r < 0) ? return('lt') : ($r) ? return('gt') : return('eq');
}

# Frame + Frame = Frame
# Frame + PT    = PT      (calculation is passed off to PT.pm)
# Frame + 'str' = PT      (passed off to PT.pm after PT->new('str') is made)
# Frame + anything else is not supported yet
sub _add {
  my ($larg, $rarg, $srvr) = @_; my $rslt;
  $larg = Time::PT->new($larg) if($srvr);
  $rarg = Time::PT->new($rarg) unless(ref($rarg) && $rarg->isa('Time::Frame'));
  if((ref($larg) && $larg->isa('Time::PT')) ||
     (ref($rarg) && $rarg->isa('Time::PT'))) {
    $rslt = $larg + $rarg; # pass off calculation to PT.pm
  } else {
    $rslt = Time::Frame->new();
    $rslt->{'_zone'}    = $larg->z + $rarg->z;
    $rslt->{'_jink'}    = $larg->j + $rarg->j;
    $rslt->{'_frame'}   = $larg->f + $rarg->f;
    $rslt->{'_second'}  = $larg->s + $rarg->s;
    $rslt->{'_minute'}  = $larg->i + $rarg->i;
    $rslt->{'_hour'}    = $larg->h + $rarg->h;
    $rslt->{'_day'}     = $larg->D + $rarg->D;
    $rslt->{'_month'}   = $larg->O + $rarg->O;
    $rslt->{'_year'}    = $larg->Y + $rarg->Y;
    $rslt->{'_century'} = $larg->C + $rarg->C;
  }
  return($rslt);
}

# Frame - Frame = Frame
# 'str' - Frame = PT     (passed off to PT.pm after PT->new('str') is made)
# Frame - anything else is not supported yet
sub _sub {
  my ($larg, $rarg, $srvr) = @_; my $rslt;
  $larg = Time::PT->new($larg) if($srvr);
  if(ref($larg) && $larg->isa('Time::PT')) {
    $rslt = $larg - $rarg; # pass off calculation to PT.pm
  } else {
    $rarg = Time::Frame->new($rarg) unless(ref($rarg) && $rarg->isa('Time::Frame'));
    $rslt = Time::Frame->new();
    $rslt->{'_zone'}    = $larg->z - $rarg->z;
    $rslt->{'_jink'}    = $larg->j - $rarg->j;
    $rslt->{'_frame'}   = $larg->f - $rarg->f;
    $rslt->{'_second'}  = $larg->s - $rarg->s;
    $rslt->{'_minute'}  = $larg->i - $rarg->i;
    $rslt->{'_hour'}    = $larg->h - $rarg->h;
    $rslt->{'_day'}     = $larg->D - $rarg->D;
    $rslt->{'_month'}   = $larg->O - $rarg->O;
    $rslt->{'_year'}    = $larg->Y - $rarg->Y;
    $rslt->{'_century'} = $larg->C - $rarg->C;
  }
  return($rslt);
}

sub _color_fields {
  my $self = shift;
  my $fstr = shift || ' ' x 10; $fstr =~ s/^0+// if(length($fstr) <= 7);
  my $ctyp = shift || 'Simp';
  my @clrz = (); my $coun = 0; my $rstr = '';
  if     ($ctyp =~ /^s/i) { # simp color codes
    @clrz = @{$self->_field_colors('simp')};
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun++]; }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(8 - length($fstr) + $coun++)]; }
    }
  } elsif($ctyp =~ /^h/i) { # HTML link && font color tag delimiters
    @clrz = @{$self->_field_colors('html')};
    $_    = '<font color="#' . $_ . '">' foreach(@clrz);
    $rstr = '<a href="http://Ax9.Org/pt?fr=' . $fstr . '">';
    if(length($fstr) > 7) {
      while(length($fstr) > $coun) { $rstr .= $clrz[$coun] . substr($fstr, $coun++, 1) . '</font>'; }
    } else {
      while(length($fstr) > $coun) { $rstr .= $clrz[(8 - length($fstr) + $coun)] . substr($fstr, $coun++, 1) . '</font>'; }
    }
    $rstr .= '</a>';
  } elsif($ctyp =~ /^4/i) { # 4nt prompt needs verbose color codes
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
      while(length($fstr) > $coun) { $rstr .= $clrz[(8 - length($fstr) + $coun)] . substr($fstr, $coun++, 1); }
    }
  }
  return($rstr);
}

# Time::Frame object constructor as class method or copy as object method.
# First param can be ref to copy.  Not including optional ref from 
#   copy, default is no params to create a new empty Frame object.
# If params are supplied, they must be a single key && a single value.
# The key must be one of the following 3 types of constructor 
#   initialization mechanisms:
#    -1) <packedB64InitStringImplies'str'>(eg. '0A1B2C3D4E')
#     0) 'str'  => <packedB64InitString>  (eg. 'str'  => '0A1B2C3D4E')
#     1) 'list' => <arrayRef>             (eg. 'list' => [0, 1, 2..9])
#     2) 'hash' => <hashRef>              (eg. 'hash' => {'jink' => 8})
sub new { 
  my ($nvkr, $ityp, $idat) = @_; 
  my $nobj = ref($nvkr);
  my $clas = $ityp;
  $clas = $nobj || $nvkr if(!defined($ityp) || $ityp !~ /::/);
  my $self = Time::Fields->new($clas);
  my @attz = $self->_attribute_names();
  foreach my $attr ( @attz ) { #$self->_attribute_names() ) { 
#    $self->{$attr} = $self->_default_value($attr); # init defaults
    $self->{$attr} = $nvkr->{$attr} if($nobj);     #  && copy if supposed to
  }
  if(defined($ityp) && $ityp !~ /::/) { # there were initialization params
    ($ityp, $idat) = ('str', $ityp) unless(defined($idat));
    if($ityp =~ /^verbose$/i) { # handle 'verbose' differently
      # verbose string param has decimal numbers followed by full field names
      while($idat =~ s/(\d+)\s*(\w+)//) {
        my($fval, $fnam) = ($1, lc($2));
        $fnam =~ s/s$//; # strip ending 's'
# should do some testing of fnam to turn into closest _attribute_name if ! one
        if($fnam =~ /^w/) { $self->{'_day'}        += (7 * $fval); }
        else              { $self->{('_' . $fnam)} += $fval; }
      }
    } elsif($ityp =~ /^s/i && length($idat) < 9) { # handle small 'str' differently
      # small str param grows left from frame field if shorter than 9 chars
      my $ilen = length($idat);
      for(my $i = (8-$ilen); $i < 8; $i++) {
        if($idat =~ s/^(.)//) {
          $self->{$attz[$i]} = b10($1); # break down str
        }
      }
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
          croak "!*EROR*! Time::Frame::new initialization type: $ityp did not match 'str', 'list', or 'hash'!\n";
        }
      }
    }
  }
  return($self);
}

sub total_frames { # return the integer number of frames in a Time::Frame obj
  my $self = shift; my $totl = 0;
  $totl += ($self->j() * (1.0 / 60.0));
  $totl +=  $self->f();
  $totl += ($self->s() * 60);
  $totl += ($self->m() * 60 * 60);
  $totl += ($self->h() * 60 * 60 * 60);
  $totl += ($self->D() * 60 * 60 * 60 * 24);
  $totl += ($self->M() * 60 * 60 * 60 * 24 * 30.4368537808642);
  $totl += ($self->Y() * 60 * 60 * 60 * 24 * 365.24225);
  $totl += ($self->C() * 60 * 60 * 60 * 24 * 365.24225 * 100);
  return($totl);
}

#sub AUTOLOAD { # methods (created as necessary)
#  no strict 'refs';
#  my ($self, $nwvl) = @_;
#
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
#    croak "No such method: $AUTOLOAD\n";
#  }
#}

sub DESTROY { } # do nothing but define in case && to calm warning in test.pl

127;
