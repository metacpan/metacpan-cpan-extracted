package Text::APL::Writer;

use strict;
use warnings;

use base 'Text::APL::Base';

sub build {
    my $self = shift;
    my ($output) = @_;

    my $writer;

    if (!ref $output) {
        open my $fh, '>', $output or die "Can't write to '$output': $!";
        $writer = sub { print $fh $_[0] };
    }
    elsif (ref $output eq 'GLOB') {
        $writer = sub { print $output $_[0] };
    }
    elsif (ref $output eq 'SCALAR') {
        ${$output} = '';
        $writer = sub { ${$output} .= $_[0] if defined $_[0] };
    }
    elsif (ref $output eq 'CODE') {
        $writer = $output;
    }
    else {
        die 'Do not know how to write';
    }

    return $writer;
}

1;
__END__

=pod

=head1 NAME

Text::APL::Writer - writer

=head1 DESCRIPTION

Write a template output to various destinations. Accepts a subroutine for
a custom implementation.

Returns a reference to subroutine. When called accepts a chunk of template
output. Chunk is undefined when template is fully processed. When received an
undefined chunk one can close a file, drop the connection etc.

For example a writer to a file handle is implemented as:

        sub { print $output $_[0] };

The following destinations are implemented:

    $reader->(\$scalar);
    $reader->($filename);
    $reader->($filehandle);
    $reader->(sub {...custom code...});

Custom subroutines are used for non-blocking output writing. See C<examples/>
directory for an example using L<IO::AIO> for non-blocking output writing.

=head1 METHODS

=head2 C<build>

Build a writer.

=cut
