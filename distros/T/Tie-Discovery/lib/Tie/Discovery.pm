package Tie::Discovery;

use 5.005;
use strict;
use vars qw( $VERSION @ISA );

$VERSION = '1.11';
@ISA = 'Tie::StdHash';

use Carp;
use Tie::Hash;
use constant SELF  => 0;
use constant KEY   => 1;
use constant VALUE => 2;

sub TIEHASH {
    return bless { debug => 0 }, shift;
}

sub STORE {
    carp "Please don't do this. Use \$obj->store or \$obj->register instead.";
    store(@_);
}

sub store { # ($$$)
    $_[SELF]{ $_[KEY] } = $_[VALUE];
}

sub register { # ($$\&)
    UNIVERSAL::isa($_[VALUE] => 'CODE')
        or croak "Second argument to register() should be coderef";
    $_[SELF]{ $_[KEY] } = $_[VALUE];
}

sub FETCH {
    my $value = $_[SELF]{ $_[KEY] };
    while (UNIVERSAL::isa($value, 'CODE')) {
        print STDERR "(Discovering $_[KEY]... " if $_[SELF]{debug} > 0;
        $value = $_[SELF]{ $_[KEY] } = $value->(@_);
        print STDERR ")" if $_[SELF]->{debug} > 0;
    }
    return $value;
}

1;
__END__

=head1 NAME

Tie::Discovery - Lazily evaluated "discovery" hashes

=head1 VERSION

This document describes version 1.11 of Tie::Discovery, released
January 28, 2009.

=head1 SYNOPSIS

    use Tie::Discovery;
    my %info = ();
    my $obj = tie %info, 'Tie::Discovery';

    sub discover_os { ... }
    $obj->register(os => \&discover_os);

    print $info{os};

=head1 DESCRIPTION

A I<discovery> hash is a hash that's designed to help you solve the data
dependency problem. It's based on the principle of least work; some
times, you may spend a lot of time in your program finding out paths,
filenames, operating system specifics, network information and so on
that you may not end up using. Discovery hashes allow you to get the
data when you need it, and only when you need it.

To use a discovery hash, first tie a hash as shown above. You will want
to keep hold of the object returned by C<tie>. You can then add things
to discover by calling the C<register> method as shown above. The above
code C<$obj-E<gt>register("os", \&discover_os);> means that when (and
only when!) the value C<$info{os}> is fetched, the sub C<&discover_os>
will be called to find it. The return value of that sub will then be
cached to save a look-up next time.

The real power comes from the fact that you may refer to the tied hash
inside of the discovery subroutines. This allows for fast, neat and
flexible top-down programming, and helps you avoid hard-coding values. 
For instance, let us find the OS by calling the F<uname> program:

    $obj->register( os => sub {
        # Here $self is the same as $obj above
        my $self = shift;
        my $uname = $self->FETCH('path_to_uname');
        return `$uname`;
    } );

Alternatively, if the tied C<%info> is still in scope, this will also do:

    $obj->register( os => sub {
        my $uname = $info{path_to_uname};
        return `$uname`;
    } );

Now we need code to find the program itself:

    use Config;
    use File::Spec::Functions;
    $obj->register( path_to_uname => sub {
        my $self = shift;
        foreach (split($Config{path_sep}, $ENV{PATH})) {
            return catfile($_, 'uname') if -x catfile($_, 'uname');
        }
        die "Couldn't even find uname";
    };

Fetching C<$info{os}> may now need a further call to fetch
C<$info{path_to_uname}> unless the path is already cached. And, of
course, we needn't stop at two levels.

Note that, since version 1.10, as long as the discovery function
returns a code reference, it will be invoked repeatedly, until a
final value is produced.

=head2 METHODS

Aside from the usual hash methods, the following are available:

=head3 register($name, \&code)

Registers C<name> as an entry in the hash, to be discovered by running
C<sub>

=head3 store($name, $value)

Stores C<value> directly into the hash under the C<name> key. The only
time you should need to do this is to set the value of the C<debug> key;
if set, this shows a trace of the discovery process.

=head2 CAVEATS

At present, since a subroutine reference signifies something to look
up, you can't usefully return one from your discovery subroutine. 

=head1 SEE ALSO

L<Scalar::Defer>, in particular its C<lazy()> function that provides a
viable alternative to this module.

L<Tie::Hash>

=head1 AUTHORS

Simon Cozens <simon@cpan.org>,
Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2004-2009 by
Simon Cozens <simon@cpan.org>,
Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
