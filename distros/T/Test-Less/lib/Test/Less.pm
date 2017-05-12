package Test::Less;
use Spiffy 0.24 -Base;
use Spiffy ':XXX';
our $VERSION = '0.11';
our @EXPORT = qw(run);

field silent => 0;
field quiet => 0;
field verbose => 0;
field 'comment';

field index => 
      -init => '$self->index_class->new(file => $self->index_file)';
field index_file => 
      $ENV{TEST_LESS_INDEX} || 
      't/Test-Less/index.txt';
field index_class => 'Test::Less::Index';

sub run {
    my @args = @_ ? @_ : @ARGV;
    @args = map {
        $_ eq '-'
        ? do {
            local $/;
            split /\s+/, <STDIN>
        }
        : ($_);
    } @args;
    Test::Less->new->run_command_line(@args);
}

sub run_command_line {
    my ($command, @arguments) = $self->parse_command_line(@_);
    my $method ="run_$command";
    $self->$method(@arguments);
}

sub run_tag { $self->tag(@_) }
sub run_untag { $self->untag(@_) }
sub run_prove { $self->prove(@_) }
sub run_show { $self->show(@_) }
sub run_list { 
    print "$_\n" for $self->list(@_);
}

# Action handlers
sub tag {
    my ($tags, $files) = $self->parse_tags_and_files(@_);
    warn "No files specified\n" unless @$files;
    for my $file (@$files) {
        $self->tag_file($file, @$tags);
    }
}

sub untag {
    my ($tags, $files) = $self->parse_tags_and_files(@_);
    for my $file (@$files) {
        $self->untag_file($file, @$tags);
    }
}

sub show {
    for my $file ($self->parse_files(@_)) {
        my @tags = $self->index->tags_for_file($file);
        print "$file:\n  @tags\n";
    }
}

sub list {
    my $spec = $self->parse_spec(@_);
    $self->index->files_matching_spec($spec);
}

sub prove {
    my ($flags, @args) = $self->parse_flags(@_);
    exec {$self->bin_path('prove')} 'prove', @$flags, $self->list(@args);
}

# Command parsers
sub parse_flags {
    my @args = @_;
    my @flags;
    while (@args and $args[0] =~ /^-/) {
        push @flags, shift @args;
    }
    return ([@flags], @args);
}

sub parse_spec {
    my @args = @_;
    my $spec = [];
    for my $part (@args) {
        if ($part =~ /,/) {
            push @$spec, [split ',', $part];
        }
        else {
            push @$spec, $part;
        }
    }
    return $spec;
}

sub parse_command_line {
    my @words = @_;
    while (my ($word) = @words) {
        if ($word =~ /^(-q|--quiet)$/) {
            $self->quiet(1);
            shift @words;
            next;
        }
        if ($word =~ /^(-v|--verbose)$/) {
            $self->verbose(1);
            shift @words;
            next;
        }
        if ($word =~ /^(?:-f|--file)(?:=(\S+))?$/) {
            shift @words;
            my $file = $1 || shift(@words)
              or $self->usage;
            $self->index_file($file);
            next;
        }
        last;
    }

    my $word = shift(@words)
      or $self->usage;
    my $command =
        $word =~ /^-?-t(ag)?$/ ? 'tag' :
        $word =~ /^-?-u(ntag)?$/ ? 'untag' :
        $word =~ /^-?-s(how)?$/ ? 'show' :
        $word =~ /^-?-l(ist)?$/ ? 'list' :
        $word =~ /^-?-p(rove)?$/ ? 'prove' :
        $self->usage;
    return ($command, @words);
}

sub parse_tags_and_files {
    my @args = @_;
    my (@tags, @files);
    while (@args) {
        last unless $args[0] =~ /^[\w-]+$/;
        push @tags, shift @args;
    }
    @files = @args;
    return (\@tags, \@files);
}

sub parse_files {
    my @args = @_;
    return @args
    ? (@args)
    : ($self->index->all_files);
}

# Other routines
sub tag_file {
    my $file = shift;
    my @tags = @_;
    my $index = $self->index;
    for my $tag (@tags) {
        $index->add_tag_file($tag, $file, $self->get_comment)
          or $self->msg2("Can't add tag '$tag' to file '$file'");
    }
    $index->write;
}

sub untag_file {
    my $file = shift;
    my @tags = @_;
    my $index = $self->index;
    for my $tag (@tags) {
        $index->remove_tag_file($tag, $file)
          or $self->msg2("Can't remove tag '$tag' from file '$file'");
    }
    $index->write;
}

sub get_comment {
    my $comment = $self->comment;
    $comment = $ENV{TEST_LESS_COMMENT} || ''
      unless defined $comment;
    my $date = scalar(gmtime);
    $date =~ s/^(mon|tue|wed|thu|fri|sat|sun)\s+//i;
    $date .= ' GMT';
    $comment =~ s/\$d/$date/ge;
    $comment =~ s/\$u/$ENV{USER}/ge;
    return $comment;
}

