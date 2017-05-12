package XML::IODEF::Simple;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.02';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

require XML::IODEF;
use Module::Pluggable require => 1;

# Preloaded methods go here.

sub new {
    my ($class,$info) = @_;
    
    my $description                 = lc($info->{'description'}) || 'unknown';
    my $confidence                  = $info->{'confidence'};
    my $severity                    = $info->{'severity'};
    my $source                      = $info->{'source'} || 'localhost';
    my $relatedid                   = $info->{'relatedid'};
    my $alternativeid               = $info->{'alternativeid'};
    my $alternativeid_restriction   = $info->{'alternativeid_restriction'} || 'private';
    my $purpose                     = $info->{'purpose'} || 'mitigation';
    my $reporttime                  = $info->{'reporttime'};
    my $lang                        = $info->{'lang'} || $info->{'language'} || 'EN';

    my $dt = $info->{'detecttime'};
    # default it to the hour
    unless($dt){
        require DateTime;
        $dt = DateTime->from_epoch(epoch => time());
        $dt = $dt->ymd().'T'.$dt->hour().':00:00Z';
    }
    if($dt =~ /^(\d{4})(\d{2})(\d{2})$/){
        $dt = $1.'-'.$2.'-'.$3.'T00:00:00Z';
    }
    $info->{'detecttime'} = $dt;

    unless($reporttime){
        require DateTime;
        $reporttime = DateTime->from_epoch(epoch => time());
        $reporttime = $reporttime->ymd().'T00:00:00Z';
    }
    if($reporttime =~ /^(\d{4})(\d{2})(\d{2})$/){
        $reporttime = $1.'-'.$2.'-'.$3.'T00:00:00Z';
    }

    my $iodef = XML::IODEF->new();
    $iodef->add('Incidentlang',$lang);
    $iodef->add('Incidentpurpose',$purpose);
    foreach($class->plugins()){
        if($_->prepare($info)){
            $iodef = $_->convert($info,$iodef);
        }
    }

    if($info->{'IncidentID'}){
        my $xid = $info->{'IncidentID'};
        $iodef->add('IncidentIncidentIDrestriction',$xid->{'restriction'}) if($xid->{'restriction'});
        $iodef->add('IncidentIncidentIDname',$xid->{'name'}) if($xid->{'name'});
        $iodef->add('IncidentIncidentIDinstance',$xid->{'instance'}) if($xid->{'instance'});
        $iodef->add('IncidentIncidentID',$xid->{'content'}) if($xid->{'content'});
    } else {
        $iodef->add('IncidentIncidentIDname',$source) if($source);
    }
    $iodef->add('IncidentReportTime',$reporttime) if($reporttime);
    $iodef->add('IncidentDetectTime',$dt) if($dt);
    $iodef->add('IncidentRelatedActivityIncidentID',$relatedid) if($relatedid);
    if($alternativeid){
        $iodef->add('IncidentAlternativeIDIncidentID',$alternativeid);
        $iodef->add('IncidentAlternativeIDIncidentIDrestriction',$alternativeid_restriction);
    }
    $iodef->add('Incidentrestriction',$info->{'restriction'} || 'private');
    $iodef->add('IncidentDescription',$description) if($description);
    if($confidence){
        $iodef->add('IncidentAssessmentConfidencerating','numeric');
        $iodef->add('IncidentAssessmentConfidence',$confidence);
    }
    my $impact = $info->{'impact'};
    $iodef->add('IncidentAssessmentImpact',$impact) if($impact && !$iodef->get('IncidentAssessmentImpact'));

    if(!$iodef->get('IncidentAssessmentImpactseverity') && $severity && $severity =~ /(low|medium|high)/){
        warn 'adding sev';
        $iodef->add('IncidentAssessmentImpactseverity',$severity);
    }

    return $iodef;
}


1;
__END__
=head1 NAME

XML::IODEF::Simple - Perl extension for easier IODEF message generation

