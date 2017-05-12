package WebService::Mappoint;
use SOAP::Lite;
use FileHandle;
use fields qw(ini_file remote_object CustomerInfoHeader UserInfoHeader);
use vars qw(%FIELDS);
use vars qw($VERSION);
$VERSION=0.30;

# @drawmap_EU might be incomplete. It might also contain values that should not be here. Please let me know if there is something wrong
my @EU = (qw(
ad al am at az by ba be bg hr ch cy cz de dk ee es fo fr fi gb ge gi gr hu is ie it lv lt lu mt nl no pl pt ro sk si se tr ua uk yu
));
my %EU;
my %NA = (us=>1, ca=>1, mx=>1);
	
use strict;

my $ini_files = {};
my ( $user, $password );

my $default_ini_path;

BEGIN {
    
   $default_ini_path = $^O =~ m/windows/i ? 'c:\mappoint.ini' : '/etc/mappoint.ini';
}

##############################################################################
sub new {
	my ( $class, $proxy_url, $inifile_path ) = @_;

	no strict 'refs';
	my $self = bless [\%{"${class}::FIELDS"}], $class;

	$self->{ini_file} = $inifile_path;

	if ( $ini_files->{$self->{ini_file}}{debug}{proxy} ) {
		$proxy_url = $ini_files->{$self->{ini_file}}{debug}{proxy}
	}
	die "There is no proxy defined\n" if (!$proxy_url);

	$self->{remote_object} = SOAP::Lite
		->on_action( sub{ $ini_files->{$self->{ini_file}}{xmlns} . $_[1]; })
		->proxy($proxy_url)
		->envprefix('soap')
		->on_fault(
			sub {
				my($soap, $res) = @_;
				die ref $res ? $res->faultdetail : $soap->transport->status, "\n";
			}
		)
		;
#	when autotype is switched of, also character escaping is switched off :-/
#	we added encoding in the handle_*_parameter methods.
	$self->{remote_object}->serializer()->autotype(0);

	if ( $ini_files->{$self->{ini_file}}{debug}{readable} ) {

		$self->{remote_object}->serializer()->readable(1);
	}

	return $self;
}

