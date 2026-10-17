package URI::VersionRange::Version;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp ();

use URI::VersionRange::Util qw(generic_version_compare);

use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

use constant DEBUG => $ENV{VERS_DEBUG};

our $VERSION = '2.26';

sub load {

    my ($class, $scheme) = @_;

    $scheme = lc($scheme // '');

    my @CLASSES = ();

    (my $name = $scheme) =~ tr/.-/__/;
    if (($name) = $name =~ /\A([a-z][a-z0-9_]*)\z/) {
        push @CLASSES, "URI::VersionRange::Scheme::$name";     # Scheme specific
        push @CLASSES, "URI::VersionRange::Version::$name";    # Scheme specific (legacy naming convention)
    }

    push @CLASSES, 'URI::VersionRange::Scheme::generic';       # Fallback
    push @CLASSES, 'URI::VersionRange::Version::generic';      # Fallback

    foreach my $version_class (@CLASSES) {
        if ($version_class->can('new') or _require_class($version_class)) {
            DEBUG and say STDERR "-- Loaded '$version_class' class";
            return $version_class;
        }
    }

    return $class;

}

sub _require_class {

    my $version_class = shift;

    (my $file = "$version_class.pm") =~ s{::}{/}g;

    return 1 if eval { require $file; 1 };

    Carp::croak "Failed to load '$version_class' comparator class: $@" if $@ !~ /^Can't locate \Q$file\E in \@INC/;
    return;

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

# SemVer

package    # hide from pause
    URI::VersionRange::Scheme::semver {
    use parent 'URI::VersionRange::Version';

    use URI::VersionRange::Util qw(semver_version_compare);
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return semver_version_compare($left->[0], $right->[0]);
    }
}

# NPM

package    # hide from pause
    URI::VersionRange::Scheme::npm {
    use parent -norequire, 'URI::VersionRange::Scheme::semver';
}

# intdot

package    # hide from pause
    URI::VersionRange::Scheme::intdot {
    use parent 'URI::VersionRange::Version';

    use URI::VersionRange::Util qw(intdot_version_compare);
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return intdot_version_compare($left->[0], $right->[0]);
    }
}

# lexicographic

package    # hide from pause
    URI::VersionRange::Scheme::lexicographic {
    use parent 'URI::VersionRange::Version';

    use URI::VersionRange::Util qw(lexicographic_version_compare);
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return lexicographic_version_compare($left->[0], $right->[0]);
    }
}

# datetime

package    # hide from pause
    URI::VersionRange::Scheme::datetime {
    use parent 'URI::VersionRange::Version';

    use URI::VersionRange::Util qw(datetime_version_compare);
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return datetime_version_compare($left->[0], $right->[0]);
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

The version comparator is provided by the scheme class (see L</HOW TO CREATE A NEW SCHEME COMPARATOR CLASS>)
and it's used by L<URI::VersionRange> for C<contains> and for sorting the constraints in C<to_string>.

=head2 BUNDLED SCHEME COMPARATORS

=over 2

=item * C<cpan> - L<version> module

=item * C<semver> - Semantic Versioning 2.0.0 (L<https://semver.org>)

=item * C<npm> - Same as C<semver>

=item * C<datetime> - RFC 3339 timestamp (leap second C<60> is not supported)

=item * C<intdot> - Integers separated by dots (eg. C<10.234.5.12>)

=item * C<lexicographic> - Byte-wise comparison of the UTF-8 encoded versions

=back

For all other schemes the generic comparator is used (see C<generic_version_compare>
in L<URI::VersionRange::Util>).


=head2 OBJECT-ORIENTED INTERFACE

=head3 B<new>

    $v = URI::VersionRange::Version->new( $value )

Create new B<URI::VersionRange::Version> instance using provided version C<value>.

=head3 B<compare>

    $v->compare

Compare the version

=head3 B<from_native>

    $vers_string = $class->from_native( $native_range, $scheme )

Convert the native range of the scheme into a VERS string (optional).

If implemented in the scheme class, this method is used by C<< URI::VersionRange->from_native >>
instead of C<native_range_to_vers> (see L<URI::VersionRange::Util>).

=head3 B<load>

    $class = URI::VersionRange::Version->load( $scheme )

Load scheme class.

The class name is built using the C<scheme>, replacing period C<.> and dash C<->
with underscore C<_> (eg. C<foo-bar> --> C<URI::VersionRange::Scheme::foo_bar>).

This method will attempt to load the classes in this order:

=over 2

=item * C<< URI::VersionRange::Scheme::<scheme> >>

=item * C<< URI::VersionRange::Version::<scheme> >> (legacy naming convention)

=item * C<URI::VersionRange::Scheme::generic> (fallback)

=item * C<URI::VersionRange::Version::generic> (fallback)

=back

If no class is found, the generic comparator of L<URI::VersionRange::Version>
will be used.

Croaks if the scheme class exists but fails to load (eg. syntax error or
missing dependency).


=head2 HOW TO CREATE A NEW SCHEME COMPARATOR CLASS

=over 2

=item * Create a new package using the naming convention C<< URI::VersionRange::Scheme::<scheme> >>
by extending L<URI::VersionRange::Version> (period C<.> and dash C<-> in the scheme
must be replaced with underscore C<_>).

=item * Implements the C<compare($left, $right)> subroutine with the algorithm required
by the C<scheme>.

C<$left> and C<$right> arguments of C<compare> are C<ARRAY> and have as their
first element the value of the version to be compared.

=item * L<overload> C<< '<=>' >> and C<cmp> operators using C<compare> subroutine (MANDATORY)

=item * Implement the C<from_native($class, $native_range, $scheme)> subroutine to convert the
native range of the scheme into a VERS string (optional)

=back


This is an example that implements a comparator for the C<generic> fallback scheme
using L<Version::libversion::XS> module:

  package URI::VersionRange::Scheme::generic {

      use Version::libversion::XS qw(version_compare2);

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
