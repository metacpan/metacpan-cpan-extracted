#!/usr/bin/perl

# Test that lexical filehandles (open my $fh) work as return values
# from ExternEnt handlers. See GitHub issue #44 / rt.cpan.org #36096.

use strict;
use warnings;

use Test::More;
use XML::Parser;
use File::Temp qw(tempfile);

if ($] < 5.012) {
    plan skip_all => 'Lexical filehandles lack read() method before Perl 5.12';
}
plan tests => 4;

# Create a temporary entity file
my ($fh, $entfile) = tempfile(UNLINK => 1, SUFFIX => '.ent');
print $fh "hello world";
close $fh;

my $xml = <<"XML";
<!DOCTYPE foo [
  <!ENTITY ext SYSTEM "$entfile">
]>
<foo>&ext;</foo>
XML

# Test 1: lexical glob returned directly (open my $fh)
{
    my $chardata = '';
    my $p = XML::Parser->new(
        Handlers => {
            Char => sub { $chardata .= $_[1] },
            ExternEnt => sub {
                my ($xp, $base, $sysid, $pubid) = @_;
                open my $efh, '<', $sysid or die "Cannot open $sysid: $!";
                return $efh;
            },
            ExternEntFin => sub { },  # no-op cleanup
        },
    );

    eval { $p->parse($xml) };
    is($@, '', 'parsing with lexical glob ExternEnt handler does not die');
    is($chardata, 'hello world', 'character data from lexical glob entity is correct');
}

# Test 3: unopened lexical glob croaks instead of segfaulting
{
    my $p = XML::Parser->new(
        Handlers => {
            ExternEnt => sub {
                my $fh;  # declared but never opened
                return \$fh;  # returns reference to undef scalar, not a glob
            },
        },
    );

    eval { $p->parse($xml) };
    ok($@, 'unopened lexical scalar ref dies gracefully');
}

# Test 4: unopened bare glob croaks instead of segfaulting
{
    no warnings 'once';
    my $p = XML::Parser->new(
        Handlers => {
            ExternEnt => sub {
                return *UNOPENED_TEST_GLOB;  # glob with no IO slot
            },
        },
    );

    eval { $p->parse($xml) };
    like($@, qr/unopened filehandle/i, 'bare unopened glob gives useful error');
}
