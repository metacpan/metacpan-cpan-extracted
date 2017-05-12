package perfSONAR_PS::Services::LS::General;

use base 'Exporter';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::LS::General - A module that provides methods for general tasks
that LSs need to perform.

=head1 DESCRIPTION

This module is a catch all for common methods (for now) of LSs in the
perfSONAR-PS framework.  As such there is no 'common thread' that each method
shares.  This module IS NOT an object, and the methods can be invoked directly
(and sparingly). 

=cut

use Exporter;
use Params::Validate qw(:all);
use perfSONAR_PS::Common;
use perfSONAR_PS::ParameterValidation;

our @EXPORT = ( 'createControlKey', 'createLSKey', 'createLSData', 'extractQuery' );

=head2 createControlKey($key, $time)

Creates a 'control' key for the control database that keeps track of time.

=cut

sub createControlKey {
    my (@args) = @_;
    my $parameters = validateParams( @args, { key => 1, time => 1 } );

    my $keyElement = "  <nmwg:metadata id=\"" . $parameters->{key} . "-control\" metadataIdRef=\"" . $parameters->{key} . "\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $keyElement = $keyElement . "    <nmwg:parameters id=\"control-parameters\">\n";
    $keyElement = $keyElement . "      <nmwg:parameter name=\"timestamp\">\n";
    $keyElement = $keyElement . "        <nmtm:time type=\"unix\" xmlns:nmtm=\"http://ggf.org/ns/nmwg/time/2.0/\">" . $parameters->{time} . "</nmtm:time>\n";
    $keyElement = $keyElement . "      </nmwg:parameter>\n";
    $keyElement = $keyElement . "    </nmwg:parameters>\n";
    $keyElement = $keyElement . "  </nmwg:metadata>\n";
    return wrapStore( { content => $keyElement, type => "LSStore-control" } );
}

=head2 createLSKey($key, $eventType)

Creates the 'internals' of the metadata that will be returned w/ a key.

=cut

sub createLSKey {
    my (@args) = @_;
    my $parameters = validateParams( @args, { key => 1, eventType => 0 } );

    my $keyElement = q{};
    $keyElement = $keyElement . "      <nmwg:key xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"key." . genuid() . "\">\n";
    $keyElement = $keyElement . "          <nmwg:parameters id=\"param." . genuid() . "\">\n";
    $keyElement = $keyElement . "            <nmwg:parameter name=\"lsKey\">" . $parameters->{key} . "</nmwg:parameter>\n";
    $keyElement = $keyElement . "          </nmwg:parameters>\n";
    $keyElement = $keyElement . "        </nmwg:key>\n";
    if ( $parameters->{eventType} ) {
        $keyElement = $keyElement . "        <nmwg:eventType>" . $parameters->{eventType} . "</nmwg:eventType>\n";
    }
    return $keyElement;
}

=head2 createLSData($dataId, $metadataId, $data)

Creates a 'data' block that is stored in the backend storage. 

=cut

sub createLSData {
    my (@args) = @_;
    my $parameters = validateParams( @args, { dataId => 1, metadataId => 1, data => 1 } );

    my $dataElement = "    <nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"" . $parameters->{dataId} . "\" metadataIdRef=\"" . $parameters->{metadataId} . "\">\n";
    $dataElement = $dataElement . "      " . $parameters->{data} . "\n";
    $dataElement = $dataElement . "    </nmwg:data>\n";
    return wrapStore( { content => $dataElement, type => "LSStore" } );
}

=head2 extractQuery($node)

Pulls out the COMPLETE contents of an XQuery subject, this also includes sub 
elements. 

=cut

sub extractQuery {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1 } );

    my $query = q{};
    if ( $parameters->{node}->hasChildNodes() ) {
        foreach my $c ( $parameters->{node}->childNodes ) {
            if ( $c->nodeType == 3 ) {
                $query = $query . $c->textContent;
            }
            else {
                $query = $query . $c->toString;
            }
        }
    }
    return $query;
}

=head2 wrapStore($content, $type)

Adds 'store' tags around some content.  This is to mimic the way eXist deals
with storing XML data.  The 'type' argument is used to type the store file.

NOT FOR EXTERNAL USE

=cut

sub wrapStore {
    my (@args) = @_;
    my $parameters = validateParams( @args, { content => 0, type => 0 } );

    my $store = "<nmwg:store xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"";
    if ( exists $parameters->{type} and $parameters->{type} ) {
        $store = $store . " type=\"" . $parameters->{type} . "\" ";
    }
    if ( exists $parameters->{content} and $parameters->{content} ) {
        $store = $store . ">\n";
        $store = $store . $parameters->{content};
        $store = $store . "</nmwg:store>\n";
    }
    else {
        $store = $store . "/>\n";
    }
    return $store;
}

1;

__END__

=head1 SEE ALSO

L<Params::Validate>, L<perfSONAR_PS::Common>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: General.pm 1877 2008-03-27 16:33:01Z aaron $

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

