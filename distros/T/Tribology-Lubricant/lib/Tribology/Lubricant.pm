package Tribology::Lubricant;

=head1 NAME

Tribology::Lubricant - Data type that represents a Lubricant class.

=head1 DESCRIPTION

This class, given technical data based on lubricant TDS/PDS documents assists in calculation of various Rheologic characteristics of the lubricant. Such as:

=over 4

=item * 

V-T behavior (C<m()>) using B<Ubbelohde-Walter> equation

=item * 

Calculate viscosity at a given temperature ( C<visc()> ) when any of two calibration points are known

=item * 

Calculate viscosity index using ASTM D2270's B<A> and B<B> procedures ( C<vi()> )

=item * 

Lookup B<L> and B<H> constants of the lubricant using ASTM D2270 Table and using linear interoplation whenever neccessary ( C<LH()> )

=back

=head1 SYNOPSIS

    require Tribology::Lubricant;

    # We already have viscosity at 40C and 100C. 
    my $lub = Tribology::Lubricant->new({
        label   => "Naphthenic spindle oil",
        visc40  => 30,
        visc100 => 100
    });

    # Viscosity @ 50C:
    my $visc50 = $lub->visc(50);

    # Viscosity index (VI)
    my $vi = $lub->vi;

    # Viscosity-temperature constant:
    my $vtc = $lub->vtc;

    # m-value, aka V-T behavior coefficient
    my $m = $lub->m;

    # To draw the V-T (hyperbolic) graph of this particular lubricant we can generate data-points, say, from -20 to +100:

    my @data_points;
    for my $T(-20..100) {
        push @data_points, [$T, $lub->visc($T)];
    }

    # Now you may pass @data_points to either GDGrap(Perl) or Highcharts(JS).  

=cut

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

=head2 new(\%attr)

Constructor. Following attributes (all optional) can be passed:

=over 4

=item label

Arbitrary label of the lubricant. Used in graph data or report tables, charts

=item visc40, visc100

Viscosity @ 40 and 100 degrees Celcius. 

=item vi

Viscosity index of the lubricant. 

=item density

Specific gravity of the lubricant at a given temperature point. Must be passed a hashref of Temprature-Density values. Density
must be in kg/cm3. 

=back

B<IMPORTANT> C<visc40> and C<visc100> are just convenience attributes, since they are most widely given in product TDSs. 
If you don't have calibration points at these temperatures IGNORE these attributes. Instead,
create empty constructor, set the calibration values you already have using C<visc()> method. Such as:

    my $lubricant = Tribology::Lubricant->new({label => "Hypothetical lubricant"});
    $lubricant->visc(50, 80);
    $lubricant->visc(100, 5.23);

=cut

sub new {
    my ( $class, $arg ) = @_;

    $arg ||= {};

    my %internals = (
        __visc_calibration_points => {},
        %$arg
    );

    if ( defined( $internals{visc40} ) ) {
        $internals{__visc_calibration_points}{40} = $internals{visc40};
    }

    if ( defined $internals{visc100} ) {
        $internals{__visc_calibration_points}{100} = $internals{visc100};
    }
    return bless( \%internals, $class );
}

=head2 label($new_label)

Returns and/or sets label of the lubricant

=cut

sub label {
    my ( $self, $new_label ) = @_;

    if ($new_label) {
        $self->{label} = $new_label;
    }
    return $self->{label};
}

=head2 visc($T, $cst)

Given temperature ($T) in celcius returns kinematic viscosity in cst. If such value was not given to the constructor it attempts to calculate
this number using B<Ubbelohde-Walter> equation. For this to be possible at least two calibration points must be given to C<new()> or two calibration
points must be set using two-argument syntax of C<visc()>.

If second argument is passed sets the viscosity point and returns the value $cst as is.

# 1.10 (eni), bo'yi ( 2.27 )

=cut

