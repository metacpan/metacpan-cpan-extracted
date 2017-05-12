$Tk::Gauge::VERSION = '0.3';

package Tk::Gauge;

use 5.8.2;
use Tk 804.027;
use Tk::widgets qw/ Trace /;
use base qw/ Tk::Derived Tk::Canvas /;
use strict;

Construct Tk::Widget 'Gauge';

# Class global definitions.

my $id = 0;			# needle ID

my ( %band_defaults )   = (
    -arccolor   =>        'white',
    -minimum    =>              0,
    -maximum    =>            100,
    -piecolor   =>        'white',
    -tag        =>             '',
);				# default band options

my $d2r = 0.0174532;		# degrees to radians

my ( %needle_defaults ) = (
    -arrowshape =>  [ 12, 23, 6 ],
    -color      =>        'black',
    -command    =>          undef,
    -format     =>           '%d',
    -id         =>              0,
    -radius     =>             96,
    -showvalue  =>              0,
    -tag        =>             '',
    -title      =>             '',
    -titlecolor =>        'black',
    -titlefont  => 'Helvetica-12',
    -titleplace =>        'south',
    -variable   =>       \my $var,
    -width      =>              5,
);				# default needle options

sub Populate {

    my ($self, $args) = @_;

    $self->SUPER::Populate($args);
    
    $self->ConfigSpecs(
        -background           => [ 'SELF',    'background'          , 'Background'          ,              'white' ],
        -bands                => [ 'PASSIVE', 'bands'               , 'Bands'               ,                undef ],
        -bandplace            => [ 'PASSIVE', 'bandPlace'           , 'BandPlace'           ,         'underticks' ],
        -bandstyle            => [ 'PASSIVE', 'bandStyle'           , 'BandStyle'           ,               'band' ],
        -bandwidth            => [ 'PASSIVE', 'bandWidth'           , 'BandWidth'           ,                   10 ],
        -caption              => [ 'PASSIVE', 'caption'             , 'Caption'             ,                   '' ],
        -captioncolor         => [ 'PASSIVE', 'captionColor'        , 'CaptionColor'        ,              'black' ],
        -extent               => [ 'PASSIVE', 'extent'              , 'Extent'              ,                 -270 ],
        -fill                 => [ 'PASSIVE', 'fill'                , 'Fill'                ,              'white' ],
        -finetickcolor        => [ 'PASSIVE', 'fineTickColor'       , 'FineTickColor'       ,              'black' ],
        -finetickinterval     => [ 'PASSIVE', 'fineTickInterval'    , 'FineTickInterval'    ,                undef ],
        -fineticklength       => [ 'PASSIVE', 'fineTickLength'      , 'FineTickLength'      ,                    2 ],
        -finetickthickness    => [ 'PASSIVE', 'fineTickThickness'   , 'FineTickThickness'   ,                    1 ],
        -from                 => [ 'PASSIVE', 'from'                , 'From'                ,                    0 ],
        -hubcolor             => [ 'PASSIVE', 'hubColor'            , 'HubColor'            ,      '#ef5bef5bef5b' ],
        -huboutline           => [ 'PASSIVE', 'hubOutline'          , 'HubOutline'          ,      '#ef5bef5bef5b' ],
        -hubplace             => [ 'PASSIVE', 'hubPlace'            , 'Hubplace'            ,         'overneedle' ],
        -hubradius            => [ 'PASSIVE', 'hubRadius'           , 'HubRadius'           ,                    5 ],
        -majortickcolor       => [ 'PASSIVE', 'majorTickColor'      , 'MajorTickColor'      ,              'black' ],
        -majortickinterval    => [ 'PASSIVE', 'majorTickInterval'   , 'MajorTickInterval'   ,                   10 ],
        -majorticklabelcolor  => [ 'PASSIVE', 'majorTickLabelColor' , 'MajorTickLabelColor' ,              'black' ],
        -majorticklabelfont   => [ 'PASSIVE', 'majorTickLabelFont'  , 'MajorTickLabelFont'  ,       'Helvetica-12' ],
        -majorticklabelformat => [ 'PASSIVE', 'majorTickLabelFormat', 'MajorTickLabelFormat',                 '%d' ],
        -majorticklabelpad    => [ 'PASSIVE', 'majorTickLabelPad'   , 'MajorTickLabelPad'   ,                   10 ],
        -majorticklabelplace  => [ 'PASSIVE', 'majorTickLabelPlace' , 'MajorTickLabelPlace' ,             'inside' ],
        -majorticklabelscale  => [ 'PASSIVE', 'majorTickLabelScale' , 'MajorTickLabelScale' ,                    1 ],
        -majorticklabelskip   => [ 'PASSIVE', 'majorTickLabelSkip'  , 'MajorTickLabelSkip'  ,                undef ],
        -majorticklength      => [ 'PASSIVE', 'majorTickLength'     , 'MajorTickLength'     ,                   10 ],
        -majortickthickness   => [ 'PASSIVE', 'majorTickThickness'  , 'MajorTickThickness'  ,                    1 ],
        -margin               => [ 'PASSIVE', 'margin'              , 'Margin'              ,                   10 ],
        -minortickcolor       => [ 'PASSIVE', 'minorTickColor'      , 'MinorTickColor'      ,              'black' ],
        -minortickinterval    => [ 'PASSIVE', 'minorTickInterval'   , 'MinorTickInterval'   ,                undef ],
        -minorticklength      => [ 'PASSIVE', 'minorTickLength'     , 'MinorTickLength'     ,                    5 ],
        -minortickthickness   => [ 'PASSIVE', 'minorTickThickness'  , 'MinorTickThickness'  ,                    1 ],
        -needles              => [ 'PASSIVE', 'needles'             , 'Needles'             , [{%needle_defaults}] ],
        -needlepad            => [ 'PASSIVE', 'needlePad'           , 'NeedlePad'           ,                    0 ],
        -outline              => [ 'PASSIVE', 'outline'             , 'Outline'             ,              'black' ],
        -outlinewidth         => [ 'PASSIVE', 'outlineWidth'        , 'OutlineWidth'        ,                    2 ],
        -start                => [ 'PASSIVE', 'start'               , 'Start'               ,                  225 ],
        -style                => [ 'PASSIVE', 'style'               , 'Style'               ,              'chord' ],
        -to                   => [ 'PASSIVE', 'to'                  , 'To'                  ,                  100 ],
    );

    $self->OnDestroy( [ \&delete_traces, $self ] );

} # end Populate

