
use strict;
use warnings;

use locale;    # localize $!

package filename;
# ABSTRACT: Perl module to load files at compile-time, without BEGIN blocks.


use Carp 1.50  ();
use File::Spec ();


our $VERSION = 'v0.20.010'; # VERSION



my ( $do, $error ) = ();    # Private subs

# Modified version of the code as specified in `perldoc -f require`
*import = \&require;
sub require {
    eval { $_[0]->isa(__PACKAGE__) } && shift
        || Carp::croak( $_[0], " is not a ", __PACKAGE__ );
    my $filename = @_ ? shift : $_;
    Carp::croak("Null filename used") unless length($filename);

    return $INC{$filename} if ( exists $INC{$filename} );

    if ( File::Spec->file_name_is_absolute($filename) ) {
        goto NOT_INC if $^V < v5.17.0 && !-r $filename;
        return $do->($filename);
    }
    foreach my $inc (@INC) {
        my $prefix = $inc;
        #if ( my $ref = ref($inc) ) {
        #    # TODO ...
        #}
        next unless -f ( my $fullpath = "$prefix/$filename" );
        next if $^V < v5.17.0 && !-r _;
        return $do->( $fullpath => $filename );
    }
    NOT_INC:
        Carp::croak("Can't locate $filename in \@INC (\@INC contains: @INC)");
}

my $do_text = <<'END';
package $pkg;
my $result = do($fullpath);
die $@ if $@;
$INC{$filename} = delete $INC{$fullpath}
    if $filename ne $fullpath && exists $INC{$fullpath};
$result;
END
$do = sub {
    my $fullpath = @_ ? shift : $_;
    my $filename = @_ ? shift : $fullpath;
    my ($pkg)    = caller(2);

    ( my $do_eval = $do_text ) =~ s/\$pkg/$pkg/;
    return eval $do_eval || $error->( $filename => $fullpath );
};

# Private sub
$error = sub {
    my $filename = @_ ? shift : $_;
    my $fullpath = @_ ? shift : $filename;

    $INC{$filename} &&= undef($!); # $! is invalid if $INC{$filename} is true.

    $@ && Carp::croak( $@, "Compilation failed in require" );

    $! && Carp::croak(
        "Can't locate $filename:   ",
        $^V >= v5.21.0 ? "$fullpath: " : (),
        "$!"
    );

    Carp::croak( $filename, " did not return a true value" );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

filename - Perl module to load files at compile-time, without BEGIN blocks.

=head1 SYNOPSIS

    # Instead of "BEGIN { require '/path/to/file.pm' }"
    # use the more succinct:
    use filename '/path/to/file.pm';

    # Or, if you need to do include a file relative to the program:
    use FindBin qw($Bin);
    use filename "$Bin/../lib/Application.pm";

    # Do it at runtime:
    filename->require('/path/to/file.pm');

    # Throw it into a loop:
    say( 'Required: ', $_ ) foreach grep filename->require, @files;

=head1 DESCRIPTION

This module came about because there was a need to include some standard
boilerplate that included some configuration and application specific paths
to all modules for an application, and to do it at compile time.
Rather than repeating C<BEGIN { require ... }> in every single entry point
for the application, this module was created to simplify the experience.

The intention is to have this module be equivalent to L<perlfunc/require>,
except that it's run at compile time (via L<perlfunc/use>),
rather than at runtime.

=head1 METHODS

=head2 C<require( $filename = $_ )>

Does the equivalent of L<perlfunc/require> on the supplied C<$filename>,
or C<$_> if no argument is provided.

Must be called as a class method: C<< filename->require( $filename ) >>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/filename/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 TODO

=over

=item * Handle references in C<@INC>

=back

=head1 VERSION

This document describes version v0.20.010 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
