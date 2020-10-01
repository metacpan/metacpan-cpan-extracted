package testcases::Web::WebAction;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::MyAction);
use XAO::Errors qw(XAO::DO::Web::Action);
use Error qw(:try);

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    $self->siteconfig->put('/xao/action/json_canonical' => 1);
    $self->siteconfig->put('/xao/action/json_pretty' => 0);
    $self->siteconfig->put('/xao/page/character_mode' => 1);

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object (page)");

    my %tests=(
        '<%MyAction%>'                                                  => 'Got MODELESS',
        '<%MyAction mode="foo"%>'                                       => 'Got FOO',
        '<%MyAction mode="bar"%>'                                       => undef,
        '<%MyAction mode="test-one" arg="one"%>'                        => 'test-one-ok',
        '<%MyAction mode="test-two" arg="two"%>'                        => 'test-two-ok',
        '<%MyAction mode="test-three" format="json"%>'                  => qr/^\s*\[\s*"foo"\s*,\s*"bar"/s,
        '<%MyAction mode="test-four"%>'                                 => q({"bar":{"hash":"ref"},"foo":"scalar","status":"success"}),
        #
        # Alternate display methods
        #
        '<%MyAction mode="test-alt" arg="A"%>'                              => 'ALT:A',
        '<%MyAction mode="test-alt" datamode="test-alt" arg="B"%>'          => 'ALT:B',
        '<%MyAction displaymode="test-alt" datamode="test-alt" arg="C"%>'   => 'ALT:C',
        '<%MyAction mode="test-alt" displaymode="" arg="D"%>'               => 'ALT:D',
        '<%MyAction mode="test-alt" datamode="" arg="E"%>'                  => 'ALT:E',
        '<%MyAction datamode="test-alt" mode="data" arg="A"%>'              => q({"arg":"A","status":"success"}),
        '<%MyAction mode="test-alt" datamode="test-two" arg="A"%>'          => 'ALT:xxA',
        #
        # Cross-polination of code cache checking
        #
        '<%MyAction2 mode="foo"%>'                                      => 'MyAction2: Got FOO',
        '<%MyAction2 mode="test-one" arg="one"%>'                       => 'MyAction2: test-one-ok',
        #
        # XML output
        #
        '<%MyAction mode="test-four" format="xml"%>'                    => '<test-four><foo>scalar</foo><bar><hash>ref</hash></bar></test-four>',
        '<%MyAction mode="test-four" xmlmode="generic" format="xml"%>'  => '<data-keys>bar,foo,status</data-keys>',
        #
        qq(<\%MyAction datamode='test-alt' format='json' arg='a\x{2122}'\%>)        => Encode::encode('utf8',qq({"arg":"a\x{2122}","status":"success"})),
        qq(<\%MyAction datamode='test-alt' format='json-embed' arg='a\x{2122}'\%>)  => qq({"arg":"a\x{2122}","status":"success"}),
        qq(<\%MyAction datamode='test-alt' format='json' arg='b\x{2122}'\%>)        => Encode::encode('utf8',qq({"arg":"b\x{2122}","status":"success"})),
        qq(<\%MyAction datamode='test-alt' format='json-embed' arg='b\x{2122}'\%>)  => qq({"arg":"b\x{2122}","status":"success"}),
    );

    foreach my $template (sort keys %tests) {
        my $expect=$tests{$template};

        my ($err_my,$err_base,$err_unknown)=('','','');

        my $got;

        try {
            $self->siteconfig->force_byte_output(0);        # Gets switched to 1 by application/json MIME on json's
            $got=$page->expand(template => $template);
        }
        catch XAO::E::DO::Web::MyAction with {
            $err_my=''.shift;
        }
        catch XAO::E::DO::Web::Action with {
            $err_base=''.shift;
        }
        otherwise {
            $err_unknown=''.shift;
        };

        if(defined $expect) {
            $self->assert(!$err_unknown,
                "Got an UNKNOWN error '$err_unknown' for '$template'");

            $self->assert(!$err_base,
                "Got an BASE error '$err_base' for '$template'");

            $self->assert(!$err_my,
                "Got an LOCAL error '$err_my' for '$template'");

            if(ref $expect eq 'Regexp') {
                $self->assert($got =~ /$expect/,
                    "Expected '$expect', got '$got' for '$template' (regex)");
            }
            else {
                $self->assert($got eq $expect,
                    "Expected '$expect', got '$got' for '$template' (plain)");
            }
        }
        else {
            $self->assert(!defined $got,
                "Expected a failure, got '".(defined $got ? $got : '<undef>')."' for '$template'");

            $self->assert(!$err_unknown,
                "Expected a custom error, got generic '$err_unknown' for '$template'");

            $self->assert(!$err_base,
                "Expected a custom error, got generic '$err_base' for '$template'");

            $self->assert($err_my,
                "Expected an error, got no error and no result for '$template'");
        }
    }
}

###############################################################################
1;
