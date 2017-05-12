# this is the modules that implements the swished daemon
 
package SWISHED::Core;
use strict;
use warnings;

use SWISHED;		# for $SWISHED::VERSION
use SWISH::API;
use URI::Escape;	# for uri_escape() and uri_unescape()
use CGI;			# for param()

use vars qw( %swish_apis );	# persistent hash of indexnames -> SWISHE::APIs

sub close_indices { %swish_apis = (); }

############################################
# dosearch()
#  reads params from CGI::param(), then
#  print()'s output which is expected to go through a web server to
#  a client like SWISH::API::Remote
sub do_search {
	# our protocol is based on the swish-e command line exe.
	# we expect a query string with the following
	# f=indexname (looks for env var SWISHED_INDEX_INDEXNAME)
	#   (indexname must match /^[a-z_]+\w*$/ and will be uppercased and have
	#    'SWISHED_INDEX_' prepended. Default is to use SWISHED_INDEX_DEFAULT,
	#    as if 'default' was passed.)
	# w=search (or absent if no search desired)
	# m=1 (or absent if no metadata desired)
	# p=prop,prop2,prop3 
	# m=max 
	# b=begin
	# s=sort string 
	
	# default swish properties include:
	#	swishdocpath swishrank swishdocsize swishtitle swishdbfile 
	#	swishlastmodified swishreccount swishfilenum 

	# these read from $r->args under modperl

	my $w = CGI::param("w") || "";	# word to search for
	my $h = CGI::param("h") || "";	# do they want Header data returned?
	my $M = CGI::param("M") || "";  # get metanames?
	my $P = CGI::param("P") || "";  # get properties?
	my $b = CGI::param("b") || 0;	# begin results at rec num
	my $m = CGI::param("m") || 10;	# max results
	my $p = CGI::param("p") || "swishdocpath,swishrank,swishtitle";
	my @props = split(/,/, $p);     # note that we do NO error checking here.
	my $d = CGI::param("d") || "";	# debug level. not used yet, but documented in PROTOCOL
	my $s = CGI::param("s") || "";  # sort spec
	my $f = CGI::param("f") || "DEFAULT"; 	# the default index is called DEFAULT. 

	# while (my ($k, $v) = each %ENV) { print ("d: ENV{$k} = $ENV{$k}\n"); } # test

	print("e: swished.modperl: not a valid indexname: $f\n") && return 
		unless $f =~ /^[a-zA-Z]+\w*$/i;	# must begin with a letter
	print("e: swished.modperl: no env var found by name: SWISHED_INDEX_$f\n") && return 
		unless exists($ENV{ "SWISHED_INDEX_$f" });

	my $index = $ENV{ "SWISHED_INDEX_$f" };	# the actual full path to the index. 
		# $f is the 'name', like 'DEFAULT'

    # create the SWISH::API object if there isn't one. TODO: Factor this out.
	unless( exists $swish_apis{$f} ) {  
		$swish_apis{$f} = SWISH::API->new ( $index );
		print("d: pid $$ opened index $index for search '$w'\n");
	}

	my $swish = $swish_apis{$f}; 
	my $search = $swish->New_Search_Object();
	#print "Searching for $w in $index\n";

	print("e: " . $swish->ErrorString() . "\n") if $swish->Error(); 
	print("k: " . join("&", map { "$_=$props[$_]" } (0 .. $#props)) . "\n" ); 	
    # output the k: line with the props they asked for and their indexes, 
    # like k: 0=swishdocpath,1=swishrank,2=swishtitle
	
	eval {
        # they want some kind of descriptive header of meta-data, get it first.
		if ($h) {	
			my %headers = _get_headers( $swish );
			my @parts = map { uri_escape($_) . "=" . uri_escape($headers{$_}) } keys (%headers);
			print "h: " .  join("&", @parts) . "\n";
		}
		if ($M) {
			my %metas = _get_metanames( $swish );	# hash of ID->"Name,Type"
			my @parts = map { uri_escape($_) . "=" . uri_escape($metas{$_}) } keys (%metas);
			print "M: " .  join("&", @parts) . "\n";
		}
		if ($P) {
			my %props = _get_properties( $swish );
			my @parts = map { uri_escape($_) . "=" . uri_escape($props{$_}) } keys (%props);
			print "P: " .  join("&", @parts) . "\n";
		}
	};
	if ($@) { print("e: $@\n"); };	# show our error fetching the descriptive data.

	if ($w ne '') { # we have a search term. Do the search.
		my $results;
		eval { 
			$search->SetSort( $s ) if $s;
			$results = $search->Execute( $w );
			$results->SeekResult( $b ) if $b;
		};
		if ($@) { print("e: $@\n"); };
		my $cnt = 0;
		eval {
			print("m: hits=" . $results->Hits() . "&swished_version=$SWISHED::VERSION\n");

			no warnings;	# skip complaints about undefs from $result->ResultPropertyString()
                
            # loop over results and create r: lines
			while ( ($cnt++ < $m) && (my $result = $results->NextResult() ) ) { 
				print( "r: " .  join("&", 
					map { "$_=" . uri_escape($result->ResultPropertyStr( $props[$_] ) )  } 
						(0 .. $#props) 
				) . "\n" ); 
			}
		};
		if ($@) { print("e: $@\n"); };
	} 
}

#####################################################
# _get_headers( $swish )
#  based on get_header_info() suggested by pek
# returns refs to hash of  headers, and lists of metas and properties
sub _get_headers {
    my ($swish) = @_;
	my %headers; 	# hash to return
	my $index_name = ( $swish->IndexNames )[ 0 ]; 	# assume the first file is representative 

    # for each header name
	for my $n ($swish->HeaderNames) {
        # get the value and store it
		my $val = $swish->HeaderValue($index_name, $n);
		$val = '' unless defined $val;
		$headers{$n} = $val;
	}
	return %headers;
}

############################################
# _get_properties( $swish )
# returns hash of IDs=>"Name,Type"
sub _get_properties {
    my ($swish) = @_;
	my $index_name = ( $swish->IndexNames )[ 0 ]; 	# assume the first file is representative 
	my @props = $swish->PropertyList( $index_name );
	return _create_metaprop_hash( \@props );
}

############################################
# _get_metanames( $swish )
# returns hash of IDs=>"Name,Type"
sub _get_metanames {
    my ($swish) = @_;
	my $index_name = ( $swish->IndexNames )[ 0 ]; 	# assume the first file is representative 
	my @metas = $swish->MetaList( $index_name ); 
	return _create_metaprop_hash( \@metas );
}

############################################
# _create_metaprop_hash( $ref_to_list_of_hashes)
#  converts values like from   $swish->MetaList()  or  $swish->PropertiesList()
#  into a convenient hash for SWISHED::Core
# returns hash of IDs=>"Name,Type" 
sub _create_metaprop_hash {
	my $listref = shift;
	my %ret;
	for my $meta (@$listref) {	
		$ret{$meta->ID} = $meta->Name . "," . $meta->Type;
	}
	return %ret;
}
1;


=head1 NAME

SWISHED::Core - perl module to provide a persistent swish-e daemon

=head1 SYNOPSIS

Put lines like the following in your httpd.conf file to use SWISHED as a 
mod_perl 2.0 handler. See the docs for examples on how to use swished
as a CGI or Apache::Registry handler:

	PerlRequire /usr/local/swished/lib/startup.pl
	PerlPassEnv SWISHED_INDEX_DEFAULT 
	<Location /swished>
		PerlResponseHandler SWISHED::Handler
		PerlSetEnv SWISHED_INDEX_DEFAULT /var/lib/sman/sman.index
		# specify your default index here, above is from 
        #   sman-update at http://search.cpan.org/~joshr/Sman/
		SetHandler perl-script
	</Location> 

=head1 DESCRIPTION 

Swished is the core module providing a persistent swish-e daemon. See SWISHED::swished
and SWISHED::Handler for examples.

=head1 AUTHOR

Josh Rabinowitz

=head1 SEE ALSO

L<SWISH::API>, L<SWISH::API::Remote>, L<SWISHED::Handler>, L<SWISHED::swished>, L<swish-e>

=cut

__END__

# $Log: Core.pm,v $
# Revision 1.10  2006/07/06 18:00:52  joshr
# bump to version 0.10, comment and documentation changes
#
# Revision 1.9  2006/06/17 17:11:10  joshr
# MANY changes to add headers, INDEXMETANAMES and INDEXPROPERTIES output;
# rewrote pek's code.
#
# Revision 1.8  2006/06/04 16:59:52  joshr
# removed code in prep of pek rewrite
#
#
