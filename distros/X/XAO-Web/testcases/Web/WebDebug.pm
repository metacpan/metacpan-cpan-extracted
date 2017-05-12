package testcases::Web::WebDebug;
use strict;
use XAO::Utils;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object (page)");

    my $testpage=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($testpage),
                  "Can't load Page object (testpage)");

    my $text=$page->expand(template => '<%Debug set="show-path,foobar"%>');

    $self->assert($text eq '',
                  "Debug returned some text ($text) while it should not");
    $self->assert($testpage->debug_check('show-path'),
                  "Show-path is not set while it shold be");
    $self->assert($testpage->debug_check('foobar'),
                  "Foobar is not set while it shold be");

    $text=$testpage->expand(template => '<%Debug clear="foobar" set="qwe"%>');

    $self->assert($text eq '',
                  "Debug returned some text ($text) while it should not");
    $self->assert($page->debug_check('show-path'),
                  "Show-path is not set while it shold be");
    $self->assert(!$page->debug_check('foobar'),
                  "Foobar is set while it shold NOT be");
    $self->assert($page->debug_check('qwe'),
                  "Qwe is not set while it shold be");
}

1;
