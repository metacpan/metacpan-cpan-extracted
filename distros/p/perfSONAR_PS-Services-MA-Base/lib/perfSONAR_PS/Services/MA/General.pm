package perfSONAR_PS::Services::MA::General;

use base 'Exporter';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::Services::MA::General - A module that provides methods for
general tasks that MAs need to perform, such as querying for results.

=head1 DESCRIPTION

This module is a catch all for common methods (for now) of MAs in the
perfSONAR-PS framework.  As such there is no 'common thread' that each method
shares.  This module IS NOT an object, and the methods can be invoked directly
(and sparingly).  

=cut

use Exporter;
use Log::Log4perl qw(get_logger);

use Params::Validate qw(:all);
use perfSONAR_PS::ParameterValidation;

use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;

our @EXPORT = ( 'getMetadataXQuery', 'getDataXQuery', 'getDataRRD', 'adjustRRDTime', 'getFilterParameters', 'extractTime', 'complexTime' );

=head2 getMetadataXQuery( { node } )

Given a metadata node, constructs and returns an XQuery statement.

=cut

sub getMetadataXQuery {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    my $query = getSPXQuery( { node => $parameters->{node}, queryString => q{} } );
    my $eventTypeQuery = getEventTypeXQuery( { node => $parameters->{node}, queryString => q{} } );
    if ($eventTypeQuery) {
        if ($query) {
            $query = $query . " and ";
        }
        $query = $query . $eventTypeQuery . "]";
    }
    return $query;
}

=head2 getSPXQuery( { node, queryString } )

Helper function for the subject and parameters portion of a metadata element.
Used by 'getMetadataXQuery', not to be called externally. 

=cut

