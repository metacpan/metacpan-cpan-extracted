package Test::SynchHaveWant;

use warnings;
use strict;

use Test::Builder;
use Data::Dumper;
use Carp 'confess';
use base 'Exporter';
our @EXPORT_OK = qw(
  have
  want
  synch
);

my %DATA_SECTION_FOR;     # this is the want() data
my %NEW_DATA_FOR;         # data from have(), if requested
my %SEEK_POSITION_FOR;    # where to synch the data, if requested
my %SYNCH_WAS_CALLED;     # calling have/want after this should fail
my %TIMES_CALLED;         # track how often have/want called

=head1 NAME

Test::SynchHaveWant - Synchronize volatile have/want values for tests

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Test::Most;
    use Test::SynchHaveWant qw/
        have
        want
    /;

    my $have = some_complex_data();

    eq_or_diff have($have),  want(), 'have and want should be the same';

    __DATA__
    [
        {
            'bar' => [ 3, 4 ],
            'foo' => 1
        },
        0,
        bless( [ 'this', 'that', 'glarble', 'fetch' ], 'Foobar' ),
    ]

If you wish to synch:

    use Test::Most;
    use Test::SynchHaveWant qw/
        have
        want
        synch
    /;

    my $have = some_complex_data();

    eq_or_diff have($have),  want(), 'have and want should be the same';
    is have(0), want(), '0 is 0';

    # note that we can use normal tests
    my $want = want();
    isa_ok $want, 'Foobar';
    is_deeply $have($some_object), $want, '... and the object is the same';
    synch();

    __DATA__
    [
        {
            'bar' => [ 3, 4 ],
            'foo' => 1
        },
        0,
        bless( [ 'this', 'that', 'glarble', 'fetch' ], 'Foobar' ),
    ]


=cut

sub _read_data_section {
    my $caller = shift;
    my $key    = _get_key();

    my $__DATA__ = do { no strict 'refs'; \*{"${caller}::DATA"} };
    unless ( defined fileno $__DATA__ ) {
        confess "__DATA__ section not found for package ($caller)";
    }

    $SEEK_POSITION_FOR{$key} = tell $__DATA__;
    seek $__DATA__, 0, 0;
    my $data_section = join '', <$__DATA__>;
    $data_section =~ s/^.*\n__DATA__\n/\n/s;    # for win32
    $data_section =~ s/\n__END__\n.*$/\n/s;

    $data_section = eval $data_section;
    if ( my $error = $@ ) {
        confess "Error reading __DATA__ for ($caller): $error";
    }
    unless ( 'ARRAY' eq ( ref $data_section || '' ) ) {
        confess "__DATA__ did not contain an array reference";
    }
    $DATA_SECTION_FOR{$key} = $data_section;
}

=head1 DO NOT USE THIS CODE WITHOUT SOURCE CONTROL

This is C<ALPHA CODE>. It's very alpha code. It's dangerous code. It attempts to
B<REWRITE YOUR TESTS> and if it screws up, you had better be using B<SOURCE
CONTROL> so you can revert.

That being said, if you need this code and you really, really understand
what's going on, go ahead and use it at your own risk.

=head1 DESCRIPTION

Sometimes you have extremely volatile data/code and you I<know> your tests are
correct even though they've failed because the code has changed or the
underlying data has been altered. Ordinarily, you never, never want your tests
to be so fragile. You want to figure out some way of mocking your test data or
isolating functional units in your code for testing.

