package WWW::Webrobot::XHtml;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use WWW::Webrobot::Ext::XHtml::HTTP::Response;


=head1 NAME

WWW::Webrobot::XHtml - enable XHTML and XPath in HTTP::Response

=head1 SYNOPSIS

use WWW::Webrobot::XHtml;

=head1 DESCRIPTION

This module enables XHTML and XPath methods on objects of type HTTP::Response.

=head1 METHODS

Additional methods for HTTP::Response:

=over

=item content_xhtml()

Get HTML resonponse as XML.
Uses lazy evaluation and caches the corresponding attributes.

=item xpath($expression)

Evaluate an XPath $expression for content_xhtml().
Uses lazy evaluation and caches the corresponding attributes.

=back

=cut

1;
