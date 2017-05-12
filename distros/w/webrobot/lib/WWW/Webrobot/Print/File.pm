package WWW::Webrobot::Print::File;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use WWW::Webrobot::Attributes qw(dir diff_mode idx url orig_url error);

my $name_index = "index";


=head1 NAME

WWW::Webrobot::Print::File - Store received content on disk and compare to a second run

=head1 SYNOPSIS

See L<WWW::Webrobot::pod::OutputListeners>

 File->new();
 File->new(dir => "directory_name");
 File->new(dir => "dir_name", diff_mode => "dir_name_for_diff");

=head1 DESCRIPTION

This module stores received content on a file.
The filenames are integers.
There is an additional file C<index> that stores the mapping
from filenames to url.

It may be used to refactor an application.


=head1 USAGE

You may use this mode for refactoring an application.

=over

=item

For the first run use C<dir => "mylocaldir">.
This run stores all results in C<mylocaldir>.

=item

Now you may refactor your application.

=item

Then run with  C<dir => "mynewdir", diff_mode => "mylocaldir">.
It stores the result in C<mynewdir> and checks all differences to C<mylocaldir>.

=back


=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=over

=item new(%parms)

 dir            Directory name where to put the files
                (there is a default if argument is missing)

 diff_mode      If defined use diff mode, directory to diff is the value
                of diff_mode

=back

=cut

sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my %parm = (@_);

    # normalize parameters
    $parm{dir} = funny_filename("dir") if ! defined $parm{dir};

    $self->dir($parm{dir});
    $self->diff_mode($parm{diff_mode} || undef);

    # create directories
    -d $self->dir or mkdir $self->dir or die "Can't make dir=$self->{_dir} err=$!";
    if ($self->diff_mode) {
        -d $self->{_diff_mode} or die "Directory=$self->{_diff_mode} not available, err=$!";
    }

    $self->idx(0);
    $self->url([]);
    $self->orig_url([]);

    return $self;
}


# static
sub funny_filename {
    my ($prefix) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year += 1900;
    $mon += 1;
    return sprintf "${prefix}_%4d-%02d-%02d_%02d-%02d-%02d",
        $year, $mon, $mday, $hour, $min, $sec;
}


sub global_start {
    my $self = shift;
    my $dir = $self->dir;
    open(INDEX, ">$dir/$name_index") or die "Can't open $dir/$name_index";
    
    if (my $diff_dir = $self->diff_mode) {
        open(OIND, "<$diff_dir/$name_index") or die "Can't open $diff_dir";
        while (my $line = <OIND>) {
            chomp $line;
            my ($index, $url) = split /\s+/, $line, 2;
            $self->orig_url->[$index] = $url;
        }
        close OIND;
    }
}

sub global_end {
    my $self = shift;
    close INDEX;
    my $err = $self->error;
    if ($err) {
        my $pl = $err > 1 ? "s" : "";
        print "Summary: $err error$pl found.\n"
    }
    else {
        print "No errors found.\n";
    }
}

sub item_pre {
    my $self = shift;
}


sub item_post {
    my ($self, $r, $arg) = @_;

    my $last = $r;
    $last = $last->previous while defined $last->previous;

    my $idx = $self->idx;
    my $uri = $last->request->uri;

    push @{$self->{_url}}, $uri;
    print INDEX "$idx $uri\n";

    my $filename = $self->dir. "/$idx";
    if (! open(FILE, ">$filename")) {
        $self->{_error}++;
        print "$idx: FAIL: Can't write to new file=$filename";
    }
    else {
        print FILE $r->content;
        close FILE;
        if (my $diff_dir = $self->diff_mode) {
            my $orig_filename = $self->diff_mode . "/$idx";
            if ($self->url->[$idx] ne $self->orig_url->[$idx]) {
                $self->{_error}++;
                print "$idx: FAIL: URLs differ\n",
                    "    url1:", $self->url->[$idx], ":\n",
                    "    url2:", $self->orig_url->[$idx], ":\n",
                    "    filename orig: $orig_filename\n",
                    "    filename new : $filename\n";
            }
            elsif (open(OLDFILE, "<$orig_filename")) {
                my $orig_content = join "", <OLDFILE>;
                close OLDFILE;
                if ($r->content eq $orig_content) {
                    print "$idx: ok\n";
                }
                else {
                    $self->{_error}++;
                    print "$idx: FAIL: content differs\n",
                        "    url: ", $self->url->[$idx], "\n",
                        "    filename orig: $orig_filename\n",
                        "    filename new : $filename\n";
                }
            }
            else {
                $self->{_error}++;
                print "$idx: FAIL: Can't read orig file=$orig_filename\n";
            }
        }
    }
    $self->idx($idx + 1);
}


=head1 BUGS

You can't run it twice using C<dir => "...">
and compare the two resulting directories afterwards.
You must run in I<diff_mode> in your second (third ...) run.

=cut

1;
