package XML::Stream::Tools;
use strict;
use warnings;

use FileHandle;

# helper function (not a method!)
sub setup_debug {
    my ($self, %args) = @_;

    $self->{DEBUGTIME} = 0;
    $self->{DEBUGTIME} = $args{debugtime} if exists($args{debugtime});

    $self->{DEBUGLEVEL} = 0;
    $self->{DEBUGLEVEL} = $args{debuglevel} if exists($args{debuglevel});

    $self->{DEBUGFILE} = "";

    $args{debugfh} ||= '';
    $args{debug}   ||= '';

    if ($args{debugfh} ne "")
    {
        $self->{DEBUGFILE} = $args{debugfh};
        $self->{DEBUG} = 1;
    }
    elsif ($args{debug} ne "")
    {
        $self->{DEBUG} = 1;
        if (lc($args{debug}) eq "stdout")
        {
            $self->{DEBUGFILE} = FileHandle->new(">&STDERR");
            $self->{DEBUGFILE}->autoflush(1);
        }
        else
        {
            if (-e $args{debug})
            {
                if (-w $args{debug})
                {
                    $self->{DEBUGFILE} = FileHandle->new(">$args{debug}");
                    $self->{DEBUGFILE}->autoflush(1);
                }
                else
                {
                    print "WARNING: debug file ($args{debug}) is not writable by you\n";
                    print "         No debug information being saved.\n";
                    $self->{DEBUG} = 0;
                }
            }
            else
            {
                $self->{DEBUGFILE} = FileHandle->new(">$args{debug}");
                if (defined($self->{DEBUGFILE}))
                {
                    $self->{DEBUGFILE}->autoflush(1);
                }
                else
                {
                    print "WARNING: debug file ($args{debug}) does not exist \n";
                    print "         and is not writable by you.\n";
                    print "         No debug information being saved.\n";
                    $self->{DEBUG} = 0;
                }
            }
        }
    }
}




1;


