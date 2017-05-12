package Test::Exit;
{
  $Test::Exit::VERSION = '0.11';
}

# ABSTRACT: Test that some code calls exit() without terminating testing

use strict;
use warnings;

use Return::MultiLevel qw(with_return);
use base 'Test::Builder::Module';

our @EXPORT = qw(exit_code exits_ok exits_zero exits_nonzero never_exits_ok);

# We have to install this at compile-time and globally.
# We provide one that does effectively nothing, and then override it locally.
# Of course, if anyone else overrides CORE::GLOBAL::exit as well, bad stuff happens.
our $exit_handler = sub {
  CORE::exit $_[0];
};
BEGIN {
  *CORE::GLOBAL::exit = sub (;$) { $exit_handler->(@_ ? 0 + $_[0] : 0) };
}


sub exit_code(&) {
  my ($code) = @_;

  return with_return {
    local $exit_handler = $_[0];
    $code->();
    undef
  };
}


sub exits_ok (&;$) {
  my ($code, $description) = @_;

  __PACKAGE__->builder->ok(defined &exit_code($code), $description);
}


sub exits_nonzero (&;$) {
  my ($code, $description) = @_;

  __PACKAGE__->builder->ok(&exit_code($code), $description);
}


sub exits_zero (&;$) {
  my ($code, $description) = @_;
  
  my $exit = &exit_code($code);
  __PACKAGE__->builder->ok(defined $exit && $exit == 0, $description);
}


sub never_exits_ok (&;$) {
  my ($code, $description) = @_;

  __PACKAGE__->builder->ok(!defined &exit_code($code), $description);
}

1;

__END__
=pod

=head1 NAME

Test::Exit - Test that some code calls exit() without terminating testing

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    use Test::More tests => 4;
    use Test::Exit;
    
    is exit_code { exit 75; }, 75, "procmail not found";
    exits_ok { exit 1; } "exiting exits";
    never_exits_ok { print "Hi!"; } "not exiting doesn't exit"l
    exits_zero { exit 0; } "exited with success";
    exits_nonzero { exit 42; } "exited with failure";

=head1 DESCRIPTION

Test::Exit provides some simple tools for testing code that might call
C<exit()>, providing you with the status code without exiting the test
file.

The only criterion tested is that the supplied code does or does not call
C<exit()>. If the code throws an exception, the exception will be propagated
and you will have to catch it yourself. C<die()>ing is not exiting for the
purpose of these tests.

Unlike previous versions of this module, the current version doesn't use
exceptions to do its work, so even if you call C<exit()> inside of an
C<eval>, everything should work.

=head1 FUNCTIONS

=head2 exit_code

Runs the given code. If the code calls C<exit()>, then C<exit_code> will
return a number, which is the status that C<exit()> would have exited with.
If the code never calls C<exit()>, returns C<undef>. This is the
L<Test::Fatal>-like interface. All of the other functions are wrappers for
this one, retained for legacy purposes.

=head2 exits_ok

Tests that the supplied code calls C<exit()> at some point.

=head2 exits_nonzero

Tests that the supplied code calls C<exit()> with a nonzero value.

=head2 exits_zero

Tests that the supplied code calls C<exit()> with a zero (successful) value.

=head2 never_exits_ok

Tests that the supplied code completes without calling C<exit()>.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

