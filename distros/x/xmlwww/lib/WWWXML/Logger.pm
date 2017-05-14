package WWWXML::Logger;
use strict;

use File::Spec::Functions qw(catfile);
use FindBin;
use Log::Log4perl ();

my $logger;

sub TIEHANDLE {
    bless [], shift;
}

sub PRINT {
    shift;
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $logger->info(@_)
        if $logger;
}

sub BINMODE {
}

sub _warn {
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $logger->warn(@_) if $logger;
}

sub _die {
    # simple check for eval
    return
        if $^S;
    # complex check for eval
    for (my $i = 1; my $sub = (caller($i))[3]; ++$i) {
        return
            if index($sub, '(eval)') == $[;
    }

    ++$Log::Log4perl::caller_depth;
    $logger->logconfess(@_)
        if $logger;
    untie *STDERR;
}

sub logger {
    my $class = shift;
    my %args = @_;

    # initialize logger
    Log::Log4perl->init_once({
        'log4perl.rootLogger'                                => 'DEBUG, LOGFILE',
        'log4perl.appender.LOGFILE'                          => 'Log::Log4perl::Appender::File',
        'log4perl.appender.LOGFILE.filename'                 => $args{filename},
        'log4perl.appender.LOGFILE.mode'                     => 'append',
        'log4perl.appender.LOGFILE.layout'                   => 'PatternLayout',
        'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d{EEE dd yyyy HH:mm:ss} %H %5P [%-5p] [%M] %m%n',
        $args{screen} ? (
            'log4perl.rootLogger'                               => 'DEBUG, LOGFILE, SCREEN',
            'log4perl.appender.SCREEN'                          => 'Log::Log4perl::Appender::Screen',
            'log4perl.appender.SCREEN.stderr'                   => 0,
            'log4perl.appender.SCREEN.mode'                     => 'append',
            'log4perl.appender.SCREEN.layout'                   => 'PatternLayout',
            'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d{HH:mm:ss} [%-5p] [%M] %m%n',
        ) : (),
    });
    $logger = Log::Log4perl->get_logger;

    # override warn and die to use logger
    $SIG{__WARN__} = \&_warn;
    $SIG{__DIE__}  = \&_die;

    # override PRINT on STDERR to use logger

    open STDERR, ">>", $args{filename};
#    open STDOUT, ">>", $args{filename};

    tie *STDERR, __PACKAGE__;

    return $logger;
}

1;
