package URI::VersionRange;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp       ();
use List::Util qw(first);
use Exporter   qw(import);

use URI::VersionRange::Constraint;
use URI::VersionRange::Version;

use constant DEBUG => $ENV{VERS_DEBUG};
use constant TRUE  => !!1;
use constant FALSE => !!0;

use overload '""' => 'to_string', fallback => 1;

our $VERSION = '2.20';
our @EXPORT  = qw(encode_vers decode_vers);

my $VERS_REGEXP = qr{^vers:[a-z\\.\\-\\+][a-z0-9\\.\\-\\+]*/.+};

sub new {

    my ($class, %params) = @_;

    my $scheme      = delete $params{scheme}      or Carp::croak "Invalid Version Range: 'scheme' is required";
    my $constraints = delete $params{constraints} or Carp::croak "Invalid Version Range: 'constraints' is required";

    my @constraints = ();

    foreach my $constraint (@{$constraints}) {

        if (ref($constraint) ne 'URI::VersionRange::Constraint') {
            $constraint = URI::VersionRange::Constraint->from_string($constraint);
        }

        push @constraints, $constraint;

    }

    my $self = {
        scheme         => lc($scheme),
        constraints    => \@constraints,
        _version_class => _load_version_class_from_scheme(lc($scheme))
    };

    return bless $self, $class;

}

sub _load_version_class_from_scheme {

    my $scheme = shift;

    my @CLASSES = (
        join('::', 'URI::VersionRange::Version', lc($scheme)),    # Schema specific
        'URI::VersionRange::Version::generic',                    # Generic or used-defined class
        'URI::VersionRange::Version'                              # Fallback class
    );

    my $loaded_version_class = undef;

VERSION_CLASS:
    foreach my $version_class (@CLASSES) {

        if ($version_class->can('new') or eval "require $version_class; 1") {
            $loaded_version_class = $version_class;
            last VERSION_CLASS;
        }

        DEBUG and say STDERR "-- (E) Failed to load '$version_class' class for '$scheme' scheme ... try next class"
            if $@;

    }

    DEBUG and say STDERR "-- Loaded '$loaded_version_class' class for '$scheme' scheme";

    return $loaded_version_class;

}

sub scheme      { shift->{scheme} }
sub constraints { shift->{constraints} }

sub encode_vers { __PACKAGE__->new(@_)->to_string }
sub decode_vers { __PACKAGE__->from_string(shift) }

sub from_string {

    my ($class, $string) = @_;

    if ($string !~ /$VERS_REGEXP/) {
        Carp::croak 'Malformed Version Range string';
    }

    my %params = ();

    # - Remove all spaces and tabs.
    # - Start from left, and split once on colon ":".
    # - The left hand side is the URI-scheme that must be lowercase.
    #       Tools must validate that the URI-scheme value is vers.
    # - The right hand side is the specifier.

    $string =~ s/(\s|\t)+//g;

    my @s1 = split(':', $string);

    # $params{uri_scheme} = lc $s1[0];

    # - Split the specifier from left once on a slash "/".
    # - The left hand side is the <versioning-scheme> that must be lowercase. Tools
    #   should validate that the <versioning-scheme> is a known scheme.
    # - The right hand side is a list of one or more constraints. Tools must validate
    #   that this constraints string is not empty ignoring spaces.

    my @s2 = split('/', $s1[1]);
    $params{scheme} = lc $s2[0];

    # - If the constraints string is equal to "", the ``<version-constraint>``
    #   is "". Parsing is done and no further processing is needed for this vers.
    #   A tool should report an error if there are extra characters beyond "*".
    # - Strip leading and trailing pipes "|" from the constraints string.
    # - Split the constraints on pipe "|". The result is a list of <version-constraint>.
    #   Consecutive pipes must be treated as one and leading and trailing pipes ignored.

    $s2[1] =~ s/(^\|)|(\|$)//g;

    my @s3 = split(/\|/, $s2[1]);
    $params{constraints} = [];

    # - For each <version-constraint>:
    #   - Determine if the <version-constraint> starts with one of the two comparators:
    #     - If it starts with ">=", then the comparator is ">=".
    #     - If it starts with "<=", then the comparator is "<=".
    #     - If it starts with "!=", then the comparator is "!=".
    #     - If it starts with "<", then the comparator is "<".
    #     - If it starts with ">", then the comparator is ">".
    #     - Remove the comparator from <version-constraint> string start. The remaining string is the version.
    #   - Otherwise the version is the full <version-constraint> string (which implies an equality comparator of "=")
    #   - Tools should validate and report an error if the version is empty.
    #   - If the version contains a percent "%" character, apply URL quoting rules to unquote this string.
    #   - Append the parsed (comparator, version) to the constraints list.

    foreach (@s3) {
        push @{$params{constraints}}, URI::VersionRange::Constraint->from_string($_);
    }

    if (DEBUG) {
        say STDERR "-- S1: @s1";
        say STDERR "-- S2: @s2";
        say STDERR "-- S3: @s3";
    }

    return $class->new(%params);

}

