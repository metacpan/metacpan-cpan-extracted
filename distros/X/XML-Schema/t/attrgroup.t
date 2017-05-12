#!/usr/bin/perl -w
#============================================================= -*-perl-*-
#
# t/attrgroup.t
#
# Test the XML::Schema::Attribute::Group module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: attrgroup.t,v 1.2 2001/12/20 13:26:28 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Constants qw( :attribs :wildcard );
use XML::Schema::Attribute::Group;
use XML::Schema::Type;
$^W = 1;

my $DEBUG = grep(/-d/, @ARGV);
$XML::Schema::Attribute::Group::DEBUG = $DEBUG;

ntests(174);
my ($pkg, $type, $attr, $group);


#------------------------------------------------------------------------
# pre-create attribute
#------------------------------------------------------------------------

$pkg  = 'XML::Schema::Type::string';
$type = $pkg->new();
ok( $type, $pkg->error() );

$pkg = 'XML::Schema::Attribute';
$attr = $pkg->new( name => 'foo', type => $type);
ok( $attr );
match( $attr->name(), 'foo' );


#------------------------------------------------------------------------
# create attribute group passing attribute object reference
#------------------------------------------------------------------------

$pkg = 'XML::Schema::Attribute::Group';

$group = $pkg->new();
ok( ! $group );
match( $pkg->error(), 'XML::Schema::Attribute::Group: name not specified' );

$group = $pkg->new( name => 'myGroup' );
assert( $group, $pkg->error() );
match( $group->name(), 'myGroup' );

$group = $pkg->new( name => 'myGroup', attributes => { foo => $attr } );
ok( $group, $pkg->error() );

my $a2 = $group->attribute('foo');
ok( $a2, $group->error() );
match( $a2->name(), 'foo' );

my $hash = $group->attributes();
ok( $hash );

my $r = $group->required('foo');
ok( defined $r, $group->error() );
match( $r, 0 );

$group->required( foo => 1 );
match( $group->required('foo'), 1 );

match( $group->default_use(), OPTIONAL );

$group = $pkg->new( name        => 'myGroup', 
		    attributes  => { bar => 'string' }, 
		    default_use => REQUIRED );
ok( $group, $pkg->error() );

match( $group->use('bar'), REQUIRED );

ok( ! $group->use('non-existant') );
match( $group->error(), "no such attribute: 'non-existant'" );


#------------------------------------------------------------------------
# see if new attributes adopt default usage requirement
#------------------------------------------------------------------------

match( $group->default_use, REQUIRED );

my $a3 = $group->attribute( name => 'wiz', type => 'string' );
ok( $a3, $group->error() );
match( $a3->name(), 'wiz' );
match( $a3->type()->type(), 'string' );

ok( $group->required('wiz') );

ok( $group->attribute( name => 'waz', type => 'string', optional => 1) );
match( $group->required('waz'), 0 );
match( $group->required('wiz'), 1 );


#------------------------------------------------------------------------
# try setting required_by_default(0) and see if new attributes adopt
#------------------------------------------------------------------------

$group->default_use(OPTIONAL);

ok( $group->attribute( name => 'flic', type => 'string' ) );
ok( $group->attribute( name => 'flac', type => 'string', use => 'required' ) );
match( $group->required('flic'), 0 );
match( $group->required('flac'), 1 );


#------------------------------------------------------------------------
# try different contructor parameters to set usage
#------------------------------------------------------------------------

$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => { type => 'string' },
	baz => { name => 'baz', type => 'string' },
	boz => { type => 'string', use => OPTIONAL },
	buz => { type => 'string', required => 1 },
    },
    required => [ qw( foo bar ) ],
});
ok( $group, $pkg->error() );


match( $group->required('foo'), 1 );
match( $group->required('bar'), 1 );
match( $group->required('baz'), 0 );
match( $group->required('boz'), 0 );
match( $group->required('buz'), 1 );


$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => { type => 'string' },
	baz => { name => 'baz', type => 'string' },
	boz => { type => 'string', optional => 1 },
	buz => { type => 'string', required => 1 },
    },
    default_use => REQUIRED,
});
ok( $group, $pkg->error() );

