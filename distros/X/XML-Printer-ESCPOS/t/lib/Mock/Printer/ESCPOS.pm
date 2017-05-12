package Mock::Printer::ESCPOS;

our $AUTOLOAD;

sub new {
    return bless { calls => [] }, 'Mock::Printer::ESCPOS';
}

sub AUTOLOAD {
    my ( $self, @params ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/^.*:://;
    push @{ $self->{calls} } => [ $method => @params ];
}

1;
