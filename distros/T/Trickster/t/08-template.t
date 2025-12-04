use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    eval { require Text::Xslate; };
    if ($@) {
        plan skip_all => 'Text::Xslate required for template tests';
    }
}

use_ok('Trickster::Template');

# Create temporary template directory
my $tmpdir = tempdir(CLEANUP => 1);
my $template_dir = File::Spec->catdir($tmpdir, 'templates');
mkdir $template_dir;

# Create a simple template
my $simple_template = File::Spec->catfile($template_dir, 'simple.tx');
open my $fh, '>', $simple_template or die "Cannot create template: $!";
print $fh "Hello [% name %]!";
close $fh;

# Create a layout template
my $layout_template = File::Spec->catfile($template_dir, 'layout.tx');
open $fh, '>', $layout_template or die "Cannot create layout: $!";
print $fh "<html><body>[% content | mark_raw %]</body></html>";
close $fh;

# Create a page template
my $page_template = File::Spec->catfile($template_dir, 'page.tx');
open $fh, '>', $page_template or die "Cannot create page: $!";
print $fh "<h1>[% title %]</h1>";
close $fh;

# Test basic template rendering
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
    );
    
    ok($template, 'Template engine created');
    
    my $output = $template->render('simple.tx', { name => 'World' });
    is($output, 'Hello World!', 'Basic template rendering works');
}

# Test render_string
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
    );
    
    my $output = $template->render_string(
        'Hello [% name %]!',
        { name => 'Alice' }
    );
    is($output, 'Hello Alice!', 'String template rendering works');
}

# Test layout
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
        layout => 'layout.tx',
    );
    
    my $output = $template->render('page.tx', { title => 'Test Page' });
    is($output, '<html><body><h1>Test Page</h1></body></html>', 'Layout rendering works');
}

# Test no_layout option
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
        layout => 'layout.tx',
    );
    
    my $output = $template->render('page.tx', { 
        title => 'Test Page',
        no_layout => 1,
    });
    is($output, '<h1>Test Page</h1>', 'no_layout option works');
}

# Test default vars
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
        default_vars => {
            app_name => 'MyApp',
        },
    );
    
    my $output = $template->render_string(
        '[% app_name %]',
        {}
    );
    is($output, 'MyApp', 'Default vars work');
}

# Test set_default_vars
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
    );
    
    $template->set_default_vars({ version => '1.0' });
    
    my $output = $template->render_string('[% version %]', {});
    is($output, '1.0', 'set_default_vars works');
}

# Test set_layout
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
    );
    
    $template->set_layout('layout.tx');
    
    my $output = $template->render('page.tx', { title => 'Test' });
    like($output, qr/<html>/, 'set_layout works');
}

# Test custom functions
{
    my $template = Trickster::Template->new(
        path => [$template_dir],
        cache => 0,
        function => {
            double => sub { return $_[0] * 2 },
            greet => sub { return "Hello, $_[0]!" },
        },
    );
    
    my $output = $template->render_string('[% double(5) %]', {});
    is($output, '10', 'Custom function works');
    
    $output = $template->render_string('[% greet("World") %]', {});
    is($output, 'Hello, World!', 'Custom function with string works');
}

done_testing;
