package Test::Trap::Builder::SystemSafe;

use version; $VERSION = qv('0.3.5');

use strict;
use warnings;
use Test::Trap::Builder;
use File::Temp qw( tempfile );
use IO::Handle;

########
#
# I can no longer (easily?) install Devel::Cover on 5.6.2, so silence the coverage report:
#
# uncoverable condition right
# uncoverable condition false
use constant GOTPERLIO => (eval "use PerlIO (); 1" || 0);

sub import {
  shift; # package name
  my $strategy_name = @_ ? shift : 'systemsafe';
  my $strategy_option = @_ ? shift : {};
  Test::Trap::Builder->capture_strategy( $strategy_name => $_ ) for sub {
    my $self = shift;
    my ($name, $fileno, $globref) = @_;
    my $pid = $$;
    if (tied *$globref or $fileno < 0) {
      $self->Exception("SystemSafe only works with real file descriptors; aborting");
    }
    my ($fh, $file) = do {
      local ($!, $^E);
      tempfile( UNLINK => 1 ); # XXX: Test?
    };
    my ($fh_keeper, $autoflush_keeper, @io_layers, @restore_io_layers);
    my $Die = $self->ExceptionFunction;
    for my $buffer ($self->{$name}) {
      $self->Teardown($_) for sub {
        local ($!, $^E);
        if ($pid == $$) {
          # this process opened it, so it gets to collect the contents:
          local $/;
          $buffer .= $fh->getline;
          close $fh; # don't leak this one either!
          unlink $file;
        }
        close *$globref;
        return unless $fh_keeper;
        # close and reopen the file to the keeper!
        my $fno = fileno $fh_keeper;
        _close_reopen( $Die, $globref, $fileno, ">&$fno",
                       sub {
                         close $fh_keeper;
                         sprintf "Cannot dup '%s' for %s: '%s'",
                           $fno, $name, $!;
                       },
                     );
        close $fh_keeper; # another potential leak, I suppose.
        $globref->autoflush($autoflush_keeper);
      IO_LAYERS: {
          GOTPERLIO or last IO_LAYERS;
          local($!, $^E);
          binmode *$globref;
          my @tmp = @restore_io_layers;
          $_ eq $tmp[0] ? shift @tmp : last for PerlIO::get_layers(*$globref);
          binmode *$globref, $_ for @tmp;
        }
      };
    }
    binmode $fh; # superfluous?
    {
      local ($!, $^E);
      open $fh_keeper, ">&$fileno"
        or $self->Exception("Cannot dup '$fileno' for $name: '$!'");
    }
  IO_LAYERS: {
      GOTPERLIO or last IO_LAYERS;
      local($!, $^E);
      @restore_io_layers = PerlIO::get_layers(*$globref, output => 1);
      if ($strategy_option->{preserve_io_layers}) {
        @io_layers = @restore_io_layers;
      }
      if ($strategy_option->{io_layers}) {
        push @io_layers, $strategy_option->{io_layers};
      }
    }
    $autoflush_keeper = $globref->autoflush;
    _close_reopen( $self->ExceptionFunction, $globref, $fileno, ">>$file",
                   sub {
                     sprintf "Cannot open %s for %s: '%s'",
                       $file, $name, $!;
                   },
                 );
  IO_LAYERS: {
      GOTPERLIO or last IO_LAYERS;
      local($!, $^E);
      for my $h (*$globref, $fh) {
        binmode $h;
        my @tmp = @io_layers or next;
        $_ eq $tmp[0] ? shift @tmp : last for PerlIO::get_layers($h);
        binmode $h, $_ for @tmp;
      }
    }
    $globref->autoflush(1);
    $self->Next;
  };
}

sub _close_reopen {
  my ($Die, $glob, $fno_want, $what, $err) = @_;
  local ($!, $^E);
  close *$glob;
  my @fh;
  while (1) {
    no warnings 'io';
    open *$glob, $what or $Die->($err->());
    my $fileno = fileno *$glob;
    last if $fileno == $fno_want;
    close *$glob;
    if ($fileno > $fno_want) {
      $Die->("Cannot get the desired descriptor, '$fno_want' (could it be that it is fdopened and so still open?)");
    }
    if (grep{$fileno == fileno($_)}@fh) {
      $Die->("Getting several files opened on fileno $fileno");
    }
    open my $fh, $what or $Die->($err->());
    if (fileno($fh) != $fileno) {
      $Die->("Getting fileno " . fileno($fh) . "; expecting $fileno");
    }
    push @fh, $fh;
  }
  close $_ for @fh;
}

1; # End of Test::Trap::Builder::SystemSafe

__END__

=head1 NAME

Test::Trap::Builder::SystemSafe - "Safe" capture strategies using File::Temp

=head1 VERSION

Version 0.3.5

=head1 DESCRIPTION

This module provides capture strategies I<systemsafe>, based on
File::Temp, for the trap's output layers.  These strategies insists on
reopening the output file handles with the same descriptors, and
therefore, unlike L<Test::Trap::Builder::TempFile> and
L<Test::Trap::Builder::PerlIO>, is able to trap output from forked-off
processes, including system().

The import accepts a name (as a string; default I<systemsafe>) and
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

If the file handle we try to trap using this strategy is on an
in-memory file, it would not be available to other processes in any
case.  Rather than change the semantics of the trapped code or
silently fail to trap output from forked-off processes, we just raise
an exception in this case.

If there is another file handle with the same descriptor (f ex after
an C<< open OTHER, '>&=', THIS >>), we can't get that file descriptor.
Rather than silently fail, we again raise an exception.

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
