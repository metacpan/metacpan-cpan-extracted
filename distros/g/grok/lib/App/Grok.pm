package App::Grok;
BEGIN {
  $App::Grok::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Grok::VERSION = '0.26';
}

use strict;
use warnings FATAL => 'all';
use App::Grok::Resource::File qw<:ALL>;
use App::Grok::Resource::Functions qw<:ALL>;
use App::Grok::Resource::Spec qw<:ALL>;
use App::Grok::Resource::Tablet qw<:ALL>;
use App::Grok::Resource::u4x qw<:ALL>;
use Config qw<%Config>;
use File::Temp qw<tempfile>;
use File::Spec::Functions qw<catdir>;
use IO::Interactive qw<is_interactive>;
use Getopt::Long qw<:config bundling>;
use List::Util qw<first>;
use Pod::Usage;

my %opt;

our $GOT_ANSI;
BEGIN {
    if ($^O eq 'Win32') {
        eval {
            require Win32::Console::ANSI;
            $GOT_ANSI = 1;
        }
    }
    else {
        $GOT_ANSI = 1;
    }
}

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub run {
    my ($self) = @_;

    $self->_get_options();

    if ($opt{update}) {
        spec_update();
        tablet_update();
        return;
    }
    elsif ($opt{index}) {
        my @index = $self->target_index();
        print "$_\n" for @index;
        return;
    }

    my $target = defined $opt{file} ? $opt{file} : $ARGV[0];

    if ($opt{locate}) {
        if (defined $opt{file}) {
            print file_locate($opt{file}), "\n";
        }
        else {
            my $file = $self->locate_target($target);
            defined $file
                ? print $file, "\n"
                : die "Target file not found\n";
            ;
        }
    }
    else {
        my $rendered;
        if ($opt{file}) {
            $rendered = $self->render_file($opt{file}, $opt{output});
        }
        else {
            $rendered = $self->render_target($target, $opt{output});
        }

        die "Target '$target' not recognized\n" if !defined $rendered;
        $self->_print($rendered, $opt{output});
    }

    return;
}

sub _get_options {
    my ($self) = @_;

    GetOptions(
        'F|file=s'      => \$opt{file},
        'h|help'        => sub { pod2usage(1) },
        'i|index'       => \$opt{index},
        'l|locate'      => \$opt{locate},
        'o|output=s'    => \($opt{output} = $GOT_ANSI ? 'ansi' : 'text'),
        'T|no-pager'    => \$opt{no_pager},
        'u|unformatted' => sub { $opt{output} = 'pod' },
        'U|update'      => \$opt{update},
        'V|version'  => sub {
            no strict 'vars';
            my $version = defined $VERSION ? $VERSION : 'dev-git';
            print "grok $version\n";
            exit;
        },
    ) or pod2usage();

    if (!$opt{update} && !$opt{index} && !defined $opt{file} && !@ARGV) {
        warn "Too few arguments\n";
        pod2usage();
    }

    return;
}

sub target_index {
    my ($self) = @_;
    my %index;
    @index{tablet_index()} = 1;
    @index{spec_index()} = 1;
    @index{func_index()} = 1;
    @index{u4x_index()} = 1;
    return keys %index;
}

sub locate_target {
    my ($self, $target) = @_;

    my $found = u4x_locate($target);
    $found = func_locate($target) if !defined $found;
    $found = spec_locate($target) if !defined $found;
    $found = tablet_locate($target) if !defined $found;
    $found = file_locate($target) if !defined $found;

    return $found if defined $found;
    return;
}

sub detect_source {
    my ($self, $target) = @_;

    $target =~ s/.*^=encoding\b.*$//m; # skip over =encoding
    my ($first_pod) = $target =~ /^(=\S+)/m;
    return if !defined $first_pod; # no Pod found

    if ($first_pod =~ /^=(?:pod|head\d+|over)$/
            || $target =~ /^=cut\b/m) {
        return 'App::Grok::Parser::Pod5';
    }
    else {
        return 'App::Grok::Parser::Pod6';
    }
}

sub render_target {
    my ($self, $target, $output) = @_;

    my $found = u4x_fetch($target);
    $found = func_fetch($target) if !defined $found;
    $found = spec_fetch($target) if !defined $found;
    $found = tablet_fetch($target) if !defined $found;
    $found = file_fetch($target) if !defined $found;
    die "Target '$target' not recognized\n" if !defined $found;

    my $parser = $self->detect_source($found);
    eval "require $parser";
    die $@ if $@;
    return $parser->new->render_string($found, $output);
}

sub render_file {
    my ($self, $file, $output) = @_;
    
    open my $handle, '<', $file or die "Can't open $file: $!\n";
    my $pod = do { local $/ = undef; scalar <$handle> };

    my $parser = $self->detect_source($pod);
    close $handle;
    eval "require $parser";
    die $@ if $@;
    return $parser->new->render_string($pod, $output);
}

sub _print {
    my ($self, $rendered, $output) = @_;

    if ($opt{no_pager} || !is_interactive()) {
        print $rendered;
    }
    else {
        my $pager = defined $ENV{PAGER} ? $ENV{PAGER} : $Config{pager};

        my @args;
        # tell less(1) to display colors without a fuss
        push @args, '-f', '-R' if $pager =~ /less/ && $output eq 'ansi';

        my ($temp_fh, $temp) = tempfile(UNLINK => 1);
        print $temp_fh $rendered;
        close $temp_fh;

        # $pager might contain options (e.g. "more /e") so we pass a string
        $^O eq 'MSWin32'
            ? system $pager . qq{ @args "$temp"}
            : system $pager . qq{ @args '$temp'}
        ;
    }

    return;
}

1;

=encoding utf8

=head1 NAME

App::Grok - Does most of grok's heavy lifting

=head1 DESCRIPTION

This class provides the main functionality needed by grok. It has some
methods you can use if you need to hook into grok.

=head1 METHODS

=head2 C<new>

This is the constructor. It takes no arguments.

=head2 C<run>

If you call this method, it will look at the command line arguments in
C<@ARGV> and act accordingly. This is basically what the L<C<grok>|grok>
program does. Takes no arguments.

=head2 C<target_index>

Takes no arguments. Returns a list of all the targets known to C<grok>.

=head2 C<detect_source>

Takes a filename as an argument. Returns the name of the appropriate
C<App::Grok::*> class to parse it. Returns nothing if the file doesn't contain
any Pod.

=head2 C<locate_target>

Takes a target name as an argument. Returns the path to the target, or nothing
if the target is not recognized.

=head2 C<render_target>

Takes two arguments, a target and the name of an output format. Returns a
string containing the rendered documentation, or nothing if the target is
unrecognized.

=head2 C<render_file>

Takes two arguments, a filename and the name of an output format. Returns
a string containing the rendered document. B<Note:> this method is called
by L<C<render_target>|/render_target>.

=head1 AUTHOR

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik Örn Sigurðsson

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=cut
