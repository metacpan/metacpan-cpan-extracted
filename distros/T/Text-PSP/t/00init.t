use Test::More tests => 4;
use File::Path qw(mkpath rmtree);
use strict;

BEGIN { use_ok 'Text::PSP';  };

if (-d 'tmp/work') {
	rmtree 'tmp/work';
}

eval {
	my $engine = Text::PSP->new('template_root' => 't/templates','workdir' => 'tmp/work');
};
ok ($@ =~ /Workdir tmp\/work does not exist/,"workdir check");

my $engine = Text::PSP->new(
    'template_root' => 't/templates',
    'workdir' => 'tmp/work',
    create_workdir => 1
);

ok (-d 'tmp/work',"create_workdir");

$engine = Text::PSP->new('template_root' => 't/templates','workdir' => 'tmp/work');

is(ref $engine,"Text::PSP","engine instantiation");