sub bin_path {
    require Config;
    require File::Spec;
    my $bin = $Config::Config{sitebin};
    File::Spec->catfile($bin, shift);
}

sub usage {
    print <<'END'; exit 0;
Usage: test-less [options] command [arguments] [-]

Options:
  -file path_to_index_file
  -quiet
  -verbose

Commands:
  -help
  -tag tags test-files
  -untag tags test-files
  -show test-files
  -list tag-specification
  -prove [prove-flags] tag-specification

Options and commands may be abbreviated to their first letter.

An argument of '-' is replaced by the contents of STDIN split on whitespace.

END
}

# I/O Stuff

sub msg {
    my @args = @_;
    chomp $args[-1];
    warn join '', @_, "\n";
}

sub msg_threshold {
    return 4 if $self->silent;
    2 + $self->quiet - $self->verbose;
}

sub msg1 {
    return if $self->msg_threshold > 1;
    $self->msg(@_);
}

sub msg2 {
    return if $self->msg_threshold > 2;
    $self->msg(@_);
}

sub msg3 {
    return if $self->msg_threshold > 3;
    $self->msg(@_);
}

sub prompt {
    print shift;
    my $answer = <>;
    chomp $answer;
    return $answer;
}

package Test::Less::Index;
use Spiffy -base;
use Spiffy ':XXX';

field file => -init => 'die';
field index => -init => '$self->read';

sub add_tag_file {
    my ($tag, $file, $comment) = @_;
    return unless -f $file;
    $comment ||= '';
    $self->index->{$tag}{$file} = $comment;
    return 1;
}

sub remove_tag_file {
    my ($tag, $file) = @_;
    my $index = $self->index;
    return defined(delete $index->{$tag}{$file}) ? 1 : 0;
}

sub all_files {
    my $index = $self->index;
    my %set = map {
        map { ($_, 1) } keys %{$index->{$_}};
    } keys %$index;
    return sort keys %set;
}

sub files_matching_spec {
    my $spec = shift;
    my $files = {};
    for my $sub (@$spec) {
        if (ref $sub) {
            $self->list_add($files, $self->files_matching_list($sub));
        }
        elsif ($sub =~ /^\^(.*)/) {
            my $term = $1;
            $self->list_add($files, $self->all_files);
            $self->list_del($files, $self->files_matching($term));
        }
        else {
            $self->list_add($files, $self->files_matching($sub));
        }
    }
    return sort keys %$files;
}

sub files_matching_list {
    my $spec = shift;
    my $files = {};
    $self->list_add($files, $self->all_files);
    for my $term (@$spec) {
        if ($term =~ s/^\^//) {
            $self->list_del($files, $self->files_matching($term));
        }
        else {
            $self->list_neg($files, $self->files_matching($term));
        }
    }
    return keys %$files;
}

sub files_matching {
    my @files = ();
    for my $term (@_) {
        if ($term =~ /[^\w\-]/) {
            push @files, $term;
        }
        else {
            push @files, keys %{$self->index->{$term}};
        }
    }
    return @files;
}

sub list_add {
    my $list = shift;
    for my $file (@_) {
        $list->{$file} = '';
    }
}

sub list_del {
    my $list = shift;
    for my $file (@_) {
        delete $list->{$file};
    }
}

sub list_neg {
    my $list = shift;
    my %keep = map {($_, 1)} @_;
    for my $file (keys %$list) {
        delete $list->{$file}
          unless defined $keep{$file};
    }
}

sub tags_for_file {
    my $query = shift;
    my $index = $self->index;
    my @set;
    for my $tag (sort keys %$index) {
        for my $file (keys %{$index->{$tag}}) {
            push @set, $tag
              if $file eq $query;
        }
    }
    return @set;
}

sub read {
    my $index = {};
    my $file = $self->file;
    return $index
      unless -f $file and 
      open INDEX, $file;
    while (my $line = <INDEX>) {
        next if $line =~ /^#/;
        chomp $line;
        my ($tag, $file, $comment) = split /\s+/, $line, 3;
        $comment ||= '';
        $index->{$tag}{$file} = $comment;
    }
    close INDEX;
    return $index;
}

sub write {
    my $index = $self->index;
    my $file = $self->file;
    $self->assert_path($file);
    open INDEX, "> $file"
      or die "Can't open $file for output:\n$!";
    print INDEX $self->preamble;
    for my $tag (sort keys %$index) {
        my $files = $index->{$tag};
        for my $file (sort keys %$files) {
            my $comment = $files->{$file};
            print INDEX "$tag $file";
            print INDEX "\t$comment"
              if $comment;
            print INDEX "\n";
        }
    }
    print INDEX $self->postamble;
    close INDEX;
    $self->index(undef);
}

