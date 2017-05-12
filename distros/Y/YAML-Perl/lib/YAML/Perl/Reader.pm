# pyyaml/lib/yaml/reader.py

package YAML::Perl::Reader;
use strict;
use warnings;

use YAML::Perl::Error;

package YAML::Perl::Error::Reader;
use YAML::Perl::Error -base;

field 'name';
field 'character';
field 'position';
field 'encoding';
field 'reason';

# use overload '""' => sub {
#     my $self = shift;
#     "XXX";
# };

package YAML::Perl::Reader;
use YAML::Perl::Processor -base;

field next_layer => '';

sub open {
    my $self = shift;
    $self->SUPER::open(@_);
    my $stream = shift;
    $self->name('<string>');
    $self->stream($stream);
    $self->raw_buffer($stream);
    $self->determine_encoding();
}

field 'name';
field 'stream';
field 'stream_pointer' => 0;
field 'eof' => True;
field 'buffer' => '';
field 'pointer' => 0;
field 'raw_buffer';
field 'raw_decode';
field 'encoding';
field 'index' => 0;
field 'line' => 0;
field 'column' => 0;

sub peek {
    my $self = shift;
    my $index = shift || 0;
    if ($self->{index} + $index > length( $self->{buffer} )) {
#         $self->update($index + 1);
        return "\0"
    }
    # print '<' . substr($self->{buffer}, $self->{index} + $index, 1) . '> ';
    return substr($self->{buffer}, $self->{index} + $index, 1);
}

sub prefix {
    my $self = shift;
    my $length = @_ ? shift : 1;
    return substr($self->{buffer}, $self->{index}, $length);
}

sub forward {
    my $self = shift;
    my $length = @_ ? shift : 1;
    # print '(' . $length . ') ';

    while ( $length-- ) {
        my $ch = $self->peek();
        if ( 
            $ch =~ /[\n\x85]/
            or ( $ch eq "\r" and $self->peek(2) != "\n" )
        ) {
            $self->{line}++;
            $self->{column} = 0;
        }
        elsif ( $ch ne "\x{FEFF}" ) {
            $self->{column}++
        }
        $self->{index}++;
    }
}
    
sub get_mark {
    my $self = shift;
    if (not defined $self->stream) {
        return YAML::Perl::Mark->new(
            name => $self->name,
            index => $self->index,
            line => $self->line,
            column => $self->column,
            buffer => $self->buffer,
            pointer => $self->pointer,
        );
    }
    return YAML::Perl::Mark->new(
        name => $self->name,
        index => $self->index,
        line => $self->line,
        column => $self->column,
    );
}

sub determine_encoding {
    my $self = shift;
    while (not $self->eof and length($self->raw_buffer) < 2) {
        $self->update_raw();
        if (0 && $self->unicode_stuf_XXX()) {
            #XXX ...
        }
    }
    $self->update(1);
}

use constant NON_PRINTABLE =>
    qr/[^\x09\x0A\x0D\x20-\x7E\x85\xA0-\x{D7FF}\x{E000}-\x{FFFD}]/;
sub check_printable {
    my $self = shift;
    my $data = shift;
    my $match = ($data =~ NON_PRINTABLE);
    if ($match) {
        my $character = 'x'; #XXX
        # $match->group();
        my $position = 666; #XXX
        # $self->index + (length($self->buffer) - $self->pointer) + $match->start();
        throw YAML::Perl::Error::Reader(
            $self->name, $position, $character,
            'unicode', "special characters are not allowed"
        );
    }
}

sub update {
    my $self = shift;
    my $length = shift;

    if (not defined $self->raw_buffer) {
        return;
    }
    $self->buffer(substr($self->buffer, $self->pointer));
    $self->pointer(0);
    while (length($self->buffer) < $length) {
        if (not $self->eof) {
            $self->update_raw();
        }
        my ($data, $converted);
        if (defined $self->raw_decode) {
            try {
                $data, $converted =
                    $self->raw_decode(
                        $self->raw_buffer,
                        'strict',
                        $self->eof,
                    );
            }
#             except {
#                 UnicodeDecodeError, exc:
#                 character = exc.object[exc.start]
#                 if self.stream is not None:
#                     position = self.stream_pointer-len(self.raw_buffer)+exc.start
#                 else:
#                     position = exc.start
#                 raise ReaderError(self.name, position, character,
#                         exc.encoding, exc.reason)
#             }
        }
        else {
            $data = $self->raw_buffer;
            $converted = length($data);
        }
        $self->check_printable($data);
        $self->{buffer} .= $data;
        $self->raw_buffer(substr($self->raw_buffer, $converted));
        if ($self->eof) {
            $self->{buffer} .= "\0";
            $self->raw_buffer(undef);
            last;
        }
    }
}

sub update_raw {
    my $self = shift;
    my $size = shift || 1024;
    my $data = $self->stream->read($size);
    if ($data) {
        $self->{raw_buffer} .= $data;
        $self->stream_pointer($self->stream_pointer + length($data));
    }
    else {
        $self->eof(True);
    }
}

1;
