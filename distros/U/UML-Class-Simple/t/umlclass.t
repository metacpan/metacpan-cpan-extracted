# test script/umlclass.pl
# XXX FIXME: should rewrite this .t file in terms of Test::Base

use strict;
no warnings;

use Config;
use YAML::Syck;
use File::Slurp;
use IPC::Run3;
use Test::More tests => 93;

my $script = 'script/umlclass.pl';
my @cmd = ($^X, '-Ilib', $script);

my ($stdout, $stderr);

{
    my $outfile = 'exclude01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '-E', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -E $Config{archlibexp}";
    like $stdout, qr/\w+::/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'exclude02.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '-E', $Config{archlibexp},
              '--exclude', $Config{installsitearch}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -E $Config{archlibexp} --exclude $Config{installsitearch}";
    like $stdout, qr/\w+::/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'exclude01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '-E', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -E $Config{archlibexp}";
    like $stdout, qr/\w+::/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'include01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '-I', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -I $Config{archlibexp}";
    like $stdout, qr/\w+::/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'include02.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '-I', $Config{archlibexp},
              '--exclude', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -I $Config{archlibexp} --exclude $Config{archlibexp}";
    is $stdout, '',
        "stdout ok - $outfile generated.";
    like $stderr, qr/error: no class found\./;
    ok !-f $outfile, "$outfile exists";
}

{
    my $outfile = 'include03.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, '--include', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -I $Config{archlibexp}";
    like $stdout, qr/\w+::/,
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    unlink 'a.png' if -f 'a.png';
    ok run3( [@cmd, qw(-p UML::Class)], \undef, \$stdout, \$stderr ),
        'umlclass -p UML::Class';
    is $stdout, "UML::Class\nUML::Class::Simple\n\na.png generated.\n",
        'stdout ok - a.png generated.';
    warn $stderr if $stderr;
    ok -f 'a.png', 'a.png exists';
    ok( (-s 'a.png' > 1000), 'a.png is nonempty' );
}

{
    unlink 'a.png' if -f 'a.png';
    ok run3( [@cmd, qw(--pattern UML::Class)], \undef, \$stdout, \$stderr ),
        'umlclass --pattern UML::Class';
    is $stdout, "UML::Class\nUML::Class::Simple\n\na.png generated.\n",
        'stdout ok - a.png generated.';
    warn $stderr if $stderr;
    ok -f 'a.png', 'a.png exists';
    ok( (-s 'a.png' > 1000), 'a.png is nonempty' );
}

{
    my $outfile = 'size01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, qw(--pattern UML::Class --s 2.1x3)],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile --pattern UML::Class --size 2x5.3";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'size02.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, qw(--pattern UML::Class --s 5x3.2)],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile --pattern UML::Class --size 2x5.3";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'b.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '-o', $outfile, qw(-c grey -p UML::Class)], \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -c grey -p UML::Class";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'b.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, '--out', $outfile, qw(--color grey --pattern UML::Class)],
             \undef, \$stdout, \$stderr ),
        "umlclass --out $outfile --color grey --pattern UML::Class";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    unlink 'foo.png' if -f 'foo.png';
    ok run3( [@cmd, qw(-p UML::Class -o foo.png)], \undef, \$stdout, \$stderr ),
        'umlclass -p UML::Class -o foo.png';
    is $stdout, "UML::Class\nUML::Class::Simple\n\nfoo.png generated.\n",
        'stdout ok - foo.png generated.';
    warn $stderr if $stderr;
    ok -f 'foo.png', 'foo.png exists';
    ok( (-s 'foo.png' > 1000), 'foo.png is nonempty' );
}

{
    my $outfile = 'bar.dot';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-p UML::Class -o), $outfile], \undef, \$stdout, \$stderr ),
        "umlclass -p UML::Class -o $outfile";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    my $dot = read_file($outfile);
    like $dot, qr/digraph uml_class_diagram/, 'dot looks okay';
}

{
    my $outfile = 'baz.yml';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-p UML::Class -o), $outfile], \undef, \$stdout, \$stderr ),
        "umlclass -p UML::Class -o $outfile";
    is $stdout, "UML::Class\nUML::Class::Simple\n\n$outfile generated.\n",
        "stdout ok - $outfile generated.";
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    my $yml = read_file($outfile);
    like $yml, qr/^\s*- classes_from_files/m, 'yml looks okay';
}

{
    my $outfile = 'fast00.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-p ^FAST -o), $outfile, 't/FAST/lib'], \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST
FAST::Util

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-r -p ^FAST -o), $outfile, 't/FAST/lib'], \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST
FAST::Element
FAST::Node
FAST::Struct
FAST::Struct::If
FAST::Struct::Seq
FAST::Struct::While
FAST::Util

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast01.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(--recursive --pattern ^FAST --out), $outfile, 't/FAST/lib'],
              \undef, \$stdout, \$stderr ),
        "umlclass --recursive --pattern ^FAST --out $outfile t/FAST/lib";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST
FAST::Element
FAST::Node
FAST::Struct
FAST::Struct::If
FAST::Struct::Seq
FAST::Struct::While
FAST::Util

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast2.png';
    unlink $outfile if -f $outfile;
    ok run3( [@cmd, qw(-p ^FAST -o), $outfile, 't/FAST/lib/FAST.pm'],
            \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib/FAST.pm";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST
FAST::Util

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast3.png';
    unlink $outfile if -f $outfile;
    ok run3(
        [@cmd, qw(-p ^FAST -o), $outfile,
            qw(t/FAST/lib/FAST.pm t/FAST/lib/FAST/Struct.pm)],
        \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib/FAST.pm t/FAST/lib/FAST/Struct.pm";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST
FAST::Struct
FAST::Util

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast4.png';
    unlink $outfile if -f $outfile;
    ok run3(
        [@cmd, qw(-p ^FAST -o), $outfile,
            't/FAST/lib/FAST/Struct/*.pm'],
        \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib/FAST/Struct/*.pm";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST::Struct::If
FAST::Struct::Seq
FAST::Struct::While

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";
    ok( (-s $outfile > 1000), "$outfile is nonempty" );
}

{
    my $outfile = 'fast5.yml';
    unlink $outfile if -f $outfile;
    ok run3(
        [@cmd, qw(-p ^FAST -o), $outfile,
            't/FAST/lib/FAST/Struct/*.pm'],
        \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile t/FAST/lib/FAST/Struct/*.pm";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
FAST::Struct::If
FAST::Struct::Seq
FAST::Struct::While

$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";

    my $dom = LoadFile($outfile);
    pop @{ $dom->{classes} };
    DumpFile($outfile, $dom);

    my $infile = $outfile;
    $outfile = 'fast5.dot';
    unlink $outfile if -f $outfile;
    ok run3(
        [@cmd, qw(-p ^FAST -o), $outfile, $infile],
        \undef, \$stdout, \$stderr ),
        "umlclass -p ^FAST -o $outfile $infile";
    is $stdout, <<_EOC_, "stdout ok - $outfile generated.";
$outfile generated.
_EOC_
    warn $stderr if $stderr;
    ok -f $outfile, "$outfile exists";

    my $dot = read_file($outfile);
    unlike $dot, qr/FAST::Struct::While/, 'FAST::Struct::While not in the dot source';
    like $dot, qr/FAST::Struct::Seq/, 'FAST::Struct::Seq is in the dot source';
    like $dot, qr/digraph uml_class_diagram/, 'dot ok';
}

