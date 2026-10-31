package YATT::Lite::ConnectionProxy; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp ();
use Symbol ();
use Scalar::Util ();
use Encode ();

require YATT::Lite::Util;

# $CON while capturing output (GH-295).
#
# Like YATT::Lite::Connection, this is a blessed glob. Its IO slot is
# the capture buffer and its HASH slot holds the original connection.
# So `print $CON ...` goes to the buffer, and all methods are
# delegated to the original connection.

sub capture {
  my ($pack, $con, $code) = @_;
  my $root = _root_connection($con)
    or return &YATT::Lite::Util::captured($code);
  my $buffer = "";
  {
    my $glob = Symbol::gensym();
    open $glob, '>:utf8', \ $buffer
      or die "Can't create capture buf:$!";
    bless $glob, $pack;
    *$glob = {connection => $root};
    $code->($glob);
    close $glob;
  }
  Encode::_utf8_on($buffer);
  $buffer;
}

# Nested capture shares the original connection (no proxy of proxy).
sub _root_connection {
  my ($con) = @_;
  return undef unless Scalar::Util::blessed($con);
  if (UNIVERSAL::isa($con, MY)) {
    $con->connection;
  } elsif ($con->isa('YATT::Lite::Connection')) {
    $con;
  } else {
    undef;
  }
}

sub connection {
  my ($glob) = @_;
  *{$glob}{HASH}->{connection};
}

# Forwarders are independent from the class of the original connection,
# so they are installed once and shared.
our %FORWARDER;
sub _forwarder {
  my ($name) = @_;
  $FORWARDER{$name} //= do {
    my $sub = sub {
      my $glob = shift;
      $glob->connection->$name(@_);
    };
    no strict 'refs';
    *{MY . "::$name"} = $sub;
  };
  \&{MY . "::$name"};
}

our $AUTOLOAD;
sub AUTOLOAD {
  my $name = substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
  my $con = ref $_[0] ? $_[0]->connection : undef;
  unless ($con and $con->can($name)) {
    Carp::croak(sprintf q{Can't locate object method "%s" via package "%s"}
                , $name, ref $con || ref $_[0] || $_[0]);
  }
  goto &{_forwarder($name)};
}

# Methods from ->can must work with the proxy as invocant.
sub can {
  my ($glob, $name) = @_;
  if (not $FORWARDER{$name} and my $sub = $glob->SUPER::can($name)) {
    return $sub;
  }
  return undef unless ref $glob;
  my $con = $glob->connection;
  $con && $con->can($name) ? _forwarder($name) : undef;
}

sub isa {
  my ($glob, $class) = @_;
  $glob->SUPER::isa($class)
    or ref $glob && do {
      my $con = $glob->connection;
      $con && $con->isa($class);
    };
}

# Never delegate this. Connection::DESTROY clears its props.
sub DESTROY {}

1;
