package Tk::ChooseDate;

use vars qw($VERSION);

$VERSION = '0.4';

use Tk;
use Tk::Photo;
use Date::Calc(qw/Calendar Language Language_to_Text Decode_Language/);
use strict;
use Carp;

require Tk::Frame;

use base qw(Tk::Frame);
Construct Tk::Widget 'ChooseDate';

use vars qw($CALGIF);
$CALGIF = __PACKAGE__ . '::calendar';
my $def_gif = 0;

sub ClassInit {
  my ( $class, $mw ) = @_;

  unless ($def_gif) {

    my $data =
     "R0lGODlhEAAOANUAAAAAALi1r4F/emZmZklKSuTi3dfX15mZmSgoKP/678jFvqSjoBAQEIeIiFVV
      V3t7ez49Pevp5L+8t9HOxN3c16upp/799pWSjG9wcZmZmVlZWdzZ0N/f3/r36729vIWFhaSlpAgI
      CFFQTzMzM2ZmZrO0tXp3cO/s5v///4yJhdvZ1MrHv7Kwq0BAQYmHg3NzdP/88e3t662lpY2Njbu4
      sMPAueTj38zMzMLCwq2trQAAAAAAAAAAAAAAAAAAAAAAACH5BAUUACgALAAAAAAQAA4AAAaqQBSj
      hcB5UMikEiNqXDCaQ8NgUCIBlgVrVpp9XtEPhYJkWCgwiokgabAaGGjlwEg8KJXAobMRQBYvDQ0P
      dQ8FLxEzBSwHFzEKNS8VdWJiDyovMQc2EhYIhHYFlQUCFHcPMAgCDCh3L6YqHycfojAAAgAlFCcV
      J4YvEgMqDyi3CyAXLhMrEycLDjQLAim3SBwcCwuNKwQoww7VVlTSHwQzOAAfVlZGBAQAI0EAOw==";
    $data =~ s/\s+//g;
    $mw->Photo( $CALGIF, -data => $data, -format => 'gif' );
    $def_gif = 1;
  }

  $class->SUPER::ClassInit($mw);
  $mw->bind( $class, "<Button-1>" => 'popDown' );
  return $class;
}

sub Populate {
  my ( $w, $args ) = @_;

  $w->SUPER::Populate($args);
  $w->{_main} = $w->toplevel;
  my $lang = $w->{_originalLangNum} = Language();
  $w->{_configuredLang} = $w->{_originalLang} = Language_to_Text($lang);

  $w->{_langHash} = {
    'English'    => 'English',
    'French'     => 'Français',
    'German'     => 'Deutsch',
    'Spanish'    => 'Español',
    'Portuguese' => 'Português',
    'Dutch'      => 'Nederlands',
    'Italian'    => 'Italiano',
    'Norwegian'  => 'Norsk',
    'Swedish'    => 'Svenska',
    'Danish'     => 'Dansk',
    'Finnish'    => 'suomi',
    'Hungarian'  => 'Magyar',
    'Polish'     => 'Polski',
    'Romanian'   => 'Romaneste'
  };

  # label widget and button
  my $l = $w->Label( -bd => 2, -relief => 'sunken' );
  my $b = $w->Button(
    -command => sub { $w->popCalendar },
    -image   => $CALGIF,
  );
  my $tl = $w->{_toplevel} =
    $w->Toplevel( -background => '#444444', -bd => 2, -relief => 'ridge' );

  $tl->transient($w);
  $tl->overrideredirect(1);

  $b->pack( -side => "right", -padx => 0 );
  $l->pack( -side => "right", -fill => 'x', -expand => 1, -padx => 0 );

  $tl->withdraw;
  my $bd   = $w->{_bd}    = 2;
  my $grid = $w->{_ygrid} = 18;
  $w->{_xgrid} = 28;
  my $closeenough = $grid / 4;
  my $c = $w->{_canvas} = $tl->Canvas(
    -bd                 => $bd,
    -highlightthickness => 0,
    -background         => '#FFFFFF',
    -closeenough        => $closeenough
  )->pack( -expand => 1, -fill => 'both' );

  $w->Advertise( "label"    => $l );
  $w->Advertise( "button"   => $b );
  $w->Advertise( "canvas"   => $c );
  $w->Advertise( "toplevel" => $tl );

  $w->afterIdle( sub { $w->_initCalendar } );

  $w->_bindItems;
  $w->{_popped} = 0;

  $w->Delegates( DEFAULT => $l );

  $w->ConfigSpecs(
    -activelabel => [ qw/METHOD activeLabel ActiveLabel/, 0 ],
    -background => [ $l, 'background', 'Background', 'white' ],
    -command    => [ qw/CALLBACK command   Command/, undef ],
    -dateformat => [qw/PASSIVE dateFormat DateFormat 2/],
    -datefmt    => '-dateformat',
    -language   => [ qw/METHOD language Language/,   $w->{_origLanguageText} ],
    -orthodox   => [qw/PASSIVE orthodox Orthodox 1/],
    -daysofweekcolor =>
      [ qw/METHOD daysOfWeekColor DaysOfWeekColor/, '#444444' ],
    -datecolor        => [ qw/METHOD dateColor DateColor/,   '#444444' ],
    -yearcolor        => [ qw/METHOD yearColor YearColor/,   '#000000' ],
    -monthcolor       => [ qw/METHOD monthColor MonthColor/, '#000000' ],
    -arrowcolor       => [ qw/METHOD arrowColor ArrowColor/, '#777777' ],
    -arrowactivecolor =>
      [ qw/METHOD arrowActiveColor ArrowActiveColor/, '#000000' ],
    -linecolor      => [ qw/METHOD lineColor LineColor/,           '#CCCCFF' ],
    -highlightcolor => [ qw/METHOD highlightColor HighlightColor/, '#FFFFCC' ],
    -repeatdelay    => [qw/PASSIVE repeatDelay    RepeatDelay    400/],
    -repeatinterval => [qw/PASSIVE repeatInterval RepeatInterval 100/],
    -state          => [ ['CHILDREN'], 'SELF' ],
    -textvariable   => [ { -textvariable => $l }, undef, undef, \$w->{_date} ],
    -width  => [ $l, undef, undef, 10 ],
    DEFAULT => [$l]
  );
}

