#!perl
package Test::OnlySome::RerunFailed;
use 5.012;
use strict;
use warnings;

use Carp qw(croak);
use Import::Into;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];
use Data::Dumper;   # for verbose

use Test::OnlySome::PathCapsule;

our $VERSION = '0.001003';

use constant DEFAULT_FILENAME => '.onlysome.yml';

# Docs {{{2

=head1 NAME

Test::OnlySome::RerunFailed - Load Test::OnlySome, and skip tests based on a file on disk

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=head1 SYNOPSIS

    use Test::OnlySome::RerunFailed;

This will load L<Test::OnlySome> and configure it to skip any test marked
as a clean pass by the last run of L<App::Prove::Plugin::Test::OnlySomeP>.

=head1 OPTIONS

The C<use> line can list the following options:

=over

=item C<< filename => 'some filename' >>

Specify the file from which to read test results.  The default is
C<.onlysome.yml>.

=item C<< verbose => 1 >>

If specified, print debugging information.

=back

=cut

# }}}2

sub import {
    my $self = shift;
    my %opts = @_;  # options from the `use` statement
    my @skips;      # test numbers to skip
    my ($target, $caller_fn) = caller;

    # Process options
    $opts{filename} //= DEFAULT_FILENAME;

    print STDERR "# Called from $target in $caller_fn; YML in $opts{filename}\n"
        if $opts{verbose};

    # Read the YAML file
    my $fn = _localpath(1, $opts{filename}, 1);
    my $hrCfg;
    eval { $hrCfg = LoadFile($fn); };

    if($opts{verbose}) {
        my $msg = "Configuration:\n" . Dumper($hrCfg);
        $msg =~ s/^/# /gm;
        print STDERR $msg;
    }

    if($hrCfg) {
        if($hrCfg->{$caller_fn}->{actual_passed}) {
            #my %skipped = map { $_ => 1 }
            #    @{ $hrCfg->{$caller_fn}->{skipped} // \() };
            #@skips = grep { !$skipped{$_} } @{ $hrCfg->{$caller_fn}->{actual_passed} };
            @skips = @{ $hrCfg->{$caller_fn}->{actual_passed} };
            print STDERR "# Skipping ", join(", ", @skips), "\n"
                if $opts{verbose}
        }
    }

    # Load Test::OnlySome with the appropriate skips
    'Test::OnlySome'->import::into($target,
        @skips ? 'skip' : (), @skips,
        $opts{verbose} ? (verbose => 1) : ()
    );
}

sub _localpath { # Return the path to a file in the same directory as the caller {{{2
    my $calleridx = shift or croak 'Need a caller index';
    my $newfn = shift or croak 'Need a filename';
    my $moveup = shift;

    my ($package, $filename) = caller($calleridx);

    $filename = 'dummy' unless $filename && $filename ne '-e';
        # Dummy filename assumed to be in cwd, if we're running from -e
        # or are otherwise without a caller.

    my $path = Test::OnlySome::PathCapsule->new($filename);
        # Assume the code up to this point hasn't changed cwd

    $path->up while $moveup--;
    $path->file($newfn);

    return $path->abs;
} #}}}2

1;
# vi: set fdm=marker fdl=1 fo-=ro:
