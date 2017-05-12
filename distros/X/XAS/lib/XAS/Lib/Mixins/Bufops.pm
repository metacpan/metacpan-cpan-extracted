package XAS::Lib::Mixins::Bufops;

our $VERSION = '0.01';

use Params::Validate qw(SCALAR SCALARREF);
use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation',
  mixins  => 'buf_slurp buf_get_line'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub buf_slurp {
    my $self = shift;
    my ($buffer, $pos) = validate_params(\@_, [
        { type => SCALARREF },
        { type => SCALAR },
    ]);

    my $output;

    if ($output = substr($$buffer, 0, $pos)) {

        substr($$buffer, 0, $pos) = '';

    }

    return $output;

}

sub buf_get_line {
    my $self = shift;
    my ($buffer, $eol) = validate_params(\@_, [
        { type => SCALARREF },
        { type => SCALAR | SCALARREF },
    ]);

    my $pos;
    my $output;

    if ($$buffer =~ m/$eol/g) {

        $pos = pos($$buffer);
        $output = $self->buf_slurp($buffer, $pos);

    }

    return $output;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Bufops - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixins::Bufops',
 ;

 my $buffer = "this is a buffer",

 my $word = $self->buf_get_line(\$buffer, ' ');

=head1 DESCRIPTION

This module performs some common operations on buffers.

=head1 METHODS

=head2 buf_get_line(\$buffer, $eol)

This method returns a "line" from a buffer.

=over 4

=item B<$buffer>

A pointer to a buffer.

=item B<$eol>

A delimiter to search for. This denotes the end of the line.

=back

=head2 buf_slurp(\$buffer, $length)

This method will extract a chunk from the buffer. The buffer will shrink 
by that amount.

=over 4

=item B<$buffer>

A pointer to a buffer.

=item B<$length>

The length of the chunk.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
