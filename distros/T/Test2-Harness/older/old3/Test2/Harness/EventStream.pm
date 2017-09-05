package Test2::Harness::EventStream;
use strict;
use warnings;
use PerlIO();

BEGIN {
    my $maker = sub {
        my ($pkg) = @_;
        my ($open, $layers);

        my $ok = eval "#line ${ \__LINE__ } \"${ \__FILE__ }\"\n
            package $pkg;" . '

            $open = sub {
                no strict q(refs);
                if (@_ == 1) {
                    return CORE::open($_[0]);
                }
                elsif (@_ == 2) {
                    return CORE::open($_[0], $_[1]);
                }
                elsif (@_ >= 3) {
                    return CORE::open($_[0], $_[1], @_[2 .. $#_]);
                }
            };

            $layers = sub { PerlIO::get_layers($_[0]) };

            1;
        ';
        die "Eval failed for ${pkg}: $@" unless $ok;
        return [$open, $layers];
    };

    my %opens;
    *CORE::GLOBAL::open = sub (*;$@) {
        my ($in, @args) = @_;

        my $caller = caller;

        $opens{$caller} ||= $maker->($caller);

        if ($args[0] =~ m/^(>{1,2})\&(.*)$/) {
            my $handle = $2 || $args[1];

            my $is_fileno = $handle =~ m/^\d+$/;

            if (!$is_fileno && grep { $_ eq 'via' } $opens{$caller}->[1]->($handle)) {
                my $fileno = $handle =~ m/^\d+$/ ? $handle : fileno($handle);
                $args[0] =~ s/\Q$handle\E$/$fileno/;
                $args[1] = $fileno if $args[1];
            }
        }

        # Need to pass $_[0] in for magic.
        $opens{$caller}->[0]->($_[0], @args);
    };
}

sub import {
    require PerlIO::via::Test2;

    local %PerlIO::via::Test2::PARAMS = (stream_name => 'STDOUT');
    binmode(STDOUT, ':via(PerlIO::via::Test2)') or die "Could not add Test2 PerlIO layer: $!";

    local %PerlIO::via::Test2::PARAMS = (stream_name => 'STDERR', diagnostics => 1);
    binmode(STDERR, ':via(PerlIO::via::Test2)') or die "Could not add Test2 PerlIO layer: $!";
}

1;
