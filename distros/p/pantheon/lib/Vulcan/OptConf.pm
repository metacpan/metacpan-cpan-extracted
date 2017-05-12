package Vulcan::OptConf;
=head1 NAME

Vulcan::OptConf - Get command line options.

=cut
use strict;
use warnings;

use Cwd;
use Carp;
use YAML::XS;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use FindBin qw( $RealScript $RealBin );

local $| = 1;

our ( $ARGC, $THIS, $CONF, $ROOT, @CONF ) = ( 0, $RealScript, '.config' );

=head1 SYNOPSIS

 use Vulcan::OptConf;

 $Vulcan::OptConf::ARGC = -1;
 @Vulcan::OptConf::CONF = qw( pass_through );

 my $option = Vulcan::OptConf->load( '/conf/file' );

 my %foo = $option->dump( 'foo' );

 my %opt = $option->set( bar => 'baz' )->get( 'timeout=i', 'verbose' )->dump;

=head1 METHODS

=head3 load( $conf )

Load options from a YAML file $conf, which if unspecified, defaults to
$RealBin/.config, or $RealBin/../.config, if either exists. Returns object.

=cut
sub load
{
    my $class = shift;
    my $self = {};
    my @conf =  map { File::Spec->join( $RealBin, $_, $CONF ) } qw( . .. );
    my ( $conf ) = @_ ? @_ : grep { -l $_ || -f $_ } @conf;

    if ( $conf )
    {
        my $error = "invalid config $conf";
        $conf = readlink $conf if -l $conf;
        confess "$error: not a regular file" unless -f $conf;

        $self = eval { YAML::XS::LoadFile( $conf ) };
        confess "$error: $@" if $@;
        confess "$error: not HASH" if ref $self ne 'HASH';

        $ROOT ||= dirname( dirname( Cwd::abs_path( $conf ) ) );
        for my $conf ( values %$self )
        {
            while ( my ( $opt, $value ) = each %$conf )
            {
                unless ( my $ref = ref $value )
                {
                    $conf->{$opt} = $class->macro( $conf->{$opt} );
                }
                elsif ( $ref eq 'ARRAY' )
                {
                    $value = [ map { $class->macro( $_ ) } @$value ];
                }
                elsif ( $ref eq 'HASH' )
                {
                    map { $value->{$_} = $class->macro( $value->{$_} ) }
                        keys %$value;
                }
            }
        }
    }

    $self->{$THIS} ||= {};
    bless $self, ref $class || $class;
}

=head3 dump( $name )

Dump options by $name, or that of $0 if $name is unspecified.
Returns HASH in scalar context or flattened HASH in list context.

=cut
sub dump
{
    my $self = shift;
    my %opt = %{ $self->{ @_ ? shift : $THIS } || {} };
    return wantarray ? %opt : \%opt;
}

=head3 set( %opt )

Set options specified by %opt for $0. Returns object.

=cut
sub set
{
    my ( $self, %opt ) = splice @_;
    map { $self->{$THIS}{$_} = $opt{$_} } keys %opt;
    return $self;
}

=head3 get( @option )

Invoke Getopt::Long to get @option, if any specified. Returns object.

Getopt::Long is configured through @CONF.

The leftover @ARGV size is asserted through $ARGC. @ARGV cannot be empty
if $ARGC is negative, otherwise size of @ARGV needs to equal $ARGC.

=cut
sub get
{
    my $self = shift;
    push @CONF, 'auto_help' unless grep /auto_help/, @CONF;
    Getopt::Long::Configure( @CONF );
    $self->assert() if ! Getopt::Long::GetOptions( $self->{$THIS}, @_ )
        || $ARGC < 0 && ! @ARGV || $ARGC > 0 && @ARGV != $ARGC;
    return $self;
}

=head3 assert( @option )

print help and exit, if any of @option is not defined.

=cut
sub assert
{
    my $self = shift;
    Pod::Usage::pod2usage( -input => $0, -output => \*STDERR, -verbose => 2 )
        if ! @_ || grep { ! defined $self->{$THIS}{$_} } @_;
    return $self;
}

=head3 macro( $path )

Replace $ROOT in $path if defined.

=cut
sub macro
{
    my ( $self, $path ) = splice @_;

    if ( $path && defined $ROOT )
    {
        $path =~ s/\$ROOT\b/$ROOT/g;
        $path =~ s/\${ROOT}/$ROOT/g;
    }

    return $path;
};

1;
