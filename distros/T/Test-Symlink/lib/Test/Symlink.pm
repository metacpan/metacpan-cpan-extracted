package Test::Symlink;

# Copyright (c) 2005 Nik Clayton
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

use warnings;
use strict;

use Test::Builder;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(symlink_ok);

my $Test = Test::Builder->new;
my $Symlinks = eval { symlink("",""); 1 }; # Do we have symlink support?

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, 'symlink_ok');
}

=head1 NAME

Test::Symlink - Test::Builder based test for symlink correctness

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Test::Symlink tests => 3;

    symlink_ok('foo', 'bar', 'foo links to bar');
    symlink_ok('foo' => 'bar', 'Use fat comma for visual clarity');

    # The test name is optional
    symlink_ok('foo' => 'bar') # ok 3 - Symlink: foo -> bar

Test::Symlink B<automatically> exports C<symlink_ok()> for testing 
the correctness of symlinks.  Test::Symlink uses Test::Builder, so 
plays nicely with Test::Simple, Test::More, and other Test::Builder 
based modules.

=head1 FUNCTIONS

=head2 symlink_ok($src, $dst, [ $test_name ]);

Verifies that $src exists, and is a symlink to $dst.

Does B<not> verify that $dst exists, as this is legal, and there is at
least one valid usage of this that I'm aware of (F</etc/malloc.conf> on
FreeBSD).  If you want to ensure that the destination exists then write
this as two tests.  For example:

    ok(-e $dst, "$dst exists");
    symlink_ok($src, $dst, "  ... and $src links to it");

The test name (C<$test_name>) is optional.  If it is omitted then a test 
name of the form "Symlink: $src -> $dst" is used.

Perl's fat comma operator can be usefully used as an visual aid.

The test will be skipped on systems that do not support symlinks.  
However, the arguments to symlink_ok() will still be checked to ensure
that they are defined and non-empty.

=cut

sub symlink_ok {
  my($src, $dst, $test_name) = @_;

  if(! defined $src or $src eq '') {
    my $ok = $Test->ok(0, 'symlink_ok()');
    $Test->diag('    You must provide a $src argument to symlink_ok()');
    return $ok;
  }

  if(! defined $dst or $dst eq '') {
    my $ok = $Test->ok(0, "symlink_ok($src)");
    $Test->diag('    You must provide a $dst argument to symlink_ok()');
    return $ok;
  }

  $test_name = "Symlink: $src -> $dst" unless defined $test_name;

  if(! $Symlinks) {
    return $Test->skip('symlinks are not supported on this platform');
  }

  # '-e' will follow symlinks.  So, to verify that $src really doesn't
  # exist you have to do the -e check, and you have to readlink() to make
  # sure it really doesn't exist.
  if(! -e $src and ! defined readlink($src)) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    $src does not exist");
    return $ok;
  }

  if(! -l $src) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    $src exists, but is not a symlink");
    return $ok;
  }

  my $act_dst;
  if(($act_dst = readlink($src)) ne $dst) {
    my $ok = $Test->ok(0, $test_name);
    $Test->diag("    $src is not a symlink to $dst");
    $Test->diag("         got: $src -> $act_dst");
    $Test->diag("    expected: $src -> $dst");
    return $ok;
  }

  return $Test->ok(1, $test_name);
}

=head1 AUTHOR

Nik Clayton, <nik@FreeBSD.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-symlink@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Symlink>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2003 Nik Clayton
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

1; # End of Test::Symlink
