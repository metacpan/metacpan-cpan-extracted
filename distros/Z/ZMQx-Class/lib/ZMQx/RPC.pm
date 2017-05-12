package ZMQx::RPC;


1;

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__



my $req = ZMQx::RPC::Message::Request->new('foo',{ type=>'JSON'},{ foo=>'bar'});
$socket->send_bytes($req->pack);
my $res = ZMQx::RPC::Message::Response->parse($socket->receive_bytes(1));

if ($res->success) {
    say 'yay';
}




my $req = ZMQx::RPC::Message::Request->new('foo',{ type=>'JSON'},{ foo=>'bar'});
$socket->send_bytes($req->pack);
my $res = ZMQx::RPC::Message::Response->parse($socket->receive_bytes(1));


# setup
my $rpc =  ZMQx::RPC->setup($socket);
my $sth = $rpc->prepare( $cmd, $header);
# in loops etc
my $result = $sth->(3, 5, 7)

my $calc = Calc->new;
my $result = $calc->sumof(3,5,7)

my $calc =  ZMQx::RPC->setup($socket, qw(sumof calculate render));
my $result = $calc->sumof(3, 5, 7)


# replace an inline class with RPCed

has 'pw_checker';
sub _build_pw_checker {
    PW::Check->new;
}
sub _build_pw_checker_zmq {
    ZMQ::RPC->new(
        based_on=>'PW::Check'
        methods=>'verify_passwd',
        socket=>$socket,
    )
}

sub login {
    my ($self, $req) = @_;

    my $pw = $self->pw_checker;
    if ($pw->verify_passwd($req->user,$req->param('passwd'))) {
        $req->session->login_user;
    }
}



