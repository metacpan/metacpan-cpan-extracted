package XML::DB::DatabaseManager;
use strict;
use XML::DB::Database;
use XML::DB::Collection;

BEGIN {
    use vars qw ($VERSION $self);
    $VERSION     = 0.02;

}

=head1 NAME

XML::DB::DatabaseManager - an approximation to the XML:DB DatabaseManager

=head1 SYNOPSIS

use XML::DB::DatabaseManager;

my $driver = 'Xindice';
my $url = 'http://localhost:4080';

eval{
    $dbm = new XML::DB::DatabaseManager();
    $dbm->registerDatabase($driver);
    $col = $dbm->getCollection("xmldb:$driver:$url/db/test");
    ......
    };

if ($@){
    die $@;
}

deregisterDatabase($driver);

=head1 DESCRIPTION

This is the initial class to use to get access to the XML:DB modules, an
approximate implementation of the XML:DB API defined for Java at
http://www.xmldb.org. This implementation is designed to give a uniform
Perl access over XML-RPC to both of the current free native XML databases,
eXist and Xindice, as well as providing the same front-end for a plain
file-system.

Unlike the DatabaseManager defined in the XML:DB API (which is a Factory), 
this simply registers driver names, generating a new Database instance for 
each request. Multiple database drivers can be used simultaneously (eg.
to transfer data from one database to another). The drivers themselves are
rather confusingly called 'Databases' in this system.

Only one DatabaseManager can be instantiated in a program.

=head1 AUTHOR

	Graham Seaman
	CPAN ID: GSEAMAN
	graham@opencollector.org

=head1 COPYRIGHT

Copyright (c) 2002 Graham Seaman. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 BUGS

=head1 SEE ALSO

XML::DB::Collection, XML::DB::Resource, XML::DB::Database, XML::DB::ResourceSet, XML::DB::Resource::XMLResource, XML::DB::Service::XPathQueryService, XML::DB::Service::XUpdateQueryService, XML::DB::Database::File, XML::DB::Database::Xindice, XML::DB::Database::Exist.

=head1 PUBLIC METHODS


=cut

=head2 new

=over

I<Usage>     : $databaseManager = new DatabaseManager;

I<Purpose>   : Constructor for singleton

I<Returns>   : The DatabaseManager 

I<Argument>  : None

=back

=cut

sub new{ 
    my $class = shift;
    return $self if defined $self;
    my $store = {
	drivers => {},
    };
    $self = bless $store, $class;
    return $self;
}

=head2 registerDatabase

=over

I<Usage>     : $databaseManager->registerDatabase($database);

I<Purpose>   : Stores names of database drivers in $self

I<Returns>   : void

I<Argument>  : Database name


=back

=cut

sub registerDatabase{
    my ($self, $driverName) = @_;
  
    $self->{'drivers'}->{$driverName} = 1;
}

=head2 deregisterDatabase

=over

I<Usage>     : $databaseManager->deregisterDatabase($driverName);

I<Purpose>   : Remove database driver name from $self

I<Returns>   : void

I<Argument>  : Driver name

=back

=cut

sub deregisterDatabase{
    my ($self, $driverName) = @_;

    delete $self->{'drivers'}->{$driverName};
}

=head2 getCollection

=over

I<Usage>     : $databaseManager->getCollection($uri, $name, $passwd);

I<Purpose>   : Stores names of database drivers in $self

I<Returns>   : void

I<Argument>  : full uri for a collection

I<Comment>   : username and password are ignored, but here for possible future drivers.

=back

=cut

sub getCollection{
    my ($self, $uri, $name, $passwd) = @_;

    
    my ($dbname, $url, $db, $collName) = _parseURI($uri);
    if (! defined $self->{'drivers'}->{$dbname}){
	die "Database $dbname not registered";
    }
    my $collection = undef;
    my $driver =  new XML::DB::Database($dbname);
    if (ref($driver)){
	$driver->setURI($url);
	eval{
	    $collection = new XML::DB::Collection($driver, $db, $collName, $name, $passwd)
	    };
	if ($@){
	    die $@;
	}
    }
    else{
	die "Couldnt get a driver in DatabaseManager::getCollection";
    }
    return $collection;
}

# conformance level depends on the driver, so we need to look up the db
# attached to the uri. However, conformance levels are generally somewhere
# fractional and undefined, so this is left for now.  
sub getConformanceLevel{
    my ($self, $uri) = @_;

    die "getConformanceLevel not implemented";
}

sub getDatabases{
    my $self = shift;

    return $self->{'drivers'};
}

sub getProperty{
    my ($self, $name) = @_;

    return $self->{$name};
}

sub setProperty{
    my ($self, $name, $value) = @_;

    $self->{$name} = $value;
}

=head1 PRIVATE METHODS

=head2 _parseURI

=cut

sub _parseURI{
    my $URI = shift;
    my ($driver, $url, $db, $collection);
    # eg. (xmldb:exist)://(localhost:4080)(/db/stuff)
    $URI =~ s|^xmldb:|| or die "db must start with xmldb in URI: $URI";
    $URI =~ s|^([^:]+):|| or die "no driver name in URI: $URI";
    $driver = $1;
    if ($URI =~ m|^(http:)?//|){
	if ($URI =~ m|^http://|){
	    $URI =~ s|^(http://[^/]*)/||;
	    $url = $1;
	}
	elsif($URI =~ m|^//|){
	    $URI =~ s|^(//[^/]*)/||;
	    $url = 'http:'.$1;
	}
    }
    else{ # special case for the File driver: how to make this more
	  # robust (ie allow ANY db directory name)? Current system
	  # forces db start 'db' just to recognise the end of the 'url'.
	$URI =~ m|^(.*?)/(db.*)$|;
	$url = $1;
	$URI = $2;
    }
    if ($URI !~ m|/|){
	$db = '/' . $URI;
    }
    else{
	$URI =~ s|/([^/]+)$|| or die "Collection name must not end in slash in URI: $URI";
	$collection = $1;
	$db = '/' . $URI;
    }
    return ($driver, $url, $db, $collection);
}
1; 

__END__


