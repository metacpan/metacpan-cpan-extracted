package Text::APL::Reader::AIO;

use strict;
use warnings;

use base 'Text::APL::Reader';

use IO::AIO;

sub _build_file_reader {
    my $self = shift;
    my ($filename) = @_;

    $filename = File::Spec->rel2abs($filename);

    sub {
        my ($cb) = @_;

        aio_open $filename, IO::AIO::O_RDONLY, 0, sub {
            my $fh = shift or die "$!";

            my $reader = $self->_build_file_handle_reader($fh);

            $reader->($cb);
        };
      }
}

sub _build_file_handle_reader {
    my $self = shift;
    my ($fh) = @_;

    sub {
        my ($cb) = @_;

        my $size = -s $fh;

        my $contents;
        aio_read $fh, 0, $size, $contents, 0, sub {
            $_[0] > 0 or die "read error: $!";

            close $fh;

            $cb->($contents);
            $cb->();
        };
      }
}

1;
__END__

=pod

=head1 NAME

Text::APL::Reader::AIO - reader using IO::AIO

=head1 DESCRIPTION

=cut
