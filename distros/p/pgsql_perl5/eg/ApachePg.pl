#!/usr/local/bin/perl

# $Id: ApachePg.pl,v 1.8 2000/04/04 19:20:02 mergl Exp $

# don't forget to create in postgres the user who is running 
# the httpd, eg 'createuser nobody' !
# 
# demo script, tested with:
#  - postgresql-7.0
#  - apache_1.3.12
#  - mod_perl-1.22
#  - perl5.6.0

use CGI;
use Pg;
use strict;

my $query = new CGI;

print  $query->header,
       $query->start_html(-title=>'A Simple Example'),
       $query->startform,
       "<CENTER><H3>Testing Module Pg</H3></CENTER>",
       "<P><CENTER><TABLE CELLPADDING=4 CELLSPACING=2 BORDER=1>",
       "<TR><TD>Enter conninfo string: </TD>",
           "<TD>", $query->textfield(-name=>'conninfo', -size=>40, -default=>'dbname=template1'), "</TD>",
       "</TR>",
       "<TR><TD>Enter select command: </TD>",
           "<TD>", $query->textfield(-name=>'cmd', -size=>40), "</TD>",
       "</TR>",
       "</TABLE></CENTER><P>",
       "<CENTER>", $query->submit(-value=>'Submit'), "</CENTER>",
       $query->endform;

if ($query->param) {

    my $conninfo = $query->param('conninfo');
    my $conn = Pg::connectdb($conninfo);
    if (PGRES_CONNECTION_OK == $conn->status) {
        my $cmd = $query->param('cmd');
        my $result = $conn->exec($cmd);
        if (PGRES_TUPLES_OK == $result->resultStatus) {
            print "<P><CENTER><TABLE CELLPADDING=4 CELLSPACING=2 BORDER=1>\n";
            my @row;
            while (@row = $result->fetchrow) {
                print "<TR><TD>", join("</TD><TD>", @row), "</TD></TR>";
            }
            print "</TABLE></CENTER><P>\n";
        } else {
            print "<CENTER><H2>", $conn->errorMessage, "</H2></CENTER>\n";
        }
    } else {
        print "<CENTER><H2>", $conn->errorMessage, "</H2></CENTER>\n";
    }
}

print $query->end_html;

