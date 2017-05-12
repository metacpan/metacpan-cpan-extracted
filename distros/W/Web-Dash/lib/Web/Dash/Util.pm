package Web::Dash::Util;
use strict;
use warnings;
use Future::Q;
use Net::DBus;
use Net::DBus::Annotation qw(dbus_call_async);
use Try::Tiny;
use Exporter qw(import);

our $VERSION = "0.041";

our @EXPORT_OK = qw(future_dbus_call);

sub future_dbus_call {
    my ($dbus_object, $method, @args) = @_;
    return Future::Q->try(sub {
        my $future = Future::Q->new;
        $dbus_object->$method(dbus_call_async, @args)->set_notify(sub {
            my $reply = shift;
            try {
                $future->fulfill($reply->get_result);
            }catch {
                my $e = shift;
                $future->reject($e);
            };
        });
        return $future;
    });
}


1;
