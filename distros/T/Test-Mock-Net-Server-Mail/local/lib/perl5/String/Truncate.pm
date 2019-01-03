use strict;
use warnings;
package String::Truncate;
# ABSTRACT: a module for when strings are too long to be displayed in...
$String::Truncate::VERSION = '1.100602';
use Carp qw(croak);
use Sub::Install 0.03 qw(install_sub);

# =head1 SYNOPSIS
#
# This module handles the simple but common problem of long strings and finite
# terminal width.  It can convert:
#
#  "this is your brain" -> "this is your ..."
#                       or "...is your brain"
#                       or "this is... brain"
#                       or "... is your b..."
#
# It's simple:
#
#  use String::Truncate qw(elide);
#
#  my $brain = "this is your brain";
#
#  elide($brain, 16); # first option
#  elide($brain, 16, { truncate => 'left' });   # second option
#  elide($brain, 16, { truncate => 'middle' }); # third option
#  elide($brain, 16, { truncate => 'ends' });   # fourth option
#
#  String::Trunc::trunc($brain, 16); # => "this is your bra"
#
# =func elide
#
#   elide($string, $length, \%arg)
#
# This function returns the string, if it is less than or equal to C<$length>
# characters long.  If it is longer, it truncates the string and marks the
# elision.
#
# Valid arguments are:
#
#  truncate - elide at left, right, middle, or ends? (default: right)
#  marker   - how to mark the elision (default: ...)
#  at_space - if true, strings will be broken at whitespace if possible
#
# =cut

my %elider_for = (
  right  => \&_elide_right,
  left   => \&_elide_left,
  middle => \&_elide_middle,
  ends   => \&_elide_ends,
);

sub _elide_right {
  &_assert_1ML; ## no critic Ampersand
  my ($string, $length, $marker, $at_space) = @_;
  my $keep = $length - length($marker);

  if ($at_space) {
    
    my ($substr) = $string =~ /\A(.{0,$keep})\s/s;
    $substr = substr($string, 0, $keep) 
      unless defined $substr and length $substr;

    return $substr . $marker;
  } else {
    return substr($string, 0, $keep) . $marker;
  }
}

sub _elide_left {
  &_assert_1ML; ## no critic Ampersand
  my ($string, $length, $marker, $at_space) = @_;
  my $keep = $length - length($marker);
  return $marker
       . reverse(_elide_right(scalar reverse($string), $keep, q{}, $at_space));
}

sub _elide_middle {
  &_assert_1ML; ## no critic Ampersand
  my ($string, $length, $marker, $at_space) = @_;
  my $keep = $length - length($marker);
  my ($keep_left, $keep_right) = (int($keep / 2)) x 2;
  $keep_left +=1 if ($keep_left + $keep_right) < $keep;
  return _elide_right($string, $keep_left, q{}, $at_space)
       . $marker
       . _elide_left($string, $keep_right, q{}, $at_space)
}

sub _elide_ends {
  &_assert_2ML; ## no critic Ampersand
  my ($string, $length, $marker, $at_space) = @_;
  my $midpoint = int(length($string) / 2);
  my $each = int($length / 2);

  return _elide_left(substr($string, 0, $midpoint), $each, $marker, $at_space)
       . _elide_right(substr($string, -$midpoint), $each, $marker, $at_space)
}

sub _assert_1ML {
  my ($string, $length, $marker) = @_;
  croak "elision marker <$marker> is longer than allowed length $length!"
    if length($marker) > $length;
}

sub _assert_2ML {
  my ($string, $length, $marker) = @_;
  # this should only complain if needed: elide('foobar', 3, {marker=>'...'})
  # should be ok -- rjbs, 2006-02-24
  croak "two elision markers <$marker> are longer than allowed length $length!"
    if (length($marker) * 2) > $length;
}

sub elide {
  my ($string, $length, $arg) = @_;
  $arg = {} unless $arg;
  my $truncate = $arg->{truncate} || 'right';

  croak "invalid value for truncate argument: $truncate"
    unless my $elider = $elider_for{ $truncate };

  # hey, this might be really easy:
  return $string if length($string) <= $length;

  my $marker = defined $arg->{marker} ? $arg->{marker} : '...';
  my $at_space = defined $arg->{at_space} ? $arg->{at_space} : 0;
  
  return $elider->($string, $length, $marker, $at_space);
}
  
# =func trunc
#
#   trunc($string, $length, \%arg)
#
# This acts just like C<elide>, but assumes an empty marker, so it actually
# truncates the string normally.
#
# =cut

sub trunc {
  my ($string, $length, $arg) = @_;
  $arg = {} unless $arg;

  croak "marker may not be passed to trunc()" if exists $arg->{marker};
  $arg->{marker} = q{};

  return elide($string, $length, $arg);
}

# =head1 IMPORTING
#
# String::Truncate exports both C<elide> and C<trunc>, and also supports the
# Exporter-style ":all" tag.
#
#   use String::Truncate ();        # export nothing
#   use String::Truncate qw(elide); # export just elide()
#   use String::Truncate qw(:all);  # export both elide() and trunc()
#   use String::Truncate qw(-all);  # export both elide() and trunc()
#
# When exporting, you may also supply default values:
#
#   use String::Truncate -all => defaults => { length => 10, marker => '--' };
#
#   # or
#
#   use String::Truncate -all => { length => 10, marker => '--' };
#
# These values affect only the imported version of the functions.  You may pass
# arguments as usual to override them, and you may call the subroutine by its
# fully-qualified name to get the standard behavior.
#
# =cut