sub to_string {
    return join '', 'vers:', $_[0]->scheme, '/', join('|', @{$_[0]->constraints});
}

sub constraint_contains {

    my ($self, $constraint, $version) = @_;

    return TRUE if $constraint->comparator eq '*';

    my $version_class = $self->{_version_class};

    my $v1 = $version_class->parse($version);
    my $v2 = $version_class->parse($constraint->version);

    return ($v1 == $v2) if ($constraint->comparator eq '=');
    return ($v1 != $v2) if ($constraint->comparator eq '!=');
    return ($v1 <= $v2) if ($constraint->comparator eq '<=');
    return ($v1 >= $v2) if ($constraint->comparator eq '>=');
    return ($v1 > $v2)  if ($constraint->comparator eq '<');
    return ($v1 < $v2)  if ($constraint->comparator eq '>');

    return FALSE;

}

sub contains {

    my ($self, $version) = @_;

    my @first  = ();
    my @second = ();

    my $version_class = $self->{_version_class};

    if (scalar @{$self->constraints} == 1) {
        return $self->constraint_contains($self->constraints->[0], $version);
    }

    foreach my $constraint (@{$self->constraints}) {

        # If the "tested version" is equal to the any of the constraint version
        # where the constraint comparator is for equality (any of "=", "<=", or ">=")
        # then the "tested version" is in the range. Check is finished.

        return TRUE
            if ((first { $constraint->comparator eq $_ } ('=', '<=', '>='))
            && ($version_class->parse($version) == $version_class->parse($constraint->version)));

        # If the "tested version" is equal to the any of the constraint version
        # where the constraint comparator is "=!" then the "tested version" is NOT
        # in the range. Check is finished.

        return FALSE
            if ($constraint->comparator eq '!='
            && ($version_class->parse($version) == $version_class->parse($constraint->version)));

        # Split the constraint list in two sub lists:
        #    a first list where the comparator is "=" or "!="
        #    a second list where the comparator is neither "=" nor "!="

        push @first,  $constraint if ((first { $constraint->comparator eq $_ } ('=',  '!=')));
        push @second, $constraint if (!(first { $constraint->comparator eq $_ } ('=', '!=')));

    }

    return FALSE unless @second;

    if (scalar @second == 1) {
        return $self->constraint_contains($second[0], $version);
    }

    # Iterate over the current and next contiguous constraints pairs (aka. pairwise)
    # in the second list.

    # For each current and next constraint:

    my $is_first_iteration = TRUE;

    my $current_constraint = undef;
    my $next_constraint    = undef;

    foreach (_pairwise(@second)) {

        ($current_constraint, $next_constraint) = @{$_};

        DEBUG and say STDERR sprintf '-- Current constraint -->  %s', $current_constraint;
        DEBUG and say STDERR sprintf '-- Next constraint    -->  %s', $next_constraint;

        # If this is the first iteration and current comparator is "<" or <=" and
        # the "tested version" is less than the current version then the "tested
        # version" is IN the range. Check is finished.

        if ($is_first_iteration) {

            return TRUE
                if ((first { $current_constraint->comparator eq $_ } ('<=', '<'))
                && ($version_class->parse($version) < $version_class->parse($current_constraint->version)));

            $is_first_iteration = FALSE;

        }

        # If current comparator is ">" or >=" and next comparator is "<" or <="
        # and the "tested version" is greater than the current version and the
        # "tested version" is less than the next version then the "tested version"
        # is IN the range. Check is finished.

        if (   (first { $current_constraint->comparator eq $_ } ('>', '>='))
            && (first { $next_constraint->comparator eq $_ } ('<', '<='))
            && ($version_class->parse($version) > $version_class->parse($current_constraint->version))
            && ($version_class->parse($version) < $version_class->parse($next_constraint->version)))
        {
            return TRUE;
        }

        # If current comparator is "<" or <=" and next comparator is ">" or >="
        # then these versions are out the range. Continue to the next iteration.

        elsif ((first { $current_constraint->comparator eq $_ } ('<', '<='))
            && (first { $next_constraint->comparator } ('>', '>=')))
        {
            next;
        }

    }

    # If this is the last iteration and next comparator is ">" or >=" and the
    # "tested version" is greater than the next version then the "tested version"
    # is IN the range. Check is finished.

    return TRUE
        if ((first { $next_constraint->comparator eq $_ } ('>', '>='))
        && ($version_class->parse($version) > $version_class->parse($next_constraint->version)));

    return FALSE;

}

