package perfSONAR_PS::Datatypes::Namespace;
use strict;
use warnings;

=head1 NAME

Namespace -  a container for namespaces 

=head1 DESCRIPTION

The purpose of this module is to  create OO interface to namespace registration and therefore
add the layer of abstraction for any namespace related operation. All  perfSONAR-PS classes should
work with the instance of this class and avoid using explicit namespace declaration. 

=head1 SYNOPSIS
 
    use perfSONAR_PS::Datatypes::Namespace; 
    # create Namespace object with default URIs
    $ns = perfSONAR_PS::Datatypes::Namespace->new();
    
    # overwrite  Namespace object with  custom URIs
    $nss =  {'pinger' => 'http://newpinger/namespace/'};
    $ns = perfSONAR_PS::Datatypes::Namespace->new(-hash => $nss);
    
    # overwrite only specific Namespace   with  custom URI 
    
    $ns = perfSONAR_PS::Datatypes::Namespace->new(-pinger =>   'http://newpinger/namespace/');
      
    $pinger_uri = $ns->getNsByKey('pinger'); ## get URI by key
    $ns->setNsByKey('pinger' =>  'http://newpinger/namespace/'); ## set URI by key
    
 
=head1 API

There are many get/set methods

=head2 new(-NS => \%nss)

Creates a new object, pass hash ref as collection of namespaces 
  or new(-pinger => http://ggf.org/ns/nmwg/tools/pinger/2.0/",   'nmwgr' => "http://ggf.org/ns/nmwg/result/2.0/")

=cut

use version; our $VERSION = 0.09; 
use Readonly;
use Log::Log4perl qw(get_logger);
Readonly::Scalar our $CLASSPATH =>  'perfSONAR_PS::Datatypes::Namespace';
Readonly::Hash our %NSS => ( 
               'xsd'=>"http://www.w3.org/2001/XMLSchema",
               'xsi' => "http://www.w3.org/2001/XMLSchema-instance",
               'SOAP-ENV' => "http://schemas.xmlsoap.org/soap/envelope/",
               'nmwg' => "http://ggf.org/ns/nmwg/base/2.0/",
               'nmwgr' => "http://ggf.org/ns/nmwg/result/2.0/" ,
	       'select'  => "http://ggf.org/ns/nmwg/ops/select/2.0/",
	       'cdf'  => "http://ggf.org/ns/nmwg/ops/cdf/2.0/",
	       'average'  => "http://ggf.org/ns/nmwg/ops/average/2.0/",
	       'histogram'  => "http://ggf.org/ns/nmwg/ops/histogram/2.0/",
	       'median'  => "http://ggf.org/ns/nmwg/ops/median/2.0/",
	       'max'  => "http://ggf.org/ns/nmwg/ops/max/2.0/",
	      
	       'min'  => "http://ggf.org/ns/nmwg/ops/min/2.0/",
	       'mean'  => "http://ggf.org/ns/nmwg/ops/mean/2.0/",
	      
	       'pingertopo' =>   "http://ogf.org/ns/nmwg/tools/pinger/landmarks/1.0/",
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
	     
	       'nmtl4' => "http://ogf.org/schema/network/topology/l4/20070707",
	       'nmtl3' => "http://ogf.org/schema/network/topology/l3/20070707",
               
               'nmtl2' => "http://ogf.org/schema/network/topology/l2/20070707/",
               'nmtopo' => "http://ogf.org/schema/network/topology/base/20070707/",
	       'nmtb' => "http://ogf.org/schema/network/topology/base/20070707/", 
	      
	       'nmtm' => "http://ggf.org/ns/nmwg/time/2.0/",
	   ); 

sub new {
    my ($that,@param) = @_;
    my $class = ref($that) || $that;
  
    my $self = \%NSS;
    bless $self, $class;
    my $logger =  get_logger($CLASSPATH);
    my %conf = ();
    if(@param) {
        if ($param[0] eq '-NS') { 
            %conf = %{$param[1]} 
        } else {
            %conf = @param;
        }
        $logger->debug(" params: " . ( join " : " , @param) );
        foreach my $cf ( keys %conf ) {
            (my $stripped_cf = $cf) =~ s/\-//xm;
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

 Might be utilized as Class method:
   my $URI =   'perfSONAR_PS::Datatypes::Namespace::getNsByKey($key);  

=cut
 

sub getNsByKey {
   my $self = shift;
   
   my $logger =  get_logger($CLASSPATH);
   if(ref($self)) { 
       my $key = shift;
       if ($key) {
           unless(defined $self->{$key}) {
   	       $logger->error( "Key '$key' not found");
   	       return;
	   }
	   return $self->{$key};
       } else {
           return $self;
       }  
   } elsif($self) {
       unless(defined $NSS{$self}) {
   	   $logger->error( "Key '$self' not found");
   	   return;
       }
       return $NSS{$self};
   } else {
       return $self;
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
