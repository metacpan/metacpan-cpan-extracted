#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-auth.t 28 2014-07-31 15:30:31Z minus $
#
#########################################################################
use Test::More tests => 10;
use File::Temp qw/ tempdir /;
use WWW::MLite::AuthSsn;
my $dir = tempdir( CLEANUP => 1 );
my $usid = undef;
my $ssn = new WWW::MLite::AuthSsn(
    -dsn  => "driver:file",
    -sid  => $usid,
    -args => {Directory => $dir},
);

is($ssn->authen( \&authen ), 0, "Access denied authen(LOGIN_INCORRECT): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo' ), 0, "Access denied authen(PASSWORD_INCORRECT): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo', 'hack' ), 0, "Access denied authen(DECLINED): ".$ssn->reason());
is($ssn->authen( \&authen, 'foo', 'bar' ), 1, "Grant access authen(OK): ".$ssn->reason());
is($ssn->get('login'), 'foo', "Login is foo");

is($ssn->authz( \&authz ), 0, "Access denied authz(FORBIDDEN): ".$ssn->reason());
$ssn->set(role  => 1);
is($ssn->authz( \&authz ), 1, "Grant access authz(OK/NEW): ".$ssn->reason());

$usid = $ssn->sid;
ok($usid ? 1 : 0, "USID generated");
is($ssn->access( \&access ), 1, "Grant access access(OK): ".$ssn->reason());
is($ssn->access( \&access, 'anonymous' ), 0, "Access denied access(FORBIDDEN): ".$ssn->reason());

sub authen {
    my $self = shift;
    my $login = shift || '';
    my $password = shift || '';

    $self->reason('LOGIN_INCORRECT') && return unless $login;
    $self->reason('PASSWORD_INCORRECT') && return unless $password;
    $self->reason('DECLINED') && return unless ($login eq 'foo') && ($password eq 'bar');

    $self->set(login => $login);
    $self->set(role  => 0);
    return 1;

}
sub authz {
    my $self = shift;
    my $role = $self->get('role') || 0;
    $self->reason('FORBIDDEN') && return unless $role;

    return 1;
}
sub access {
    my $self = shift;
    my $login = shift || $self->get('login') || 'anonymous';
    $self->reason('FORBIDDEN') && return if $login eq 'anonymous';
    return 1;
}

1;