sub getSPXQuery {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        my $queryCount = 0;
        if ( $parameters->{node}->nodeType != 3 ) {
            if ( !( $parameters->{node}->nodePath() =~ m/select:parameters\/nmwg:parameter/mx ) ) {
                ( my $path = $parameters->{node}->nodePath() ) =~ s/\/nmwg:message//mx;
                $path =~ s/\?//gmx;
                $path =~ s/\/nmwg:metadata//mx;
                $path =~ s/\/nmwg:data//mx;

                # XXX Jason 2/25/06
                # Would this be required elsewhere?
                $path =~ s/\/.*:node//mx;
                $path =~ s/\[\d+\]//gmx;
                $path =~ s/^\///gmx;
                $path =~ s/nmwg:subject/*[local-name()=\"subject\"]/mx;

                if ( $path ne "nmwg:eventType" and ( not $path =~ m/parameters$/mx ) ) {
                    ( $queryCount, $parameters->{queryString} ) = xQueryAttributes( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } );
                    if ( $parameters->{node}->hasChildNodes() ) {
                        ( $queryCount, $parameters->{queryString} ) = xQueryText( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } );
                        foreach my $c ( $parameters->{node}->childNodes ) {
                            $parameters->{queryString} = getSPXQuery( { node => $c, queryString => $parameters->{queryString} } );
                        }
                    }
                }
                elsif ( $path =~ m/parameters$/mx ) {
                    if ( $parameters->{node}->hasChildNodes() ) {
                        ( $queryCount, $parameters->{queryString} ) = xQueryParameters( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } );
                    }
                }
            }
        }
    }
    return $parameters->{queryString};
}

=head2 getEventTypeXQuery( { node, queryString } )

Helper function for the eventType portion of a metadata element.  Used
by 'getMetadataXQuery', not to be called externally. 

=cut

sub getEventTypeXQuery {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        if ( $parameters->{node}->nodeType != 3 ) {
            ( my $path = $parameters->{node}->nodePath() ) =~ s/\/nmwg:message//mx;
            $path =~ s/\?//gmx;
            $path =~ s/\/nmwg:metadata//mx;
            $path =~ s/\/nmwg:data//mx;
            $path =~ s/\[\d+\]//gmx;
            $path =~ s/^\///gmx;
            if ( $path eq "nmwg:eventType" ) {
                if ( $parameters->{node}->hasChildNodes() ) {
                    $parameters->{queryString} = xQueryEventType( { node => $parameters->{node}, path => $path, queryString => $parameters->{queryString} } );
                }
            }
            foreach my $c ( $parameters->{node}->childNodes ) {
                $parameters->{queryString} = getEventTypeXQuery( { node => $c, queryString => $parameters->{queryString} } );
            }
        }
    }
    return $parameters->{queryString};
}

=head2 getDataXQuery( { node, queryString } )

Given a data node, constructs and returns an XQuery statement.

=cut

sub getDataXQuery {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        my $queryCount = 0;
        if ( $parameters->{node}->nodeType != 3 ) {
            ( my $path = $parameters->{node}->nodePath() ) =~ s/\/nmwg:message//mx;
            $path =~ s/\?//gmx;
            $path =~ s/\/nmwg:metadata//mx;
            $path =~ s/\/nmwg:data//mx;
            $path =~ s/\[\d+\]//gmx;
            $path =~ s/^\///gmx;

            if (   $path =~ m/nmwg:parameters$/mx
                or $path =~ m/snmp:parameters$/mx
                or $path =~ m/netutil:parameters$/mx
                or $path =~ m/neterr:parameters$/mx
                or $path =~ m/netdisc:parameters$/mx )
            {
                ( $queryCount, $parameters->{queryString} ) = xQueryParameters( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } ) if ( $parameters->{node}->hasChildNodes() );
            }
            else {
                ( $queryCount, $parameters->{queryString} ) = xQueryAttributes( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } );
                if ( $parameters->{node}->hasChildNodes() ) {
                    ( $queryCount, $parameters->{queryString} ) = xQueryText( { node => $parameters->{node}, path => $path, queryCount => $queryCount, queryString => $parameters->{queryString} } );
                    foreach my $c ( $parameters->{node}->childNodes ) {
                        ( my $path2 = $c->nodePath() ) =~ s/\/nmwg:message//mx;
                        $path  =~ s/\?//mxg;
                        $path2 =~ s/\/nmwg:metadata//mx;
                        $path2 =~ s/\/nmwg:data//mx;
                        $path2 =~ s/\[\d+\]//gmx;
                        $path2 =~ s/^\///gmx;
                        $parameters->{queryString} = getDataXQuery( { node => $c, queryString => $parameters->{queryString} } );
                    }
                }
            }
        }
    }
    return $parameters->{queryString};
}

=head2 xQueryParameters( { node, path, queryCount, queryString } )

Helper function for the parameters portion of NMWG elements, not to 
be called externally. 

=cut

sub xQueryParameters {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, path => 1, queryCount => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        my %paramHash = ();
        if ( $parameters->{node}->hasChildNodes() ) {
            my $attrString = q{};
            foreach my $c ( $parameters->{node}->childNodes ) {
                ( my $path2 = $c->nodePath() ) =~ s/\/nmwg:message//mx;
                $parameters->{path} =~ s/\?//gmx;
                $path2              =~ s/\/nmwg:metadata//mx;
                $path2              =~ s/\/nmwg:data//mx;
                $path2              =~ s/\[\d+\]//gmx;
                $path2              =~ s/^\///gmx;

                if (   $path2 =~ m/nmwg:parameters\/nmwg:parameter$/mx
                    or $path2 =~ m/snmp:parameters\/nmwg:parameter$/mx
                    or $path2 =~ m/netutil:parameters\/nmwg:parameter$/mx
                    or $path2 =~ m/netdisc:parameters\/nmwg:parameter$/mx
                    or $path2 =~ m/neterr:parameters\/nmwg:parameter$/mx )
                {
                    foreach my $attr ( $c->attributes ) {
                        if ( $attr->isa('XML::LibXML::Attr') ) {
                            if ( $attr->getName eq "name" ) {
                                $attrString = "\@name=\"" . $attr->getValue . "\"";
                            }
                            else {
                                if (    ( $attrString ne "\@name=\"startTime\"" )
                                    and ( $attrString ne "\@name=\"endTime\"" )
                                    and ( $attrString ne "\@name=\"time\"" )
                                    and ( $attrString ne "\@name=\"resolution\"" )
                                    and ( $attrString ne "\@name=\"consolidationFunction\"" ) )
                                {
                                    if ( $paramHash{$attrString} ) {
                                        $paramHash{$attrString} .= " or " . $attrString . "and \@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                                        $paramHash{$attrString} .= " or " . $attrString . " and text()=\"" . $attr->getValue . "\"" if ( $attr->getName eq "value" );
                                    }
                                    else {
                                        $paramHash{$attrString} = $attrString . "and \@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                                        $paramHash{$attrString} .= " or " . $attrString . " and text()=\"" . $attr->getValue . "\"" if ( $attr->getName eq "value" );
                                    }
                                }
                            }
                        }
                    }

                    if (    ( $attrString ne "\@name=\"startTime\"" )
                        and ( $attrString ne "\@name=\"endTime\"" )
                        and ( $attrString ne "\@name=\"time\"" )
                        and ( $attrString ne "\@name=\"resolution\"" )
                        and ( $attrString ne "\@name=\"consolidationFunction\"" ) )
                    {
                        if ( $c->childNodes->size() >= 1 ) {
                            if ( $c->firstChild->nodeType == 3 ) {
                                ( my $value = $c->firstChild->textContent ) =~ s/\s{2}//gmx;
                                if ($value) {
                                    if ( $paramHash{$attrString} ) {
                                        $paramHash{$attrString} .= " or " . $attrString . " and \@value=\"" . $value . "\" or " . $attrString . " and text()=\"" . $value . "\"";
                                    }
                                    else {
                                        $paramHash{$attrString} = $attrString . " and \@value=\"" . $value . "\" or " . $attrString . " and text()=\"" . $value . "\"";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        foreach my $key ( sort keys %paramHash ) {
            $parameters->{queryString} = $parameters->{queryString} . " and " if ( $parameters->{queryString} );
            if ( $parameters->{path} eq "nmwg:parameters" ) {
                $parameters->{queryString} = $parameters->{queryString} . "./*[local-name()=\"parameters\"]/nmwg:parameter[";
            }
            else {
                $parameters->{queryString} = $parameters->{queryString} . $parameters->{path} . "/nmwg:parameter[";
            }
            $parameters->{queryString} = $parameters->{queryString} . $paramHash{$key} . "]";
        }
    }
    return ( $parameters->{queryCount}, $parameters->{queryString} );
}

=head2 xQueryAttributes( { node, path, queryCount, queryString } )

Helper function for the attributes portion of NMWG elements, not to 
be called externally. 

=cut

sub xQueryAttributes {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, path => 1, queryCount => 1, queryString => 1 } );
    my $logger     = get_logger("perfSONAR_PS::Services::MA::General");
    my $counter    = 0;

    unless ( $parameters->{node}->getType == 8 ) {
        foreach my $attr ( $parameters->{node}->attributes ) {
            if ( $attr->isa('XML::LibXML::Attr') ) {
                if (   ( not $parameters->{path} )
                    or $parameters->{path} =~ m/metadata$/mx
                    or $parameters->{path} =~ m/data$/mx
                    or $parameters->{path} =~ m/subject$/mx
                    or $parameters->{path} =~ m/\*\[local-name\(\)=\"subject\"\]$/mx
                    or $parameters->{path} =~ m/parameters$/mx
                    or $parameters->{path} =~ m/key$/mx
                    or $parameters->{path} =~ m/service$/mx
                    or $parameters->{path} =~ m/eventType$/mx
                    or $parameters->{path} =~ m/node$/mx )
                {
                    if ( $attr->getName ne "id" and ( not $attr->getName =~ m/.*IdRef$/mx ) ) {
                        if ( $parameters->{queryCount} == 0 ) {
                            $parameters->{queryString} = $parameters->{queryString} . " and " if ( $parameters->{queryString} );
                            $parameters->{queryString} = $parameters->{queryString} . $parameters->{path} . "[";
                            $parameters->{queryString} = $parameters->{queryString} . "\@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                            $parameters->{queryCount}++;
                        }
                        else {
                            $parameters->{queryString} = $parameters->{queryString} . " and \@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                        }
                        $counter++;
                    }
                }
                else {
                    if ( $parameters->{queryCount} == 0 ) {
                        $parameters->{queryString} = $parameters->{queryString} . " and " if ( $parameters->{queryString} );
                        $parameters->{queryString} = $parameters->{queryString} . $parameters->{path} . "[";
                        $parameters->{queryString} = $parameters->{queryString} . "\@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                        $parameters->{queryCount}++;
                    }
                    else {
                        $parameters->{queryString} = $parameters->{queryString} . " and \@" . $attr->getName . "=\"" . $attr->getValue . "\"";
                    }
                    $counter++;
                }
            }
        }

        if ($counter) {
            my @children = $parameters->{node}->childNodes;
            if ( $#children == 0 ) {
                if ( $parameters->{node}->firstChild->nodeType == 3 ) {
                    ( my $value = $parameters->{node}->firstChild->textContent ) =~ s/\s{2}//gmx;
                    $parameters->{queryString} = $parameters->{queryString} . "]" if ( !$value );
                }
            }
            else {
                $parameters->{queryString} = $parameters->{queryString} . "]";
            }
        }
    }
    return ( $parameters->{queryCount}, $parameters->{queryString} );
}

=head2 xQueryText( { node, path, queryCount, queryString } )

Helper function for the text portion of NMWG elements, not to 
be called externally.  

=cut

sub xQueryText {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, path => 1, queryCount => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        my @children = $parameters->{node}->childNodes;
        if ( $#children == 0 ) {
            if ( $parameters->{node}->firstChild->nodeType == 3 ) {
                ( my $value = $parameters->{node}->firstChild->textContent ) =~ s/\s{2}//gmx;
                if ($value) {
                    if ( $parameters->{queryCount} == 0 ) {
                        $parameters->{queryString} = $parameters->{queryString} . " and " if ( $parameters->{queryString} );
                        $parameters->{queryString} = $parameters->{queryString} . $parameters->{path} . "[";
                        $parameters->{queryString} = $parameters->{queryString} . "text()=\"" . $value . "\"";
                        $parameters->{queryCount}++;
                    }
                    else {
                        $parameters->{queryString} = $parameters->{queryString} . " and text()=\"" . $value . "\"";
                    }
                    $parameters->{queryString} = $parameters->{queryString} . "]" if ( $parameters->{queryCount} );
                    return ( $parameters->{queryCount}, $parameters->{queryString} );
                }
            }
        }

        #    if($parameters->{queryCount}) {
        #      $parameters->{queryString} = $parameters->{queryString} . "]";
        #    }
    }
    return ( $parameters->{queryCount}, $parameters->{queryString} );
}

=head2 xQueryEventType( { node, path, queryString } )

Helper function for the eventTYpe portion of NMWG elements, not to 
be called externally. 

=cut

sub xQueryEventType {
    my (@args) = @_;
    my $parameters = validateParams( @args, { node => 1, path => 1, queryString => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    unless ( $parameters->{node}->getType == 8 ) {
        my @children = $parameters->{node}->childNodes;
        if ( $#children == 0 ) {
            if ( $parameters->{node}->firstChild->nodeType == 3 ) {
                ( my $value = $parameters->{node}->firstChild->textContent ) =~ s/\s{2}//gmx;
                if ($value) {
                    if ( $parameters->{queryString} ) {
                        $parameters->{queryString} = $parameters->{queryString} . " or ";
                    }
                    else {
                        $parameters->{queryString} = $parameters->{queryString} . $parameters->{path} . "[";
                    }
                    $parameters->{queryString} = $parameters->{queryString} . "text()=\"" . $value . "\"";

                    #          return $parameters->{queryString};
                }
            }
        }
    }
    return $parameters->{queryString};
}

=head2 getDataRRD( { directory, file, timeSettings, rrdtool } )

Returns either an error or the actual results of an RRD database query.

=cut

sub getDataRRD {
    my (@args) = @_;
    my $parameters = validateParams( @args, { directory => 1, file => 1, timeSettings => 1, rrdtool => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    my %result = ();
    if ( $parameters->{directory} ) {
        if ( !( $parameters->{file} =~ "^/" ) ) {
            $parameters->{file} = $parameters->{directory} . "/" . $parameters->{file};
        }
    }

    my $datadb = new perfSONAR_PS::DB::RRD( { path => $parameters->{rrdtool}, name => $parameters->{file}, error => 1 } );
    $datadb->openDB;

    if (
        not $parameters->{timeSettings}->{"CF"}
        or (    $parameters->{timeSettings}->{"CF"} ne "AVERAGE"
            and $parameters->{timeSettings}->{"CF"} ne "MIN"
            and $parameters->{timeSettings}->{"CF"} ne "MAX"
            and $parameters->{timeSettings}->{"CF"} ne "LAST" )
        )
    {
        $parameters->{timeSettings}->{"CF"} = "AVERAGE";
    }

    my %rrd_result = $datadb->query(
        {
            cf         => $parameters->{timeSettings}->{"CF"},
            resolution => $parameters->{timeSettings}->{"RESOLUTION"},
            start      => $parameters->{timeSettings}->{"START"}->{"internal"},
            end        => $parameters->{timeSettings}->{"END"}->{"internal"}
        }
    );

    if ( $datadb->getErrorMessage ) {
        my $msg = "Query error \"" . $datadb->getErrorMessage . "\"; query returned \"" . $rrd_result{ANSWER} . "\"";
        $logger->error($msg);
        $result{"ERROR"} = $msg;
        $datadb->closeDB;
        return %result;
    }
    else {
        $datadb->closeDB;
        return %rrd_result;
    }
}

=head2 adjustRRDTime( { timeSettings } )

Given an MA object, this will 'adjust' the time values in an data request
that will end up quering an RRD database.  The time values are only
'adjusted' if the resolution value makes them 'uneven' (i.e. if you are
requesting data between 1 and 70 with a resolution of 60, RRD will default
to a higher resolution becaues the boundaries are not exact).  We adjust
the start/end times to better fit the requested resolution.

=cut

sub adjustRRDTime {
    my (@args) = @_;
    my $parameters = validateParams( @args, { timeSettings => 1 } );
    my $logger = get_logger("perfSONAR_PS::Services::MA::General");

    my ( $sec, $frac ) = Time::HiRes::gettimeofday;

    return if ( ( not exists $parameters->{timeSettings}->{"START"}->{"internal"} ) and ( not exists $parameters->{timeSettings}->{"END"}->{"internal"} ) );

    my $oldStart = $parameters->{timeSettings}->{"START"}->{"internal"};
    my $oldEnd   = $parameters->{timeSettings}->{"END"}->{"internal"};
    if ( $parameters->{timeSettings}->{"RESOLUTION"} and $parameters->{timeSettings}->{"RESOLUTION"} =~ m/^\d+$/mx ) {
        if ( $parameters->{timeSettings}->{"START"}->{"internal"} % $parameters->{timeSettings}->{"RESOLUTION"} ) {
            $parameters->{timeSettings}->{"START"}->{"internal"} = int( $parameters->{timeSettings}->{"START"}->{"internal"} / $parameters->{timeSettings}->{"RESOLUTION"} + 1 ) * $parameters->{timeSettings}->{"RESOLUTION"};
        }
        if ( $parameters->{timeSettings}->{"END"}->{"internal"} % $parameters->{timeSettings}->{"RESOLUTION"} ) {
            $parameters->{timeSettings}->{"END"}->{"internal"} = int( $parameters->{timeSettings}->{"END"}->{"internal"} / $parameters->{timeSettings}->{"RESOLUTION"} ) * $parameters->{timeSettings}->{"RESOLUTION"};
        }
    }

    # XXX: Jason 2/24
    # When run over and over this will alter the START time for an RRD range.
    #
    #  if($parameters->{timeSettings}->{"START"} and $parameters->{timeSettings}->{"RESOLUTION"} and $parameters->{timeSettings}->{"RESOLUTION"} =~ m/^\d+$/) {
    #    $parameters->{timeSettings}->{"START"} = $parameters->{timeSettings}->{"START"} - $parameters->{timeSettings}->{"RESOLUTION"};
    #  }

    if (    $parameters->{timeSettings}->{"START"}->{"internal"}
        and $parameters->{timeSettings}->{"START"}->{"internal"} =~ m/^\d+$/mx
        and $parameters->{timeSettings}->{"RESOLUTION"}
        and $parameters->{timeSettings}->{"RESOLUTION"} =~ m/^\d+$/mx )
    {
        while ( $parameters->{timeSettings}->{"START"}->{"internal"} > ( $sec - ( $parameters->{timeSettings}->{"RESOLUTION"} * 2 ) ) ) {
            $parameters->{timeSettings}->{"START"}->{"internal"} -= $parameters->{timeSettings}->{"RESOLUTION"};
        }
    }

    if (    $parameters->{timeSettings}->{"END"}->{"internal"}
        and $parameters->{timeSettings}->{"END"}->{"internal"} =~ m/^\d+$/mx
        and $parameters->{timeSettings}->{"RESOLUTION"}
        and $parameters->{timeSettings}->{"RESOLUTION"} =~ m/^\d+$/mx )
    {
        while ( $parameters->{timeSettings}->{"END"}->{"internal"} > ( $sec - ( $parameters->{timeSettings}->{"RESOLUTION"} * 2 ) ) ) {
            $parameters->{timeSettings}->{"END"}->{"internal"} -= $parameters->{timeSettings}->{"RESOLUTION"};
        }
    }
    return;
}

=head2 getFilterParameters( { m, namespaces, default_resolution, resolution } )

Extract the filter parameters from the filter metadata block.

=cut

sub getFilterParameters {
    my (@args) = @_;
    my $parameters = validateParams(
        @args,
        {
            m                  => 1,
            namespaces         => 1,
            default_resolution => 0,
            resolution         => 0
        }
    );

    my %time = ();

    # We need to know the resolution before anything else since the gt or lt operators use it.
    my $temp = find( $parameters->{m}, ".//*[local-name()=\"parameters\"]/*[local-name()=\"parameter\" and \@name=\"resolution\"]", 1 );
    if ($temp) {
        $time{"RESOLUTION"} = extract( $temp, 1 );
    }

    $time{"RESOLUTION_SPECIFIED"} = 0;
    if (   ( not $time{"RESOLUTION"} )
        or ( not $time{"RESOLUTION"} =~ m/^\d+$/mx ) )
    {
        if ( exists $parameters->{default_resolution} ) {
            $time{"RESOLUTION"} = $parameters->{default_resolution};
        }
    }
    else {
        $time{"RESOLUTION_SPECIFIED"} = 1;
    }

    my $find_res = find( $parameters->{m}, ".//*[local-name()=\"parameters\"]/*[local-name()=\"parameter\"]" );

    if ($find_res) {
        foreach my $param ($find_res->get_nodelist) {
            my $name = $param->getAttribute("name");
            my $operator = $param->getAttribute("operator");

            if ($name eq "consolidationFunction") {
                $time{"CF"} = extract( $param, 1 );
                next;
            }

            if ($name eq "startTime") {
                my $res = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, start => "1" } );
                $time{"START"} = $res if ($res);
                next;
            }

            if ($name eq "endTime") {
                my $res  = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, end => "1" } );
                $time{"END"} = $res if ($res);
                next;
            }

            if ($name eq "time" and $operator eq "gte") {
                my $res  = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, start => "1" } );
                $time{"START"} = $res if ($res);
                next;
            }

            if ($name eq "time" and $operator eq "lte") {
                my $res  = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, end => "1" } );
                $time{"END"} = $res if ($res);
                next;
            }

            if ($name eq "time" and $operator eq "gt") {
                my $res = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, start => "1" } );
                $time{"START"} = $res + $time{"RESOLUTION"} if ($res);
                next;
            }

            if ($name eq "time" and $operator eq "lt") {
                my $res  = extractTime( { parameter => $param, namespaces => $parameters->{namespaces}, end => "1" } );
                $time{"END"} = $res + $time{"RESOLUTION"} if ($res);
                next;
            }

            if ($name eq "time" and $operator eq "eq") {
                my $res = extractTime( { parameter => $param, namespaces => $parameters->{namespaces} } );
                $time{"START"} = $res if ($res);
                $time{"END"} = $time{"START"};
                next;
            }

        }
    }

    foreach my $t ( keys %time ) {
        $time{$t} =~ s/(\n)|(\s+)//gmx;
    }

    if (    $time{"START"}
        and $time{"END"}
        and $time{"START"}->{"value"} > $time{"END"}->{"value"} )
    {
        return;
    }

    return \%time;
}

=head2 extractTime( { parameter, namespaces, start, end } )

Checks the various nesting combinations possible when specifying time.

=cut

sub extractTime {
    my (@args) = @_;
    my $parameters = validateParams(
        @args,
        {
            parameter  => 1,
            namespaces => 1,
            start      => 0,
            end        => 0
        }
    );
    my %unit = ();
    $unit{"type"} = $parameters->{parameter}->getAttribute("type") if $parameters->{parameter}->getAttribute("type");

    my $timePrefix = $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"};
    if ($timePrefix) {
        my $time = find( $parameters->{parameter}, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":time", 1 );
        if ($time) {
            $unit{"type"} = $time->getAttribute("type") if $time->getAttribute("type");
            my $value = find( $time, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":value", 1 );
            if ($value) {
                $unit{"type"} = $value->getAttribute("type") if $value->getAttribute("type");
                $unit{"value"} = complexTime( { element => $value } );
            }
            else {
                if ( $parameters->{start} ) {
                    my $start = find( $time, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":start", 1 );
                    if ($start) {
                        $unit{"type"} = $start->getAttribute("type") if $start->getAttribute("type");
                        $value = find( $start, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":value", 1 );
                        if ($value) {
                            $unit{"type"} = $value->getAttribute("type") if $value->getAttribute("type");
                            $unit{"value"} = complexTime( { element => $value } );
                        }
                        else {
                            $unit{"value"} = complexTime( { element => $start } );
                        }
                    }
                    else {
                        $unit{"value"} = complexTime( { element => $time } );
                    }
                }
                elsif ( $parameters->{end} ) {
                    my $end = find( $time, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":end", 1 );
                    if ($end) {
                        $unit{"type"} = $end->getAttribute("type") if $end->getAttribute("type");
                        $value = find( $end, "./" . $parameters->{namespaces}->{"http://ggf.org/ns/nmwg/time/2.0/"} . ":value", 1 );
                        if ($value) {
                            $unit{"type"} = $value->getAttribute("type") if $value->getAttribute("type");
                            $unit{"value"} = complexTime( { element => $value } );
                        }
                        else {
                            $unit{"value"} = complexTime( { element => $end } );
                        }
                    }
                    else {
                        $unit{"value"} = complexTime( { element => $time } );
                    }
                }
                else {
                    $unit{"value"} = complexTime( { element => $time } );
                }
            }
        }
        else {
            $unit{"value"} = complexTime( { element => $parameters->{parameter} } );
        }
    }
    else {
        $unit{"value"} = complexTime( { element => $parameters->{parameter} } );
    }
    return \%unit;
}

=head2 complexTime( { element } )

Given an elemenet (normally time based), checks to see if it is 'complex', i.e. 
if there are nested elements inside.  If there are none, return the text that is
enclosed.

=cut

sub complexTime {
    my (@args) = @_;
    my $parameters = validateParams( @args, { element => 1 } );

    my $complex = q{};
    foreach my $p ( $parameters->{element}->childNodes ) {
        if ( $p->nodeType != 3 ) {
            $complex++;
            last;
        }
    }
    unless ($complex) {
        my $result = extract( $parameters->{element}, 0 );
        $result =~ s/(^\s*|\s*$)//gmx;
        return $result;
    }
    return;
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>

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
