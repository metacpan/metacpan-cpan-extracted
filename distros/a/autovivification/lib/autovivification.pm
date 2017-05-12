package autovivification;

use 5.008_003;

use strict;
use warnings;

=head1 NAME

autovivification - Lexically disable autovivification.

=head1 VERSION

Version 0.16

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.16';
}

=head1 SYNOPSIS

    no autovivification;

    my $hashref;

    my $a = $hashref->{key_a};       # $hashref stays undef

    if (exists $hashref->{option}) { # Still undef
     ...
    }

    delete $hashref->{old};          # Still undef again

    $hashref->{new} = $value;        # Vivifies to { new => $value }

=head1 DESCRIPTION

When an undefined variable is dereferenced, it gets silently upgraded to an array or hash reference (depending of the type of the dereferencing).
This behaviour is called I<autovivification> and usually does what you mean (e.g. when you store a value) but it may be unnatural or surprising because your variables gets populated behind your back.
This is especially true when several levels of dereferencing are involved, in which case all levels are vivified up to the last, or when it happens in intuitively read-only constructs like C<exists>.

This pragma lets you disable autovivification for some constructs and optionally throws a warning or an error when it would have happened.

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head1 METHODS

=head2 C<unimport>

    no autovivification; # defaults to qw<fetch exists delete>
    no autovivification qw<fetch store exists delete>;
    no autovivification 'warn';
    no autovivification 'strict';

Magically called when C<no autovivification @opts> is encountered.
Enables the features given in C<@opts>, which can be :

=over 4

=item *

C<'fetch'>

Turns off autovivification for rvalue dereferencing expressions, such as :

    $value = $arrayref->[$idx]
    $value = $hashref->{$key}
    keys %$hashref
    values %$hashref

Starting from perl C<5.11>, it also covers C<keys> and C<values> on array references :

    keys @$arrayref
    values @$arrayref

When the expression would have autovivified, C<undef> is returned for a plain fetch, while C<keys> and C<values> return C<0> in scalar context and the empty list in list context.

=item *

C<'exists'>

Turns off autovivification for dereferencing expressions that are parts of an C<exists>, such as :

    exists $arrayref->[$idx]
    exists $hashref->{$key}

C<''> is returned when the expression would have autovivified.

=item *

C<'delete'>

Turns off autovivification for dereferencing expressions that are parts of a C<delete>, such as :

    delete $arrayref->[$idx]
    delete $hashref->{$key}

C<undef> is returned when the expression would have autovivified.

=item *

C<'store'>

Turns off autovivification for lvalue dereferencing expressions, such as :

    $arrayref->[$idx] = $value
    $hashref->{$key} = $value
    for ($arrayref->[$idx]) { ... }
    for ($hashref->{$key}) { ... }
    function($arrayref->[$idx])
    function($hashref->{$key})

An exception is thrown if vivification is needed to store the value, which means that effectively you can only assign to levels that are already defined.
In the example, this would require C<$arrayref> (resp. C<$hashref>) to already be an array (resp. hash) reference.

=item *

C<'warn'>

Emits a warning when an autovivification is avoided.

=item *

C<'strict'>

Throws an exception when an autovivification is avoided.

=back

Each call to C<unimport> B<adds> the specified features to the ones already in use in the current lexical scope.

When C<@opts> is empty, it defaults to C<< qw<fetch exists delete> >>.

=cut

my %bits = (
 strict => A_HINT_STRICT,
 warn   => A_HINT_WARN,
 fetch  => A_HINT_FETCH,
 store  => A_HINT_STORE,
 exists => A_HINT_EXISTS,
 delete => A_HINT_DELETE,
);

sub unimport {
 shift;
 my $hint = _detag($^H{+(__PACKAGE__)}) || 0;
 @_ = qw<fetch exists delete> unless @_;
 $hint |= $bits{$_} for grep exists $bits{$_}, @_;
 $^H |= 0x00020000;
 $^H{+(__PACKAGE__)} = _tag($hint);
 ();
}

=head2 C<import>

    use autovivification; # default Perl behaviour
    use autovivification qw<fetch store exists delete>;

Magically called when C<use autovivification @opts> is encountered.
Disables the features given in C<@opts>, which can be the same as for L</unimport>.

Each call to C<import> B<removes> the specified features to the ones already in use in the current lexical scope.

When C<@opts> is empty, it defaults to restoring the original Perl autovivification behaviour.

=cut

sub import {
 shift;
 my $hint = 0;
 if (@_) {
  $hint = _detag($^H{+(__PACKAGE__)}) || 0;
  $hint &= ~$bits{$_} for grep exists $bits{$_}, @_;
 }
 $^H |= 0x00020000;
 $^H{+(__PACKAGE__)} = _tag($hint);
 ();
}

=head1 CONSTANTS

=head2 C<A_THREADSAFE>

True if and only if the module could have been built with thread-safety features enabled.
This constant only has a meaning when your perl is threaded, otherwise it will always be false.

=head2 C<A_FORKSAFE>

True if and only if this module could have been built with fork-safety features enabled.
This constant will always be true, except on Windows where it is false for perl 5.10.0 and below.

=head1 CAVEATS

Using this pragma will cause a slight global slowdown of any subsequent compilation phase that happens anywere in your code - even outside of the scope of use of C<no autovivification> - which may become noticeable if you rely heavily on numerous calls to C<eval STRING>.

The pragma doesn't apply when one dereferences the returned value of an array or hash slice, as in C<< @array[$id]->{member} >> or C<< @hash{$key}->{member} >>.
This syntax is valid Perl, yet it is discouraged as the slice is here useless since the dereferencing enforces scalar context.
If warnings are turned on, Perl will complain about one-element slices.

Autovivifications that happen in code C<eval>'d during the global destruction phase of a spawned thread or pseudo-fork (the processes used internally for the C<fork> emulation on Windows) are not reported.

=head1 DEPENDENCIES

L<perl> 5.8.3.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<XSLoader> (standard since perl 5.6.0).

=head1 SEE ALSO

L<perlref>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-autovivification at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=autovivification>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc autovivification

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/autovivification>.

=head1 ACKNOWLEDGEMENTS

Matt S. Trout asked for it.

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of autovivification