The first pass I had at solving this problem was to effectively compute the
edit distance for data structures, but even that failed as differences emerged
over time (see L<http://blogs.perl.org/users/ovid/2011/02/is-almost.html>).

For this module, we're giving devs a chance to rewrite their test results on
the fly, assuming that the new results of their code is correct.

This is generally an I<INCREDIBLY STUPID IDEA>.  It's very stupid.  Not only
do we attempt to rewrite your __DATA__ sections, we make it very easy for
you to have bogus tests because you may incorrectly assume that the new data
you're returning is correct.  That's why this is a B<BIG, FAT, DANGEROUS
EXPERIMENT>.

I've been asked a couple of times why I feel the need to experiment with
writing "fragile" tests but I can't tell you due to my NDA.

=head1 WHY IS OVID BEING STUPID?

Tests should not be as fragile as indicated here. You should mock up your test
data or find ways of isolating functionality to make your tests more robust.

Not everyone has that luxury. If you insist that everyone does have that
luxury, be aware that the real world of "these are the constraints I have" and
the fantasy world of "the way I like things is the only way things should be
done" aren't on speaking terms to one another.

=head1 USAGE

To make this work, you must have a C<__DATA__> section in your code. This
section should contain terse L<Data::Dumper> output of an array reference with each
value being a subsequent expected test result. Every time C<want()> is called,
the next value in this array ref is returned:

    is have($foo),         want();    # 3
    is_deeply have($aref), want();    # ['foo','bar']
    is have($idiot),       want();    # 'ovid'
    __DATA__
    [
       3,
       [ qw/foo bar/ ],
       'ovid',
    ]

The C<have()> function must be called as often as the C<want()> function (and
in sequence) to track the values we have received. 

If desired, the C<synch()> function may be exported and called at the end of
the test run. If any tests failed (C<< ! Test::Builder->new->is_passing >>),
then we attempt to write all values passed to C<have()> to the C<__DATA__>
section.

C<synch()> will fail if have/want have been called a different number of times
or if it has already been called. C<have()> and C<want()> will fail if
C<synch()> has already been called.

It goes without saying that this means you must have a deterministic order for
your tests. Bad:

    while ( my ( $key, $value ) = each %test ) {
        is_deeply have( some_func( $key, $value ) ), want();
    }

Good:

    foreach my $key  ( sort keys %test ) {
        my $value = $test{$key};
        is_deeply have( some_func( $key, $value ) ), want();
    }

=head1 EXPORT

=head2 C<have>

 is have($have), want(), 'have should equal want';

Ordinarily this function is a no-op. It merely returns the value it is passed.
However, if synch is called at the end of the test run, the values passed to
this function will be written to the data in the __DATA__ section.

=cut

sub have {
    my $have = shift;
    my $key  = _get_key();
    if ( exists $SYNCH_WAS_CALLED{$key} ) {
        confess "Synch was already called for ($key)";
    }

    no warnings 'uninitialized';
    $TIMES_CALLED{$key}{have}++;
    $NEW_DATA_FOR{$key} ||= [];
    push @{ $NEW_DATA_FOR{$key} } => $have;
    return $have;
}

=head2 C<want>

 is have($have), want(), 'have should equal want';

Returns the current expected test result. Attempting to read past the end of
the test results will result in a fatal error.

=cut

sub want {
    my $key = _get_key();
    if ( exists $SYNCH_WAS_CALLED{$key} ) {
        confess "Synch was already called for ($key)";
    }

    unless ( exists $DATA_SECTION_FOR{$key} ) {
        _read_data_section( scalar caller );
    }
    no warnings 'uninitialized';
    $TIMES_CALLED{$key}{want}++;
    my $data_section = $DATA_SECTION_FOR{$key};
    unless (@$data_section) {
        confess("Attempt to read past end of __DATA__ for $0");
    }
    return shift @$data_section;
}

=head2 C<synch>

    synch();

This function will attempt to take all of the values passed to have() and
write them out to the __DATA__ section. If C<have()> and C<want()> have been
called an unequal number of times, this function will die.

Will not attempt to synch the __DATA__ if the tests appear to be passing.

If tests are not passing, will prompt the user if they really want to synch
tests results. Only a C<< /^\s*[Yy]/ >> is acceptable. To ensure that we don't
block on automated systems, we have an alarm set for 10 seconds. After that,
we merely return without attempting to synch.

=cut

sub synch {
    my $key = _get_key();

    my ( $have, $want ) = @{ $TIMES_CALLED{$key} }{qw/have want/};

    unless ( $have == $want ) {
        confess(
"have/want not in synch: have was called $have times and want was called $want times"
        );
    }

    my $builder = Test::Builder->new;
    return if $builder->is_passing;

    print STDERR "# Really synch have/want data? (y/N) ";

    my $response;
    eval {
        local $SIG{ALRM} = sub { die "Died while bored" };

        alarm 10;
        $response = <STDIN>;
        alarm 0;
    };
    if (my $error = $@) {
        return if $error =~ /Died while bored/;
        confess($error);
    }
    unless ( $response =~ /^\s*[yY]/ ) {
        warn "# Aborting synch ...";
        return;
    }

    if ( exists $SYNCH_WAS_CALLED{$key} ) {
        confess "Synch was already called for ($key)";
    }

    $SYNCH_WAS_CALLED{$key} = 1;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    unless ( exists $SEEK_POSITION_FOR{$key} ) {
        confess("Panic: seek position for ($key) not found");
    }
    my $new_data = $NEW_DATA_FOR{$key};
    unless ( 'ARRAY' eq ref $new_data ) {
        confess(
            "PANIC: new data to write to __DATA__ is not an array reference");
    }
    my $position = $SEEK_POSITION_FOR{$key};

    open my $fh, '+<', $0 or confess "Cannot open $0 for writing: $!";
    seek $fh, $position, 0
      or confess "Cannot seek to position $position for $0: $!";
    truncate $fh, tell($fh)
      or confess "Cannot truncate $0 at position $position: $!";
    print $fh Dumper($new_data) or confess "Could not print new data to $0: $!";
    close $fh or confess "Could not close $0: $!";
}

# XXX eventually I may have to add to this if people start using this
sub _get_key {
    return $0;
}

=head1 AUTHOR

Curtis 'Ovid' Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-synchhavewant at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-SynchHaveWant>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::SynchHaveWant

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-SynchHaveWant>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-SynchHaveWant>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-SynchHaveWant>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-SynchHaveWant/>

=back

=head1 ACKNOWLEDGEMENTS

You don't really think I'm going to blame anyone else for this idiocy, do you?

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Curtis 'Ovid' Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
