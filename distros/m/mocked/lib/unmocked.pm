package unmocked;
use strict;
use warnings;
use mocked;

=head1 NAME

unmocked - use real libraries from within mocked libraries

=head1 SYNOPSIS

  # Your mocked module needs to use a real library
  package Fake::Fun;
  use unmocked 'URI';

=head1 DESCRIPTION

When mocking modules using 'mocked', you are certain that no extra "real"
libraries are being loaded.  But sometimes you don't want to use real
libraries from within your mocked library.  This module allows you to load
real libraries using your previous include paths.

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 import

With a package name, this function will ensure that the module you specify
is loaded from the regular @INC path (that mocked.pm has removed).

=cut

sub import {
    my $class = shift;
    my $module = shift;
    return unless $module;
 
    {
      local @INC = @$mocked::real_inc_paths;
      eval "require $module";
    }
    die $@ if $@;

    my $import = $module->can('import');
    @_ = ($module, @_);
    goto &$import if $import;
}

=head1 AUTHOR

Luke Closs, C<< <cpan at 5thplane.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
