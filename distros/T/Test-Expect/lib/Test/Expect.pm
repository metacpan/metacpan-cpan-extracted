package Test::Expect;
use strict;
use warnings;
use Class::Accessor::Chained::Fast;
use Expect::Simple;
use Exporter;
use Test::Builder;
use base qw(Class::Accessor::Chained::Fast Exporter);
__PACKAGE__->mk_accessors(qw(program));
our $VERSION = "0.34";
our @EXPORT  = qw(
    expect_run
    expect_handle
    expect_is
    expect_like
    expect_send
    expect_quit
    expect
    END
);

my $Test = Test::Builder->new;

my $expect;
my $sent;

sub import {
    my $self = shift;
    if (@_) {
        die @_;
        my $package = caller;
        $Test->exported_to($package);
        $Test->plan(@_);
    }
    $Test->no_ending(0);
    $self->export_to_level( 1, $self, $_ ) foreach @EXPORT;
}

sub expect_run {
    my (%conf) = @_;
    local $ENV{PERL_RL} = "Stub o=0";
    $expect = Expect::Simple->new(
        {   Cmd           => $conf{command},
            Prompt        => $conf{prompt},
            DisconnectCmd => $conf{quit},
            Verbose       => 0,
            Debug         => 0,
            Timeout       => 100
        }
    );
    die $expect->error if $expect->error;
    $Test->ok( 1, "expect_run" );
}

sub expect_handle { return $expect->expect_handle(); }

sub before {
    my $before = $expect->before;
    $before =~ s/\r//g;
    $before =~ s/^\Q$sent\E// if $sent;
    $before =~ s/^\n+//;
    $before =~ s/\n+$//;
    return $before;
}

sub expect_like {
    my ( $like, $comment ) = @_;
    $Test->like( before(), $like, $comment );
}

sub expect_is {
    my ( $is, $comment ) = @_;
    $Test->is_eq( before(), $is, $comment );
}

sub expect_send {
    my ( $send, $comment ) = @_;
    $expect->send($send);
    $sent = $send;
    $Test->ok( 1, $comment );
}

sub expect {
    my ( $send, $is, $label ) = @_;
    expect_send( $send, $label );
    expect_is( $is, $label );
}

sub expect_quit {
    undef $expect;
}

sub END {
    expect_quit;
}

1;

__END__

=head1 NAME

Test::Expect - Automated driving and testing of terminal-based programs

=head1 SYNOPSIS

  # in a t/*.t file:
  use Test::Expect;
  use Test::More tests => 13;
  expect_run(
    command => ["perl", "testme.pl"],
    prompt  => 'testme: ',
    quit    => 'quit',
  );
  expect("ping", "pong", "expect");
  expect_send("ping", "expect_send");
  expect_is("* Hi there, to testme", "expect_is");
  expect_like(qr/Hi there, to testme/, "expect_like");

=head1 DESCRIPTION

L<Test::Expect> is a module for automated driving and testing of
terminal-based programs.  It is handy for testing interactive programs
which have a prompt, and is based on the same concepts as the Tcl
Expect tool.  As in L<Expect::Simple>, the L<Expect> object is made
available for tweaking.

L<Test::Expect> is intended for use in a test script.

=head1 SUBROUTINES

=head2 expect_run

The expect_run subroutine sets up L<Test::Expect>. You must pass in
the interactive program to run, what the prompt of the program is, and
which command quits the program:

  expect_run(
    command => ["perl", "testme.pl"],
    prompt  => 'testme: ',
    quit    => 'quit',
  );

The C<command> may either be a string, or an arrayref of program and
arguments; the latter for bypasses the shell.

=head2 expect

The expect subroutine is the catch all subroutine. You pass in the
command, the expected output of the subroutine and an optional
comment.

  expect("ping", "pong", "expect");

=head2 expect_send

The expect_send subroutine sends a command to the program. You pass in
the command and an optional comment.

  expect_send("ping", "expect_send");

=head2 expect_is

The expect_is subroutine tests the output of the program like
Test::More's is. It has an optional comment:

  expect_is("* Hi there, to testme", "expect_is");

=head2 expect_like

The expect_like subroutine tests the output of the program like
Test::More's like. It has an optional comment:

  expect_like(qr/Hi there, to testme/, "expect_like");

=head2 expect_handle

This returns the L<Expect> object.

=head2 expect_quit

Closes the L<Expect> handle.

=head1 SEE ALSO

L<Expect>, L<Expect::Simple>.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Original module by Leon Brocard, E<lt>acme@astray.comE<gt>

=head1 BUGS

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-Test-Expect@rt.cpan.org">bug-Test-Expect@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=Test-Expect">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-Test-Expect@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=Test-Expect


=head1 COPYRIGHT

This extension is Copyright (C) 2015 Best Practical Solutions, LLC.

Copyright (C) 2005, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
