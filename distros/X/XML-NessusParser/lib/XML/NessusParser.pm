package XML::NessusParser;

use strict;
use warnings;

use XML::NessusParser::Host; 
#use XML::NessusParser::Preferences
#use XML::NessusParser::Report

use Exporter qw(import);

our $VERSION = "0.01";  
our @EXPORT_OK = qw(new parse livehosts RecursiveXMLtags);


sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->initialize(@_);
    $self;
}

sub initialize {
    my $self = shift;
    $self->{stem} = shift;
    $self->{english} = shift;
}
  
 
sub parse { 
	my ($self,$filename) = @_;
	
	$self->{parsed} = {};
	 
	my $parser = XML::LibXML->new();
	my $nessusXML = $parser->parse_file($filename);

	
	foreach ( $nessusXML->findnodes('/NessusClientData_v2/Policy/Preferences/ServerPreferences/preference') ) {
		my @array = split('\n', $_->to_literal());
		if ($#array eq 1 ) { 
			$self->{preferences}{server}{$array[0]} = $array[1];  
		}
	}
	
	my @PluginPrefernces; 
	foreach ( $nessusXML->findnodes('/NessusClientData_v2/Policy/Preferences/PluginsPreferences/item') ) {
		my %hash;  
		if ($_->findnodes('pluginName')->string_value()) { $hash{pluginName} = $_->findnodes('pluginName')->string_value(); }
		if ($_->findnodes('pluginId')->string_value()) { $hash{pluginId} = $_->findnodes('pluginId')->string_value(); }
		if ($_->findnodes('fullName')->string_value()) { $hash{fullName} = $_->findnodes('fullName')->string_value(); }
		if ($_->findnodes('preferenceName')->string_value()) { $hash{preferenceName} = $_->findnodes('preferenceName')->string_value(); }
		if ($_->findnodes('preferenceType')->string_value()) { $hash{preferenceType} = $_->findnodes('preferenceType')->string_value(); }
		if ($_->findnodes('preferenceValues')->string_value()) { $hash{preferenceValues} = $_->findnodes('preferenceValues')->string_value(); }
		if ($_->findnodes('selectedValue')->string_value()) { $hash{selectedValue} = $_->findnodes('selectedValue')->string_value(); }
		push(@PluginPrefernces, { %hash });
	}
	
	$self->{preferences}{plugins} = [ @PluginPrefernces ];
	
	my @Hosts; 
	foreach ($nessusXML->findnodes('/NessusClientData_v2/Report/ReportHost') ) {
		my %HostHash;
		for my $HostProperties (  @{$_->findnodes('HostProperties')} ) {
			my %hash; 
			for my $tag ( $HostProperties->findnodes('tag') ) {
				$HostHash{HostProperties}{$tag->getAttribute('name')} = $tag->string_value();
			} 			
		}
		my @ReportItems; 
		for my $ReportItem ( $_->findnodes('ReportItem') ) {
			my %item;  
			if ( $ReportItem->hasAttributes() ) {
				for my $attribute ( $ReportItem->attributes() ) { $item{$attribute->name} = $attribute->getValue; } 
			}
			for my $child ( $ReportItem->nonBlankChildNodes() ) { $item{$child->nodeName} = $child->string_value(); }
			push(@ReportItems, { %item } );
		}
		$HostHash{ReportItems} = [ @ReportItems ] ;	
		push(@Hosts, { %HostHash });	
	}
	$self->{hosts} = [ @Hosts ]; 
}

sub plugin_set { 
	my ($self) = @_;  
	return split(/;/, $self->{preferences}{server}{plugin_set});  	
	
}
sub target { 
	my ($self) = @_;
	return $self->{preferences}{server}{TARGET}; 
}
	
sub server_preference { 
	my ($self,$preference) = @_;
	return $self->{preferences}{server}{$preference}; 
}

sub plugin_preference { 
	my ($self,$preference) = @_;
	return $self->{preferences}{plugins}; 
}

sub sc_version { 
	my ($self,$preference) = @_;
	return $self->{preferences}{plugins}; 
}

sub nessus_version {
	my ($self) = @_;
	my $version; 
	foreach ( @{$self->{hosts}}) {
		for my $item ( @{$_->{ReportItems}} ) {
			if ($item->{pluginID} eq "19506" ) {
				for my $line ( split('\n',$item->{plugin_output}) ) {
					 
					chomp($line);
					if ($line =~ /^Nessus version/ ) { 
						(undef,$version) = split(/:/,$line);
						$version =~ s/^\s+//;$version =~ s/\s+$//;
						last; 
					}
				}
			} 
		} 
	} 
	return $version; 
}

sub host_count { 
	my ($self) = @_;
	my $hostCount = ( $#{$self->{hosts}} +1 ); 
	return $hostCount;  
}

sub get_ips { 
	my ($self) = @_;
	my @IPs;
 
	foreach ( @{$self->{hosts}}) {
		for my $item ( @{$_->{ReportItems}} ) {
			if (defined($_->{HostProperties}{'host-ip'}) ) { push(@IPs,$_->{HostProperties}{'host-ip'});}
		} 
	} 
	return @IPs; 
}

sub get_host {
	 
	my ($self,$hostIP) = @_;
	my $host;
	foreach ( @{$self->{hosts}}) {
		for my $item ( @{$_->{ReportItems}} ) {
			if (defined($_->{HostProperties}{'host-ip'}) ) {
				$host = $_ if ( $_->{HostProperties}{'host-ip'} eq $hostIP )
			}
		} 
	} 
	my $HOST = NessusParser::Host->new($host);
	
	return $HOST; 
		
}

sub get_policyName { 
	
}

sub get_reportName { 
	
}


=head1 NAME

XML::NessusParser - The great new XML::NessusParser!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use XML::NessusParser;

    my $foo = XML::NessusParser->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 parse($xml_file)

Parses the Nessus XML scan data in $xml_file. This file is version 2 export/downlaoded Nessus results
obtained either from a nessus scanner directly or via Security Center. If you get an error or your 
program dies due to parsing, please check that the xml information is compliant. 


=head2 plugin_set()

Returns an array of pluginIDs used for the parsed scan. 
 
=head2 all_server_preferences()

returns an ARRAY containing a HASH values for all server preferences assoaciated with the scan results 

=head2 server_preference($preference_name)

returne the prefeence setting associated with the preference arguement. 

=head2 all_plugin_preferences()

returns an ARRAY containing a HASH values for all plugin preferences assoaciated with the scan results 
 
=head2 plugin_preference($preferance_name)

method to return a HASH value containing the prefeernces associated with the 

=head2 target()

shortcut method to return the target string of hosts scanned. 
 
=head2 sc_version()

shortcut method to return the Security Center version (if available) in the XML results

=head2 nessus_version()

short cut method to return the nessus version used to scan as captured in the results of a pluginID 19506 output. 

=head2 host_count()

returns number of live IPs in XML results  
 
=head2 get_ips() 

returns an array of IP addresses scanned that have results in the 

=head2 get_host($ip_address)

returns a XML::NessusParser::Host object for the IP address passed as an arguement


=head2 get_policyName()

 
=head2 get_reportName()


=cut

=head1 AUTHOR

littleurl, C<< <pjohnson21211@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-nessusparser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-NessusParser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::NessusParser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-NessusParser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-NessusParser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-NessusParser>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-NessusParser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 P Johnson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of XML::NessusParser