sub preamble {
    return <<'_';
# This file is an index for the `test-less` facility.
#
# More information can be found at:
#   http://search.cpan.org/search?query=Test-Less;mode=dist
#
_
}

sub postamble {
    '';
}

sub assert_path {
    my $file = shift;
    return if -e $file;
    return unless $file =~ /(.+)[\\\/]/;
    my $dir = $1 or return;
    return if -d $dir;
    mkdir $dir;
}

__DATA__

=head1 NAME

Test::Less - Test Categorization and Subset Execution

=head1 SYNOPSIS

    # Mark foo and bar tests with 4 tags
    > test-less -tag slow unit 3743 gui t/foo.t t/bar.t

    # Unmark t/bar.t as a gui test
    > test-less -untag gui t/bar.t
    
    # Show tags for all the tests in t/
    > test-less -show t/*.t

    # List the unit tests for ticket 3743, except the gui ones
    > test-less -list unit,3743,^gui

    # Prove (run) all gui unit tests
    > test-less -prove -v gui,unit

    # Same as above
    > prove -l `test-less -list gui,unit`

    # Without `test-less` program:
    > perl -MTest::Less -e "run" -prove -l gui,unit
    
=head1 DESCRIPTION

Sometimes Less is More.

Test::Less really has nothing to do with Test::More. It is also not
meant to discourage you from writing lots of tests. To the contrary, it
allows you to write potentially thousands of tests, but then be
selective about which ones you run and when.

The fact is that sometimes Test::Harness testing can be slow. You don't
always want to run every test in your C<t/> directory, especially if
they take an hour or more to run.

Test::Less allows you to categorize your tests with keyword tags, and
then select which group of tests should be run for the problem at hand.

=head1 COMMAND LINE USAGE

Test::Less installs a program called C<test-less> in your Perl bin
directory. You use this command to tag, list and run your various
groups of tests.

C<test-less> normally keeps the index file of mappings between tags
and test files, in a file called C<t/Test-Less/index.txt>. You can
override this with the C<--file> option or the C<TEST_LESS_INDEX>
environment variable.

=head1 TAGS

Tags are strings matching C</^[\w\-]+$/>. 

The C<-list> and C<-prove> commands take what is called a I<tag
specification>.

A specication is a a list of tags and possibly file names.

    test-less -prove foo bar baz

Runs all the foo tests, bar tests and baz tests.

    test-less -prove foo,bar,baz

Runs all the tests that are foo and bar and baz.

    test-less -prove foo,^bar

Runs all the tests that are foo but not bar.

    test-less -prove ^foo

Runs all the tests that are in the Test-Less index file, except
the foo ones.

etc...

You can pipe the output of one command to another:

    test-less -list foo | test-less -prove -
    test-less -lisr foo | test-less -untag bar

=head1 PROGRAMATIC USAGE

Test::Less is object oriented, and it is very easy to use its
functionality from another program:

    use Test::Less;

    my $tl = Test::Less->new(
        index_file => 'my_index',
    );

    $tl->prove('-l', '-b', 'foo,bar,^baz boom');

=head1 THE INDEX FILE

Test::Less keeps all of its tag and file mappings in a text file called
(by default) C<t/Test-Less/index.txt>. This file is autogenerated by
Test::Less but can be edited by hand. The file consists of comment lines
(that begin with C<#>) and index lines of the form:

    tag file    optional_comment

The index lines are written in sorted order by tag and then file. This
rather verbose format is used so that it plays nice with revision
control on projects where many people are changing the file.

=head1 ENVIRONMENT VARIABLES

Test::Less uses some special purpose environment variables.

=over

=item TEST_LESS_INDEX

The path to the index file to be used by C<test-less>.

=item TEST_LESS_COMMENT

A comment string to be added to new index entries. C<$d> and C<$u> are
special variables that expanf to GMT date/time and current user.

    TEST_LESS_COMMENT='$d -- $u'

will expand to something like:

    Jun  4 23:22:12 2005 GMT -- ingy

=back

=head1 TIPS AND TRICKS

Here are some helpful tips from my personal experience using
Test::Less. If you have a helpful tip, please send it to me, and I'll
include it here.

Go ahead and check in the C<index.txt> file into your code repository
and C<MANIFEST> file. It is useful info that other people can use if
they want to.

When working on a bug fix from an RT ticket, use the ticket number as a
tag. Like C<2143> or C<rt2143>.

Feel free to hand edit the C<index.txt> file.

Consider using the following shell aliases or something equivalent:

    alias tl='test-less'
    alias tlp='test-less -prove'
    alias tlt='test-less -tag'

etc...

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
