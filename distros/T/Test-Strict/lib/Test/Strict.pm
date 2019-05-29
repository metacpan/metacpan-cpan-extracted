package Test::Strict;

=head1 NAME

Test::Strict - Check syntax, presence of use strict; and test coverage

=head1 VERSION

Version 0.48

=head1 SYNOPSIS

C<Test::Strict> lets you check the syntax, presence of C<use strict;>
and presence C<use warnings;> in your perl code.
It report its results in standard L<Test::Simple> fashion:

    use Test::Strict tests => 3;
    syntax_ok( 'bin/myscript.pl' );
    strict_ok( 'My::Module', "use strict; in My::Module" );
    warnings_ok( 'lib/My/Module.pm' );

Module authors can include the following in a t/strict.t
and have C<Test::Strict> automatically find and check
all perl files in a module distribution:

  use Test::Strict;
  all_perl_files_ok(); # Syntax ok and use strict;

or

    use Test::Strict;
    all_perl_files_ok( @mydirs );

C<Test::Strict> can also enforce a minimum test coverage
the test suite should reach.
Module authors can include the following in a t/cover.t
and have C<Test::Strict> automatically check the test coverage:

    use Test::Strict;
    all_cover_ok( 80 );  # at least 80% coverage

or

    use Test::Strict;
    all_cover_ok( 80, 't/' );

=head1 DESCRIPTION

The most basic test one can write is "does it compile ?".
This module tests if the code compiles and play nice with L<Test::Simple> modules.

Another good practice this module can test is to "use strict;" in all perl files.

By setting a minimum test coverage through C<all_cover_ok()>, a code author
can ensure his code is tested above a preset level of I<kwality> throughout the development cycle.

Along with L<Test::Pod>, this module can provide the first tests to setup for a module author.

This module should be able to run under the -T flag for perl >= 5.6.
All paths are untainted with the following pattern: C<qr|^([-+@\w./:\\]+)$|>
controlled by C<$Test::Strict::UNTAINT_PATTERN>.

=cut

use strict; use warnings;
use 5.006;
use Test::Builder;
use File::Spec;
use FindBin qw($Bin);
use File::Find;
use Config;

our $COVER;
our $VERSION = '0.48';
our $PERL    = $^X || 'perl';
our $COVERAGE_THRESHOLD = 50; # 50%
our $UNTAINT_PATTERN    = qr|^(.*)$|;
our $PERL_PATTERN       = qr/^#!.*perl/;
our $CAN_USE_WARNINGS   = ($] >= 5.006);
our $TEST_SYNTAX   = 1;  # Check compile
our $TEST_STRICT   = 1;  # Check use strict;
our $TEST_WARNINGS = 0;  # Check use warnings;
our $TEST_SKIP     = []; # List of files to skip check
our $DEVEL_COVER_OPTIONS = '+ignore,".Test.Strict\b"';
our $DEVEL_COVER_DB      = 'cover_db';
my $IS_WINDOWS = $^O =~ /MSwin/i;

my $Test  = Test::Builder->new;
my $updir = File::Spec->updir();
my %file_find_arg = ($] <= 5.006) ? ()
                                  : (
                                      untaint         => 1,
                                      untaint_pattern => $UNTAINT_PATTERN,
                                      untaint_skip    => 1,
                                    );

