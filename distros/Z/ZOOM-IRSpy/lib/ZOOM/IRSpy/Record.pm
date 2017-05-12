
package ZOOM::IRSpy::Record;
### I don't think there's any reason for this to be separate from
#   ZOOM::IRSpy::Connection, now that the correspondence is always 1:1

use 5.008;
use strict;
use warnings;

use Scalar::Util;
use XML::LibXML;
use XML::LibXML::XPathContext;
use ZOOM::IRSpy::Utils qw(xml_encode isodate irspy_xpath_context);

=head1 NAME

ZOOM::IRSpy::Record - record describing a target for IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub new {
    my $class = shift();
    my($irspy, $target, $zeerex) = @_;

    if (!defined $zeerex) {
	$zeerex = _empty_zeerex_record($target);
    }

    ### Parser should be in the IRSpy object
    my $parser = new XML::LibXML();
    my $this = bless {
	irspy => $irspy,
	target => $target,
	parser => $parser,
	zeerex => $parser->parse_string($zeerex)->documentElement(),
	zoom_error => { TIMEOUT => 0 },
    }, $class;

    #Scalar::Util::weaken($this->{irspy});
    #Scalar::Util::weaken($this->{parser});

    return $this;
}

sub zoom_error { return shift->{'zoom_error'} }

sub _empty_zeerex_record {
    my($target) = @_;

    my($protocol, $host, $port, $db) =
	ZOOM::IRSpy::_parse_target_string($target);

    my $xprotocol = xml_encode($protocol);
    my $xhost = xml_encode($host);
    my $xport = xml_encode($port);
    my $xdb = xml_encode($db);
    return <<__EOT__;
<explain xmlns="http://explain.z3950.org/dtd/2.0/">
 <serverInfo protocol="$xprotocol">
  <host>$xhost</host>
  <port>$xport</port>
  <database>$xdb</database>
 </serverInfo>
</explain>
__EOT__
}


sub append_entry {
    my $this = shift();
    my($xpath, $frag) = @_;

    #print STDERR "this=$this, xpath='$xpath', frag='$frag'\n";
    my $xc = $this->xpath_context();
    $xc->registerNs(zeerex => "http://explain.z3950.org/dtd/2.0/");
    $xc->registerNs(irspy => $ZOOM::IRSpy::Utils::IRSPY_NS);

    my @nodes = $xc->findnodes($xpath);
    if (@nodes == 0) {
	# Make the node that we're inserting into, if possible.  A
	# fully general version would work its way through each
	# component of the XPath, but for now we just treat it as a
	# single chunk to go inside the top-level node.
	$this->_half_decent_appendWellBalancedChunk($xc->getContextNode(),
						    "<$xpath></$xpath>");
	@nodes = $xc->findnodes($xpath);
	die("still no matches for '$xpath' after creating: can't append")
	    if @nodes == 0;
    }

    $this->{irspy}->log("warn",
			scalar(@nodes), " matches for '$xpath': using first")
	if @nodes > 1;

    $this->_half_decent_appendWellBalancedChunk($nodes[0], $frag);
}

sub xpath_context {
    my $this = shift();

    return irspy_xpath_context($this->{zeerex});
}

sub store_result {
    my ($this, $type, %info) = @_;
    my $xml = "<irspy:$type";

    foreach my $key (keys %info) {
        $xml .= " $key=\"" . xml_encode($info{$key}) . "\"";
    }

    $xml .= ">" . isodate(time()) . "</irspy:$type>\n";

    $this->append_entry('irspy:status', $xml);
}


# *sigh*
#
# _Clearly_ the right way to append a well-balanced chunk of XML to
# a node's children is to call appendWellBalancedChunk() from the
# XML::LibXML::Element class.  However, this fails in the common case
# where the ZeeRex record we're working with doesn't declare the
# "irspy" namespace that the inserted fragments use.
#
# To my utter astonishment it seems that XML::LibXML (as of version
# 1.58, 31st March 2004) doesn't provide ANY way to register a
# namespace for parsing, which makes the parse_balanced_chunk()
# function that appendWellBalancedChunk() uses effectively useless.
# It _is_ possible to use setNamespace() on a node, to register a new
# namespace mapping for that node -- but that only affects pre-parsed
# trees, and is no use for parsing.  Hence the following pair of lines
# DOES NOT WORK:
#	$node->setNamespace($ZOOM::IRSpy::Utils::IRSPY_NS, "irspy", 0);
#	$node->appendWellBalancedChunk($frag);
#
# Instead I have to go the long way round, hence this method.  I have
# two candidate re-implementations, of which the former is marginally
# less loathsome, but does require that the excess namespace
# declarations be factored out later -- as least, if you want neat
# output.
#
sub _half_decent_appendWellBalancedChunk {
    my $this = shift();
    my($node, $frag) = @_;

    if (1) {
	$frag =~ s,>, xmlns:irspy="$ZOOM::IRSpy::Utils::IRSPY_NS">,;
	eval {
	    $node->appendWellBalancedChunk($frag);
	}; if ($@) {
	    print STDERR "died while trying to appendWellBalancedChunk(), probably due to bad XML:\n$frag";
	    die $@;
	}
	return;
    }

    # Instead -- and to call this brain-damaged would be an insult
    # to all those fine people out there with actual brain damage
    # -- I have to "parse" the XML fragment myself and insert the
    # resulting hand-build DOM tree.  Someone shoot me now.
    my($open, $content, $close) = $frag =~ /^<(.*?)>(.*)<\/(.*?)>$/;
    die "can't 'parse' XML fragment '$frag'"
	if !defined $open;
    my($tag, $attrs) = $open =~ /(.*?)\s(.*)/;
    $tag = $open if !defined $tag;
    die "mismatched XML start/end <$open>...<$close>"
	if $close ne $tag;
    print STDERR "tag='$tag', attrs=[$attrs], content='$content'\n";
    die "## no code yet to make DOM node";
}


=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