sub visc {
    my ( $self, $T, $cst ) = @_;

    unless ( defined $T ) {
        croak "visc(): usage error";
    }

    if ( defined $cst ) {
        $self->{__visc_calibration_points}{$T} = $cst;
        return $cst;
    }

    # If this calibration point was already given just return it:
    if ( my $visc = $self->{__visc_calibration_points}{$T} ) {
        return $visc;
    }

    # We have to attempt to calculate the viscosity at this given temp

    my @calibrations = @{ $self->__calibration_points(2) };
    unless ( scalar(@calibrations) == 2 ) {
        croak "visc(): Not enough calibration points to complete Ubbelohde-Walter equation";
    }

    my $c1_temp = $calibrations[0][0];
    my $c1_cst  = $calibrations[0][1];

    my $c2_temp = $calibrations[1][0];
    my $c2_cst  = $calibrations[1][1];

    my $vtc = $self->vtc;

    #my $b = ( log( log( $c1_cst + $vtc ) ) - log( log( $c2_cst + $vtc ) ) ) / ( log($c2_temp) - log($c1_temp) );
    my $m = $self->m;
    my $a = log( log( $c2_cst + $vtc ) / log(10) ) / log(10) + ( $m * log($c2_temp) / log(10) );

    #carp "\$c2_cst = $c2_cst";
    #carp "\$c2_temp = $c2_temp";
    #carp "\$a = $a";
    #carp "\$m = $m";
    #carp "\$vtc = $vtc";

    my $c = $a * 100;
    my $d = $m * 25;

    my $visc = exp(1)**( log(10) * exp(1)**( ( ( $c * log(10) ) / 100 ) - ( ( $d * log( __c2k($T) ) ) / 25 ) ) ) - 0.7;

    $self->{__visc_calibration_points}{$T} = $visc;
    return $visc;
} ## end sub visc

=head2 m()

Heart of the B<Ubbelohde-Walter> equation. This is the coeffient that characterises V-T behavior of oils. It's a double-logarithmic V-T graph slope.
It requires at least two calibration points be present, or must be calculatable to work. Otherwise it throws error (croaks).

=cut

sub m {
    my $self = shift;

    my $calibrations = $self->__calibration_points(2);

    unless ( scalar @$calibrations == 2 ) {
        croak "m(): at least 2 calibration points are required to properly calculate V-T slope (m).";
    }

    my $c1_temp = $calibrations->[0][0];
    my $c1_cst  = $calibrations->[0][1];

    my $c2_temp = $calibrations->[1][0];
    my $c2_cst  = $calibrations->[1][1];
    
    #carp "c1_temp = $c1_temp\nc1_cst=$c1_cst\n";
    #carp "c2_temp = $c2_temp\nc2_cst=$c2_cst\n";

    my $vtc = $self->vtc;
    return ( log( log( $c1_cst + $vtc ) ) - log( log( $c2_cst + $vtc ) ) ) / ( log($c2_temp) - log($c1_temp) ) ;
}

=head2 LH()

Returns B<L> and B<H> values for the given lubricant. For this method to work lubricant's viscosity @ 100C must be known or calculatable.

=cut

