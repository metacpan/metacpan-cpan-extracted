package POP::Carp;

use Carp;
use POP::Environment qw/$POP_LOG_FILE $POP_LID_FILE
		        $POP_MAILER $POP_ADMIN_EMAIL/;
use POP::Error;
use POP::Lid_factory;
use Symbol;
use SelectSaver;
use File::lockf;
use POSIX qw/EAGAIN/;
require Exporter;
use vars qw/$log $lid_factory @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/croak throw/;

$main::SIG{__DIE__}=\&POP::Carp::croak;

$lid_factory = new POP::Lid_factory $POP_LID_FILE;
$log = gensym;
open($log, "+>>$POP_LOG_FILE") or die "Couldn't open [$POP_LOG_FILE]: $!";
{
  my $old = new SelectSaver $log;
  $| = 1;
}

=head2 METHOD
Title:  POP::Carp::email_admin
Desc:   This method will email whatever (error) message is passed in as
        ARG1 (string argument) to address specified by the $POP_ADMIN_EMAIL
	environment variable. The mailer program used to send the email will
	be found in the path/file-name specified by the $POP_MAILER environment
	variable.  No return-codes are checked on the mailer as we're already
	in a croak when this is called.
=cut

sub  email_support {
  my $errmsg = @_;

  open (MAIL, "|$POP_MAILER -s 'Error Notification' $POP_ADMIN_EMAIL");
  print MAIL $errmsg;
  close MAIL;
}

sub log_mess {
  my($msg) = @_;

  # Try to get a lock on the file. If cannot get it after
  # a few times, forget the lock and just write the message.
  my $retries = 3;
  unless (-e $log) { die "Log file $POP_LOG_FILE doesn't exist!" }
  my $status = File::lockf::tlock($log);
  while ($status == EAGAIN and $retries--) {
    sleep 1;
    $status = File::lockf::tlock($log);
  }
  seek($log,0,2);
  print $log $msg;
  File::lockf::ulock($log);
}

sub throw {CORE::die @_,"\n"}

{
  local $^W = 0;  # Avoid "sub redefinition" warnings
  eval <<'Q_EVAL_Q';
sub croak {
  my $no = $POP::Carp::lid_factory->next;
  POP::Carp::log_mess(
    ('-'x43)."\n".
    "Message $no received at ".(scalar localtime)."\n".
    Carp::longmess(@_) );
  POP::Carp::email_support("Message $no received at ".(scalar localtime)."\n".
    Carp::longmess(@_) );
  CORE::die POP::Error->new($no);
}
Q_EVAL_Q
  *{'Carp::croak'} = \&croak;
}

1;
