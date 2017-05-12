# Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

package Time::Duration::Filter;
use 5.004;
use strict;
no strict 'refs';
use Carp;
use Module::Load;
use vars qw($VERSION $AUTOLOAD);

$VERSION = 12;

# uncomment this to run the ### lines
# use Smart::Comments;


my @_target_ISA = ('Exporter');

sub import {
  shift; # $class own __PACKAGE__
  setup (scalar caller(), @_);
}
sub setup {
  my ($package, %options) = @_;
  my $from = $options{'from'} || 'Time::Duration';
  Module::Load::load ($from);

  ### setup: $package
  ### $from
  no strict;
  *{"${package}::AUTOLOAD"} = \&_target_AUTOLOAD;
  *{"${package}::can"}      = \&_target_can;
  ${"${package}::_from"}    = $from;

  require Exporter;
  *{"${package}::ISA"}      = \@_target_ISA;

  # same exports as the $from package
  foreach my $varname ('EXPORT','EXPORT_OK') {
    if (my $aref = *{"${from}::$varname"}{ARRAY}) {
      ### store array: $varname
      *{"${package}::$varname"} = $aref;
    }
  }
  foreach my $varname ('EXPORT_TAGS') {
    if (my $href = *{"${from}::$varname"}{HASH}) {
      ### store hash: $varname
      *{"${package}::$varname"} = $href;
    }
  }
}

sub _target_can {
  my ($class, $name) = @_;
  return ($class->SUPER::can($name) || _make_func ($class, $name));
}
sub _target_AUTOLOAD {
  ### TDF AUTOLOAD of: $AUTOLOAD
  my ($package, $name) = ($AUTOLOAD =~ /(.*)::(.*)/);
  my $subr = _make_func ($package, $name)
    || die "No function $name exported by " . ${"${package}::_from"};
  goto $subr;
}

sub _make_func {
  my ($package, $name) = @_;

  scalar(grep {$_ eq $name} @{"${package}::EXPORT_OK"})
    or return; # no such function

  my $from = ${"${package}::_from"};
  my $from_func = "${from}::$name";
  my $filter_func = "${package}::_filter";
  ### from: $from_func
  ### filter: $filter_func

  my $subr = sub { &$filter_func (&$from_func (@_)) };
  *{"${package}::$name"} = $subr;
  return $subr;
}


#   if ($name eq '_filter') {
#     die "$package didn't define a _filter() function";
#   }
#   if ($name =~ /^_f/) {
#     die "Oops, bad autoload $AUTOLOAD";
#   }

1;
__END__

=for stopwords Ryde

=head1 NAME

Time::Duration::Filter - fun filtering of Time::Duration strings

=head1 SYNOPSIS

 package Time::Duration::sv_CHEF;
 use Time::Duration::Filter  from => 'Time::Duration::sv';
 sub _filter {
    my ($str) = @_;
    return "$str, bjork, bjork";
 }

=head1 DESCRIPTION

This is an experiment, it's not really meant for use yet, though it works as
far as it goes.

C<Time::Duration::Filter> sets up a new package with exports and functions
compatible with C<Time::Duration> and which all work by filtering the output
of C<Time::Duration> or a given language-specific package.

=head1 SEE ALSO

L<Time::Duration>, L<Text::Bastardize>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/time-duration-locale/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

Time-Duration-Locale is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Time-Duration-Locale is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

=cut
