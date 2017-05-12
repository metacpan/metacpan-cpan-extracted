package Errors::Errors;

##############################################
# Errors module written by Julian Lishev
# This module is part of WebTools package!
# Privacy and terms are same as WebTools!
# See also: http://www.proscriptum.com/
##############################################

use strict;

# ----- Global members for all objects -----
$Errors::Errors::debugging = 0;
$Errors::Errors::sys_last_TERM_obj = '';
$Errors::Errors::sys_last_ALRM_obj = '';
$Errors::Errors::sys_sent_content  = 0;
$Errors::Errors::sys_last_ERROR = 0;
$Errors::Errors::sys_exit_called = 0;

BEGIN
 {
  use vars qw($VERSION @ISA @EXPORT);
  $VERSION = "1.26";
  @ISA = qw(Exporter);
  @EXPORT = qw();
 }

sub AUTOLOAD
{
 my $self = shift;
 my $type = ref($self) or die "$self is not an object";
 my $name = $Errors::Errors::AUTOLOAD;
 $name =~ s/.*://;   # Strip fully-qualified portion
 $name = lc($name);
 unless (exists $self->{__subs}->{$name})
   {
    print "Can't access '$name' field in class $type";
    exit;
   }
my $ref =  $self->{__subs}->{$name};
if(ref($ref)) { &$ref($self,@_); }
}

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 
 my %inp = @_;

 $self->{'error'} = 0;
 $self->{'content'} = $inp{'content'} || 1;
 $Errors::Errors::sys_sent_content = $self->{'content'};
 $self->{'context'} = $ENV{SCRIPT_NAME} eq '' ? 'console' : 'browser';
 $self->{'__subs'} = {};
 $self->{'__errors'} = {};
 $self->{'__objects'} = {};
 $self->{'__counters'} = {};
 $self->{'__subs'}->{'header'}  = \&__default_header;
 $self->{'__subs'}->{'onerror'} = \&__default;
 $self->{'__subs'}->{'onexit'}  = \&__default;
 $self->{'__subs'}->{'onterm'}  = \&__default;
 $self->{'__subs'}->{'ontimeout'}  = \&__default;
 $self->{'__counters'}->{'exit'} = 0;
 $self->{'__counters'}->{'die'} = 0;

 bless($self,$class);
 return($self);
}

sub _set_val_Errors
{
 my $self = shift(@_);
 my $name = shift(@_);
 my @params = @_;
 if(defined($_[0]))
  {
   my $code = '$self->{'."'$name'".'} = $_[0];';
   eval $code;
   return($_[0]);
  }
 else
  {
   my $code = '$code = $self->{'."'$name'".'};';
   eval $code;
   return($code);
  }
}

sub content
{
 my $self = shift(@_);
 my $val  = shift(@_);
 $self->_set_val_Errors('content', $val); 
 $Errors::Errors::sys_sent_content = $val;
} 

sub __default {return 1;}
sub __default_header
{
 if(!$Errors::Errors::sys_sent_content)
  {
   print "Content-type: text/html\n\n";
  }
}

sub __default_SIGNALS
{
  my $self = $Errors::Errors::sys_last_TERM_obj;
  my $sub;
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'onterm'};
    if(ref($ref)) { &$ref($self,'term',''); }
   }
  my $ref = $self->{'__subs'}->{'onterm'};
  if(ref($ref)) { &$ref($self,'term',''); }
}

sub __default_ALRM
{
  my $self = $Errors::Errors::sys_last_ALRM_obj;
  my $sub;
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'ontimeout'};
    if(ref($ref)) { &$ref($self,'timeout',''); }
   }
  my $ref = $self->{'__subs'}->{'ontimeout'};
  if(ref($ref)) { &$ref($self,'timeout',''); }
}

