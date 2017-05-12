#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::XSD::Parser;
use XML::LibXML;

my $dir = path($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->child('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
# create the parser object
my $parser = W3C::SOAP::XSD::Parser->new(
    location      => $dir->child('elementFormDefault-qualified.xsd').'',
    template      => $template,
    lib           => $dir->child('lib').'',
    ns_module_map => {},
    module_base   => 'ElementFormDefault',
);

my (@classes) = sort eval { $parser->dynamic_classes };
ok !$@, "Create dynamic classes correctly"
    or BAIL_OUT($@);

dynamic_modules(@classes);
done_testing();
exit;

sub dynamic_modules {
    my ($qual, $unqual) = @_;

    my $unobject = $unqual->new(
        process_record => {
            base           => 'TEST',
            timestamp      => '2013-08-26T00:00:00',
            correlation_id => '1234',
            billing_id     => '4321',
        }
    );

    ok $unobject, 'Get a new unobject';
    ok $unobject->process_record, 'Currectly set element';
    is $unobject->process_record->base, 'TEST', 'Currectly set element';

    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
XML

    my ($xml_str) = $unobject->to_xml($xml);
    note $xml_str;
    like $xml_str, qr/<base>/, 'The base attribute has no namespace prefix';

    my ($body) = $xml->findnodes('//soapenv:Body');
    $body->appendChild($xml_str);
    my $new_unobject = eval { $unqual->new($body) };
    my $e = $@;
    ok !$e, 'No errors in trying to reconstruct object from XML'
        or diag $e;
    is_deeply eval { $new_unobject->to_data } || undef, $unobject->to_data, 'New data the same as old data';

    eval {
        my $object = $qual->new(
            re_process_record => {
                base           => 'TEST',
                timestamp      => '2013-08-26T00:00:00',
                correlation_id => '1234',
                billing_id     => '4321',
            }
        );

        ok $object, 'Get a new object';
        ok $object->re_process_record, 'Currectly set element';
        is $object->re_process_record->base, 'TEST', 'Currectly set parent base element';
        is $object->re_process_record->billing_id, '4321', 'Currectly set this base element';

        my ($xml_str) = $object->to_xml($xml);
        note $xml_str;
        like $xml_str, qr/<base>/, 'The base attribute has no namespace prefix';
        like $xml_str, qr/<\w+:billingId>/, 'The billingId attribute has a namespace prefix';

        my ($body) = $xml->findnodes('//soapenv:Body');
        $body->removeChild($body->firstChild);
        $body->appendChild($xml_str);
        my $new_object = eval { $qual->new($body) };
        my $e = $@;
        ok !$e, 'No errors in trying to reconstruct object from XML'
            or diag $e;
        is_deeply eval { $new_object->to_data } || undef, $object->to_data, 'New data the same as old data';

    };
    $e = $@;
    ok !$e, 'No errors parsing complex content value';
    diag $e;
}

