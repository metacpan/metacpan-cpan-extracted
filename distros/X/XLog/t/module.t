use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use Test::Fatal;

subtest 'root' => sub {
    is ref(XLog::root), 'XLog::Module';
    is XLog::root->name, "";
    XLog::root->level;
};

subtest 'create' => sub {
    subtest 'name' => sub {
        my $module = XLog::Module->new("mymod");
        is $module->name, "mymod";
    };
    subtest 'name+module' => sub {
        my $module = XLog::Module->new("mymod");
        my $submodule = XLog::Module->new("subm", $module);
        is $submodule->name, "mymod::subm";
    };
    subtest 'name+level' => sub {
        my $module = XLog::Module->new("mymod", XLog::ERROR);
        is $module->level, XLog::ERROR;
    };
    subtest 'name+module+level' => sub {
        my $module = XLog::Module->new("mymod");
        my $submodule = XLog::Module->new("subm", $module, XLog::ALERT);
        is $submodule->name, "mymod::subm";
        is $submodule->level, XLog::ALERT;
    };
    ok !XLog::get_module("mymod"), 'modules deregistered';
    ok !XLog::get_module("mymod::subm"), 'modules deregistered';
};

subtest 'logging to module' => sub {
    my $ctx = Context->new;
    my $mod = XLog::Module->new("mymod", XLog::DEBUG);

    XLog::verbose_debug("hi");
    is $ctx->{cnt}, 0;
    XLog::verbose_debug($mod, "hi");
    is $ctx->{cnt}, 0;

    XLog::debug("hi");
    is $ctx->{cnt}, 0;
    XLog::debug($mod, "hi");
    $ctx->check(module => "mymod");

    XLog::warning("hi");
    $ctx->check(module => "");
    XLog::warning($mod, "hi");
    $ctx->check(module => "mymod");

    $mod->set_level(XLog::NOTICE);

    XLog::debug("hi");
    is $ctx->{cnt}, 0;
    XLog::debug($mod, "hi");
    is $ctx->{cnt}, 0;
};

subtest 'auto module by namespace' => sub {
    my $ctx = Context->new;
    
    subtest 'basic' => sub {
        {
            package A1;
            sub func ()  { XLog::error("A"); }
            sub mod  ($) { my $depth = shift; my $m = XLog::resolve_module($depth); XLog::error($m, "A"); }
            
            package A1::B1;
            our $xlog_module = XLog::Module->new("B1");
            sub func ()  { XLog::error("B"); }
            sub mod  ($) { A1::mod(shift) ; }

            package A1::B1::C1;
            sub func ()  { XLog::error("C"); }
            sub mod  ($) { A1::B1::mod(shift) ; }

            package A1::B1::C1::D1;
            our $xlog_module = XLog::Module->new("D1", $A1::B1::xlog_module);
            sub func ()  { XLog::error("D"); }
            sub mod  ($) { A1::B1::C1::mod(shift) ; }
        }
        
        for (1..2) {
            A1::func();
            $ctx->check(msg => "A", module => "");

            A1::mod(0);
            $ctx->check(msg => "A", module => "");
        }
        
        for (1..2) {
            A1::B1::func();
            $ctx->check(msg => "B", module => "B1");

            A1::B1::mod(0); $ctx->check(msg => "A", module => '');
            A1::B1::mod(1); $ctx->check(msg => "A", module => "B1");
        }
        
        for (1..2) {
            A1::B1::C1::func();
            $ctx->check(msg => "C", module => "B1");
            A1::B1::C1::mod(0); $ctx->check(msg => "A", module => '');
            A1::B1::C1::mod(1); $ctx->check(msg => "A", module => "B1");
            A1::B1::C1::mod(2); $ctx->check(msg => "A", module => "B1");
        }
        
        for (1..2) {
            A1::B1::C1::D1::func();
            $ctx->check(msg => "D", module => "B1::D1");
            A1::B1::C1::D1::mod(0); $ctx->check(msg => "A", module => '');
            A1::B1::C1::D1::mod(1); $ctx->check(msg => "A", module => "B1");
            A1::B1::C1::D1::mod(2); $ctx->check(msg => "A", module => "B1");
            A1::B1::C1::D1::mod(3); $ctx->check(msg => "A", module => "B1::D1");
        }
        
        undef $A1::B1::xlog_module;
        undef $A1::B1::C1::D1::xlog_module;
    };
    
    subtest 'through non-existing package' => sub {
        {
            package A2;
            our $xlog_module = XLog::Module->new("A2");
            
            package A2::B2::C2::D2;
            sub func () { XLog::error("D"); }
        }
        for (1..2) {
            A2::B2::C2::D2::func();
            $ctx->check(msg => "D", module => "A2");
        }
    };
    
    subtest 'skipping wrong xlog_module variables' => sub {
        {
            package A3;
            our $xlog_module = XLog::Module->new("A3");
            
            package A3::B3;
            our $xlog_module = bless {}, 'A3::B3';
            
            package A3::B3::C3;
            our $xlog_module = 1;
            
            package A3::B3::C3::D3;
            sub func () { XLog::error("D"); }
        }
        for (1..2) {
            A3::B3::C3::D3::func();
            $ctx->check(msg => "D", module => "A3");
        }
    };
    
    subtest 'up to main' => sub {
        {
            package main;
            our $xlog_module = XLog::Module->new("mainperl");
            
            package A4;
            sub func () { XLog::error("A4"); }
        }
        for (1..2) {
            A4::func();
            $ctx->check(msg => "A4", module => "mainperl");
        }
    };
};

subtest 'set_logger/set_formatter' => sub {
    my $ctx = Context->new;
    my $root   = XLog::Module->new("root", undef);
    my $mod    = XLog::Module->new("mod", $root);
    my $submod = XLog::Module->new("submod", $mod);
    
    my (@l,@f);
    $root->set_logger(sub { push @l, 1 });
    $root->set_formatter(sub { push @f, 1 });
    XLog::warning($_, "") for $root, $mod, $submod;
    is_deeply [\@l, \@f], [[1,1,1], [1,1,1]];
    @l = @f = ();
    
    $mod->set_logger(sub { push @l, 2 });
    $mod->set_formatter(sub { push @f, 2 });
    XLog::warning($_, "") for $root, $mod, $submod;
    is_deeply [\@l, \@f], [[1,2,2], [1,2,2]];
};

subtest 'passthrough' => sub {
    my $ctx = Context->new;
    my $root   = XLog::Module->new("root", undef);
    my $mod    = XLog::Module->new("mod", $root);
    my $submod = XLog::Module->new("submod", $mod);
    
    my @l;
    $root->set_logger(sub { push @l, 1 });
    $submod->set_logger(sub { push @l, 2}, "true");
    XLog::warning($submod, "");
    is_deeply \@l, [2,1];
};

subtest 'get_module' => sub {
    my $ctx = Context->new;
    my $m = XLog::Module->new("abc");
    my $same = XLog::get_module("abc");
    $same->set_level(XLog::EMERGENCY);
    is $same->level, $m->level;
};

done_testing();