sub activelabel {

  # Treat a click on the label as a click on the button
  my ( $w, $active ) = @_;
  return $w->{Configure}{ -activelabel } unless defined $active;
  my $l = $w->Subwidget('label');
  my $b = $w->Subwidget('button');
  if ($active) {
    $l->bind( '<ButtonPress-1>', sub { $b->invoke } );
  }
  else {
    $l->bind( '<ButtonPress-1>', '' );
  }
}

sub arrowcolor {
  my ( $w, $color ) = @_;
  return $w->{_arrowcolor} unless defined $color;
  $w->{_arrowcolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'arrows', -fill => $color );
}

sub arrowactivecolor {
  my ( $w, $color ) = @_;
  return $w->{_arrowactivecolor} unless defined $color;
  $w->{_arrowactivecolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'arrows', -activefill => $color );
}

sub _bindItems {
  my ($w) = @_;

  my $c = $w->{_canvas};
  my $l = $w->Subwidget('label');
  $l->bind( '<Button-1>', sub { $w->popDown } );
  $c->bind(
    'date',
    '<ButtonPress-1>',
    sub {
      $w->{_day} = $c->itemcget( 'current', -text );
      $w->formatDate;
      $w->popCalendar;
    }
  );
  $c->bind( 'decYEAR',  '<ButtonPress-1>', sub { $w->decYear } );
  $c->bind( 'incYEAR',  '<ButtonPress-1>', sub { $w->incYear } );
  $c->bind( 'decMONTH', '<ButtonPress-1>', sub { $w->decMonth } );
  $c->bind( 'incMONTH', '<ButtonPress-1>', sub { $w->incMonth } );
  $c->Tk::bind(
    "<ButtonRelease-1>",
    sub {
      $w->{after}->cancel if ( defined $w->{after} );
      $w->{after} = undef;
    }
  );

}

sub datecolor {
  my ( $w, $color ) = @_;
  return $w->{_datecolor} unless defined $color;
  $w->{_datecolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'date', -fill => $color );
}

sub daysofweekcolor {
  my ( $w, $color ) = @_;
  return $w->{_daysofweekcolor} unless defined $color;
  $w->{_daysofweekcolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'dayofweek', -fill => $color );
}