match( $group->required('foo'), 1 );
match( $group->required('bar'), 1 );
match( $group->required('baz'), 1 );
match( $group->required('boz'), 0 );
match( $group->required('buz'), 1 );

$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => { type => 'string' },
	baz => { name => 'baz', type => 'string' },
	boz => { type => 'string', use => OPTIONAL },
	buz => { type => 'string', required => 1 },
    },
    required => 0,
});
ok( $group, $pkg->error() );

match( $group->required('foo'), 0 );
match( $group->required('bar'), 0 );
match( $group->required('baz'), 0 );
match( $group->required('boz'), 0 );
match( $group->required('buz'), 1 );

match( $group->optional('foo'), 1 );
match( $group->optional('bar'), 1 );
match( $group->optional('baz'), 1 );
match( $group->optional('boz'), 1 );
match( $group->optional('buz'), 0 );


$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => { type => 'string' },
	baz => { name => 'baz', type => 'string' },
	boz => { type => 'string', optional => 1 },
	buz => { type => 'string', required => 1 },
    },
    required => [ qw( foo bar boz buz ) ],
});
ok( $group, $pkg->error() );

match( $group->required('foo'), 1 );
match( $group->required('bar'), 1 );
match( $group->required('baz'), 0 );
match( $group->required('boz'), 0 );
match( $group->required('buz'), 1 );


my $req = $group->required();
ok( $req, $group->error() );
@$req = sort @$req;

match( $#$req, 2 );
match( $req->[0], 'bar' );
match( $req->[1], 'buz' );
match( $req->[2], 'foo' );

$req = $group->optional();
@$req = sort @$req;

match( $#$req, 1 );
match( $req->[0], 'baz' );
match( $req->[1], 'boz' );

$req = $group->prohibited();
match( $#$req, -1 );

ok( $group->prohibited( foo => 1 ) );
$req = $group->prohibited();
match( $#$req, 0 );
match( $req->[0], 'foo' );

$req = $group->required();
ok( $req, $group->error() );
@$req = sort @$req;
match( $#$req, 1 );
match( $req->[0], 'bar' );
match( $req->[1], 'buz' );


#------------------------------------------------------------------------
# test validate() method
#------------------------------------------------------------------------

$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
	wiz => { type => 'string', use => REQUIRED },
	waz => { type => 'integer', optional => 1 },
    },
    required => [ 'bar' ],
});
ok( $group, $pkg->error() );

my $in = {
    bar => 10,
    wiz => 'hello',
};


my $out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ bar }, 10 );
match( $out->{ wiz }, 'hello' );

$in = {
    wiz => 'hello',
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "required attribute 'bar' not defined" );

$in = {
    bar => 99,
};

$in = {
    bar => 'hello',
    wiz => 'goodbye',
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "bar attribute: value is not a decimal" );

$in = {
    bar => 3.14,
    wiz => 'goodbye',
};


$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "bar attribute: value is not an integer" );

$in = {
    bar => 42,
    wiz => 'goodbye',
    bad => 99,
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "unexpected attribute: bad" );

$in = {
    foo => 'hello',
    wiz => 'world',
    bar => 42,
    waz => 99,
};

$out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ foo }, 'hello' );
match( $out->{ wiz }, 'world' );
match( $out->{ bar }, 42 );
match( $out->{ waz }, 99 );



#------------------------------------------------------------------------
# test PROHIBITED option
#------------------------------------------------------------------------

$group->use( foo => PROHIBITED );

$in = {
    bar => 42,
    wiz => 'goodbye',
};

$out = $group->validate( $in );
ok( $out, $group->error() );

$in = {
    foo => 'something',
    bar => 42,
    wiz => 'goodbye',
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "attribute 'foo' is prohibited" );


#------------------------------------------------------------------------
# test wildcards
#------------------------------------------------------------------------

my $factory = $group->factory();
assert( $factory );

my $wildcard = $factory->wildcard( namespace => 'ok' );
assert( $wildcard, $factory->error() );

$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => $wildcard,
});
ok( $group, $pkg->error() );

