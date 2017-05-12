package Log::Message::Simple;

use strict;
use Log::Message private => 0;;

BEGIN { 
    use vars qw[$VERSION]; 
    $VERSION = 0.06; 
}
        

{   package Log::Message::Handlers;
    
    sub msg {
        my $self    = shift;
        my $verbose = shift || 0;

        ### so you don't want us to print the msg? ###
        return if defined $verbose && $verbose == 0;

        my $old_fh = select $Log::Message::Simple::MSG_FH;
        print '['. $self->tag (). '] ' . $self->message . "\n";
        select $old_fh;

        return;
    }

    sub debug {
        my $self    = shift;
        my $verbose = shift || 0;

        ### so you don't want us to print the msg? ###
        return if defined $verbose && $verbose == 0;

        my $old_fh = select $Log::Message::Simple::DEBUG_FH;
        print '['. $self->tag (). '] ' . $self->message . "\n";
        select $old_fh;

        return;
    }

    sub error {
        my $self    = shift;
        my $verbose = shift;
           $verbose = 1 unless defined $verbose;    # default to true

        ### so you don't want us to print the error? ###
        return if defined $verbose && $verbose == 0;

        my $old_fh = select $Log::Message::Simple::ERROR_FH;

        my $msg     = '['. $self->tag . '] ' . $self->message;

        print $Log::Message::Simple::STACKTRACE_ON_ERROR 
                    ? Carp::shortmess($msg) 
                    : $msg . "\n";

        select $old_fh;

        return;
    }
}

BEGIN {
    use Exporter;
    use Params::Check   qw[ check ];
    use vars            qw[ @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA ];;

    @ISA            = 'Exporter';
    @EXPORT         = qw[error msg debug];
    @EXPORT_OK      = qw[carp cluck croak confess];
    
    %EXPORT_TAGS    = (
        STD     => \@EXPORT,
        CARP    => \@EXPORT_OK,
        ALL     => [ @EXPORT, @EXPORT_OK ],
    );        

    my $log         = new Log::Message;

    for my $func ( @EXPORT, @EXPORT_OK ) {
        no strict 'refs';
        
                        ### up the carplevel for the carp emulation
                        ### functions
        *$func = sub {  local $Carp::CarpLevel += 2
                            if grep { $_ eq $func } @EXPORT_OK;
                            
                        my $msg     = shift;
                        $log->store(
                                message => $msg,
                                tag     => uc $func,
                                level   => $func,
                                extra   => [@_]
                        );
                };
    }

    sub flush {
        return reverse $log->flush;
    }

    sub stack {
        return $log->retrieve( chrono => 1 );
    }

    sub stack_as_string {
        my $class = shift;
        my $trace = shift() ? 1 : 0;

        return join $/, map {
                        '[' . $_->tag . '] [' . $_->when . '] ' .
                        ($trace ? $_->message . ' ' . $_->longmess
                                : $_->message);
                    } __PACKAGE__->stack;
    }
}

BEGIN {
    use vars qw[ $ERROR_FH $MSG_FH $DEBUG_FH $STACKTRACE_ON_ERROR ];

    local $| = 1;
    $ERROR_FH               = \*STDERR;
    $MSG_FH                 = \*STDOUT;
    $DEBUG_FH               = \*STDOUT;
    
    $STACKTRACE_ON_ERROR    = 0;
}


1;

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
