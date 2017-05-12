package main;
use Modern::Perl;
use MARC::MIR::Template;
use Test::More 'no_plan';
use YAML ();

my ($spec,$data,$expected) = YAML::Load << 'END';
001: id
200: [ authors, { a: name, b: firstname } ]
300: { a: title, b: subtitle }
700: [ auth_author, { a: name, b: firstname } ]
701: [ auth_author, { a: name, b: firstname } ]
---
authors:
    - { name: Doe, firstname: [john, elias, frederik] }
    - { name: Doe, firstname: jane }
title: "i can haz title"
subtitle: "also subs"
id: PPNxxxx
---
- [001, PPNxxxx ]
- [200, [ [a, Doe], [b, john], [b, elias], [b, frederik] ]]
- [200, [ [a, Doe], [b, jane]                            ]]
- [300, [ [a, "i can haz title"], [b, "also subs"]       ]]
END

my $template = MARC::MIR::Template->new( $spec );
ok( $template->isa('MARC::MIR::Template'),"constructor works");
my $got = $template->data( $data );
is_deeply ( $got, $expected , "data ready for MARC::MIR" );
my $back = $template->mir( $got ); 
# say YAML::Dump $back, $data;
is_deeply ( $back, $data , "mir ready for MARC::MIR" );
