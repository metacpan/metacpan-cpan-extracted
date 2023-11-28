package Variable::Disposition;
# ABSTRACT: dispose of variables
use strict;
use warnings;

use parent qw(Exporter);

our $VERSION = '0.005';

=head1 NAME

Variable::Disposition - helper functions for disposing of variables

=head1 SYNOPSIS

 use feature qw(say);
 use Variable::Disposition;
 my $x = [];
 dispose $x;
 say '$x is no longer defined';

=head1 DESCRIPTION

Provides some basic helper functions for making sure variables go away
when you want them to.

Currently provides L</dispose> as a default import. To avoid this:

 use Variable::Disposition ();

In addition, L</retain> and L</retain_future> are available as optional
imports.

 use Variable::Disposition qw(dispose retain retain_future);

The C< :all > tag can be used to import every available function:

 use Variable::Disposition qw(:all);

but it would be safer to use a version instead:

 use Variable::Disposition qw(:v1);

since these are guaranteed not to change in future.

Other functions for use with L<Future> and L<IO::Async> are likely to be
added later.

=cut

our @EXPORT_OK = qw(dispose retain retain_future);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
    v1  => [ qw(dispose retain retain_future) ],
);

our @EXPORT = qw(dispose);

use Scalar::Util ();

our %RETAINED;

=head1 FUNCTIONS

=cut

=head2 dispose

Undefines the given variable, then checks that the original ref was destroyed.

 my $x = [1,2,3];
 dispose $x;
 # $x is no longer defined.

This is primarily intended for cases where you no longer need a variable, and want
to ensure that you haven't accidentally captured a strong reference to it elsewhere.

Note that this clears the B<caller>'s variable.

This function is defined with a prototype of ($), since it is only intended for use
on scalar variables. To clear multiple variables, use a L<foreach> loop:

 my ($x, $y, $z) = ...;
 dispose $_ for $x, $y, $z;
 is($x, undef);
 is($y, undef);
 is($z, undef);

=cut

sub dispose($) {
    die "Variable not defined" unless defined $_[0];
    die "Variable was not a ref" unless ref $_[0];
    delete $RETAINED{$_[0]}; # just in case we'd previously retained this one
    Scalar::Util::weaken(my $copy = $_[0]);
    undef $_[0];
    die "Variable was not released" if defined $copy;
}

=head2 retain

Keeps a copy of this variable until program exit or L</dispose>.

Returns the original variable.

=cut

sub retain($) {
    die "Variable not defined" unless defined $_[0];
    die "Variable was not a ref" unless ref $_[0];
    $RETAINED{$_[0]} = $_[0];
    $_[0]
}

=head2 retain_future

Holds a copy of the given L<Future> until it's marked ready, then releases our copy.
Does not use L</dispose>, since that could interfere with other callbacks attached
to the L<Future>.

Since Future 0.36, this behaviour is directly available via the L<Future/retain> method,
so it is recommended to use that instead of this function.

Returns the original L<Future>.

=cut

sub retain_future {
    my ($f) = @_;
    die "Variable does not seem to be a Future, since it has no ->on_ready method" unless $f->can('on_ready');
    return $f->retain;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Devel::Refcount> - assert_oneref is almost identical to this, although it doesn't clear the variable it's called on

=item * L<Closure::Explicit> - provides a sub{} wrapper that will complain if you capture a lexical without explicitly declaring that you're going to do that.

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.