sub decMonth {
  my $w    = shift;
  my $fire = shift || 'initial';

  $w->{_month}--;

  if ( $w->{_month} < 1 ) {
    $w->{_month} = 12;
    $w->{_year}--;
  }
  $w->plotCalendar;

  if ( $fire eq 'initial' ) {
    $w->{after} =
      $w->after( $w->cget( -repeatdelay ), [ \&decMonth, $w, 'again' ] );
  }
  else {
    $w->{after} =
      $w->after( $w->cget( -repeatinterval ), [ \&decMonth, $w, 'again' ] );
  }
}

sub decYear {
  my $w    = shift;
  my $fire = shift || 'initial';
  my $year = $w->{_year};

  if ( $fire eq 'initial' ) {
    $w->{_startx} = $w->{_currentx} = $w->pointerx;
    $w->{after} =
      $w->after( $w->cget( -repeatdelay ), [ \&decYear, $w, 'again' ] );
  }
  else {
    $w->{_currentx} = $w->pointerx;
    $w->{after}     =
      $w->after( $w->cget( -repeatinterval ), [ \&decYear, $w, 'again' ] );
  }

  if ( $w->{_currentx} - $w->{_startx} < -40 ) {
    $year -= 10;
  }
  else {
    $year--;
  }
  $year = 1 if ( $year < 0 );
  $w->{_year} = $year;
  $w->plotCalendar;

}

sub formatDate {
  my ($w)    = @_;
  my $format = $w->cget( -dateformat );
  my $varref = $w->cget( -textvariable );

  my ( $y, $m, $d ) = ( $w->{_year}, $w->{_month}, $w->{_day} );
  my $val;
  if ( $format == 1 ) {
    $val = sprintf( "%02d/%02d/%04d", $m, $d, $y );
    ${$varref} = $val;
  }
  elsif ( $format == 2 ) {
    $val = sprintf( "%04d/%02d/%02d", $y, $m, $d );
    ${$varref} = $val;
  }
  elsif ( $format == 3 ) {
    $val = sprintf( "%04d/%02d/%02d", $y, $m, $d );
    ${$varref} = $val;
  }
  $w->Callback( -command, $w, $val );
}

sub get {
  my ($w) = @_;
  if (wantarray) {

    # Return year, month, day
    my @a = $w->parseDate;
    return @a;
  }
  else {

    # Return scalar in the current dateformat (including slashes)
    my $varref = $w->cget( -textvariable );
    return ${$varref};
  }
}

sub highlight {
  my ($w)   = @_;
  my $c     = $w->{_canvas};
  my @tags  = $c->gettags('current');
  my ($tag) = grep /R\d+C\d+/, @tags;

  # Convert to rectangle tag..
  $tag =~ s/R/RR/g;
  $tag =~ s/C/CC/g;
  $c->itemconfigure( $tag, -outline => '#000000', -width => 2 );
  $w->{_lasttag} = $tag;
}

sub highlightcolor {
  my ( $w, $color ) = @_;
  return $w->{_highlightcolor} unless defined $color;
  $w->{_highlightcolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'highlight', -fill => $color );
}

sub incMonth {
  my $w    = shift;
  my $fire = shift || 'initial';

  $w->{_month}++;

  if ( $w->{_month} > 12 ) {
    $w->{_month} = 1;
    $w->{_year}++;
  }
  $w->plotCalendar;

  if ( $fire eq 'initial' ) {
    $w->{after} =
      $w->after( $w->cget( -repeatdelay ), [ \&incMonth, $w, 'again' ] );
  }
  else {
    $w->{after} =
      $w->after( $w->cget( -repeatinterval ), [ \&incMonth, $w, 'again' ] );
  }
}

sub incYear {
  my $w    = shift;
  my $fire = shift || 'initial';
  my $year = $w->{_year};

  if ( $fire eq 'initial' ) {
    $w->{_startx} = $w->{_currentx} = $w->pointerx;
    $w->{after} =
      $w->after( $w->cget( -repeatdelay ), [ \&incYear, $w, 'again' ] );
  }
  else {
    $w->{_currentx} = $w->pointerx;
    $w->{after}     =
      $w->after( $w->cget( -repeatinterval ), [ \&incYear, $w, 'again' ] );
  }

  if ( $w->{_currentx} - $w->{_startx} > 40 ) {
    $year += 10;
  }
  else {
    $year++;
  }

  $year = 9999 if ( $year > 9999 );
  $w->{_year} = $year;
  $w->plotCalendar;

}