sub ConfigChanged {

    my( $self, $args ) = @_;

    $self->delete( 'gauge', 'hub', 'ticks', 'caption' );

    my $radius = $self->maxradius;
    $self->{ -maxradius } = $radius;

    my( $center_x, $center_y ) = $self->centerpoint;
    $self->configure( -width => 2 * $center_x, -height => 2 * $center_y - $self->cget( -margin ) / 2 );

    # Create the main gauge.

    $self->createArc(
        ( $center_x - $radius, $center_y - $radius ),
        ( $center_x + $radius, $center_y + $radius ),
        -extent  => $self->cget( -extent ),
        -fill    => $self->cget( -fill ),
        -outline => $self->cget( -outline ),
        -start   => $self->cget( -start ),
        -style   => $self->cget( -style ),
        -tags    => 'gauge',
        -width   => $self->cget( -outlinewidth ),
    );

    # Creat the hub.

    my $hub_place = $self->cget( -hubplace );
    die "Invalid -hubplace '$hub_place': must be 'overneedle', 'underneedle or 'hide'." unless $hub_place =~
	/^overneedle|underneedle|hide$/;
    if( $hub_place ne 'hide' ) {
	$self->createOval(
            ( $center_x - $self->cget( -hubradius ), $center_y - $self->cget( -hubradius ) ),
            ( $center_x + $self->cget( -hubradius ), $center_y + $self->cget( -hubradius ) ),
            -fill    => $self->cget( -hubcolor ),
            -outline => $self->cget( -huboutline ),
            -tags    => 'hub',
        );
    }

    # Draw bands.
    
    my $from  = $self->cget( -from );
    my $to    = $self->cget( -to );
    my $bands = $self->cget( -bands );
    if( $bands ) {
	foreach my $band ( @$bands ) {
	    my(@margs, %ahsh, $args, @args);        # fill in default band options not supplied by the user
	    @margs = grep ! defined $band->{$_}, keys %band_defaults;
	    %ahsh = %$band;                         # argument hash
	    @ahsh{@margs} = @band_defaults{@margs}; # fill in missing values
	    my( $arccolor, $min, $max, $piecolor, $tag ) =
		@ahsh{ qw/-arccolor -minimum -maximum -piecolor -tag / };
	    my $gext    = $self->cget( -extent ); # gauge -extent
	    my $gstart  = $self->cget( -start ); # gauge -start
	    my $ext     = - ( $max - $min  ) * ( $gext / ( $to - $from ) );
	    my $start   = $gstart + $gext * ( $max - $from ) / ( $to - $from );
            my $radius4 = $radius - ( $self->cget( -bandwidth ) / 2 );
	    my $style   = $self->cget( -bandstyle );
	    die "Invalid -bandstyle '$style': must be 'band' or 'pieslice'." unless $style =~ /^band|pieslice$/;
	    $style = 'arc' if $style eq 'band';
            $self->createArc(
                ( $center_x - $radius4, $center_y - $radius4 ),
                ( $center_x + $radius4, $center_y + $radius4 ),
                -extent  => $ext,
                -fill    => $piecolor,
                -outline => $arccolor,
                -start   => $start,
                -style   => $style,
                -tags    => [ 'bands', $tag ],
                -width   => $self->cget( -bandwidth ),
            );
	} # forend all bands
    } # ifend bands

    # Draw tick marks.

    my $start  = $self->cget( -start );
    my $extent = $self->cget( -extent );
    my $tincr  =  ( $extent / ( $to - $from ) );
    my $angle  = $start - $tincr;

    for( my $gvalue = $from; $gvalue <= $to; $gvalue ++ ) {

	$angle += $tincr;
	my $theta = -$angle * $d2r;

	my( $x, $y ) = ( cos( $theta ) * $radius, sin( $theta ) * $radius );
	$x += $center_x;
	$y += $center_y;

	my $major = 0;
	   $major  = ! ( $gvalue % $self->cget( -majortickinterval ) );
	my $minor  = 0;
	   $minor  = ! ( $gvalue % $self->cget( -minortickinterval ) ) if defined $self->cget( -minortickinterval );
	my $fine   = 0;
	   $fine   = ! ( $gvalue % $self->cget( -finetickinterval  ) ) if defined $self->cget( -finetickinterval );

	next unless $major or $minor or $fine;

	my $format = $self->cget( -majorticklabelformat );
	my $scale  = $self->cget( -majorticklabelscale );

	my $place = $self->cget( -majorticklabelplace );
	die "Invalid -majorticklabelplace '$place': must be 'inside', 'outside' or 'hide'." unless $place =~
	    /^inside|outside|hide$/;
	my $skip = 0;
	my $skipref = $self->cget( -majorticklabelskip );
	if( defined $skipref ) {
	    die "Invalid -majorticklabelskip '$skipref': must be an array reference." unless ref $skipref eq 'ARRAY';
	    foreach my $skipval ( @$skipref ) {
		next unless $skipval == $gvalue;
		$skip = 1;
		last;
	    }
	}

	if( $major and $place ne 'hide' and not $skip ) {
	    my $radius2;
	    my $fw = $self->fontMeasure( $self->cget( '-majorticklabelfont' ), '0' );
	    if( $place eq 'outside' ) {
		$radius2 = $radius + ( length( $to * $scale ) / 2 * $fw ) + $self->cget( -majorticklabelpad ) ;
	    } elsif( $place eq 'inside' ) {
		$radius2 = $radius - ( length( $to * $scale ) / 2 * $fw ) - $self->cget( -majorticklabelpad ) - $self->cget( -majorticklength );
	    }
	    my( $x2, $y2 ) = ( cos( $theta ) * $radius2, sin( $theta ) * $radius2 );
	    $x2 += $center_x;
	    $y2 += $center_y;
	    my $tangle = sprintf( $format, $gvalue * $scale );
	    $self->createText( $x2, $y2, -text => $tangle, -fill => $self->cget( -majorticklabelcolor ), -tags => 'ticklabel' );
	}

	if( $major or $minor or $fine ) {
	    my $radius3;	# order is important
	    my $color;
	    my $tag;
	    my $width;
	    if( $fine ) {
		$radius3  = $radius - $self->cget( -fineticklength );
		$color    = $self->cget( -finetickcolor );
		$tag      = 'finetick';
		$width    = $self->cget( -finetickthickness );
	    } 
	    if( $minor ) {
		$radius3  = $radius - $self->cget( -minorticklength );
		$color    = $self->cget( -minortickcolor );
		$tag      = 'minortick';
		$width    = $self->cget( -minortickthickness );
	    } 
	    if( $major ) {
		$radius3  = $radius - $self->cget( -majorticklength );
		$color    = $self->cget( -majortickcolor );
		$tag      = 'majortick';
		$width    = $self->cget( -majortickthickness );
	    }
	    my( $x3, $y3 ) = ( cos( $theta ) * $radius3, sin( $theta ) * $radius3 );
	    $x3 += $center_x;
	    $y3 += $center_y;
	    $self->createLine( $x, $y, $x3, $y3,
                -fill  => $color,
                -tags  => $tag,
                -width => $width,
            );
	}
	
    } # forend all ticks

    # Add the caption.

    $self->createText( $center_x, $self->cget( -margin ) + 2 * $radius,
        -fill => $self->cget( -captioncolor ),
        -text => $self->cget( -caption ),
        -tags => 'caption',
    );

    # Trace the variables and setup callbacks associated with all the needles.

    my $needles = $self->cget( -needles );
    if( $needles ) {
	$id = 'needle000000';
	$self->delete_traces;
	foreach my $needle ( @$needles ) {
	    $needle->{ -id } = $id++;
	    $self->delete( $needle->{ -id } );
	    $self->traceVariable ( $needle->{ -variable } , 'w', [ \&tracew => $self, $needle ] );
	    if( defined $needle->{ -command } ) {
		$needle->{ -command_callback } = Tk::Callback->new( $needle->{ -command } );
	    }
	}
    } 

} # end ConfigChanged

