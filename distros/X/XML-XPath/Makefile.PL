#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'XML::XPath',
    AUTHOR             => 'Matt Sergeant, AxKit.com Ltd',
    VERSION_FROM       => 'lib/XML/XPath.pm',
    ABSTRACT_FROM      => 'lib/XML/XPath.pm',
    MIN_PERL_VERSION   => 5.006,
    LICENSE            => 'artistic_2',
    EXE_FILES          => [ 'examples/xpath' ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES     => {
        'Test::More'   => 0,
        'Path::Tiny'   => '0.076',
    },
    PREREQ_PM => {
        'XML::Parser'  => '2.23',
        'Scalar::Util' => '1.45',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-XPath-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'XML::XPath'                      => { file => 'lib/XML/XPath.pm',                version => '1.44' },
            'XML::XPath::XMLParser'           => { file => 'lib/XML/XPath/XMLParser.pm',      version => '1.44' },
            'XML::XPath::Parser'              => { file => 'lib/XML/XPath/Parser.pm',         version => '1.44' },
            'XML::XPath::Expr'                => { file => 'lib/XML/XPath/Expr.pm',           version => '1.44' },
            'XML::XPath::Function'            => { file => 'lib/XML/XPath/Function.pm',       version => '1.44' },
            'XML::XPath::Literal'             => { file => 'lib/XML/XPath/Literal.pm',        version => '1.44' },
            'XML::XPath::LocationPath'        => { file => 'lib/XML/XPath/LocationPath.pm',   version => '1.44' },
            'XML::XPath::Number'              => { file => 'lib/XML/XPath/Number.pm',         version => '1.44' },
            'XML::XPath::Node'                => { file => 'lib/XML/XPath/Node.pm',           version => '1.44' },
            'XML::XPath::Node::Element'       => { file => 'lib/XML/XPath/Node/Element.pm',   version => '1.44' },
            'XML::XPath::Node::Attribute'     => { file => 'lib/XML/XPath/Node/Attribute.pm', version => '1.44' },
            'XML::XPath::Node::AttributeImpl' => { file => 'lib/XML/XPath/Node/Attribute.pm', version => '1.44' },
            'XML::XPath::Node::Text'          => { file => 'lib/XML/XPath/Node/Text.pm',      version => '1.44' },
            'XML::XPath::Node::Namespace'     => { file => 'lib/XML/XPath/Node/Namespace.pm', version => '1.44' },
            'XML::XPath::Node::PI'            => { file => 'lib/XML/XPath/Node/PI.pm',        version => '1.44' },
            'XML::XPath::Node::Comment'       => { file => 'lib/XML/XPath/Node/Comment.pm',   version => '1.44' },
            'XML::XPath::Step'                => { file => 'lib/XML/XPath/Step.pm',           version => '1.44' },
            'XML::XPath::Variable'            => { file => 'lib/XML/XPath/Variable.pm',       version => '1.44' },
            'XML::XPath::NodeSet'             => { file => 'lib/XML/XPath/NodeSet.pm',        version => '1.44' },
            'XML::XPath::Boolean'             => { file => 'lib/XML/XPath/Boolean.pm',        version => '1.44' },
            'XML::XPath::Root'                => { file => 'lib/XML/XPath/Root.pm',           version => '1.44' },
            'XML::XPath::PerlSAX'             => { file => 'lib/XML/XPath/PerlSAX.pm',        version => '1.44' },
            'XML::XPath::Builder'             => { file => 'lib/XML/XPath/Builder.pm',        version => '1.44' },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/XML-XPath.git',
                web  => 'https://github.com/manwar/XML-XPath',
            },
        }})
     : ()
    ),
);
