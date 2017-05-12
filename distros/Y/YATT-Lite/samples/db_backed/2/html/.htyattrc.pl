#!/usr/bin/perl -w
use strict;
use warnings qw(FATAL all NONFATAL misc);

use fields qw(dbic
	      cf_tmpdir cf_datadir
	      cf_dbname cf_dbuser cf_dbpass);

use YATT::Lite::Entities qw(*CON);

sub DBIC () { __PACKAGE__ . '::DBIC' }

use YATT::Lite::WebMVC0::DBSchema::DBIC
  (DBIC, verbose => $ENV{DEBUG_DBSCHEMA}
   , [user => undef
      , uid => [integer => -primary_key
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
      , login => 'text'
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

#========================================

sub dbic {
  my MY $self = shift;
  $self->{dbic} //= do {
    my ($dbi, $user, $pass) = $self->dbi_dsn;
    # DBIC warns 'AutoCommit => 0'.
    $self->DBIC->connect
      ($dbi, $user, $pass
       , {PrintError => 0, RaiseError => 1, AutoCommit => 1});
  };
}

sub dbi_dsn {
  my MY $self = shift;
  my $dsn = "dbi:mysql:database=$self->{cf_dbname}";
  wantarray ? ($dsn, $self->{cf_dbuser}, $self->{cf_dbpass}) : $dsn;
}

sub cmd_setup {
  my MY $self = shift;
  require File::Path;
  foreach my $dir ($self->{cf_datadir}, $self->{cf_tmpdir}) {
    next if -d $dir;
    File::Path::make_path($dir, {mode => 02775, verbose => 1});
  }
  $self->DBIC->YATT_DBSchema->cf_let
    ([verbose => $ENV{VERBOSE} // 1, auto_create => 1
      , coltype_map => {text => 'varchar(80)'}]
     , connect_to => $self->dbi_dsn);
}

#========================================
sub after_new {
  my MY $self = shift;

  $self->{cf_tmpdir}  //= $self->app_path_var_tmp;
  $self->{cf_datadir} //= $self->app_path_var('data');

  my $passfile = $self->app_root."/.htdbpass";
  unless (-e $passfile) {
    die "Can't find $passfile";
  }
  unless (-r $passfile) {
    die "Can't read $passfile";
  }

  $self->cf_by_filetype(xhf => $passfile);

  foreach my $name (qw/dbname dbuser dbpass/) {
    unless (defined $self->{"cf_$name"}) {
      $self->error("'%s' is empty in '%s'!", $name, $passfile);
    }
  }
}
