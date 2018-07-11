package XAO::DO::Web::UniHex;
use strict;
use warnings;
use XAO::Objects;
use XAO::Utils;

use base XAO::Objects->load(objname => 'Web::Page');

# This is a helper object to test Unicode encoding of
# object arguments

sub display ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $output='';
    foreach my $n (sort keys %$args) {
        my $v=$args->{$n};

        my $hex=unpack('H*',Encode::is_utf8($v) ? Encode::encode('utf8',$v) : $v);

        $output.='('.join('|',$n,$hex,Encode::is_utf8($v)).')';
    }

    $self->textout($output);
}

1;
