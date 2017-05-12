package WWW::StreamSend::Response;

use strict;
use warnings;

sub new {
    my ($class, $params) = @_;
    my $self = {
        data    => $params->{data},
        xml     => $params->{xml},
    };
    bless $self => $class;
    return $self;
}

sub as_xml {
    my ($self) = @_;
    return $self->{xml};
}

sub fields {
    my ($self) = @_;
    my @out = ();
    foreach my $key (keys %{$self->{data}}) {
        next if (ref $self->{data}{$key}[0] ne ref {});
        next unless ($self->{data}{$key}[0]{content});
        $key=~s/-/_/g;
        push @out, $key;
    }
    return @out;
}

# all unknown methods are accessors
sub UNIVERSAL::AUTOLOAD {
    my ($self) = @_;
    my ($methodname) = $UNIVERSAL::AUTOLOAD =~ /.*::(.*)/;
    return if $methodname eq 'DESTROY';
    $methodname=~s/_/-/g;
    return (exists $self->{data}->{$methodname}) ? $self->{data}{$methodname}[0]{content} : undef;
}

1;
