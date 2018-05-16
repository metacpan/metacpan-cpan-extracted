package lazy;

use strict;
use warnings;

our $VERSION = '0.000005';

use App::cpm 0.974;    # CLI has no $VERSION
use App::cpm::CLI;

# Cargo-culted from App::cpm::CLI
# Adding pass_through so that we don't have to keep up with all possible options
use Getopt::Long qw(
    :config
    no_auto_abbrev
    no_ignore_case
    bundling
    pass_through
);

use Module::Loaded qw( is_loaded );

sub import {
    shift;
    my @args = @_;

    my $is_global;
    my $local_lib;

    {
        local @ARGV = @args;

        # Stolen from App::cpm::CLI::parse_options()
        GetOptions(
            'L|local-lib-contained=s' => \$local_lib,
            'g|global'                => \$is_global,
        );
    }

    # Generally assume a global install, which makes the invocation as
    # simple as:

    # perl -Mlazy foo.pl

    # However, if we're already using local::lib and --global has not been
    # explicitly set and no local::lib has been explicitly set, let's try
    # to DTRT and use the correct local::lib.

    # This allows us to do something like:
    # perl -Mlocal::lib -Mlazy foo.pl

    # This may or may not be a good idea.

    # Allowing --local-lib-contained to be passed is mostly useful for
    # testing.  For real world cases, the user should specify the
    # local::lib via local::lib itself.

    # perl -Mlocal::lib=my_local_lib -Mlazy foo.pl

    if ( ( !$is_global && !$local_lib ) && is_loaded('local::lib') ) {
        my @paths = local::lib->new->active_paths;
        my $path  = shift @paths;
        if ($path) {
            push @args, ( '-L', $path );
            _print_msg_about_local_lib($path);
        }
    }

    # Assume a global install if local::lib is not in use or has not been
    # explicitly invoked.

    elsif ( !$is_global && !$local_lib ) {
        push @args, ('-g');
    }

    my $cpm = App::cpm::CLI->new;

    # Push the hook onto @INC and then re-add all of @INC again.  This way, if
    # we got to the hook and tried to install, we can re-try @INC to see if the
    # module can now be used.

    push @INC, sub {
        shift;

        # Don't try to install if we're called inside an eval
        my @caller = caller(1);
        return
            if ( ( $caller[3] && $caller[3] =~ m{eval} )
            || ( $caller[1] && $caller[1] =~ m{eval} ) );

        my $name = shift;
        $name =~ s{/}{::}g;
        $name =~ s{\.pm\z}{};

        $cpm->run( 'install', @args, $name );
        return 1;
    }, @INC;
}

sub _print_msg_about_local_lib {
    my $path = shift;

    print <<"EOF";

********

You haven't included any arguments for App::cpm via lazy, but you've
loaded local::lib, so we're going to install all modules into:

$path

If you do not want to do this, you can explicitly invoke a global install via:

    perl -Mlazy=-g path/to/script.pl

or, from inside your code:

    use lazy qw( -g );

If you would like to install to a different local lib:

    perl -Mlocal::lib=my_local_lib -Mlazy path/to/script.pl

or, from inside your code:

    use local::lib qw( my_local_lib );
    use lazy;

********

EOF
}

1;

# ABSTRACT: Lazily install missing Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

lazy - Lazily install missing Perl modules

=head1 VERSION

version 0.000005

=head1 SYNOPSIS

    # Auto-install missing modules globally
    perl -Mlazy foo.pl

    # Auto-install missing modules into local_foo/.  Note local::lib needs to
    # precede lazy in this scenario in order for the script to compile on the
    # first run.
    perl -Mlocal::lib=local_foo -Mlazy foo.pl

    # Auto-install missing modules into local/
    use local::lib 'local';
    use lazy;

    # Auto-install missing modules globally
    use lazy;

    # Same as above, but explicity auto-install missing modules globally
    use lazy qw( -g );

    # Use a local::lib and get verbose, uncolored output
    perl -Mlocal::lib=foo -Mlazy=-v,--no-color

=head2 DESCRIPTION

Your co-worker sends you a one-off script to use.  You fire it up and realize
you haven't got all of the dependencies installed in your work environment.
Now you fire up the script and one by one, you find the missing modules and
install them manually.

Not anymore!

C<lazy> will try to install any missing modules automatically, making your day
just a little less long.  C<lazy> uses L<App::cpm> to perform this magic in the
background.

=head2 USAGE

You can pass arguments directly to L<App::cpm> via the import statement.

    use lazy qw( --verbose );

Or

    use lazy qw( --man-pages --with-recommends --verbose );

You get the idea.

This module uses L<App::cpm>'s defaults, with the exception being that we
default to global installs rather than local.

So, the default usage would be:

    use lazy;

If you want to use a local lib:

    use local::lib qw( my_local_lib );
    use lazy;

Lazy will automatically pick up on your chosen local::lib and install there.
Just make sure that you C<use local::lib> before you C<use lazy>.

=head2 CAVEATS

* If not installing globally, C<use local::lib> before you C<use lazy>

* Don't pass the C<-L> or C<--local-lib-contained> args directly to C<lazy>.  Use L<local::lib> directly to get the best (and least confusing) results.

* Remove C<lazy> before you put your work into production.

=head2 SEE ALSO

L<Acme::Magic::Pony>, L<lib::xi>, L<CPAN::AutoINC>, L<Module::AutoINC>

=head2 ACKNOWLEDGEMENTS

This entire idea was ripped off from L<Acme::Magic::Pony>.  The main difference
is that we use L<App::cpm> rather than L<CPAN::Shell>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
