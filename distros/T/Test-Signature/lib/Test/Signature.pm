package Test::Signature;

use 5.005;
use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
use Exporter;
use Test::Builder;

BEGIN {
    $VERSION   = '1.11';
    @ISA       = qw( Exporter );
    @EXPORT    = qw( signature_ok );
    @EXPORT_OK = qw( signature_force_ok );
}

my $test = Test::Builder->new();

=head1 NAME

Test::Signature - Automated SIGNATURE testing

=head1 SYNOPSIS

    # This is actually the t/0-signature.t file from this distribution.
    use Test::More tests => 1;
    use Test::Signature;

    signature_ok();

=head1 ABSTRACT

C<Test::Signature> verifies that the C<Module::Signature> generated
signature of a module is correct.

=head1 DESCRIPTION

C<Module::Signature> allows you to verify that a distribution has
not been tampered with. C<Test::Signature> lets that be tested
as part of the distribution's test suite.

By default, if C<Module::Signature> is not installed then it will just
say so and not fail the test. That can be overridden though.

B<IMPORTANT>: This is not a substitute for the users verifying
the distribution themselves. By the time this module is run, the
users will have already run your F<Makefile.PL> or F<Build.PL> scripts
which could have been compromised.

This module is more for ensuring you've updated your signature
appropriately before distributing, and for preventing accidental
errors during transmission or packaging.

=cut

=head1 FUNCTIONS

C<signature_ok> is exported by default. C<signature_force_ok> must be
explicitly exported.

=head2 signature_ok()

This will test that the C<Module::Signature> generated signature
is valid for the distribution. It can be given two optional parameters.
The first is a name for the test. The default is C<Valid signature>.
The second is whether a lack of C<Module::Signature> should be regarded
as a failure. The default is C<0> meaning 'no'.

    # Test with defaults
    signature_ok()
    # Test with custom name
    signature_ok( "Is the signature valid?" );
    # Test with custom name and force C<Module::Signature> to exist
    signature_ok( "Is the signature valid?", 1 );
    # Test without custom name, but forcing
    signature_ok( undef, 1 );

=cut

sub action_skip { $test->skip( $_[0] ) }
sub action_ok { $test->ok( 0, $_[0] ) }

sub signature_ok {
    my $name  = shift || 'Valid signature';
    my $force = shift || 0;
    my $action = $force ? \&action_ok : \&action_skip;
  SKIP: {
        if ( !-s 'SIGNATURE' ) {
            $action->("No SIGNATURE file found.");
        }
        elsif ( !eval { require Module::Signature; 1 } ) {
            $action->(
                    "Next time around, consider installing Module::Signature, "
                  . "so you can verify the integrity of this distribution." );
        }
        elsif ( !eval { require Socket; Socket::inet_aton('pgp.mit.edu') } ) {
            $action->("Cannot connect to the keyserver.");
        }
        else {
            $test->ok( Module::Signature::verify(skip => 1) ==
                  Module::Signature::SIGNATURE_OK() => $name );
        }
    }
}

=head2 signature_force_ok()

This is equivalent to calling C<< signature_ok( $name, 1 ) >>
but is more readable.

    # These are equivalent:
    signature_force_ok( "Is our signature valid?" );
    signature_ok( "Is our signature valid?", 1);

    # These are equivalent:
    signature_force_ok();
    signature_ok( undef, 1 );

=cut

sub signature_force_ok {
    signature_ok( $_[0] || undef, 1 );
}

1;
__END__

=head1 NOTES ON USE

=head2 F<MANIFEST> and F<MANIFEST.SKIP>

It is B<imperative> that your F<MANIFEST> and F<MANIFEST.SKIP> files be
accurate and complete. If you are using C<ExtUtils::MakeMaker> and you
do not have a F<MANIFEST.SKIP> file, then don't worry about the rest of
this. If you do have a F<MANIFEST.SKIP> file, or you use
C<Module::Build>, you must read this.

Since the test is run at C<make test> time, the distribution has been
made. Thus your F<MANIFEST.SKIP> file should have the entries listed
below.

If you're using C<ExtUtils::MakeMaker>, you should have, at least:

    #defaults
    ^Makefile$
    ^blib/
    ^blibdirs$
    ^pm_to_blib$

