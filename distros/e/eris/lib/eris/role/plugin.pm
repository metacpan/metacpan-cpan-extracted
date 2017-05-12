package eris::role::plugin;

use Moo::Role;
use Types::Standard qw(Int Str);

########################################################################
# Attributes
has name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_name',
);
has 'priority' => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    builder => '_build_priority',
);

########################################################################
# Builders
sub _build_name     { ref $_[0] }
sub _build_priority { 50 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::plugin

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
