#!/usr/bin/perl
use strict;
use lib '../blib/lib';
use lib '../blib/arch';
use lib './blib/lib';
use lib './blib/arch';
use sapnwrfc;
use Data::Dumper;
use Devel::Cycle;

use vars qw($DEBUG);

#$| = 1;

$DEBUG = 1;

#   Register an external program to provide outbound
#   RFCs

print "Testing SAPNW::Rfc-$SAPNW::Rfc::VERSION\n";
SAPNW::Rfc->load_config;

my $pass = 0;
my $server = SAPNW::Rfc->rfc_register(
                           tpname   => 'wibble.rfcexec',
                           gwhost   => 'gecko.local.net',
                           gwserv   => '3301',
                           trace    => '1',
#                           );
                           debug => 1 );

print STDERR "Connection attributes: ".Dumper($server->connection_attributes)."\n";
my $func;
##if (1==2) {
$func = new SAPNW::RFC::FunctionDescriptor("RFC_REMOTE_PIPE");
my $pipedata = new SAPNW::RFC::Type(name => 'DATA', 
                                    type => RFCTYPE_TABLE,
                                    fields => [{name => 'LINE',
                                                type => RFCTYPE_CHAR, 
                                                len => 80}]
                                    );
$func->addParameter(new SAPNW::RFC::Export(name => "COMMAND", len => 80, type => RFCTYPE_CHAR));
$func->addParameter(new SAPNW::RFC::Table(name => "PIPEDATA", len => 80, type => $pipedata));
$func->callback(\&do_remote_pipe);
$server->installFunction($func);
##} 
##else {
#$func = new SAPNW::RFC::FunctionDescriptor("MY_RFC_PING");
#$func->callback(\&do_ping);
##}


$server->installFunction($func);

print STDERR " START: ".scalar localtime() ."\n";

$server->accept(5, \&do_something);

$server->disconnect();

sleep 1;
warn "bing!\n";


sub do_ping {
  debug("PING ...");
    $pass += 1;
    warn "pass: $pass\n";
   # if ($pass >= 75) {
   # warn "going to die...\n";
   # return undef;
   # } else {
    return 1;
   # }
}

sub do_something {
  my $thing = shift;
  debug("Running do_something ($thing) ...");
    return 1;
}


sub do_remote_pipe {
  my $func = shift;
  my $ls = $func->COMMAND;
  debug("Running do_remote_pipe: $ls");
  $func->PIPEDATA( [ map {  { 'LINE' => pack("A80",$_) } } split(/\n/, `$ls`) ]);
  #die "MY_CUSTOM_ERROR with some other text";
   $pass += 1;
   warn "pass: $pass\n";
   if ($pass >= 100) {
     warn "going to die...\n";
     return undef;
   } else {
     return 1;
   }
}


sub debug {
  return unless $DEBUG;
  print  STDERR scalar localtime().": ", @_, "\n";
}

