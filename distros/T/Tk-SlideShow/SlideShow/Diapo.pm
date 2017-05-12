package Tk::SlideShow::Diapo;

sub New {
  my ($class,$name,$code) = @_;
  my $s =  bless { 'name' => $name, 
		   'latex'=> 'No documentation',
		   'code' => $code
		 };
  return $s;
}

sub name { return (shift)->{'name'};}
sub code { return (shift)->{'code'};}

sub html { my ($s,$v) = @_;
	    if (defined ($v)) { $s->{'html'} = $v; return $s; }
	    return $s->{'html'}
	  }



1;

