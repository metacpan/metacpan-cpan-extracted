use APR::Pool;
use APR::BucketAlloc;

sub import {
    my $class = shift;
    return unless @_;
    my $pkg = caller;
    no strict 'refs';

    for (@_) {
        *{"$pkg\::$_"} = $class->can($_)
            or die "Can't find method $_ in class $class";
    }
}

sub param_status {
    my $req = shift;
    return $req->args_status || $req->body_status if wantarray;
    return ($req->args_status, $req->body_status);
}

sub upload {
    require APR::Request::Param;
    my $req = shift;
    my $body = $req->body or return;
    my $uploads = $body->uploads($req->pool);
    $uploads->param_class("APR::Request::Param");

    return $uploads->get(@_) if @_;
    return keys %$uploads if wantarray;
    return $uploads;
}

package APR::Request::Custom;
our @ISA = qw/APR::Request/;

package APR::Request::Cookie::Table;

sub EXISTS {
    my ($t, $key) = @_;
    return defined $t->FETCH($key);
}

package APR::Request::Param::Table;

sub EXISTS {
    my ($t, $key) = @_;
    return defined $t->FETCH($key);
}