$in = {
    foo => 'something',
    bar => 42,
    wiz => 'goodbye',
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "unexpected attribute: wiz" );


$in = {
    foo => 'something',
    bar => 42,
    'ok:wiz' => 'goodbye',
};

$out = $group->validate( $in );
ok( $out );
match( $out->{ foo }, 'something' );
match( $out->{ bar }, 42 );
match( $out->{'ok:wiz'}, 'goodbye' );


#------------------------------------------------------------------------
# test that group constructor creates wildcard for us
#------------------------------------------------------------------------

$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    any => 1,
});
ok( $group, $pkg->error() );

$in = {
    foo => 'something',
    bar => 42,
    'cool:wiz' => 'hello',
    'warm:waz' => 'goodbye',
    poop => 'test',
};

$out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ foo }, 'something' );
match( $out->{ bar }, 42 );
match( $out->{'cool:wiz'}, 'hello' );
match( $out->{'warm:waz'}, 'goodbye' );


$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => { any => 1 },
});
ok( $group, $pkg->error() );

$in = {
    foo => 'something',
    bar => 42,
    'cool:wiz' => 'hello',
    'warm:waz' => 'goodbye',
    poop => 'test',
};

$out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ foo }, 'something' );
match( $out->{ bar }, 42 );
match( $out->{'cool:wiz'}, 'hello' );
match( $out->{'warm:waz'}, 'goodbye' );



$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => { namespace => ANY },
});
ok( $group, $pkg->error() );

$in = {
    foo => 'something',
    bar => 42,
    'cool:wiz' => 'hello',
    'warm:waz' => 'goodbye',
    poop => 'test',
};

$out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ foo }, 'something' );
match( $out->{ bar }, 42 );
match( $out->{'cool:wiz'}, 'hello' );
match( $out->{'warm:waz'}, 'goodbye' );


$group = $pkg->new( {
    name => 'myGroup',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => { namespace => 'cool' },
});
ok( $group, $pkg->error() );

$in = {
    foo => 'something',
    bar => 42,
    'cool:wiz' => 'hello',
    'warm:waz' => 'goodbye',
};

$out = $group->validate( $in );
ok( ! $out );
match( $group->error(), "unexpected attribute: warm:waz" );

$in = {
    foo => 'something',
    bar => 42,
    'cool:wiz' => 'hello',
    'cool:waz' => 'goodbye',
};

$out = $group->validate( $in );
ok( $out, $group->error() );
match( $out->{ foo }, 'something' );
match( $out->{ bar }, 42 );
match( $out->{'cool:wiz'}, 'hello' );
match( $out->{'cool:waz'}, 'goodbye' );



#------------------------------------------------------------------------
# test nested groups
#------------------------------------------------------------------------

my $group1 = $pkg->new( {
    name => 'group_1',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => { namespace => 'cool' },
});
assert( $group1, $pkg->error() );

my $group2 = $pkg->new( {
    name => 'group_2',
    attributes => { 
	wiz => 'string',
	waz => 'integer',
    },
    required => [ 'waz' ],
    wildcard => { namespace => 'warm' },
});
assert( $group2, $pkg->error() );

my $parent_group = $pkg->new( {
    name => 'parent_group',
    attributes => { 
	bing => 'string',
	bang => 'integer',
    },
    required => [ 'bang' ],
    wildcard => { namespace => 'lukewarm' },
});
assert( $parent_group, $pkg->error() );

ok( $parent_group->group($group1), $parent_group->error() );
ok( $parent_group->group($group2), $parent_group->error() );

my $child1 = $parent_group->attribute_group('group_1');
assert( $child1 );
match( $group1, $child1 );

my $child2 = $parent_group->attribute_group('group_2');
assert( $child2 );
match( $group2, $child2 );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
};

$out = $parent_group->validate($in);
assert( $out, $parent_group->error() );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
    strange => 'loops',
};

$out = $parent_group->validate($in);
ok( ! $out );
match( $parent_group->error(), 'unexpected attribute: strange' );


#------------------------------------------------------------------------
# play the wildcard
#------------------------------------------------------------------------

