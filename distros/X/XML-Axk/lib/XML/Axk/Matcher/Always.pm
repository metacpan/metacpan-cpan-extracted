#!/usr/bin/env perl
# XML::Axk::Matcher::Always - Always match or not
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::Matcher::Always;
use XML::Axk::Base;

use XML::Axk::Object::TinyDefaults { always => true };

sub test {
    my $self = shift;
    return $self->always;
} #test()

1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
