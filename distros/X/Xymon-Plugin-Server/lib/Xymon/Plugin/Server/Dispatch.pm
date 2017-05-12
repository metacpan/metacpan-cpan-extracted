#
# plugin dispatcher
#
package Xymon::Plugin::Server::Dispatch;

use strict;
use warnings;

=head1 NAME

Xymon::Plugin::Server::Dispatch - Xymon plugin dispatcher

=head1 SYNOPSIS

    use Xymon::Plugin::Server::Dispatch;
    use YourMonitor;

    # dispatch to class
    my $dispatch1 = Xymon::Plugin::Server::Dispatch
                    ->new('test' => 'YourMonitor');
    $dispatch1->run;

    # dispatch to method
    my $dispatch2 = Xymon::Plugin::Server::Dispatch
                    ->new('test' => new YourMonitor());
    $dispatch2->run;

    # dispatch to CODEREF
    my $dispatch3 = Xymon::Plugin::Server::Dispatch
                    ->new('test' => sub { ... });
    $dispatch3->run;


=cut

use Xymon::Plugin::Server::Hosts;


=head1 SUBROUTINES/METHODS

=head2 new(testName1 => ModuleName1, ...)

Create dispatch object for tests and modules.

If testName has wildcard character(like http:*), $test will be ARRAYREF
when run method is called.

=cut

sub new {
    my $class = shift;
    my @keyvalue = @_;

    my @keys;
    my %dic;

    while (@keyvalue > 0) {
	my $key = shift @keyvalue;
	push(@keys, $key);
	$dic{$key} = shift @keyvalue;
    }

    my $self = {
	_keys => \@keys,
	_dic => \%dic,
    };

    bless $self, $class;
}

=head1 SUBROUTINES/METHODS

=head2 run

For every host listed in bb-hosts(Xymon 4.2) or hosts.cfg (Xymon 4.3),
following operation is executed.

    # if class name is given
    my $module = YourMonitor->new($host, $test);
    $module->run;

    # if object is given
    $module->run($host, $test);

    # if CODEREF is given
    &$code($host, $test);

=cut

sub run {
    my $self = shift;

    for my $key (@{$self->{_keys}}) {
	my $dest = $self->{_dic}->{$key};
	my $code;
	if (ref($dest)) {
	    if (ref($dest) eq 'CODE') {
		$code = $dest;
	    }
	    else {
		$code = sub { $dest->run(@_); };
	    }
	}
	else {
	    $code = sub {
		my $obj = $dest->new(@_);
		$obj->run;
	    };
	}

	for my $entry (Xymon::Plugin::Server::Hosts->new->grep($key)) {
	    eval {
		my $host = $entry->[1];
		my $test = $entry->[2];
		my $ip = $entry->[0];

		&$code($host, $test, $ip);
	    };
	    if ($@) {
		print STDERR $@;
	    }
	}
    }
}

1;
