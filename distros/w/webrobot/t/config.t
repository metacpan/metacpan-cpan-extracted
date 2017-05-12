#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 9;
use WWW::Webrobot::Properties;


my $properties = <<'EOF';
#load
load.number_of_clients=8
load.base:1.77827941003892
load.scale =  40 
load.output_file  =WEBROBOT_OUT
load.simple value of load.simple
          !comment 1
    # comment 2
#comment 3
names=server=erbse.s3.abas.de
names.1=port=7080
names.2=application=http://erbse.s3.abas.de:7080/troja
names=www=www.abas.de
names=s3www=s3www.abas.de

authentification.basic=,Partner-Website,login=abas,password=po77kal
authentification.basic=|eBusiness-Troja|kunde|sued,west
authentification.basic=/JDMK/admin/grizzly/

output=WWW::Webrobot::Print::Test
output=WWW::Webrobot::Print::Html
output=WWW::Webrobot::Print::File 'dir' => 'diff_new', 'diff_mode' => 'diff_orig'

mail.Data=zeile 1\n\
zeile 2 des body\n\
zeile 3\n
EOF


MAIN: {

my $properties0 = <<'EOF'; # note blank characters at end of line
number_of_clients=8
base:1.77827941003892

output_file  =WEBROBOT_OUT
simple value of simple
          !comment 1
    # comment 2
EOF
    is_deeply(
        WWW::Webrobot::Properties->new()->load_string($properties0),
        {
            'base' => '1.77827941003892',
            'number_of_clients' => '8',
            'output_file' => 'WEBROBOT_OUT',
            'simple' => 'value of simple',
        },
        "Simple properties file"
    );

my $properties1 = <<'EOF'; # note blank characters at end of line
scale1=40 
scale2=40  
scale3=40   
scale4=40\ 
scale5=40\  
scale6=40\   
EOF
    is_deeply(
        WWW::Webrobot::Properties->new()->load_string($properties1),
        {
            'scale1' => '40',
            'scale2' => '40',
            'scale3' => '40',
            'scale4' => '40 ',
            'scale5' => '40 ',
            'scale6' => '40 ',
        },
        "Values followed by blanks"
    );

my $properties2 = <<'EOF';
names = opt1 = value1
names : opt2= value2
names : opt3   =value2
EOF

    is_deeply(
        WWW::Webrobot::Properties -> new(key_value => [qw(names)]) ->
              load_string($properties2),
        {
            'names' => [
                ['opt1', 'value1'],
                ['opt2', 'value2'],
                ['opt3', 'value2'],
            ]
        },
        "Blanks separating key/value pairs in value of property"
    );

    is_deeply(
        WWW::Webrobot::Properties->new(key_value => [qw/name/]) ->
                              load_string('name = opt1 = \ value_blank\ ' . "\n"),
        {
            'name' => [
                ['opt1', ' value_blank '],
            ]
        },
        "Blanks in Values"
    );

    my $config1 = WWW::Webrobot::Properties->new();
    my $cfg1 = $config1->load_string($properties);
    is_deeply($cfg1, {
          'names' => 's3www=s3www.abas.de',
          'names.1' => 'port=7080',
          'names.2' => 'application=http://erbse.s3.abas.de:7080/troja',
          'load.number_of_clients' => '8',
          'load.simple' => 'value of load.simple',
          'authentification.basic' => '/JDMK/admin/grizzly/',
          'output' => 'WWW::Webrobot::Print::File \'dir\' => \'diff_new\', \'diff_mode\' => \'diff_orig\'',
          'load.base' => '1.77827941003892',
          'load.output_file' => 'WEBROBOT_OUT',
          'load.scale' => '40',
          'mail.Data' => "zeile 1\nzeile 2 des body\nzeile 3\n",
        }, "Now more complex properties"
    );

    my $config2 = WWW::Webrobot::Properties->new(
        listmode => [qw(names authentification.basic output)]
    );
    my $cfg2 = $config2->load_string($properties);
    is_deeply($cfg2, {
        'mail.Data' => "zeile 1\nzeile 2 des body\nzeile 3\n",
        'load.number_of_clients' => '8',
        'names' => [
            'server=erbse.s3.abas.de',
            'port=7080',
            'application=http://erbse.s3.abas.de:7080/troja',
            'www=www.abas.de',
            's3www=s3www.abas.de'
        ],
        'load.simple' => 'value of load.simple',
        'authentification.basic' => [
            ',Partner-Website,login=abas,password=po77kal',
            '|eBusiness-Troja|kunde|sued,west',
            '/JDMK/admin/grizzly/'
        ],
        'output' => [
            'WWW::Webrobot::Print::Test',
            'WWW::Webrobot::Print::Html',
            'WWW::Webrobot::Print::File \'dir\' => \'diff_new\', \'diff_mode\' => \'diff_orig\''
        ],
        'load.base' => '1.77827941003892',
        'load.output_file' => 'WEBROBOT_OUT',
        'load.scale' => '40'
    }, "dito. in 'listmode'");

    my $config3 = WWW::Webrobot::Properties->new(
        listmode => [qw(names authentification.basic output)],
        key_value => [qw(names)],
        multi_value => [qw(authentification.basic)],
    );
    my $cfg3 = $config3->load_string($properties);
    is_deeply($cfg3, {
        'mail.Data' => "zeile 1\nzeile 2 des body\nzeile 3\n",
        'load.number_of_clients' => '8',
        'names' => [
            ['server', 'erbse.s3.abas.de'],
            ['port', '7080'],
            ['application', 'http://erbse.s3.abas.de:7080/troja'],
            ['www', 'www.abas.de'],
            ['s3www', 's3www.abas.de'],
        ],
        'load.simple' => 'value of load.simple',
        'authentification.basic' => [
            [
                'Partner-Website',
                'login=abas',
                'password=po77kal'
            ],
            [
                'eBusiness-Troja',
                'kunde',
                'sued,west'
            ],
            [
                'JDMK',
                'admin',
                'grizzly'
            ]
        ],
        'output' => [
            'WWW::Webrobot::Print::Test',
            'WWW::Webrobot::Print::Html',
            'WWW::Webrobot::Print::File \'dir\' => \'diff_new\', \'diff_mode\' => \'diff_orig\''
        ],
        'load.base' => '1.77827941003892',
        'load.output_file' => 'WEBROBOT_OUT',
        'load.scale' => '40',
    }, "dito with values containing key/value and lists");


    my $result4 = {
        'mail.Data' => "zeile 1\nzeile 2 des body\nzeile 3\n",
        'names' => [
            ['server', 'erbse.s3.abas.de'],
            ['port', '7080'],
            ['application', 'http://erbse.s3.abas.de:7080/troja'],
            ['www', 'www.abas.de'],
            ['s3www', 's3www.abas.de'],
        ],
        'authentification.basic' => [
            [
                'Partner-Website',
                'login=abas',
                'password=po77kal'
            ],
            [
                'eBusiness-Troja',
                'kunde',
                'sued,west'
            ],
            [
                'JDMK',
                'admin',
                'grizzly'
            ]
        ],
        'output' => [
            'WWW::Webrobot::Print::Test',
            'WWW::Webrobot::Print::Html',
            'WWW::Webrobot::Print::File \'dir\' => \'diff_new\', \'diff_mode\' => \'diff_orig\''
        ],
        'load' => {
            'base' => '1.77827941003892',
            'number_of_clients' => '8',
            'output_file' => 'WEBROBOT_OUT',
            'simple' => 'value of load.simple',
            'scale' => '40'
        }
    };
    my %options = (
        listmode => [qw(names authentification.basic output)],
        key_value => [qw(names)],
        multi_value => [qw(authentification.basic)],
        structurize => [qw(load)],
    );
    my $config4 = WWW::Webrobot::Properties->new(%options);
    my $cfg4 = $config4->load_string($properties);
    is_deeply($cfg4, $result4, "dito with structurized keys");

    my $filename = "tmp";
    open FILE, ">$filename" or die "Can't open file '$filename' $!";
    print FILE $properties;
    close FILE;
    my $config5 = WWW::Webrobot::Properties->new(%options);
    my $cfg5 = $config4->load_file($filename);
    is_deeply($cfg5, $result4, "dito read from file");

}

1;
