package WWW::Webrobot::WebrobotLoad;
use strict;
use warnings;


# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use WWW::Webrobot;
use WWW::Webrobot::Global;
use WWW::Webrobot::Forker;
use WWW::Webrobot::Statistic;
use WWW::Webrobot::Histogram;
use WWW::Webrobot::Print::ChildSend;


my $USAGE = __PACKAGE__ . "->new(\$cfg, \$cmd_param)";

=head1 NAME

WWW::Webrobot::WebrobotLoad - Run testplans with multiple clients

=head1 SYNOPSIS

    my $wrl = WWW::Webrobot::WebrobotLoad->new($cfg_name, $cmd_param);
    my ($statistic, $histogram, $url_statistic, $http_errcode, $assert_ok) =
         $wrl -> run($testplan_name);

    # for $cmd_param see bin/webrobot-load

=head1 DESCRIPTION

Runs multiple clients.

[missing documentation]
Look into the sources L<webrobot-load>.

=head1 METHODS

=over

=item $wr = WWW::Webrobot::WebrobotLoad -> new( $cfg_name, $cmd_param );

Construct an object.

 $cfg_name
     Name of the config file
 $cmd_param
     ??? to be documented

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my ($cfg_name, $cmd_param) = @_;
    $self->{cfg_name} = $cfg_name or die $USAGE;
    $self->{cmd_param} = $cmd_param or die $USAGE;
    $self->{cfg} = WWW::Webrobot -> read_configuration($self->{cfg_name}, $self->{cmd_param});
    WWW::Webrobot::Global->save_memory(1);
    return $self;
}


=item ($statistic, $histogram, $url_statistic, $http_errcode, $assert_ok) = run($testplan_name);

Run a test.

B<INPUT VARIABLES:>

=over

=item $testplan_name

Name of the testplan

=back

B<OUTPUT VARIABLES:>

=over

=item $statistic

see L<WWW::Webrobot::Statistic>

=item $histogram

see L<WWW::Webrobot::Histogram>

=item $url_statistic

=item $http_errcode

=item $assert_ok

=back

=cut

sub run {
    my ($self, $testplan_name) = @_;

    my $statistic = WWW::Webrobot::Statistic -> new(extended => 1);
    my $histogram = WWW::Webrobot::Histogram -> new(base => $self->cfg->{load}->{base} || 2);
    my $url_statistic = {};
    my $http_errcode = {};
    my $assert_ok = [];
    my $exit_status = {};
    my @parm_list = (
        $statistic,
        $histogram,
        $url_statistic,
        $http_errcode,
        $assert_ok,
        $exit_status,
    );
                     
    my $forker = WWW::Webrobot::Forker -> new();
    $forker -> fork_children(
        $self->cfg->{load}->{number_of_clients},
        $self->child($testplan_name)
    );
    $forker -> eventloop(parent(@parm_list));
    return @parm_list;
}

sub child {
    # This is a child worker process.
    # If you 'print' anything, it is written into the pipe to the main parent process.
    
    my ($self, $testplan_name) = @_;

    # We get a new instance of WWW::Webrobot.
    # The config file was read only once.
    my $webrobot = WWW::Webrobot -> new($self->{cfg_name}, $self->{cmd_param});
    
    return sub {
        my ($child_id) = @_;
        
        # Note: the following line will write to the parent process due to a
        # WWW::Webrobot::Print::ChildSend.pm listener defined in bin/webrobot-load
        #
        # Currently all children will work with the same test plan,
        # but parse it itself.  If you want the child processes make work on
        # different test plans, this is the place to change it.
        #
        my $exit = $webrobot -> run($testplan_name, $child_id);

        # Now we write the exit status into the pipe. Note that this line must be
        # compatible to the lines send by WWW::Webrobot::Print::ChildSend.pm and
        # received by WWW::Webrobot::WebrobotLoad::parent(), see below.
        #
        print "EXIT $exit\n";
    }
}


sub parent {
    # We are in the main parent process.
    
    my ($statistic, $histogram, $url_stat, $http_errcode, $assert_ok, $exit_status) = @_;
    print <<EOS;
# --- Format ----------------------------------------------------------
# CMD      current action
#              REQ     action is a HTTP request
#              EXIT    child exit
# ID       child-id
# A        assertion status, 0=success 1=fail
# TIME     execution time for the HTTP request
# COD      HTTP status code
# MTD      HTTP method
# URL      requested url
# ---------------------------------------------------------------------
EOS
    printf "%-4s %3s %1s %6s %3s %3s %s\n", "CMD", "ID", "A", "TIME", "COD", "MTD", "URL";
    return sub {
        # Printing here is STDOUT
        my ($child_id, $line) = @_;
        my ($cmd, $rest) = split /\s+/, $line, 2;
        if ($cmd eq "TIME") {
            my ($float, $fail,  $errcode, $method, $url) = split /\s+/, $rest, 5;
            $statistic -> add($float);
            $histogram -> add($float);
            $url_stat->{$url} = WWW::Webrobot::Statistic->new() if !defined $url_stat->{$url};
            $url_stat->{$url} -> add($float);
            $http_errcode->{$errcode}++;
            $assert_ok->[$fail]++;
            printf "%-4s %03d %1s %6.3f %3d %3s %s\n", "REQ", $child_id, $fail, $float, $errcode, $method, $url;
        }
        elsif ($cmd eq "EXIT") {
            $exit_status->{$child_id} = $rest;
            printf "%-4s %03d %1s\n", "EXIT", $child_id, $rest; # $rest is exit-status
        }
        else {
            print "*** UNKNOWN COMMAND: $child_id $line\n";
            #die;
        }
    }
}

sub cfg {
    my ($self) = @_;
    return $self->{cfg};
}

=back

=head1 SEE ALSO

L<webrobot-load>

L<webrobot>

L<WWW::Webrobot::pod::Config>

L<WWW::Webrobot::pod::Testplan>

=cut

1;
