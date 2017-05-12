package Test::Run::Trap::Obj;

use strict;
use warnings;

=head1 NAME

Test::Run::Trap::Obj - wrapper around Test::Trap for trapping errors.

=head1 SYNPOSIS

    my $got = Test::Run::Trap::Obj->trap_run({
        args => [test_files => ["t/sample-tests/simple"]]
    });

    $got->field_like("stdout", qr/All tests successful/,
        "Everything is OK."
    );

=head1 DESCRIPTION

This class implements a wrapper around L<Test::Trap>. When an
assertion files, the diagnostics prints all the relevant and trapped
fields for easy debugging.

=head1 METHODS

=cut

use Moose;

extends('Test::Run::Base::Struct');


use Test::More;
use Data::Dumper ();

use Text::Sprintf::Named;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use Test::Run::Obj;

my @fields = qw(
    die
    exit
    leaveby
    return
    stderr
    stdout
    wantarray
    warn
    run_func
);


has 'die' => (is => "rw", isa => "Any");
has 'exit' => (is => "rw", isa => "Any");
has 'leaveby' => (is => "rw", isa => "Str");
has 'return' => (is => "rw", isa => "Any");
has 'stderr' => (is => "rw", isa => "Str");
has 'stdout' => (is => "rw", isa => "Str");
has 'wantarray' => (is => "rw", isa => "Bool");
has 'warn' => (is => "rw", isa => "Any");
has 'run_func' => (is => "rw", isa => "CodeRef");

sub _stringify_value
{
    my ($self, $name) = @_;

    my $value = $self->$name();

    if (($name eq "return") || ($name eq "warn"))
    {
        return Data::Dumper->new([$value])->Dump();
    }
    else
    {
        return (defined($value) ? $value : "");
    }
}

=head2 $trapper->diag_all()

Calls L<Test::More>'s diag() with all the trapped fields, like stdout,
stderr, etc.

=cut

sub diag_all
{
    my $self = shift;

    diag(
        Text::Sprintf::Named->new(
            {
                fmt =>
            join( "",
            map { "$_ ===\n{{{{{{\n%($_)s\n}}}}}}\n\n" }
            (@fields))
            }
        )->format({args => { map { my $name = $_;
                        ($name => $self->_stringify_value($name)) }
                    @fields
                }})
    );
}

=head2 $trapper->field_like($what, $regex, $message)

A wrapper for L<Test::More>'s like(), that also emits more diagnostics
on failure.

=cut

sub field_like
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $regex, $name) = @_;

    if (! Test::More::like($self->$what(), $regex, $name))
    {
        $self->diag_all();
    }
}

=head2 $trapper->field_unlike($what, $regex, $msg)

A wrapper for unlike().

=cut

sub field_unlike
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $regex, $name) = @_;

    if (! Test::More::unlike($self->$what(), $regex, $name))
    {
        $self->diag_all();
    }
}

=head2 $trapper->field_is($what, $expected, $msg)

A wrapper for is().

=cut

sub field_is
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $expected, $name) = @_;

    if (! Test::More::is($self->$what(), $expected, $name))
    {
        $self->diag_all();
    }
}

=head2 $trapper->field_is_deeply($what, $expected, $msg)

A wrapper for is_deeply().

=cut

sub field_is_deeply
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $expected, $name) = @_;

    if (! Test::More::is_deeply($self->$what(), $expected, $name))
    {
        $self->diag_all();
    }
}


=head2 my $got = Test::Run::Trap::Obj->trap_run({class => $class, args => \@args, run_func => $func})

Runs C<$class->$func()> with the arguments @args placed into a hash-ref,
traps the results and returns a results object.

=cut

sub trap_run
{
    my ($class, $args) = @_;

    my $test_run_class = $args->{class} || "Test::Run::Obj";

    my $test_run_args = $args->{args};

    my $run_func = $args->{run_func} || "runtests";

    my $tester = $test_run_class->new(
        {@{$test_run_args}},
        );

    trap { $tester->$run_func(); };

    return $class->new({
        ( map { $_ => $trap->$_() }
        (qw(stdout stderr die leaveby exit return warn wantarray)))
    });
}

1;

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 SEE ALSO

L<Test::Trap> , L<Test::More> .

=cut
