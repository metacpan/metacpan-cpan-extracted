package Vulcan::Cruft;

=head1 NAME

Vulcan::Cruft - Rotate log files and keep directories clean of cruft.

=cut
use strict;
use warnings;

use Carp;
use POSIX;
use File::Spec;
use File::Basename;
use Time::HiRes qw( time );

use constant KILO => 1024;
use constant BYTE => qw( B K M G T P E Z Y );
use constant TIME => qw( S 1 M 60 H 3600 D 86400 W 604800 );

our %CUT = ( block => '8K', size => '10MB' );

=head1 SYNOPSIS

 use Vulcan::Cruft;

 my $cruft = Vulcan::Cruft->new( @logdir, @logfile );

 my %cut = $cruft->cut( size => '10MB', block => '8K' );

 unlink $cruft->cruft
 ( 
    count => 20,
    regex => qr/^foobar/,
    size => '100MB',
    age => '10days',
 );
 
=cut
sub new
{
    my $class = shift;
    bless [ map { -l $_ ? readlink $_ : $_ } map { glob $_ } @_ ],
        ref $class || $class;
}

=head1 METHODS

=head3 cruft( %param )

Purge files according to %param. Returns a list of 'cruft'.

 regex: pattern of file name.
 count: number of files to keep.
 size: total file size.
 age: age of file.
 remove: remove cruft.

=cut
sub cruft
{
    my ( $self, %param ) = splice @_;
    my ( $count, $regex ) = @param{ qw( count regex ) };
    my ( $now, %stat, @file, @cruft ) = time;

    my $size = $self->convert( size => $param{size} );
    my $age = $self->convert( time => $param{age} );

    for my $path ( @$self )
    {
        my $sum = -d $path ? 0 : next;

        for my $file ( glob File::Spec->join( $path, '*' ) )
        {
            next unless -f $file;
            next if $regex && File::Basename::basename( $file ) !~ $regex;

            my ( $size, $ctime ) = ( stat $file )[7,10];
            if ( $now && $now > $ctime + $age ) { push @cruft, $file }
            else { $stat{$file} = [ $size, $ctime, $file ] }
        }

        for my $file ( sort { $stat{$b}[1] <=> $stat{$a}[1] } keys %stat )
        {
            if ( $size && ( $sum += $stat{$file}[0] ) > $size )
            {
                push @cruft, $file;
                $sum -= $stat{$file}[0] unless $age;
            }
            else { unshift @file, $file }
        }

        push @cruft, splice @file, $count, $#file if $count && @file > $count;
    }

    unlink @cruft if $param{remove};
    return wantarray ? @cruft : \@cruft;
}

=head3 cut( %param )

Rotate files according to %param. Returns a hash of results.

 size: max size of each segment.
 block: block size ( per cut ).
 count: number of files to keep.

=cut
sub cut
{
    my ( $self, %param, %cut ) = splice @_;
    my ( $block, $size ) = map
        { $self->convert( size => $param{$_} || $CUT{$_} ) } qw( block size );

    $block = $size if $size < $block;

    my $count = int( $size / $block );
    my $dd = "dd bs=$block count=$count";
    my $time = POSIX::strftime( '.%Y-%m-%d.%H%M.', localtime );

    for my $file ( @$self )
    {
        next unless -f $file;
        my $cut = ( stat $file )[7] / $size;

        next if $cut <= 1;
        $cut = int $cut;

        my $keep = $param{count} || $cut;
        my ( $chunk, $i ) = ( $file.$time, 0 );

        while ( $cut >= 0 )
        {
            my $skip = $count * $i ++;
            my $of = $keep < $cut -- ? next : $chunk . ( $cut + 1 );
            last if system sprintf "$dd if=$file of=$of skip=$skip";
        }

        $chunk .= 0;
        system "cat $chunk > $file && rm $chunk";
        $cut{$file} = [ $time, $i < $keep ? $i : $keep ];
    }
    return wantarray ? %cut : \%cut;
}

=head3 convert( $type, $expr )

Convert an $expr of $type to a number of base units. $type can be

I<time>: base unit 1 second, units can be

 s[econd] m[inutea h[our] d[ay] w[eek]

I<size>: base unit 1 byte, units can be B K M G T P E Z Y

An expression may consist of multiple units, e.g.

 '2h,3m,20s' or '2MB 10K'

=cut
sub convert
{
    my ( $class, $type, $expr ) = splice @_;
    return undef unless defined $expr;

    my @token = split /(\D+)/, $expr;
    return undef if $token[0] !~ /\d/;

    my ( $sum, %unit ) = 0;

    if ( $type eq 'time' )
    {
        push @token, 'S' if @token % 2;
        %unit = (TIME);
    }
    else
    {
        push @token, 'B' if @token % 2;
        %unit = map { (BYTE)[$_] => KILO ** $_ } 0 .. (BYTE) - 1;
    }

    while ( @token )
    {
        my ( $num, $unit ) = splice @token, 0, 2;
        $sum += $num * $unit if $unit = $unit{ uc substr $unit, 0, 1 };
    }
    return $sum;
}

1;
