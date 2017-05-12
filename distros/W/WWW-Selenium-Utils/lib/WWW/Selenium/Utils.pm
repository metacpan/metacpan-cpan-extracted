package WWW::Selenium::Utils;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Find;
use Config;
use WWW::Selenium::Utils::Actions qw(%selenium_actions);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(generate_suite cat parse_wikifile);

our $VERSION = '0.09';

sub html_header;
sub html_footer;

sub generate_suite {
    my %opts = @_;

    my %config = parse_config();
    $opts{$_} ||= $config{$_} for keys %config;

    croak "Must provide a directory of tests!\n" unless $opts{test_dir};

    _generate_suite( %opts );

    # create a test Suite index
    create_suite_index($opts{test_dir}, $opts{index}) if $opts{index};
}

sub _generate_suite {
    my %opts = @_;
    my $testdir = $opts{test_dir};
    $testdir =~ s#/$##;
    croak "$testdir is not a directory!\n" unless -d $testdir;
    my $files = $opts{files} || test_files($testdir, $opts{perdir}, \%opts);

    my $suite = "$testdir/TestSuite.html";
    my $date = localtime;

    open(my $fh, ">$suite.tmp") or croak "Can't open $suite.tmp: $!";
    print $fh html_header(title => "Test Suite",
                          text  => "Generated at $date",
                         );

    my $tests_added = 0;
    for (sort {$a cmp $b} @$files) {
        next if /(?:\.tmp|TestSuite\.html)$/;

        my $f = $_;
        my $fp = "$testdir/$f";
        if ($f =~ /(.+)\.html$/) {
            my $basename = $1;
            # skip html files that we have or will generate
            next if -e "$testdir/$basename.wiki";
            # find orphaned html files
            my $html = cat($fp);
            if ($html =~ m#Auto-generated from $testdir/$basename\.wiki# and 
                        !-e "$testdir/$basename.wiki") {
                print "Deleting orphaned file $fp\n" if $opts{verbose};
                unlink $fp or croak "Can't unlink $fp: $!";
                next;
            }
        }

        print "Adding row for $f\n" if $opts{verbose};
        if (/\.wiki$/) {
            $f = wiki2html($fp, 
                           verbose => $opts{verbose},
                           base_href => $opts{base_href});
            $f =~ s/^$testdir\///;
            $fp = "$testdir/$f";
        }
        my $title = find_title($fp);
        print $fh qq(\t<tr><td><a href="./$f">$title</a></td></tr>\n);
        $tests_added++;
    }
    #print the footer
    print $fh html_footer();
    close $fh or croak "Can't close $suite.tmp: $!";

    if ($tests_added) {
        # rename into place
        rename "$suite.tmp", $suite or croak "can't rename $suite.tmp $suite: $!";
        print "Created new $suite\n" if $opts{verbose};
    }
    else {
        unlink "$suite.tmp";
    }
}

