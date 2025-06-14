package exact::conf;
# ABSTRACT: Cascading merged application configuration extension for exact

use 5.014;
use exact;

our $VERSION = '1.09'; # VERSION

sub import {
    my ( $self, $params, $caller ) = @_;
    $caller //= caller();

    my @params = grep { length } split( /[,\s]+/, $params || '' );

    require Config::App;
    Config::App->import(@params) if ( @params or not length $params );

    {
        no strict 'refs';
        my $method = 'conf';
        *{ $caller . '::' . $method } = \&$method unless ( defined &{ $caller . '::' . $method } );
    }
}

sub conf {
    shift;
    return Config::App->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact::conf - Cascading merged application configuration extension for exact

=head1 VERSION

version 1.09

=for markdown [![test](https://github.com/gryphonshafer/exact-conf/workflows/test/badge.svg)](https://github.com/gryphonshafer/exact-conf/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/exact-conf/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/exact-conf)

=head1 SYNOPSIS

    use exact -conf;

=head1 DESCRIPTION

L<exact::conf> is a cascading merged application configuration extension for
L<exact>. It effectively is an integration of L<Config::App> with L<exact>.
Consult the L<Config::App> documentation for additional information.
See the L<exact> documentation for additional information about
extensions. The intended use of L<exact::conf> is via the extension interface
of L<exact>.

    use exact -conf, -cli, -noutf8;

However, you can also use it directly, which will also use L<exact> with
default options:

    use exact::conf;

=head1 IMPORTED FUNCTION

There is only 1 imported function:

=head2 conf

This...

    use exact -conf;
    say conf->get('answer');

...is equivalent to this...

    use Config::App;
    say Config::App->new->get('answer');

If you'd like to load L<Config::App> but skip its default import process that
looks for default-location-located configuration files and errors if it can't
find such, pass some false value. For example, if you want to specify a
non-default-located configuration file at runtime, do this:

    use exact 'conf(0)';
    say conf('settings/conf.yaml')->get('answer');

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact-conf>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact::conf>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/exact-conf/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/exact-conf>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact-conf>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/D/exact-conf.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
