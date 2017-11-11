package Win32::Shortkeys::Manager;
use strict;
use warnings;

#use Data::Dumper;

use constant STARTKEY => 226; #<

sub new {
  my ($class, $data) = @_;
  my $self = bless ({}, ref ($class) || $class);
  $self->{searchOn}= 0;
  $self->{found} = 0; 
  $self->{data} = $data;
 
 return $self;
}


sub listen {
    my ($self, $kcode) = @_;

    my %data = %{$self->{data}};
    #print "Listen to kcode  $kcode current: ", defined $self->{current} ? $self->{current} : " undef", "\n";
    
      $self->{found} = 0;
    if ($kcode == STARTKEY ) { 
        # $self->{searchOn} = ( $self->{searchOn} ? 0 : 1) ; 
        $self->{searchOn} = 1;
        $self->{current} = undef;
        $self->{found}=0;
    } elsif ($self->{searchOn} && 64 < $kcode && $kcode < 91) {
          $self->{current} .= chr (32 + $kcode); #lower case letters in {current}
          #die $self->{current};

          if ( exists $data{ $self->{current} }) {
                #print $self->{current}, "\n";
                $self->{found} =1;
                $self->{searchOn} = 0;
          }
         

    
    } else  { 
        $self->{found} = 0;
        $self->{searchOn} = 0;
        $self->{current} = undef;
    
    }

    #  print "listen  current: ", ( $self->{current} ? $self->{current} : " undef "), " searchOn: ", $self->{searchOn}, " found: ", $self->{found}, "\n";

}


sub is_ready {
    my $self = shift;
    #print "is_ready ", ( $self->{found} ? " true ": " false "), "\n";
    $self->{found};


}

sub get_shortkey {
    my $self = shift;
    $self->{found} ? $self->{current} : undef;
}

sub get_data {
    my $self = shift;
    #print "get_Data returning ", ($self->{found} ? $self->{data}->{ $self->{current} } : " undef "), "\n";
    $self->{found} ? $self->{data}->{ $self->{current} }:  undef;
}

sub print_all {
    my $self = shift;
    my @shks = keys %{ $self->{data} };
    for my $shk ( @shks ) {
        print $shk, " -> ", $self->{data}->{$shk}, "\n";
    }
}

1;
