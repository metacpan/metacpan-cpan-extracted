package perfSONAR_PS::XML::Namespace;
{
=head1 NAME

Namespace -  a container for namespaces 

=head1 DESCRIPTION

The purpose of this module is to  create OO interface to namespace registration and therefore
add the layer of abstraction for any namespace related operation. All  perfSONAR-PS classes should
work with the instance of this class and avoid using explicit namespace declaration. 

=head1 SYNOPSIS
 
    use perfSONAR_PS::XML::Namespace; 
    # create Namespace object with default URIs
    $ns = perfSONAR_PS::XML::Namespace->new();
    
    # overwrite  Namespace object with  custom URIs
    $nss =  {'pinger' => 'http://newpinger/namespace/'};
    $ns = perfSONAR_PS::XML::Namespace->new(-hash => $nss);
    
    # overwrite only specific Namespace   with  custom URI 
    
    $ns = perfSONAR_PS::XML::Namespace->new(-pinger =>   'http://newpinger/namespace/');
      
    $pinger_uri = $ns->getNsByKey('pinger'); ## get URI by key
    $ns->setNsByKey('pinger' =>  'http://newpinger/namespace/'); ## set URI by key
    
 
=head1 API

There are many get/set methods

=head2 new(-NS => \%nss)

Creates a new object, pass hash ref as collection of namespaces 
  or new(-pinger => http://ggf.org/ns/nmwg/tools/pinger/2.0/",   'nmwgr' => "http://ggf.org/ns/nmwg/result/2.0/")

=cut

use version; our $VERSION = qv('3.0_1'); 
use Log::Log4perl qw(get_logger);

our $nss = {
           'nmwg' => "http://ggf.org/ns/nmwg/base/2.0/",
               'nmwgr' => "http://ggf.org/ns/nmwg/result/2.0/" ,
	       'select'  => "http://ggf.org/ns/nmwg/ops/select/2.0/",
	       'netutil' => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/", 
	
	       'traceroute' =>"http://ggf.org/ns/nmwg/tools/traceroute/2.0/",
	       'snmp' =>  "http://ggf.org/ns/nmwg/tools/snmp/2.0/", 
	       'ping' => "http://ggf.org/ns/nmwg/tools/ping/2.0/", 
	       'owamp' =>"http://ggf.org/ns/nmwg/tools/owamp/2.0/", 
	       'bwctl' =>"http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
	       'pinger' =>"http://ggf.org/ns/nmwg/tools/pinger/2.0/",
	       'iperf' =>"http://ggf.org/ns/nmwg/tools/iperf/2.0/",
	     
	       'average'=> "http://ggf.org/ns/nmwg/ops/average/2.0/",
	       'nmwgt' => "http://ggf.org/ns/nmwg/topology/2.0/",	
	       'topo'=> "http://ggf.org/ns/nmwg/topology/2.0/",
	     
	       'nmtl4' => "http://ogf.org/schema/network/topology/l4/20070707 ",
	       'nmtl3' => "http://ogf.org/schema/network/topology/l3/20070707",
               
               'nmtl2' => "http://ogf.org/schema/network/topology/l2/20070707/",
               'nmtopo' => "http://ogf.org/schema/network/topology/base/20070707/",
	       'nmtb' => "http://ogf.org/schema/network/topology/base/20070707/", 
	      
	       'nmtm' => "http://ggf.org/ns/nmwg/time/2.0/",
	   };
sub new {
 my $that = shift;
  my $class = ref($that) || $that;
  my @param = @_;
  my $self =   $nss ; 
  bless $self, $class;
  my $logger =  get_logger($that);
  my %conf = ();
  if(@param) {
     if ($param[0] eq '-NS') { 
       %conf = %{$param[1]} 
     } else {
       %conf = @param;
     }
     $logger->debug(" params: " . ( join " : " , @param) );
     foreach my $cf ( keys %conf ) {
        (my $stripped_cf = $cf) =~ s/\-//;
       if(exists $self->{$stripped_cf}) {
           $self->{$stripped_cf} = $conf{$cf};
        }  else {
            $logger->warn("Unknown option: $cf - " . $conf{$cf}) ;
        }
     }
  } 
  return $self;

}

=head2 getNsByKey()

Returns namespace string by id of the namespace, where kyes are:
'nmwg', 'nmwgr  
'nmwgt' ( aliased as 'topo' too),'nmwgtopo3' 
'nmtl3','nmtl4', 'nmtm' 
'select', 'average'
'traceroute','snmp', 'ping', 'owamp', 'netutil', 'bwctl','pinger', 'iperf

 Might be utized as Class method:
   my $URI =   Namespace::getNsByKey($key);  

=cut
 

sub getNsByKey {
   my $self = shift;
   my $key = shift;
   my $logger =  get_logger($that);
   if(ref($self)) {
     if ( ! defined $self->{$key} ) {
   	$logger->error( "Key '$key' not found");
   	return undef;
      }
      return $self->{$key};
   } else {
      if ( ! defined $nss->{$self} ) {
   	$logger->error( "Key '$self' not found");
   	return undef;
      }
     return $nss->{$self};
   } 
   
  
}

=head2 setNsByKey('pinger' =>  'http://newpinger/namespace/' ) 

Sets namespace URI string by id of the namespace or defnies the new one
 
=cut

sub setNsByKey {
   my $self = shift;
   my ($key , $val) = @_;
   return  $self->{$key}=$val;
}

}

1;



__END__

 

=head1 SEE ALSO
 
To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 AUTHOR

Maxim Grigoriev, E<lt>maxim@fnal.govE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
