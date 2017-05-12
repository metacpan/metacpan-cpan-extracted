package perfSONAR_PS::DB::File;

use fields 'FILE', 'XML', 'LOGGER';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::DB::File - A module that provides methods for adding 'database
like' functions to files that contain XML markup.

=head1 DESCRIPTION

This purpose of this module is to ease the burden for someone who simply wishes
to use a flat file as an XML database.  It should be known that this is not
recommended as performance will no doubt suffer, but the ability to do so can
be valuable.  The module is to be treated as an object, where each instance of
the object represents a direct connection to a file.  Each method may then be
invoked on the object for the specific database.  

=cut

use XML::LibXML;
use Log::Log4perl qw(get_logger :nowarn);
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::ParameterValidation;

=head2 new($package, { file })

The only argument is a string representing the file to be opened.

=cut 

sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { file => 0 } );

    my $self = fields::new($package);
    $self->{LOGGER} = get_logger("perfSONAR_PS::DB::File");
    if ( defined $parameters->{file} and $parameters->{file} ) {
        $self->{FILE} = $parameters->{file};
    }
    return $self;
}

=head2 setFile($self, { file })

(Re-)Sets the name of the file to be used.

=cut 

sub setFile {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { file => 1 } );

    if ( $parameters->{file} =~ m/\.xml$/mx ) {
        $self->{FILE} = $parameters->{file};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set filename.");
        return -1;
    }
}

=head2 openDB($self, { error })          

Opens the database, will return status of operation.

=cut 

sub openDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );

    if ( defined $self->{FILE} ) {
        my $parser = XML::LibXML->new();
        $self->{XML} = $parser->parse_file( $self->{FILE} );
        ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
        return 0;
    }
    else {
        my $msg = "Cannot open database, missing filename.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 closeDB($self, { error })

Close the database, will return status of operation.

=cut 

sub closeDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );

    if ( defined $self->{XML} and $self->{XML} ) {
        if ( defined open( my $FILE, ">", $self->{FILE} ) ) {
            print $FILE $self->{XML}->toString;
            my $status = close($FILE);
            if ( $status  ) {
                ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
                return 0;
            }
            else {
                my $msg = "File close failed.";
                $self->{LOGGER}->error($msg);
                ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
                return -1;
            }
        }
        else {
            my $msg = "Couldn't open output file \"" . $self->{FILE} . "\"";
            $self->{LOGGER}->error($msg);
            ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
            return -1;
        }
    }
    else {
        my $msg = "LibXML DOM structure not defined.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 query($self, { query, error } )

Given a query, returns the results or nothing.

=cut 

sub query {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, error => 0 } );

    my @results = ();
    if ( $parameters->{query} ) {
        $self->{LOGGER}->debug( "Query \"" . $parameters->{query} . "\" received." );
        if ( defined $self->{XML} and $self->{XML} ) {
            my $nodeset = $self->{XML}->find( $parameters->{query} );
            foreach my $node ( @{$nodeset} ) {
                push @results, $node->toString;
            }
            ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
            return @results;
        }
        else {
            my $msg = "LibXML DOM structure not defined.";
            $self->{LOGGER}->error($msg);
            ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 querySet($self, { query error } )

Given a query, returns the results (as a nodeset) or nothing.  

=cut 

sub querySet {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, error => 0 } );

    if ( $parameters->{query} ) {
        $self->{LOGGER}->debug( "Query \"" . $parameters->{query} . "\" received." );
        if ( defined $self->{XML} and $self->{XML} ) {
            ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
            return $self->{XML}->find( $parameters->{query} );
        }
        else {
            my $msg = "LibXML DOM structure not defined.";
            $self->{LOGGER}->error($msg);
            ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 count($self, { query error } )

Counts the results of a query. 

=cut 

sub count {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, error => 0 } );

    if ( $parameters->{query} ) {
        $self->{LOGGER}->debug( "Query \"" . $parameters->{query} . "\" received." );
        if ( defined $self->{XML} and $self->{XML} ) {
            my $nodeset = $self->{XML}->find( $parameters->{query} );
            ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
            return $nodeset->size();
        }
        else {
            my $msg = "LibXML DOM structure not defined.";
            $self->{LOGGER}->error($msg);
            ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 getDOM($self, { error } )

Returns the internal XML::LibXML DOM object. Will return "" on error.  

=cut 

sub getDOM {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );

    if ( defined $self->{XML} and $self->{XML} ) {
        ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
        return $self->{XML};
    }
    else {
        my $msg = "LibXML DOM structure not defined.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

=head2 setDOM($self, { dom, error } )

Sets the DOM object.

=cut

sub setDOM {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { dom => 1, error => 0 } );

    if ( $parameters->{dom} ) {
        $self->{XML} = $parameters->{dom};
        ${ $parameters->{error} } = q{} if ( defined $parameters->{error} );
        return 0;
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error($msg);
        ${ $parameters->{error} } = $msg if ( defined $parameters->{error} );
        return -1;
    }
}

1;

__END__

=head1 SYNOPSIS

    use perfSONAR_PS::DB::File;
  
    my $file = new perfSONAR_PS::DB::File(
      "./store.xml"
    );

    # or also:
    # 
    # my $file = new perfSONAR_PS::DB::File;
    # $file->setFile("./store.xml");  
    
    my $parameters->{error} = "";
    $file->openDB($parameters->{error});

    print "There are " , $file->count("//nmwg:metadata", $parameters->{error}) , " elements in the file.\n";

    my @results = $file->query("//nmwg:metadata", $parameters->{error});
    foreach my $r (@results) {
      print $r , "\n";
    }

    $file->closeDB($parameters->{error});
    
    # If a DOM already exists...
    
    my $dom = XML::LibXML::Document->new("1.0", "UTF-8");
    $file->setDOM($dom, $parameters->{error});
    
    # or getting back the DOM...
    
    my $dom2 = $file->getDOM($parameters->{error});
    
=head1 SEE ALSO

L<XML::LibXML>, L<Log::Log4perl>, L<Params::Validate>, L<perfSONAR_PS::Common>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
