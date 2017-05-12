use Test'More tests => 1;

# [rt.cpan.org #108645]
use WWW::Scripter;

eval {
        my $scripter = WWW::Scripter->new;
        $scripter->use_plugin('JavaScript');
        $scripter->eval("var t = false;");
        die "Fatality!\n";
};
is $@, "Fatality!\n", 'destructors do not clobber $@';
