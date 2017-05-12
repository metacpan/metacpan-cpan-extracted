package YATT::Class::Tcl;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Tcl;

use base qw(YATT::Class::Configurable);
use YATT::Fields (qw(tcl)
		  , ['^cf_myname'  => '::yatt::perl']
		  , ['cf_tclinit' => 1]);

use YATT::Util::Symbol;

foreach my $meth (qw(Eval EvalFile Init call icall invoke result
		     CreateCommand DeleteCommand
		     SetResult AppendResult AppendElement ResetResult
		     SplitList
		     SetVar SetVar2 GetVar GetVar2
		     UnsetVar UnsetVar2
		     return_ref delete_ref )) {
  *{globref(MY, $meth)} = sub {
    my MY $self = shift;
    $self->{tcl}->$meth(@_);
  };
}

#
# Expose tcl commands (in ::*) as methods.
#
sub AUTOLOAD {
  my $method = our $AUTOLOAD;
  $method =~ s/.*:://;
  (my MY $self) = @_;
  our ($sub, %NEGATIVE_CACHE);
  if (exists $NEGATIVE_CACHE{$method} or not do {
    if (my @found = $self->{tcl}->invoke(info => commands => $method)) {
      $sub = sub {
	my MY $self = shift;
	$self->{tcl}->invoke($method, @_);
      };
    } else {
      undef $NEGATIVE_CACHE{$method}
    }
   }) {
    die "No such method: $method";
  }
  *{globref(class($self), $method)} = $sub;
  goto &$sub;
}

sub new {
  my MY $self = shift->SUPER::new(@_);
  $self->{tcl}->Init if $self->{cf_tclinit};
  if (my $myname = $self->myname) {
    # 決め打ちはどうかとも思うが、そもそもこの tcl interp は
    # この YATT::Class::Tcl インスタンスに固有だから、衝突のしようがない。
    $self->{tcl}->Eval(<<'END');
namespace eval ::yatt {
proc nslist nsname {
    set q [namespace qualifier $nsname]
    if {$q eq ""} {
	return [list $nsname]
    } else {
	linsert [nslist $q] end [namespace tail $nsname]
    }
}

proc ensure-nslist nslist {
    if {![llength $nslist]} {
	list
    } else {
	list namespace eval [lindex $nslist 0] \
	    [ensure-nslist [lrange $nslist 1 end]]
    }
}

proc ensure-ns nsname {
  uplevel #0 [ensure-nslist [nslist [namespace qualifier $nsname]]]
}

}

END

    $self->{tcl}->invoke('yatt::ensure-ns', $myname);
    $self->{tcl}->CreateCommand($myname, \&perl_dispatch, $self);
  }
  $self
}

sub before_configure {
  my MY $self = shift;
  $self->{tcl} = new Tcl;
  $self
}

sub perl_dispatch {
  (my MY $self, my ($tcl, undef, $method)) = splice @_, 0, 4;
  $tcl->ResetResult;
  my @result = $self->$method(@_); # To make debugger happy.
  $tcl->AppendResult(map {defined $_ ? $_ : ""} @result);
}

sub MainLoop {
  (my MY $self, my $varname) = @_;
  $self->{tcl}->invoke(vwait => $varname || 'forever');
}

sub lexpand {
  (my MY $tcl, my ($list, $n)) = @_;
  $tcl->{tcl}->invoke(lrange => $list, defined $n ? $n : 0, 'end');
}

sub lexpand_if {
  (my MY $tcl, my ($typename, $list)) = @_;
  return if $tcl->{tcl}->lindex($list, 0) ne $typename;
  # 先頭が一致するなら、残りを返す。
  $tcl->lexpand($list, 1);
}

1;
