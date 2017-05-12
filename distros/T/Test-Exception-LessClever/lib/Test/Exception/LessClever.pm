package Test::Exception::LessClever;
use strict;
use warnings;

use base 'Exporter';
use Test::Builder;
use Carp qw/carp/;

#{{{ POD

=head1 NAME

Test::Exception::LessClever - (DEPRECATED) Test::Exception simplified

=head1 DEPRECATION NOTICE

*** This module is deprecated: please do not use it! ***

An alternative to L<Test::Exception> that is much simpler. This alternative
does not use fancy stack tricks to hide itself. The idea here is to keep it
simple. This also solves the Test::Exception bug where some dies will be hidden
when a DESTROY method calls eval. If a DESTROY method masks $@ a warning will
be generated as well.

=head1 WHY REWRITE TEST-EXCEPTION

Here is an IRC log.

    <Exodist> wtf? Bizarre copy of HASH in sassign at /usr/lib64/perl5/5.10.1/Carp/Heavy.pm line 104
    <Exodist> hmm, it doesn't happen when I step through the debugger, that sure is helpful yessir
    <Exodist> hmm, throws_ok or dies_ok { stuff that croaks in a package used by the one being tested }, at least in this case causes that error. If I change it to eval {}; ok( $@ ); like( $@, qr// ); it works fine
    <Exodist> Ah-Ha,   earlier when I mentioned I stopped using throws_ok because of something I could not remember, this was it, I stumbled on it again!
    <confound> probably because throws_ok tries to do clever things to fiddle with the call stack to make it appear as though its guts are not being called
    <confound> less clever would be more useful

=head1 SYNOPSIS

Pretty much a clone of L<Test::Exception> Refer to those docs for more details.

    use Test::More;
    use Test::Exception;

    dies_ok { die( 'xxx' )} "Should die";
    lives_ok { 1 } "Should live";
    throws_ok { die( 'xxx' )} qr/xxx/, "Throws 'xxx'";
    lives_and { ok( 1, "We did not die" )} "Ooops we died";

    done_testing;

=head1 EXPORTABLE FUNCTIONS

=over 4

=cut

#}}}

our @EXPORT_OK = qw/live_or_die/;
our @EXPORT = qw/lives_ok dies_ok throws_ok lives_and/;
our @CARP_NOT = ( __PACKAGE__ );
our $TB = Test::Builder->new;
our $VERSION = "0.009";

warnings::warnif('deprecated', '!!! Test::Exception::LessClever is deprecated');

=item $status = live_or_die( sub { ... }, $name )

=item ($status, $msg) = live_or_die( sub { ... }, $name )

Check if the code lives or dies. In scalar context returns true or false. In
array context returns the same true or false with the error message. If the
return is true the error message will be something along the lines of 'did not
die' but this may change in the future.

Will generate a warning if the test dies, $@ is empty AND called in array
context. This usually occurs when an objects DESTROY method calls eval and
masks $@.

*NOT EXPORTED BY DEFAULT*

=cut

sub live_or_die {
    my ( $code ) = @_;
    my $return = eval { $code->(); 'did not die' } || "died";
    my $msg = $@;

    if ( $return eq 'did not die' ) {
        return ( 1, $return ) if wantarray;
        return 1;
    }
    else {
        return 0 unless wantarray;

        if ( !$msg ) {
            carp "code died as expected, however the error is masked. This"
               . " can occur when an object's DESTROY() method calls eval";
        }

        return ( 0, $msg );
    }
}

=item lives_ok( sub { ... }, $name )

Test passes if the sub does not die, false if it does.

=cut

sub lives_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    $TB->ok( $ok, $name );
    return $ok;
}

=item dies_ok( sub { ... }, $name )

Test passes if the sub dies, false if it does not.

=cut

sub dies_ok(&;$) {
    my ( $code, $name ) = @_;
    my $ok = live_or_die( $code );
    $TB->ok( !$ok, $name );
    return !$ok;
}

=item throws_ok( sub { ... }, qr/message/, $name )

Check that the sub dies, and that it throws an error that matches the regex.

Test fails is the sub does not die, or if the message does not match the regex.

=cut

sub throws_ok(&$;$) {
    my ( $code, $reg, $name ) = @_;
    my ( $ok, $msg ) = live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;

    # If we lived
    if ( $ok ) {
        $TB->diag( "Test did not die as expected at $file line $number." );
        return $TB->ok( !$ok, $name );
    }

    my $match = $msg =~ $reg ? 1 : 0;
    $TB->ok( $match, $name );

    $TB->diag( "$file line $number:\n  Wanted: $reg\n  Got: $msg" )
        unless( $match );

    return $match;
}

=item lives_and( sub {...}, $name )

Fails with $name if the sub dies, otherwise is passive. This is useful for
running a test that could die. If it dies there is a failure, if it lives it is
responsible for itself.

=cut

sub lives_and(&;$) {
    my ( $code, $name ) = @_;
    my ( $ok, $msg )= live_or_die( $code );
    my ( $pkg, $file, $number ) = caller;
    chomp( $msg );
    $msg =~ s/\n/ /g;
    $TB->diag( "Test unexpectedly died: '$msg' at $file line $number." ) unless $ok;
    $TB->ok( $ok, $name ) if !$ok;
    return $ok;
}

1;

__END__

=back

=head1 SEE ALSO

=over 4

=item *

L<Test::Fatal>

=item *

L<Test::Exception>

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Test-Exception-LessClever is free software; Standard perl licence.

Test-Exception-LessClever is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
