use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Deploy qw/do_system older/;
use Module::Extract::Use;
use JSON::Parse 'json_file_to_perl';
use Perl::Build 'get_info';
my $info = get_info (base => "$Bin/../", verbose => 1);
die unless $info;
my $pm = $info->{pm};
my $extor = Module::Extract::Use->new;
my @modules = $extor->get_modules( $pm );
my $meta = "$Bin/../MYMETA.json";
my $make = "$Bin/../Makefile.PL";
if (older ($meta, $make)) {
    chdir "$Bin/../";
    do_system ("perl Makefile.PL");
    if (! -f $meta) {
	die "no $meta";
    }
}
my $minfo = json_file_to_perl ($meta);
my $runreq = $minfo->{prereqs}{runtime}{requires};
my %mods;
for my $module (@modules) {
    next if $module =~ /\b(utf8|strict|warnings)\b/;
    $mods{$module} = 1;
    ok (defined $runreq->{$module}, "Requirement for $module is in meta file");
}
for my $req (keys %$runreq) {
    next if $req =~ /\b(perl)\b/;
    ok (defined $mods{$req}, "requirement for $req matches module");
}
done_testing ();
