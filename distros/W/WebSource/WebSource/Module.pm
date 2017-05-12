package WebSource::Module;
use strict;
use Carp;

use WebSource::Envelope;

=head1 NAME

WebSource::Module : WebSource module - class from which all modules inherit
Each module needs to define a C<handler> method.

=head1 SYNOPSIS

{
  package MyModule;
  our @ISA=('WebSource::Module');

  sub handler {
    my ($self,$val) = @_;
    # do something with $val and produce @res
    return @res;
  }

}

my $m = MyModule->new(
  name => "GiveMeAName",
  queue => $queue
);

... do some stuff ...

$m->forwardTo($queue);

... do some stuff ...

$m->run->join();

=head1 METHODS

=over 2

=cut

=item C<< $mod = WebSource::Module->new( name => $name ) >>

Create a new instance of module;

=cut

sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless \%params, $class;
  $self->_init_;
  return $self;
}

=item C<< $mod->_init_ >>

Does some initializations. Any operator $op inheriting from WebSource::Module
should call $op->SUPER::_init_ inside a redefined _init_ method.

=cut

sub _init_ {
  my $self = shift;  
  if(!$self->{name}) {
    carp("No module name given. Using default noname");
    $self->{name} = "noname";
  }
  $self->{producers} = [];
  $self->{consumers} = [];
  $self->{results} = [];
  $self->log(1,"new module named ", $self->{name}, " created");
  if(my $wsd = $self->{wsdnode}) {
    foreach my $dnode ($wsd->findnodes('data')) {
      $self->push(WebSource::Envelope->new(
                     type => "text/string",
                     data => $dnode->textContent
                  ));
    }
    foreach my $dnode ($wsd->findnodes('xmldata')) {
      if(my @enodes = $dnode->findnodes("*")) {
        $self->push(WebSource::Envelope->new(
                       type => "object/dom-node",
                       data => $enodes[0]
                    ));
      } else {
        carp("Warning : xmldata without data detected\n");
      }
    }
    foreach my $pnode ($wsd->findnodes('parameters/param')) {
      my $key = $pnode->getAttribute("name");
      my $val = $pnode->getAttribute("value");
      $key =~ s/-/_/g;
      $self->{$key} = $val;
    }
  }
}

=item C<< $mod->log($level,$message) >>

Use this modules logger to log a message $message with priority level
$level. This is actually used internally. Any inheriting module is encouraged
to use the logging facility.

=cut 

sub log {
  my $self = shift;
  my $level = shift;
  my $class = ref($self);
  my $name = $self->{name};
  $self->{logger} and
    $self->{logger}->log($level, "[$class/$name] ", @_);
}

=item C<< $mod->will_log($level) >>

Use this modules logger to check if a message at level
$level will be logged. This is actually used internally. Any inheriting module is encouraged
to use the logging facility.

=cut 

sub will_log {
  my $self = shift;
  my $level = shift;
  return ($self->{logger} && $self->{logger}->will_log($level));
}

=item C<< $mod->set_logger($log) >>

Sets the logger associated to this module

=cut

sub set_logger {
  my $self = shift;
  $self->{logger} = shift;
  $self->log(1,"logger set");
}

=item C<< $mod->push($val) >>

Push $val into the module. This handles the given value and stores
it onto the stock.

=cut