sub _initCalendar {
  my ($w)              = @_;
  my $c                = $w->{_canvas};
  my $xgrid            = $w->{_xgrid};
  my $ygrid            = $w->{_ygrid};
  my $bd               = $w->{_bd};
  my $arrowcolor       = $w->{_arrowcolor};
  my $arrowactivecolor = $w->{_arrowactivecolor};
  my $linecolor        = $w->{_linecolor};
  my $yearcolor        = $w->{_yearcolor};
  my $monthcolor       = $w->{_monthcolor};
  my $dowcolor         = $w->{_daysofweekcolor};
  my $datecolor        = $w->{_datecolor};
  my $hcolor           = $w->{_highlightcolor};

  $c->configure(
    -width  => $xgrid * 7 + $bd * 2,
    -height => $ygrid * 9 + $bd * 2,
  );

  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
    localtime(time);
  $w->{_year}  = $year += 1900;
  $w->{_month} = ++$mon;
  $w->{_day}   = $mday;

  my %hash = $w->_parseCalendar( $year, $mon );

  $c->create(
    'rectangle',
    $bd, $bd, $c->cget('-width'), $ygrid * 2,
    -width => 0,
    -fill  => $hcolor,
    -tags  => ['highlight']
  );

  $c->create(
    'text',
    $xgrid / 2 + $bd, $bd + $ygrid / 2,
    -font       => [ 'Arial', 12, 'bold' ],
    -text       => "<<<",
    -anchor     => 'w',
    -activefill => $arrowactivecolor,
    -fill       => $arrowcolor,
    -tags => [ 'arrows', 'decYEAR' ]
  );

  $c->create(
    'text',
    $bd + $xgrid * 3.5, $bd + $ygrid / 2,
    -font   => [ 'Arial', 11, 'bold' ],
    -fill   => $yearcolor,
    -text   => $hash{year},
    -anchor => 'c',
    -tags => [ 'YM', 'YEAR' ]
  );
  $c->create(
    'text',
    $bd + $xgrid / 2 + $xgrid * 6, $bd + $ygrid / 2,
    -font       => [ 'Arial', 12, 'bold' ],
    -text       => ">>>",
    -anchor     => 'e',
    -activefill => $arrowactivecolor,
    -fill       => $arrowcolor,
    -tags => [ 'arrows', 'incYEAR' ]
  );
  $c->create(
    'text',
    $xgrid / 2 + $bd, $bd + $ygrid + $ygrid / 2,
    -font       => [ 'Arial', 12, 'bold' ],
    -text       => "<<<",
    -anchor     => 'w',
    -activefill => $arrowactivecolor,
    -fill       => $arrowcolor,
    -tags => [ 'arrows', 'decMONTH' ]
  );
  $c->create(
    'text',
    $bd + $xgrid * 3.5, $bd + $ygrid + $ygrid / 2,
    -font   => [ 'Arial', 10, 'bold' ],
    -fill   => $monthcolor,
    -text   => $hash{month},
    -anchor => 'c',
    -tags => [ 'YM', 'MONTH' ]
  );
  $c->create(
    'text',
    $bd + $xgrid / 2 + $xgrid * 6, $bd + $ygrid + $ygrid / 2,
    -font       => [ 'Arial', 12, 'bold' ],
    -text       => ">>>",
    -anchor     => 'e',
    -activefill => $arrowactivecolor,
    -fill       => $arrowcolor,
    -tags => [ 'arrows', 'incMONTH' ]
  );

  foreach my $num ( 1 .. 7 ) {
    $c->create(
      'text', $bd + $xgrid * $num, $bd + $ygrid * 2 + $ygrid / 2,
      -font   => [ 'Courier', 9, 'normal' ],
      -text   => $hash{"dayofweek$num"},
      -anchor => 'e',
      -fill   => $dowcolor,
      -tags => [ "dayofweek", "day$num" ]
    );

  }
  foreach my $col ( 1 .. 7 ) {
    foreach my $row ( 3 .. 9 ) {
      $c->create(
        'text', $bd + ($col) * $xgrid,
        $bd + ( $row * $ygrid ) + $ygrid / 2,
        -font   => [ 'Arial', 12, 'normal' ],
        -text   => undef,
        -anchor => 'e',
        -fill   => $datecolor,
        -tags => [ 'date', "R${row}C${col}" ]
      );

    }
  }
  foreach my $key ( keys %hash ) {
    next unless $hash{$key} =~ /^R(\d+)C(\d+)$/;
    my $row = $1;
    my $col = $2;
    $c->itemconfigure( "R${row}C${col}", -text => $key );
  }

  foreach my $col ( 0 .. 6 ) {
    my $colp = $col + 1;
    foreach my $row ( 3 .. 8 ) {
      $c->create(
        'rectangle', $bd + 1 + $xgrid * $col, $bd + $ygrid * $row,
        $bd + 1 + $xgrid * ( $col + 1 ), $bd + $ygrid * ( $row + 1 ),
        -fill    => 'white',
        -outline => $linecolor,
        -tags    => [ 'rect', "RR${row}CC${colp}" ],
      );
    }
  }

  $c->lower('rect');
  $c->bind( 'date', '<Enter>', sub { $w->highlight } );
  $c->bind( 'date', '<Leave>', sub { $w->revert } );

  $c->Tk::bind(
    '<ButtonPress>',
    sub {
      my @tags = $c->gettags('current');
      $w->popDown unless (@tags);
      $w->popDown unless ( grep /inc|dec|date/, @tags );
    }
  );
}