##############################################################################
# Set header info
sub set_CustomLogEntry { $_[0]->{CustomerInfoHeader}{CustomLogEntry} = $_[1]; }
sub set_CultureName { $_[0]->{UserInfoHeader}{Culture}{Name} = $_[1]; }
sub set_CultureLCID { $_[0]->{UserInfoHeader}{Culture}{LCID} = $_[1]; }
sub set_DefaultDistanceUnit { $_[0]->{UserInfoHeader}{DefaultDistanceUnit} = $_[1]; }
sub set_ContectGeoID { $_[0]->{UserInfoHeader}{Context}{GeoID} = $_[1]; }
sub set_ContectGeoISO2 { $_[0]->{UserInfoHeader}{Context}{GeoISO2} = $_[1]; }
##############################################################################
sub method {
	my ($self, $name, %args) = @_;

	# we need to set the credentials to be used in this call
	# so that SOAP::Transport::HTTP::Client::get_basic_credentials
	# returns the ones corresponding to the ini-file of this 
	# object --How else could we achieve this that is less convoluted?
	$user = $ini_files->{$self->{ini_file}}{user};
	$password = $ini_files->{$self->{ini_file}}{password};

	return $self->{remote_object}
		->call(
			SOAP::Data->name($name)
			->attr({ xmlns => $ini_files->{$self->{ini_file}}{xmlns} }) 
				=> (@{handle_parameters(%args)}, @{$self->header()})
		      );
}
##############################################################################
sub header {
	my ($self) = @_;

	# handle data from ini-file
	if ($ini_files->{$self->{ini_file}}{culture}) {
		$self->{UserInfoHeader} ||= {};
		$self->{UserInfoHeader}{Culture} ||= {};
		map( $self->{UserInfoHeader}{Culture}{$_} ||= $ini_files->{$self->{ini_file}}{culture}->{$_}, keys %{$ini_files->{$self->{ini_file}}{culture}} );
	}

	if ($ini_files->{$self->{ini_file}}{userinfoheader} ) {
		$self->{UserInfoHeader} ||= {};
		map($self->{UserInfoHeader}{$_} ||= $ini_files->{$self->{ini_file}}{userinfoheader}->{$_}, keys %{$ini_files->{$self->{ini_file}}{userinfoheader}});
	}

	my @header = ();;
	if ($self->{CustomerInfoHeader}) {
		push(@header, 
			SOAP::Header->name('CustomerInfoHeader' => \SOAP::Header->value(
				@{handle_header_parameters(%{$self->{CustomerInfoHeader}})}
			))->attr({xmlns => $ini_files->{$self->{ini_file}}{xmlns}})
		);
	}
	if ($self->{UserInfoHeader}) {
		my @param;
		push(@header, 
			SOAP::Header->name('UserInfoHeader' => \SOAP::Header->value(
				@{handle_header_parameters(%{$self->{UserInfoHeader}})}
			))->attr({xmlns => $ini_files->{$self->{ini_file}}{xmlns}})
		);
	}

	return \@header;
}
##############################################################################
sub parse_ini_file {
    my $fname = shift;

    # don't do anything if file has already been parsed
    if ( exists $ini_files->{$fname}{user} ) { return }
    
    my $fh = new FileHandle($fname, 'r');
    die "No ini-file ($fname) found\n" if (!$fh);
    
    my (%sec, $sec);
    while(my $line = <$fh>) {
	$line = strip($line);
	next if (substr($line, 0, 1) eq ';');
	if ($line =~ m/^\[/ && $line =~ m/\]$/) {
	    $sec = lc(strip(substr($line,1,length($line)-2)));
	}
	elsif ($line =~ m/=/) {
	    die "put [section]-line in the ini-file\n" if (!$sec);
	    my ($param,$value) = ($line =~ m/(\S+)\s*=\s*(\S*)$/);
	    $sec{$sec} ||= {};
	    $sec{$sec}{$param} = $value;
	}
	else {
	    die "Weird line in mappoint.ini: $line\n" if ($line !~ m/^\s*$/);
	}
    }
    die "No credentials section in ini-file\n" if (!$sec{credentials});
    $ini_files->{$fname}{xmlns} = $sec{general}{xmlns}
    || die "put a 'xmlns=...' in the general section in the ini-file\n";
    $ini_files->{$fname}{user} = $sec{credentials}{user} 
    || die "put 'user=...' in credentials section in ini-file\n";
    $ini_files->{$fname}{password} = $sec{credentials}{password} 
    || die "put 'password=...' in credentials section in ini-file\n";
    $ini_files->{$fname}{proxy} = $sec{proxy};
    $ini_files->{$fname}{culture} = $sec{culture};
    $ini_files->{$fname}{debug} = $sec{debug};
    $ini_files->{$fname}{userinfoheader} = $sec{userinfoheader};
}

