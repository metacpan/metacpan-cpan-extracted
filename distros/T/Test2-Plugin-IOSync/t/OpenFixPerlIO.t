# Make sure loading it multiple times is not a problem
use Test2::Plugin::OpenFixPerlIO;
use Test2::Plugin::OpenFixPerlIO;
use Test2::Plugin::OpenFixPerlIO;
use Test2::Bundle::Extended;

use IO::Handle;

{
    package PerlIO::via::XXX;

    sub PUSHED {
        my $class = shift;
        bless {}, $class;
    }

    sub WRITE {
        my ($self, $buffer, $handle) = @_;

        print $handle $buffer;
        return length($buffer);
    }
}

use File::Temp qw/tempfile/;
my ($fh, $name) = tempfile("$$-XXXXXXXX");
binmode($fh, ':via(PerlIO::via::XXX):utf8');

ok(
    lives {
        is(
            warnings {
                local *FH; # So that it closes with the scope end

                open(my $clone1, '>&', $fh) or die "Could not clone handle (3 arg): $!";
                open(my $clone2, '>&' . fileno($fh)) or die "Could not clone handle (2 arg, errorno): $!";
                open(FH, '>&', $fh) or die "Could not clone: $!";
                binmode(FH, ':via(PerlIO::via::XXX)');
                open(my $clone3, '>&FH') or die "Could not clone handle (2 arg, bareword): $!";
                open(my $clone4, '>&', *FH) or die "Could not clone handle (3 arg, bareword): $!";

                my ($clone5, $clone6);
                {
                    package Foo::Bar;
                    local *FH = *main::FH;
                    open($clone5, '>&FH') or die "Could not clone handle (2 arg, bareword, not main): $!";
                    open($clone6, '>&', *FH) or die "Could not clone handle (3 arg, bareword, not main): $!";
                }

                ok((grep {$_ eq 'utf8'} PerlIO::get_layers($clone1)), "Preserved non-via layers that were added for clone 1");
                ok((grep {$_ eq 'utf8'} PerlIO::get_layers(FH)), "Preserved non-via layers that were added for 'FH'");
                # Clone 2 uses the fileno, perl never preserves layers in that case.

                $_->autoflush(1) for $clone1, $clone2, $clone3, $clone4, $clone5, $clone6;

                ok((print $clone1 "clone1\n"), "print to clone1");
                ok((print $clone2 "clone2\n"), "print to clone2");
                ok((print $clone3 "clone3\n"), "print to clone3");
                ok((print $clone4 "clone4\n"), "print to clone4");
                ok((print $clone5 "clone5\n"), "print to clone5");
                ok((print $clone6 "clone6\n"), "print to clone6");
                ok((print FH "FH\n"),          "print to FH");
            },
            [],
            "cloning filehandle with a via layer does not warn"
        );
    },
    "cloning a filehandle with a via layer does not die",
    $@
);

close($fh);
open($fh, '<', $name);
is(
    [<$fh>],
    [
        "clone1\n",
        "clone2\n",
        "clone3\n",
        "clone4\n",
        "clone5\n",
        "clone6\n",
        "FH\n",
    ],
    "Wrote as expected"
);
unlink($name);

like(
    warnings {
        no warnings 'redefine';
        *CORE::GLOBAL::open = sub(*;$@) { die "oops" }
    },
    [qr/^DESTROYED 'CORE::GLOBAL::open' override before it was time!/],
    "Got the expected warning if another non-local open override is made"
);

done_testing;