sub delete_traces {

    my( $self ) = @_;

    my $needles = $self->cget( -needles );
    return unless defined $needles;
    foreach my $needle ( @$needles  ) {
	$self->traceVdelete ( $needle->{ -variable } ) if defined $needle->{ -variable };
    }

} # end delete_traces

sub setvalue {			# draw needle(s)

    my( $self, $value, $needle ) = @_;

    # Fill in default needle options not supplied by the user.

    my(@margs, %ahsh, $args, @args);
    @margs = grep ! defined $needle->{$_}, keys %needle_defaults;
    %ahsh = %$needle;                         # argument hash
    @ahsh{@margs} = @needle_defaults{@margs}; # fill in missing values

    # Get needle options.

    my( $radius, $color, $cmd, $format, $vref, $width, $arrowshape, $showvalue, $title, $tcolor, $tfont, $tplace, $tag ) =
	@ahsh{ qw/ -radius -color -command -format -variable -width -arrowshape
		   -showvalue -title -titlecolor -titlefont -titleplace -tag / };

    my( $center_x, $center_y ) = $self->centerpoint;

    if( $value > $self->cget( -to ) ) {
	$value = $self->cget( -to );
    } elsif( $value < $self->cget( -from ) ) {
	$value = $self->cget( -from );
    }

    my( $x, $y ) = $self->radialpoint( $value, $radius );
    $self->delete( $needle->{ -id } );
    $self->createLine( $x, $y, $center_x, $center_y,
        -arrow      => 'first',
        -arrowshape => $arrowshape,
        -fill       => $color,
        -tags       => [ 'needle', $needle->{ -id }, $tag ],
        -width      => $width,
    );
    my $hub_place = $self->cget( -hubplace );
    $self->raise( 'hub', 'needle' ) if $hub_place eq 'overneedle';
    $self->lower( 'hub', 'needle' ) if $hub_place eq 'underneedle';
    
    if( $showvalue ) {
	my $fw = $self->fontMeasure( $self->cget( -majorticklabelfont ), '0' );
	my $radius2 = $self->{ -maxradius } + $self->cget( -majorticklabelpad ) + ( $fw * length( $self->cget( -to ) ) );
	( $x, $y ) = $self->radialpoint( $value, $radius2 );
	$value = sprintf( $format, $value );
	$self->createText( $x, $y, -text => $value, -fill => $color, -tags => [ 'needlevalue', $needle->{ -id } ] );
    }

    # Needle title.

    $x = $center_x;
    die "Invalid -titleplace '$tplace': must be 'north' or 'south'." unless $tplace =~ /^north|south$/;
    if( $tplace eq 'south' ) {
	$y = $center_y + $radius / 2;
    } elsif( $tplace eq 'north' ) {
	$y = $center_y - $radius / 2;
    }

    $self->createText( $x, $y, -text => $title, -fill => $tcolor, -font => $tfont , -tags => [ 'title', $needle->{ -id } ] );

    my $bplace = $self->cget( -bandplace );
    die "Invalid -bandplace '$bplace': must be 'underticks' or 'overticks'." unless $bplace =~
	/^overticks|underticks$/;
    $self->raise( 'bands' ) if $bplace eq 'overticks';

} # end setvalue

