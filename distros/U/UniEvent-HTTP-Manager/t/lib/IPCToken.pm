package IPCToken;
use 5.016;
use warnings;
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT);
use IPC::Semaphore;

sub new {
    my ($class, $initial) = @_;
    my $sem = IPC::Semaphore->new(IPC_PRIVATE, 1, S_IRUSR | S_IWUSR | IPC_CREAT);

    my $obj = bless {sem => $sem} => $class;
    $obj->inc($initial) if $initial;
    return $obj;
}

sub inc {
    my ($self, $val) = @_;
    $val //= 1;
    $self->{sem}->op(0, $val, 0);
}

sub dec {
    my ($self, $val) = @_;
    ($val //= 1) *= -1;
    $self->{sem}->op(0, $val, 0);
}

sub await {
    my ($self, $timeout) = @_;
    eval {
         local $SIG{ALRM} = sub { die "alarm\n" };
         alarm $timeout;

         my $opstring = pack("s!s!s!", 0, 0, 0);
         $self->{sem}->op(0, 0, 0);

         alarm 0;
     };
     $self->{sem}->remove;
     if ($@) {
        if ($@ eq "alarm\n") {
            return "timed out";
        }
        else {
            return @$;
        }
     }
     else {
        return undef;
     }
}



1;