sub language {
  my ( $w, $language ) = @_;
  return $w->{_configuredLang} unless defined $language;
  $language = ucfirst($language);

  my @languages = keys %{ $w->{_langHash} };
  unless ( grep /^$language$/, @languages ) {
    carp "$language not a valid language";
    return;
  }
  $w->{_configuredLang} = $w->{_langHash}->{$language};
  return $w->{_configuredLang};
}

sub linecolor {
  my ( $w, $color ) = @_;
  return $w->{_linecolor} unless defined $color;
  $w->{_linecolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'rect', -outline => $color );
}

sub monthcolor {
  my ( $w, $color ) = @_;
  return $w->{_monthcolor} unless defined $color;
  $w->{_monthcolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'MONTH', -fill => $color );
}

sub _parseCalendar {

  # This returns a hash containing the parsed calendar.
  # Particularly - this is only to be able to plot items properly on a Canvas.
  # This is why it is an internal method.

  my ( $w, $y, $m ) = @_;
  return unless defined $m;

  if ( $y <= 0 ) {
    carp "Year must be greater than zero";
    return;
  }
  unless ( $y =~ /^\d{1,4}?$/ ) {
    carp "Year must be 1 to 4 digits";
    return;
  }
  unless ( $m > 0 and $m <= 12 and $m =~ /^\d{1,2}?$/ ) {
    carp "Month must be an integer between 1 and 12";
    return;
  }

  $m = sprintf( "%2d", $m );
  my %parsedCal;
  my $orthodox = $w->cget('-orthodox');

  my $lang = $w->{_configuredLang};
  my $cal;

  # Heed this warning in Date::Calc !
  # Note that in the current implementation of this package,
  # the selected language is a global setting valid for ALL
  # functions that use the names of months, days of week or
  # languages internally, valid for ALL PROCESSES using the
  # same copy of the 'Date::Calc' shared library in memory!

  if ( $lang eq $w->{_originalLang} ) {
    $cal = Date::Calc::Calendar( $y, $m, $orthodox );
  }
  else {

    # Change the language temporarily - then change it
    # back immediately
    Language( Decode_Language($lang) );
    $cal = Date::Calc::Calendar( $y, $m, $orthodox );
    Language( $w->{_originalLangNum} );
  }

  $cal =~ s/^\s*\n+//g;
  $cal =~ s/\s*\n+$//g;

  my @arr = split( "\n", $cal );
  my $monyearline = shift(@arr);
  $monyearline =~ s/^\s*//g;
  $monyearline =~ s/\s*$//g;
  my ( $mm, $yy ) = split( /\s+/, $monyearline );
  $parsedCal{month} = $mm;
  $parsedCal{year}  = $yy;

  my $dd = shift(@arr);
  $dd =~ s/^\s*//g;
  $dd =~ s/\s*$//g;
  my @daysofweek = split( /\s+/, $dd );

  my $i = 1;
  foreach (@daysofweek) {
    $parsedCal{"dayofweek$i"} = $_;
    $i++;
  }

  my $row = 3;    #Because the first three rows are already taken
  foreach my $line (@arr) {

    while ( $line =~ /\b(\d+)\b/gi ) {
      my $val = $1;
      my $col = int( pos($line) / 4 ) + 1;
      $parsedCal{"$val"} = "R${row}C${col}";
    }
    $row++;
  }

  return (%parsedCal);
}

