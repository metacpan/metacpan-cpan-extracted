#!/usr/bin/perl -w

# (C) 2004 Identity Commons. All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

use CGI;
use HTML::Entities;
use lib "..";                           # in case XRI isn't installed yet
use XRI;

my $q = new CGI;

my $myurl = $q->url;

# print header and form
#
print $q->header .
    $q->start_html('XRI Resolver GUI') .
    $q->h3('XRI Resolver GUI') .
    $q->start_form . "<p><b>XRI:</b>" .
    $q->textfield(-name=>xri, -default=>'', -override=>1, -size=>50 ) .
    "</p>E.g., try one of these (the second two are synonyms):\n" .
    $q->ul(
           $q->li([
                   $q->a({href=>"$myurl?xri=xri:\@pw*user"},"xri:\@pw*user"),
                   $q->a({href=>"$myurl?xri=xri:(mailto:user\@example.com)*home/quotes"},
                                           "xri:(mailto:user\@example.com)*home/quotes"),
                   $q->a({href=>"$myurl?xri=xri:*home/quotes"},"xri:*home/quotes"),
                   $q->a({href=>"$myurl?xri=xri://yahoo.com"},"xri://yahoo.com"),
                  ])
           ) .
# "<b>HTTP URL of custom Roots XML</b>:" .
#    $q->textfield(rootsurl) . "(optional)<br>" .
    "See the default <a href=\"../XRI/xriroots.xml\">xriroots.xml file</a><br><br>" .
    $q->submit(-name=>Resolve) .
    $q->end_form;

# if SUBMIT, then call Resolver
#
if ($q->param) {
    my ($laxri, $authXML);

    my $xriv = $q->param('xri');

    print "<ol>\n<li>Resolving: <b>$xriv</b></li>\n";

    # FIXME: rootsurl is ignored (so is this call to readRoots)
    #
    if ($q->param('rootsurl')) {
        XRI::readRoots($q->param('rootsurl'));
        print "<li>Successfully loaded new roots file from ",
              $q->param('rootsurl'), "</li>\n";
    }
    else {
        XRI::readRoots('../XRI/xriroots.xml');     # for testing
    }

    my $XRI = XRI->new($xriv);

    eval {
        $laxri   = $XRI->getGetURL;             # this does the work
        $authXML = encode_entities( $XRI->{descriptorXML} );
    };
    if ( $@ =~ /NoLocalAccessFound/ ) {
        print "<li>No Local Access service found for ",
              $q->escapeHTML($xriv), "<\li>\n";
    }
    elsif ( $@ =~ /NoLocalAccessDescriptor/ ) {
        print "<li>No Local Access descriptor found for ",
              $q->escapeHTML($xriv), "<\li>\n";
    }
    elsif ( $@ =~ /UnknownAuthority/ ) {
        print "<li>Cannot determine authority for ",
              $q->escapeHTML($xriv), "<\li>\n";
    }
    elsif ( $@ ) {
        print $@;
    }
    else {
        print "<li>Got Local Access URL: <b><a href=\"$laxri\">$laxri</a></b></li>\n";
        print "<li>XRI Authority Descriptor =<br><pre>$authXML</pre></li>\n" if $authXML;
    }
}

print "</ol>\n" .
    $q->end_html;
