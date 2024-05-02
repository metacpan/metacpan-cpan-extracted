package Version::libversion::XS;

use feature ':5.10';
use strict;
use utf8;
use warnings;

require Exporter;
require XSLoader;
our @ISA = qw(Exporter);

our @EXPORT = qw(
    version_compare
    version_compare2
    version_compare4
);

our @EXPORT_OK = qw(
    VERSIONFLAG_P_IS_PATCH
    VERSIONFLAG_ANY_IS_PATCH
    VERSIONFLAG_LOWER_BOUND
    VERSIONFLAG_UPPER_BOUND

    P_IS_PATCH
    ANY_IS_PATCH
    LOWER_BOUND
    UPPER_BOUND

    LIBVERSION_VERSION
);

our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

our $VERSION = '1.00';

use overload ('""' => \&value, cmp => \&cmp, '<=>' => \&cmp, fallback => 1);

XSLoader::load(__PACKAGE__, $VERSION);

sub new {

    my ($class, $value, $flags) = @_;
    my $self = {value => $value, flags => $flags};

    return bless $self, $class;

}

*parse = \&new;

sub value { shift->{value} }
sub flags { shift->{flags} }

sub cmp {

    my ($left, $right) = @_;

    unless (ref($right)) {
        $right = __PACKAGE__->new($right);
    }

    return version_compare($left->value, $right->value, ($left->flags || 0), ($right->flags || 0));

}

1;
__END__
=head1 NAME

Version::libversion::XS - Perl binding for libversion

=head1 SYNOPSIS

  use Version::libversion::XS;

  # OO-interface

  if ( Version::libversion::XS->new($v1) == Version::libversion::XS->new($v2) ) {
      # do stuff
  }

  # Sorting mixed version styles

  @ordered = sort { Version::libversion::XS->new($a) <=> Version::libversion::XS->new($b) } @list;


  # Functional interface

  use Version::libversion::XS ':all';

  say '0.99 < 1.11' if(version_compare2('0.99', '1.11') == -1);

  say '1.0 == 1.0.0' if(version_compare2('1.0', '1.0.0') == 0);

  say '1.0alpha1 < 1.0.rc1' if(version_compare2('1.0alpha1', '1.0.rc1') == -1);

  say '1.0 > 1.0.rc1' if(version_compare2('1.0', '1.0-rc1') == 1);

  say '1.2.3alpha4 is the same as 1.2.3~a4' if(version_compare2('1.2.3alpha4', '1.2.3~a4') == 0);

  # by default, 'p' is treated as 'pre' ...
  say '1.0p1 == 1.0pre1'  if(version_compare2('1.0p1', '1.0pre1') == 0);
  say '1.0p1 < 1.0post1'  if(version_compare2('1.0p1', '1.0post1') == -1);
  say '1.0p1 < 1.0patch1' if(version_compare2('1.0p1', '1.0patch1') == -1);

  # ... but this is tunable: here it's handled as 'patch'
  say '1.0p1 > 1.0pre1'    if(version_compare4('1.0p1', '1.0pre1', VERSIONFLAG_P_IS_PATCH, 0) == 1);
  say '1.0p1 == 1.0post1'  if(version_compare4('1.0p1', '1.0post1', VERSIONFLAG_P_IS_PATCH, 0) == 0);
  say '1.0p1 == 1.0patch1' if(version_compare4('1.0p1', '1.0patch1', VERSIONFLAG_P_IS_PATCH, 0) == 0);

  # a way to check that the version belongs to a given release
  if(
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1)
  ) {
    say '1.0alpha1 and 1.0.1 belong to 1.0 release, e.g. they lie between' .
        '(lowest possible version in 1.0) and (highest possible version in 1.0)';
  }

=head1 DESCRIPTION

Perl bindings for C<libversion>, which provides fast, powerful and correct generic
version string comparison algorithm.

See C<libversion> repository for more details on the algorithm.

L<https://github.com/repology/libversion>

