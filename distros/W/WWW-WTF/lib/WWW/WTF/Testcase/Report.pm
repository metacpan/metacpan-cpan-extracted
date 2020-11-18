package WWW::WTF::Testcase::Report;
use Moose;
use common::sense;
use Test2::API qw/context/;

sub pass {
    my ($self, $message, $o) = @_;

    my $ctx = context();

    my $event = $ctx->send_ev2(
        assert  => {
            pass        => 1,
            no_debug    => 1,
            details     => "$message",
        },
    );

    $ctx->release;
}

sub fail {
    my ($self, $message, $o) = @_;

    my $ctx = context();

    my $event = $ctx->send_ev2(
        assert  => {
            pass        => 0, 
            no_debug    => 1,
            details     => "$message",
        },
    );

    $ctx->release;
}

sub diag {
    my ($self, $message, $o) = @_;

    my $ctx = context();

    my $event = $ctx->diag($message);

    $ctx->release;
}


sub done {
    my ($self) = @_;

    my $ctx = context();
    $ctx->done_testing();
    $ctx->release;
}



__PACKAGE__->meta->make_immutable;
1;
