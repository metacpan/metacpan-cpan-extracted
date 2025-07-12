package URI::VersionRange::Constraint;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp     ();
use Exporter qw(import);

use overload '""' => 'to_string', fallback => 1;

use URI::VersionRange::Version;

our $VERSION = '2.23';

our %COMPARATOR = (
    '='  => 'equal',
    '<'  => 'less than',
    '<=' => 'less than or equal',
    '>'  => 'greater than',
    '>=' => 'greater than or equal',
);

sub new {

    my ($class, %params) = @_;

    my $comparator = delete $params{comparator} // '=';
    my $version    = delete $params{version};

    my $self = {comparator => $comparator, version => $version};

    return bless $self, $class;
}

sub version    { shift->{version} }
sub comparator { shift->{comparator} }

sub from_string {

    my ($class, $string) = @_;

    Carp::croak 'Empty version' unless $string;

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

    if ($string =~ /^(>=|<=|!=|<|>)(.*)/) {
        my ($comparator, $version) = ($1, $2);
        return $class->new(comparator => $comparator, version => $version);
    }

    return $class->new(comparator => '*') if ($string eq '*');

    return $class->new(comparator => '=', version => $string);

}

sub to_string {

    my $self = shift;

    return '*' if $self->comparator eq '*';

    return $self->version if $self->comparator eq '=';

    return join '', $self->comparator, $self->version;

}

sub to_human_string { sprintf '%s %s', $COMPARATOR{$_[0]->comparator}, $_[0]->version }

sub TO_JSON { {version => $_[0]->version, comparator => $_[0]->comparator} }

1;

__END__
=head1 NAME

URI::VersionRange::Constraint - Version Constraint for Version Range Specification

=head1 SYNOPSIS

  use URI::VersionRange::Constraint;

  # OO-interface

  $constraint = URI::VersionRange::Constraint->new(
    comparator => '>',
    version    => '2.00'
  );
  
  say $constraint; # >2.00

  # Parse "vers" string
  $constraint = URI::VersionRange::Constraint->from_string('>2.00');


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


=head2 OBJECT-ORIENTED INTERFACE

=over

=item $constraint = URI::VersionRange::Constraint->new( comparator => STRING, version => STRING )

Create new B<URI::VersionRange::Constraint> instance.

=item $constraint->comparator

Return the comparator.

=item $constraint->version

Return the version string.

=item $vers->to_string

Stringify C<vers> components.

=item $vers->to_human_string

Convert the constraint into human-readable format.

    $constraint = URI::VersionRange::Constraint->new(
        comparator => '>=',
        version    => '2.10'
    );

    say $constraint->to_human_string; # greater than or equal 2.10

=item $vers->TO_JSON

Helper method for JSON modules (L<JSON>, L<JSON::PP>, L<JSON::XS>, L<Mojo::JSON>, etc).

    use Mojo::JSON qw(encode_json);

    say encode_json($constraint);  # {"comparator":">","version":"2.00"}

=item $vers = URI::VersionRange::Constraint->from_string($vers_string);

Converts the given "constraint" string to L<URI::VersionRange::Constraint> object. Croaks on error.

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

This software is copyright (c) 2022-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