sub push {
  my $self = shift;
  foreach my $env (@_) {
    UNIVERSAL::isa($env,'WebSource::Envelope') or croak("Didn't push in an envelope");
    $self->log(3,"Handling $env : ", $env->as_string);
    $self->log(8,"Content $env : ",$env->dataXML);
    my @res = $self->handle($env);
    map { defined($_) or croak("Undefined value generated") } @res;
    $self->log(3,"Obtained ",$#res+1," results");
    push @{$self->{results}}, @res;
  }
}

=item C<< $mod->producers(@modules) >>

Add a list of modules from where to ask for data (ie. set @modules
as producers of this module).
Also sets this module as a consumer of each of the modules in @modules.

B<Note :> Only C<producers> or C<consumers> calls should be used

=cut

sub producers {
  my $self = shift;
  foreach my $p (@_) {
    $self->_producers($p);
    $p->_consumers($self);
  }
}

=item C<< $mod->consumers(@modules) >>

Add a list of modules where results should be sent to (ie. set @modules
as consumers of this modules production).
Also sets this module as a producer of each of the modules in @modules.

B<Note :> Only C<producers> or C<consumers> calls should be used

=cut

sub consumers {
  my $self = shift;  
  foreach my $c (@_) {
    $self->_consumers($c);
    $c->_producers($self);
  }
}

sub _producers {
  my $self = shift;
  CORE::push @{$self->{producers}}, @_;
}

sub _consumers {
  my $self = shift;
  CORE::push @{$self->{consumers}}, @_;
}

=item C<< $self->produce >>

Ask this module to produce a result. If some are available in the
stock, the first is sent to its consumers. If not, more results are produced
by asking the producers of this module to produce more.

If a result is produced it is forwarded to the modules consumers and
returned. If no results can be produced undef is returned. (However if
in a consumer, with an originally empty stock, a simpler test on the
stock after having called produce on a producer will do).

=cut

sub produce {
  my $self = shift;
  my %map = @_;

  if(!$self->{__started__}) {
    $self->start();
    $self->{__started__} = 1;
  }

  defined($map{$self->{name}}) or $map{$self->{name}} = 0;
  $map{$self->{name}} >= 1 and return ();
  $map{$self->{name}} += 1;

  my %save = %map;
  $self->log(3,"Producing");
  my @prods = @{$self->{producers}};
  my $done = 0;
  while(!@{$self->{results}} && !$done) {
    $self->log(1,"Asking our ",scalar(@prods)," producers to produce");
    my @res = map {
      $_->produce(%map) 
    } @prods;
    $done = !@res;
    $self->log(1,"Queue has ",scalar(@{$self->{results}})," pending items");
  }
#  while(!@{$self->{results}} && @prods) {
#    my $prod = shift @prods;
#    %map = %save;
#    my @res = $prod->produce(%map);
#    while(!@{$self->{results}} && @res && $res[0]) {
#      %map = %save;
#      @res = $prod->produce(%map);
#    }
#  }
  if(@{$self->{results}}) {
    my $res = shift @{$self->{results}};
    $self->log(3,"Produced ",$res->as_string," (forwarding)");
    foreach my $c (@{$self->{consumers}}) {
      $c->push($res);
    }
    $self->{abortIfEmpty} = 0;
    return $res;
  } else {
    if(!$self->{abortIfEmpty}) {
      return ();
      $self->{__started__} = 0;
      $self->end();
    } else {
      die "No production for ".$self->{name}." with abort-if-empty marked yes\n";
    }
  }
}


=item C<< $mod->start() >>

Called at before production has started

=cut

sub start() {}

=item C<< $mod->end() >>

Called when production has ended (no more producers have data)

=cut

sub end() {}


=item C<< $mod->handle($val) >>

Called internally by push (ie. when data arrives).
When a value $val arrives, C<< $module->handle($val) >> is called
which produces C<@res>. The resulting values are stored onto the
stock;

=cut

sub handle {
  my $self = shift;
#  my $class = ref($self);
#  $self->log(1,"Warning : $class did not define a handler method");
  return @_;
}


sub print_state {
  my $self = shift;
  print "--- State of module ",$self->{name}," ---\n";
  print "In stock  : ",join(",",@{$self->{results}}),"\n";
  print "Producers : ", join(",",map { $_->{name} } @{$self->{producers}}),"\n";
  print "Consumers : ", join(",",map { $_->{name} } @{$self->{consumers}}),"\n";
  print "---\n";
}

sub as_string {
  my $self = shift;
  my $name = $self->{name};
  my $class = ref($self);
  return "$class/$name";
}

=head1 SEE ALSO

WebSource::Fetch, WebSource::Extract, etc.

=cut

1;
