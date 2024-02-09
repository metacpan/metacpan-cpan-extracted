package Text::Markup::Cmd;

use strict;
use warnings;
use Symbol;
use IPC::Open3;
use File::Spec;
use Carp;use constant WIN32  => $^O eq 'MSWin32';
use Exporter 'import';
our @EXPORT = qw(find_cmd exec_or_die open_pipe WIN32);

sub find_cmd {
    my ($names, @opts) = @_;
    my $cli;
    EXE: {
        for my $exe (@{ $names }) {
            for my $p (File::Spec->path) {
                my $path = File::Spec->catfile($p, $exe);
                next unless -f $path && -x $path;
                $cli = $path;
                last EXE;
            }
        }
    }

    unless ($cli) {
        my $list = join(', ', @{ $names }[0..$#$names-1]) . ", or $names->[-1]";
        Carp::croak( "Cannot find $list in path $ENV{PATH}" );
    }

    # Make sure it looks like it will work.
    exec_or_die("$cli will not execute", $cli, @opts);
    return $cli;
}

sub exec_or_die {
    my $err = shift;
    my $output = gensym;
    my $pid = open3(undef, $output, $output, @_);
    waitpid $pid, 0;
    return 1 unless $?;
    use Carp;
    local $/;
    Carp::croak( qq{$err\n}, <$output> );
}

# Stolen from SVN::Notify.
sub open_pipe {
    # Ignored; looks like docutils always emits UTF-8.
    if (WIN32) {
        my $cmd = q{"} . join(q{" "}, @_) . q{"|};
        open my $fh, $cmd or die "Cannot fork: $!\n";
        return $fh;
    }

    my $pid = open my $fh, '-|';
    die "Cannot fork: $!\n" unless defined $pid;

    if ($pid) {
        # Parent process, return the file handle.
        return $fh;
    } else {
        # Child process. Execute the commands.
        exec @_ or die "Cannot exec $_[0]: $!\n";
        # Not reached.
    }
}

1;
__END__

=head1 Name

Text::Markup::Cmd - Tools for external commands

=head1 Synopsis

  use Text::Markup::Cmd;
  my $fh = open_pipe(qw(perl -V));

=head1 Description

Text::Markup::Cmd provides tools for Text::Markup parsers that depend on
external commands, such as L<Text::Markup::Rest> and
L<Text::Markup::AsciiDoctor>. Will mainly be of interest to those
L<adding a new parser|Text::Markup/Add a Parser> with such a dependency.

=head3 Interface

=head2 Exported Functions

=head3 C<WIN32>

  my $exe = 'nerble' . (WIN32 ? '.exe' : '');

Constant indicating whether the current runtime environment (OS) is Windows.

=head3 C<find_cmd>

  my $cmd = find_cmd(
    ['nerble' . (WIN32 ? '.exe' : ''), 'nerble.rb'],
    '--version',
);

Searches the path for one or more named commands. Returns the first command
to be found in the path and which executes with the specified command line
options without error. The caller must specify OS-appropriate spellings
of the commands.

=head3 C<exec_or_die>

  exec_or_die(
      qq{Missing required Python "docutils" module},
      $PYTHON, '-c', 'import docutils',
  );

Executes a command and its arguments. Dies with the error argument if the
command fails.

=head3 C<open_pipe>

  my $fh = open_pipe(qw(nerble --as-html input.nerb));

Executes a command and its arguments and returns a file handle opened to
its C<STDOUT>. Dies if the command fails.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2012-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