use Sub::Exporter::Util ();
use Sub::Exporter 0.953 -setup => {
  exports => {
    Sub::Exporter::Util::merge_col(defaults => {
      trunc => sub { trunc_with_defaults($_[2]) },
      elide => sub { elide_with_defaults($_[2]) },
    })
  },
  collectors => [ qw(defaults) ]
};

# =head1 BUILDING CODEREFS
#
# The imported builds and installs lexical closures (code references) that merge
# in given values to the defaults.  You can build your own closures without
# importing them into your namespace.  To do this, use the C<elide_with_defaults>
# and C<trunc_with_defaults> routines.
#
# =head2 elide_with_defaults
#
#   my $elider = String::Truncate::elide_with_defaults(\%arg);
#
# This routine, never exported, builds a coderef which behaves like C<elide>, but
# uses default values when needed.  All the valid arguments to C<elide> are valid
# here, as well as C<length>.
#
# =cut

sub _code_with_defaults {
  my ($code, $skip_defaults) = @_;
  
  sub {
    my $defaults = shift || {};
    my %defaults = %$defaults;
    delete $defaults{$_} for @$skip_defaults;

    my $length = delete $defaults{length};

    sub {
      my $string = $_[0];
      my $length = defined $_[1] ? $_[1] : $length;
      my $arg = { %defaults, (defined $_[2] ? %{ $_[2] } : ()) };

      return $code->($string, $length, $arg);
    }
  }
}

BEGIN {
  install_sub({
    code => _code_with_defaults(\&elide),
    as   => 'elide_with_defaults',
  });
}

# =head2 trunc_with_defaults
#
# This routine behaves exactly like elide_with_defaults, with one obvious
# exception: it returns code that works like C<trunc> rather than C<elide>.  If a
# C<marker> argument is passed, it is ignored.
#
# =cut

BEGIN {
  install_sub({
    code => _code_with_defaults(\&trunc, ['marker']),
    as   => 'trunc_with_defaults',
  });
}

# =head1 SEE ALSO
#
# L<Text::Truncate> does a very similar thing.  So does L<Text::Elide>.
#
# =head1 BUGS
#
# Please report any bugs or feature requests through the web interface at
# L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Truncate>.  I will be
# notified, and then you'll automatically be notified of progress on your bug as
# I make changes.
#
# =head1 ACKNOWLEDGEMENTS
#
# Ian Langworth gave me some good advice about naming things.  (Also some bad
# jokes.  Nobody wants String::ETOOLONG, Ian.)  Hans Dieter Pearcey suggested
# allowing defaults just in time for a long bus ride, and I was rescued from
# boredom by that suggestion
#
# =cut

1; # End of String::Truncate

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Truncate - a module for when strings are too long to be displayed in...

=head1 VERSION

version 1.100602

=head1 SYNOPSIS

This module handles the simple but common problem of long strings and finite
terminal width.  It can convert:

 "this is your brain" -> "this is your ..."
                      or "...is your brain"
                      or "this is... brain"
                      or "... is your b..."

It's simple:

 use String::Truncate qw(elide);

 my $brain = "this is your brain";

 elide($brain, 16); # first option
 elide($brain, 16, { truncate => 'left' });   # second option
 elide($brain, 16, { truncate => 'middle' }); # third option
 elide($brain, 16, { truncate => 'ends' });   # fourth option

 String::Trunc::trunc($brain, 16); # => "this is your bra"

=head1 FUNCTIONS

=head2 elide

  elide($string, $length, \%arg)

This function returns the string, if it is less than or equal to C<$length>
characters long.  If it is longer, it truncates the string and marks the
elision.

Valid arguments are:

 truncate - elide at left, right, middle, or ends? (default: right)
 marker   - how to mark the elision (default: ...)
 at_space - if true, strings will be broken at whitespace if possible

=head2 trunc

  trunc($string, $length, \%arg)

This acts just like C<elide>, but assumes an empty marker, so it actually
truncates the string normally.

=head1 IMPORTING

String::Truncate exports both C<elide> and C<trunc>, and also supports the
Exporter-style ":all" tag.

  use String::Truncate ();        # export nothing
  use String::Truncate qw(elide); # export just elide()
  use String::Truncate qw(:all);  # export both elide() and trunc()
  use String::Truncate qw(-all);  # export both elide() and trunc()

When exporting, you may also supply default values:

  use String::Truncate -all => defaults => { length => 10, marker => '--' };

  # or

  use String::Truncate -all => { length => 10, marker => '--' };

These values affect only the imported version of the functions.  You may pass
arguments as usual to override them, and you may call the subroutine by its
fully-qualified name to get the standard behavior.

=head1 BUILDING CODEREFS

The imported builds and installs lexical closures (code references) that merge
in given values to the defaults.  You can build your own closures without
importing them into your namespace.  To do this, use the C<elide_with_defaults>
and C<trunc_with_defaults> routines.

=head2 elide_with_defaults

  my $elider = String::Truncate::elide_with_defaults(\%arg);

This routine, never exported, builds a coderef which behaves like C<elide>, but
uses default values when needed.  All the valid arguments to C<elide> are valid
here, as well as C<length>.

=head2 trunc_with_defaults

This routine behaves exactly like elide_with_defaults, with one obvious
exception: it returns code that works like C<trunc> rather than C<elide>.  If a
C<marker> argument is passed, it is ignored.

=head1 SEE ALSO

L<Text::Truncate> does a very similar thing.  So does L<Text::Elide>.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Truncate>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

Ian Langworth gave me some good advice about naming things.  (Also some bad
jokes.  Nobody wants String::ETOOLONG, Ian.)  Hans Dieter Pearcey suggested
allowing defaults just in time for a long bus ride, and I was rescued from
boredom by that suggestion

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
