#!perl
package Test::OnlySome::RerunFailed;
use 5.012;
use strict;
use warnings;

use Carp qw(croak);
use Import::Into;
use Best [ [qw(YAML::XS YAML)], qw(LoadFile) ];

# Docs {{{2

=head1 NAME

Test::OnlySome::RerunFailed - Load Test::OnlySome, and skip tests based on a file on disk

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=cut

# }}}2

use constant DEFAULT_FILENAME => '.onlysome.yml';   # TODO make this a parameter

# Docs {{{2

=head1 NAME

Test::OnlySome::RerunFailed - load Test::OnlySome and intialize skips

- prove plugin supporting Test::OnlySome

=head1 INSTALLATION

See L<Test::OnlySome>, with which this module is distributed.

=head1 USAGE

    use Test::OnlySome::RerunFailed;

This will load L<Test::OnlySome> and configure it to skip any test marked
as a clean pass by the last run of L<App::Prove::Plugin::Test::OnlySomeP>.

=cut

# }}}2

sub import {
    my $self = shift;
    my %opts = @_;
    my ($target, $caller_fn) = caller;

    # Process options
    $opts{filename} //= DEFAULT_FILENAME;

    #print STDERR "Called from $target in $caller_fn; YML in $opts{filename}\n";

    # Read the YAML file
    my $fn = _localpath(1, $opts{filename}, 1);
    my $hrCfg = LoadFile($fn);
    #print STDERR Dumper($hrCfg);

    # TODO pick the numbers to skip
    my @skips;
    if($hrCfg->{$caller_fn}->{actual_passed}) {
        my %skipped = map { $_ => 1 }
            @{ $hrCfg->{$caller_fn}->{skipped} // \() };
        @skips = grep { !$skipped{$_} } @{ $hrCfg->{$caller_fn}->{actual_passed} };
        #print STDERR "Skipping ", join(", ", @skips), "\n";
    }

    # Load Test::OnlySome with the appropriate skips
    'Test::OnlySome'->import::into($target, @skips ? 'skip' : (), @skips);
}

sub _localpath { # Return the path to a file in the same directory as the caller {{{2
    my $calleridx = shift or croak 'Need a caller index';
    my $newfn = shift or croak 'Need a filename';
    my $moveup = shift;

    my ($package, $filename) = caller($calleridx);

    $filename = 'dummy' unless $filename && $filename ne '-e';
        # Dummy filename assumed to be in cwd, if we're running from -e
        # or are otherwise without a caller.

    $filename = File::Spec->rel2abs($filename);
        # Assume the code up to this point hasn't changed cwd

    #print STDERR "abs: $filename\n";
    my ($vol, $dir, $file) = File::Spec->splitpath($filename);
    $dir = File::Spec->catdir($dir);
        # Trim trailing slash , if any

    if($moveup) {
        my @dirs = File::Spec->splitdir($dir);
        #print STDERR "Dirs before: ", join "\n", @dirs, "\n";
        pop @dirs while $moveup--;
        #print STDERR "Dirs after ", join "\n", @dirs, "\n";
        $dir = File::Spec->catdir(@dirs);
    }

    return File::Spec->catpath($vol, $dir, $newfn)
} #}}}2

our $VERSION = '0.000006';

=head1 VERSION

Version 0.0.6

=cut

1;

# vi: set fdm=marker fdl=1 fo-=ro:
