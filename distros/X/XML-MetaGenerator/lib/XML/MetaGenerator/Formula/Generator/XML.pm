package XML::MetaGenerator::Formula::Generator::XML;

use strict;
use XML::Generator;
use XML::MetaGenerator;

BEGIN  {
  $XML::MetaGenerator::Formula::Generator::XML::VERSION = '0.03';
  @XML::MetaGenerator::Formula::Generator::XML::ISA = qw();
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my ($handlers) = [
		    Init =>\&{__PACKAGE__.'::_handle_init'},
		    Final =>\&{__PACKAGE__.'::_handle_final'},
		    End => \&{__PACKAGE__.'::_handle_end'},
		    Start => \&{__PACKAGE__.'::_handle_start'},
		    Char =>\&{__PACKAGE__.'::_handle_char'}
		   ];
  bless {
	 handlers => $handlers,
	 buffer => undef,
	}, $class;
}

sub getHandlers {
  my ($self) = shift;
  return $self->{handlers};
}

sub _handle_init {
  my ($expat) = shift;
  my $wow = XML::MetaGenerator->get_instance;
  my ($buffer) = \$wow->{generator}->{buffer};
  my ($xml) = \$wow->{generator}->{xml};

  $$buffer .= "<?xml version=\"1.0\" ?>\n";
  $$buffer .= "<".$wow->{formula_key}.">\n";
}

sub _handle_final {
  my ($expat) = shift;

  my ($wow) = XML::MetaGenerator->get_instance;
  my ($buffer) = \$wow->{generator}->{buffer};

  $$buffer .= "</".$wow->{formula_key}.">";
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

  my ($wow) = XML::MetaGenerator->get_instance;
  my ($buffer) = \$wow->{generator}->{buffer};

  if ($element eq 'element') {
    $$buffer .= "\t<".$attr{name}.">";
    $$buffer .= $wow->{form}->{$attr{name}};
    $$buffer .= "</".$attr{name}.">\n";
  }


}

sub _handle_end {
  my ($expat) = shift;
  my ($element) = shift;
  # do nothing
  ;
}

1;
