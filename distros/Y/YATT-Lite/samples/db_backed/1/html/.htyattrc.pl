#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use fields qw(dbic
	      cf_tmpdir cf_datadir cf_dbname);

use YATT::Lite::Entities qw(*CON);

sub DBIC () { __PACKAGE__ . '::DBIC' }

use YATT::Lite::WebMVC0::DBSchema::DBIC
  (DBIC, verbose => $ENV{DEBUG_DBSCHEMA}
   , [user => undef
      , uid => [integer => -primary_key, -autoincrement
		, [-has_many
		   , [address => undef
		      , addrid => [integer => -primary_key]
		      , owner => [int => [-belongs_to => 'user']]
		      , country => 'text'
		      , zip => 'text'
		      , prefecture => 'text'
		      , city => 'text'
		      , address => 'text'], 'owner']
		, [-has_many
		   , [entry => undef
		      , eid => [integer => -primary_key]
		      , owner => [int => [-belongs_to => 'user']]
		      , title => 'text'
		      , text  => 'text'], 'owner']]
      , login => ['text', -unique]
      , encpass => 'text'
      , tmppass => 'text'
      , tmppass_expire => 'datetime'
      , email => 'text'
      , confirm_token => ['text', -unique]
     ]
   );

#========================================
Entity resultset => sub {
  shift->YATT->dbic->resultset(@_);
};

#========================================
Entity LOGIN => sub { 'login' };

Entity is_logged_in => sub {
  my ($this) = @_;
  $this->entity_sess($this->entity_LOGIN);
};

Entity set_logged_in => sub {
  my ($this, $login) = @_;
  if (defined $login and $login ne '') {
    $CON->start_session([$this->entity_LOGIN => $login]);
  } else {
    $CON->delete_session;
  }
};

#========================================
use Digest::MD5 qw(md5_hex);

sub is_user {
  my ($self, $loginname) = @_;
  $self->dbic->resultset('user')->single({login => $loginname})
}

sub find_user_by_login {
  my ($self, $login) = @_;
  $self->dbic->resultset('user')->single({login => $login});
}

sub find_user_by_email {
  my ($self, $email) = @_;
  $self->dbic->resultset('user')
    ->search({email => $email})
      ->single;
}

sub find_user {
  my ($self, $login_or_email) = @_;
  if ($login_or_email =~ /\@/) {
    $self->find_user_by_email($login_or_email)
  } else {
    $self->find_user_by_login($login_or_email)
  }
}

sub has_auth_failure {
  my ($self, $loginname, $plain_pass) = @_;
  my $user = $self->dbic->resultset('user')->single({login => $loginname})
    or return "No such user: $loginname";
  return 'Password mismatch' unless $user->encpass eq md5_hex($plain_pass);
  return undef;
}

sub add_user {
  my ($self, $login, $pass, $email) = @_;

  # XXX: Is this good token?
  my $token = $self->encrypt_password
    ($self->make_password, $login, $pass);

  my $newuser = $self->dbic->resultset('user')
    ->new({login => $login
	   , email => $email
	   , encpass => md5_hex($pass)
	   , confirm_token => $token
	   # XXX: tmppass_expire
	  });

  $newuser->insert;

  ($newuser, $token);
}

