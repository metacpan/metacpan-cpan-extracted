package eris::base::types;

use Type::Library
    -base,
    -declare => qw(HashRefFromYAML);
use Type::Utils -all;
use Types::Standard -types;
use YAML;

# Config File to HashRef Conversion
declare_coercion "HashRefFromYAML",
    to_type HashRef,
    from Str,
    q|
        my $file = $_;
        my $config = {};
        if ( -f $file ) {
            eval {
                $config = YAML::LoadFile($file);
                1;
            } or die "unable to parse YAML file: $file, $@";
        }
        return $config;
    |;

# Return True
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::base::types

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