sub LH {
    my ($self) = @_;

    my $cst100 = $self->visc(100);
    unless ($cst100) {
        croak "__LH(): Viscosity of the lubricant \@ 100C is unknown. Cannot proceed further";
    }

    if ( $cst100 < 2 ) {
        croak "__LH(): ASTM D2270 does not define VI for lubricants below 2cst \@ 100C";
    }

    if ( $cst100 > 70 ) {
        my $L = ( 0.8353 * ( $cst100**2 ) ) + 14.67 * $cst100 - 216;
        my $H = ( 0.1684 * ( $cst100**2 ) ) + 11.85 * $cst100 - 97;
        return ( $L, $H );
    }

    my ( @one_before, @one_after );
    seek( DATA, 0, 0 );
    while ( my $line = <DATA> ) {
        next unless length($line);
        next if $line =~ m/^#/;
        next if $line =~ m/^\s*$/;

        my ( $visc, $L, $H ) = $line =~ m/^
            ([\d\.]+) \s+ ([\d\.]+) \s+ ([\d\.]+)
        \s* $/x;

        next unless ( $visc && $L && $H );
        return ( $L, $H ) if ( $visc == $cst100 );
        if ( $visc < $cst100 ) {
            @one_before = ( $visc, $L, $H );
            next;
        }
        if ( $visc > $cst100 ) {
            push @one_after, $visc, $L, $H;
            last;
        }
    }

    unless ( @one_before && @one_after ) {
        croak "__LH(): has nothing to interoplate";
    }

    my $visc1      = $one_before[0];
    my $visc2      = $one_after[0];
    my $visc_delta = $visc2 - $visc1;

    my $L1      = $one_before[1];
    my $L2      = $one_after[1];
    my $L_delta = $L2 - $L1;

    my $H1      = $one_before[2];
    my $H2      = $one_after[2];
    my $H_delta = $H2 - $H1;

    my $L1_per_unit = $L_delta / $visc_delta;
    my $H1_per_unit = $H_delta / $visc_delta;

    my $L = $L1 + ( ( $cst100 - $visc1 ) * $L1_per_unit );
    my $H = $H1 + ( ( $cst100 - $visc1 ) * $H1_per_unit );

    return ( $L, $H );
} ## end sub LH


sub data_table {
    my $self = shift;
    
    my @data = ();
    seek( DATA, 0, 0 );
    while ( my $line = <DATA> ) {
        next unless length($line);
        next if $line =~ m/^#/;
        next if $line =~ m/^\s*$/;

        my ( $visc, $L, $H ) = $line =~ m/^
            ([\d\.]+) \s+ ([\d\.]+) \s+ ([\d\.]+)
        \s* $/x;

        next unless ( $visc && $L && $H );
        
        push @data, [$visc, $L, $H];
    }
    return \@data;
}

=head2 vi()

Returns viscosity index of the lubricant, if such is possible. Remember, for this to be possible
calibration points at 40C and 100C must be available or calculatble. If it's impossible, it returns undef and writes a warning
to STDERR. When checking for error you must check for C<undef> at return.

=cut

sub vi {
    my ($self) = @_;

    my $vi = $self->__vi_lt_100;
    if ( $vi > 100 ) {
        $vi = $self->__vi_gt_100;
    }
    return $vi;
}

sub log10 {
    my ($n) = @_;
    return ( log($n) / log(10) );
}

=head2 vtc()

Returns B<VTC - viscosity-temperature constant> used in B<Ubbelohde-Walter> equation to better differentiate V-T behavior
when the influence of temperature is low. This constant must be used to accurately (or properly) calculate C<m>. 
To calculate this value properly we need to have calibration points at 40C and 100C. If either of these points are missing
C<vtc()> defaults to 0.8.

=cut

sub vtc {
    my $self = shift;

    my $visc40  = $self->{__visc_calibration_points}{40};
    my $visc100 = $self->{__visc_calibration_points}{100};

    return 0.8 unless ( $visc40 && $visc100 );
    return ( $visc40 - $visc100 ) / $visc40 ;
}

=head2 is_mineral

Based on the C<m> constant or C<vi> attempts to guess if current instance represents a mineral oil. 

=cut

sub is_mineral {
    my $self = shift;
    my $vi   = $self->vi;
    die "work in progress";
}

=head1 INTERNALS

=head2 __c2k($T)

Given temperature in celcius converts it to Kelvin

=cut

sub __c2k {
    my ($c) = @_;
    unless (defined $c) {
        die "__c2k(): usage error";
    }
    return ( $c + 273.15 );
}

=head2 __k2c($T)

Given temperature in Kelvin converts it to celcius

=cut

sub __k2c {
    my ($k) = @_;
    return ( $k - 273.15 );
}

