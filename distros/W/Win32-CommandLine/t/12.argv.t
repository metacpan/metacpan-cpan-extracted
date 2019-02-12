#!perl -w   -- -*- tab-width: 4; mode: perl -*-

use strict;
use warnings;

use Test::More;             # included with perl
use Test::Differences;      # included with perl

my $haveTestNoWarnings = eval { require Test::NoWarnings; import Test::NoWarnings; 1; };

if ( !$ENV{HARNESS_ACTIVE} ) {
    # not executing under Test::Harness
    use lib qw{ blib/arch };    # only needed for dynamic module loads (eg, compiled XS) [ remove if no XS ]
    use lib qw{ lib };          # use the 'lib' version (for ease of testing from command line and testing immediacy; so 'blib/arch' version doesn't have to be built/updated 1st)
    }

use Win32::CommandLine;

use File::Glob;
use File::Spec;

sub add_test;
sub test_num;
sub do_tests;

# Tests

# token to add uniqueness to a filename
my $token = "fperihf393fu34iouh34uf34oiuf34iuf34iufn34uifiou3fgf23iu34hf44sa823";

## accumulate tests

# ToDO: organize tests, add new tests for 'xx.bat'

add_test( [ qq{$0 }.q{-m "VERSION: update to 0.3.11"} ], ( q{-m}, q{VERSION: update to 0.3.11} ) );
add_test( [ qq{$0 }.q{-m "VERSION: update to 0.3.11"}, {dosquote => 1} ], ( q{-m}, q{"VERSION: update to 0.3.11"} ) );