ok( $parent_group->wildcard( any => 1 ), $parent_group->error() );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
    strange => 'loops',
};

$out = $parent_group->validate($in);
ok( $out, $parent_group->error() );
match( $out->{ bing }, 'bong' );
match( $out->{ foo  }, 'hello' );
match( $out->{ wiz  }, 'world' );
match( $out->{ bang }, 42 );
match( $out->{ bar  }, 69 );
match( $out->{ waz  }, 99 );
match( $out->{'cool:ice' }, 'chilly' );
match( $out->{'warm:beer'}, 'silly'  );
match( $out->{'lukewarm:water'}, 'fire + ice'  );
match( $out->{ strange }, 'loops'  );


#------------------------------------------------------------------------
# test that attribute groups correctly bind sub-groups to the correct
# outer scope so that types, etc., can be correctly resolved.
#------------------------------------------------------------------------

my $group3 = $pkg->new( {
    name => 'group_3',
    attributes => { 
	plonk => 'plank',
    },
    required => 'plonk',
});
assert( $group3, $pkg->error() );

ok( $parent_group->group($group3) );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
    strange => 'loops',
    plonk => '10.20',
};

my $save_in = { %$in };

$out = $parent_group->validate($in);
ok( ! $out );
match( $parent_group->error(), 'plonk attribute: no such type: plank' );

ok( $parent_group->simpleType( name => 'plank', base => 'float' ),
    $parent_group->error() );

$in = { %$save_in };
$out = $parent_group->validate($in);
ok( $out, $parent_group->error() );
    


#------------------------------------------------------------------------
# test nested groups specified to contructor
#------------------------------------------------------------------------
#------------------------------------------------------------------------
# test nested groups
#------------------------------------------------------------------------

my $cfg1 = {
    name => 'group_a',
    attributes => { 
	foo => 'string',
	bar => 'integer',
    },
    required => [ 'bar' ],
    wildcard => { namespace => 'cool' },
};

my $cfg2 = {
    name => 'group_b',
    attributes => { 
	wiz => 'string',
	waz => 'integer',
    },
    required => [ 'waz' ],
    wildcard => { namespace => 'warm' },
};

$group = $pkg->new( {
    name => 'group_abc',
    attributes => { 
	bing => 'string',
	bang => 'integer',
    },
    required => [ 'bang' ],
    wildcard => { namespace => 'lukewarm' },
    groups   => [ $cfg1, $cfg2 ],
});
assert( $group, $pkg->error() );

ok( $group->attribute_group('group_a'), $group->error() );
ok( $group->attribute_group('group_b'), $group->error() );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
};

$out = $group->validate($in);
assert( $out, $group->error() );


#------------------------------------------------------------------------
# different approach: pass pre-created group object
#------------------------------------------------------------------------

my $groupa = $pkg->new( $cfg1 );
assert( $groupa, $pkg->error() );

my $groupb = $pkg->new( $cfg2 );
assert( $groupb, $pkg->error() );

$group = $pkg->new( {
    name => 'group_abc',
    attributes => { 
	bing => 'string',
	bang => 'integer',
    },
    required => [ 'bang' ],
    wildcard => { namespace => 'lukewarm' },
    groups   => [ $groupa, $groupb ],
});
assert( $group, $pkg->error() );

ok( $group->attribute_group('group_a'), $group->error() );
ok( $group->attribute_group('group_b'), $group->error() );

$in = {
    bing => 'bong',
    foo  => 'hello',
    wiz  => 'world',
    bang => 42,
    bar  => 69,
    waz  => 99,
    'cool:ice'  => 'chilly',
    'warm:beer' => 'silly',
    'lukewarm:water' => 'fire + ice',
};

$out = $group->validate($in);
assert( $out, $group->error() );


$group = $pkg->new( {
    name  => 'group_a2',
    group => $groupa,
});
assert( $group, $pkg->error() );

ok( $group->attribute_group('group_a'), $group->error() );

$in = {
    foo  => 'hello',
    bar  => 69,
    'cool:ice'  => 'chilly',
};

$out = $group->validate($in);
assert( $out, $group->error() );

