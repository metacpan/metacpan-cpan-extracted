package Test::Trap::Builder::TempFile;

use version; $VERSION = qv('0.3.5');

use strict;
use warnings;
use IO::Handle;
use File::Temp qw( tempfile );
use Test::Trap::Builder;

########
#
# I can no longer (easily?) install Devel::Cover on 5.6.2, so silence the coverage report:
#
# uncoverable condition right
# uncoverable condition false
use constant GOTPERLIO => (eval "use PerlIO (); 1" || 0);

sub import {
  shift; # package name
  my $strategy_name = @_ ? shift : 'tempfile';
  my $strategy_option = @_ ? shift : {};
  Test::Trap::Builder->capture_strategy( $strategy_name => $_ ) for sub {
    my $self = shift;
    my ($name, $fileno, $globref) = @_;
    my $pid = $$;
    my ($fh, $file) = do {
      local ($!, $^E);
      tempfile( UNLINK => 1 ); # XXX: Test?
    };
    # make an alias to $self->{$name}, so that the closure does not hold $self:
    for my $buffer ($self->{$name}) {
      $self->Teardown($_) for sub {
        # if the file is opened by some other process, that one should deal with it:
        return unless $pid == $$;
        local $/;
        local ($!, $^E);
        $buffer .= <$fh>;
        close $fh;
        unlink $file;
      };
    }
    my @io_layers;
  IO_LAYERS: {
      GOTPERLIO or last IO_LAYERS;
      local($!, $^E);
      if ($strategy_option->{preserve_io_layers}) {
        @io_layers = PerlIO::get_layers(*$globref, output => 1);
      }
      if ($strategy_option->{io_layers}) {
        push @io_layers, $strategy_option->{io_layers};
      }
      binmode $fh; # set the perlio layers for reading:
      binmode $fh, $_ for @io_layers;
    }
    local *$globref;
    {
      no warnings 'io';
      local ($!, $^E);
      open *$globref, '>>', $file;
    }
  IO_LAYERS: {
      GOTPERLIO or last IO_LAYERS;
      local($!, $^E);
      binmode *$globref; # set the perlio layers for writing:
      binmode *$globref, $_ for @io_layers;
    }
    *$globref->autoflush(1);
    $self->Next;
  };
}

1; # End of Test::Trap::Builder::TempFile

__END__

=head1 NAME

Test::Trap::Builder::TempFile - Capture strategies using File::Temp

=head1 VERSION

Version 0.3.5

=head1 DESCRIPTION

This module by default provides a capture strategy based on File::Temp
for the trap's output layers.

The import accepts a name (as a string; default I<tempfile>) and
options (as a hashref; by default empty), and registers a capture
strategy with that name and a variant implementation based on the
options.

Note that you may specify different strategies for each output layer
on the trap.

See also L<Test::Trap> (:stdout and :stderr) and
L<Test::Trap::Builder> (output_layer).

=head1 OPTIONS

The following options are recognized:

=head2 preserve_io_layers

A boolean, indicating whether to apply to the handles writing to and
reading from the tempfile, the same perlio layers as are found on the
to-be-trapped output handle.

=head2 io_layers

A colon-separated string representing perlio layers to be applied to
the handles writing to and reading from the tempfile.

If the I<preserve_io_layers> option is set, these perlio layers will
be applied on top of the original (preserved) perlio layers.

=head1 CAVEATS

Using File::Temp, we need privileges to create tempfiles.

We need disk space for the output of every trap (it should clean up
after the trap is sprung).

Disk access may be slow -- certainly compared to the in-memory files
of PerlIO.

If the options specify (explicitly or via preserve on handles with)
perlio custom layers, they may (or may not) fail to apply to the
tempfile read and write handles.

Threads?  No idea.  It might even work correctly.

=head1 BUGS

Please report any bugs or feature requests directly to the author.

=head1 AUTHOR

Eirik Berg Hanssen, C<< <ebhanssen@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2014 Eirik Berg Hanssen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
