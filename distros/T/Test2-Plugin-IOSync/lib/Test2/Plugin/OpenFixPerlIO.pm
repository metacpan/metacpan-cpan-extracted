package Test2::Plugin::OpenFixPerlIO;
use strict;
use warnings;

our $VERSION = '0.000007';

use Carp qw/cluck/;
use PerlIO;

BEGIN {
    my $maker = sub {
        my ($pkg) = @_;
        my ($open, $layers, $binmode);

        my $ok = eval "#line ${ \__LINE__ } \"${ \__FILE__ }\"\n
        package $pkg;" . '

        $open = sub {
            no strict q(refs);
            return CORE::open($_[0]) if @_ == 1;
            return CORE::open($_[0], $_[1]) if @_ == 2;
            return CORE::open($_[0], $_[1], @_[2 .. $#_]);
        };

        $layers = sub { PerlIO::get_layers($_[0]) };

        $binmode = sub { binmode($_[0], $_[1]) };

        1;
        ';
        die "Eval failed for ${pkg}: $@" unless $ok;
        return [$open, $layers, $binmode];
    };

    my %opens;
    my $new_open = sub (*;$@) {
        my ($in, @args) = @_;

        my $caller = caller;

        $opens{$caller} ||= $maker->($caller);

        my @keep_layers;

        if ($args[0] =~ m/^(\+?>{1,2})\&(.*)$/) {
            my $handle = $2 || $args[1];

            my $is_fileno = $handle =~ m/^\d+$/;

            my @layers = $opens{$caller}->[1]->($handle);
            @keep_layers = grep { $_ ne 'via' } @layers;

            if (!$is_fileno && @layers != @keep_layers) {
                my $fileno;
                if (ref($handle) eq 'GLOB') {
                    $fileno = fileno($handle);
                }
                elsif ($handle =~ m/^\d+$/) {
                    $fileno = $handle;
                }
                else {
                    no strict 'refs';
                    no warnings 'once';
                    $fileno = $handle =~ m/^\*(.*)$/ ? fileno(\*{$1}) : fileno(\*{"$caller\::$handle"});
                }

                $args[0] =~ s/\Q$handle\E$//;
                $args[1] = $fileno;
            }
            else {
                @keep_layers = ();
            }
        }

        # Need to pass $_[0] in for magic.
        my $out = $opens{$caller}->[0]->($_[0], @args);
        return $out unless defined $out;

        if (@keep_layers) {
            my %have = map {$_ => 1} $opens{$caller}->[1]->($_[0]);
            my $binmode = join '' => map ":$_", grep { !$have{$_} } @keep_layers;
            $opens{$caller}->[2]->($_[0], $binmode) if $binmode;
        }
        return $out;
    };

    bless $new_open, __PACKAGE__;

    no warnings 'once';
    *CORE::GLOBAL::open = $new_open;

    # Make sure the global reference is the only reference
    $new_open = undef;
}

my $WE_CARE = 1;
END { $WE_CARE = 0 };
sub DESTROY {
    cluck "DESTROYED 'CORE::GLOBAL::open' override before it was time!" if $WE_CARE && !$^C;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::OpenFixPerlIO - Override CORE::GLOBAL::open() to fix perlio via
cloning.

=head1 DESCRIPTION

Normally you cannot clone an IO handle that has a L<PerlIO::via> layer applied
to it, it will crash. This plugin overrides C<CORE::GLOBAL::open()> so that it
handles it better (by not trying to copy the 'via' layer).

=head1 SYNOPSIS

    use Test2::Plugin::OpenFixPerlIO;

    binmode(STDOUT, ':via(Some::Class)');

    # This will crash without the plugin.
    open(my $STDOUT_CLONE, '>&', \*STDOUT);

=head1 CAVEATS

=over 4

=item CORE::GLOBAL::open override

Obviosuly this will be a problem if anything else overrides
C<CORE::GLOBAL::open>.

=item Cannot use a bareword as the third argument

Normally this is allowed:

    open(CLONE, '>&', STDOUT);

This will be a syntax error with this plugin. The limitations if perl's
prototypes mean we cannot make the third argument accept a bareword without
breaking the 4+ arg syntax.

The prototype we use: C<sub (*;$@) { ... }>. We could also use
C<sub (*;$*@) { ... }> which would allow the third argument to be a bareword,
but that breaks things if the final arguments are provided as a list or array:
C<< open(my $fh, '>', qw/echo hi/) >>, which would become
C<< open(my $fh, '>', 'hi') >> because of how a list is flattened by the '*' in
the prototype.

=back

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
