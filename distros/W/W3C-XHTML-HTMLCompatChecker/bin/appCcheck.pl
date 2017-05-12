#!/usr/bin/perl
# Copyright (c) 2005-2008 W3C


use strict;
use warnings;

use CGI qw(param);
require LWP::UserAgent;
use URI;
use CGI::Carp 'fatalsToBrowser';
use HTML::Template       2.6  qw();
use W3C::XHTML::HTMLCompatChecker;

# Define global constants
use constant TRUE  => 1;
use constant FALSE => 0;


## Output routines ########################################################
sub prep_output {
    my $output_param = shift;
    my $html_output_template_text = CGI::header(). '
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>W3C HTML Compatibility Checker for HTML</title>
<style type="text/css" media="all">
  @import "http://validator.w3.org/style/base.css";
  p.submit_button { margin-top: 1em; }
</style>

</head>
<body>
   <div id="banner">
    <h1 id="title">
      <a href="http://www.w3.org/"><img alt="W3C" width="110" height="61" id="logo" src="http://validator.w3.org/images/w3c.png" /></a>
			<a href="./"><span>HTML Compatibility Checker for HTML</span></a>
      </h1>
      <p id="tagline">Check XHTML documents against HTML compatibility guidelines</p>
   </div>




<div id="frontforms">
<ul id="tabset_tabs">
	<li class="selected"><a href="#validate-by-uri"><span>Check online</span> document</a></li>
</ul>
   <div id="fields">

<fieldset id="validate-by-uri" class="tabset_content front">
<form method="get" action="">
<p>
	<label title="Address of page to Validate" for="uri">Address:</label>
     <input type="text" name="uri" id="uri" size="60" <TMPL_IF NAME="uri">value="<TMPL_VAR NAME="uri" ESCAPE="HTML">"</TMPL_IF>/>
</p>
<p class="submit_button"><input  title="Submit for validation" type="submit" value="Check" />
</p>


</fieldset>
</form>
</div>

<dl>
<TMPL_LOOP NAME="message_loop">
    <dt><strong><TMPL_VAR NAME="severity" ESCAPE="HTML"></strong> Line <TMPL_VAR NAME="line" ESCAPE="HTML"> column <TMPL_VAR NAME="column" ESCAPE="HTML"></dt>
    <dd><a href="http://www.w3.org/TR/xhtml1/#C_<TMPL_VAR NAME="cnum" ESCAPE="HTML">"><TMPL_VAR NAME="message_text" ESCAPE="HTML"></a></dd>
</TMPL_LOOP>
</dl>

<TMPL_UNLESS NAME="uri"><p>Enter the URI of an XHTML 1.0 document which you would like to check against the 
<a href="http://www.w3.org/TR/xhtml1/#guidelines">HTML Compatibility Guidelines</a> .</p></TMPL_UNLESS>

<TMPL_UNLESS NAME="has_messages"><TMPL_IF NAME="uri"><p>No issue found in this document. Congratulations.</p></TMPL_IF></TMPL_UNLESS>

<TMPL_IF NAME="Abort">
<p>The document was not checked against HTML Compatibility Guidelines.  
Reason: <em><TMPL_VAR NAME="Abort_Message"></em>.
</p>
</TMPL_IF>

</div>

</body>
</html>
';

    my $html_output = HTML::Template->new_scalar_ref(\$html_output_template_text, 
        die_on_bad_params => FALSE,
        loop_context_vars => TRUE,
        );


    my $xml_output_template_text = 'Content-Type: text/xml; charset=UTF-8

<?xml version="1.0" encoding="UTF-8"?><observationresponse xmlns="http://www.w3.org/unicorn/observationresponse"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="http://www.w3.org/QA/2006/obs_framework/ns/observation/  http://www.w3.org/QA/2006/obs_framework/response/observer-response.xsd">
<uri><TMPL_VAR NAME="uri" ESCAPE="HTML"></uri>
<passed><TMPL_IF NAME="passed">true<TMPL_ELSE>false</TMPL_IF></passed>
<result>
<errors>
  <errorcount><TMPL_VAR NAME="error_count" ESCAPE="HTML"></errorcount>
  <errorlist>
      <uri><TMPL_VAR NAME="uri" ESCAPE="HTML"></uri>
      <TMPL_LOOP NAME="error_loop">
      <error>
              <line><TMPL_VAR NAME="line" ESCAPE="HTML"></line>
              <column><TMPL_VAR NAME="column" ESCAPE="HTML"></column>
              <message><TMPL_VAR NAME="message_text" ESCAPE="HTML"></message>
              <longmessage>See HTML Compatibility Guideline <TMPL_VAR NAME="cnum" ESCAPE="HTML">:
	      <a href="http://www.w3.org/TR/xhtml1/#C_<TMPL_VAR NAME="cnum" ESCAPE="HTML">"><TMPL_VAR NAME="guideline_title" ESCAPE="HTML"></a></longmessage>
      </error>
      </TMPL_LOOP>
  </errorlist>
</errors>
<warnings>
  <warningcount><TMPL_VAR NAME="warning_count" ESCAPE="HTML"></warningcount>
  <warninglist>
      <uri><TMPL_VAR NAME="uri" ESCAPE="HTML"></uri>
      <TMPL_LOOP NAME="warning_loop">
      <warning>
              <line><TMPL_VAR NAME="line" ESCAPE="HTML"></line>
              <column><TMPL_VAR NAME="column" ESCAPE="HTML"></column>
              <message><TMPL_VAR NAME="message_text" ESCAPE="HTML"></message>
              <longmessage>See HTML Compatibility Guideline <TMPL_VAR NAME="cnum" ESCAPE="HTML">:
	      <a href="http://www.w3.org/TR/xhtml1/#C_<TMPL_VAR NAME="cnum" ESCAPE="HTML">"><TMPL_VAR NAME="guideline_title" ESCAPE="HTML"></a></longmessage>
      </warning>
      </TMPL_LOOP>
  </warninglist>
</warnings>
<informations>
  <infocount><TMPL_VAR NAME="info_count" ESCAPE="HTML"></infocount>
  <infolist>
      <uri><TMPL_VAR NAME="uri" ESCAPE="HTML"></uri>
      <TMPL_LOOP NAME="info_loop">
      <info>
              <line><TMPL_VAR NAME="line" ESCAPE="HTML"></line>
              <column><TMPL_VAR NAME="column" ESCAPE="HTML"></column>
              <message><TMPL_VAR NAME="message_text" ESCAPE="HTML"></message>
              <longmessage>See HTML Compatibility Guideline <TMPL_VAR NAME="cnum" ESCAPE="HTML">:
	      <a href="http://www.w3.org/TR/xhtml1/#C_<TMPL_VAR NAME="cnum" ESCAPE="HTML">"><TMPL_VAR NAME="guideline_title" ESCAPE="HTML"></a></longmessage>
      </info>
      </TMPL_LOOP>
      <TMPL_UNLESS NAME="is_wf">
      <info>
              <message>The document appears to not be well-formed XML. Either it is not XHTML (e.g HTML up to version 4.01) or it has XML well-formedness errors. 
              HTML Compatibility guidelines checking does not apply.</message>
      </info>
      </TMPL_UNLESS>
  </infolist>
</informations>
</result>
</observationresponse>
';

    my $xml_output = HTML::Template->new_scalar_ref(\$xml_output_template_text, 
        die_on_bad_params => FALSE,
        loop_context_vars => TRUE,
        );

    if ($output_param eq "html") {
        return $html_output;
    }
    else {
        return $xml_output;
    }
}

