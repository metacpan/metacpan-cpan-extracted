use strict;
use warnings;
use Text::MicroTemplate::Extended;
use FindBin;
use Test::More tests => 2;

{
    package t::Poo;
    sub bob {
        my $code = shift;
        my $mteref = $t::Poo::_MTEREF || $t::Poo::_MTREF;
        my $before = $$mteref;
        $$mteref = '';
        $code->();
        $$mteref =~ s/John/Bob/;
        $$mteref = $before . $$mteref;
    }
}

my $t = Text::MicroTemplate::Extended->new(
    include_path => [ "$FindBin::Bin/templates" ],
    use_cache    => 2,
    package_name => 't::Poo',
);
my $got = $t->render_file("filter");
like $got, qr/base title/;
like $got, qr/Hello, Bob\./;