sub install
{
 my $self = shift;
 my $name  = shift;
 my $subref = shift;
 my $sub  = shift;
 $name = lc($name);
 $sub  = lc($sub);
 
 if($sub eq '')
  {
   if($name eq 'onterm')
    {
     $SIG{'TERM'} = \&__default_SIGNALS;
     $SIG{'QUIT'} = \&__default_SIGNALS;
     $SIG{'PIPE'} = \&__default_SIGNALS;
     $SIG{'STOP'} = \&__default_SIGNALS;
     $Errors::Errors::sys_last_TERM_obj = $self;
    }
   if($name eq 'ontimeout')
    {
     $SIG{'ALRM'} = \&__default_ALRM;
     $Errors::Errors::sys_last_ALRM_obj = $self;
    }
   $self->{'__subs'}->{$name} = $subref;
  }
 else
  {
   $self->{'__errors'}->{$sub}->{$name} = $subref;
  }
 return(1);
}

sub uninstall
{
 my $self = shift;
 my $name  = shift;
 my $sub  = shift;
 $name = lc($name);
 $sub  = lc($sub);
 
 if($sub eq '')
  {
   if($name eq 'onterm')
    {
     $SIG{'TERM'} = \&__default_SIGNALS;
     $SIG{'QUIT'} = \&__default_SIGNALS;
     $SIG{'PIPE'} = \&__default_SIGNALS;
     $SIG{'STOP'} = \&__default_SIGNALS;
    }
   if($name eq 'ontimeout')
    {
     $SIG{'ALRM'} = \&__default_ALRM;
    }
   $self->{'__subs'}->{$name} = undef;
  }
 else
  {
   $self->{'__errors'}->{$sub}->{$name} = undef;
  }
 return(1);
}

sub print
{
 my $self = shift;
 print @_;
}

sub attach
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 $self->{'__errors'}->{$name} = {
 	'error' => 0,
 	'onerror' => \&__default,
        'onexit'  => \&__default,
        'onterm'  => \&__default,
        'ontimeout'  => \&__default,
        };
 $self->{'__objects'}->{$name} = '';
 return(1);
}

sub attach_object
{
 my $self = shift;
 my $name  = shift;
 my $objref = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    $self->{'__objects'}->{$name} = $objref;
   }
 return(1);
}

sub fetch_object
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    return($self->{'__objects'}->{$name});
   }
 return(undef);
}

sub detach_object
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 
 if($self->{'__errors'}->{$name})
   {
    $self->{'__objects'}->{$name} = undef;
   }
 return(1);
}

sub detach
{
 my $self = shift;
 my $name  = shift;
 $name = lc($name);
 $self->{'__errors'}->{$name} = undef;
 $self->{'__objects'}->{$name} = undef;
 return(1);
}

sub error
{
  my $self  = shift;
  my $value = shift;
  my $name  = shift;
  my @res = ();
  my $sub;
  if($name eq '')
   {
    @res = $self->_set_val_Errors('error', $value);
    $Errors::Errors::sys_last_ERROR = $value;
   }
  else
   {
    my $hashref = $self->{'__errors'};
    if(defined($value))
     {
      $hashref->{$name}->{'error'} = $value;
      $Errors::Errors::sys_last_ERROR = $value;
      @res = ($value);
     }
    else
     {
      @res = $hashref->{$name}->{'error'};
     }
   }
  my $hashref = $self->{'__errors'};
  foreach $sub (keys %$hashref)
   {
    my $ref = $hashref->{$sub}->{'onerror'};
    if(ref($ref)) { &$ref($self,$value,$name,@_); }
   }
  my $ref = $self->{'__subs'}->{'onerror'};
  if(ref($ref)) { &$ref($self,$value,$name,@_); }
 
  return(@res);
}

sub die
{
  my $self = shift;
  if($self->{'__counters'}->{'die'} == 0)
  {
   $Errors::Errors::sys_exit_called = 1;
   $self->{'__counters'}->{'die'} = 1;
   my $sub;
   my $hashref = $self->{'__errors'};
   foreach $sub (keys %$hashref)
    {
     my $ref = $hashref->{$sub}->{'onexit'};
     if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','die'); }
    }
   my $ref = $self->{'__subs'}->{'onexit'};
   if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','die'); }
   die(@_);
  }
  else {die(@_);}
}