sub tracew {

    my ( $index, $value, $op, $self, $needle ) = @_;

    # Invoke the -command callback, if any, then move the needle.

    return unless defined $self; # if app is being destroyed
    return if $self->{_busy};

    if ( $op eq 'w' ) {
	my $rc = 1;
	if( defined $needle->{ -command_callback } ) {
	    $rc = $needle->{ -command_callback }->Call;
	}
	$self->setvalue( $value, $needle ) if $rc;
	return $value;
    } elsif ( $op eq 'r' ) {
    } elsif ( $op eq 'u' ) {
	$self->traceVdelete ( $needle->{-variable} );
    }

} # end tracew

# Public methods.

sub centerpoint {            # coordinates of center of gauge

    my( $self ) = @_;

    $self->{ -maxradius } = $self->maxradius;;
    return ( $self->cget( -margin ) + $self->{ -maxradius } ) x 2;

} # end centerpoint

sub maxradius {		     # maximum needle radius including padding

    my( $self ) = @_;

    my $radius = 0;
    foreach my $needle ( @{ $self->cget( -needles ) } ) {
	$radius = $needle->{ -radius } if $needle->{ -radius } > $radius;
    }
    return $radius += $self->cget( -needlepad );

} # end maxradius

sub radialpoint {            # coordinates of a needle value relative to the gauge centerpoint

    my( $self, $value, $radius ) = @_;

    my $from     = $self->cget( -from );
    my $to       = $self->cget( -to );
    my $start    = $self->cget( -start );
    my $extent   = $self->cget( -extent );
    my $tincr    = $extent / ( $to - $from );
    my $angle    = $start + ( ( $value - $from ) * $tincr );
    $angle       = -$angle * $d2r;
    my( $x, $y ) = ( cos( $angle ) * $radius, sin( $angle ) * $radius );
    my( $center_x, $center_y ) = $self->centerpoint;
    $x += $center_x;
    $y += $center_y;
    return ( $x, $y );

} # end radialpoint

