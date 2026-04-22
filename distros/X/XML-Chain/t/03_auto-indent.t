#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;

use FindBin qw($Bin);
use lib "$Bin/lib";

use XML::Chain qw(xc);

subtest 'auto indentation (synopsis of XML::Chain::Selector)' => sub {

    # Simple indentation.
    my $simple = xc('div')->auto_indent(1)->c('div')->t('in')->root;
    eq_or_diff_text(
        $simple->as_string,
        "<div>\n\t<div>in</div>\n</div>",
        'auto indented simple'
    );

    # Namespaces and auto indentation.
    my $user =
        xc( 'user', xmlns => 'http://testns' )
        ->auto_indent( { chars => ' ' x 4 } )
        ->a( 'name',     '-' => 'Johnny Thinker' )
        ->a( 'username', '-' => 'jt' )
        ->c('bio')
        ->c( 'div', xmlns => 'http://www.w3.org/1999/xhtml' )
        ->a( 'h1', '-' => 'about' )
        ->a( 'p',  '-' => '...' )
        ->up->a( 'greeting', '-' => 'Hey' )->up->a( 'active', '-' => '1' )
        ->root;
    eq_or_diff_text( $user->as_string, user_as_string(),
        '=head1 SYNOPSIS; auto-indented user' );
};

subtest 'auto indentation is non-destructive' => sub {
    my $mixed = xc( \'<div><p>  keep   spacing  </p><p>second</p></div>' );
    my $before_plain = $mixed->as_xml_libxml->toStringC14N;

    $mixed->auto_indent(1);
    my $indented_once  = $mixed->as_string;
    my $after_plain    = $mixed->as_xml_libxml->toStringC14N;
    my $indented_twice = $mixed->as_string;

    is( $after_plain, $before_plain,
        'auto_indent() does not mutate the original DOM content',
    );
    is( $after_plain,
        '<div><p>  keep   spacing  </p><p>second</p></div>',
        'original text spacing is preserved after auto-indented rendering',
    );
    is( $indented_twice, $indented_once,
        'auto-indented serialization is idempotent',
    );
};

subtest 'partial auto_indent on subtrees' => sub {

    # Create nested structure
    my $root =
        xc( 'root', )
        ->c( 'section', id => 'a' )
        ->c('item')
        ->t('Item 1')
        ->up->up->c( 'section', id => 'b' )
        ->c('item')
        ->t('Item 2')
        ->up->up->c( 'section', id => 'c' )->c('item')->t('Item 3')->root;

    # Format only section b
    my $section_b = $root->find('//section[@id="b"]')->first;
    $section_b->auto_indent(1);

    # Render the formatted subtree directly
    my $output_b = $section_b->as_string;

    # Section b should have formatted children with indentation
    like(
        $output_b,
        qr/<section id="b">\s*<item>Item 2<\/item>\s*<\/section>/,
        'formatted subtree has indentation when rendered directly'
    );

    # When rendering unformatted section, it should be compact
    my $section_a = $root->find('//section[@id="a"]')->first;
    my $output_a  = $section_a->as_string;
    like(
        $output_a,
        qr/<section id="a"><item>Item 1<\/item><\/section>/,
        'unformatted section remains compact'
    );
};

subtest 'auto_indent on multiple subtrees' => sub {

    # Create structure with multiple branches
    my $root =
        xc('root')
        ->c( 'branch', name => 'first' )
        ->c('leaf')
        ->t('l1')
        ->up->c('leaf')->t('l2')->up->up->c( 'branch', name => 'second' )
        ->c('leaf')
        ->t('l3')
        ->up->c('leaf')->t('l4')->up->root;

    # Format all branches
    $root->find('//branch')->auto_indent(1);

    # Render each formatted branch
    my @branches           = $root->find('//branch')->as_xml_libxml;
    my $first_branch_elem  = $root->find('//branch[@name="first"]')->first;
    my $second_branch_elem = $root->find('//branch[@name="second"]')->first;

    my $output_first  = $first_branch_elem->as_string;
    my $output_second = $second_branch_elem->as_string;

    # Both branches should have formatted children
    like(
        $output_first,
        qr/<branch name="first">\s*<leaf>l1<\/leaf>\s*<leaf>l2<\/leaf>\s*<\/branch>/,
        'first branch renders with indentation'
    );
    like(
        $output_second,
        qr/<branch name="second">\s*<leaf>l3<\/leaf>\s*<leaf>l4<\/leaf>\s*<\/branch>/,
        'second branch renders with indentation'
    );
};