=head1 SYNOPSIS

  use XML::IODEF::Simple;
  my $report = XML::IODEF::Simple->new({
        guid        => 'mygroup.example.com',
        source      => 'example.com',
        restriction => 'need-to-know',
        description => 'spyeye',
        impact      => 'botnet',
        address     => '1.2.3.4',
        protocol    => 'tcp',
        portlist    => '8080',
        contact     => {
            name        => 'root',
            email       => 'root@localhost',
        },
        purpose                     => 'mitigation',
        confidence                  => '85',
        alternativeid               => 'https://example.com/rt/Ticket/Display.html?id=1234',
        alternativeid_restriction   => 'private',
        sharewith                   => 'partners.example.com,leo.example.com', 
    });
    my $xml = $report->out(); 
    my $hash = $report->to_tree();

    # generates
    <?xml version="1.0" encoding="UTF-8"?>
    <IODEF-Document version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xmls:schema:iodef-1.0"><Incident purpose="mitigation" restriction="need-to-know"><IncidentID name="example.com"/><AlternativeID><IncidentID restriction="private">https://example.com/rt/Ticket/Display.html?id=1234</IncidentID></AlternativeID><DetectTime>2011-10-24T13:00:00Z</DetectTime><Description>spyeye</Description><Assessment><Impact severity="high">botnet</Impact><Confidence rating="numeric">85</Confidence></Assessment><Contact type="person" role="creator"><ContactName>root</ContactName><Email>root@localhost</Email></Contact><EventData><Flow><System><Node><Address category="ipv4-addr">1.2.3.4</Address></Node><Service ip_protocol="6"><Portlist>8080</Portlist></Service></System></Flow></EventData><AdditionalData dtype="string" meaning="guid">mygroup.example.com</AdditionalData><AdditionalData dtype="string" meaning="sharewith">leo.example.com</AdditionalData><AdditionalData dtype="string" meaning="sharewith">partners.example.com</AdditionalData></Incident></IODEF-Document>

=head1 DESCRIPTION

This module makes it a bit simpler to crank out XML+IODEF messages. It uses what it finds under XML/IODEF/Simple/Plugin/ to adapt "defaults" to the keypairs it takes in. To allow for other default settings / manipulations, create XML::IODEF::Simple::Plugin::MyPlugin and Module::Pluggable will pick it up on the fly. See XML::IODEF::Simple::Plugin::Ipv4 as an example.

This module takes into account some of the work done with the Collective Intelligence Framework. It makes assumptions about severity based on the impact given. Up to date documentation surrounding this taxonomy can be found at http://code.google.com/p/collective-intelligence-framework/wiki/Taxonomy

=head1 Addons

To enhance the exchange of XML::IODEF based messages, the 'sharewith' and 'guid' tags have been added to IncidentAdditionalData

=head2 sharewith

A comma-seperated or array value that denotes what other federations a derivative of this message may be shared with. These are usually denoted by a FQDN:
  grp1.example.com
  grp2.example.com
  leo.example.com

=head2 guid

A simple FQDN used (in CIF) as a unix-style permission that denotes what groups within a federation can have access to this data. Groups are simple strings, in this example we use FQDN's to ensure unique-ness throughout a federation. Typically groups are hashed into v5 uuid's behind the scenes.

=head1 EXAMPLES

=head2 Botnet

Typically a high-severity observation

=head2 Malware / Exploit

Typically a medium-severity observation

=head2 Phishing

Typically a medium-severity observation

=head2 Highjacked

Typcially a medium-severity observation

=head1 PLUGINS

This module can be extended at run-time by adding plugins under XML::IODEF::Simple::Plugin (eg: XML::IODEF::Simple::Plugin::MyPlug). See the lib/XML/IODEF/Simple/Plugin directory or XML::IODEF::Simple::Plugin::TLP for more examples.

=head1 SEE ALSO

XML::IODEF, http://code.google.com/p/collective-intelligence-framework/

=head1 AUTHOR

Wes Young, E<lt>wes@barely3am.comE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright 2011 The Trustees of Indiana University, indiana.edu
 Copyright 2011 REN-ISAC, ren-isac.net
 Copyright 2011 Wes Young, claimid.com/wesyoung

 This library is free software; you can redistribute it and/or modify
 it under the same terms as Perl itself, either Perl version 5.10.0 or,
 at your option, any later version of Perl 5 you may have available.


=cut