1;

__END__

=head1 NAME

Tk::Gauge - create a multitude of analog gauge widgets.

=head1 SYNOPSIS

 use Tk::Gauge;
 my $g = $mw->Gauge( -option => value );

=head1 DESCRIPTION

This widget creates an analog gauge.  A gauge has various components:
a radius highlighted by a circumference, one or more needles, a hub,
three granularities of tick marks, one of which has a value label, a
caption, title and specialized bands that visually compartmentalize
the gauge.

A gauge's appearance is specified by manipulating a set of
approximately 60 options, all described below. Given this flexibility
one may create instruments including, but not limited to, a 12 or 24
hour clock, CPU meter, voltmeter, fuel and temperature gauge,
speedometer and tachometer.

The following option/value pairs are supported (default value in parentheses):

=over 4

=item B<-background> ('white')

The gauge's background color.

=item B<-bands> (undef)

This is the gauge's band(s) descriptor. A band demarcates a section of
the gauge; for instance, a tachometer usually has a red band around a
portion of its circumference indicating when the engine's RPM has
exceeded "redline". The value of B<-bands> must be an array reference,
with each element of the array a hash reference having key/value pairs
laying out the details of one band. Other than the actual key/value
pairs, the format is identical to the B<-needles> option, and you can see
samples of that in the EXAMPLES section. Here are the B<-bands>
options and their default values:

 {
     -arccolor   =>       'white',
     -minimum    =>             0,
     -maximum    =>           100,
     -piecolor   =>       'white',
     -tag        =>            '',
 }

B<-arccolor> is relevant if B<-bandstyle> => 'band', while
B<-piecolor> is relevant if B<-bandstyle> => 'pieslice'.

B<-minimum> must be >= B<-from> and B<-maximum> must be <= B<-to>.

B<-tag> is a string that allows you to provide one custom tag for the
band(s).

=item B<-bandplace> ('underticks')

Controls the placements of the band(s) relative to the gauge tick
marks. A value of 'overticks' raises the band(s) above
the tick marks and obscures them.

=item B<-bandstyle> ('band')

Specifies the style of band.  The default is an arc-like band.  Alternately, a
'pieslice' style is available.

=item B<-bandwidth> (10)

Specifies the width of the band or the pieslice outline.

=item B<-caption> ('')

A title placed below the gauge.

=item B<-captioncolor> ('black')

The caption text color.

=item B<-extent> (-270)

