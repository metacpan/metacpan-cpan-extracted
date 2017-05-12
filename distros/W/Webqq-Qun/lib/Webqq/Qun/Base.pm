package Webqq::Qun::Base;
use Carp;
use strict;
use Data::Dumper;
use Scalar::Util qw(blessed reftype);
sub dump {
    my $self = shift;
    print Dumper $self;
}
sub each {
    my $self = shift;
    my $callback = pop;
    my @data;
    if(@_ == 1 and reftype $_[0] eq 'ARRAY'){
        @data = @{$_[0]};
    }
    else{
        @data = @_;
    }
    for (@data){
        $callback->($_);
    }
}
1;
