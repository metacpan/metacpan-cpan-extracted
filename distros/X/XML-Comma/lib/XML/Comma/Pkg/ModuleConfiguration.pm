package XML::Comma::Pkg::ModuleConfiguration;

use strict;
use warnings;

{
  my $config; 

  sub get {
    my ( $class, $m ) = @_;
    # fill the private config hash if we haven't already
    $config->{$class} ||= $class->make_config();
    return $config->{$class}->{$m}; 
  }

  sub dump {
    my ( $class ) = shift;
    $config->{$class} ||= $class->make_config();
    foreach my $key ( keys %{$config->{$class}} ) {
      print "$key --> " . $config->{$class}->{$key} . "\n";
    }
  }

  #only privileged code should ever call this. right now the only
  #use is for appending architecture to XML::Comma->sys_directory()
  sub _set {
    my ( $class, $m, $v ) = @_;
    $config->{$class}->{$m} = $v; 
  }

}

sub make_config {
  my $class = shift();
  my $fh = $class->get_data_filehandle();
  # use a join rather than local'ing $/ so that line numbers are
  # counted (for error reporting). it might also be possible to set
  # the input line number to some guessed-at offset, to help error
  # line numbers be close to what they should be.
  my $block = join ( '', <$fh> );
  my $config = eval "{ $block }";
  if ( $@ ) {
    my $err = $@; 
    die "eval err: $err\n"; 
  }
  return $config; 
}

sub get_data_filehandle {
  no strict "refs";
  my $class = shift;
  my $fh_name = "$class" . '::DATA';
  #print "fhname: $fh_name\n"; 
  return *{$fh_name};
}

1;
