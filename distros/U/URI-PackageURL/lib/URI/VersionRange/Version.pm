package URI::VersionRange::Version;

use feature ':5.10';
use strict;
use utf8;
use warnings;
use version ();
use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

sub new     { my $class = shift; bless [@_], $class }
sub compare { (version->parse($_[0]->[0]) <=> version->parse($_[1]->[0])) }

*parse = \&new;


package    # hide from pause
    URI::VersionRange::Version::cpan;
use parent 'URI::VersionRange::Version';

1;

__END__
=head1 NAME

URI::VersionRange::Version - Version comparator class

=head1 SYNOPSIS

  package URI::VersionRange::Version::generic {

      use Version::libversion::XS qw(version_compare2);

      use parent 'URI::VersionRange::Version';
      use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

      sub compare {
          my ($left, $right) = @_;
          return version_compare2($left->[0], $right->[0]);
      }

  }

  my $vers = URI::VersionRange->from_string('vers:generic/>v1.00|!=v2.10|<=v3.00');

  if ($vers->contains('v2.50')) {
    # do stuff
  }


=head1 DESCRIPTION

This is a base class for the version comparator.

NOTE: L<URI::VersionRange> provide out-of-the-box C<cpan> type comparator.


=head2 OBJECT-ORIENTED INTERFACE

=over

=item $v = URI::VersionRange::Version->new( $value )

Create new B<URI::VersionRange::Version> instance using provided version C<value>.

=item $v->compare

Compare the version

=back

=head2 HOW TO CREATE A NEW VERSION COMPARATOR

=over

=item * Create a new package using the naming convention C<< URI::VersionRange::Version::<scheme> >>
by extending L<URI::VersionRange::Version>.

=item * Implements the C<compare($left, $right)> subroutine with the algorithm required
by the C<scheme>.

C<$left> and C<$right> arguments of C<compare> are C<ARRAY> and have as their
first element the value of the version to be compared.

=item * L<overload> C<< '<=>' >> and C<cmp> operators using C<compare> subroutine (MANDATORY)

=back


This is an example that implements a comparator for the C<generic> scheme using
L<Version::libversion::XS> module:

  package URI::VersionRange::Version::generic {

      use Version::libversion::XS;

      use parent 'URI::VersionRange::Version';
      use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

      sub compare {
          my ($left, $right) = @_;
          return version_compare2($left->[0], $right->[0]);
      }

  }

This is an another example for the C<rpm> scheme using L<RPM4> module:

  package URI::VersionRange::Version::rpm {

      use RPM4;

      use parent 'URI::VersionRange::Version';
      use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

      sub compare {
          my ($left, $right) = @_;
          return rpmvercmp($left->[0], $right->[0]);
      }

  }


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-URI-PackageURL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-URI-PackageURL>

    git clone https://github.com/giterlizzi/perl-URI-PackageURL.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
