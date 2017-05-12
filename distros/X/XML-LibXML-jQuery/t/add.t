#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;

sub test (&@);


test { shift->add('div > bar') } "add(selector)";

test {
    my $orig = shift;
    $orig->add('bar', $orig->document->find('baz'));
} "add(selector, context)";

test {
    my $orig = shift;
    $orig->add($orig->document->find('div > bar')->{nodes});
} "add(elements)";

test {
    my $orig = shift;
    my $new = $orig->add('<bar/>')->append_to($orig->parent); # append to render as html
    $new;
} "add(html)";

test {
    my $orig = shift;
    my $new = $orig->add(j('<bar/>'))->append_to($orig->parent); # append to render as html
    $new;
} "add(jQuery)";


done_testing;



sub test (&@) {
    my ($cb, $name) = @_;

    my $html = q(
        <div>
            <foo/>
            <bar/>
            <baz>
                <bar/>
            </baz>
        </div>
    );

    subtest $name => sub {

        my $orig_obj = j($html)->find('foo');
        my $new_obj = $cb->($orig_obj);

        isnt $orig_obj, $new_obj, "returns new object";
        is $orig_obj->size, 1, 'orig object size';
        is $new_obj->size, 2, 'new object size';
        is $new_obj->as_html, '<foo></foo><bar></bar>', 'output';
    };
}