sub exit
{
  my $self = shift;
  if($self->{'__counters'}->{'exit'} == 0)
  {
   $Errors::Errors::sys_exit_called = 1;
   $self->{'__counters'}->{'exit'} = 1;
   my $sub;
   my $hashref = $self->{'__errors'};
   foreach $sub (keys %$hashref)
    {
     my $ref = $hashref->{$sub}->{'onexit'};
     if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','exit'); }
    }
   my $ref = $self->{'__subs'}->{'onexit'};
   if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','exit'); }
   exit(@_);
  }
  else {exit(@_);}
}

sub DESTROY
{
  my $self = shift;
  my $sub;
  my $hashref = $self->{'__errors'};
  if(!$Errors::Errors::sys_exit_called)
   {
    $Errors::Errors::sys_exit_called = 1;
    $self->{'__counters'}->{'die'} = 1;
    $self->{'__counters'}->{'exit'} = 1;
    foreach $sub (keys %$hashref)
     {
      my $ref = $hashref->{$sub}->{'onexit'};
      if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','destroy'); }
     }
    my $ref = $self->{'__subs'}->{'onexit'};
    if(ref($ref)) { &$ref($self,$Errors::Errors::sys_last_ERROR,'','destroy'); }
   }
}

1;
__END__

=head1 NAME

 Errors.pm - Full featured error management module

=head1 DESCRIPTION

=over 4

Error module is created as base "error" catcher module especially for Web

=back

=head1 SYNOPSIS

 use Errors::Errors;

 $obj = Errors::Errors->new();
 
 $obj->content(0);
 $obj->header();

 $obj->attach('xreader');  # Attach sub object for error of type 'xreader'
 $obj->attach('myown');    # Attach sub object for error of type 'myown'
 
 $hash = {
	  name=>'July',
	  born_year=>'81',
	 };
 
 $obj->attach_object('xreader',$hash); # Hash ref or object
 
 $obj->install('onTerm',\&custom);
 $obj->install('onError',\&anysub,'xreader');
 $obj->install('onExit',\&leave);
 $obj->install('onTerm',\&custom,'myown');
 
 $obj->error(7,'xreader');
 
 $h = $obj->fetch_object('xreader');
 $obj->print($h->{name});
 
 $obj->uninstall('onError','xreader');
 
 $obj->detach_object('xreader');
 $obj->detach('xreader');
 
 $obj->install('onTimeOut',\&timeout);
 eval 'alarm(2);';
 
 $obj->exit();

 sub custom {
  my $obj   = shift;       # 'Errors' object
  my $err   = shift;       # Error number/message (for TERM it has value 'term')
  my $name  = shift;       # 'name' of error (for TERM it has empty value)
  # ...blah...blah...
 }
 sub leave {
  my $obj   = shift;       # 'Errors' object
  my $err   = shift;       # Last error number/message
  my $name  = shift;       # 'name' of error
  my $how   = shift;       # can be: 'exit','die' or 'destroy'
  # ...blah...blah...
 }
 sub timeout
 {
  my $obj    = shift;      # 'Errors' object
  my $what   = shift;      # 'timeout' string
  # ...blah...blah...
  print "Time OUT";
 }
 sub anysub {
  my $obj   = shift;       # 'Errors' object
  my $err   = shift;       # Error number/message
  my $name  = shift;       # 'name' of error
  if($name =~ m/xreader/si)
   {
    $obj->print ("Error in Xreader!!!");  # If error is raised in 'xreader'
   }
  else
   {
    $obj->print ("Error in ... I don't know :-)!!!");
   }
 }

=head1 AUTHOR

 Julian Lishev - Bulgaria, Sofia, 
 e-mail: julian@proscriptum.com, 
 www.proscriptum.com

=cut
