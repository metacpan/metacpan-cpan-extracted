use strict;
use warnings;

package Working::Daemon::Syslog;
use base "Working::Daemon";
use NEXT;
use Sys::Syslog qw(:DEFAULT setlogsock :macros);

setlogsock('unix') || die "$!";


sub init {
    my $self = shift;
    openlog($self->name, 'ndelay,pid', LOG_DAEMON);
    $self->NEXT::init;
}


sub do_log {
    my ($self, $prio, $msg) = @_;
    syslog($prio, $msg) || die "$!";
    $self->NEXT::do_log($prio, $msg);
}

sub action_stop {
    my $self = shift;
    $self->NEXT::action_stop(@_);
    closelog();
}