=head2 __calibration_points($limit)

Returns all known calibration points to the lubricant as array reference. If C<$limit> is given limits the result set to that many points.
The points are guaranteed to be in ascending order by temperature. All temperature points are converted to Kelvin, since that's 
what all internal formulas rely on.

=cut

sub __calibration_points {
    my ( $self, $limit ) = @_;

    my @calibrations = ( sort { $a <=> $b } keys %{ $self->{__visc_calibration_points} } );

    my $lowest_temp  = $calibrations[0];
    my $highest_temp = $calibrations[-1];

    return [
        [ __c2k($lowest_temp),  $self->visc($lowest_temp) ],
        [ __c2k($highest_temp), $self->visc($highest_temp) ]
    ];
}

=head2 __vi_lt_100()

Uses algorithm described in B<5. Procedure A> section of ASTM D2270. When you use C<vi()> it invokes  either method
accordingly.

=cut

sub __vi_lt_100 {
    my ($self) = @_;

    my $cst40  = $self->visc(40);
    my $cst100 = $self->visc(100);

    unless ( $cst40 && $cst100 ) {
        croak "vi2(): viscosities at 40C and 100C must be known or calculatable";
    }

    my ( $L, $H ) = $self->LH;
    my $vi = ( ( $L - $cst40 ) / ( $L - $H ) ) * 100;

    return sprintf( "%d", $vi );
}

=head2 __vi_gt_100()

Uses algorithm described in B<6. Procedure B> section of ASTM D2270. When you use C<vi()> it invokes either method
accordingly. 

=cut

sub __vi_gt_100 {
    my ($self) = @_;

    my ( undef, $H ) = $self->LH;
    my $cst40  = $self->visc(40);
    my $cst100 = $self->visc(100);

    my $N = ( log10($H) - log10($cst40) ) / log10($cst100);
    my $vi = ( ( ( 10**$N ) - 1 ) / 0.00715 ) + 100;
    return sprintf( "%d", $vi );
}

=head1 SEE ALSO

L<Lubricants and Lubrication|http://www.amazon.com>, Second Edition by  Wiley-VCH

=cut

1;

__DATA__