Specifies the size of the angular range occupied by the arc.  The
arc's range extends for the specified number of degrees
counter-clockwise from the starting angle given by the B<-start> option.
Degrees may be negative.  If it is greater than 360 or less than -360,
then degrees modulo 360 is used as the extent.  For more details see
the documentation on the I<arc> item in the Canvas man page.

=item B<-fill> ('white')

The interior color of the gauge.

=item B<-finetickcolor> ('black')

Color of the fine tick marks.

=item B<-finetickinterval> (undef)

A positive integer specifying the smallest interval between gauge tick
marks.

=item B<-fineticklength> (2)

Pixel length of fine tick marks.

=item B<-finetickthickness> (1)

Pixel width of fine tick marks.

=item B<-from> (0)

Gauge's lower value, which must be an integer >= 0. See the B<-to> option
for important additional details.

=item B<-hubcolor> ('#ef5bef5bef5b')

Color of hub.

=item B<-huboutline> ('#ef5bef5bef5b')

Color of hub outline.

=item B<-hubplace> ('overneedle')

The hub is normally placed over the base of the needle(s), but you may
specify 'underneedle' if desired.

=item B<-hubradius> (5)

Radius of the hub.

=item B<-majortickcolor> ('black')

Color of the major tick marks.

=item B<-majortickinterval> (10)

A positive integer specifying the largest interval between gauge tick
marks.

=item B<-majorticklabelcolor> ('black')

Major tick marks can be labelled with an integer value of this color.

=item B<-majorticklabelfont> ('Helvetica-12')

A standard Tk font specification.

=item B<-majorticklabelformat> ('%d')

A standard C language I<(s)printf> format specification.

=item B<-majorticklabelpad> (10)

Padding distance between the major tick label and the gauge's circumference.

=item B<-majorticklabelplace> ('inside')

Major tick label values are normally placed inside the gauge's
circumference.  Specify 'outside' to place them outside the
circumference.

=item B<-majorticklabelscale> (1)

This is a multiplier that converts a gauge value to a major tick label
value.

=item B<-majorticklabelskip> (undef)

This must be an array reference - the array elements enumerate major
tick label values that should NOT be displayed. These are unscaled
values.

=item B<-majorticklength> (10)

Pixel length of major tick marks.

=item B<-majortickthickness> (1)

Pixel width of major tick marks.

=item B<-margin> (10)

A margin surrounding all four sides of the gauge, measured in pixels.

=item B<-minortickcolor> ('black')

Color of the minor tick marks.

=item B<-minortickinterval> (undef)

A positive integer specifying the middle interval between gauge tick
marks.

=item B<-minorticklength> (5)

Pixel length of minor tick marks.

=item B<-minortickthickness> (1)

Pixel width of minor tick marks.

=item B<-needles> ( [ { %needle_defaults } ] )

This is the gauge's needle(s) descriptor. A needle points to a
specific gauge value, from B<-from> to B<-to>, by rotating around the
hub of the gauge.  The value of B<-needles> must be an array
reference, with each element of the array a hash reference having
key/value pairs laying out the details of one needle.  You can see
samples of the B<-needles> option in the EXAMPLES section. Here are
the B<-needles> options and their default values:

 {
     -arrowshape => [ 12, 23, 6 ],
     -color      =>       'black',
     -command    =>         undef,
     -format     =>          '%d',
     -radius     =>            96,
     -showvalue  =>             0,
     -tag        =>            '',
     -title      =>            '',
     -titlecolor =>       'black',
     -titlefont  =>'Helvetica-12',
     -titleplace =>       'south',
     -variable   =>      \my $var,
     -width      =>             5,
 }

B<-arrowshape> describes the shape of a needle's arrow - you can model
various arrow shapes by running the I<widget> Canvas demonstration
I<An editor for arrowheads on Canvas lines.>

B<-color> is the needle's color.

B<-command> is a Perl/Tk callback that's invoked whenever the needle's
B<-variable> changes.  The callback should return a true or false value:
the needle is only moved if the callback returns true.

B<-format> is a standard C langauge I<(s)printf> format specification used
if B<-showvalue> => 1 to display the needle's current value.

B<-radius> is the needle's radius.

B<-showvalue>, if true, displays the needle's current value at its tip,
just outside the gauge's circumference.

B<-tag> is a string that allows you to provide one custom tag for the
needle.

B<-title> is the needle's title.

B<-titlecolor> is the needle's title color.

B<-titleplace> specifies where the title is displayed relative to the hub,
either 'north' or 'south'.