sub parseDate {
  my ($w) = @_;
  my $varref = $w->cget( -textvariable );

  my ( $m, $d, $y );
  my $format = $w->cget( -dateformat );

  if ( $format == 1 ) {
    ( $m, $d, $y ) = split( "/", $$varref );
  }
  elsif ( $format == 2 ) {
    ( $y, $m, $d ) = split( "/", $$varref );
  }
  elsif ( $format == 3 ) {
    ( $d, $m, $y ) = split( "/", $$varref );
  }
  if ( defined $y and defined $m and defined $d ) {
    return ( $y, $m, $d );
  }
}

sub plotCalendar {
  my ($w)    = @_;
  my $c      = $w->{_canvas};
  my $grid   = $w->{_grid};
  my $mon    = $w->{_month};
  my $year   = $w->{_year};
  my $day    = $w->{_day};
  my $dcolor = $w->{_datecolor};
  my $hcolor = $w->{_highlightcolor};

  my %hash = $w->_parseCalendar( $year, $mon );
  $c->itemconfigure( 'YEAR',  -text => $hash{year} );
  $c->itemconfigure( 'MONTH', -text => $hash{month} );
  $c->itemconfigure(
    'date',
    -text => undef,
    -fill => $dcolor,
    -font => [ 'Arial', 12, 'normal' ]
  );
  $c->itemconfigure( 'rect', -fill => '#FFFFFF' );

  foreach my $key ( keys %hash ) {
    if ( $key =~ /dayofweek(\d+)/ ) {
      my $tag = 'dayofweek' . $1;
      $c->itemconfigure( $tag, -text => $hash{$tag} );
    }
    next unless $hash{$key} =~ /^R(\d+)C(\d+)$/;
    my $row = $1;
    my $col = $2;
    $c->itemconfigure( "R${row}C${col}", -text => $key );
    if ( $key == $w->{_day} ) {
      $c->itemconfigure(
        "R${row}C${col}",
        -fill => $dcolor,
        -font => [ 'Arial', 12, 'bold' ]
      );
      $c->itemconfigure( "RR${row}CC${col}", -fill => $hcolor, );
    }
  }
}

sub popCalendar {
  my ($w) = @_;
  my $popped = $w->{_popped};
  if ( not $popped ) {
    $w->popUp;
  }
  else {
    $w->popDown;
  }
}

sub popDown {
  my ($w) = @_;
  if ( $w->{_popped} ) {
    $w->{_popped} = 0;
    $w->{_toplevel}->withdraw;
    $w->grabRelease;

    if ( $Tk::oldgrab and $Tk::oldgrabstatus ) {
      $Tk::oldgrab->grab       if $Tk::oldgrabstatus eq 'local';
      $Tk::oldgrab->grabGlobal if $Tk::oldgrabstatus eq 'global';
    }
  }
}

sub popUp {
  my ($w) = @_;
  unless ( $w->{_popped} ) {
    $w->plotCalendar;
    $w->{_toplevel}->Popup(
      -popover    => $w->Subwidget('label'),
      -popanchor  => 'nw',
      -overanchor => 'sw'
    );
    $w->{_popped} = 1;

    if ( $w->grabCurrent ) {
      $Tk::oldgrab       = $w->grabCurrent;
      $Tk::oldgrabstatus = $Tk::oldgrab->grabStatus;
    }

    $w->grabGlobal;

  }
}

sub revert {
  my ($w) = @_;
  my $c = $w->{_canvas};
  $c->itemconfigure(
    $w->{_lasttag},
    -outline => $w->{_linecolor},
    -width   => 1
  );
}

sub set {
  my ( $w, %val ) = @_;
  $w->{_year}  = sprintf( "%4d", $val{y} ) if ( exists $val{y} );
  $w->{_month} = sprintf( "%2d", $val{m} ) if ( exists $val{m} );
  $w->{_day}   = sprintf( "%2d", $val{d} ) if ( exists $val{d} );
  $w->formatDate;
}

sub yearcolor {
  my ( $w, $color ) = @_;
  return $w->{_yearcolor} unless defined $color;
  $w->{_yearcolor} = $color;
  my $c = $w->{_canvas};
  $c->itemconfigure( 'YEAR', -fill => $color );
}

1;

=head1 NAME

Tk::ChooseDate - Popup Calendar with support for dates prior to 1970

