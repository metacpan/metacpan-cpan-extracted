package XML::MetaGenerator::Formula::Generator::SimpleHTML;

use strict;
use XML::MetaGenerator;

BEGIN  {
  $XML::MetaGenerator::Formula::Generator::SimpleHTML::VERSION = '0.03';
  @XML::MetaGenerator::Formula::Generator::SimpleHTML::ISA = qw();
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

  $$buffer .= "<html><head><title>".$wow->{formula_key}."</title></head>\n";
  $$buffer .= "<body>\n";
  $$buffer .= "<table bgcolor=\"#999999\">\n";
  $$buffer .= "<tr bgcolor=\"#444444\"><td><font color=\"white\">Key</font></td><td><font color=\"white\">Value</font></td></tr>\n";
}

sub _handle_final {
  my ($expat) = shift;

  my ($wow) = XML::MetaGenerator->get_instance;
  my ($buffer) = \$wow->{generator}->{buffer};

  $$buffer .= "</table>\n</body></html>";
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
    $$buffer .= "<tr ";
# && eval { foreach ($wow->{validator}->{invalids}) { return 1 unless ($_ ne $attr{name})};})
    $$buffer .= (defined($wow-> {validator}->{invalids}) && eval { foreach (@{$wow->{validator}->{invalids}}) { return 1 unless($_ ne $attr{name});}} )?"bgcolor=\"#CC0000\" ":"";
    $$buffer .= "><td>";
    $$buffer .= $attr{desc}?$attr{desc}:$attr{name};
    $$buffer .="</td>";
    $$buffer .= "<td>".$wow->{form}->{$attr{name}}."</td></tr>\n";
  }


}

sub _handle_end {
  my ($expat) = shift;
  my ($element) = shift;
  # do nothing
  ;
}

1;