##############################################################################
sub strip { my $s = shift; $s =~ s/^\s+//; $s =~ s/\s+$//; return $s }
##############################################################################
sub encode { SOAP::Utils::encode_data(@_); }
##############################################################################
sub handle_header_parameters {
	my (%args) = @_;
	my @parameters;
	foreach my $k (keys %args) {
		if (ref($args{$k}) eq 'HASH') {
			push(@parameters, SOAP::Header->name($k => \SOAP::Header->value(
				@{handle_header_parameters(%{$args{$k}})}
			)));
		}
		else {
			push(@parameters, SOAP::Header->name($k => encode($args{$k})));
		}
	}
	return \@parameters;
}
##############################################################################
sub handle_parameters {
	my (%args) = @_;
	my @parameters;
	foreach my $k (keys %args) {
		if (ref($args{$k}) eq 'ARRAY') {
			my @data = @{$args{$k}};
			my @params;
			while (scalar(@data) > 0) {
				my ($key, $value) = (shift(@data), shift(@data));
				push(@params, @{handle_parameters($key => $value)});
			}

			if( $k =~ /:/ ) {
			    my( $type, $subtype ) = split( /:/, $k );
			    
			    push(@parameters, SOAP::Data->name( $type => \SOAP::Data->value(
											    @params
											   ) )->attr( { 'xsi:type' => $subtype } ) );
			    
			} else {
			    
			    push(@parameters, SOAP::Data->name($k => \SOAP::Data->value(
											@params
										       )));
			}
		}
		elsif (ref($args{$k}) eq 'HASH') {
			push(@parameters, SOAP::Data->name($k)->attr( $args{$k}));
		}
		else {
#			if ($args{$k} eq 'true' || $args{$k} eq 'false') {
#				push(@parameters, SOAP::Data->name($k => $args{$k})->type('bool'));
#			}
#			else {
				push(@parameters, SOAP::Data->name($k => encode($args{$k})));
#			}
		}
	}

#	use Data::Dumper;
#	print STDERR "PARAMETROS:\n";
#	print STDERR Dumper(\@parameters);

	return \@parameters;
}
##############################################################################
sub drawmap_for_country {
	# take last argument, so that this method can be use as function as well
	# as class/instance method
	my $country = lc(pop(@_));
	print STDERR ("country code: $country\n");
	map($EU{$_}=1, @EU) if (!exists($EU{nl}));
	return 'MapPoint.EU' if $EU{$country};
	return 'MapPoint.NA' if $NA{$country};
	return 'MapPoint.World';
}
##############################################################################
sub address_datasource {
	my $country = lc(pop(@_));
	map($EU{$_}=1, @EU) if (!exists($EU{nl}));
	return 'MapPoint.EU' if $EU{$country};
	return 'MapPoint.NA' if $NA{$country};
	return '';
}
##############################################################################
#BEGIN { parse_ini_file(); }
##############################################################################

##############################################################################
package WebService::Mappoint::Common;
use base qw(WebService::Mappoint);
##############################################################################
sub new {
    my $class = shift;
    my $inifile_path = 
      shift || $default_ini_path;
    
    WebService::Mappoint::parse_ini_file( $inifile_path );
    
    return $class->SUPER::new( $ini_files->{ $inifile_path }{proxy}{common}, $inifile_path );
}
sub GetEntityTypesProperties { return shift->method('GetEntityTypesProperties', @_); }
sub GetGeoCountryRegionInfo { return shift->method('GetGeoCountryRegionInfo', @_); }
sub GetGreatCircleDistances { return shift->method('GetGreatCircleDistances', @_); }
sub GetDataSourceInfo { return shift->method('GetDataSourceInfo', @_); }
sub GetVersionInfo { return shift->method('GetVersionInfo', @_); }

# methods new to 3.0
sub GetCountryRegionInfo { return shift->method('GetCountryRegionInfo', @_); }
sub GetEntityTypes { return shift->method('GetEntityTypes', @_); }


##############################################################################
package WebService::Mappoint::Render;
use base qw(WebService::Mappoint);
##############################################################################
sub new {
    my $class = shift;
    my $inifile_path = 
      shift || $default_ini_path;
	
    WebService::Mappoint::parse_ini_file( $inifile_path );

    return $class->SUPER::new( $ini_files->{ $inifile_path }{proxy}{render}, $inifile_path );
}
sub GetMap { return shift->method('GetMap', @_); }
sub GetBestMapView { return shift->method('GetBestMapView', @_); }
sub ConvertToPoint { return shift->method('ConvertToPoint', @_); }
sub ConvertToLatLong { return shift->method('ConvertToLatLong', @_); }

# methods exclusive to 2.0 servers
sub GetRouteMap { return shift->method('GetRouteMap', @_); }
sub GetBoundingMap { return shift->method('GetBoundingMap', @_); }


##############################################################################
package WebService::Mappoint::Find;
use base qw(WebService::Mappoint);
##############################################################################
sub new {
    my $class = shift;
    my $inifile_path = 
      shift || $default_ini_path;
	
    WebService::Mappoint::parse_ini_file( $inifile_path );

    return $class->SUPER::new( $ini_files->{ $inifile_path }{proxy}{find}, $inifile_path );
}
sub FindNearby { return shift->method('FindNearby', @_); }
sub FindAddress { return shift->method('FindAddress', @_); }
sub Find { return shift->method('Find', @_); }

# methods new in 3.0
sub GetLocationInfo { return shift->method('GetLocationInfo', @_); }
sub ParseAddress { return shift->method('ParseAddress', @_); }

##############################################################################
package WebService::Mappoint::Route;
use base qw(WebService::Mappoint);
##############################################################################
sub new {
    my $class = shift;
    my $inifile_path = 
      shift || $default_ini_path;
	
    WebService::Mappoint::parse_ini_file( $inifile_path );

    return $class->SUPER::new( $ini_files->{ $inifile_path }{proxy}{route}, $inifile_path );
}

sub CalculateRoute { return shift->method('CalculateRoute', @_); }
sub CalculateSimpleRoute { return shift->method('CalculateSimpleRoute', @_); }


##############################################################################
package WebService::Mappoint::ResultElement;
#use fields qw(name attr subitems);
#use vars qw(%FIELDS);
##############################################################################
sub new {
	my ($class, %args) = @_;
	no strict 'refs';
#	my $self = bless [\%{"${class}::FIELDS"}], $class;
	my $self = bless {}, $class;
	map($self->{$_} = $args{$_}, keys %args);
	return $self;
}
##############################################################################
sub name { return shift->{name}; }
sub attr { return shift->{attr}; }
sub subitems { return shift->{subitems} || []; }
sub get { return $_[0]->{attr}{$_[1]}; }
sub add_sub { 
	my ($self, $elm) = @_; 
	$self->{subitems} ||= [];
	push(@{$self->{subitems}}, $elm);
}
	

##############################################################################
package WebService::Mappoint::Result;
use fields qw(_content _tree);
use vars qw(%FIELDS);
##############################################################################
sub new {
	my ($class, $som) = @_;
	no strict 'refs';
	my $self = bless [\%{"${class}::FIELDS"}], $class;
	$self->{_content} = $som->{_content};
	$self->build_tree();
	return $self;
}
##############################################################################
sub show_content {
	my ($self) = @_;
	_show_content($self->{_content}, 0);
}
##############################################################################
sub _show_content {
	my ($s, $level) = @_;
	my $indent = '  ';
	if (ref($s->[0])) {
		foreach my $e (@$s) {
			_show_content($e, $level+1);
		}
	}
	elsif ($s->[0]) {
		if (ref($s->[2])) {
			print STDERR ($indent x $level, $s->[0], "\n");
			_show_content($s->[2], $level+1);
		}
		else {
			if ($s->[2]) {
				print STDERR ($indent x $level, $s->[0], ': ', $s->[2], "\n");
			}
			if (scalar(keys %{$s->[1]}) > 0) {
				print STDERR ($indent x $level, $s->[0], "\n") if (!$s->[2]);
				foreach my $k (keys %{$s->[1]}) {
					print STDERR ($indent x($level+1), $k, ': ', $s->[1]{$k}, "\n");
				}
			}
		}
	}
}
##############################################################################
sub build_tree {
	my ($self) = @_;
	$self->{_tree} = _build_tree($self->{_content});
	_clean_up_tree($self->{_tree});
}
##############################################################################
sub _build_tree {
	my ($s, $parent) = @_;
	my ($name, $attr, $value) = @$s;
	if (!ref($name)) {
		# if it's only a name-value pair, its an attribute of the parent
		if (scalar(keys %$attr) == 0 && !ref($value)) {
			$parent->{attr}{$name} = $value;
			return;
		}
		my $elm = new WebService::Mappoint::ResultElement(name => $s->[0], attr => $s->[1]);
		if (ref($value) eq 'ARRAY') {
			_build_tree($value, $elm);
		}
		if ($parent) {
			$parent->add_sub($elm);
		}
		else {
			return $elm; # root object
		}
	}
	else {
		foreach my $e (@$s) {
			_build_tree($e, $parent);
		}
	}
}
##############################################################################
sub _clean_up_tree {
	my ($elm) = @_;
	my %name;
	foreach my $sub (@{$elm->subitems}) {
		if (scalar(@{$sub->subitems}) == 0) {
			$name{$sub->name}++;
		}
	}
	my @newsubitems;
	foreach my $sub (@{$elm->subitems}) {
		if ($name{$sub->name} && $name{$sub->name} == 1) {
#			print("cleaning up ", $sub->name, "\n");
			$elm->{attr}{$sub->name} = $sub->{attr};
		}
		else {
			push(@newsubitems, $sub);
		}
	}
	$elm->{subitems} = \@newsubitems;
	foreach my $sub (@{$elm->subitems}) {
		_clean_up_tree($sub);
	}
}
##############################################################################
sub show {
	my ($self, $tree) = @_;
	$tree ||= $self->{_tree};
	_show($tree, 0);
}
##############################################################################
sub _show {
	my ($elm, $level) = @_;
	my $indent='   ';
	print STDERR ($indent x $level, $elm->name, "\n");
	foreach my $k (sort keys %{$elm->attr}) {
		my $value = $elm->{attr}{$k};
		if (ref($value)) {
			$value = join(', ', map($_ . ': ' . $value->{$_}, keys %$value));
			$value = "($value)";
		}
		print STDERR ($indent x ($level+1), $k, ': ', $value, "\n");
	}
	foreach my $sub (@{$elm->subitems}) {
		_show($sub, $level+1);
	}
}
##############################################################################
sub get_first {
	my ($self, $name, $tree) = @_;
	$tree ||= $self->{_tree};
	return _get_first($tree, $name);
}
##############################################################################
sub _get_first {
	my ($elm, $name) = @_;
	return undef if (!$elm);
	return $elm if ($elm->name eq $name);
	foreach my $e (@{$elm->subitems}) {
		my $t = _get_first($e, $name);
		return $t if ($t);
	}
	return undef;
}


##############################################################################
package main;
sub SOAP::Transport::HTTP::Client::get_basic_credentials { 

	return $user => $password;
}
##############################################################################

1;

__END__

=head1 NAME

WebService::Mappoint - Client SOAP implementation for Mappoint, Microsoft's geographic maps web service, based on SOAP::Lite.

=head1 SYNOPSIS

Map fetch example for use with Mappoint 3.0 service. 

     use WebService::Mappoint;
     use MIME::Base64;

     my $render = new WebService::Mappoint::Render();
     my $map;

     $map = $render->GetMap(
               specification => [ 
                 DataSourceName => 'MapPoint.EU',
                 Options => [
                               Format => [
                                            Height => 320,
                                            Width => 320 
                                         ],
                            ],
                 Views => [
                             'MapView:ViewByScale' => 
                                [
                                   CenterPoint =>
                                     [ Latitude => 37.7632, 
                                       Longitude => -122.439702 ],
                                   MapScale => 100000000
                                ],
                          ],	
                 Pushpins => [ 
                   Pushpin => 
                     [  
                       IconName => '176',
                       IconDataSource => 'MapPoint.Icons',
                       PinID => 'san_francisco',
                       Label => 'San Francisco',
                       ReturnsHotArea => 'false',
                       LatLong => [ Latitude => 37.7632, 
                                    Longitude => -122.439702 ],
                     ]
                ]			    
              ] );

     my $image = decode_base64($map->result->{MapImage}{MimeData}{Bits});
     open( GIF, ">san_francisco.gif" );
     print( GIF $image );


Example mappoint.ini file (in /etc or c:\ depending on OS)

     [general]
     xmlns=http://s.mappoint.net/mappoint-30/

     [credentials]
     user=MyUserID
     password=MyUserPassword

     [proxy]
     common=http://findv3.mappoint.net/Find-30/Common.asmx
     find=http://findv3.mappoint.net/Find-30/FindService.asmx
     route=http://routev3.mappoint.net/Route-30/RouteService.asmx
     render=http://renderv3.mappoint.net/Render-30/RenderService.asmx

     [UserInfoHeader]
     DefaultDistanceUnit=km

     [Culture]
     Name=nl
     LCID=19

     [Debug]
     ;proxy=http://localhost/cgi-bin/soaptest.cgi
     ;readable=1


SOAP::Mappoint supports both 3.0 and 2.0 servers. See subsection F<Mappoint 2.0 Example> below for an equivalent 2.0 example.

=head1 DESCRIPTION

=head2 Overview

WebService::Mappoint provides an easy to use interface to Microsoft's  Mappoint maps web service.

The following classes exist:

	WebService::Mappoint::Common
	WebService::Mappoint::Find
	WebService::Mappoint::Render
	WebService::Mappoint::Route

These classes reflect the remote SOAP classes as decribed at

        http://msdn.microsoft.com/library/default.asp?url=/library/en-us/mpn30m/html/mpn30intMPNET.asp

and
	http://msdn.microsoft.com/library/default.asp?url=/library/en-us/mpn20/html/mpdevHeaders.asp?frame=true

and

     http://findv3.mappoint.net/Find-30/Common.asmx
     http://findv3.mappoint.net/Find-30/FindService.asmx
     http://routev3.mappoint.net/Route-30/RouteService.asmx
     http://renderv3.mappoint.net/Render-30/RenderService.asmx

     http://find.staging.mappoint.net/Find-20/Common.asmx?WDSL
     http://find.staging.mappoint.net/Find-20/FindService.asmx?op=FindNearby
     http://render.staging.mappoint.net/Render-20/RenderService.asmx?WDSL
     http://route.staging.mappoint.net/Route-20/RouteService.asmx?WDSL

The Mappoint classes rely on SOAP::Lite, which is required. The Mappoint classes offer an easier API to the Mappoint services than using SOAP::Lite by itself.

WebService::Mappoint is the base class for the other classes and should not be used solely.

For parsing the results from Mappoint, the WebService::Mappoint::Result class can be used. 

Here is an example of creating an imagemap out of the response of GetMap method

    my $map = $render->GetMap(....);
    my $result = new WebService::Mappoint::Result($map);
    my $hot_areas = $result->get_first('HotAreas');

    if( defined $hot_areas ) {

	foreach my $hotarea_elm ( @{$hot_areas->subitems} ) {

	    my $hotarea = $hotarea_elm->attr;

            foreach my $type (qw(IconRectangle LabelRectangle)) {
               my $rect = $hotarea->{$type};
                  $tag .= sprintf('<area shape="rect" coords="%d,%d,%d,%d" href="%s">',
                                $rect->{left},
				$rect->{top},
				$rect->{right},
				$rect->{bottom},
				$hotarea->{PinID} . '.html' );
            }
        }
	$tag .= '</map>';
    }

The ini-file is required and is read at the moment the class WebService::Mappoint is loaded.

=head2 Constructor and intialisation

Constructors for all classes (Common, Find, Render and Route) can take an optional parameter to indicate an alternate ini-file to use. This allows coexistance of 3.0 and 2.0 code within the same application, to ease transition. If no parameter is passed, the default ini-file is used  (/etc/mappoint.ini or c:\mappoint.ini depending on OS). This feature also allows for placement of ini-files in paths different than the default one. Example:

     # produces a render object which will use the servers described
     # in /etc/mappoint30.ini
     my $render30 = new WebService::Mappoint::Render('/etc/mappoint30.ini');

     # produces a render object which will use the servers described
     # in the default file ( /etc/mappoint.ini ).
     my $render = new WebService::Mappoint::Render();


=head2 Class and Object methods

Methods that all classes offer (except the WebService::Mappoint::Result related classes):

	$object->set_CustomLogEntry($value)
	$object->set_CultureName($value)
	$object->set_CultureLCID($value)
	$object->set_DefaultDistanceUnit($value)
	$object->set_ContectGeoID($value)
	$object->set_ContectGeoISO2($value)

The first method deals with the CustomerInfo header, the others deal with the UserInfoHeader.

Other methods are the same as in the description on the earlier mentiond links. However, the parameters are given in a different way. See example in SYNOPSIS.

Note that an anonymous hash is used for attribute of an element and an anonymous array is used for (underlying) elements. These nested data structures are used both to specify Mappoint requests and to present response data.

There is one instance of the 3.0 API in which this nested-structure approach is not enough for fully describing a request. This instance is the MapView class used for GetMap requests. In 3.0 MapView is an abstract class, so a subclass of it needs to be specified via an attribute tag in the request's XML. WebService::Mappoint simplifies this by allowing a subclass name to be specified via a colon separated notation, as follows (see SYNOPSIS example for context):

          Views => [
                  'MapView:ViewByScale' => 
                     [
                        CenterPoint =>
                          [ Latitude => 37.7632, 
                            Longitude => -122.439702 ],
                        MapScale => 100000000
                     ],
                   ]	


The WebService::Mappoint::Result class offers a show-method for showing the response from Mappoint in a clear way. The contructor will build a tree of WebService::Mappoint::ResultElement objects, which have a name, attributes and sub elements.
With the get_first($name) method you can get a subtree of an element with name $name. See also the example above for building the image map.

=head2 Mappoint 2.0 Example

	use WebService::Mappoint;
	use MIME::Base64;

	my $render = new WebService::Mappoint::Render;

	my $map = $render->GetMap(
		view => [
			MapView => [
				CenterPoint => {
					Latitude => 52.1309,
					Longitude => 5.42743
				},
				Scale => 2000000
			],
		],
		options => [
			Format => [
				Width => 500,
				Height => 500
			],
			GeoDataSource => [
				Name => 'MapPoint.EU'
			]
		]
	);

	my $image = decode_base64($map->result->{MapImage}{Image}{Bits});
	open(GIF, ">/tmp/image.gif");
	print(GIF $image);

Example mappoint.ini file (in /etc or c:\ depending on OS) with Mappoint 2.0 servers.

	[credentials]
	user=MyUserid
	password=MyPassword

	[proxy]
	common=http://find.staging.mappoint.net/Find-20/Common.asmx
	find=http://find.staging.mappoint.net/Find-20/FindService.asmx
	render=http://render.staging.mappoint.net/Render-20/RenderService.asmx
	route=http://route.staging.mappoint.net/Route-20/RouteService.asmx

	[UserInfoHeader]
	DefaultDistanceUnit=km

	[Culture]
	Name=nl
	LCID=19

	[Debug]
	;proxy=http://localhost/cgi-bin/soaptest.cgi
	;readable=1

Sample code for generating Image map from Mappoint 2.0 responses.

	my $map = $render->GetMap(....);
	my $result = new WebService::Mappoint::Result($map);
	my $active_area = $result->get_first('ActiveArea');

	foreach my $hotarea_elm (@{$active_area->subitems}) {
	    my $hotarea = $hotarea_elm->attr;

		foreach my $type (qw(IconRectangle LabelRectangle)) {
			my $rect = $hotarea->{$type};
			$tag .= sprintf('<area shape="rect" coords="%d,%d,%d,%d" href="%s">',
				$rect->{left},
				$rect->{top},
				$rect->{right},
				$rect->{bottom},
				$hotarea->{PinID} . '.html'
			);
		}
	}
	$tag .= '</map>';

=head1 ENVIRONMENT

=head1 DIAGNOSTICS

=head1 BUGS

Probably ;-)

=head1 FILES

mappoint.ini

The mappoint.ini file supports also a [Debug] section, where a proxy can be defined you want to use for test purposes. You can also force a readable(1) so that the xml output is more readable in trace mode (when you do +trace=>'all').

	[Debug]
	proxy=http://localhost/cgi-bin/soaptest.cgi
	readable=1


=head1 SEE ALSO

=head1 AUTHOR(S)

Herald van der Breggen (herald at breggen. xs4all. nl)
Claudio Garcia (claudio.garcia at stanfordalumni. org)

