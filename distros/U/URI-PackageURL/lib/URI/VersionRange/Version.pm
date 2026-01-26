package URI::VersionRange::Version;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use URI::VersionRange::Util qw(generic_version_compare);

use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

use constant DEBUG => $ENV{VERS_DEBUG};

our $VERSION = '2.24';

sub load {

    my ($class, $scheme) = @_;

    $scheme = lc $scheme;

    my @CLASSES = (
        join('::', 'URI::VersionRange::Scheme',  lc($scheme)),    # Scheme specific
        join('::', 'URI::VersionRange::Version', lc($scheme)),    # Scheme specific (legacy naming convention)
    );

    foreach my $version_class (@CLASSES) {

        if ($version_class->can('new') or eval "require $version_class; 1") {
            DEBUG and say STDERR "-- Loaded '$version_class' class";
            return $version_class;
        }

        DEBUG and say STDERR "-- (E) Failed to load '$version_class' class: $@" if $@;

    }

    return $class;

}

sub new { my $class = shift; bless [@_], $class }

sub scheme {
    return (split(/\:\:/, shift, 4))[3];
}

sub compare {
    my ($left, $right) = @_;
    return generic_version_compare($left->[0], $right->[0]);
}

# CPAN

package    # hide from pause
    URI::VersionRange::Scheme::cpan {
    use parent 'URI::VersionRange::Version';

    use version();
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return (version->parse($left->[0]) <=> version->parse($right->[0]));
    }
}

# PyPi

package    # hide from pause
    URI::VersionRange::Scheme::pypi {
    use parent 'URI::VersionRange::Version';

    use version();
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return (version->parse($left->[0]) <=> version->parse($right->[0]));
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

URI::VersionRange::Version - Version scheme helper class

=head1 SYNOPSIS

  package URI::VersionRange::Scheme::generic {

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

This is a base class for the version scheme helper.


=head2 OBJECT-ORIENTED INTERFACE

=head3 B<new>

    $v = URI::VersionRange::Version->new( $value )

Create new B<URI::VersionRange::Version> instance using provided version C<value>.

=head3 B<compare>

    $v->compare

Compare the version

=head3 B<from_native>

    $v->from_native( $native_range )

Convert the native range of the scheme into a VERS string


=head2 HOW TO CREATE A NEW SCHEME COMPARATOR CLASS

=over 2

=item * Create a new package using the naming convention C<< URI::VersionRange::Scheme::<scheme> >>
by extending L<URI::VersionRange::Version>.

=item * Implements the C<compare($left, $right)> subroutine with the algorithm required
by the C<scheme>.

C<$left> and C<$right> arguments of C<compare> are C<ARRAY> and have as their
first element the value of the version to be compared.

=item * L<overload> C<< '<=>' >> and C<cmp> operators using C<compare> subroutine (MANDATORY)

=item * Implement the C<from_native($self, $native)> subroutine to convert the
native range of the scheme into a VERS string

=back


This is an example that implements a comparator for the C<generic> scheme using
L<Version::libversion::XS> module:

  package URI::VersionRange::Scheme::generic {

      use Version::libversion::XS;

      use parent 'URI::VersionRange::Version';
      use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

      sub compare {
          my ($left, $right) = @_;
          return version_compare2($left->[0], $right->[0]);
      }

  }

This is an another example for the C<rpm> scheme using L<RPM4> module:

  package URI::VersionRange::Scheme::rpm {

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

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
