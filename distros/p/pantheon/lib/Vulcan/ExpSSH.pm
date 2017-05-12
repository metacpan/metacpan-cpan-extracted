package Vulcan::ExpSSH;

use strict;
use warnings;

use Expect;

our $TIMEOUT = 20;
our $SSH = 'ssh -o StrictHostKeyChecking=no -c blowfish';

=head1 SYNOPSIS

 use Vulcan::ExpSSH;

 my $ssh = Vulcan::ExpSSH->new( @zone );

 $ssh->conn( host => 'foo', user => 'joe', pass = 'secret', sudo => 'john' );

=cut

sub new
{
    my $class = shift;
    bless $class->l2h( @_ ), ref $class || $class;
}

sub conn
{
    my ( $self, %conn ) = splice @_;
    my $i = 0;

    return unless my @host = $self->host( $conn{host} );

    if ( @host > 1 )
    {
        my @host = map { sprintf "[ %d ] %s", $_ + 1, $host[$_] } 0 .. $#host; 
        print STDERR join "\n", @host, "please select: [ 1 ] ";
        $i = $1 - 1 if <STDIN> =~ /(\d+)/ && $1 && $1 <= @host;
    }

    my $exp = Expect->new();
    my $ssh = "$SSH -l $conn{user} $host[$i]";
    my $prompt = '::sudo::';
    my $pass = $conn{pass} || "\n"; $pass .= "\n" if $pass !~ /\n$/;

    if ( my $sudo = $conn{sudo} ) { $ssh .= " sudo -p '$prompt' su - $sudo" }

    $SIG{WINCH} = sub
    {
        $exp->slave->clone_winsize_from( \*STDIN );
        kill WINCH => $exp->pid if $exp->pid;
        local $SIG{WINCH} = $SIG{WINCH};
    };

    $exp->slave->clone_winsize_from( \*STDIN );
    $exp->spawn( $ssh );
    $exp->expect
    ( 
        $TIMEOUT, 
        [ qr/assword: *$/ => sub { $exp->send( $pass ); exp_continue; } ],
        [ qr/[#\$%] $/ => sub { $exp->interact; } ],
        [ qr/$prompt$/ => sub { $exp->send( $pass ); $exp->interact; } ],
    );
}

sub host
{
    my ( $self, $host ) = splice @_;
    return $host if ! $host || $host =~ qr/^\d+\.\d+\.\d+\.\d+$/;

    my $zone = $self;
    my ( $name, @zone ) = split '\.', $host;
    map { return () unless $zone = $zone->{$_} } @zone if %$zone;

    grep { ! system "host $_ > /dev/null" }
        %$zone ? map { join '.', $host, $_ } sort $self->h2l( $zone ) : $host;
}

sub l2h
{
    my $class = shift;
    return {} unless @_;
    my $zone = shift; $zone = [ $zone ] unless ref $zone;
    return { map { $_ => $class->l2h( @_ ) } @$zone };
}

sub h2l
{
    my ( $class, $hash, @list ) = splice @_;
    my @zone = sort keys %$hash;

    return @zone unless %{ $hash->{ $zone[0] } };

    for my $zone ( @zone )
    {
        push @list, map { join '.', $zone, $_ } $class->h2l( $hash->{$zone} );
    }
    return @list;
}

1;
