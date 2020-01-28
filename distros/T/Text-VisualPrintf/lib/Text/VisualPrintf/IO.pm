package Text::VisualPrintf::IO;

use v5.10;
use strict;
use warnings;

use IO::Handle;
use Text::VisualPrintf;

no warnings 'once', 'redefine';

*IO::Handle::printf  = \&Text::VisualPrintf::printf;
*IO::Handle::vprintf = \&Text::VisualPrintf::printf;

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf::IO - IO::Handle interface using Text::VisualPrintf

=head1 SYNOPSIS

    use IO::Handle;
    use Text::VisualPrintf::IO;

    FILEHANDLE->printf(FORMAR, LIST);

=head1 DESCRIPTION

This module replace IO::Handle::printf by Text::VisualPrintf::printf
funciton.  So you can use C<printf> method from IO::File or such.

=head1 SEE ALSO

L<Text::VisualPrintf>

L<https://github.com/kaz-utashiro/Text-VisualPrintf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
