package Fitnesse::Slim::Test::LoginDialogDriver;

# Adapted from FitNesse v20251025's fitnesse.slim.test.LoginDialogDriver.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use warnings;

sub new {
    my ($class, $user_name, $password) = @_;
    return bless {
        user_name => $user_name,
        password => $password,
        message => undef,
        login_attempts => 0,
    }, $class;
}

sub login_with_username_and_password {
    my ($self, $user_name, $password) = @_;
    ++$self->{login_attempts};
    my $success = defined($self->{user_name})
        && defined($self->{password})
        && defined($user_name)
        && defined($password)
        && $self->{user_name} eq $user_name
        && $self->{password} eq $password;
    my $name = defined($self->{user_name}) ? $self->{user_name} : 'null';
    $self->{message} = $success ? "$name logged in." : "$name not logged in.";
    return $success ? 'true' : 'false';
}

sub login_message {
    my ($self) = @_;
    return $self->{message};
}

sub number_of_login_attempts {
    my ($self) = @_;
    return $self->{login_attempts};
}

1;
