package cPanel::TQSerializer::YAML;
$cPanel::TQSerializer::YAML::VERSION = '0.900';
use YAML::Syck ();

# with no bless flags
$YAML::Syck::LoadBlessed = 0;
$YAML::Syck::NoBless     = 1;

#use warnings;
use strict;

sub load {
    my ( $class, $fh ) = @_;
    local $/;
    return YAML::Syck::Load( scalar <$fh> );
}

sub save {
    my ( $class, $fh, @args ) = @_;
    return print $fh YAML::Syck::Dump(@args);
}

sub filename {
    my ( $class, $stub ) = @_;
    return "$stub.yaml";
}

1;

__END__

Copyright (c) 2014, cPanel, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
