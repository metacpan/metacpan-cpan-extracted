package URI::VersionRange::Version::generic {

    use Version::libversion::XS;

    use parent 'URI::VersionRange::Version';
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return version_compare2($left->[0], $right->[0]);
    }

}

package URI::VersionRange::Version::rpm {

    use RPM4;

    use parent 'URI::VersionRange::Version';
    use overload ('cmp' => \&compare, '<=>' => \&compare, fallback => 1);

    sub compare {
        my ($left, $right) = @_;
        return rpmvercmp($left->[0], $right->[0]);
    }

}

1;
