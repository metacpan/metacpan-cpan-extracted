#ABSTRACT: simple time sequence base on Date::Calc
package Time::Sequence;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw( get_time seq_times cut_time );

our $VERSION = 0.01;

use Date::Calc qw/Mktime Add_Delta_YMDHMS Localtime/;

our $TIME_FORMAT = "%04d-%02d-%02d %02d:%02d:%02d";
our $DAY_FORMAT  = "%04d-%02d-%02d";
our @TIME_FIELDS = qw/year month day hour minute second/;

sub get_time {
    my ( $time, %opt ) = @_;
    $opt{format} ||= $TIME_FORMAT;
    $opt{delta}  ||= {};
    $opt{delta}{$_} ||= 0 for @TIME_FIELDS;

    my @s = $time ? parse_time($time) : ( Localtime() )[ 0 .. 5 ];
    @s = Add_Delta_YMDHMS( @s, @{ $opt{delta} }{@TIME_FIELDS} );

    return sprintf( $opt{format}, @s );
}

sub parse_time {
    my ($t) = @_;
    $t =~ s/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/;
    my @times = $t =~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    return @times;
}

sub seq_times {
    my ( $from, $to, %opt ) = @_;
    $opt{format} ||= $DAY_FORMAT;
    $opt{delta}  ||= { day => 1 };
    $to          ||= get_time();

    my @s = parse_time($from);
    my @e = parse_time($to);

    my @times;
    while (Mktime(@s)<Mktime(@e) ) {
        push @times, sprintf( $opt{format}, @s );
        @s = Add_Delta_YMDHMS( @s, @{ $opt{delta} }{@TIME_FIELDS} );
    }

    my $ss = sprintf( $opt{format}, @s );
    my $ee = sprintf( $opt{format}, @e );
    push @times, $ee unless ( $opt{trim_end} and ( $ss cmp $ee ) );

    return \@times;
}

sub cut_time {
    my ( $time, $seq_times ) = @_;

    for ( my $i = 0 ; $i < $#$seq_times ; $i++ ) {
        my ( $f, $e ) = @{$seq_times}[ $i, $i + 1 ];
        next if( ($e cmp $time) == -1);
        last if( ($f cmp $time) == 1);
        return $f;
    }
    return '';
}

1;
