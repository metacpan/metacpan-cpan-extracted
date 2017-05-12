use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('UML::Sequence::JavaSeq'); }

my $youre_brave = 1;

chomp(my $java_path = `which java`);
my $tools_jar;
my $java_failed = $?;
my $tool_failed = 0;

unless ($java_failed) {
    $tools_jar      = $java_path;
    my $count       = $tools_jar =~ s!/bin/java!!;
    $tool_failed    = 1 unless $count;
    $tools_jar      = "$tools_jar/lib/tools.jar";
    $tool_failed    = 1 unless (-f $tools_jar);
    $ENV{CLASSPATH} = "$tools_jar:.";
}

SKIP: {
    skip "No Java found",                           2 if $java_failed;
    skip "No tools.jar found, I tried: $tools_jar", 2 if $tool_failed;

    chdir "java";

    my $out_rec     = UML::Sequence::JavaSeq
                        ->grab_outline_text(qw(Hello.methods Hello));

    my @correct_out = <DATA>;

    is_deeply($out_rec, \@correct_out, "java sequence outline");

    my $methods     = UML::Sequence::JavaSeq->grab_methods($out_rec);

    my @correct_methods = (
        "Hello.main(java.lang.String[])\n",
        "HelloHelper.<init>()\n",
        "HelloHelper.<init>(java.lang.String)\n",
        "HelloHelper.printIt(java.lang.String, float, java.lang.String[][], HelloHelper)\n",
    );

    my @methods = sort keys %$methods;

    is_deeply(\@methods, \@correct_methods, "method list");

}

__DATA__
Hello.main(java.lang.String[])
  helloHelper1:HelloHelper.<init>()
    helloHelper2:HelloHelper.<init>(java.lang.String)
  helloHelper2:HelloHelper.printIt(java.lang.String, float, java.lang.String[][], HelloHelper)
