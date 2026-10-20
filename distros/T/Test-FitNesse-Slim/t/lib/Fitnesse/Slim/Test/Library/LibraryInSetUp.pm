package Fitnesse::Slim::Test::Library::LibraryInSetUp;

# Adapted from FitNesse v20251025's fitnesse.slim.test.library.LibraryInSetUp.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless { echo_called => 0 }, $class;
}

sub echo {
    my ($self) = @_;
    $self->{echo_called} = 1;
    return;
}

sub echo_in_set_up_library_called {
    my ($self) = @_;
    return $self->{echo_called} ? 'true' : 'false';
}

1;
