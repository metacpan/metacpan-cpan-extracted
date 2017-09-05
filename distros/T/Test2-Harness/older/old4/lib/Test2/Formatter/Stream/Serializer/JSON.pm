package Test2::Formatter::Stream::Serializer::JSON;
use strict;
use warnings;

use Test2::Harness::JSON qw/JSON decode_json/;

use Test2::Util::HashBase qw/encoder/;

use Carp qw/confess/;

sub init {
    my $self = shift;

    return if $self->{+ENCODER};

    my $J = JSON->new;
    $J->indent(0);
    $J->convert_blessed(1);
    $J->allow_blessed(1);
#    $J->canonical(1);
    $J->utf8(1);

    $self->{+ENCODER} = $J;
}

sub send {
    my $self = shift;
    my ($io, $data) = @_;

    # Any unknown blessed things will be stringified
    my $json = eval {
        no warnings 'once';
        local *UNIVERSAL::TO_JSON = sub { "$_[0]" };
        $self->encoder->encode($data)
    } or die "Error encoding JSON: $@";

    my $orig = eval { decode_json($json) } or confess $@;

    print $io "$json\n";
}

1;
