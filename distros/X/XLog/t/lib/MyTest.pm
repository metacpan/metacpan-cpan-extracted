package MyTest;
use 5.012;
use XLog;

our @levels = (
    XLog::DEBUG,
    XLog::INFO,
    XLog::NOTICE,
    XLog::WARNING,
    XLog::ERROR,
    XLog::CRITICAL,
    XLog::ALERT,
    XLog::EMERGENCY
);

{
    package ContextLogger;
    use parent 'XLog::Logger';
    use Scalar::Util 'weaken';
    
    sub new {
        my $self = shift->SUPER::new();
        $self->{ctx} = shift;
        # weaken $ctx - we need Context::DESTROY to fire
        weaken($self->{ctx});
        return $self;
    }
    
    sub log_format {
        my ($self, $msg, $level, $module, $file, $line, $func) = @_;
        my $ctx = $self->{ctx};
        $ctx->{level}  = $level;
        $ctx->{msg}    = $msg;
        $ctx->{module} = $module;
        $ctx->{file}   = $file;
        $ctx->{line}   = $line;
        $ctx->{func}   = $func;
        $ctx->{cnt}++;
    }
}

{
    package Context;
    use Test::More;
    
    sub new {
        my $self = bless {cnt => 0}, shift;
        XLog::set_level(XLog::WARNING);
        XLog::set_formatter("%m");
        XLog::set_logger(ContextLogger->new($self));
        return $self;
    }
    
    sub cnt { $_[0]->{cnt} }
    
    sub check {
        my ($self, %p) = @_;

        is $self->{cnt}, 1, "logcb called";
        $self->{cnt} = 0;
        
        return unless %p;
        
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        foreach my $key (qw/level module file line func/) {
            is $self->{$key}, $p{$key}, "$key=$p{$key}" if exists $p{$key};
        }
        if (exists $p{msg}) {
            my $pattern = $p{msg};
            if (ref($pattern) eq 'Regexp') {
                like $self->{msg}, $pattern, "message like '$pattern'";
            } else {
                is $self->{msg}, $pattern, "message '$pattern'";;
            }
        }
    }
    
    sub DESTROY {
        XLog::set_logger(undef);
        XLog::set_formatter(undef);
    }
}

XS::Loader::load();

1;
