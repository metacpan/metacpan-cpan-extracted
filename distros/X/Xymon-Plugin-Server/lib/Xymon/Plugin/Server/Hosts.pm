#
# bbhostgrep wrapper
#

package Xymon::Plugin::Server::Hosts;

=head1 NAME

Xymon::Plugin::Server::Hosts - Xymon bbhostgrep wrapper

=head1 SYNOPSIS

    use Xymon::Plugin::Server::Hosts;

    my $hosts = Xymon::Plugin::Server::Hosts->new();
    my @result = $hosts->grep('bbd');

    for my $entry (@result) {
        my ($ip, $host, $test) = @$entry;
        print "ip = $ip, host = $host, test = $test\n";
    }

=cut

use strict;
use Carp;

use Xymon::Plugin::Server;

=head1 SUBROUTINES/METHODS

=head2 new

Just a constructor.
(Takes bbhostgrep options optionally)

=cut

sub new {
    my $class = shift;
    my @params = @_;

    my $self = {
	_params => \@params
    };

    bless $self, $class;
}

sub _select_test {
    my $self = shift;
    my $test = shift;
    my $s = shift;

    my @tests = split(/\s+/, $s);

    my $re = $test;
    $re =~ s/\*/.*/g;
    return grep { /^$re/ } @tests;
}

=head2 grep(TEST)

Execute bbhostgrep and return its result.

Return value is an array like:

  (entry1, entry2, ...)

Each entiries are arrayref like:

  [ IP-address, hostname, tests ]

If TEST does not contain wildcard character ('*'), tests is a scalar value.
Otherwise it is ARRAYREF contains test names which matchies TEST.

=cut

sub grep {
    my $self = shift;
    my $test = shift;

    my $xyhome = Xymon::Plugin::Server->home;

    my $grep = "$xyhome/bin/bbhostgrep";

    my @cmdline = ($grep);
    push(@cmdline, @{$self->{_params}}, $test);

    my @result;

    open(my $fh, "-|", @cmdline)
      or croak "cannot execute $grep: $!";

    while (<$fh>) {
	chomp;
	my ($iphost, $tests) = split(/\s*#\s*/);
	my ($ip, $host) = split(/\s+/, $iphost);

	$tests =~ s/\s*$//;
	$ip =~ s/^\s//;

	my @filtered = $self->_select_test($test, $tests);
	if ($test =~ /\*/) {
	  push(@result, [$ip, $host, \@filtered]);
	}
	else {
	  push(@result, [$ip, $host, @filtered]);
	}
    }

    return @result;
}

1;
