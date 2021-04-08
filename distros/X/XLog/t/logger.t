use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

subtest 'set logger callback' => sub {
    my $ctx = Context->new;
    my $msg;
    XLog::set_logger(sub { $msg = shift; });
    XLog::log(XLog::WARNING, "hello");
    
    like $msg, qr/hello/;
};

subtest 'set logger object' => sub {
    my $ctx = Context->new;
    
    subtest 'simple logger' => sub {
        {
            package MySimpleLogger;
            use parent 'XLog::Logger';
            
            our @args;
            
            sub new {
                my $self = shift->SUPER::new();
                $self->{prop} = 'val';
                return $self;
            }
            
            sub log { @args = @_; }
        }
        
        my $logger = MySimpleLogger->new;
        XLog::set_logger($logger);
        is XLog::get_logger(), $logger;
        undef $logger; # logger is held by C++
        
        XLog::log(XLog::ERROR, "shit happens");
        
        my @args = @MySimpleLogger::args;
        is ref($args[0]), 'MySimpleLogger';
        is $args[0]{prop}, 'val';
        like $args[1], qr/shit happens/;
    };
    
    subtest 'format logger' => sub {
        {
            package MyFmtLogger;
            use parent 'XLog::Logger';
            our @args;
            sub log_format { @args = @_; }
        }
        
        XLog::set_logger(MyFmtLogger->new);
        
        XLog::log(XLog::ERROR, "shithpns2");
        
        my @args = @MyFmtLogger::args;
        is ref($args[0]), 'MyFmtLogger';
        is $args[1], "shithpns2";
        is $args[2], XLog::ERROR;
        is $args[3], "";
        like $args[4], qr/logger.t/;
        is $args[5], 57;
        is $args[6], "__ANON__";
    };
};

subtest 'logger destroy' => sub {
    my $ctx = Context->new;
    {
        package MyLoggerDtor;
        use parent 'XLog::Logger';
        our $dtor = 0;
        sub log {}
        sub DESTROY { $dtor++ }
    }
    
    XLog::set_logger(MyLoggerDtor->new);
    XLog::log(XLog::ERROR, "");
    is $MyLoggerDtor::dtor, 0;

    XLog::set_logger(MyLoggerDtor->new);
    is $MyLoggerDtor::dtor, 1;
    
    XLog::set_logger(undef);
    is $MyLoggerDtor::dtor, 2;
} if $^V >= '5.24'; # on perl < 5.24 false DESTROY could be called when no refs from perl

done_testing();
