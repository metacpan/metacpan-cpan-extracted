package Vulcan::Gflags;
=head1 NAME

Vulcan::Gflags - Get command line options.

=cut

use strict;
use warnings;

use Carp;
use Tie::File;
use Pod::Usage;
use Getopt::Long;

our ( $ARGC, @CONF ) = 0;

sub new
{
    my $self = shift;
    $self->load( @_ );
}

=head1 SYNOPSIS

 use Vulcan::Gflags;

 $Vulcan::Gflags::ARGC = -1;
 @Vulcan::Gflags::CONF = qw( pass_through );

 my $option = Vulcan::Gflags->load( '/conf/file' );
 my %opt = $option->get( 'timeout=i', 'verbose' )->dump();

=head1 METHODS

=head3 load( $conf )

Load options from a gflags file $conf. Returns object.

=cut
sub load
{
    local $/ = "\n";

    my ( $class, $conf ) = splice @_;
    my ( @conf, %self );

    confess "invalid config"
        unless defined $conf &&  -e $conf && tie @conf, 'Tie::File', $conf;

    map { $self{$1} = $2 if $_ =~ /^\s*--([\w\d-]+)\s*=\s*(.+)/ } @conf;
    bless \%self, ref $class || $class;
}

=head3 dump()

Dump options. Returns HASH in scalar context or flattened HASH in list context.

=cut
sub dump
{
    my %conf = %{ shift @_ };
    return wantarray ? %conf : \%conf;
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

    push @_, map { join '=', $_, $self->{$_} =~ /^\d+$/
        ? 'i' : $self->{$_} =~ /^\d+\.\d+$/ ? 'f' : 's' } keys %$self;

    $self->assert() if ! Getopt::Long::GetOptions( $self, @_ )
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
        if ! @_ || grep { ! defined $self->{$_} } @_;
    return $self;
}

1;