B<-variable> is a reference to the variable that holds the needle's
current value.  When the variable is written the needle moves, subject
to the return value from the needle's B<-command> callback.

B<-width> is the needle's width.

=item B<-needlepad> (0)

The padding between the tip of a gauge's longest needle and the major
tick labels.

=item B<-outline> ('black')

The gauge's outline color.

=item B<-outlinewidth> (2)

The pixel width of the gauge outline.

=item B<-start> (225)

Specifies the beginning of the angular range occupied by the gauge's
arc.  The value is given in units of degrees measured counterclockwise
from the 3-o'clock position; it may be either positive or negative.

=item B<-style> ('chord')

A gauge is a Canvas I<arc> item, so the B<-style> option specifies the
overall appearance of the widget.  Beside the default 'chord', other
possible values are 'pieslice' and 'arc'.  See the Canvas documentation
for more details.

=item B<-to> (100)

The B<-to> option seems obvious enough: it's the gauge's final value,
and must be a positive integer > than B<-from>.  But this option is
more complex, as it's intimately related to the fine, minor and major
tick mark intervals, the major tick mark label scale value, and to the
overall efficiency of the gauge.

For efficiency you want to make the difference between B<-to> and 
B<-from> as small as possible. So, looping from 1 to 80 is fine,
but a loop from 1 to 8,000 will be very slow and impact the startup
time of your application.

Now comes the hard part: specifying B<-from> and B<-to> to play nicely
with your tick marks, of which there are three species: major, minor
and fine. Essentially, since B<-from> and B<-to> must be positive
integers, and the major, minor and fine tick intervals must be
positive integers, your job is to find the integral Lowest Common
Denominator (iLCD) amongst them all, I<and> to set
B<-majorticklabelscale> accordingly.

For instance, suppose you want to make a tachometer to display RPM
from zero to 8,000.  Do not chose B<-from> => 0 and B<-to> -> 8000!
Slow city. If your major tick interval unit is RPM/1000, choose 1 .. 8
instead. Well, maybe.

Now suppose you require a minor tick every 500 RPM. Since any tick
interval must be a positive integer, make B<-to> 80, the major tick
interval 10, and the minor tick interval 5.

Now suppose your PHB requires a third fine tick interval every 250
RPM. Since any tick interval must be a positive integer, make B<-to>
800, the major tick interval 100, the minor tick interval 50, and
the new, fine tick interval, 25.  Finally, set the major tick label 
scale value to 0.01 so the displayed units are 0 .. 8.  Whew.

But wait, that's not the iLCD - we can divide everything by 5.  So
make B<-to> 160, the major tick interval 20, the minor tick interval
10, and the new fine tick interval, 5.  Finally, set the major tick
label scale value to 0.05.  Double whew!

More simply:

 my $iLCD = 50;         # integral Lowest Common Denominator
 -finetickinterval     => 250 / $iLCD
 -from                 => 0
 -majortickinterval    => 1000 / $iLCD
 -majorticklabelscale  => $iLCD / 1000
 -minortickinterval    => 500 / $iLCD

And to scale an actual RPM value:  $rpm = 1800 / $iLCD. See
the EXAMPLES section.

=back

=head1 METHODS

A Tk::Gauge widget is derived from a Tk::Canvas widget and thus has
all the standard Canvas methods, plus these:

=over 4

=item B<centerpoint>

Returns a list of two integers that are the X and Y Canvas coordinates
of the center of the gauge.

=item B<maxradius>

Returns the radius of the gauge, which is the length of the longest needle
plus the needle padding.

=item B<radialpoint>

Returns a list of two integers that are the X and Y Canvas coordinates
of a point that is relative to a gauge's centerpoint and defined by a
radius and value from -from to -to. 

=back

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
A Tk::Gauge widget is derived from a Tk::Canvas widget and thus
has no subwidgets.

=head1 ADVERTISED CANVAS TAGS

Tk::Gauge components are simply Canvas items, which are given tags
as noted below.

=over 4

=item B<bands>

  Tag for each band, an arc item.

=item B<caption>

  Tag for the caption, a text item.

=item B<finetick>

  Tag for each fine tick mark, a line item.

=item B<gauge>

  Tag for the gauge, an arc item.

=item B<hub>

  Tag for the hub, an oval item.

=item B<majortick>

  Tag for each major tick mark, a line item.

=item B<minortick>

  Tag for each minor tick mark, a line item.

=item B<needle>

  Tag for each needle, a line item.

