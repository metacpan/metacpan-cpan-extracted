package Term::UI::History;

use strict;
use base 'Exporter';
use base 'Log::Message::Simple';

BEGIN {
    use Log::Message private => 0;

    use vars      qw[ @EXPORT $HISTORY_FH ];
    @EXPORT     = qw[ history ];
    my $log     = new Log::Message;
    $HISTORY_FH = \*STDOUT;

    for my $func ( @EXPORT ) {
        no strict 'refs';
        
        *$func = sub {  my $msg     = shift;
                        $log->store(
                                message => $msg,
                                tag     => uc $func,
                                level   => $func,
                                extra   => [@_]
                        );
                };
    }

    sub history_as_string {
        my $class = shift;

        return join $/, map { $_->message } __PACKAGE__->stack;
    }
}


{   package Log::Message::Handlers;
    
    sub history {
        my $self    = shift;
        my $verbose = shift;
           $verbose = 1 unless defined $verbose;    # default to true

        ### so you don't want us to print the msg? ###
        return if defined $verbose && $verbose == 0;

        local $| = 1;
        my $old_fh = select $Term::UI::History::HISTORY_FH;

        print $self->message . "\n";
        select $old_fh;

        return;
    }
}


1;

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
