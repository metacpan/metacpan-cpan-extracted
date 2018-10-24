package testcases::Objects;
use warnings;
use strict;
use XAO::SimpleHash;
use XAO::Utils;
use Error qw(:try);

use base qw(testcases::base);

###############################################################################

sub test_everything {
    my $self=shift;

    use XAO::Objects;

    ##
    # Loading `test' project Config
    #
    my $obj=XAO::Objects->new(objname => 'Config',
                              sitename => 'test');

    $self->assert(ref($obj),
                  "new(Config) did not return an object reference");
    my $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::test::Config',
                  "new(Config) returned an object of wrong type ($ref)");

    use XAO::Projects;
    XAO::Projects::create_project(name => 'test',
                                  object => $obj,
                                  set_current => 1);

    $obj=XAO::Objects->new(objname => 'Test1');
    $self->assert(ref($obj),
                  "new(Test1) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::test::Test1',
                  "new(Test1) returned an object of wrong type ($ref)");

    $obj=XAO::Objects->new(objname => 'Test2');
    $self->assert(ref($obj),
                  "new(Test2) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::Test2',
                  "new(Test2) returned an object of wrong type ($ref)");

    $obj=XAO::Objects->new(objname => 'Test1', baseobj => 1);
    $self->assert(ref($obj),
                  "new(Test1,base) did not return an object reference");
    $ref=ref($obj);
    $self->assert($ref eq 'XAO::DO::Test1',
                  "new(Test1,base) returned an object of wrong type ($ref)");

    # Testing error throwing

    $obj=XAO::Objects->new(objname => 'Thrower');

    my $etext;
    try {
        throw $obj "function - error message";
    }
    otherwise {
        my $e=shift;
        $etext="$e";
    };

    $self->assert(defined $etext,
                  "'Throw' did not throw an error");

    $self->assert(($etext =~ /^XAO::DO::Thrower::function - error message/) ? 1 : 0,
                  "Throw message ($etext) is not formatted as expected");

    undef $etext;
    try {
        $obj->eat('leftovers');
    }
    otherwise {
        my $e=shift;
        $etext="$e";
    };

    $self->assert(defined $etext,
                  "obj->eat did not throw an error");

    $self->assert(($etext =~ /^XAO::DO::Thrower::eat\(leftovers\) - not edible/) ? 1 : 0,
                  "Throw message ($etext) is not formatted as expected");

    undef $etext;
    try {
        $obj->drink;
    }
    otherwise {
        my $e=shift;
        $etext="$e";
    };

    $self->assert(defined $etext,
                  "obj->drink did not throw an error");

    $self->assert(($etext =~ /^XAO::DO::Thrower::drink - drunk/) ? 1 : 0,
                  "Throw message ($etext) is not formatted as expected");
}

###############################################################################

sub test_include {
    my $self=shift;

    use XAO::Objects;
    use XAO::Projects;

    # This project is set to include objects from two other: testlib and
    # test.
    #
    my $sitename='testuse';
    my $config=XAO::Objects->new(
        objname     => 'Config',
        sitename    => $sitename,
    );

    $self->assert(ref($config),
                  "new(Config) did not return an object reference");

    $config->init();

    XAO::Projects::create_project(
        name        => $sitename,
        object      => $config,
        set_current => 1,
    );

    my %tests=(
        t00 => {
            objname => 'Local',
            coderef => sub { return shift->method_local('t00') },
            expect  => 'local:t00',
        },
        t01 => {        # inherited from 'test'
            objname => 'DepBase',
            coderef => sub { return shift->method_A('t01') },
            expect  => 'testuse:test-DepBase-A:t01',
        },
        t02 => {        # Redefined in 'testuse'
            objname => 'DepBase',
            coderef => sub { return shift->method_B('t02') },
            expect  => 'testuse:testuse-DepBase-B:t02',
        },
        t03 => {        # Defined in 'testlib'
            objname => 'DepBase',
            coderef => sub { return shift->method_C('t03') },
            expect  => 'testuse:testlib-DepBase-C:t03',
        },
        t04 => {        # New method in 'testuse'
            objname => 'DepBase',
            coderef => sub { return shift->method_D('t04') },
            expect  => 'testuse:testuse-DepBase-D:t04',
        },
        t05 => {        # Undefined
            objname => 'DepBase',
            coderef => sub { return shift->method_E('t04') },
            codeerr => 1,
        },
        t05 => {        # Undefined
            objname => 'DepBAD',
            objerr  => 1,
        },
        t06 => {        # Defined in testlib only
            objname => 'DepLib',
            coderef => sub { return shift->method_D('t06') },
            expect  => 'testuse:testlib-DepLib-D:t06',
        },
        t07a => {       # Defined in 'test' and 'testlib' independently
            objname => 'DepOver',
            coderef => sub { return shift->method_X('t07a') },
            expect  => 'testlib:t07a',
        },
        t07b => {
            objname => 'DepOver',
            coderef => sub { return shift->method_X('t07b') },
            expect  => 'testlib:t07b',
        },
        t08 => {        # New object in testuse
            objname => 'DepUse',
            coderef => sub { return shift->method_E('t08') },
            expect  => 'testuse:testuse-DepUse-E:t08',
        },
        t09 => {        # Only in test
            objname => 'Test1',
            coderef => sub { return shift->method() },
            expect  => 'XX<no-arg>XX',
        },
    );

    foreach my $tname (sort keys %tests) {
        my $test=$tests{$tname};

        my $obj;
        my $got;
        my $etext='';

        try {
            $obj=XAO::Objects->new(objname => $test->{'objname'});
            $got=$test->{'coderef'}->($obj);
        }
        otherwise {
            $etext=''.shift;
        };

        if($test->{'objerr'}) {
            $self->assert(!defined $obj,
                "Expected to NOT receive an object for test '$tname'");
            next;
        }

        $self->assert($obj && ref($obj),
            "Expected '$test->{'objname'}' object for test '$tname', got error: $etext");

        if($test->{'codeerr'}) {
            $self->assert(!defined $got,
                "Expected to error in getting a value for test '$tname'");
            next;
        }

        $self->assert(defined $got,
            "Expected a value for test '$tname', got error: $etext");

        my $expect=$test->{'expect'};

        $self->assert($got eq $expect,
            "Got '$got', expected '$expect' (test $tname)");
    }
}

###############################################################################

sub test_system {
    my $self=shift;

    use XAO::Objects;
    use XAO::Projects;

    # Loading without site name and without site context
    #
    my $obj=XAO::Objects->new(objname => 'Atom');

    $self->assert(!XAO::Projects::get_current_project_name(),
        "Expected to have no current context, have ".(XAO::Projects::get_current_project_name()//'<no-site>'));

    $self->assert(ref $obj,
        "Expected to get an Atom instance reference");

    $self->assert($obj->objname eq 'Atom',
        "Expected Atom as objname, got ".$obj->objname);
}

###############################################################################

sub tear_down {
    my $self=shift;
    $self->SUPER::tear_down(@_);

    use XAO::Projects;

    my $sitename=XAO::Projects::get_current_project_name();
    if($sitename) {
        XAO::Projects::drop_project($sitename);
    }
}

###############################################################################
1;