=item B<needlevalue>

  Tag for a needle's value when B<-showvalue> => 1, a text item.

=item B<ticklabel>

  Tag for each major tick label, a text item.

=item B<title>

  Tag for a needle's title, a text item.

=back

=head1 EXAMPLES

 1) A 12 hour clock.

 my( $hour, $minute );

 my $clock = $mw->Gauge(
     -extent               => -359.9, # 360 loses outline
     -from                 => 0,
     -huboutline           => 'black',
     -majortickinterval    => 5,
     -majorticklabelscale  => 12.0 / 60.0,
     -majorticklabelskip   => [ 0 ],
     -minortickinterval    => 1,
     -needles              => [
                               {
                                   -radius     => 100,
                                   -variable   => \$minute,
                               },
                               {
                                  -radius     => 60,
                                  -variable   => \$hour,
                               },
                              ] ,
     -start                => 90,
     -to                   => 60,
 )->pack;

 2) A 24 hour clock. 

 my( $hour, $minute );

 my $clock = $mw->Gauge(
     -background           => 'bisque',
     -extent               => -359.9, # 360 loses outline
     -fill                 => 'red',
     -from                 => 0,
     -hubcolor             => 'gray',
     -huboutline           => 'black',
     -majortickcolor       => 'bisque',
     -majortickinterval    => 5,
     -majorticklabelcolor  => 'bisque',
     -majorticklabelformat => '%02d',
     -majorticklabelscale  => 24 / 120,
     -majorticklabelskip   => [ 120 ],
     -majorticklength      => 15,
     -majortickthickness   => 3,
     -margin               => 65,
     -minortickinterval    => 2,
     -minorticklength      => 7,
     -needles              => [
                               {
                                   -radius   => 120,
                                   -variable => \$minute,
                                   -width    => 2,
                               },
                               {
                                   -color    => 'bisque',                        
                                   -radius   => 80,
                                   -variable => \$hour,
                               },
                              ] ,
     -needlepad            => 10,
     -start                => 90,
     -to                   => 120,
 )->pack;

 # Add the minute ticks and their labels.

 my( $center_x, $center_y ) = $clock->centerpoint;
 my $radius = $clock->maxradius;
 foreach ( 1 .. 12 ) {
     my( $x, $y ) = $clock->radialpoint( 120 / 12 * $_, $radius + 20 );
     $clock->createText( $x, $y, -text => $_ * 5 );
 }

 3) A tachometer.

 my $iLCD = 50;		# integral Lowest Common Denominator
 my $tachv;
 my $tach = $mw->Gauge(
 -start => 225, -extent => -270,
     -background           => 'black',
     -bands                => [
                               {
                                -arccolor => 'red', 
                                -minimum  => 6250 / $iLCD,
                                -maximum  => 8000 / $iLCD,
                                -tags     => 'redtach',
                               },
                              ],
     -bandplace            => 'overticks',
     -bandwidth            => 12,
     -fill                 => 'black',
     -finetickinterval     => 250 / $iLCD,
     -fineticklength       => 5,
     -finetickcolor        => 'white',
     -from                 => 0,
     -highlightthickness   => 0,
     -hubcolor             => 'gray21',
     -huboutline           => 'gray21',
     -hubplace             => 'underneedle',
     -hubradius            => 20,
     -majortickinterval    => 1000 / $iLCD,
     -majorticklength      => 15,
     -majortickcolor       => 'white',
     -majorticklabelcolor  => 'white',
     -majorticklabelscale  => $iLCD / 1000,
     -margin               => 50,
     -minortickinterval    => 500 / $iLCD,
     -minorticklength      => 10,
     -minortickcolor       => 'white',
     -needles              => [
                               {
                               -radius     => 120,
                               -color      => 'orangered2',
                               -command    => [ sub {
                                   print "tach args=@_!\n";
                                   1;
                               }, 1, 2 ],
                               -variable   => \$tachv,
                               -width      => 3,
                               -showvalue  => 0,
                               -title      => 'x 1000 r / min',
                               -titlecolor => 'white',
                               -titleplace => 'north',
                               -arrowshape => [ 6, 6, 0 ],
                               },
                              ] ,
     -needlepad            => 15,
     -to                   => 8000 / $iLCD,
 );

=head1 AUTHOR and COPYRIGHT

sol0@lehigh.edu

Copyright (C) 2004 - 2004, Stephen O. Lidie.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Gauge, Canvas, mega-widget

=cut
