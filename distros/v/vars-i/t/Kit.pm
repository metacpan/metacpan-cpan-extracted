package #Hide from PAUSE
    Kit;
use 5.006001;
use strict;
use warnings;
use Import::Into;
use Test::More;

use Carp qw(croak);

use parent 'Exporter';

our @EXPORT;
BEGIN { @EXPORT=qw(eval_dies_ok eval_lives_ok eval_dies_like eval_is_var
    line_mark_string); }

=head1 NAME

Kit - vars::i test kit

=head1 SYNOPSIS

Test helpers.  These make it easier to trap undefined variables using string
eval and C<use strict>.

=head1 FUNCTIONS

=head2 eval_dies_ok

    eval_dies_ok "Code string" [, "message"];

Runs the code string; tests that the code died.
Any exception will be reported at the same line in the caller as the
C<eval_dies_ok> invocation.

=cut

sub eval_dies_ok {
    my (undef, $filename, $line) = caller;
    eval line_mark_string($filename, $line-1, $_[0]);
    ok($@, $_[1] || ('Died as expected: ' . $_[0]));
}

=head2 eval_lives_ok

    eval_lives_ok "Code string" [, "message"];

Runs the code string; tests that the code did not throw an exception.

=cut

sub eval_lives_ok {
    eval $_[0];
    is($@, '', $_[1] || ('Lived as expected: ' . $_[0]));
}

=head2 eval_dies_like

    eval_dies_like "Code string", qr/regex/ [, "message"];

Runs the code string; tests that the code threw an exception matching C<regex>.

=cut

sub eval_dies_like {
    eval $_[0];
    like($@, $_[1], $_[2] || ('Died with exception matching ' . $_[1]));
}

=head2 eval_is_var

    eval_is_var '$Package::var', value [, "message"];

Tests that C<$Package::var> exists, and that C<$Package::var eq value>.

=cut

sub eval_is_var {
    my ($varname, $expected, $msg) = @_;
    $msg ||= "$varname eq $expected";
    my ($sigil, $package, $basename) = ($varname =~ m/^(.)(.+)::([^:]+)$/);
    die "Invalid varname $varname" unless $package && $varname;

    my $got = eval qq[do { package $package; use strict; $sigil$basename }];

    is($@, '', "Accessed $varname");
    is($got, $expected, $msg);
} #eval_var_is

=head2 line_mark_string

Add a C<#line> directive to a string.  Usage:

    my $str = line_mark_string <<EOT ;
    $contents
    EOT

or

    my $str = line_mark_string __FILE__, __LINE__, <<EOT ;
    $contents
    EOT

In the first form, information from C<caller> will be used for the filename
and line number.

The C<#line> directive will point to the line after the C<line_mark_string>
invocation, i.e., the first line of <C$contents>.  Generally, C<$contents> will
be source code, although this is not required.

C<$contents> must be defined, but can be empty.

=cut

sub line_mark_string {
    my ($contents, $filename, $line);
    if(@_ == 1) {
        $contents = $_[0];
        (undef, $filename, $line) = caller;
    } elsif(@_ == 3) {
        ($filename, $line, $contents) = @_;
    } else {
        croak "Invalid invocation";
    }

    croak "Need text" unless defined $contents;
    die "Couldn't get location information" unless $filename && $line;

    $filename =~ s/"/-/g;
    ++$line;

    return <<EOT;
#line $line "$filename"
$contents
EOT
} #line_mark_string()

=head2 import

Exports the functions using L<Exporter> --- all functions are exported by
default.  Also loads L<Test::More> into the caller.

=cut

sub import {
    my $target = caller;
    __PACKAGE__->export_to_level(1, @_);
    Test::More->import::into($target);
    my $oldfh = select(STDERR); $| = 1; select($oldfh); $| = 1;
}
