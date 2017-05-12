package setup;

use strict;
use warnings;
use WWW::SFDC;

our $skip;

our $TYPES = {
    'email' => {
        'suffix' => 'email',
        'directoryName' => 'email',
        'inFolder' => 'true',
        'xmlName' => 'EmailTemplate',
        'metaFile' => 'true'
    },
    'documents' => {
        'inFolder' => 'true',
        'directoryName' => 'documents',
        'metaFile' => 'true',
        'xmlName' => 'Document'
    },
    'quickActions' => {
        'inFolder' => 'false',
        'directoryName' => 'quickActions',
        'suffix' => 'quickAction',
        'metaFile' => 'false',
        'xmlName' => 'QuickAction'
    },
    'classes' => {
        'xmlName' => 'ApexClass',
        'metaFile' => 'true',
        'suffix' => 'cls',
        'directoryName' => 'classes',
        'inFolder' => 'false'
    },
    'objects' => {
        'xmlName' => 'CustomObject',
        'metaFile' => 'false',
        'suffix' => 'object',
        'childXmlNames' => [
            'CustomField',
            'BusinessProcess',
            'CompactLayout',
            'RecordType',
            'WebLink',
            'ValidationRule',
            'SharingReason',
            'ListView',
            'FieldSet'
        ],
        'directoryName' => 'objects',
        'inFolder' => 'false'
    },
    'triggers' => {
        'xmlName' => 'ApexTrigger',
        'metaFile' => 'true',
        'suffix' => 'trigger',
        'inFolder' => 'false',
        'directoryName' => 'triggers'
    },
    'reports' => {
        'suffix' => 'report',
        'inFolder' => 'true',
        'directoryName' => 'reports',
        'xmlName' => 'Report',
        'metaFile' => 'false'
    },
    'staticresources' => {
        'metaFile' => 'true',
        'xmlName' => 'StaticResource',
        'directoryName' => 'staticresources',
        'inFolder' => 'false',
        'suffix' => 'resource'
    },
};

sub client {
    unless (-e "t/test.config") {
        $skip = "No t/test.config file found";
        return;
    }

    my $options = Config::Properties
        ->new(file => "t/test.config")
        ->splitToTree();

    unless (
        $options->{username}
        and $options->{password}
        and $options->{url}
    ) {
        $skip = "Missing credentials in t/test.config";
        return;
    }

    return WWW::SFDC->new(creds => {
        username => $options->{username},
        password => $options->{password},
        url => $options->{url},
    });

}

1;
