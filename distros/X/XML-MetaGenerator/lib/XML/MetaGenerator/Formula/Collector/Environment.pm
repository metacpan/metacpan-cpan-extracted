package XML::MetaGenerator::Formula::Collector::Environment;

use strict;
use XML::MetaGenerator;

BEGIN  {
  $XML::MetaGenerator::Formula::Collector::Environment::VERSION = '0.03';
  @XML::MetaGenerator::Formula::Collector::Environment::ISA = qw();
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my ($handlers) = [
		    End => \&{__PACKAGE__.'::_handle_end'},
		    Start => \&{__PACKAGE__.'::_handle_start'},
		    Char =>\&{__PACKAGE__.'::_handle_char'}	
		   ];
  bless {
	 r => $r, 
	 handlers => $handlers
	}, $class;
}

sub getHandlers {
  return $handlers;
}

sub _handle_char {
  my ($expat, $string) = @_;
  #do nothing
  0;
}

sub _handle_start {
  my ($expat) = shift;
  my ($element) = shift;
  my %attr = @_;

  # fake a central $self object [?!?]
  my $self = XML::MetaGenerator->get_instance();
  my $r = $self->{collector}->{r};

  if ($element eq 'element') {
    if (defined($attr{type}) && ($attr{type} eq 'string' || $attr{type} eq 'password')) {
      my $in = $ENV{$attr{name}};
      chomp $in;
      $self->{form}->{$attr{name}} = $in;
    }
  }
}

sub _handle_end {
  my ($expat) = shift;
  my ($element) = shift;
  # do nothing
  ;
}

1;
