package XML::Directory::Apache;

require 5.005_03;
BEGIN { require warnings if $] >= 5.006; }

use strict;
use XML::Directory::String;
use Apache::Constants qw(:common );


sub handler {
    my $r = shift;
    my %query = $r->args;
    my $path = $r->path_info;
    my $dets = 2;
    my $depth = 1000;
    my $ret;

    $dets = $query{dets} if $query{dets};
    $depth = $query{depth} if $query{depth};

    if ($path) {

	my $dir = new XML::Directory::String($path,$dets,$depth);
	$dir->enable_ns if $query{ns} == 1;
	$dir->error_treatment('warn');
	my $rc  = $dir->parse;
	$ret = $dir->get_string;

    } else {

	my $dir = new XML::Directory;
	$dir->enable_ns if $query{ns} == 1;
	my $ns = $dir->get_ns_data;

	my $pref = '';
	my $decl = '';
	if ($ns->{enabled}) {
	    if ($ns->{prefix}) {
		$pref = "$ns->{prefix}:";
		$decl = " xmlns:$ns->{prefix}=\"$ns->{uri}\"";
	    } else {
		$decl = " xmlns=\"$ns->{uri}\"";
	    }
	}

	$ret .= "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
	$ret .= "<$pref" . 'dirtree' . "$decl>\n";
	$ret .= "<$pref" 
	  . "error number=\"100\">Path not defined!</$pref" . "error>\n";
	$ret .= "</$pref" . "dirtree>\n";
    }

    $r->status(OK);
    $r->content_type("text/xml");
    $r->no_cache(1);
    $r->send_http_header();
    $r->print($ret);


    return OK;
}

1;

__END__
# Below is a documentation.

=head1 NAME

XML::Directory::Apache - mod_perl wrapper over XML::Directory

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz

=head1 SEE ALSO

XML::Directory, perl(1).

=cut
