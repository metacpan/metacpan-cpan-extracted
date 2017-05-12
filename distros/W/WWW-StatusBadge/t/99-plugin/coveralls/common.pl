#!/usr/bin/perl

no warnings 'redefine';

sub common_plugin_class  { 'WWW::StatusBadge::Service::Coveralls' }
sub common_method { 'coveralls' }

1;
