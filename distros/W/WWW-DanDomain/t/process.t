#!/usr/bin/perl -w

# $Id$

use strict;
use Test::More tests => 3;
use Test::MockObject::Extends;
use File::Slurp qw(slurp);
use WWW::DanDomain;
use Env qw(TEST_VERBOSE);
use Carp qw(croak);

my $mech = Test::MockObject::Extends->new('WWW::Mechanize');
my $wd;

$mech->mock(
    'content',
    sub {
        my ( $mb, %params ) = @_;

        my $content = slurp('t/testdata')
            || croak "Unable to read file - $!";

        return $content;
    }
);
$mech->set_true('get', 'follow_link', 'submit_form');

my $content;

$wd = WWW::DanDomain->new({
	username  => 'topshop',
	password  => 'topsecret',
	url       => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    verbose   => $TEST_VERBOSE,
    mech      => $mech,
});

is(${$wd->retrieve}, 'test');

$wd = WWW::DanDomain->new({
	username  => 'topshop',
	password  => 'topsecret',
	url       => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    verbose   => $TEST_VERBOSE,
    mech      => $mech,
	processor => sub {                
        ${$_[0]} =~ s/test/fest/;
        
        return $_[0];
    },
});

is(${$wd->retrieve}, 'fest');

my $processor = MyProcessor->new();

$wd = WWW::DanDomain->new({
	username  => 'topshop',
	password  => 'topsecret',
	url       => 'http://www.billigespil.dk/admin/edbpriser-export.asp',
    verbose   => $TEST_VERBOSE,
    mech      => $mech,
	processor => $processor,
});

is(${$wd->retrieve}, 'fest');

package MyProcessor;

use strict;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
}

sub process {
    my ($self, $content) = @_;
    
    ${$content} =~ s/test/fest/;
    
    return $content
}