# 
# ASTM D2270 Table 1
#
2.00 7.994 6.394  
2.10 8.640 6.894  
2.20 9.309 7.410  
2.30 10.00 7.944  
2.40 10.71 8.496  
2.50 11.45 9.063  
2.60 12.21 9.647  
2.70 13.00 10.25  
2.80 13.80 10.87  
2.90 14.63 11.50  
3.00 15.49 12.15  
3.10 16.36 12.82  
3.20 17.26 13.51  
3.30 18.18 14.21  
3.40 19.12 14.93  
3.50 20.09 15.66  
3.60 21.08 16.42  
3.70 22.09 17.19  
3.80 23.13 17.97  
3.90 24.19 18.77  
4.00 25.32 19.56  
4.10 26.50 20.37  
4.20 27.75 21.21  
4.30 29.07 22.05  
4.40 30.48 22.92  
4.50 31.96 23.81  
4.60 33.52 24.71  
4.70 35.13 25.63  
4.80 36.79 26.57  
4.90 38.50 27.53  
5.00 40.23 28.49  
5.10 41.99 29.46  
5.20 43.76 30.43  
5.30 45.53 31.40  
5.40 47.31 32.37  
5.50 49.09 33.34  
5.60 50.87 34.32  
5.70 52.64 35.29  
5.80 54.42 36.26  
5.90 56.20 37.23  
6.00 57.97 38.19  
6.10 59.74 39.17  
6.20 61.52 40.15  
6.30 63.32 41.13  
6.40 65.18 42.14  
6.50 67.12 43.18  
6.60 69.16 44.24  
6.70 71.29 45.33  
6.80 73.48 46.44  
6.90 75.72 47.51  
7.00 78.00 48.57
7.10 80.25 49.61
7.20 82.39 50.69
7.30 84.53 51.78
7.40 86.66 52.88
7.50 88.85 53.98
7.60 91.04 55.09
7.70 93.20 56.20
7.80 95.43 57.31
7.90 97.72 58.45
8.00 100.0 59.60
8.10 102.3 60.74
8.20 104.6 61.89
8.30 106.9 63.05
8.40 109.2 64.18
8.50 111.5 65.32
8.60 113.9 66.48
8.70 116.2 67.64
8.80 118.5 68.79
8.90 120.9 69.94
9.00 123.3 71.10
9.10 125.7 72.27
9.20 128.0 73.42
9.30 130.4 74.57
9.40 132.8 75.73
9.50 135.3 76.91
9.60 137.7 78.08
9.70 140.1 79.27
9.80 142.7 80.46
9.90 145.2 81.67
10.0 147.7 82.87
10.1 150.3 84.08
10.2 152.9 85.30
10.3 155.4 86.51
10.4 158.0 87.72
10.5 160.6 88.95
10.6 163.2 90.19
10.7 165.8 91.40
10.8 168.5 92.65
10.9 171.2 93.92
11.0 173.9 95.19
11.1 176.6 96.45
11.2 179.4 97.71
11.3 182.1 98.97
11.4 184.9 100.2
11.5 187.6 101.5
11.6 190.4 102.8
11.7 193.3 104.1
11.8 196.2 105.4
11.9 199.0 106.7
12.0 201.9 108.0 
12.1 204.8 109.4 
12.2 207.8 110.7 
12.3 210.7 112.0 
12.4 213.6 113.3 
12.5 216.6 114.7 
12.6 219.6 116.0 
12.7 222.6 117.4 
12.8 225.7 118.7 
12.9 228.8 120.1 
13.0 231.9 121.5 
13.1 235.0 122.9 
13.2 238.1 124.2 
13.3 241.2 125.6 
13.4 244.3 127.0 
13.5 247.4 128.4 
13.6 250.6 129.8 
13.7 253.8 131.2 
13.8 257.0 132.6 
13.9 260.1 134.0 
14.0 263.3 135.4 
14.1 266.6 136.8 
14.2 269.8 138.2 
14.3 273.0 139.6 
14.4 276.3 141.0 
14.5 279.6 142.4 
14.6 283.0 143.9 
14.7 286.4 145.3 
14.8 289.7 146.8 
14.9 293.0 148.2 
15.0 296.5 149.7 
15.1 300.0 151.2 
15.2 303.4 152.6 
15.3 306.9 154.1 
15.4 310.3 155.6 
15.5 313.9 157.0 
15.6 317.5 158.6 
15.7 321.1 160.1 
15.8 324.6 161.6 
15.9 328.3 163.1 
16.0 331.9 164.6 
16.1 335.5 166.1 
16.2 339.2 167.7 
16.3 342.9 169.2 
16.4 346.6 170.7 
16.5 350.3 172.3 
16.6 354.1 173.8 
16.7 358.0 175.4 
16.8 361.7 177.0 
16.9 365.6 178.6 
17.0 369.4 180.2 
17.1 373.3 181.7 
17.2 377.1 183.3 
17.3 381.0 184.9 
17.4 384.9 186.5 
17.5 388.9 188.1 
17.6 392.7 189.7 
17.7 396.7 191.3 
17.8 400.7 192.9 
17.9 404.6 194.6 
18.0 408.6 196.2 
18.1 412.6 197.8 
18.2 416.7 199.4 
18.3 420.7 201.0 
18.4 424.9 202.6 
18.5 429.0 204.3 
18.6 433.2 205.9 
18.7 437.3 207.6 
18.8 441.5 209.3 
18.9 445.7 211.0 
19.0 449.9 212.7 
19.1 454.2 214.4 
19.2 458.4 216.1 
19.3 462.7 217.7 
19.4 467.0 219.4 
19.5 471.3 221.1 
19.6 475.7 222.8 
19.7 479.7 224.5 
19.8 483.9 226.2 
19.9 488.6 227.7 
20.0 493.2 229.5 
20.2 501.5 233.0 
20.4 510.8 236.4 
20.6 519.9 240.1 
20.8 528.8 243.5 
21.0 538.4 247.1 
21.2 547.5 250.7 
21.4 556.7 254.2 
21.6 566.4 257.8 
21.8 575.6 261.5 
22.0 585.2 264.9 
22.2 595.0 268.6 
22.4 604.3 272.3 
22.6 614.2 275.8 
22.8 624.1 279.6 
23.0 633.6 283.3 
23.2 643.4 286.8 
23.4 653.8 290.5 
23.6 663.3 294.4 
23.8 673.7 297.9 
24.0 683.9 301.8
24.2 694.5 305.6
24.4 704.2 309.4
24.6 714.9 313.0
24.8 725.7 317.0
25.0 736.5 320.9
25.2 747.2 324.9
25.4 758.2 328.8
25.6 769.3 332.7
25.8 779.7 336.7
26.0 790.4 340.5
26.2 801.6 344.4
26.4 812.8 348.4
26.6 824.1 352.3
26.8 835.5 356.4
27.0 847.0 360.5
27.2 857.5 364.6
27.4 869.0 368.3
27.6 880.6 372.3
27.8 892.3 376.4
28.0 904.1 380.6
28.2 915.8 384.6
28.4 927.6 388.8
28.6 938.6 393.0
28.8 951.2 396.6
29.0 963.4 401.1
29.2 975.4 405.3
29.4 987.1 409.5
29.6 998.9 413.5
29.8 1011 417.6 
30.0 1023 421.7 
30.5 1055 432.4 
31.0 1086 443.2 
31.5 1119 454.0 
32.0 1151 464.9 
32.5 1184 475.9 
33.0 1217 487.0 
33.5 1251 498.1 
34.0 1286 509.6 
34.5 1321 521.1 
35.0 1356 532.5 
35.5 1391 544.0 
36.0 1427 555.6 
36.5 1464 567.1 
37.0 1501 579.3 
37.5 1538 591.3 
38.0 1575 603.1 
38.5 1613 615.0 
39.0 1651 627.1 
39.5 1691 639.2 
40.0 1730 651.8
40.5 1770 664.2
41.0 1810 676.6
41.5 1851 689.1
42.0 1892 701.9
42.5 1935 714.9
43.0 1978 728.2
43.5 2021 741.3
44.0 2064 754.4
44.5 2108 767.6
45.0 2152 780.9
45.5 2197 794.5
46.0 2243 808.2
46.5 2288 821.9
47.0 2333 835.5
47.5 2380 849.2
48.0 2426 863.0
48.5 2473 876.9
49.0 2521 890.9
49.5 2570 905.3
50.0 2618 919.6
50.5 2667 933.6
51.0 2717 948.2
51.5 2767 962.9
52.0 2817 977.5
52.5 2867 992.1
53.0 2918 1007
53.5 2969 1021
54.0 3020 1036
54.5 3073 1051
55.0 3126 1066
55.5 3180 1082
56.0 3233 1097
56.5 3286 1112
57.0 3340 1127
57.5 3396 1143
58.0 3452 1159
58.5 3507 1175
59.0 3563 1190
59.5 3619 1206
60.0 3676 1222
60.5 3734 1238
61.0 3792 1254
61.5 3850 1270
62.0 3908 1286
62.5 3966 1303
63.0 4026 1319
63.5 4087 1336
64.0 4147 1352
64.5 4207 1369
65.0 4268 1386
65.5 4329 1402
66.0 4392 1419
66.5 4455 1436
67.0 4517 1454
67.5 4580 1471
68.0 4645 1488
68.5 4709 1506
69.0 4773 1523
69.5 4839 1541
70.0 4905 1558

