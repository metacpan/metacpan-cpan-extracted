###################################################
## YahooRESTGeocode.pm
## Andrew N. Hicox		<andrew@hicox.com>
## Hicox Information Systems Development
##
## a built in XML::Parser style for parsing 
## the xml returned from Yahoo REST webservices
###################################################


## Global Stuff ###################################
package XML::Parser::YahooRESTGeocode;
use 5.6.0;
use Carp;

$VERSION = 0.2;

#register with XML::Parser as built in style
$XML::Parser::Built_In_Styles{YahooRESTGeocode} = 1;

#host data fields
my %node_tree = (
	'Result'	=> ['Latitude','Longitude','Address','City','State','Zip','Country']
);




## Init ###########################################
sub Init {
	my $expat = shift;
    $expat->{'Lists'}	= {};
    $expat->{'Curlist'} = [];			#everything @OPEN used to be
    $expat->{'errstr'}  = ();			#clear out the error string
    $expat->{'errmsg'}	= ();			#clear out the advisory errorrs
	
	#if there's any arguments corresponding to nodes in 'node_tree',
	#evacuate them to '_CDB2IMP_callbacks', they must be code refs
	#we'll execute 'em when one of those nodes ends
	foreach (keys %node_tree){
		if ((exists($expat->{$_})) && (ref ($expat->{$_}) eq "CODE")){
			$expat->{'_YahooREST_callbacks'}->{$_} = $expat->{$_};
			delete($expat->{$_});
		}
	}
    
}




## Start ##########################################
sub Start {
	my ($expat, $element, %p) = @_;
    push (@{$expat->{'Curlist'}}, {
        '_name'			=> $element,
        '_attributes'	=> \%p
    });
}




## Char ###########################################
sub Char {
    my ($expat, $data) = @_;
    unless ($data =~/^\s+$/){
        $expat->{'Curlist'}->[$#{$expat->{'Curlist'}}]->{'_data'} .= $data;
    }
}




## Final ##########################################
sub Final {
	my $expat = shift;
	#handle error
	if ($expat->{'errstr'}){ $XML::Parser::errstr = $expat->{'errstr'}; return (undef); }
	#handle advisory messages
	if ($expat->{'errmsg'}){ $XML::Parser::errmsg = $expat->{'errmsg'}; }
	#clean up
	delete $expat->{Curlist};
	my $out = $expat->{Lists}->{'DATA'};
	delete $expat->{Lists};
	return ($out);
}


## gather_data ####################################
sub gather_data {
    my ($expat, $name) = @_;
    my (@data) = ();
    while ($expat->{'Curlist'}->[$#{$expat->{'Curlist'}}]->{'_name'} ne $name){
        push (@data, pop(@{$expat->{'Curlist'}}));
    };
   #one more to catch the start tag
    push (@data, pop(@{$expat->{'Curlist'}}));
    reverse (@data);
    return (\@data);
}


## extract_pcdata #################################
sub extract_pcdata {
    my $data = shift();
    my %out = ();
    foreach (@{$data}){
        foreach my $f (@_){
            if (($_->{'_name'} eq $f) && ($_->{'_data'} !~/^$/)){
                $out{$f} = $_->{'_data'};
            }
        }
    }
    return (\%out);
}


## End ############################################
sub End { 
	my ($expat, $element) = @_;
	
	if (exists($node_tree{$element})){
	
		my $data = extract_pcdata(gather_data($expat, $element), @{$node_tree{$element}});
		push (@{$expat->{'Lists'}->{'DATA'}->{$element}}, $data);
		
		#if the user defined some callback to execute, do that
		if (exists($expat->{'_YahooREST_callbacks'}->{$element})){
			&{$expat->{'_YahooREST_callbacks'}->{$element}}($data);
		}
	
	}
}

## True ###########################################
1;