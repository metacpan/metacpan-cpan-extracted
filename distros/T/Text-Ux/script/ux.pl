#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(:config posix_default no_ignore_case bundling auto_help);
use Pod::Usage;
use Time::HiRes qw(gettimeofday tv_interval);
use Term::ReadLine;
use Text::Ux;

exit &main;

sub main {
    my %commands = (
        list   => \&list,
        search => \&search,
        build  => \&build,
    );
    my $command = shift @ARGV || '';
    my $sub = $commands{$command} or pod2usage(1);
    $sub->();
}

sub list {
    my %opt;
    GetOptions(\%opt,
        'index|i=s',
    ) or pod2usage(1);
    my $ux = Text::Ux->new;
    die 'Argument --index required' unless exists $opt{index};
    $ux->load($opt{index});
    for (my $i = 0; $i < $ux->size; $i++) {
        print $ux->decode_key($i), "\n";
    }
    0;
}

sub search {
    my %opt = (limit => 10);
    GetOptions(\%opt,
        'index|i=s',
        'limit|l=i',
    ) or pod2usage(1);

    die 'Argument --index required' unless exists $opt{index};

    my $ux = Text::Ux->new;
    $ux->load($opt{index});
    local $| = 1;
    my $term = Term::ReadLine->new('ux-perl search');
    while (defined(my $query = $term->readline('> '))) {
        $query =~ s/^\s+//;
        $query =~ s/\s+$//;
        next unless $query;
        printf "query:[%s]\n", $query;
        my $key = $ux->prefix_search($query);
        printf "prefixSearch: %s\n", defined $key ? $key : 'not found.';
        my @keys = $ux->common_prefix_search($query);
        printf "commonPrefixSearch: %d found\n", scalar(@keys);
        print $_, "\n" for @keys;
        @keys = $ux->predictive_search($query);
        printf "predictiveSearch: %d found\n", scalar(@keys);
        print $_, "\n" for @keys;
        $term->add_history($query) if $query =~ /\S/ && $term->can('add_history');
    }
    0;
}

sub build {
    GetOptions(\my %opt,
        'keylist|k=s',
        'index|i=s',
        'uncompress|u!',
    ) or pod2usage(1);
    die 'Argument --keylist required' unless exists $opt{keylist};

    my $ux = Text::Ux->new;
    my @keys;
    open my $fh, '<', $opt{keylist} or die "Could not open keylist file: $opt{keylist}";
    while (<$fh>) {
        chomp;
        push @keys, $_;
    }
    close $fh;
    my $start = [gettimeofday];
    $ux->build(\@keys, !$opt{uncompress});
    printf "  index time:\t%s\n", tv_interval($start);
    print $ux->alloc_stat($ux->alloc_size);
    print $ux->stat;
    my $original_size = -s $opt{keylist};
    printf "originalSize:\t%s\n", $original_size;
    printf "   indexSize:\t%s (%s)\n", $ux->alloc_size, ($ux->alloc_size / $original_size);
    printf "      keyNum:\t%s\n", $ux->size;
    $ux->save($opt{index}) if exists $opt{index};
    0;
}

__END__

=head1 NAME

ux.pl - ux command-line tool

=head1 SYNOPSIS

  $ ux.pl <command> [<args>]

  # Build index
  $ ux.pl build --keylist=<path> [--index=<path>] [--uncompress]

  # List keys
  $ ux.pl list --index=<path>

  # Launch search prompt
  $ ux.pl search --index=<path> [--limit=<num>]

=head1 DESCRIPTION

ux.pl is a command line utility to build/list/search index.

=head1 COMMANDS

=over 4

=item build

Build index.

=item list

List index.

=item search

Search index.

=back

=head1 ARGUMENTS

=over 4

=item -i, --index

Specifies the index file.

=item -k, --keylist

Specifies the keylist file.

=item -c, --uncompress

Specifies compress method.

=item -l, --limit

Specifies result num.

=back

=head1 AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

=head1 SEE ALSO

L<Text::Ux>

=cut
