package XML::MetaGenerator::Formula::Collector::ReadLine;

use strict;
use Term::ReadLine;
use Term::ReadKey;
use XML::MetaGenerator;

BEGIN  {
  $XML::MetaGenerator::Formula::Collector::ReadLine::VERSION = '0.03';
  @XML::MetaGenerator::Formula::Collector::ReadLine::ISA = qw();
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $t = new Term::ReadLine 'XML::MetaGenerator::Formula::Collector::ReadLine';
  my $form = {};
  my ($handlers) = [
		    End => \&{__PACKAGE__.'::_handle_end'},
		    Start => \&{__PACKAGE__.'::_handle_start'},
		    Char =>\&{__PACKAGE__.'::_handle_char'}	
		   ];
  bless {
	 t => $t, 
	 form=> $form,
	 handlers => $handlers
	}, $class;
}

sub getHandlers {
  my ($self) = shift;
  return $self->{handlers};
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
  my $t = $self->{collector}->{t};

  if ($element eq 'formula') {
    $self->{form}->{formula} = $attr{id};
  }
  elsif ($element eq 'element') {
    if (defined($attr{type}) && ($attr{type} eq 'string' || $attr{type} eq 'password')) {
      my $desc = $attr{editdesc}?$attr{editdesc}:$attr{desc};
      my $type = $attr{type};
      my $prompt = $self->{form}->{formula}.":".$attr{name}." - ".$desc." ($type):# ";
      my $in = $t->readline($prompt);
      chomp $in;
      $self->{form}->{$attr{name}} = $in;
      $t->addhistory($in);
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