sub reset_password {
  my ($self, $email, $expire_mins) = @_;
  my $dbic = $self->dbic;
  my ($auth, $token, $error);
  txn_do $dbic sub {
    unless ($auth = $self->find_user_by_email($email)) {
      $error = "Unknown email: $email";
      return;
    }

    $auth->tmppass($token = $self->make_password(20));
    $auth->tmppass_expire(time + 60*($expire_mins // 60));
    $auth->update;
  };

  die $error if $error;

  $token;
}

sub can_change_password {
  my ($self, $email, $token) = @_;
  my $auth = $self->dbic->resultset('user')
    ->search({email => $email})
      ->single
	or return;

  return unless ($auth->tmppass // '') eq $token;
  return unless time < ($auth->tmppass_expire // 0);
  $auth;
}

sub do_change_password {
  my ($self, $email, $token, $password) = @_;
  my $dbic = $self->dbic;
  my ($user, $error);
  txn_do $dbic sub {
    unless ($user = $self->can_change_password($email, $token)) {
      $error = "Invalid email or expired token!";
      return
    }
    my $auth = $user;
    $auth->update({encpass => md5_hex($password)
		   , tmppass => undef
		   , tmppass_expire => undef});
  };
  die $error if $error;
  $user;
}

sub fetch_pass_pair {
  (my MY $self, my $con) = @_;
  my $pass1 = $con->param_type('password', qr{^\w{8,}$ }x
			       , q|Password should be alphabets and digits|
			      . q|, at least 8 chars.|);
  my $pass2 = $con->param_type('password2', nonempty =>
			       , q|Please retype same password.|);

  unless ($pass1 eq $pass2) {
    die "Password mismatch!";
  }

  $pass1;
}

sub fetch_email {
  (my MY $self, my $con) = @_;
  my $email = $con->param_type
    ('email', qr{^[\w\.\-]+\@[\w\.\-]+$ }x
     , q|Email syntax error!|);
}

# Stolen from Slash/Utility/Data/Data.pm:changePassword
{
  my @chars = grep !/[0O1Iil]/, 0..9, 'A'..'Z', 'a'..'z';
  sub make_password {
    my ($self, $len) = @_;
    return join '', map { $chars[rand @chars] } 1 .. ($len // 8);
  }

  sub encrypt_password {
    my ($self, @rest) = @_;
    md5_hex(join ":", reverse @rest);
  }
}

#========================================
use YATT::Lite::XHF qw(parse_xhf);
use YATT::Lite::Util qw(terse_dump);
use YATT::Lite::Util qw(ostream);

sub output_file {
  my ($fn, $enc) = @_;
  open my $fh, '>'.($enc // ''), $fn or die "Can't open file '$fn': $!";
  $fh;
}

sub sendmail {
  my ($self, $con, $page, $widget_name, $to, @rest) = @_;
  if (grep {not defined $_} $widget_name, $to) {
    die "Not enough parameter!";
  }
  my $sub = $page->can("render_$widget_name")
    or die "Unknown widget $widget_name";

  my $transport = $ENV{EMAIL_SENDER_TRANSPORT};
  my $is_debug = defined $transport && $transport eq 'YATT_TEST';

  my $layer = $con->get_encoding_layer;
  my $fh = $is_debug ? output_file("$self->{cf_datadir}/.htdebug.eml", $layer)
    : ostream(my $buffer, $layer);

  $sub->($page, $fh, $to, @rest);

  if ($is_debug) {
    return 'ok';
  } else {
    require Email::Simple;
    require Email::Sender::Simple;
    my $msg = Email::Simple->new($buffer);

    Email::Sender::Simple->send($msg);
  }
}

Entity mail_sender => sub {
  my ($this) = @_;
  $this->entity_dir_config('mail_sender') || 'webmaster@localhost';
};


#========================================

sub dbic {
  my MY $self = shift;
  $self->{dbic} //= $self->DBIC->connect($self->dbi_dsn);
}

sub dbic_disconnect {
  (my MY $self) = @_;
  if (my $dbic = $self->{dbic}) {
    $dbic->storage->disconnect;
  }
  $self;
}

sub dbi_dsn {
  my MY $self = shift;
  "dbi:SQLite:dbname=$self->{cf_dbname}";
}

sub cmd_setup {
  my MY $self = shift;
  require File::Path;
  foreach my $dir ($self->{cf_datadir}, $self->{cf_tmpdir}) {
    next if -d $dir;
    File::Path::make_path($dir, {mode => 02775, verbose => 1});
  }
  # XXX: more verbosity.
  # XXX: Should be idempotent.
  # $self->dbic->YATT_DBSchema->deploy;
  $self->DBIC->YATT_DBSchema->cf_let
    ([verbose => 1]
     , connect_to => sqlite => $self->{cf_dbname});
}

#========================================
sub after_new {
  my MY $self = shift;

  $self->SUPER::after_new(); # **REQUIRED**

  $self->{cf_tmpdir}  //= $self->app_path_var_tmp;
  $self->{cf_datadir} //= $self->app_path_var('data');
  $self->{cf_dbname}  //= "$self->{cf_datadir}/.htdata.db";
}