subtest 'auto_indent with custom indentation chars on subtrees' => sub {

    # Create structure
    my $root =
        xc('root')->c('container')->c('item')->t('one')->up->c('item')
        ->t('two')
        ->up->root;

    # Format with 2-space indentation
    my $container = $root->find('//container')->first;
    $container->auto_indent( { chars => '  ' } );

    my $output = $container->as_string;

    # Should contain 2-space indentation with newlines
    like(
        $output,
        qr/<container>\s*\n\s{2}<item>one<\/item>\s*\n\s{2}<item>two<\/item>\s*\n<\/container>/s,
        'subtree formatted with custom indentation chars (2 spaces) and newlines'
    );
};

subtest 'nested partial formatting' => sub {

    # Create deeply nested structure
    my $root =
        xc('root')
        ->c( 'div', id => '1' )
        ->c( 'div', id => '1.1' )
        ->c('span')
        ->t('text1')
        ->up->up->up->c( 'div', id => '2' )
        ->c( 'div', id => '2.1' )
        ->c('span')
        ->t('text2')
        ->up->up->root;

    # Format only the inner div 1.1
    my $div_1_1 = $root->find('//div[@id="1.1"]')->first;
    $div_1_1->auto_indent(1);

    my $output = $div_1_1->as_string;

    # Div 1.1 and its children should be formatted
    like(
        $output,
        qr/<div id="1\.1">\s*<span>text1<\/span>\s*<\/div>/,
        'inner div 1.1 renders formatted with indentation'
    );

    # Div 2.1 should NOT be formatted (unless we format it)
    my $div_2_1    = $root->find('//div[@id="2.1"]')->first;
    my $output_2_1 = $div_2_1->as_string;
    like(
        $output_2_1,
        qr/<div id="2\.1"><span>text2<\/span><\/div>/,
        'non-selected div 2.1 stays compact'
    );
};

subtest 'partial indenting preserves DOM for unformatted elements' => sub {
    my $orig_content = '<root><a>content a</a><b><c>content c</c></b></root>';
    my $root         = xc( \$orig_content );

    # Store original unformatted state
    my $before_format = $root->as_string;

    # Format only element b
    my $elem_b = $root->find('//b')->first;
    $elem_b->auto_indent(1);

    # Render element b with formatting
    my $b_formatted = $elem_b->as_string;

    # Element a should still be unformatted
    my $elem_a   = $root->find('//a')->first;
    my $a_output = $elem_a->as_string;
    like( $a_output, qr/<a>content a<\/a>/, 'element a remains compact' );

    # Element b content should now be on separate lines
    like(
        $b_formatted,
        qr/<b>\s*<c>content c<\/c>\s*<\/b>/,
        'element b is formatted'
    );
};

subtest 'auto_indent chainable on subtrees' => sub {
    my $root =
        xc('root')->c('section')->c('para')->t('p1')->up->c('para')
        ->t('p2')
        ->up->root;

    # Get section and chain formatting with other operations
    my $section = $root->find('//section')->first;
    $section->auto_indent(1)->c('para')->t('p3');

    # Render the formatted section
    my $output = $section->as_string;

    # Should have 3 paragraphs in formatted section
    my $section_count = $section->find('//para')->count;
    is( $section_count, 3, 'chaining after auto_indent works' );

    # Section should be formatted
    like(
        $output,
        qr/<section>\s*<para>p1<\/para>\s*<para>p2<\/para>\s*<para>p3<\/para>\s*<\/section>/,
        'formatted section with added element'
    );
};

subtest 'rendering subtree multiple times with auto_indent' => sub {
    my $root = xc('root')->c('item')->t('content')->root;

    my $item = $root->find('//item')->first;
    $item->auto_indent(1);

    # Render subtree multiple times
    my $first_render  = $item->as_string;
    my $second_render = $item->as_string;

    is( $first_render, $second_render,
        'multiple renders of formatted subtree produce consistent output' );

    # Root element (unformatted) should stay compact
    my $root_output = $root->as_string;
    like(
        $root_output,
        qr/<root><item>content<\/item><\/root>/,
        'root element remains unformatted'
    );
};

done_testing;

sub user_as_string {
    my $usr = <<'__USER_AS_STRING__'
<user xmlns="http://testns">
    <name>Johnny Thinker</name>
    <username>jt</username>
    <bio>
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>about</h1>
            <p>...</p>
        </div>
        <greeting>Hey</greeting>
    </bio>
    <active>1</active>
</user>
__USER_AS_STRING__
        ;
    chomp($usr);
    return $usr;
}
