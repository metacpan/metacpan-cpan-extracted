#!/usr/bin/perl

no warnings 'redefine';

sub common_plugin_class { 'WWW::StatusBadge::Service::TravisCI' }
sub common_method { 'travis' }

1;