add_test( [ qq{$0 }.q{'"'} ], ( q{"} ) );   #"
#add_test( [ qq{$0 }.q{'"'}, { dosify => 1 }  ], ( q{"\\""} ) );    #"
#add_test( [ qq{$0 }.q{"\\""}, { dosify => 1 }  ], ( q{"\\""} ) );  #"
add_test( [ qq{$0 }.q{'"'}, { dosquote => 1 }  ], ( q{"\\""} ) );   #"
add_test( [ qq{$0 }.q{"\\""}, { dosquote => 1 }  ], ( q{"\\""} ) );     #"

add_test( [ qq{$0 }.q{$()} ], ( q{} ) );

add_test( [ qq{$0 }.q{$} ], ( q{$} ) );
add_test( [ qq{$0 }.q{$$} ], ( q{$$} ) );
add_test( [ qq{$0 }.q{$a} ], ( q{$a} ) );
add_test( [ qq{$0 }.q{a$} ], ( q{a$} ) );
add_test( [ qq{$0 }.q{a$a} ], ( q{a$a} ) );

add_test( [ qq{$0 }.q{$()$} ], ( q{$} ) );

add_test( [ qq{$0 }.q{$""} ], ( q{} ) );
add_test( [ qq{$0 }.q{$'\x25'} ], ( q{%} ) );
add_test( [ qq{$0 }.q{$'\X25'} ], ( q{\\X25} ) );

add_test( [ qq{$0 }.q{$""$} ], ( q{$} ) );

# ToDO: add systematic full testing of octal (1 to 3 digits), hex (1 to 2 digits), and control character escapes

add_test( [ qq{$0 }.q{$'\0'} ], ( qq{\x00} ) );
add_test( [ qq{$0 }.q{$'\1'} ], ( qq{\x01} ) );

add_test( [ qq{$0 }.q{$'\z'} ], ( q{\z} ) );

add_test( [ qq{$0 }.q{$'test'} ], ( q{test} ) );
add_test( [ qq{$0 }.q{$"test"} ], ( q{test} ) );
add_test( [ qq{$0 }.q{'"test"'} ], ( q{"test"} ) );

add_test( [ qq{$0} ], qw( ) );

add_test( [ qq{ $0} ], qw( ) );

add_test( [ qq{$0 } ], qw( ) );

add_test( [ qq{ $0 } ], qw( ) );

add_test( [ qq{ a } ], qw( ) );

add_test( [ qq{ a b c } ], qw( ) );

add_test( [ qq{ a 'b' c } ], qw( ) );

add_test( [ qq{$0 a '' } ], ( qq{a}, qq{} ) );

add_test( [ qq{$0 a b c} ], qw( a b c ) );

add_test( [ qq{$0 "a b" c} ], ( 'a b', 'c' ) );

add_test( [ qq{$0 'a b' c'' } ], ( "a b", "c" ) );

add_test( [ qq{$0 "a b" c"" } ], ( "a b", "c" ) );

add_test( [ qq{$0 "a b" c""d } ], ( "a b", "cd" ) );

add_test( [ qq{$0 'a'b c''d } ], ( 'ab', 'cd' ) );

add_test( [ qq{$0 a'b'c''d } ], ( 'abcd' ) );

add_test( [ qq{$0 "a"b c""d } ], ( 'ab', 'cd' ) );

add_test( [ qq{$0 a"b"c""d } ], ( 'abcd' ) );

add_test( [ qq{$0 "a"b c''d } ], ( 'ab', 'cd' ) );

add_test( [ qq{$0 a"b"c''d } ], ( 'abcd' ) );

add_test( [ qq{$0 'a'b c""d } ], ( 'ab', 'cd' ) );

add_test( [ qq{$0 a'b'c""d } ], ( 'abcd' ) );

add_test( [ qq{$0 'a b" c'} ], ( qq{a b" c} ) );    ##"

add_test( [ qq{$0 'a bb" c'} ], ( qq{a bb" c} ) );      ##"

add_test( [ qq{$0 \$'test'} ], ( qq{test} ) );

add_test( [ qq{$0 \$'\\x34\\x34'} ], ( qq{44} ) );

add_test( [ qq{$0 '\\x34\\x34'} ], ( qq{\\x34\\x34} ) );

add_test( [ qq{$0 \$'\\X34\\X34'} ], ( qq{\\X34\\X34} ) );

add_test( [ qq{$0 '\\X34\\X34'} ], ( qq{\\X34\\X34} ) );

add_test( [ qq{$0 \$'\\x34\\X34'} ], ( qq{4\\X34} ) );

add_test( [ qq{$0 \$'\\X34\\x34'} ], ( qq{\\X344} ) );

add_test( [ qq{$0 \*.t} ], ( q{*.t} ) );

add_test( [ qq{$0 '*.t} ], ( q{Unbalanced command line quotes [#1] (at token`'*.t` from command line `}.qq{$0}.q{ '*.t`)} ) );

add_test( [ qq{$0 a b c \*.t} ], ( qw{a b c}, q{*.t} ) );

add_test( [ qq{$0 a b c t/\*.t} ], ( qw{a b c}, glob('t/*.t') ) );

add_test( [ qq{$0 a t/\*.t b} ], ( "a", glob('t/*.t'), "b" ) );

add_test( [ qq{$0 t/\"*".t} ], ( q{t/*.t} ) );      ##"

add_test( [ qq{$0 t/\'*'.t} ], ( q{t/*.t} ) );

add_test( [ qq{$0 t/{0}\*.t} ], ( glob('t/{0}*.t') ) );

add_test( [ qq{$0 t/{0,}\*.t} ], ( glob('t/{0,}*.t') ) );

add_test( [ qq{$0 t/{0,p}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{0,p}*.t') ) );

add_test( [ qq{$0 t/\{0,t,p\}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{0,t,p}*.t') ) );

add_test( [ qq{$0 t/\{t,p,0\}\*.t}, { 'nullglob' => 1 } ], ( glob('t/{t,p,0}*.t') ) );

add_test( [ qq{$0 t/\*} ], ( glob('t/*') ) );

add_test( [ qq{$0 '\\\\'} ], ( '\\\\' ) );

add_test( [ qq{$0 'a\\a' '\\a\\x\\'} ], ( 'a\\a', '\\a\\x\\' ) );

add_test( [ qq{$0 '/a\a'} ], ( qq{/a\a} ) );

add_test( [ qq{$0 '//foo\\bar'} ], ( q{//foo\\bar} ) );

add_test( [ qq{$0 '/a\a' /foo\\\\bar} ], ( qq{/a\a}, q{/foo\\\\bar} ) );

add_test( [ qq{$0 1 't\\glob-file.tests'/*} ], ( 1, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 2 't\\glob-file.tests'\\*} ], ( 2, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 3 't\\glob-file.tests/'*} ], ( 3, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 4 't\\glob-file.tests\\'*} ], ( 4, glob('t/glob-file.tests/*') ) );

add_test( [ qq{$0 5 't\\glob-file.tests\\*'} ], ( 5, q{t\\glob-file.tests\\*} ) );

add_test( [ qq{$0 t ""} ], ( q{t}, q{} ) );

add_test( [ qq{$0 t 0} ], ( q{t}, q{0} ) );

add_test( [ qq{$0 t 0""} ], ( q{t}, q{0} ) );

add_test( [ qq{$0 't\\glob-file.tests\\'*x} ], ( q{t\\glob-file.tests\\*x} ) );

add_test( [ qq{$0 missing_file} ], ( q{missing_file} ) );
add_test( [ qq{$0 missing_file{,0}} ], ( qw/ missing_file missing_file0 / ) );
add_test( [ qq{$0 missing_file'{,0}'} ], ( q/missing_file{,0}/ ) );
add_test( [ qq{$0 missing_file"{,0}"} ], ( q/missing_file{,0}/ ) );

add_test( [ qq[$0 -] ], ( qw[-] ) );
add_test( [ qq[$0 -''] ], ( qw[-] ) );
add_test( [ qq[$0 -""] ], ( qw[-] ) );

add_test( [ qq[$0 -{}] ], ( qw[./-] ) );
add_test( [ qq[$0 -"{}"] ], ( qw[-{}] ) );
add_test( [ qq[$0 -'{}'] ], ( qw[-{}] ) );

add_test( [ qq[$0 -{,0}] ], ( qw[./- ./-0] ) );
add_test( [ qq[$0 -"{,0}"] ], ( q/-{,0}/ ) );
add_test( [ qq[$0 -'{,0}'] ], ( q/-{,0}/ ) );

add_test( [ qq{$0 --option={,0}} ], ( qw[./--option= ./--option=0] ) );
add_test( [ qq{$0 --option="{,0}"} ], ( q/--option={,0}/ ) );

### TEST_FRAGILE == tests which require a specific environment setup to work
if ($ENV{TEST_FRAGILE}) {
    sub add_path_tests {
        my ($path_prefix, $path_file) = @_;
        my $path_original = $path_prefix.$path_file;
        my $path_dosify = dosify( $path_original );
        my $path_dosify_if_file = (-e $path_original) ? dosify( $path_original ) : $path_original;
        my $path_unixify = unixify( $path_original );
        # diag("path_prefix = '$path_prefix' ; path_file = '$path_file'");

        add_test_for_caller( [ qq{$0 }.double_quote_path($path_prefix.$path_file), { dosify => 1 } ], ( $path_original ) );
        add_test_for_caller( [ qq{$0 }.double_quote_path($path_prefix.$path_file), { dosify => 'all' } ], ( $path_dosify_if_file ) );
        add_test_for_caller( [ qq{$0 }.double_quote_path($path_prefix).q({).double_quote_path($path_file).q(}), { dosify => 1 } ], ( $path_dosify_if_file ) );
        if (not ($path_prefix =~ m/\s/ or $path_file =~ m/\s/)) {
            add_test_for_caller( [ qq{$0 }.$path_prefix.$path_file, { dosify => 1 } ], ( $path_original ) );
            add_test_for_caller( [ qq{$0 }.$path_prefix.$path_file, { dosify => 'all' } ], ( $path_dosify_if_file ) );
            add_test_for_caller( [ qq{$0 }.$path_prefix.qq{{"$path_file"}}, { dosify => 1 } ], ( $path_dosify_if_file ) );
            my $p = $path_prefix.qq{{$path_file}*};
            # diag("p = $p");
            my @files = File::Glob::bsd_glob( $p, File::Glob::GLOB_BRACE | File::Glob::GLOB_NOCASE );
            # diag("files = [ @files ]");
            add_test_for_caller( [ qq{$0 }.$path_prefix.qq{{"$path_file"}*}, { dosify => 1 } ], dosify( @files ) );
            }
        return;
    }


    # SLIGHTLY-FRAGILE
    my ($path_prefix, $path_file, $path_dosify, $path_unixify);

    my ($system_root_volume, $system_root_dir, $system_root_file) = File::Spec->splitpath( glob( quotemeta_glob($ENV{SystemRoot}) ) );
    my $drive_letter;
    ($drive_letter = $system_root_volume) =~ s/:\z//;

    add_path_tests( $system_root_volume.$system_root_dir, $system_root_file );


    # UNC tests;
    # "\\127.0.0.1\...", "\\localhost\..." are supported, but the more esoteric UNC constructions "\\?\C:\..." and "\\?\UNC\ServerName\Share" are not supported
    # URLrefs:
    # [Wikipedia - UNC Pathnames] http://en.wikipedia.org/wiki/Path_(computing)#Uniform_Naming_Convention @@ http://www.webcitation.org/66OV1apf6
    # [Get local fro UNC path] http://briancaos.wordpress.com/2009/03/05/get-local-path-from-unc-path @@ http://www.webcitation.org/66OU5E35i
    # [UNC Path to a folder on my local computer] http://stackoverflow.com/questions/2787203/unc-path-to-a-folder-on-my-local-computer
    # [Get UNV path from mapped drive or local share] http://www.camaswood.com/tech/get-unc-path-from-mapped-drive-or-local-share @@ http://www.webcitation.org/66OULPyWH
    add_path_tests( q{\\\\127.0.0.1\\}.$drive_letter.q{$\\}, $system_root_file );
    add_path_tests( q{//127.0.0.1/}.$drive_letter.q{$/}, $system_root_file );
    add_path_tests( q{//127.0.0.1\\}.$drive_letter.q{$/}, $system_root_file );
    add_path_tests( q{\\\\localhost\\}.$drive_letter.q{$\\}, $system_root_file );
    add_path_tests( q{//localhost/}.$drive_letter.q{$/}, $system_root_file );
    add_path_tests( q{//localhost\\}.$drive_letter.q{$/}, $system_root_file );

    if (-e q{c:\Documents and Settings}) {
        my $path = ( File::Glob::bsd_glob( 'c:\\documents and settings*', File::Glob::GLOB_NOCASE ) )[0]; # get path in correct case
        # diag("path = $path");
        my ($path_v, $path_d, $path_f) = File::Spec->splitpath( $path );
        my $path_l;
        ($path_l = $path_v) =~ s/:\z//;
        # diag("path_l = '$path_l' ; path_v = '$path_v' ; path_d = '$path_d' ; path_f = '$path_f' ;");
        add_path_tests( $path_v.q{\\}, $path_f );
        add_path_tests( $path_v.q{/}, $path_d.$path_f );
        add_path_tests( q{//}.$ENV{UserDomain}.q{/}.$path_l.q{$/}, $path_d.$path_f );   # MORE FRAGILE :: USERDOMAIN may not point to this machine
        }

    add_path_tests( q{//}.$ENV{UserDomain}.q{/}.$drive_letter.q{$/}, $system_root_file );   # MORE FRAGILE :: USERDOMAIN may not point to this machine

    add_test( [ qq{$0 }.q{c:/{documents}*}, { dosify => 1 } ], ( q{"c:\\Documents and Settings"} ) );
    add_test( [ qq{$0 }.q{c:\\{windows}}, { dosify => 1 } ], ( q{c:\\windows} ) );
    add_test( [ qq{$0 }.q{c:\\{documents}*}, { dosify => 1 } ], ( q{"c:\\Documents and Settings"} ) );
    add_test( [ qq{$0 }.q{"c:\\"win*} ], ( q{Unbalanced command line quotes [#1] (at token`"c:\\"win*` from command line `}.qq{$0}.q{ "c:\\"win*`)} ) );       ##"
    add_test( [ qq{$0 }.q{"c:\\"win*}, { dosify => 1 } ], ( q{Unbalanced command line quotes [#1] (at token`"c:\\"win*` from command line `}.qq{$0}.q{ "c:\\"win*`)} ) );


    # SLIGHTLY-FRAGILE
    my $username = $ENV{username};
    my $user_home = $ENV{UserProfile};
    my $user_home_dosify = dosify( $user_home );
    my $user_home_unixify = $user_home;
    $user_home_unixify =~ s/\\/\//g;
    add_test( [ qq{$0 ~*} ], ( q{~*} ) );
    add_test( [ qq{$0 ~*}, { dosify => 1 } ], ( q{~*} ) );
    add_test( [ qq{$0 ~} ], ( $user_home_unixify ) );
    add_test( [ qq{$0 ~}, { dosify => 1 } ], ( $user_home_dosify ) );
    add_test( [ qq{$0 ~ ~$username} ], ( $user_home_unixify, $user_home_unixify ) );
    add_test( [ qq{$0 ~ ~$username}, { dosify => 1 } ], ( $user_home_dosify, $user_home_dosify ) );
    add_test( [ qq{$0 ~$username/} ], ( $user_home_unixify.q{/} ) );
    add_test( [ qq{$0 ~$username/}, { dosify => 1 } ], ( $user_home_dosify.q{\\} ) );
    add_test( [ qq{$0 x ~$username\\ x} ], ( q{x}, $user_home_unixify.q{/}, q{x} ) );
    add_test( [ qq{$0 x ~$username\\ x}, { dosify => 1 } ], ( q{x}, $user_home_dosify.q{\\}, q{x} ) );
    add_test( [ qq{$0 ~"$username"} ], ( $user_home_unixify ) );
    add_test( [ qq{$0 ~"$username"}, { dosify => 1 } ], ( $user_home_dosify ) );
    add_test( [ qq{$0 ~"$username"/} ], ( $user_home_unixify.q{/} ) );
    add_test( [ qq{$0 ~"$username"/}, { dosify => 1 } ], ( $user_home_dosify.q{\\} ) );
    add_test( [ qq{$0 ~"$username"test} ], ( q{~}.$username.q{test} ) );
    add_test( [ qq{$0 ~"$username"test}, { dosify => 1 } ], ( q{~}.$username.q{test} ) );
    }
###

## TODO: test backslash escapes within quotes (how to output ", \", etc) => {\"} => {"}, {\\"} => {\"}, ...

add_test( [ qq{$0 }.q{"\\"} ], ( q{Unbalanced command line quotes [#1] (at token`"\"` from command line `}.qq{$0}.q{ "\\"}.q{`)} ) );
add_test( [ qq{$0 }.q{"\\"}, { dosify => 1 } ], ( q{Unbalanced command line quotes [#1] (at token`"\"` from command line `}.qq{$0}.q{ "\\"}.q{`)} ) );
add_test( [ qq{$0 }.q{"\\\\"} ], ( q{\\} ) );
add_test( [ qq{$0 }.q{"\\\\"}, { dosquote => 1 } ], ( q{\\} ) );
# double-quotes
add_test( [ qq{$0 }.q{"\\""} ], ( q{"}) );
add_test( [ qq{$0 }.q{"\\""}, { dosquote => 1 } ], ( q{"\\""} ) );
add_test( [ qq{$0 }.q{"\\\\""} ], ( q{Unbalanced command line quotes [#1] (at token`"` from command line `}.qq{$0}.q{ "\\\\""}.q{`)} ) );
add_test( [ qq{$0 }.q{"\\\\""}, { dosify => 1 } ], ( q{Unbalanced command line quotes [#1] (at token`"` from command line `}.qq{$0}.q{ "\\\\""}.q{`)} ) );
add_test( [ qq{$0 }.q{"\\\\\\""} ], ( q{\\"} ) );
add_test( [ qq{$0 }.q{"\\\\\\""}, { dosquote => 1 } ], ( q{"\\\\\\""} ) );


# rule tests
# non-globbed tokens should stay the same
add_test( [ qq{$0 1 foo\\bar} ], ( 1, q{foo\\bar} ) );
add_test( [ qq{$0 2 \\foo/bar} ], ( 2, q{\\foo/bar} ) );
add_test( [ qq{$0 1 't\\glob-file.tests\\'*} ], ( 1, glob('t/glob-file.tests/*') ) );

# dosify
add_test( [ qq{$0 foo\\bar} ], ( q{foo\\bar} ) );

# dosify (globbed [or all] ARGS which are files) vs dosquote (non-globbed ARGS) vs unixify (globbed [or all] ARGS which are files)
# NOTE: These options are needed for cases of ARGS such as:
#   perl -e "$x = split( /n/, q{Win32::CommandLine}); print $x;" (which would otherwise be translated to...) perl -e "$x = split( \n\, q{Win32::CommandLine}); print $x;"
# dosify = 1; DOS-quote all globbed args which are files
# dosify = all; DOS-quote all args which are files
# dosquote = 1 = all; DOS-quote all non-globbed ARGS, files or not
## VERY SLIGHTLY FRAGILE (but, with the token, the names should always be unique)
add_test( [ qq{$0 "nodrive\\not\\a file $token"} ], ( qq{nodrive\\not\\a file $token} ) );
add_test( [ qq{$0 "nodrive\\not\\a file $token"}, {dosify => 1} ], ( qq{nodrive\\not\\a file $token} ) );
add_test( [ qq{$0 "nodrive\\not\\a file $token"}, {dosify => 'all'} ], ( qq{nodrive\\not\\a file $token} ) );
add_test( [ qq{$0 "nodrive\\not\\a file $token"}, {dosquote => 1} ], ( qq{"nodrive\\not\\a file $token"} ) );
add_test( [ qq{$0 "nodrive\\not\\a file $token"}, {dosquote => 'all'} ], ( qq{"nodrive\\not\\a file $token"} ) );

### TEST_FRAGILE == tests which require a specific environment setup to work
if ($ENV{TEST_FRAGILE}) {
    add_test( [ qq{$0 "c:\\documents and settings"} ], ( q{c:\\documents and settings} ) );
    add_test( [ qq{$0 "c:\\documents and settings"}, {dosify => 1} ], ( q{c:\\documents and settings} ) );
    add_test( [ qq{$0 "c:\\documents and settings"}, {dosify => 'all'} ], ( q{"c:\\documents and settings"} ) );
    add_test( [ qq{$0 "c:\\documents and settings"}, {dosquote => 1} ], ( q{"c:\\documents and settings"} ) );
    add_test( [ qq{$0 "c:\\documents and settings"}, {dosquote => 'all'} ], ( q{"c:\\documents and settings"} ) );

    add_test( [ qq{$0 "c:\\documents and settings"*} ], ( q{c:/Documents and Settings} ) );
    add_test( [ qq{$0 "c:\\documents and settings"*}, {dosify => 1} ], ( q{"c:\\Documents and Settings"} ) );
    add_test( [ qq{$0 "c:\\documents and settings"*}, {dosify => 'all'} ], ( q{"c:\\Documents and Settings"} ) );
    add_test( [ qq{$0 "c:\\documents and settings"*}, {dosquote => 1} ], ( q{c:/Documents and Settings} ) );
    add_test( [ qq{$0 "c:\\documents and settings"*}, {dosquote => 'all'} ], ( q{c:/Documents and Settings} ) );
    }
###

## TODO: check both with and without nullglob, including using %opts for argv()
add_test( [ qq{$0 foo\\bar}, { nullglob => 0 } ], ( q{foo\\bar} ) );

## do tests

# setup a known environment
$ENV{nullglob} = 0;     ## no critic ( RequireLocalizedPunctuationVars ) ## ToDO: remove/revisit

#plan tests => test_num() + ($Test::NoWarnings::VERSION ? 1 : 0);
plan tests => test_num() + ($haveTestNoWarnings ? 1 : 0);

do_tests(); # test re-parsing of command_line() by argv()
##
my @tests;
sub add_test { push @tests, [ (caller(0))[2], @_ ]; return; }       ## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub add_test_for_caller { push @tests, [ (caller(1))[2].'(via line:'.(caller(0))[2].')', @_ ]; return; }        ## NOTE: caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
sub test_num { return scalar(@tests); }
## no critic (Subroutines::ProtectPrivateSubs)
sub do_tests { foreach my $t (@tests) { my $line = shift @{$t}; my @args = @{shift @{$t}}; my @exp = @{$t}; my @got; eval { @got = Win32::CommandLine::parse(@args); 1; } or ( @got = ( $@ =~ /^(.*)\s+at.*$/ ) ); eq_or_diff \@got, \@exp, "[line:$line]: `@args`"; } return; }

#### SUBs

sub _is_const { my $is_const = !eval { ($_[0]) = $_[0]; 1; }; return $is_const; }
sub double_quote_path {
    # double_quote_path( $|@:STRING(s) [,\%:OPTIONAL_ARGS] ): returns $|@ ['shortcut' function] (with optional hash_ref containing function options)
    # surround path with double quotes, escaping any trailing backslash to avoid inadvertant quoting of the last doulble quote
    use Carp();
    my %opt = ();

    my $me = (caller(0))[3];    ## no critic ( ProhibitMagicNumbers )   ## caller(EXPR) => ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i);
    my $opt_ref;
    $opt_ref = pop @_ if ( @_ && (ref($_[-1]) eq 'HASH'));  ## no critic (ProhibitPostfixControls)  ## pop last argument only if it's a HASH reference (assumed to be options for our function)
    if ($opt_ref) { for (keys %{$opt_ref}) { if (exists $opt{$_}) { $opt{$_} = $opt_ref->{$_}; } else { Carp::carp "Unknown option '$_' for function ".$me; return; } } }
    if ( !@_ && !defined(wantarray) ) { Carp::carp 'Useless use of '.$me.' with no arguments in void return context (did you want '.$me.'($_) instead?)'; return; } ## no critic ( RequireInterpolationOfMetachars ) #
    if ( !@_ ) { Carp::carp 'Useless use of '.$me.' with no arguments'; return; }

    my $arg_ref;
    $arg_ref = \@_;
    $arg_ref = [ @_ ] if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    for my $arg ( @{$arg_ref} ) {
        if (_is_const($arg)) { Carp::carp 'Attempt to modify readonly scalar'; return; }
        $arg .= q{\\} if $arg =~ m/\\\z/;
        $arg =~ s/\A(.*)\z/\"$1\"/;
##  diag("DQ() = ".$arg);
        }

        return wantarray ? @{$arg_ref} : "@{$arg_ref}";
    }

sub dosify{
    # use Win32::CommandLine::_dosify
    use Win32::CommandLine;
    return Win32::CommandLine::_dosify(@_); ## no critic ( ProtectPrivateSubs )
}

sub unixify{
    # _unixify( <null>|$|@ ): returns <null>|$|@ ['shortcut' function]
    # unixify string, returning a string which has unix correct slashes
    @_ = @_ ? @_ : $_ if defined wantarray;     ## no critic (ProhibitPostfixControls)  ## break aliasing if non-void return context

    ## no critic ( ProhibitUnusualDelimiters )

    for (@_ ? @_ : $_)
        {
        s:\\:\/:g;
        }

    return wantarray ? @_ : "@_";
}

sub quotemeta_glob{
    my $s = shift @_;

    my $gc = quotemeta( q{?*[]{}~}.q{\\} );
    $s =~ s/([$gc])/\\$1/g;                 # backslash quote all glob metacharacters (backslashes as well)
    return $s;
}
