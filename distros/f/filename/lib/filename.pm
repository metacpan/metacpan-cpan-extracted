
use v5.10.1;

use strict;
use warnings;

use locale;    # localize $!

use Array::RefElem ();  #qw( hv_store );

package filename;
# ABSTRACT: Perl module to load files at compile-time, without BEGIN blocks.


use Carp 1.50    ();
use File::Spec   ();
use Scalar::Util ();    #qw( blessed refaddr );


our $VERSION = 'v0.20.022'; # VERSION



my ( $do, $eval, $check_inc, $error ) = ();    # Private subs

# Modified version of the code as specified in `perldoc -f require`
*import = \&require;
sub require {
    eval { $_[0]->isa(__PACKAGE__) } && shift
        || Carp::croak( $_[0], " is not a ", __PACKAGE__ );
    my $filename = @_ ? shift : $_;
    Carp::croak("Null filename used") unless length($filename);

    if ( exists $INC{$filename} ) {
        return 1 if $INC{$filename};
        Carp::croak(
              "Attempt to reload $filename aborted.\n"
            . "Compilation failed in require"
        );
    }

    if ( File::Spec->file_name_is_absolute($filename) ) {
        goto NOT_INC if $^V < v5.17.0 && !-r $filename;
        return $do->($filename);
    }
    foreach my $inc (@INC) {
        my $fullpath = $check_inc->( $inc, $filename );
        next unless length($fullpath);
        return ref($fullpath)
            ? $eval->( $$fullpath => $filename, $inc )
            : $do->( $fullpath => $filename );
    }
    NOT_INC:
    my $module = "";
    if ( v5.18.0 <= $^V && $^V < v5.26.0 ) {
        if ( ( my $pm = $filename ) =~ s/\.pm\z// ) {
            $pm =~ s!/!::!g;
            $module = $pm;
        }
        $module = "(you may need to install the $module module) "
            if $module;
    }
    Carp::croak(
        "Can't locate $filename in \@INC $module(\@INC contains: @INC)");
}

### Private subs ###

$check_inc = sub {
    my ( $inc, $filename ) = @_;

    if ( my $ref = ref($inc) ) {
        my $subref = undef;
        if ( defined( my $pkg = Scalar::Util::blessed($inc) ) ) {
            $subref = $inc->can("INC")
                or Carp::croak(
                    qq!Can't locate object method "INC" via package "$pkg"!
                );
        } else {
            $subref
                = $ref eq "ARRAY" ? $inc->[0]
                : $ref eq "CODE"  ? $inc
                :                   return;
        }
        my @elems = $subref->( $inc, $filename );
        return unless @elems && ( my $elem_ref = ref( $elems[0] ) );
        # Possible elements of @elems:
        # SCALAR - Prepended code
        # IO     - Filehandle to read
        # CODE   - Code to execute with IO
        # REF    - State for CODE

        my $code = "";
        if ( $elem_ref eq "SCALAR" ) {
            $code = ${ shift @elems };
            $elem_ref = ref( $elems[0] );
        }

        my $fh = undef;
        if ( $elem_ref eq "GLOB" ) {
            $fh = shift @elems;
            $fh = *{$fh}{IO};
            $elem_ref = ref( $elems[0] );
        }

        my $sub   = undef;
        my $state = undef;
        if ( $elem_ref eq "CODE" ) {
            ( $sub, $state ) = @elems;

            local $_;
            $code .= $_
                while do { $_ = <$fh> if $fh; $sub->( 0, $state ); };
        } elsif ($fh) {
            local $_;
            $code .= $_ while (<$fh>);
        }

        return \$code;
    }

    return unless length($inc);
    my $fullpath = "$inc/$filename";
    return unless -f $fullpath;
    return if $^V < v5.17.0 && !-r _;
    return $fullpath;
};

my $do_text = <<'END';
package $pkg;
my $result = do($fullpath);
$INC{$filename} = delete $INC{$fullpath}
    if $filename ne $fullpath && exists $INC{$fullpath};
if ($@) {
    $INC{$filename} && Array::RefElem::hv_store( %INC, $filename, undef );
    die $@;
}
$result;
END
$do = sub {
    my $fullpath = @_ ? shift : $_;
    my $filename = @_ ? shift : $fullpath;
    my ($pkg)    = caller(2);

    ( my $do_eval = $do_text ) =~ s/\$pkg/$pkg/;
    return eval $do_eval || $error->( $filename => $fullpath );
};

my $eval_text = <<'END';
package $pkg;
my $result = eval $code;
Array::RefElem::hv_store( %INC, $filename, $@ ? undef : $inc );
die $@ if $@;
$result;
END
$eval = sub {
    my $code     = @_ ? shift : $_;
    my $filename = @_ ? shift : $code;
    my $inc      = @_ ? shift : $filename;
    my ($pkg)    = caller(2);

    my $tmpfile = sprintf( "/loader/0x%x/%s",
        Scalar::Util::refaddr( \$code ),
        $filename
    );
    $code = "#line 0 $tmpfile\n" . $code;

    ( my $eval_eval = $eval_text ) =~ s/\$pkg/$pkg/;
    return eval $eval_eval || $error->( $filename => $inc );
};

$error = sub {
    my $filename = @_ ? shift : $_;
    my $fullpath = @_ ? shift : $filename;

    $@ && Carp::croak( $@, "Compilation failed in require" );

    # $INC{$filename} shouldn't be set if we've gotten here,
    # and $! is invalid if $INC{$filename} is true.
    delete $INC{$filename} && undef($!);

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

    # Or, if you need to include a file relative to the program:
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

=head1 VERSION

This document describes version v0.20.022 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
