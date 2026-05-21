package lazy;

use strict;
use warnings;
use feature qw( state );

our $VERSION = '1.000002';

use App::cpm 0.997017 ();                # CLI has no $VERSION
use App::cpm::CLI     ();
use Carp              qw( longmess );
use Sub::Name         qw( subname );
use Sub::Identify     qw( sub_name );
use Try::Tiny         qw( catch try );

# Cargo-culted from App::cpm::CLI
# Adding pass_through so that we don't have to keep up with all possible options
use Getopt::Long qw(
    :config
    no_auto_abbrev
    no_ignore_case
    bundling
    pass_through
);

sub import {
    shift;
    my @args = @_;

    my $local_lib;

    # Don't add this to @INC twice
    for my $i (@INC) {
        next unless ref $i && ref $i eq 'CODE';
        return if sub_name($i) eq '_lazy_worker';
    }

    {
        local @ARGV = @args;

        # Stolen from App::cpm::CLI::parse_options()
        # We only need to peek at -L here; everything else (including -g) is
        # forwarded to App::cpm via pass_through.
        GetOptions(
            'L|local-lib-contained=s' => \$local_lib,
        );
    }

    # Generally assume a global install, which makes the invocation as
    # simple as:

    # perl -Mlazy foo.pl
    #
    # To install into ./local:
    # perl -Mlazy='-Llocal'
    #
    # To install into ./some-other-dir:
    # perl -Mlazy='-Lsome-other-dir'

    # Ensure global install by default
    if ( !$local_lib ) {
        print "🌍 global install if required\n" unless $ENV{HARNESS_ACTIVE};
        push @args, ('-g');
    }
    else {
        print "🔨 Installing into $local_lib if required\n"
            unless $ENV{HARNESS_ACTIVE};
        require local::lib;
        local::lib->import($local_lib);
    }

    my $cpm = App::cpm::CLI->new;

    # Push the hook onto @INC and then re-add all of @INC again.  This way, if
    # we got to the hook and tried to install, we can re-try @INC to see if the
    # module can now be used.
    my $_lazy = sub {
        shift;
        my $name = shift;

        state %seen;
        $seen{$name}++;
        return if $seen{$name} > 1;    # Limit recursion to a single attempt

        $name =~ s{/}{::}g;
        $name =~ s{\.pm\z}{};

        if ( $name =~ qr{\Aauto::.*\.al\z} ) {
            warn "skipping autoloader file $name";
            return;
        }
        if ( $name =~ qr{\ANet::DNS::Resolver::} ) {
            warn "skipping $name";
            return;
        }
        if ( $name eq 'Encode::ConfigLocal' ) {
            warn "skipping $name";
            return;
        }

        warn "lazy: installing $name ...\n";
        try {
            $cpm->run( 'install', @args, $name );
        }
        catch {
            warn "Failed to install $name: " . longmess();
            warn $_;
        };

        return;
    };
    subname '_lazy_worker', $_lazy;
    push @INC, $_lazy, @INC;
}

1;

# ABSTRACT: Lazily install missing Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

lazy - Lazily install missing Perl modules

=head1 VERSION

version 1.000002

=head1 SYNOPSIS

    # At the command line
    # --------------------------------------------------

    # Auto-install missing modules globally
    perl -Mlazy foo.pl

    # Auto-install missing modules into ./local
    perl -Mlazy='-Llocal' foo.pl

    # Auto-install missing modules into ./some-other-dir
    perl -Mlazy='-Lsome-other-dir' foo.pl

    # Via PERL5OPT, e.g. when prove invokes perl for you
    # --------------------------------------------------

    PERL5OPT=-Mlazy prove -lvr t
    PERL5OPT=-Mlazy=-Llocal prove -lvr t

    # In your code
    # --------------------------------------------------

    # Auto-install missing modules globally
    use lazy;

    # Auto-install missing modules into ./local
    use local::lib;
    use lazy qw( -L local );

    # Auto-install missing modules into ./some-other-dir
    use local::lib qw( some-other-dir );
    use lazy qw( -L some-other-dir );

    # Auto-install missing modules into ./some-other-dir and pass more options to App::cpm
    use local::lib qw( some-other-dir );
    use lazy qw( -L some-other-dir --man-pages --verbose --no-color );

    # In a one-liner?
    # --------------------------------------------------

    # Install App::perlimports via a one-liner, but why would you want to?
    perl -Mlazy -MApp::perlimports -E 'say "ok"'

=head1 DESCRIPTION

Your co-worker sends you a one-off script to use.  You fire it up and realize
you haven't got all of the dependencies installed in your work environment.
Now you fire up the script and one by one, you find the missing modules and
install them manually.

Not anymore!

C<lazy> will try to install any missing modules automatically, making your day
just a little less long.  C<lazy> uses L<App::cpm> to perform this magic in the
background.

=head1 USAGE

    perl -Mlazy foo.pl

Or use a local lib:

    perl -Mlazy='-Llocal' foo.pl

You can pass arguments directly to L<App::cpm> via the import statement.

    use lazy qw( --verbose );

Or

    use lazy qw( --man-pages --with-recommends --verbose );

You get the idea.

This module uses L<App::cpm>'s defaults, with the exception being that we
default to global installs rather than local.

So, the default usage would be:

    use lazy;

If you want to install to a local lib, use L<local::lib> first:

    use local::lib qw( my-local-lib );
    use lazy    q( -L my-local-lib );

=head2 Via C<PERL5OPT>

If C<prove> is invoking C<perl> for you, set L<perlrun/PERL5OPT> in the
environment and each spawned C<perl> will pick C<lazy> up automatically:

    PERL5OPT=-Mlazy prove -lvr t
    PERL5OPT=-Mlazy=-Llocal prove -lvr t

Note that C<PERL5OPT> uses commas to separate import arguments (per
L<perlrun>), where C<-M> on the command line uses spaces.

=head1 CAVEATS

* Remove C<lazy> before you put your work into production.

=head1 SEE ALSO

L<Acme::Intraweb>, L<Acme::Magic::Pony>, L<CPAN::AutoINC>, L<lib::xi>, L<Module::AutoINC>, L<Module::AutoLoad>, L<The::Net> and L<Class::Autouse>

=head1 ACKNOWLEDGEMENTS

This entire idea was ripped off from L<Acme::Magic::Pony>.  The main difference
is that we use L<App::cpm> rather than L<CPAN::Shell>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