=head2 FUNCTIONAL INTERFACE

They are exported by default:

=over

=item version_compare2 ( $v1, $v2 )

  say '0.99 < 1.11' if(version_compare2('0.99', '1.11') == -1);

  say '1.0 == 1.0.0' if(version_compare2('1.0', '1.0.0') == 0);

  say '1.0alpha1 < 1.0.rc1' if(version_compare2('1.0alpha1', '1.0.rc1') == -1);

  say '1.0 > 1.0.rc1' if(version_compare2('1.0', '1.0-rc1') == 1);

  say '1.2.3alpha4 is the same as 1.2.3~a4' if(version_compare2('1.2.3alpha4', '1.2.3~a4') == 0);

  # by default, 'p' is treated as 'pre' (see version_compare4)
  say '1.0p1 == 1.0pre1'  if(version_compare2('1.0p1', '1.0pre1') == 0);
  say '1.0p1 < 1.0post1'  if(version_compare2('1.0p1', '1.0post1') == -1);
  say '1.0p1 < 1.0patch1' if(version_compare2('1.0p1', '1.0patch1') == -1);

=item version_compare4 ( $v1, $v2, $v1_flags, $v2_flags )

  # Export all constants
  use Version::libversion::XS ':all';

  # by default, 'p' is treated as 'pre' but this is tunable: here it's handled as 'patch'
  say '1.0p1 > 1.0pre1' if(version_compare4('1.0p1', '1.0pre1', VERSIONFLAG_P_IS_PATCH, 0) == 1);
  say '1.0p1 == 1.0post1' if(version_compare4('1.0p1', '1.0post1', VERSIONFLAG_P_IS_PATCH, 0) == 0);
  say '1.0p1 == 1.0patch1' if(version_compare4('1.0p1', '1.0patch1', VERSIONFLAG_P_IS_PATCH, 0) == 0);

  # a way to check that the version belongs to a given release
  if(
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0alpha1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_LOWER_BOUND) == 1) &&
      (version_compare4('1.0.1', '1.0', 0, VERSIONFLAG_UPPER_BOUND) == -1)
  ) {
    say '1.0alpha1 and 1.0.1 belong to 1.0 release, e.g. they lie between' .
        '(lowest possible version in 1.0) and (highest possible version in 1.0)';
  }


=item version_compare ( $v1, $v2, [ $v1_flags, $v2_flags ] )

Alias of C<version_compare4>

=back

=head2 CONSTANTS

=over

=item LIBVERSION_VERSION

Expose libversion version

=back

Flags

=over

=item VERSIONFLAG_P_IS_PATCH

=item VERSIONFLAG_ANY_IS_PATCH

=item VERSIONFLAG_LOWER_BOUND

=item VERSIONFLAG_UPPER_BOUND

=back

Flags alias:

=over

=item P_IS_PATCH

=item ANY_IS_PATCH

=item LOWER_BOUND

=item UPPER_BOUND

=back

=head2 OBJECT-ORIENTED INTERFACE

=over

=item Version::libversion::XS->new( $version, [ $flags ])

=item $v->version

=item $v->flags

=back

=head3 How to compare version objects

C<Version::libversion::XS> objects overload the C<cmp> and C<< <=> >> operators.
Perl automatically generates all of the other comparison operators based on those
two so all the normal logical comparisons will work.

  if ( Version::libversion::XS->new($v1) == Version::libversion::XS->new($v2) ) {
    # do stuff
  }

If a version object is compared against a non-version object, the non-object
term will be converted to a version object using C<new()>.  This may give
surprising results:

  $v1 = Version::libversion::XS->new("v0.95.0");
  $bool = $v1 < 0.94; # TRUE

Always comparing to a version object will help avoid surprises:

  $bool = $v1 < Version::libversion::XS->new("v0.94.0"); # FALSE

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Version-libversion-XS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Version-libversion-XS>

    git clone https://github.com/giterlizzi/perl-Version-libversion-XS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