sub test_files {
    my ($testdir, $perdir, $opts) = @_;

    my @tests;
    if ($perdir) {
        my @files = glob("$testdir/*");
        foreach my $f (@files) {
            if (-d $f) {
                $opts->{test_dir} = $f;
                generate_suite( %$opts );
                next;
            }
            push @tests, $f;
        }
    }
    else {
        find(sub { push @tests, $File::Find::name }, $testdir);
    }

    @tests = grep { !-d $_ and m#(?:wiki|html)$# } @tests;
    for (@tests) {
        s#^$testdir/?##;
        s#^.+/tests/##;
    }

    return \@tests;
}

sub wiki2html {
    my ($wiki, %opts) = @_;
    my $verbose = $opts{verbose};
    my $base_href = $opts{base_href};
    $base_href =~ s#/$## if $base_href;

    (my $html = $wiki) =~ s#\.wiki$#.html#;

    my $results = parse_wikifile(filename => $wiki, 
                                 base_href => $base_href);
    if ($results->{errors}) {
        croak "Error parsing file $wiki:\n  " 
              . join("\n  ", @{$results->{errors}})
              . "\n";
    }

    print "Generating html for ($results->{title}): $html\n" if $verbose;
    open(my $out, ">$html") or croak "Can't open $html: $!";
    print $out html_header( title => $results->{title},
                    text => "<b>Auto-generated from $wiki</b><br />");
    foreach my $r (@{$results->{rows}}) {
        print $out "\n\t<tr>",
                   join('', map "<td>$_</td>", @$r),
                   "</tr>\n";
    }

    my $now = localtime;
    print $out html_footer("<hr />Auto-generated from $wiki at $now\n");
    close $out or croak "Can't write $html: $!";
    return $html;
}

sub parse_wikifile {
    my %opts = @_;
    my $filename = $opts{filename};
    my $base_href = $opts{base_href};
    my $include   = $opts{include};
    (my $base_dir = $filename) =~ s#(.+)/.+$#$1#;

    my $title;
    my @rows;
    my @errors;

    # $. and $_ are global, so we don't need to pass them in
    # to this closure
    my $parse_error = sub {
        push @errors, "line $.: $_[0] ($_)";
    };

    open(my $in, $filename) or croak "Can't open $filename: $!";
    while(<$in>) {
        s/^\s*//;
        next if /^#/ or /^\s*$/;
        chomp;

        # included files won't have a title
        if (not defined $title and not $include) {
            $title = $_;
            $title =~ s#^\s*##;
            $title =~ s#^\|(.+)\|$#$1#;
            next;
        }
        elsif (/^\s*                   # some possible leading space
                \|\s*([^\|]+?)\s*\|    # cmd
                (?:\s*([^\|]+?)\s*\|)? # opt1 (optional)
                (?:\s*([^\|]+?)\s*\|)? # opt2 (optional)
                \s*$/x) {
            my ($cmd, $opt1, $opt2) = ($1,$2,$3);
            $parse_error->("No command found") and next unless $cmd;

            my $numargs = (grep { defined $_ } ($opt1, $opt2));
            my $expected_args = $selenium_actions{lc($cmd)};
            if (defined $expected_args and $expected_args != $numargs) {
                $parse_error->("Incorrect number of arguments for $cmd");
                next;
            }

            $opt1 = '&nbsp;' unless defined $opt1;
            $opt2 = '&nbsp;' unless defined $opt2;
            if ($base_href and ($cmd eq "open" or 
                                $cmd =~ /(?:assert|verify)Location/)) {
                $opt1 =~ s#^/##;
                $opt1 = "$base_href/$opt1";
            }
            push @rows, [ $cmd, $opt1, $opt2 ];
        }
        elsif (/^\s*include\s+(.+)\s*$/) {
            my $incl = $1;
            $incl = "$base_dir/$1" unless -e $1;
            unless (-e $incl) {
                $parse_error->("Can't include $incl - file doesn't exist!");
                next;
            }
            my $r = parse_wikifile( %opts, filename => $incl, 
                                          include => 1);
            push @rows,   @{$r->{rows}}   if $r->{rows};
            push @errors, @{$r->{errors}} if $r->{errors};
        }
        else { 
            $parse_error->("Invalid line");
        }
    }
    close $in or croak "Can't close $filename: $!";
    return { $title ? (title => $title) : (),
             @errors ? (errors => \@errors) : (),
             rows  => \@rows,
           };
}

sub find_title {
    my $filename = shift;

    open(my $fh, $filename) or croak "Can't open $filename: $!";
    my $contents;
    { 
        local $/;
        $contents = <$fh>;
    }
    close $fh or croak "Can't close $filename: $!";

    return $filename unless $contents;
    return $1 if $contents =~ m#<title>\s*(.+)\s*</title>#;
    return $1 if $filename =~ m#^.+/(.+)\.html$#;
    return $filename;
}

sub create_suite_index {
    my ($testdir, $index) = @_;
    my @suites;
    find( sub { push @suites, $File::Find::name if /TestSuite\.html$/ }, $testdir);
    return unless @suites;
    
    (my $index_dir = $index) =~ s#^(.+)/.+$#$1#;
    open(my $fh, ">$index.tmp") or croak "Can't open $index.tmp: $!";
    print $fh html_header(title => "Selenium TestSuites");
    foreach my $s (@suites) {
        my $name = "Main";
        $name = $1 if $s =~ m#\Q$testdir\E/(.+)/TestSuite\.html$#;
        (my $link = $s) =~ s#\Q$index_dir\E/##;
        print $fh qq(\t<tr><td><a href="TestRunner.html?test=./$link">$name TestSuite</a></td></tr>\n);
    }
    print $fh html_footer;
    close $fh or croak "Can't write $index.tmp: $!";
    rename "$index.tmp", $index or croak "Can't rename $index.tmp to $index: $!";
}

sub html_header {
    my %opts = @_;
    my $title = $opts{title} || 'Generic Title';
    my $text = $opts{text} || '';

    my $header = <<EOT;
<html>
  <head>
    <meta content="text/html; charset=ISO-8859-1"
          http-equiv="content-type">
    <title>$title</title>
  </head>
  <body>
    $text
    <table cellpadding="1" cellspacing="1" border="1">
      <tbody>
        <tr>
          <td rowspan="1" colspan="3">$title</td>
        </tr>
EOT
    return $header;
}

sub html_footer {
    my $text = shift || '';
    return <<EOT;
      </tbody>
    </table>
    $text
  </body>
</html>
EOT
}

sub cat {
    my $file = shift;
    my $contents;
    eval {
        open(my $fh, $file) or croak "Can't open $file: $!";
        { 
            local $/;
            $contents = <$fh>;
        }
        close $fh or croak "Can't close $file: $!";
    };
    warn if $@;
    return $contents;
}

sub parse_config {
    my $file = ($ENV{SELUTILS_ROOT} || $Config{prefix}) . "/etc/selutils.conf";
    return () unless -e $file;
    # try evaling the file (current file format)
    open(my $fh, $file) or croak "Can't open $file: $!";
    my $contents;
    { 
        local $/ = undef;
        $contents = <$fh>;
    }
    close $fh or die "Can't close $file: $!";

    our $perdir;
    our $test_dir;
    our $index;
    { 
        local $SIG{__WARN__} = sub {}; # hide eval errors
        eval $contents;
    }
    my $eval_err = $@;

    # failed to eval file - try reading as an old style config
    if ($eval_err) {
        while($contents =~ /^\s*(\w+)\s*=\s*['"]?([^'"]+)['"]?\s*$/mg) {
            $perdir = $2 if $1 eq 'perdir';
            $index = $2 if $1 eq 'index';
            $test_dir = $2 if $1 eq 'test_dir';
        }
        warn "$file eval error: $eval_err\n" unless $test_dir;
    }
    my %config = ( perdir => $perdir,
                   test_dir => $test_dir,
                   index => $index,
                 );
    return %config;
}

1;
__END__

=head1 NAME

WWW::Selenium::Utils - helper functions for working with Selenium

=head1 SYNOPSIS

  use WWW::Selenium::Utils qw(generate_suite);

  # convert .wiki files to .html and create TestSuite.html
  generate_suite( test_dir => "/var/www/selenium/tests",
                  base_href => "/monkey",
                  verbose => 1,
                );

=head1 DESCRIPTION

This package contains utility functions for working with Selenium.

=head1 SUBROUTINES

=head2 generate_suite

C<generate_suite()> will convert all .wiki files in selenium/tests to .html,
and then create a TestSuite.html file that contains links to all the .html 
files.

The .wiki files are much easier to read and write.  The format of .wiki files
is like this:

  title
  | cmd | opt1 | opt2 |
  | cmd | opt1 |
  # comment

  # empty lines are ignored
  # comments are ignored too

  # you can include other wiki files too!  These files should not 
  # have a title.  I'll look for the file in the same directory
  # as the current .wiki file
  include "foo.incl"

  # if you don't want included files to also be converted to html,
  # then don't name them .wiki

Parameters:

=over 4

=item test_dir

The path to the 'tests' directory inside selenium.

=item verbose

If true, informative messages will be printed.

=item base_href

Will prepend the given location to all locations for the
open and assert/verifyLocation commands.

=item perdir

Will create a separate TestSuite.html for each directory
under test_dir.

=item index

Will create a html index of all available TestSuite.html files
found inside test_dir.

=back

generate_suite() will parse a config file if present at either 
$ENV{SELUTILS_ROOT}/etc/selutils.conf or $Config{prefix}/etc/selutils.conf.

Supported options in selutils.conf and are the same as the generate_suite()
arguments:

=over 4

=item test_dir

=item perdir 

=back

=head1 INTEGRATION WITH SELENIUM RECORDER

Selenium Recorder is Firefox extension that records your actions as you
browse. The result is a test file that can be played back in Selenium. 

It's quite easy to make Selenium Recorder generate a syntax that
is directly compatible with the wiki syntax suggested here. 

In Selenium Recorder 0.6, you can update templates by opening
the "Preferences" from the Extension panel of Firefox, and then
clicking "Save". Adjust the input fields as follows:

Template for new test html file

 ${name}
 ${commands}

Template for command entries in the test html file

 | ${command.command} | ${command.target} | ${command.value} |

Template for comment entries in the test html file

 # ${comment.comment}

Further information about Selenium Recorder is available at:

  http://www.openqa.org/selenium-ide/

=head1 DIAGNOSTICS

If you set the C<verbose> option to 1 when calling generate_suite, the function
will print lines detailing what it is doing.

=head1 DEPENDENCIES

Uses CGI.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problums to Luke Closs (cpan@5thplane.com).
Patches are welcome.

=head1 AUTHOR

Luke Closs (cpan@5thplane.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005 Luke Closs (cpan@5thplane.com).  All rights reserved.

This module is free software; you can redstribute it and/or
modify it under the same terms as Perl itself.  See L<perlartistic>.

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