## Main ###################################################################

my $uri = param('uri'); # "http://www.w3.org/TR/xhtml1/";
my $output_param = "html";
if (defined param('output'))
{
	$output_param = param('output');
	if ($output_param ne "html" and $output_param ne "xml") {
		$output_param = "html";
	}
}

my $debug = 0;

if (defined param('debug'))
{
        $debug = param('debug');
}

my $output = &prep_output($output_param);
## output defaults 
$output->param(passed => 1);
$output->param(info_count => 0);                               
$output->param(warning_count => 0);                         
$output->param(error_count => 0);
$output->param(Abort=>0);
$output->param(has_messages=>0);


my $compat_parser =  W3C::XHTML::HTMLCompatChecker->new();
if ($uri){
    my @checker_messages = $compat_parser->check_uri($uri);
    if (exists $checker_messages[0]) {
        $output->param(has_messages=>1);
         if ($checker_messages[0]{"severity"} eq "Abort"){
            if ($checker_messages[0]{"message_text"} ne "Bad URI") { $output->param(uri => $uri);}
            $output->param(Abort=>1);
            $output->param(Abort_Message=>$checker_messages[0]{"message_text"});
        }
        else {
            $output->param(uri => $uri);
            $output->param(message_loop => \@checker_messages);
            my (@ERRORS, @WARNINGS, @INFOS);
            for (my $i=0; $i < scalar @checker_messages; $i++)
            {
                    if ($checker_messages[$i]{'severity'} eq "Error") {	push @ERRORS, $checker_messages[$i];}
                    elsif ($checker_messages[$i]{'severity'} eq "Warning") {push @WARNINGS, $checker_messages[$i];}
                    else {push @INFOS, $checker_messages[$i];}
            }
            if (@ERRORS) {$output->param(passed => 0) } else {$output->param(passed => 1)}
            $output->param(info_loop => \@INFOS);
            $output->param(info_count => scalar @INFOS);
            $output->param(warning_loop => \@WARNINGS);
            $output->param(warning_count => scalar @WARNINGS);
            $output->param(error_loop => \@ERRORS);
            $output->param(error_count => scalar @ERRORS);
        
        }
    } else {
        $output->param(uri => $uri);
    } 
}
print $output->output();


__END__
