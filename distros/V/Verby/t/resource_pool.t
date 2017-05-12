#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => "POE::Component::ResourcePool not installed" unless eval { require POE::Component::ResourcePool };
	plan 'no_plan';
}

use POE::Component::ResourcePool::Resource::Semaphore;

use Test::Deep;
use Test::MockObject;
use List::MoreUtils qw/uniq/;
use Verby::Config::Data;
use Set::Object;

use POE;

use Verby::Dispatcher;

my @items = map { Test::MockObject->new } 1 .. 20;

foreach my $meth (qw/is_satisfied provides_cxt/){
	$_->set_false($meth) for @items;
}

$_->set_list( resources => ( steps => 1 ) ) for @items;

$_->set_list( depends => () ) for @items;

my @finished;
my $running = Set::Object->new;
my $max_size = 0;

foreach my $item ( @items ) {
	$item->mock( 'do' => sub {
		my $step = shift;
		POE::Session->create(
			inline_states => {
				_start => sub { $running->insert($step); $max_size = $running->size if $running->size > $max_size },
				_stop => sub { push @finished, $step; $running->remove($step) },
			}
		);
	});
}

my $d = Verby::Dispatcher->new(
	resource_pool => POE::Component::ResourcePool->new(
		resources => {
			steps => POE::Component::ResourcePool::Resource::Semaphore->new( initial_value => 3 ),
		},
	),
);

my $cfg = Verby::Config::Data->new;
$cfg->data->{logger} = Test::MockObject->new;
$d->config_hub($cfg);

$cfg->logger->set_true($_) for qw/info debug/;
#$cfg->logger->mock($_ => sub { warn "@_\n" }) for qw/info debug/;

can_ok($d, "add_steps");
$d->add_steps(@items);

can_ok($d, "do_all");
my $t1 = times;
$d->do_all;
my $t2 = times;

cmp_ok( $max_size, "<=", 3, "never exceeded 3 concurrent jobs" );