sub TO_JSON {
    return {scheme => $_[0]->scheme, constraints => $_[0]->constraints};
}

sub _pairwise {

    my @out = ();

    for (my $i = 0; $i < scalar @_; $i++) {
        push @out, [$_[$i], $_[$i + 1]] if $_[$i + 1];
    }

    return @out;

}

1;

__END__
=head1 NAME

URI::VersionRange - Perl extension for Version Range Specification

=head1 SYNOPSIS

  use URI::VersionRange;

  # OO-interface

  $vers = URI::VersionRange->new(
    scheme      => 'cpan',
    constraints => ['>2.00']
  );
  
  say $vers; # vers:cpan/>2.00

  if ($vers->contains('2.10')) {
    say "The version is in range";
  }

  # Parse "vers" string
  $vers = URI::VersionRange->from_string('vers:cpan/>2.00|<2.20');

  # exported functions

  $vers = decode_vers('vers:cpan/>2.00|<2.20');
  say $vers->scheme;  # cpan

  $vers_string = encode_vers(scheme => cpan, constraints => ['>2.00']);
  say $vers_string; # vers:cpan/>2.00


=head1 DESCRIPTION

A version range specifier (aka. "vers") is a URI string using the C<vers> URI-scheme with this syntax:

  vers:<versioning-scheme>/<version-constraint>|<version-constraint>|...

C<vers> is the URI-scheme and is an acronym for "VErsion Range Specifier".

The pipe "|" is used as a simple separator between C<version-constraint>.
Each C<version-constraint> in this pipe-separated list contains a comparator and a version:

  <comparator:version>

This list of C<version-constraint> are signposts in the version timeline of a package
that specify version intervals.

A C<version> satisfies a version range specifier if it is contained within any
of the intervals defined by these C<version-constraint>.

L<https://github.com/package-url/purl-spec>


=head2 FUNCTIONAL INTERFACE

They are exported by default:

=over

=item $vers_string = encode_vers(%params);

Converts the given C<vers> components to "vers" string. Croaks on error.

This function call is functionally identical to:

    $vers_string = URI::VersionRange->new(%params)->to_string;

=item $vers = decode_vers($vers_string);

Converts the given "vers" string to L<URI::VersionRange> object. Croaks on error.

This function call is functionally identical to:

    $vers = URI::VersionRange->from_string($vers_string);

=back

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $vers = URI::VersionRange->new( scheme => STRING, constraints -> ARRAY )

Create new B<URI::Version> instance using provided C<vers> components
(scheme, constraints).

=item $vers->scheme

By convention the versioning scheme should be the same as the L<URI::PackageURL>
package C<type> for a given package ecosystem.

=item $vers->constraints

C<constraints> is ARRAY of L<URI::VersionRange::Constraint> object.

=item $vers->contains($version)

Check if a version is contained within a range

    my $vers = URI::VersionRange::from_string('vers:cpan/>2.00|<2.20');

    if ($vers->contains('2.10')) {
        say "The version is in range";
    }

See L<URI::VersionRange::Version>.

=item $vers->constraint_contains

Check if a version is contained within a specific constraint.

See L<URI::VersionRange::Version>.

=item $vers->to_string

Stringify C<vers> components.

=item $vers->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

    use Mojo::JSON qw(encode_json);

    say encode_json($vers);  # {"constraints":[{"comparator":">","version":"2.00"},{"comparator":"<","version":"2.20"}],"scheme":"cpan"}

=item $vers = URI::VersionRange->from_string($vers_string);

Converts the given "vers" string to L<URI::VersionRange> object. Croaks on error.

=back


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

This software is copyright (c) 2022-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
