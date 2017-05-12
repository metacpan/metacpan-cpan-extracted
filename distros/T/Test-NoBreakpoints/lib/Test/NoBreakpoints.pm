# ABSTRACT: test that files do not contain soft breakpoints


package Test::NoBreakpoints;
{
  $Test::NoBreakpoints::VERSION = '0.15';
}
{
  $Test::NoBreakpoints::DIST = 'Test-NoBreakpoints';
}

use strict;

use File::Spec;
use File::Find;
use Test::Builder;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA       = 'Exporter';
@EXPORT    = qw|
    all_files_no_breakpoints_ok
    all_files_no_brkpts_ok
    no_breakpoints_ok
    no_brkpts_ok
|;
@EXPORT_OK = qw|all_perl_files|;
%EXPORT_TAGS = (
    all => [ @EXPORT, @EXPORT_OK ],
);

# get a Test singleton to use
my $Test = Test::Builder->new;

# a regular expression to find soft breakpoints
my $brkpt_rx = qr/
    (                   # match it
        \$DB            # The DB package
        (?:::|')        # Perl 4 or 5 package seperator
        si(?:ngle|gnal) # signal or single
        \s*=\s*         # an equal with optional whitespace
        [1-9]           # a digit other than zero
                        # (am I being stupid here?  Is there
    )                   #  no easier way to say that?)
/x;

# check that there are no breakpoints in a file
sub no_breakpoints_ok($;$)
{
    
    my($file, $name) = @_;
    $name ||= "no breakpoint test of $file";
    
    # slurp in the file
    my $fh;
    unless( open($fh, $file) ) {
        $Test->ok(0, $name);
        $Test->diag("could not open $file: $!");
        return;
    }
    my $text = do { local( $/ ) ; <$fh> } ;
    close($fh);
    
    # check the file against our regex
    my($matched) = $text =~ m/$brkpt_rx/;
    if( ! $matched ) {
        $Test->ok(1, $name);
    }
    else {
        $Test->ok(0, $name);
        $Test->diag("breakpoint found in $file: $matched");
    }
    
    return $matched ? 0 : 1;
    
}

# find all perl files in a given directory
# graciously borrwed from Test::Pod::all_pod_files by
# Andy Lester / brian d foy
sub all_perl_files
{

    my @queue = @_ ? @_ : _starting_points();
    my @files = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            push @files, $file if _is_perl( $file );
        }
    } # while

    return @files;

}


sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub _is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|m)$/;
    return 1 if $file =~ /\.t$/;

    local *FH;
    open FH, $file or return;
    my $first = <FH>;
    close FH;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return;
}        

# run no_breakpoints_ok on all files in a given directory
sub all_files_no_breakpoints_ok
{

    my @files = @_ ? @_ : all_perl_files();

    my $ok = 1; # presume all succeed
    for( @files ) {
        no_breakpoints_ok($_) or $ok = 0;
    }
    return $ok;
    
}

# keep require happy
1;




=pod

=head1 NAME

Test::NoBreakpoints - test that files do not contain soft breakpoints

=head1 VERSION

version 0.15

=head1 SYNOPSIS

 use Test::NoBreakpoints;
 plan tests => $num_tests;
 no_breakpoints_ok( $file, 'Contains no soft breakpoints' );

Module authors can include the following in a t/nobreakpoints.t file to add
such checking to a module distribution:

  use Test::More;
  eval "use Test::NoBreakpoints 0.10";
  plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
  all_files_no_breakpoints_ok();

=head1 DESCRIPTION

I love soft breakpoints (C<$DB::single = 1>) in the Perl debugger. 
Unfortunately, I have a habit of putting them in my code during development
and forgetting to take them out before I upload it to CPAN, necessitating a
hasty fix/package/bundle cycle followed by much cursing.

Test::NoBreakpoints checks that files contain neither the string
C<$DB::single = 1> nor C<$DB::signal = 1>.  By adding such a test to all my
modules, I swear less and presumably lighten the load on the CPAN in some
small way.

=head1 FUNCTIONS

Unless otherwise noted, all functions are tests built on top of
Test::Builder, so the standard admonition about having made a plan before
you run them apply.

=head2 no_breakpoints_ok($file, [$description] )

Checks that $file contains no breakpoints.  If the optional $description is
not passed it defaults to "no breakpoint test of $file".

If the test fails, the line number of the file where the breakpoint was
found will be emitted.

For compatibility with old versions of this module, the deprecated name
C<no_brkpts_ok> may also be used (but see L</"DEPRECATED FUNCTIONS">).

=head2 all_perl_files( [@dirs] )

Returns a list of all F<*.pl>, F<*.pm> and F<*.t> files in the directories
listed.  If C<@dirs> is not passed, defaults to C<blib> and C<t>.

The order of the files returned is machine-dependent.  If you want them
sorted, you'll have to sort them yourself.

=head2 all_files_no_breakpoints_ok( [@files] )

Checks all files that look like they contain Perl using no_breakpoints_ok(). If
C<@files> is not provided, it defaults to the return of B<all_perl_files()>.

For compatibility with old versions of this module, the deprecated name
C<all_files_no_brkpts_ok> may also be used (but see L</"DEPRECATED
FUNCTIONS">).

=head1 EXPORTS

By default B<all_files_no_breakpoints_ok> and B<no_breakpoints_ok>.

For the time being, the deprecated forms the above
(B<all_files_no_brkpts_ok> and B<no_brkpts_ok>) are also exported (but see
L</"DEPRECATED FUNCTIONS">).

On request, B<all_perl_files>.

Everything with the tag B<:all>.

=head1 DEPRECATED FUNCTIONS

Prior to v0.13 of this module, no_breakpoints_ok was called no_brkpts_ok and
all_files_no_breakpoints_ok was similarly abbreviated.

In v0.13, these older names were deprecated.  They are still exported by
default, but will emit a warning unless you disable the B<deprecated>
lexical warning category:

  {
    no warnings 'deprecated';
    no_brkpts_ok(...);
  }

In the next release, the deprecated functions will have to be pulled in via
an import tag.  In the release after that, they will cease to be.

=head1 ACKNOWLEDGEMENTS

Michael Schwern for Test::Builder.

Andy Lester for Test::Pod, which is where I got the idea and borrowed the
logic of B<all_perl_files> from.

=head1 BUGS

=over 4

=item * doesn't catch some breakpoints

This is a valid breakpoint:

  package DB;
  $single = 1;
  package main;

as is this:

  my $break = \$DB::single;
  $$break = 1;

but neither are currently caught.

=back

=head1 TODO

=over 4

=item * enhance regex to find esoteric setting of breakpoints

If you have a legitimate breakpoint set that isn't caught, please send me an
example and I'll try to augment the regex to match it.

=item * only look at code rather than the entire file

This is not as easy as simply stripping out POD, because there might be
inline tests or examples that are code in there (using Test::Inline).
Granted, those should be caught when the generated .t files are themselves
tested, but I'd like to make it smarter.

=item * not use regular expressions

The ideal way to find a breakpoint would be to compile the code and then
walk the opcode tree to find places where the breakpoint is set. 
B::FindAmpersand does something similar to this to find use of the C<$&> in
regular expressions, so this is probably the direction I'm going to head in.

=back

=head1 SEE ALSO

L<Test::Builder>

L<Test::Pod>

=head1 AUTHORS

=over 4

=item *

James FitzGibbon <jfitz@cpan.org>

=item *

Apocalypse <APOCAL@cpan.org>

=item *

Chisel <chisel@chizography.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James FitzGibbon and Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

