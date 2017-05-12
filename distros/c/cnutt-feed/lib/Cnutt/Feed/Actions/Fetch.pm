package Cnutt::Feed::Actions::Fetch;

use strict;
use warnings;
use utf8;


=head1 NAME

Cnutt::Feed::Actions::Get - Fetch some feeds as defined in the config file

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

This file is part of cnutt-feed. You should read its documentation.

=cut

use Config::Tiny;
use Cnutt::Feed::Mailbox;

my %defaults = (
                html => 1,
                delete => 0,
                verbose => 1,
                );

=head2 fetch_one

Fetch only one feed

=cut

sub fetch_one {
    my ($roptions, $conf, $name) = @_;
    my %options = %{$roptions};

    die "Feed $name not found in $options{config}.\n"
        if (!exists($conf->{$name}));

    # fill the blank using default value found in config file or in the
    # code
    my $url = $conf->{$name}->{url};
    my $mb  = $conf->{$name}->{mailbox};
	$mb =~ s/^~/$ENV{HOME}/;

    foreach (keys %{$conf->{$name}}) {
        if (!defined($options{$_})) {
            $options{$_} = $conf->{$name}->{$_};
        }
    }
    foreach (keys %{$conf->{_}}) {
        if (!defined($options{$_})) {
            $options{$_} = $conf->{_}->{$_};
        }
    }
    foreach (keys %defaults) {
        if (!defined($options{$_})) {
            $options{$_} = $defaults{$_};
        }
    }

    my $count = Cnutt::Feed::Mailbox->fetch($url, $mb,
                                            $options{html},
                                            $options{delete},
                                            $options{verbose},
                                            $name
        );
    if (defined($count)) {
        print "Found $count new entries in $name\n" if $options{verbose};
        if ($count) {
            print "\n";
        }
    }
}

=head2 fetch

  fetch ($roptions, @names)

By default, fetch all the feeds given in C<@names>

If B<--all> is given, the feeds in C<@names> will be exclued.

=cut

sub fetch {
    my ($roptions, @names) = @_;
    my %options = %{$roptions};

    # read the config file
    my $conf = Config::Tiny->read($options{config});
    die "$Config::Tiny::errstr\n" unless $conf;

    if ($options{all}) {
        for my $name (keys %{$conf}) {
            next if $name eq "_";
            next if grep(/$name/, @names);
            fetch_one($roptions, $conf, $name);
        }
    }
    else {
        for (@names) {
            fetch_one($roptions, $conf, $_);
        }
    }
}

1;