sub import {
    my $self   = shift;
    my $caller = caller;

    {
        no strict 'refs';
        *{$caller.'::strict_ok'}         = \&strict_ok;
        *{$caller.'::warnings_ok'}       = \&warnings_ok;
        *{$caller.'::syntax_ok'}         = \&syntax_ok;
        *{$caller.'::all_perl_files_ok'} = \&all_perl_files_ok;
        *{$caller.'::all_cover_ok'}      = \&all_cover_ok;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}

##
## _all_perl_files( @dirs )
## Returns a list of perl files in @dir
## if @dir is not provided, it searches from one dir level above
##
sub _all_perl_files {
    my @all_files = _all_files(@_);
    return grep { _is_perl_module($_) || _is_perl_script($_) } @all_files;
}

sub _all_files {
    my @base_dirs = @_ ? @_
        : File::Spec->catdir($Bin, $updir);
    my @found;
    my $want_sub = sub {
        #return if ($File::Find::dir =~ m![\\/]?CVS[\\/]|[\\/]?.svn[\\/]!); # Filter out cvs or subversion dirs/
        #return if ($File::Find::dir =~ m![\\/]?blib[\\/]libdoc$!); # Filter out pod doc in dist
        #return if ($File::Find::dir =~ m![\\/]?blib[\\/]man\d$!); # Filter out pod doc in dist
        if (-d $File::Find::name &&
            ($_ eq 'CVS' || $_ eq '.svn' || # Filter out cvs or subversion dirs
             $File::Find::name =~ m!(?:^|[\\/])blib[\\/]libdoc$! || # Filter out pod doc in dist
             $File::Find::name =~ m!(?:^|[\\/])blib[\\/]man\d$!) # Filter out pod doc in dist
            ) {
            $File::Find::prune = 1;
            return;
        }

        return unless (-f $File::Find::name && -r _);
        return if ($File::Find::name =~ m!\.#.+?[\d\.]+$!);         # Filter out CVS backup files (.#file.revision)
        push @found, File::Spec->canonpath( File::Spec->no_upwards( $File::Find::name ) );
    };

    my $find_arg = {
        %file_find_arg,
        wanted   => $want_sub,
        no_chdir => 1,
    };
    find( $find_arg, @base_dirs); # Find all potential file candidates

    my $files_to_skip = $TEST_SKIP || [];
    my %skip = map { $_ => undef } @$files_to_skip;
    return grep { ! exists $skip{$_} } @found; # Exclude files to skip
}

=head1 FUNCTIONS

=head2 syntax_ok( $file [, $text] )

Run a syntax check on C<$file> by running C<perl -c $file> with an external perl interpreter.
The external perl interpreter path is stored in C<$Test::Strict::PERL> which can be modified.
You may prefer C<use_ok()> from L<Test::More> to syntax test a module.
For a module, the path (lib/My/Module.pm) or the name (My::Module) can be both used.

=cut

sub syntax_ok {
    my $file     = shift;
    my $test_txt = shift || "Syntax check $file";

    $file = _module_to_path($file);
    unless (-f $file && -r _) {
        $Test->ok( 0, $test_txt );
        $Test->diag( "File $file not found or not readable" );
        return;
    }

    my $is_script = _is_perl_script($file);

    # Set the environment to compile the script or module
    require Config;
    my $inc = join($Config::Config{path_sep}, @INC) || '';
    $file            = _untaint($file);
    my $perl_bin     = _untaint($PERL);
    local $ENV{PATH} = _untaint($ENV{PATH}) if $ENV{PATH};

    # Add the -t -T switches if they are set in the #! line
    my $switch = '';
    $switch = _taint_switch($file) || '' if $is_script;

    # Compile and check for errors
    my $eval =  do {
        local $ENV{PERL5LIB} = $inc;
        `$perl_bin -c$switch \"$file\" 2>&1`;
    };
    $file = quotemeta($file);
    my $ok = $eval =~ qr!$file syntax OK!ms;
    $Test->ok($ok, $test_txt);
    unless ($ok) {
        $Test->diag( $eval );
    }
    return $ok;
}

=head2 strict_ok( $file [, $text] )

Check if C<$file> contains a C<use strict;> statement.
C<use Moose> and C<use Mouse> are also considered valid.
use Modern::Perl is also accepted.

This is a pretty naive test which may be fooled in some edge cases.
For a module, the path (lib/My/Module.pm) or the name (My::Module) can be both used.

=cut

sub strict_ok {
    my $file     = shift;
    my $test_txt = shift || "use strict   $file";
    $file = _module_to_path($file);
    open my $fh, '<', $file or do { $Test->ok(0, $test_txt); $Test->diag("Could not open $file: $!"); return; };
    my $ok = _strict_ok($fh);
    $Test->ok($ok, $test_txt);
    return $ok;
}

sub _module_rx {
    my (@module_names) = @_;
    my $names = join '|', map quotemeta, reverse sort @module_names;
    # TODO: improve this matching (e.g. see TODO test)
    return qr/\buse\s+(?:$names)(?:[;\s]|$)/;
}

sub _strict_ok {
    my ($in) = @_;
    my $strict_module_rx = _module_rx( modules_enabling_strict() );
    local $_;
    while (<$in>) {
        next if (/^\s*#/); # Skip comments
        next if (/^\s*=.+/ .. /^\s*=(cut|back|end)/); # Skip pod
        last if (/^\s*(__END__|__DATA__)/); # End of code
        return 1 if $_ =~ $strict_module_rx;
        if (/\buse\s+(5\.\d+)/ and $1 >= 5.012) {
            return 1;
        }
        if (/\buse\s+v5\.(\d+)/ and $1 >= 12) {
            return 1;
        }
    }
    return;
}

=head2 modules_enabling_strict

Experimental. Returning a list of modules and pragmata that enable strict.
To modify this list, change C<@Test::Strict::MODULES_ENABLING_STRICT>.

List taken from L<Module::CPANTS::Kwalitee::Uses> v95

=cut

our @MODULES_ENABLING_STRICT = qw(
    strict
    Any::Moose
    Catmandu::Sane
    Class::Spiffy
    Coat
    common::sense
    Dancer
    HTML::FormHandler::Moose
    HTML::FormHandler::Moose::Role
    Mo
    Modern::Perl
    Mojo::Base
    Moo
    Moo::Role
    MooX
    Moose
    Moose::Exporter
    Moose::Role
    MooseX::Declare
    MooseX::Role::Parameterized
    MooseX::Types
    Mouse
    Mouse::Role
    perl5
    perl5i::1
    perl5i::2
    perl5i::latest
    Role::Tiny
    Spiffy
    strictures
    Test::Most
    Test::Roo
);

sub modules_enabling_strict { return @MODULES_ENABLING_STRICT }

=head2 modules_enabling_warnings

Experimental. Returning a list of modules and pragmata that enable warnings
To modify this list, change C<@Test::Strict::MODULES_ENABLING_WARNINGS>.

List taken from L<Module::CPANTS::Kwalitee::Uses> v95

=cut

our @MODULES_ENABLING_WARNINGS = qw(
    warnings
    Any::Moose
    Catmandu::Sane
    Class::Spiffy
    Coat
    common::sense
    Dancer
    HTML::FormHandler::Moose
    HTML::FormHandler::Moose::Role
    Mo
    Modern::Perl
    Mojo::Base
    Moo
    Moo::Role
    MooX
    Moose
    Moose::Exporter
    Moose::Role
    MooseX::Declare
    MooseX::Role::Parameterized
    MooseX::Types
    Mouse
    Mouse::Role
    perl5
    perl5i::1
    perl5i::2
    perl5i::latest
    Role::Tiny
    Spiffy
    strictures
    Test::Most
    Test::Roo
);

sub modules_enabling_warnings { return @MODULES_ENABLING_WARNINGS }

=head2 warnings_ok( $file [, $text] )

Check if warnings have been turned on.

If C<$file> is a module, check if it contains a C<use warnings;> or C<use warnings::...>
or C<use Moose> or C<use Mouse> statement. use Modern::Perl is also accepted.
If the perl version is <= 5.6, this test is skipped (C<use warnings> appeared in perl 5.6).

If C<$file> is a script, check if it starts with C<#!...perl -w>.
If the -w is not found and perl is >= 5.6, check for a C<use warnings;> or C<use warnings::...>
or C<use Moose> or C<use Mouse> statement. use Modern::Perl is also accepted.

This is a pretty naive test which may be fooled in some edge cases.
For a module, the path (lib/My/Module.pm) or the name (My::Module) can be both used.

=cut

sub warnings_ok {
    my $file = shift;
    my $test_txt = shift || "use warnings $file";

    $file = _module_to_path($file);
    my $is_module = _is_perl_module( $file );
    my $is_script = _is_perl_script( $file );
    if (!$is_script and $is_module and ! $CAN_USE_WARNINGS) {
        $Test->skip();
        $Test->diag("This version of perl ($]) does not have use warnings - perl 5.6 or higher is required");
        return;
    }

    open my $fh, '<', $file or do { $Test->ok(0, $test_txt); $Test->diag("Could not open $file: $!"); return; };
    my $ok = _warnings_ok($is_script, $fh);
    $Test->ok($ok, $test_txt);
    return $ok
}

# TODO unite with _strict_ok
sub _warnings_ok {
    my ($is_script, $in) = @_;
    my $warnings_module_rx = _module_rx( modules_enabling_warnings() );
    local $_;
    while (<$in>) {
        if ($. == 1 and $is_script and $_ =~ $PERL_PATTERN) {
            if (/\s+-\w*[wW]/) {
                return 1;
            }
        }
        last unless $CAN_USE_WARNINGS;
        next if (/^\s*#/); # Skip comments
        next if (/^\s*=.+/ .. /^\s*=(cut|back|end)/); # Skip pod
        last if (/^\s*(__END__|__DATA__)/); # End of code
        return 1 if $_ =~ $warnings_module_rx;
    }
    return;
}

=head2 all_perl_files_ok( [ @directories ] )

Applies C<strict_ok()> and C<syntax_ok()> to all perl files found in C<@directories> (and sub directories).
If no <@directories> is given, the starting point is one level above the current running script,
that should cover all the files of a typical CPAN distribution.
A perl file is *.pl or *.pm or *.t or a file starting with C<#!...perl>

If the test plan is defined:

  use Test::Strict tests => 18;
  all_perl_files_ok();

the total number of files tested must be specified.

You can control which tests are run on each perl site through:

  $Test::Strict::TEST_SYNTAX   (default = 1)
  $Test::Strict::TEST_STRICT   (default = 1)
  $Test::Strict::TEST_WARNINGS (default = 0)
  $Test::Strict::TEST_SKIP     (default = []) "Trusted" files to skip

=cut

sub all_perl_files_ok {
    my @files = _all_perl_files( @_ );

    _make_plan();
    foreach my $file ( @files ) {
        syntax_ok( $file )   if $TEST_SYNTAX;
        strict_ok( $file )   if $TEST_STRICT;
        warnings_ok( $file ) if $TEST_WARNINGS;
    }
}

=head2 all_cover_ok( [coverage_threshold [, @t_dirs]] )

This will run all the tests in @t_dirs
(or current script's directory if @t_dirs is undef)
under L<Devel::Cover>
and calculate the global test coverage of the code loaded by the tests.
If the test coverage is greater or equal than C<coverage_threshold>, it is a pass,
otherwise it's a fail. The default coverage threshold is 50
(meaning 50% of the code loaded has been covered by test).

The threshold can be modified through C<$Test::Strict::COVERAGE_THRESHOLD>.

You may want to select which files are selected for code
coverage through C<$Test::Strict::DEVEL_COVER_OPTIONS>,
see L<Devel::Cover> for the list of available options.
The default is '+ignore,"/Test/Strict\b"'.

The path to C<cover> utility can be modified through C<$Test::Strict::COVER>.

The 50% threshold is a completely arbitrary value, which should not be considered
as a good enough coverage.

The total coverage is the return value of C<all_cover_ok()>.

=cut

sub all_cover_ok {
    my $cover_bin    = _cover_path();
    die "ERROR: Cover binary not found, please install Devel::Cover.\n"
        unless (defined $cover_bin);

    my $threshold = shift || $COVERAGE_THRESHOLD;
    my @dirs = @_ ? @_
        : (File::Spec->splitpath( $0 ))[1] || '.';
    my @all_files = grep { ! /$0$/o && $0 !~ /$_$/ }
    grep { _is_perl_script($_) }
    _all_files(@dirs);
    _make_plan();

    my $perl_bin     = _untaint($PERL);
    local $ENV{PATH} = _untaint($ENV{PATH}) if $ENV{PATH};
    if ($IS_WINDOWS and ! -d $DEVEL_COVER_DB) {
        mkdir $DEVEL_COVER_DB or warn "$DEVEL_COVER_DB: $!";
    }

    my $res = `$cover_bin -delete 2>&1`;
    if ($?) {
        $Test->skip();
        $Test->diag("Cover at $cover_bin got error $?: $res");
        return;
    }
    foreach my $file ( @all_files ) {
        $file = _untaint($file);
        `$perl_bin -MDevel::Cover=$DEVEL_COVER_OPTIONS $file`;
        $Test->ok(! $?, "Coverage captured from $file" );
    }
    $Test->ok(my $cover = `$cover_bin 2>&1`, "Got cover");

    my ($total) = ($cover =~ /^\s*Total.+?([\d\.]+)\s*$/m);
    $Test->ok( $total >= $threshold, "coverage = ${total}% > ${threshold}%");
    return $total;
}

sub _is_perl_module {
    return 0 if $_[0] =~ /\~$/;
    $_[0] =~ /\.pm$/i || $_[0] =~ /::/;
}


sub _is_perl_script {
    my $file = shift;

    return 0 if $file =~ /\~$/;
    return 1 if $file =~ /\.pl$/i;
    return 1 if $file =~ /\.t$/;
    open my $fh, '<', $file or return;
    my $first = <$fh>;
    return 1 if defined $first && ($first =~ $PERL_PATTERN);
    return;
}

##
## Returns the taint switches -tT in the #! line of a perl script
##
sub _taint_switch {
    my $file = shift;

    open my $fh, '<', $file or return;
    my $first = <$fh>;
    $first =~ /^#!.*\bperl.*\s-\w*([Tt]+)/ or return;
    return $1;
}

##
## Return the path of a module
##
sub _module_to_path {
    my $file = shift;

    my @parts = split /::/, $file;
    my $module = File::Spec->catfile(@parts) . '.pm';
    foreach my $dir (@INC) {
        my $candidate = File::Spec->catfile($dir, $module);
        next unless (-e $candidate && -f _ && -r _);
        return $candidate;
    }
    return $file; # non existing file - error is catched elsewhere
}


sub _cover_path {
    return $COVER if defined $COVER;

    my $os_separator = $IS_WINDOWS ? ';' : ':';
    foreach ((split /$os_separator/, $ENV{PATH}), @Config{qw(bin sitedir scriptdir)} ) {
        my $path = $_ || '.';
        my $path_cover = File::Spec->catfile($path, 'cover');
        if ($IS_WINDOWS) {
            next unless (-f $path_cover && -r _);
        }
        else {
            next unless -x $path_cover;
        }
        return $COVER = _untaint($path_cover);
    }
    return;
}


sub _make_plan {
    unless ($Test->has_plan) {
        $Test->plan( 'no_plan' );
    }
    $Test->expected_tests;
}

sub _untaint {
    my @untainted = map {($_ =~ $UNTAINT_PATTERN)} @_;
    wantarray ? @untainted
        : $untainted[0];
}

=head1 CAVEATS

For C<all_cover_ok()> to work properly, it is strongly advised to install the most recent version of L<Devel::Cover>
and use perl 5.8.1 or above.
In the case of a C<make test> scenario, C<all_perl_files_ok()> re-run all the tests in a separate perl interpreter,
this may lead to some side effects.

=head1 SEE ALSO

L<Test::More>, L<Test::Pod>. L<Test::Distribution>, L<Test::NoWarnings>

=head1 REPOSITORY

L<https://github.com/manwar/Test-Strict>

=head1 AUTHOR

Pierre Denis, C<< <pdenis@gmail.com> >>.

=head1 MAINTAINER

L<Gabor Szabo|http://szabgab.com/>

Currently maintained by Mohammad S Anwar (MANWAR), C<< <mohammad.anwar at yahoo.com> >>

=head1 COPYRIGHT

Copyright 2005, 2010 Pierre Denis, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut

1;
