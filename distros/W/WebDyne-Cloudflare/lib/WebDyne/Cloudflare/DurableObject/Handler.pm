package WebDyne::Cloudflare::DurableObject::Handler;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::DurableObject;
use WebDyne::Cloudflare::DurableObject::Context;
our $VERSION='0.001';

#  The hosting wrapper supplies the package and an allowlisted method. Each
#  finite event has a fresh context and yields exactly one structured result.
#
async sub application {
    my ($scope_hr, $receive_cr, $send_cr)=@_;
    my $response_hr;
    my $ok=eval {
        my $package=$scope_hr->{'package'};
        my $method=$scope_hr->{'method'};
        die "Invalid handler package or method\n"
            unless (defined($package)&&($package=~/\A[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/)
                &&defined($method)&&($method=~/\A[A-Za-z]\w*\z/));
        my $module_fn=$package;
        $module_fn=~s{::}{/}g;
        require "$module_fn.pm";
        my $handler_cr=$package->can($method) or die "Handler $package\::$method is not defined\n";
        my $context_or=WebDyne::Cloudflare::DurableObject::Context->new($scope_hr);
        my $args_ar=WebDyne::Cloudflare::DurableObject::decode_value($scope_hr->{'args'});
        die "Handler arguments must be an array\n" unless (ref($args_ar) eq 'ARRAY');
        my $result_ref=$handler_cr->($context_or, @{$args_ar});
        $result_ref=await $result_ref if (blessed($result_ref)&&$result_ref->isa('Future'));
        $response_hr={ok => JSON::PP::true, result => WebDyne::Cloudflare::DurableObject::encode_value($result_ref)};
        1;
    };
    unless ($ok) {
        my $error_ref=$@;
        my %error=(name => 'DURABLE_OBJECT_ERROR', message => substr("$error_ref", 0, 4096));
        if (blessed($error_ref)&&$error_ref->isa('WebDyne::Cloudflare::DurableObject::Error')) {
            $error{'name'}=substr($error_ref->name(), 0, 128);
            $error{'message'}=substr($error_ref->message(), 0, 4096);
            $error{'code'}=substr($error_ref->code(), 0, 128) if defined($error_ref->code());
        }
        $response_hr={ok => JSON::PP::false, error => \%error};
    }
    await $send_cr->({type => 'invocation.result', value => $response_hr});
    return;
}

1;
