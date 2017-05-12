package mocked;
use strict;
use warnings;
use base 'Exporter'; # load this so mocked libraries can export things
use unmocked;

=head1 NAME

mocked - use mocked libraries in unit tests

=head1 SYNOPSIS

  # use a fake LWP::Simple for testing from t/lib/LWP/Simple.pm
  use mocked 'LWP::Simple';
  my $text = get($url);

  # use a fake WWW::Mechanize for testing from t/mock-libs/WWW/Mechanize.pm
  use mocked [qw(WWW::Mechanize t/mock-libs)];
  

=head1 DESCRIPTION

Often during unit testing, you may find the need to use mocked libraries
to test edge cases, or prevent unit tests from using slow or external
code.

This is where mocking libraries can help.

When you mock a library, you are creating a fake one that will be used
in place of the real one.  The code can do as much or as little as is
needed.

Use mocked.pm as a safety measure (be sure you're actually using the
mocked module), and as a way to document the tests for future
maintainers.

=cut

our $VERSION = '0.09';

=head1 VARIABLES

=head2 real_inc_paths

The real @INC that we are over-ridding is stored here while we are 
loading the mocked library.

=cut

our $real_inc_paths;

=head1 FUNCTIONS

=head2 import

With a package name, this function will ensure that the module you specify
is loaded from t/lib.

You can also pass an array reference containing the package name and a
directory from which to load it from.

=cut

sub import {
    my $class = shift;
    my $module = shift;
    return unless $module;
 
    {
      no strict 'refs';
      my $sym = $module . '::';
      if(
          exists $INC{ convert_package_to_file($module) } 
          || (keys %{$sym})
        ){
        die q{Attempting to mock an already loaded library};
      }
    }

    my $mock_path = 't/lib';
    if(ref($module) eq 'ARRAY'){
      ($module, $mock_path) = @$module;
    }
    
    # Load the real inc paths the first time we're called.
    $real_inc_paths ||= \@INC;
    {
      local @INC = ($mock_path);
      eval "require $module";
    }
    die $@ if $@;

    my $import = $module->can('import');
    @_ = ($module, @_);
    goto &$import if $import;
}

sub convert_package_to_file {
  my $package = shift;
  (my $filename = $package) =~ s{::}{/}g;
  $filename .= q{.pm};
  return $filename;
}

=head1 AUTHOR

Luke Closs, C<< <cpan at 5thplane.com> >>
Scott McWhirter, C<< <kungfuftr at cpan.org> >>

=head1 MAD CREDS TO

Ingy döt net, for only.pm

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
