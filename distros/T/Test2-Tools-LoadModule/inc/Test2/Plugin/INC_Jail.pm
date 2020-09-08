package Test2::Plugin::INC_Jail;

use 5.008001;

use strict;
use warnings;

use Carp;

our $VERSION = '0.003';

sub import {
    my ( undef, $test_class, @test_inc ) = @_;

    my $caller = caller;

    unless ( defined $test_class ) {
	my $code = $caller->can( 'CLASS' )
	    or croak 'No test class specified and caller does not define CLASS';
	$test_class = $code->();
    }

    @test_inc
	or push @test_inc, 't/lib';
    foreach ( @test_inc ) {
	-d
	    or croak "Test module directory $_ not found";
    }

    unshift @INC, sub {

	my $lvl = 0;

	while ( my $pkg = caller $lvl ) {

	    if ( $test_class eq $pkg ) {
		foreach my $dir ( @test_inc ) {
		    my $fh;
		    open $fh, '<', "$dir/$_[1]"
			and return $] ge '5.020' ? ( \'', $fh ) : $fh;
		}
		croak "Can't locate $_[1] in \@INC";
	    }

	    # The reason we have to iterate if the package is our
	    # original caller is that the module under test might be
	    # loading the requested module on behalf of said caller by
	    # doing a stringy eval in the caller's name space.
	    $caller eq $pkg
		or return;

	} continue {
	    $lvl++;
	}
	return;
    };

    return;
}

1;

__END__

=head1 NAME

Test2::Plugin::INC_Jail - Create an @INC jail for the module under test

=head1 SYNOPSIS

 use Test2::V0 -target => 'My::Module::Under::Test';
 
 # The following defaults the module under test to CLASS, and the
 # directory containing the modules it loads to t/lib
 use Test2::Plugin::INC_Jail;
 
 # The following will be found anywhere in @INC except t/lib
 use Test2::Tools::Explain; # Comes from anywhere in @INC
 
 # Test::Module will be found, if at all, ONLY in t/lib
 CLASS->do_something_that_loads( 'Test::Module' );

=head1 DESCRIPTION

This module is B<private> to the C<Test2-Tools-LoadModule> distribution.
It can be changed or revoked at any time. It is written as a
C<Test2::Plugin> simply as a feasability study.

This module creates an @INC jail for the module under test.

When you C<use()> this module you can specify arguments.

The first is the name of the module under test. If undefined, this
defaults to the value of C<CLASS> found in the script that loaded this
module. If C<CLASS> is not found an exception is thrown.

The second and subsequent arguments are the names of directories
containing modules to be loaded by the module under test. If
unspecified, this defaults to F<t/lib/>. If any of the directories do
not exist, an exception is thrown.

Modules loaded by the module under test can come only from the specified
directory. Modules loaded by anyone else can never come from the
specified directory.

B<Note> that this plug-in does not implement a way to get out of jail.
If you need this, open a block, localize C<@INC>, and close the block
when you are done:

 {
   local @INC = @INC;
   use Test2::Plugin::INC_Jail;
 
   # Any tests requiring the jail.
 
 }
 
 # @INC is now back the way it was before.

=head1 SEE ALSO

L<Test2::V0|Test2::V0>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
