package WebService::Google::Closure::Type::Stats;

use Moose;
use MooseX::Types::Moose qw( Str Int );

has original_size => (
    is         => 'ro',
    isa        => Int,
    init_arg   => 'originalSize',
    required   => 1,
);

has compressed_size => (
    is         => 'ro',
    isa        => Int,
    init_arg   => 'compressedSize',
    required   => 1,
);

has original_gzip_size => (
    is         => 'ro',
    isa        => Int,
    init_arg   => 'originalGzipSize',
    required   => 1,
);

has compressed_gzip_size => (
    is         => 'ro',
    isa        => Int,
    init_arg   => 'compressedGzipSize',
    required   => 1,
);

has compile_time => (
    is         => 'ro',
    isa        => Int,
    init_arg   => 'compileTime',
    required   => 1,
);


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

WebService::Google::Closure::Type::Stats - Statistics from compilation

=head1 ATTRIBUTES

=head2 $stats->original_size

Number of bytes of the submitted code.

=head2 $stats->compressed_size

Number of bytes of the compiled javascript code.

=head2 $stats->original_gzip_size

Number of bytes of the submitted code when compressed with gzip.

=head2 $stats->compressed_gzip_size

Number of bytes of the compiled javascript code when compressed with gzip.

=head2 $stats->compile_time

Time spent compiling the javascript code.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Magnus Erixzon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
