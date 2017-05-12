package SAPNW::Connection;

=pod

    Copyright (c) 2006 - 2010 Piers Harding.
        All rights reserved.

=cut

  use strict;
  require 5.008;
  require DynaLoader;
  require Exporter;
  use Data::Dumper;
  use SAPNW::Base;

  use base qw(SAPNW::Base);



  use vars qw(@ISA $VERSION $DEBUG $SAPNW_RFC_CONFIG);
  $VERSION = '0.37';
  @ISA = qw(DynaLoader Exporter); 

  sub dl_load_flags { $^O =~ /hpux|aix/ ? 0x00 : 0x01 }
  SAPNW::Connection->bootstrap($VERSION);

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @rest = @_;
    my $self = {
       interfaces => {},
       config => { @rest },
       handle => undef
    };
    bless($self, $class);
    return $self;
    }


    sub config {
      my $self = shift;
        return $self->{config};
    }


    sub interfaces {
      my $self = shift;
        return $self->{interfaces};
    }


    sub installFunction {
       my $self = shift;
       my ($func, $sysid) = @_;
       die "must be passed a Function Descriptor\n" unless
          ref($func) eq "SAPNW::RFC::FunctionDescriptor";
       $sysid ||= "";
       return SAPNW::Connection::install($func, $sysid);
    }


sub handler {

  my $handler = shift;
  my $attrib = shift;

  my $result = "";
  eval { $result = &$handler($attrib); };
    $result = $@ if $@;
    debug("global callback result: $result");
  return $result;

}


sub main_handler {

    my $func = shift;
    my $parameters = shift;
    my $fcall = {'parameters' => $parameters};
    bless($fcall, 'SAPNW::RFC::FunctionCall');
    my $handler = $func->callback;
    my $result = "";
    eval { $result = &$handler($fcall); };
    $result = {'message' => $@, 'code' => 999, 'key' => 'PERL_ERROR'} if $@;
    debug("function callback result: $result");
    delete $fcall->{'parameters'};
    undef $fcall;
    return $result;
}



# Tidy up open Connection when DESTROY Destructor Called
sub DESTROY {
    my $self = shift;
    $self->disconnect() if exists $self->{handle} && defined($self->{handle});
}

1;
