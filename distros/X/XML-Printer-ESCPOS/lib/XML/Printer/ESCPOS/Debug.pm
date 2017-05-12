package XML::Printer::ESCPOS::Debug;

use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.05';

our $AUTOLOAD;

=head2 new

Constructs a debug printer object.

=cut

sub new {
    return bless { calls => [], }, $_[0];
}

=head2 AUTOLOAD

Logs all calls to the printer object.

=cut

sub AUTOLOAD {
    my ( $self, @params ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    push @{ $self->{calls} } => [ $method => @params ];
}

=head2 as_perl_code

Returns all calls to the printer as perl code.

=cut

sub as_perl_code {
    my $self = shift;
    my $devicevar = shift || '$device';
    {
        local $Data::Dumper::Terse = 1;
        return join '' => map {
            my $method = shift @$_;
            my $paramlist = Data::Dumper->Dump( [$_], [qw(*ary)] );
            $paramlist =~ s/\s+$//gm;
            $devicevar . '->printer->' . $method . $paramlist . ";\n";
        } @{ $self->{calls} };
    }
}

1;
