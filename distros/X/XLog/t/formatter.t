use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

sub mysub {
    XLog::log(XLog::ERROR, "mymsg");
}

subtest 'set formatter callback' => sub {
    my $ctx = Context->new;
    my @args;
    my $msg;
    XLog::set_formatter(sub {
        @args = @_;
        return "formatted";
    });
    XLog::set_logger(sub { $msg = shift });
    
    XLog::log(XLog::ERROR, "hello"); my $line = __LINE__;
    
    is $args[0], "hello";
    is $args[1], XLog::ERROR;
    is $args[2], "";
    like $args[3], qr/formatter.t/;
    is $args[4], $line;
    is $args[5], "__ANON__";
    is $msg, "formatted";
};

subtest 'set formatter object' => sub {
    my $ctx = Context->new;
    
    {
        package MyFormatter;
        use parent 'XLog::Formatter';
        our @args;
        sub format {
            @args = @_;
            return "epta";
        }
    }
    my $msg;

    XLog::set_logger(sub { $msg = shift });
        
    my $formatter = MyFormatter->new;
    XLog::set_formatter($formatter);
    is XLog::get_formatter(), $formatter;
    undef $formatter;
       
    XLog::log(XLog::ERROR, "hello"); my $line = __LINE__;
        
    my @args = @MyFormatter::args;
    is ref($args[0]), 'MyFormatter';
    is $args[1], "hello";
    is $args[2], XLog::ERROR;
    is $args[3], "";
    like $args[4], qr/formatter.t/;
    is $args[5], $line;
    is $args[6], "__ANON__";
    is $msg, "epta";
};

subtest 'formatter destroy' => sub {
    my $ctx = Context->new;
    {
        package MyFormatterDtor;
        use parent 'XLog::Formatter';
        our $dtor = 0;
        sub format { return "" }
        sub DESTROY { $dtor++ }
    }
    
    XLog::set_logger(sub {});
    XLog::set_formatter(MyFormatterDtor->new);
    XLog::log(XLog::ERROR, "");
    is $MyFormatterDtor::dtor, 0;

    XLog::set_formatter(MyFormatterDtor->new);
    is $MyFormatterDtor::dtor, 1;
    
    XLog::set_formatter(undef);
    is $MyFormatterDtor::dtor, 2;
} if $^V >= '5.24'; # on perl < 5.24 false DESTROY could be called when no refs from perl


subtest 'set_format' => sub {
    my $ctx = Context->new;
    
    XLog::set_formatter("LEVEL=%L FILE=%f LINE=%l FUNC=%F MODULE=%M MESSAGE=%m");
    my $msg;
    XLog::set_logger(sub { $msg = shift });
    
    mysub();
    
    is $msg, "LEVEL=error FILE=formatter.t LINE=7 FUNC=mysub MODULE= MESSAGE=mymsg";
};

subtest 'program-decorator' => sub {
    my $ctx = Context->new;

    my $msg;
    XLog::set_logger(sub { $msg = shift });
    XLog::set_formatter("dollar-zero: %P");

    subtest "applied by default" => sub {
        mysub();
        my $script = __FILE__ =~ s|(.+)/(.+)|$2|r;
        like $msg, qr/dollar-zero: $script/;
    };

    subtest "spy on custom" => sub {
        XLog::Formatter::Pattern::set_program_decorator(sub {
            my $name = shift;
            return "---===[$name]===---";
        });
        $0 = "my_script";
        mysub();

        is $msg, "dollar-zero: ---===[my_script]===---";
    };
};

done_testing();
