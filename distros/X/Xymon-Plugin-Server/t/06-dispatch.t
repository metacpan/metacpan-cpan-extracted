use strict;
use Test::More tests => 5;

use Xymon::Plugin::Server::Dispatch;

#
# override Xymon::Plugin::Server::Hosts
#
BEGIN {
    no warnings "redefine";
    *Xymon::Plugin::Server::Hosts::new = sub {
	return bless {}, 'Xymon::Plugin::Server::Hosts';
    };

    *Xymon::Plugin::Server::Hosts::grep = sub {
	my $obj = shift;
	my $tag = shift;

	return (['127.0.0.1', 'host1', 'test1']) if ($tag eq 'test1');
	return (['127.0.0.2', 'host2', 'test2']) if ($tag eq 'test2');
	return (['127.0.0.3', 'host3', 'test3']) if ($tag eq 'test3');
	return (['127.0.0.4', 'host4', ['test4:a', 'test4:b']]) if ($tag eq 'test4*');

	return;
    };
}

our $class1_result;
our $class2_result;

package Class1;

sub new {
    my $class = shift;
    my $self = {
	_data => [@_],
    };
    bless $self, $class;
}

sub run {
    my $self = shift;
    my @data = @{$self->{_data}};

    $main::class1_result = join(", ", @data);
}

package Class2;

sub new {
    my $class = shift;
    my $self = {
	_data => [@_],
    };
    bless $self, $class;
}

sub run {
    my $self = shift;
    my @data = @_;

    $main::class2_result = join(", ", @data);
}

package main;

{
    my $test3_result;
    my ($test4_result, $test4_result_test);

    my $dispatch = Xymon::Plugin::Server::Dispatch
	->new('test1' => 'Class1',
	      'test2' => Class2->new,
	      'test3' => sub {
		  $test3_result = join(", ", @_);
	      },
	      'test4*' => sub {
		  my ($host, $test, $ip) = @_;
		  $test4_result = join(", ", $host, $ip);
		  $test4_result_test = join(", ", @$test);
	      },
	      );

    $dispatch->run;

    is($class1_result, "host1, test1, 127.0.0.1");
    is($class2_result, "host2, test2, 127.0.0.2");
    is($test3_result, "host3, test3, 127.0.0.3");

    is($test4_result, "host4, 127.0.0.4");
    is($test4_result_test, "test4:a, test4:b");
}


