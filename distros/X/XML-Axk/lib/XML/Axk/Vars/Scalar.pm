#!/usr/bin/env perl
# XML::Axk::Vars::Scalar - tie a scalar to a member in X::A::Core.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::Vars::Scalar;
use XML::Axk::Base;

use Tie::Scalar;
use parent -norequire => 'Tie::StdScalar';

# Tie methods ==================================================== {{{1

# Create a scalar tied to a script-accessible var in an XAC instance
# @param $class
# @param $core      XML::Axk::Core instance
# @param $varname   Name of the new variable
sub TIESCALAR {
    my $class = shift;
    croak("Internal use only --- see XML::Axk::Sandbox")
        unless scalar caller eq 'XML::Axk::Sandbox';

    my ($sandbox, $lang, $varname) = @_;
    croak 'No sandbox' unless ref $sandbox eq 'XML::Axk::Sandbox';
    croak 'No language name' unless $lang;
    croak 'No varname' unless $varname;

    #say "Tying scalar \$$varname to $core";
    my $hrSP = $sandbox->sps($lang);
    return bless \($hrSP->{$varname}), $class;
} #TIESCALAR()

# }}}1
1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker foldlevel=2: #
