#!/usr/bin/perl

use lib 'lib', 't/lib';
use Test::Most tests => 8;
use Data::Dumper;

no warnings 'redefine';

my @NOTE;
local *Test::More::note = sub { @NOTE = @_ };
my @DIAG;
local *Test::More::diag = sub { @DIAG = @_ };

explain 'foo';
eq_or_diff \@NOTE, ['foo'], 'Basic explain() should work just fine';

my $aref = [qw/this that/];
{
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;

    explain 'hi', $aref, 'bye';

    eq_or_diff \@NOTE, [ 'hi', Dumper($aref), 'bye' ],
      '... and also allow you to dump references';
}

{
    my $expected;
    local $Data::Dumper::Indent = 1;
    $expected = Dumper($aref);
    $expected =~ s/VAR1/aref/;
    show $aref;

    SKIP: {
        eval "use Data::Dumper::Names ()";
        skip 'show() requires Data::Dumper::Names version 0.03 or better', 2
            if $@ or $Data::Dumper::Names::VERSION < .03;
        eq_or_diff \@NOTE,  [$expected],
            '... and show() should try to show the variable name';

        show 3;
        chomp @NOTE;
        eq_or_diff \@NOTE, ['$VAR1 = 3;'],
            '... but will default to $VARX names if it can\'t';
    }
}

always_explain 'foo';
eq_or_diff \@DIAG, ['foo'], 'Basic always_explain() should work just fine';

{
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;

    always_explain 'hi', $aref, 'bye';

    eq_or_diff \@DIAG, [ 'hi', Dumper($aref), 'bye' ],
      '... and also allow you to dump references';
}

{
    my $expected;
    local $Data::Dumper::Indent = 1;
    $expected = Dumper($aref);
    $expected =~ s/VAR1/aref/;
    always_show $aref;

    SKIP: {
        eval "use Data::Dumper::Names ()";
        skip 'always_show() requires Data::Dumper::Names version 0.03 or better', 2
            if $@ or $Data::Dumper::Names::VERSION < .03;
        eq_or_diff \@DIAG,  [$expected],
            '... and always_show() should try to show the variable name';

        always_show 3;
        chomp @DIAG;
        eq_or_diff \@DIAG, ['$VAR1 = 3;'],
            '... but will default to $VARX names if it can\'t';
    }
}
