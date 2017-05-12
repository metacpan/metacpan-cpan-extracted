# -*- mode: cperl -*-
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.  
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

#use lib qw(./blib/lib ./blib/arch);

#small package implementing Sablotron message and scheme handler
package SimpleHandler;

use vars qw( $self_ok $code_called $log_called $error_called);

sub new {
    my $class = shift;
    my $self = {a => "aaa"}; #data for test of $self passing
    bless $self, $class;
}

sub MHMakeCode {
    my ($self, $processor, $severity, $facility, $code) = @_;
    $self_ok = $self->{a} eq "aaa";
    $code_called = 1;
}

sub MHLog {
    my ($self, $processor, $code, $level, @fields) = @_;
    $log_called = 1;
}

sub MHError {
    my ($self, $processor, $code, $level, @fields) = @_;
    $error_called = 1;
}


############################################################
# main
package main;

BEGIN 
  { $| = 1; print "1..10\n"; }
END 
  { print "not ok 1\n" unless $loaded; }

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


use XML::Sablotron qw( :all );


$template = <<'eofeof';
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output omit-xml-declaration="yes"/>
<xsl:template match="a"> *** </xsl:template>
</xsl:transform>
eofeof

$template_p = <<'eofeof';
<?xml version="1.0"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output omit-xml-declaration="yes"/>
<xsl:param name="testparam" select="'bad result'"/>
<xsl:template match="a">
<xsl:value-of select="$testparam"/>
</xsl:template>
</xsl:transform>
eofeof

$data = '<?xml version="1.0"?><xml><a/></xml>';

########## simple processstrings test ##########
$c = "--";
$r = ProcessStrings($template, $data, $c);

print ((($c eq " *** \n") && !$r) ? "ok 2\n" : "not ok 2\n");

########## simple process test ##########
$c = "--";
$r = Process("arg:/a", "arg:/b", "arg:/c", 
			      undef, 
			      ["a", $template, "b", $data], $c);

print ((($c eq " *** \n") && !$r) ? "ok 3\n" : "not ok 3\n");

########## process test with param ##########
$c = "--";
$r = Process("arg:/a", "arg:/b", "arg:/c", 
			      ["testparam", " *** "], 
			      ["a", $template_p, "b", $data], $c);

print ((($c eq " *** \n") && !$r) ? "ok 4\n" : "not ok 4\n");

#################
# object tests

########## simple runprocessor test ##########
my $obj = new XML::Sablotron();
$r = $obj->runProcessor("arg:/a", "arg:/b", "arg:/c", 
			undef, ["a", $template, "b", $data]);
$c = $obj->getResultArg("c");

print ((($c eq " *** \n") && !$r) ? "ok 5\n" : "not ok 5\n");


########## message handler test ##########
my $sh = new SimpleHandler();
$obj->regHandler(0, $sh);
$obj->freeResultArgs();
$r = $obj->runProcessor("arg:/a", "arg:/b", "arg:/c", 
  			undef, ["a", $template, "b", $data . "kkk"]);

my $_foo = ($SimpleHandler::code_called and
	    $SimpleHandler::log_called and
	    $SimpleHandler::error_called);
print ($_foo ? "ok 6\n" : "not ok 6\n");


$obj->unregHandler(0, $sh);
undef $sh;

########## "local" methods for handler ##########
my ($code_c, $log_c, $error_c);
sub MHMakeCode {
    my ($self, $processor, $severity, $facility, $code) = @_;
    $code_c = 1;
}

sub MHLog {
    my ($self, $processor, $code, $level, @fields) = @_;
    $log_c = 1;
}

sub MHError {
    my ($self, $processor, $code, $level, @fields) = @_;
    $error_c = 1;
}


$obj->regHandler(0, { MHMakeCode => \&MHMakeCode,
  		      MHLog      => \&MHLog,
  		      MHError    => \&MHError,
  		    });

$r = $obj->runProcessor("arg:/a", "arg:/b", "arg:/c", 
  			undef, ["a", $template, "b", $data . "kkk"]);

print (($code_c and $log_c and $error_c) ? "ok 7\n" : "not ok 7\n");


########## scheme handler test (document() in template ##########

$status = 0;

sub SHOpen {
    my ($self, $processor, $scheme, $rest) = @_;
    $status = 1;
    return $rest;
}

sub SHGetAll {
    my ($self, $processor, $scheme, $rest) = @_;
    return undef;
}

sub SHGet {
    my ($self, $processor, $handle, $size) = @_;
    if ( $status ) {
	$status = 0;
	return "<?xml version='1.0'?><a>***</a>";
    } else {
	return undef;
    }

}

my $buff = "";

sub SHPut {
    my ($self, $processor, $handle, $data) = @_;
    $buff .= $data;
    return 1;
}

sub SHClose {
    my ($self, $processor, $handle) = @_;
}

my $h_xsl = <<'eof';
<?xml version='1.0'?>
<xsl:transform xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
version='1.0'>
<xsl:output omit-xml-declaration='yes'/>
<xsl:template match='/'>
  <xsl:apply-templates select="document('test:/Handler.xml')/*"/>
</xsl:template>
</xsl:transform>
eof

my $h_data = "<?xml version = '1.0'?><a/>";

$obj->regHandler(1, { SHOpen => \&SHOpen,
		      SHGetAll => \&SHGetAll,
		      SHGet => \&SHGet,
		      SHPut => \&SHPut,
		      SHClose => \&SHClose,
		    }
		);

$obj->runProcessor("arg:/a", "arg:/b", "arg:/c", undef, 
		   ["a", $h_xsl, "b", $h_data]);


undef $c;
$c = $obj->getResultArg("c");

print (($c eq "***\n") ? "ok 8\n" : "not ok 8\n");

########## output scheme handler ##########
$obj->runProcessor("arg:/a", "arg:/b", "test:/c", undef, 
		   ["a", $h_xsl, "b", $h_data]);

print (($buff eq "***\n") ? "ok 9\n" : "not ok 9\n");


########## misc handler test - DocumentData ##########
$out_xsl = <<'eof';
<?xml version='1.0'?>
<xsl:transform xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
version='1.0'>
<xsl:output omit-xml-declaration='yes' media-type="text/html"
   encoding="utf-8"/>
</xsl:transform>
eof

my ($ct, $enc);
sub XHDocumentInfo {
    my ($self, $processor, $contentType, $encoding) = @_;
    $ct = $contentType;
    $enc = $encoding;
}

$obj->regHandler(3, { XHDocumentInfo => \&XHDocumentInfo });

$obj->runProcessor("arg:/a", "arg:/b", "arg:/c", undef,
                   ["a", $out_xsl, "b", $data]);


print (($ct eq "text/html" and $enc eq "utf-8") ? "ok 10\n" : "not ok 10\n");

#$obj->freeResultArgs();

undef $obj;

__END__