These entries are part of the default set provided by
C<ExtUtils::Manifest>, which is ignored if you provide your own
F<MANIFEST.SKIP> file.

If you are using C<Module::Build>, there is no default F<MANIFEST.SKIP>
so you B<must> provide your own. It must, minimally, contain:

    ^Build$
    ^Makefile$
    ^_build/
    ^blib/

If you don't have the correct entries, C<Module::Signature> will
complain that you have:

    ==> MISMATCHED content between MANIFEST and distribution files! <==

You should note this during normal development testing anyway.

=head2 Use with Test::Prereq

C<Test::Prereq> tends to get a bit particular about modules.
If you're using the I<force> option with C<Test::Signature> then
you will have to specify that you expect C<Module::Signature> as a
prerequisite. C<Test::Signature> will not have it as a prerequisite
since that would defeat the point of having the I<force> variant.

If you are using C<ExtUtils::MakeMaker> you should have a line like the
following in your F<Makefile.PL>:

    'PREREQ_PM' => {
	'Test::Signature'   => '1.04',
	'Module::Signature' => '0.22',
	'Test::More'        => '0.47',
    },

If using C<Module::Build>, your F<Build.PL> should have:

    build_requires => {
	'Test::Signature'   => '1.04',
	'Module::Signature' => '0.22',
	'Test::More'        => '0.47',
    },

If you just want the default behaviour of testing the signature if and
only if the user already has C<Module::Signature> installed, then you
will need something like the following code. The example uses
C<Module::Build> format but it should be trivial for you to translate to
C<ExtUtils::MakeMaker>.

    #!/usr/bin/perl -w
    use strict;
    use Module::Build 0.18;

    my @extra_build;

    eval { require Module::Signature };
    if (!$@ or $Test::Prereq::VERSION)
    {
	push @extra_build, "Module::Signature" => '0.22'
    }

    my $m = Module::Build->new(
	dist_name => 'WWW-Yahoo-Groups',
	dist_version => '1.7.7',
	license => 'perl',

	requires => {
	    # various modules
	    'perl'             => '5.6.0',
	},
	build_requires => {
	    'Test::More'          => 0.47,
	    'Test::Prereq'        => 0.19,
	    'Test::Prereq::Build' => 0.04,
	    'Test::Signature'     => 1.04,
	    @extra_build,
	},
    );

    $m->create_build_script;

If you have any questions on using this module with C<Test::Prereq>,
just email me (address below).

=head2 Use with Module::Install

C<Module::Install> is a module to assist in the bundling of build
prerequisite modules in packages. Well, among other things.

C<Test::Signature> is a perfect candidate for such a module. As it's a
module aimed purely at those writing modules rather than those using
them.

Here's a good way to use it:

Make a test file (say, F<t/00sig.t>) that contains the following:

    use lib 'inc';
    use Test::More tests => 1;
    use Test::Signature;
    signature_ok();

In your F<Makefile.PL> (or F<Build.PL> if appropriate) add:

    include 'Test::Signature';

And that's it! You don't have to specify it as a prerequisite or
anything like that because C<Module::Install> will include it in your
distribution. And you don't have to worry about size because
C<Module::Install> strips out all this waffling POD.

=head1 THANKS

Arthur Bergman for suggesting the module.

Audrey Tang for writing L<Module::Signature>, and making some suggestions.

Tels suggested testing network connectivity to Audrey; Audrey added that
to C<Module::Signature> 0.16 and I (Iain Truskett) added it to this module
(as of 1.03).

=head1 BUGS

Please report bugs at E<lt>bug-test-signature@rt.cpan.orgE<gt>
or via the web interface at L<http://rt.cpan.org>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>
Original author: Iain Truskett E<lt>spoon@cpan.orgE<gt>, now passed away.

=head1 LICENSE AND COPYRIGHT

Copyright 2002, 2003 by Iain Truskett.
Copyright 2003, 2007, 2015 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Module::Signature>, L<Test::More>.

L<Module::Build>, L<ExtUtils::Manifest>, L<ExtUtils::MakeMaker>.

L<Test::Prereq>, L<Module::Install>.

=cut
