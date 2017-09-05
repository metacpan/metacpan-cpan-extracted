package lazy;
$lazy::VERSION = '0.000001';
use strict;
use warnings;

use App::cpm;

# Push the hook onto @INC and then re-add all of @INC again.  This way, if we
# got to the hook and tried to install, we can re-try @INC to see if the module
# can now be used.

sub import {
    shift;
    my @args = @_;

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
        App::cpm->new->run( 'install', @args, $name );
        return 1;
    }, @INC;
}

1;

# ABSTRACT: Lazily install missing Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

lazy - Lazily install missing Perl modules

=head1 VERSION

version 0.000001

=head1 SYNOPSIS

    # Auto-install missing modules into local/.  Note local::lib needs to
    # precede lazy in this scenario in order for the script to compile on the
    # first run.
    perl -Mlocal::lib=local -Mlazy foo.pl

    # Auto-install missing modules globally
    perl -Mlocal::lib -Mlazy=--global foo.pl

    # Auto-install missing modules into local/
    use local::lib 'local';
    use lazy;

    # Auto-install missing modules globally
    use lazy qw( --global );

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

    use lazy qw( --global --verbose );

You get the idea.

This module uses L<App::cpm>'s defaults, so by default modules will be
installed to a folder called C<local> in your current working directory.  This
folder will be created on demand.

So, the default usage would be:

    use local::lib 'local';
    use lazy;

If you want the module available generally, use the C<--global> switch.

    use lazy qw( --global );

=head2 CAVEATS

Be sure to remove C<lazy> before you put your work into production.

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
