package Valiant::Util;

use strict;
use warnings;
 
use Module::Runtime;
use Moo::_Utils;

our @DEFAULT_EXPORTS = qw( throw_exception debug DEBUG_FLAG );

sub default_exports { @DEFAULT_EXPORTS }

sub import {
  my $class = shift;
  my $target = caller;
  my @exports = $class->default_exports;

  foreach my $exported_method (@exports) {
    my $sub = sub { $class->$exported_method($target, @_) };
    Moo::_Utils::_install_tracked($target, $exported_method, $sub);
  }
}

sub throw_exception {
  my ($class, $target, $class_name, @args) = @_;
  my $namespace = "Valiant::Util::Exception::$class_name";
  my $exception = Module::Runtime::use_module($namespace)->new(@args);
  die $exception->as_string;
}

sub DEBUG_FLAG { $ENV{VALIANT_DEBUG} ? 1:0 }

sub debug {
  my ($class, $target, $target_level, @args) = @_;
  return unless exists $ENV{VALIANT_DEBUG};
  my ($level, $package_pattern) = split(',', $ENV{VALIANT_DEBUG});
  if($package_pattern) {
    return unless $target eq ($package_pattern||'');
  }
  warn "$target: @args\n" if $level  >= $target_level;
}

1;

=head1 NAME

Valiant::Util - Importable utility methods;

=head1 SYNOPSIS

    use Valiant::Util 'throw_exception';

    throw_exception 'MissingMethod' => (object=>$self, method=>'if');

=head1 DESCRIPTION

Just a place to stick various utility functions that are cross cutting concerns.

=head1 SUBROUTINES 

This package has the following subroutines for EXPORT

=head2 debug

  debug $level, 'message';

Send debuggin info to STDERR if $level is greater or equal to the current log level
(default log level is '0' or 'no logging').

=head2 throw_exception

    throw_exception 'MissingMethod' => (object=>$self, method=>'if');

Used to encapsulate exception types.  Maybe someday we can do continuations instead :)

=head1 SEE ALSO
 
L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
