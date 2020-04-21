package fs::Promises::Utils;
use v5.24;
use warnings;
use AnyEvent ();
use AnyEvent::XSPromises ();
use Scalar::Util qw(blessed);
use Exporter qw(import);
our @EXPORT_OK = qw(await p_while then);

sub await ($) {
    my $p = shift;
    my $cv = AnyEvent->condvar;
    $p->then(
        sub { $cv->send(@_) },
        sub { $cv->croak(@_) },
    );
    return $cv->recv;
}

sub then (&) { return $_[0] }
sub p_while (&$) {
    my ($while_cond, $cb) = @_;

    my $d = AnyEvent::XSPromises::deferred();

    sub {
        my $do_while = __SUB__;
        my $cond = $while_cond->();
        $cond    = AnyEvent::XSPromises::resolved($cond) if !blessed($cond) || !$cond->can('then');
        return $cond->then(sub {
            return unless defined($_[0]);
            $cb->($_[0]);
            $do_while->();
        })
    }->()->finally(sub { $d->resolve });

    return $d->promise;
}

1;

