package URI::VersionRange::Util;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Time::Local;
use Exporter qw(import);
use Carp     ();

our $VERSION = '2.26';

our @EXPORT = qw(
    parse_semver normalize_semver is_semver
    native_range_to_vers
    version_compare semver_version_compare generic_version_compare
    intdot_version_compare datetime_version_compare lexicographic_version_compare
);

# SemVer (https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string)
my $SEMVER_REGEXP = qr{(?x)
    ^
    (?P<major>0|[1-9]\d*)
    \.
    (?P<minor>0|[1-9]\d*)
    \.
    (?P<patch>0|[1-9]\d*)
    (?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?
    (?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?
    $
};

# RFC 3339 date-time (https://www.rfc-editor.org/rfc/rfc3339#section-5.6)
my $RFC3339_REGEXP = qr{(?x)
    ^
    (?P<year>[0-9]{4}) - (?P<month>[0-9]{2}) - (?P<day>[0-9]{2})             # full-date
    [Tt]
    (?P<hour>[0-9]{2}) : (?P<minute>[0-9]{2}) : (?P<second>[0-9]{2})         # partial-time
    (?: \. (?P<fraction>[0-9]+) )?                                           # time-secfrac
    (?:                                                                      # time-offset
        (?P<utc>[Zz])
        |
        (?P<offset_sign>[+-]) (?P<offset_hour>[0-9]{2}) : (?P<offset_minute>[0-9]{2})
    )
    $
};

sub native_range_to_vers {

    my ($scheme, $range) = @_;

    my %TYPES = (
        conan  => \&_conan_native_range,
        gem    => \&_gem_native_range,
        nginx  => \&_nginx_native_range,
        npm    => \&_semver_native_range,
        nuget  => \&_nuget_native_range,
        raku   => \&_raku_native_range,
        semver => \&_semver_native_range,
    );

    if (defined $TYPES{$scheme}) {
        return sprintf 'vers:%s/%s', $scheme, $TYPES{$scheme}->($range);
    }

    my @parts = split /\,/, $range;
    map {s{\s+}{}g} @parts;

    return sprintf 'vers:%s/%s', $scheme, join '|', sort @parts;

}

sub _nginx_native_range {

    my $native = shift;
    $native =~ s/\s+//g;

    my @plus   = ();
    my @others = ();

    my @p = split /,/, $native;

    foreach my $part (@p) {

        next unless length $part;

        # "1.0.0-1.0.1"
        if ($part =~ /^(.*?)-(.*)$/) {
            my $min = normalize_semver($1);
            my $max = normalize_semver($2);
            push @others, ">=$min|<=$max";
            next;
        }

        # "1.0.1+"
        if ($part =~ /^\s*(.*?)\+\s*$/) {
            my $version = normalize_semver($1);
            push @plus, $version if defined $version;
            next;
        }

        if (my $v = normalize_semver($part)) {
            push @others, $v;
            next;
        }

        push @others, $part;
    }

    if (@plus) {

        my %seen = ();

        # Remove duplicates and sort
        @plus = sort {

            my $A = parse_semver($a);
            my $B = parse_semver($b);

            $A->{major} <=> $B->{major} || $A->{minor} <=> $B->{minor} || $A->{patch} <=> $B->{patch}

        } grep { !$seen{$_}++ } @plus;

        # One "+"
        if (@plus == 1) {

            my $semver = parse_semver($plus[0]);
            my $upper  = join('.', $semver->{major}, $semver->{minor} + 1, 0);

            return join('|', (">=$plus[0]", "<$upper", @others));

        }

        my @parts = (">=$plus[0]");

        # Skip first plus
        for (my $i = 1; $i < @plus; $i++) {
            push @parts, "<$plus[$i]", ">=$plus[$i]";
        }

        return join('|', @parts, @others);

    }

    return join('|', grep {$_} @others);

}

sub _nuget_native_range {

    my $native = shift;

    # https://learn.microsoft.com/en-us/nuget/concepts/package-versioning

    # Notation      Applied rule    Description
    # 1.0           x ≥ 1.0         Minimum version, inclusive
    # [1.0,)        x ≥ 1.0         Minimum version, inclusive
    # (1.0,)        x > 1.0         Minimum version, exclusive
    # [1.0]         x == 1.0        Exact version match
    # (,1.0]        x ≤ 1.0         Maximum version, inclusive
    # (,1.0)        x < 1.0         Maximum version, exclusive
    # [1.0,2.0]     1.0 ≤ x ≤ 2.0   Exact range, inclusive
    # (1.0,2.0)     1.0 < x < 2.0   Exact range, exclusive
    # [1.0,2.0)     1.0 ≤ x < 2.0   Mixed inclusive minimum and exclusive maximum version
    # (1.0)         invalid         invalid

    my @parts = map {
        /^\((.*)\)$/
            ? Carp::croak 'Invalid nuget version range'    # (1.0)
            : /^\($/       ? '>0.0'                        # (
            : /^\)$/       ? ''                            # )
            : /^\[(.*)\]$/ ? $1                            # [1.0]
            : /^\[(.*)/    ? ">=$1"                        # [1.0
            : /(.*)\]$/    ? "<=$1"                        # 1.0]
            : /^\((.*)/    ? ">$1"                         # (1.0
            : /(.*)\)$/    ? "<$1"                         # 1.0)
            : $_                                           # 1.0
    } grep {$_} split /\,/, $native;

    return join('|', grep {$_} @parts);

}

sub _semver_native_range {

    my $native = shift;

    $native =~ s/^(.*)\s\-\s(.*)$/>= $1 <= $2/g;    # TODO
    $native =~ s/(>\=|<\=|>|<)\s+/$1/g;

    my @constraints = ();

    # "||" separates the ranges (union) and whitespace separates the comparators (intersection)
    foreach my $range (split /\|\|/, $native) {

        my @parts       = grep {$_} split /\s+/, $range;
        my @comparators = map  { split /\|/ } map { _semver_native_comparator($_) } @parts;

        # Intersect the comparators (eg. ">=5.0.3 >=4.2.1" --> ">=5.0.3")
        push @constraints, (@parts > 1) ? _semver_intersect(@comparators) : @comparators;

    }

    return join '|', @constraints;
}

sub _semver_native_comparator {

    my $part = shift;

    $part =~ s{v(\d+)}{$1};
    $part =~ s{^=}{};
    $part =~ s/^\s+|\s+$//g;

    # Wildcards (1.x or 2.0.x)
    if (my @wildcards = _semver_wildcards('>=', $part)) {
        return @wildcards;
    }

    # Tilde operator
    if ($part =~ /^(~)(.*)/) {
        return _tilde_operator('semver', $2);
    }

    # Caret operator
    if ($part =~ /^(\^)(.*)/) {
        return _caret_operator('semver', $2);
    }

    # Operators
    if ($part =~ /(>\=|<\=|>|<)(.*)/) {

        my ($operator, $version) = ($1, $2);

        # Wildcards (1.x or 2.0.x)
        if (my @wildcards = _semver_wildcards($operator, $version)) {
            return @wildcards;
        }

        $version = normalize_semver($version);

        if ($version and is_semver($version)) {
            return join('', $operator, $version);
        }

    }

    if ($part ne '*') {

        my $version = normalize_semver($part);

        if ($version and is_semver($version)) {
            return $version;
        }

    }

    return $part;

}

sub _semver_intersect {

    my @comparators = @_;

    my ($lower, $upper, $equal);

    foreach my $comparator (@comparators) {

        my ($operator, $version) = $comparator =~ /^(>=|<=|>|<)?(.*)$/;

        # Skip the intersection for non-SemVer versions (eg. "*")
        return @comparators unless is_semver($version);

        if (!$operator) {

            if ($equal && semver_version_compare($equal, $version) != 0) {
                Carp::croak "Invalid Version Range: '$equal' and '$version' match no version";
            }

            $equal = $version;
            next;

        }

        # Keep the highest lower bound (">" wins over ">=" for the same version)
        if ($operator =~ /^>/) {

            my $cmp = $lower ? semver_version_compare($version, $lower->[1]) : 1;
            $lower = [$operator, $version] if ($cmp > 0 || ($cmp == 0 && $operator eq '>'));
            next;

        }

        # Keep the lowest upper bound ("<" wins over "<=" for the same version)
        my $cmp = $upper ? semver_version_compare($version, $upper->[1]) : -1;
        $upper = [$operator, $version] if ($cmp < 0 || ($cmp == 0 && $operator eq '<'));

    }

    my @bounds = grep {$_} $lower, $upper;

    if ($lower && $upper) {

        my $cmp = semver_version_compare($lower->[1], $upper->[1]);

        if ($cmp > 0 || ($cmp == 0 && ($lower->[0] eq '>' || $upper->[0] eq '<'))) {
            Carp::croak sprintf "Invalid Version Range: '%s' and '%s' match no version", map { join '', @{$_} } @bounds;
        }

    }

    if ($equal) {

        foreach my $bound (@bounds) {

            my ($operator, $version) = @{$bound};
            my $cmp = semver_version_compare($equal, $version);

            my %match = ('>=' => $cmp >= 0, '>' => $cmp > 0, '<=' => $cmp <= 0, '<' => $cmp < 0);

            unless ($match{$operator}) {
                Carp::croak "Invalid Version Range: '$equal' and '$operator$version' match no version";
            }

        }

        return ($equal);

    }

    return map { join '', @{$_} } @bounds;

}

sub _conan_native_range {

    my $native = shift;

    my @p     = grep {$_} split /(?:\s+|\|\|)/, $native;
    my @parts = ();

    foreach my $part (@p) {

        $part =~ s{^=}{}g;
        $part =~ s{\-$}{}g;
        $part =~ s{\,}{}g;

        if ($part =~ /^(\*|\*\-)$/) {
            push @parts, '>=0.0.0';
            next;
        }

        if ($part =~ /^(~)(.*)/) {
            push @parts, _tilde_operator('conan', $2);
            next;
        }

        if ($part =~ /^(\^)(.*)/) {
            push @parts, _caret_operator('conan', $2);
            next;

        }

        push @parts, $part;

    }

    return join '|', @parts;

}

sub _raku_native_range {

    my $native = shift;

    my @parts = map {
              /(.*)\+$/
            ? ">=$1"                            # 1.0+
            : /^(\d+)\.\*/        ? ">=$1"      # 1.*
            : /^(\d+)\.(\d+)\.\*/ ? ">=$1.0"    # 1.0.*
            : $_                                # 1.0
    } grep {$_} split /\,/, $native;

    return join('|', grep {$_} @parts);

}

sub _gem_native_range {

    # Convert GEM version spec to VERS range

    my $native = shift;
    $native =~ s/\s+//g;

    # Specification From  ... To (exclusive)
    # ">= 3.0"      3.0   ... &infin;
    # "~> 3.0"      3.0   ... 4.0
    # "~> 3.0.0"    3.0.0 ... 3.1
    # "~> 3.5"      3.5   ... 4.0
    # "~> 3.5.0"    3.5.0 ... 3.6
    # "~> 3"        3.0   ... 4.0

    my @parts       = grep {length} split /,/, $native;
    my @constraints = ();

    foreach my $part (@parts) {


        if ($part =~ /^(~>)(.*)/) {
            push @constraints, _tilde_operator('gem', $2);
            next;
        }

        push @constraints, $part;

    }

    return join('|', @constraints);

}

sub _semver_wildcards {

    my ($operator, $term) = @_;
    $term =~ s/\s+//g;

    # >= major.x
    if ($operator eq '>=' && $term =~ /^(\d+)\.x(?:\.x)?$/) {
        my $major = $1;
        return (">=$major.0.0", '<' . ($major + 1) . ".0.0");
    }

    # >= major.minor.x
    if ($operator eq '>=' && $term =~ /^(\d+)\.(\d+)\.x$/) {
        my ($major, $minor) = ($1, $2);
        return (">=$major.$minor.0", "<$major." . ($minor + 1) . ".0");
    }

    return ();

}

sub _tilde_operator {

    my ($scheme, $version) = @_;
    $version =~ s/\s+//;

    my $semver = parse_semver($version);

    my $has_prerelease = defined($semver->{prerelease}) && ($semver->{prerelease} ne '');
    my ($major, $minor, $patch) = @{$semver}{qw[major minor patch]};

    if ($has_prerelease && defined $patch) {

        my $lower = join('.', $major, $minor, $patch);
        my $upper = join('.', $major, $minor, $patch + 1);

        return join '|', ">=$version", "<$lower", ">=$lower", "<$upper";
    }

    my ($upper_major, $upper_minor, $upper_patch) = ($major, $minor, $patch);

    if ($patch > 0) {
        ($upper_minor, $upper_patch) = ($minor + 1, 0);
    }
    elsif ($minor > 0) {
        ($upper_minor, $upper_patch) = ($minor + 1, 0);
    }
    else {
        ($upper_major, $upper_minor, $upper_patch) = ($major + 1, 0, 0);
    }

    my @upper = ($upper_major, $upper_minor, $upper_patch);

SWITCH:
    for ($scheme) {

        if (/gem/) {
            pop @upper;
            last SWITCH;
        }

        if (/conan/) {

            # strip trailing zeros
            pop @upper while @upper && $upper[-1] == 0;
            $upper[-1] .= '-';
            last SWITCH;
        }

    }

    # >= min and < max version
    return join '|', ">=$version", sprintf('<%s', join('.', @upper));

}

sub _caret_operator {

    my ($scheme, $version) = @_;
    $version =~ s/\s+//;

    my $semver = parse_semver($version);
    my ($major, $minor, $patch) = @{$semver}{qw[major minor patch]};

    my ($upper_major, $upper_minor, $upper_patch) = ($major, $minor, $patch);

    if ($major > 0) {
        ($upper_major, $upper_minor, $upper_patch) = ($major + 1, 0, 0);
    }
    elsif ($minor > 0) {
        ($upper_minor, $upper_patch) = ($minor + 1, 0);
    }
    else {
        $upper_patch = $patch + 1;
    }

    my @upper = ($upper_major, $upper_minor, $upper_patch);

SWITCH:
    for ($scheme) {

        if (/conan/) {

            # strip trailing zeros
            pop @upper while @upper && $upper[-1] == 0;
            $upper[-1] .= '-';
            last SWITCH;
        }

    }

    # >= min and < max version
    return join '|', ">=$version", sprintf('<%s', join('.', @upper));
}

sub is_semver {
    ($_[0] =~ /$SEMVER_REGEXP/) ? 1 : 0;
}

sub parse_semver {

    my $version = shift;

    # FIX semver (1 --> 1.0.0 or 1.0 -> 1.0.0)
    my @parts = split /\./, $version;

    $version = join '.', (@parts, 0, 0) if (@parts == 1);
    $version = join '.', (@parts, 0) if (@parts == 2);

    my %semver = (major => 0, minor => 0, patch => 0, prerelease => undef, buildmetadata => undef);

    if ($version =~ /$SEMVER_REGEXP/) {
        %semver = map { $_ => $+{$_} } qw[major minor patch prerelease buildmetadata];
    }

    return wantarray ? %semver : \%semver;

}

sub normalize_semver {
    return unless $_[0];
    return hash_to_semver(parse_semver($_[0]));
}

sub hash_to_semver {

    my %hash = (major => 0, minor => 0, patch => 0, prerelease => undef, buildmetadata => undef, @_);

    my $semver = join '.', $hash{major}, $hash{minor}, $hash{patch};

    $semver .= '-' . $hash{prerelease}    if $hash{prerelease};
    $semver .= '+' . $hash{buildmetadata} if $hash{buildmetadata};

    return $semver;
}

sub version_compare {

    my ($scheme, $left, $right) = @_;

    require URI::VersionRange::Version;

    my $version_class = URI::VersionRange::Version->load($scheme);
    return $version_class->new($left) <=> $version_class->new($right);

}

# SemVer compare

sub semver_version_compare {

    return 0 if $_[0] eq $_[1];

    my $a = parse_semver($_[0]);
    my $b = parse_semver($_[1]);

    my $major_cmp = $a->{major} <=> $b->{major};
    return $major_cmp if $major_cmp != 0;

    my $minor_cmp = $a->{minor} <=> $b->{minor};
    return $minor_cmp if $minor_cmp != 0;

    my $patch_cmp = $a->{patch} <=> $b->{patch};
    return $patch_cmp if $patch_cmp != 0;

    return -1 if defined $a->{prerelease}  && !defined $b->{prerelease};
    return 1  if !defined $a->{prerelease} && defined $b->{prerelease};
    return 0  if !defined $a->{prerelease} && !defined $b->{prerelease};

    if (defined $a->{prerelease} && defined $b->{prerelease}) {

        my @pre_a = split(/\./, $a->{prerelease});
        my @pre_b = split(/\./, $b->{prerelease});

        my $min = @pre_a < @pre_b ? scalar(@pre_a) : scalar(@pre_b);

        for my $i (0 .. $min - 1) {
            my $pre_cmp = _cmp_prerelease($pre_a[$i], $pre_b[$i]);
            return $pre_cmp if $pre_cmp != 0;
        }

        return @pre_a <=> @pre_b;

    }

    return 0;

}

sub _cmp_prerelease {

    my ($a, $b) = @_;

    if ($a =~ /^\d+$/ && $b =~ /^\d+$/) {
        return $a <=> $b;
    }

    if ($a =~ /^\d+$/ || $b =~ /^\d+$/) {
        return $a =~ /^\d+$/ ? -1 : 1;
    }

    return $a cmp $b;

}

# Optimized version of Sort::Version

sub generic_version_compare {

    my ($a, $b) = @_;

    $a =~ s/^[vV]//;
    $b =~ s/^[vV]//;

    return 0 if $a eq $b;

    my @A = ($a =~ /([-.]|\d+|[^-.\d]+)/g);
    my @B = ($b =~ /([-.]|\d+|[^-.\d]+)/g);

    my ($A, $B);

    while (@A and @B) {

        $A = shift @A;
        $B = shift @B;

        return -1 if $A eq '-' && $B ne '-';
        return 1  if $B eq '-' && $A ne '-';

        return -1 if $A eq '.' && $B ne '.';
        return 1  if $B eq '.' && $A ne '.';

        next if $A eq '-' && $B eq '-';
        next if $A eq '.' && $B eq '.';

        if ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
            my $num_cmp = ($A =~ /^0/ || $B =~ /^0/) ? ($A cmp $B) : ($A <=> $B);
            return $num_cmp if $num_cmp;
        }
        else {
            my $str_cmp = uc($A) cmp uc($B);
            return $str_cmp;
        }

    }

    return @A <=> @B;

}

# intdot compare

sub intdot_version_compare {

    my ($a, $b) = @_;

    ($a) = ($a // '') =~ /^([0-9.]*)/;
    ($b) = ($b // '') =~ /^([0-9.]*)/;

    my @A = split /\./, $a;
    my @B = split /\./, $b;

    s/^0+// for @A;
    s/^0+// for @B;

    my $max = @A > @B ? scalar @A : scalar @B;

    for my $i (0 .. $max - 1) {
        my $a_part = $A[$i] || 0;
        my $b_part = $B[$i] || 0;

        my $cmp = ($a_part <=> $b_part);
        return $cmp if $cmp;
    }

    return 0;

}


# datetime compare

sub datetime_version_compare {

    my ($a, $b) = @_;

    my ($a_epoch, $a_fraction) = _datetime_to_epoch($a);
    my ($b_epoch, $b_fraction) = _datetime_to_epoch($b);

    return ($a_epoch <=> $b_epoch) || ($a_fraction cmp $b_fraction);
}

sub _datetime_to_epoch {

    my $datetime = shift // '';

    Carp::croak "Invalid datetime version '$datetime'" unless $datetime =~ $RFC3339_REGEXP;

    my %dt = %+;

    Carp::croak "Invalid datetime version '$datetime' (time-offset out of range)"
        if (defined $dt{offset_hour} && ($dt{offset_hour} > 23 || $dt{offset_minute} > 59));

    my $epoch = eval { timegm($dt{second}, $dt{minute}, $dt{hour}, $dt{day}, $dt{month} - 1, $dt{year}) };

    Carp::croak "Invalid datetime version '$datetime'" unless defined $epoch;

    if (defined $dt{offset_hour}) {
        my $offset = ($dt{offset_hour} * 60 + $dt{offset_minute}) * 60;
        $epoch -= $offset if ($dt{offset_sign} eq '+');
        $epoch += $offset if ($dt{offset_sign} eq '-');
    }

    my $fraction = $dt{fraction} // '000';
    $fraction .= '0' x (9 - length $fraction);    # nanoseconds

    return ($epoch, $fraction);

}


# lexicographic compare

sub lexicographic_version_compare {

    my ($a, $b) = @_;

    utf8::encode($a);
    utf8::encode($b);

    return $a cmp $b;

}

1;

__END__

=encoding utf-8

=head1 NAME

URI::VersionRange::Util - Utility for URI::VersionRange

=head1 SYNOPSIS

  use URI::VersionRange::Util qw(native_range_to_vers);

  $vers = native_range_to_vers('npm', '~1.6.5 || >=1.7.2'); # vers:npm/>=1.6.5|<1.7.0|>=1.7.2


=head1 DESCRIPTION

URL::VersionRange::Util is the utility package for URL::VersionRange.

=over

=item $string = native_range_to_vers($scheme, $native_range)

Converts the specified native range string and returns the corresponding VERS string.

    $vers = native_range_to_vers('npm', '~1.6.5 || >=1.7.2'); # vers:npm/>=1.6.5|<1.7.0|>=1.7.2


Supported native range scheme:

=over

=item conan

=item gem

=item nginx

=item npm

=item nuget

=item raku

=item semver

=back

For other schemes, C<native_range_to_vers> will attempt to convert the native
range string to a VERS string, but this may not work perfectly.

=back


=head2 Version compare utility

=over

=item $int = version_compare($scheme, $a, $b)

Compare two versions using the scheme comparator class (see L<URI::VersionRange::Version>).

=item $int = generic_version_compare($a, $b)

Generic comparison (split on numeric and alphabetic segments).

=item $int = semver_version_compare($a, $b)

Semantic Versioning 2.0.0 comparison (L<https://semver.org>).

=item $int = datetime_version_compare($a, $b)

RFC 3339 timestamp comparison based on the UTC instant (eg. C<2024-01-01T00:00:00Z == 2023-12-31T19:00:00-05:00>).
Fractional seconds are supported up to 9 digits. Croaks on invalid timestamp.

=item $int = intdot_version_compare($a, $b)

Integers separated by dots (eg. C<10.234.5.12>). Leading zeros are ignored, a missing segment is equivalent
to a zero segment and the interpretation stops at the first character that is not a digit or a dot.

=item $int = lexicographic_version_compare($a, $b)

Byte-wise comparison of the UTF-8 encoded versions, without normalisation.

=back


=head2 Semver utility

=over

=item $string = hash_to_semver(%hash)

=item $bool = is_semver($string)

=item $string = normalize_semver($string)

=item %hash = parse_semver($string)

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

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
