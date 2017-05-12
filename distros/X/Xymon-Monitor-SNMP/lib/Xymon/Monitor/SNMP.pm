package Xymon::Monitor::SNMP;
use Net::SNMP;
use Config::General;
use Switch;
use Xymon::Client;
use strict;


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.04';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}



sub new
{
    my ($class, $parm) = @_;

    my $self = bless ({}, ref ($class) || $class);
	
	$parm->{version} = $parm->{version} || "2c";
	
	($self->{session}, my $error) = Net::SNMP->session(
                           -hostname      => $parm->{hostname},
                           -version       => $parm->{version},
                           -community     => $parm->{community},   # v1/v2c
                        );
	
	
	$self->{parm} = $parm;
	$self->{hostname} = $parm->{hostname};
	
	#
	# Read in config file of elements and oids
	#
	my $conf = new Config::General(
		-ConfigFile => $parm->{oidconfig},
		-MergeDuplicateBlocks => 1,
		-ForceArray => 1
	);

	my %config = $conf->getall;
	$self->{elements} = \%config;
	
	
    return $self;
}

sub getValues {
	
	my $self = shift;
	my $rethash = {};
	
	foreach my $variable ( sort keys %{$self->{elements}} ) {
		
		foreach my $oid ( @{$self->{elements}->{$variable}->{OIDS}}) {
			my $result = $self->{session}->get_request(-varbindlist => [$oid]);
	
			if (!defined $result) {
		      	printf "ERROR: %s.\n", $self->{session}->error();
	    	  	$self->{session}->close();
				exit 1;
	   		}

	        push @{$rethash->{$variable}}, $result->{$oid};

		}
		
	};
	
	return $rethash;
		
}
sub run {

	
	my $self = shift;
	
	my $result = getValues($self);
	my $elements = $self->{elements};
	my $xymon = Xymon::Client->new({home=>"/home/hobbit/client/"});
	my $color = "green";
	
	foreach my $element ( keys %$result) {
		my $count = 0;
		my $elementstring = "";
		foreach my $value ( @{$result->{$element}}) {
	
			$count = $count + 1;
	
			my $elementname = $element;
			if(scalar @{$result->{$element}} > 1 ) {
				$elementname = $element . $count;
				$elementstring .= $elementname . ":" . $value ."\n";
			} else {
				$elementstring = $elementname . ":" . $value . "\n";
			}
			
			# Check Against Threshold.
			# If already red then skip.
			if( $color ne "red" ) {
				if(compare($value,$elements->{$element}->{THRESH},$elements->{$element}->{THRESHDIR})) {
					$color="red";							
				} else {
					$color = "green";
				}
			}
	
		}
		
		
		# Send To Xymon
		
		$xymon->send_status({
        	server => $self->{hostname},
        	testname => $element,
        	color => $color,
        	msg => "\n\n" . $elementstring
        
  		})
	}
	
		
  
  
}




sub compare {
	
	my ( $left, $right, $operator ) = @_;
	
	if($operator eq "<") {
		return $left < $right;
	}
	
	if($operator eq ">") {
		return $left > $right;
	}
	
	if($operator eq "=" || $operator eq "==") {
		return $left == $right;
	}
	
	if($operator eq "<>" || $operator eq "!=") {
		return $left != $right;
	}
	
	return -1;
	
}

sub close {
	
	my $self = shift;
	$self->{session}->close();
	$self = "";
	
}





#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Xymon::SNMP - Xymon Interface to SNMP

=head1 SYNOPSIS

  use Xymon::SNMP;
  
  my $snmp = Xymon::Monitor::SNMP->new({
	 	hostname=>"$host",
	 	version=>"2c",
	 	community=>"public",
	 	oidconfig=>"liebert.conf"
	 	}
  );

  $snmp->run();
  $snmp->close();


=head1 DESCRIPTION

Provides an interface for monitoring snmp based devices using
a configuration file to determin which oids to retrieve,
their thresholds and what tests they are mapped to. 

=head1 USAGE

An example configuration file:

	#
	# Output Current
	#
	<current>
		OIDS = 1.3.6.1.2.1.33.1.4.4.1.3.1
	 	OIDS = 1.3.6.1.2.1.33.1.4.4.1.3.2
	 	OIDS = 1.3.6.1.2.1.33.1.4.4.1.3.3
		
	 	THRESH = 350
	 	THRESHDIR = >
	</current>
	
	#
	# Percentage of maximum output current
	#
	<percentload>
		OIDS = 1.3.6.1.2.1.33.1.4.4.1.5.1
		OIDS = 1.3.6.1.2.1.33.1.4.4.1.5.2
		OIDS = 1.3.6.1.2.1.33.1.4.4.1.5.3
		
		THRESH = 90
		THRESHDIR = >
	</percentload>


The config file is loaded when the snmp object is created:

my $snmp = Xymon::Monitor::SNMP->new({
	 	hostname=>"router1",
	 	version=>"2c",
	 	community=>"public",
	 	oidconfig=>"router.conf"
	 	}
  );



This configuration file is used to map the OIDS listed and retrieve the
data as below where the first field is the host name, the second is
the testname, the third is the field within the test, the fourth is
the return value from snmp, the fifth is the comparison operator and
the sixth field is the threshold:

	router1:percentload:percentload1:44:>:90
	router1:percentload:percentload2:41:>:90
	router1:percentload:percentload3:31:>:90
	router1:batterystatus:batterystatus:2:<>:2
	router1:battcharge:battcharge:100:<:100
	router1:batteryminutes:batteryminutes:29:<:15,
	router1:current:current1:152:>:350
	router1:current:current2:153:>:350
	router1:current:current3:113:>:350

These are used to generate the message to send to Xymon. The first for eaxmple 
would be equivalent to:

	bb 127.0.0.1 "status router1.percentload green 
	
	percentload1:44
	percentload2:41
	percentload3:31"

The above is an explanation of what happens behind the scenes, however the actual
generation and sending of the message to Xymon is all taken care of when you perform
the run method.


=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

