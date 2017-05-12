package Zed::Plugin::Host::Checkout;

use strict;
use Zed::Plugin;
use Zed::Output;
use Zed::Config::Env;
use Zed::Config::Space;

=head1 SYNOPSIS

    Checkout execute result to separate space
    ex:
        checkout
        checkout ex1

=cut

invoke "checkout" => sub {

    my ( $prefix, %result, %checkout ) = shift;
    %result = %{ env('result') };
    $prefix ||= 'default';
    debug("result:", \%result);
    
    my %checkout = map
    {
        my( $v, %hash ) = $result{$_};
        ref $v eq "ARRAY" ? $hash{$_} = $v : ref $v eq "HASH"  ? map{ $hash{$_} = $v->{$_}  }keys %$v : ();
        %hash;
    } qw( suc fail group );

    while( my($key, $v) = each %checkout )
    {
       space("$prefix\.$key", $v);
       info("add $prefix\.$key hosts[", scalar @$v, "] suc!");
    }
};
1