=head1 SYNOPSIS

I<$chooseDate> = I<$parent>-E<gt>B<ChooseDate>(?I<options>?);

=head1 EXAMPLE

    use Tk;
    use Tk::ChooseDate;

    my $mw=tkinit;
    $mw->ChooseDate(
        -textvariable=>\$date,
        -command=>sub{print "$date\n"},
    )->pack(-fill=>'x', -expand=>1);
    MainLoop;

=head1 SUPER-CLASS

C<ChooseDate> is derived from the C<Frame> class.
This megawidget is comprised of an C<Label> and C<Button>
allowing a popup C<Toplevel> with an embedded C<Canvas>.

=head1 DESCRIPTION

ChooseDate is yet-another-date-choosing widget via a popup calendar.
It was created because L<Tk::DateEntry> and L<Tk::DatePick> do not
allow support for dates prior to 1970. Besides this major item, I
personally think that this is a nicer-looking widget with similar
functionality of the others - but much more user friendly as dates
can be chosen quickly and easily.

Although the widget looks much like an Entry - it is not. It is a
sunken label. This means that the date is not directly editable by
the user; yes - this is by design. That said however, the programmer
can get and set the date using the mehods described herein.

=head1 WIDGET-SPECIFIC OPTIONS

All options not specified below are delegated to the label widget.

=over 4

=item Name:	B<activeLabel>

=item Class:	B<ActiveLabel>

=item Switch:	B<-activelabel>

Specifies if the label offers the same binding functionality as
the calendar button. This is a boolean value. Setting this to 1
means that clicking on the label will toggle the popup
window just as if the user clicked on the button. Setting this
to 0 will disable this functionality and force the user to click
on the button to get the popup.

=item Name:	B<arrowColor>

=item Class:	B<ArrowColor>

=item Switch:	B<-arrowcolor>

Specifies the color of the text for the increment/decrement arrows.

=item Name:	B<arrowActiveColor>

=item Class:	B<ArrowActiveColor>

=item Switch:	B<-arrowactivecolor>

Specifies the color of the text for the increment/decrement
arrows when mouse hovers over them.

=item Name:	B<command>

=item Class:	B<Command>

=item Switch:	B<-command>

Specifies a function to call when a selection is made in the popped
up calendar. It is passed the widget and date string. This function
is called after the variable has been assigned the value.

=item Name:	B<dateColor>

=item Class:	B<DateColor>

=item Switch:	B<-datecolor>

Specifies the color of the text for the date numbers within the calendar.

=item Name:	B<dateFormat>

=item Class:	B<DateFormat>

=item Switch:	B<-dateformat/-datefmt>

Specifies the format of the date. Must be an integer
between 1 and 3. Where:

=over 4

=item -dateformat => 1

MM/DD/YYYY

=item -dateformat => 2

YYYY/MM/DD (default)

=item -dateformat => 3

DD/MM/YYYY

=back

=item Name:	B<dateOfWeekColor>

=item Class:	B<DaysOfWeekColor>

=item Switch:	B<-daysofweekcolor>

Specifies the color of the text for the days of the week headings.

=item Name:	B<highlightColor>

=item Class:	B<HighlightColor>

=item Switch:	B<-highlightcolor>

Specifies the color to highlight the chosen date.

=item Name:	B<language>

=item Class:	B<Language>

=item Switch:	B<-language>

Specifies the language of the calendar. Please see L<Date::Calc>
for more documentation on how languages are handled.

=over 4

=item You must specify one of the following exactly:

=over 4

=item English

=item French

=item German

=item Spanish

=item Portuguese

=item Dutch

=item Italian

=item Norwegian

=item Swedish

=item Danish

=item Finnish

=item Hungarian

=item Polish

=item Romanian

=back

=back

=item Name:	B<lineColor>

=item Class:	B<LineColor>

=item Switch:	B<-linecolor>

Specifies the color of the lines on the calendar. If set to undef
then no lines will show.

=item Name:	B<monthColor>

=item Class:	B<MonthColor>

=item Switch:	B<-monthcolor>

Specifies the color of text for the month name.

=item Name:	B<orthodox>

=item Class:	B<Orthodox>

=item Switch:	B<-orthodox>

Specifies the order of the days of the week in the calendar
header. This is a boolean value with a default of 1.

=over 4

=item -orthodox => 0

Mon Tue Wed Thu Fri Sat Sun

