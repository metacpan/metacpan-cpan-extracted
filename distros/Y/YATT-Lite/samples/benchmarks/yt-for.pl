#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use YATT::Lite;

use Text::Xslate;
use Text::MicroTemplate qw(build_mt);
use HTML::Template::Pro;

use Benchmark qw(:all);
use Config; printf "Perl/%vd %s\n", $^V, $Config{archname};

foreach my $mod(qw(YATT::Lite
		   Text::Xslate Text::MicroTemplate HTML::Template::Pro)){
    print $mod, '/', $mod->VERSION, "\n";
}

my $n = shift(@ARGV) || 10;

my %vpath;
$vpath{for} = <<'TX';
<ul>
: for $books ->($item) {
    <li><:= $item.title :></li>
    <li><:= $item.title :></li>
    <li><:= $item.title :></li>
    <li><:= $item.title :></li>
    <li><:= $item.title :></li>
: }
</ul>
TX
;

my $tx = Text::Xslate->new(
    path      => \%vpath,
    cache_dir => '.xslate_cache',
    cache     => 2,
);

my $mt  = build_mt(<<'MT_END');
<ul>
? for my $item(@{$_[0]->{books}}) {
    <li><?= $item->{title} ?></li>
    <li><?= $item->{title} ?></li>
    <li><?= $item->{title} ?></li>
    <li><?= $item->{title} ?></li>
    <li><?= $item->{title} ?></li>
? }
</ul>
MT_END

my $ht = HTML::Template::Pro->new(scalarref => \<<'HT_END', case_sensitive => 1);
<ul>
<tmpl_loop name="books">
    <li><tmpl_var name="title" escape="html"></li>
    <li><tmpl_var name="title" escape="html"></li>
    <li><tmpl_var name="title" escape="html"></li>
    <li><tmpl_var name="title" escape="html"></li>
    <li><tmpl_var name="title" escape="html"></li>
</tmpl_loop>
</ul>
HT_END

my $yt = YATT::Lite->new(app_ns => 'MyApp'
			 , debug_cgen => $ENV{DEBUG_YATT}
			 , vfs => [data => <<'YT_END']);
<!yatt:args vars=value>
<ul><yatt:foreach my:value=item list="@{&yatt:vars{books};}">
    <li>&yatt:item{title};</li>
    <li>&yatt:item{title};</li>
    <li>&yatt:item{title};</li>
    <li>&yatt:item{title};</li>
    <li>&yatt:item{title};</li></yatt:foreach>
</ul>
YT_END


my %vars = (
     books => [(
        { title => 'Islands in the stream' },
        { title => 'Beautiful code' },
        { title => 'Introduction to Psychology' },
        { title => 'Programming Perl' },
        { title => 'Compilers: Principles, Techniques, and Tools' },
     ) x $n],
);

(my $o_tx = $tx->render(for => \%vars)) eq $mt->(\%vars)
    or die $tx->render(for => \%vars);

my $o_yt = $yt->render('' => [\%vars]);

$o_yt eq $o_tx
  or die "YATT generates different result.
==tx result==
$o_tx

==yt result==
$o_yt\n";

#$ht->param(\%vars);die $ht->output();

# suppose PSGI response body
cmpthese -1 => {
    Xslate => sub {
        my $body = [$tx->render(for => \%vars)];
        return;
    },
    MT => sub {
        my $body = [$mt->(\%vars)];
        return;
    },
    HTP => sub{
        $ht->param(\%vars);
        my $body = [$ht->output()];
        return;
    },
    YT => sub {
        my $body = $yt->render('' => [\%vars]);
	return;
    },
};
