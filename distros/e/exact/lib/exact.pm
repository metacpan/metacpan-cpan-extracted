package exact;
# ABSTRACT: Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

use 5.014;
use strict;
use warnings;
use namespace::autoclean;
use Try::Tiny;

our $VERSION = '1.08'; # VERSION

use feature    ();
use utf8       ();
use mro        ();
use IO::File   ();
use IO::Handle ();
use Carp       qw( croak carp confess cluck );

my %features = (
    10 => [ qw( say state switch ) ],
    12 => ['unicode_strings'],
    16 => [ qw( unicode_eval evalbytes current_sub fc ) ],
    18 => ['lexical_subs'],
    24 => [ qw( postderef postderef_qq ) ],
    28 => ['bitwise'],
);

my %deprecated = (
    16 => ['array_base'],
);

my %experiments = (
    20 => ['signatures'],
    22 => ['refaliasing'],
    26 => ['declared_refs'],
);

my @function_list = qw(
    nostrict nowarnings noutf8 noc3 nobundle noexperiments noskipexperimentalwarnings noautoclean nocarp notry
);

my @feature_list   = map { @$_ } values %features, values %deprecated, values %experiments;
my ($perl_version) = $^V =~ /^v5\.(\d+)/;

my @autoclean_parameters;

sub import {
    shift;
    my ( @bundles, @functions, @features, @subclasses );
    for (@_) {
        my $opt = lc $_;

        if ( grep { $_ eq $opt } @feature_list ) {
            push( @features, $opt );
        }
        elsif ( grep { $_ eq $opt } @function_list ) {
            push( @functions, $opt );
        }
        elsif ( $opt =~ /^:?v?5?\.?(\d+)/ and $1 >= 10 ) {
            push( @bundles, $1 );
        }
        else {
            push( @subclasses, $opt );
        }
    }

    strict->import unless ( grep { $_ eq 'nostrict' } @functions );
    warnings->import unless ( grep { $_ eq 'nowarnings' } @functions );

    unless ( grep { $_ eq 'noutf8' } @functions ) {
        utf8->import;
        binmode( $_, ':utf8' ) for ( *STDIN, *STDERR, *STDOUT );
    }

    mro::set_mro( scalar caller(), 'c3' ) unless ( grep { $_ eq 'noc3' } @functions );

    if (@bundles) {
        my ($bundle) = sort { $b <=> $a } @bundles;
        feature->import( ':5.' . $bundle );
    }
    elsif ( not grep { $_ eq 'nobundle' } @functions ) {
        feature->import( ':5.' . $perl_version );
    }

    try {
        feature->import($_) for (@features);
        my @experiments = map { @{ $experiments{$_} } } grep { $_ <= $perl_version } keys %experiments;
        feature->import(@experiments) unless ( not @experiments or grep { $_ eq 'noexperiments' } @functions );
    }
    catch {
        my $err = $_;
        $err =~ s/\s*at .+? line \d+\.\s+//;
        croak("$err via use of exact");
    };

    warnings->unimport('experimental')
        unless ( $perl_version < 18 or grep { $_ eq 'noskipexperimentalwarnings' } @functions );

    my $caller = caller();
    unless ( grep { $_ eq 'nocarp' } @functions ) {
        no strict 'refs';
        *{ $caller . '::croak' }   = \&croak;
        *{ $caller . '::carp' }    = \&carp;
        *{ $caller . '::confess' } = \&confess;
        *{ $caller . '::cluck' }   = \&crcluck;
    }

    eval qq{
        package $caller {
            use Try::Tiny;
        };
    } unless ( grep { $_ eq 'notry' } @functions );

    for my $opt (@subclasses) {
        my $params = ( $opt =~ s/\(([^\)]+)\)// ) ? [$1] : [];

        ( my $pm = $opt ) =~ s{::|'}{/}g;
        require "exact/$pm.pm";

        if ( my $e = lcfirst($@) ) {
            my $v = __PACKAGE__->VERSION;
            croak(
                qq{Either "$opt" not supported by exact} .
                ( ($v) ? ' ' . $v : '' ) .
                qq{ or $e}
            );
        }

        "exact::$opt"->import( scalar caller(), @$params ) if ( "exact::$opt"->can('import') );
    }

    namespace::autoclean->import( -cleanee => scalar caller(), @autoclean_parameters )
        unless ( grep { $_ eq 'noautoclean' } @functions ) ;
}

sub autoclean {
    my $self = shift;

    my $i = 0;
    my $caller;
    while (1) {
        $caller = caller($i);
        last if ( not $caller or $caller !~ /^exact\b/ );
        $i++;
    }

    @autoclean_parameters = @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

exact - Perl pseudo pragma to enable strict, warnings, features, mro, filehandle methods

=head1 VERSION

version 1.08

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/exact.svg)](https://travis-ci.org/gryphonshafer/exact)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/exact/badge.png)](https://coveralls.io/r/gryphonshafer/exact)

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use utf8;
    use open ':std', ':utf8';
    use feature ':5.23';
    use feature qw( signatures refaliasing bitwise );
    use mro 'c3';
    use IO::File;
    use IO::Handle;
    use namespace::autoclean;
    use Carp qw( croak carp confess cluck );
    use Try::Tiny;

    no warnings "experimental::signatures";
    no warnings "experimental::refaliasing";
    no warnings "experimental::bitwise";

Type this:

    use exact;

Or for finer control, add some trailing modifiers like a line of the following:

    use exact '5.20';
    use exact 5.16, nostrict, nowarnings, noc3, noutf8, noexperiments, noautoclean;
    use exact noexperiments, fc, signatures;

=head1 DESCRIPTION

L<exact> is a Perl pseudo pragma to enable strict, warnings, features, mro,
and filehandle methods. The goal is to reduce header boilerplate, assuming
defaults that seem to make sense but allowing overrides easily.

By default, L<exact> will:

=over 4

=item *

enable L<strictures> (version 2)

=item *

load the latest L<feature> bundle supported by the current Perl version

=item *

load all experimental L<feature>s and switch off experimental warnings

=item *

set C3 style of L<mro>

=item *

use utf8 in the source code context and set STDIN, STROUT, and STRERR to handle UTF8

=item *

enable methods on filehandles

=item *

import L<Carp>'s 4 methods

=item *

import (kinda) L<Try::Tiny>

=back

=head1 IMPORT FLAGS

L<exact> supports the following import flags:

=head2 C<nostrict>

This skips turning on the L<strict> pragma.

=head2 C<nowarnings>

This skips turning on the L<warnings> pragma.

=head2 C<noutf8>

This skips turning on UTF8 in the source code context. Also skips setting
STDIN, STDOUT, and STDERR to expect UTF8.

=head2 C<noc3>

This skips setting C3 L<mro>.

=head2 C<nobundle>

Normally, L<exact> will look at your current version and find the highest
supported L<feature> bundle and enable it. Applying C<nobundle> causes this
behavior to be skipped. You can still explicitly set bundles yourself.

=head2 C<noexperiments>

This skips enabling all features currently labled experimental by L<feature>.

=head2 C<noskipexperimentalwarnings>

Normally, L<exact> will disable experimental warnings. This skips that
disabling step.

=head2 C<noautoclean>

This skips using L<namespace::autoclean>.

=head2 C<nocarp>

This skips importing the 4 L<Carp> methods: C<croak>, C<carp>, C<confess>,
C<cluck>.

=head2 C<notry>

This skips importing the functionality of L<Try::Tiny>.

=head1 BUNDLES

You can always provide a list of explicit features and bundles from L<feature>.
If provided, these will be enabled regardless of the other import flags set.

    use exact noexperiments, fc, signatures;

Bundles provided can be exactly like those described in L<feature> or in a
variety of obvious forms:

=over 4

=item *

:5.26

=item *

5.26

=item *

v5.26

=item *

26

=back

=head1 METHODS

=head2 C<autoclean>

Normally, unless you include the C<noautoclean> flag, L<namespace::autoclean>
will automatically clean your namespace. You can pass flags to autoclean via:

    exact->autoclean( -except => [ qw( method_a method_b) ] );

Note that for this to have any effect, it needs to be called from within your
module's C<import> method.

=head1 EXTENSIONS

It's possible to write extensions or plugins for L<exact> to provide
context-specific behavior, provided you are using Perl version 5.14 or newer.
To activate these extensions, you need to provide their named suffix as a
parameter to the C<use> of L<exact>.

    # will load "exact" and "exact::class";
    use exact class;

    # will load "exact" and "exact::role" and turn off UTF8 features;
    use exact role, noutf8;

It's possible to provide parameters to the C<import> method of the extension.

    # will load "exact" and "exact::answer" and pass "42" to the import method
    use exact 'answer(42)';

=head2 Writing Extensions

An extension may but is not required to have an C<import> method. If such a
method does exist, it will be passed: the package name, the name of the caller
of L<exact>, and any parameters passed.

    package exact::example;
    use exact;

    sub import {
        my ( $self, $caller, $params ) = @_;
        {
            no strict 'refs';
            *{ $caller . '::example' } = \&example;
        }
        exact->autoclean( -except => ['example'] );
    }

    sub example {
        say 42;
    }

    1;

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/exact>

=item *

L<CPAN|http://search.cpan.org/dist/exact>

=item *

L<MetaCPAN|https://metacpan.org/pod/exact>

=item *

L<AnnoCPAN|http://annocpan.org/dist/exact>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/exact>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/exact>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/exact>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/exact.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