=item -orthodox => 1

Sun Mon Tue Wed Thu Fri Sat

=back

=item Name:	B<repeatDelay>

=item Class:	B<RepeatDelay>

=item Switch:	B<-repeatdelay>

Specifies the amount of time (in ms) before the firebutton
callback is first invoked after the Button-1 is pressed over
the increment/decrement arrows. 

=item Name:	B<repeatInterval>

=item Class:	B<RepeatInterval>

=item Switch:	B<-repeatinterval>

Specifies the amount of time between updates to the date
changes if Button-1 is pressed and held over the increment/
decrement arrows.

=item Switch:	B<-state>

Specifies the state of the widget. Choose between I<normal> or I<disabled>.

=item Switch:   B<-textvariable>

Specifies a reference to a scalar variable. The value of the variable
is a text string date to be displayed inside the widget. If the variable
value changes then the widget will automatically update itself
to reflect the new value. 

=item Name:	B<yearColor>

=item Class:	B<YearColor>

=item Switch:	B<-yearcolor>

Specifies the color of text for the year name.

=back

=head1 WIDGET METHODS

If you wish to use the L<Tk::Label> or L<Tk::Button> methods then you
will have to use the Subwidget method to get the advertised objects.
Otherwise I<currently> only two public methods exist.

=over 4

=item I<$choosedate>-E<gt>B<get>

Gets the chosen date. The returned value depends context of the request.
If being stored to a I<scalar> then the entire string will be returned
as set by the B<-dateformat> option. If being stored to an I<array> then
the year, month and day are returned in an array format in that
particular order - (Y,M,D)

=item I<$choosedate>-E<gt>B<set(datehash)>

Sets any or all of the portions of the date. The hash keys must be be:

I<y>,I<m>,I<d>

=over 4

=item Example

I<$choosedate>-B<E<gt>set>( B<y>=E<gt>2005, B<m>=E<gt>5, B<d>=E<gt>5)
will set the date to May 5, 2005.

=item Alternatively

You can just change one of the date parameters
I<$choosedate>-B<E<gt>set>( B<m>=E<gt>11) change the month to November

=back

=back

=head1 MANIPULATING THE DATES

In order to allow quick access to choosing the date, arrows have been
provided to increment or decrement the year and month. Firebutton-like
functionality exists with these arrows. So if you hold down the mouse
button, the dates will continuously increment or decrement. Of course
you can feel free to just click numerous times for the same, albeit slower
result.

When using the firebutton-like feature on the YEAR, the program will track
the X position of your mouse. If your mouse remains over the arrows then
the years will increment or decrement by 1. If however your mouse moves
at least 40 pixels in the direction of the arrow then the years will
increment or decrement by 10. This feature cannot be shut-off in this
version.

=head1 ADVERTISED WIDGETS

The following widgets are advertised:

=over

=item label

The label widget (which really looks like an entry).

=item button

The button widget to the right of the label.

=item canvas

The canvas widget which houses the actual calendar.

=item toplevel

The toplevel popup widget which houses the canvas.

=back

=head1 KNOWN BUGS

=over 4

=item Fonts

Fonts cannot be adjusted.

=item Language

Ths module has now been tested using the varying language options of
Date::Calc. All disclaimers for that module apply here as well. i.e.
the following quote may be relevant:

E<quot>I<Note that in the current implementation of this package, the selected
language is a global setting valid for ALL functions that use the
names of months, days of week or languages internally, valid for
B<ALL PROCESSES> using the same copy of the L<Date::Calc> shared
library in memory!>E<quot>

To avoid this potential pitfall, Tk::ChooseDate stores the current
language at startup and resets it on-the-fly. Before the call to
Calendar is made, the language is changed to the one specified in the
user options. After the call returns the language is immediately set
back to the original. This likely has some speed implications on
slower computers - but I do not note much of a difference and I
was not intending on benchmarking it.

=back

=head1 PREREQUISITES

=over 4

=item Tk

=item Date::Calc

=back

=head1 AUTHOR

B<Jack Dunnigan> dunniganjE<lt>atE<gt>cpanE<lt>dotE<gt>org

Copyright (c) 2005 Jack Dunnigan. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Portions of this code were based on Tk::DateEntry and Tk::DatePick
so my thanks go out to the authors of those modules.

Thanks also to Ala Qumsieh and Rob Seegal for providing feedback.

=cut

