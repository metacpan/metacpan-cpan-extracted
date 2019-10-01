
=head1 DESCRIPTION

This tests the L<Yancy::Backend::Static> directly.

=head1 SEE ALSO

L<Yancy>

=cut

use Test::More;
use Mojo::File qw( path tempdir );
use Yancy::Backend::Static;
use JSON::PP ( );

my $temp = tempdir();
my $be = Yancy::Backend::Static->new(
    'static:' . $temp,
);

my %index_page = (
    path => 'index',
    title => 'Index',
    is_draft => JSON::PP::false,
    markdown => qq{# Index\n\nThis is my index page\n},
);

my $id = $be->create( pages => \%index_page );
is $id, 'index', 'id is returned';
ok -e $temp->child( "$id.markdown" ), 'created index page exists';
like $temp->child( "$id.markdown" )->slurp, qr {false}, 'not a draft';

my $item = $be->get( pages => $id );
ok $item, 'id from create() works for get()';
is_deeply $item,
    {
        %index_page,
        html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
    },
    'returned page is complete and correct';

$item = $be->get( pages => 'NOT_FOUND' );
is $item, undef, 'get() NOT_FOUND returns undef';

my %about_page = (
    path => 'about',
    title => 'About',
    markdown => qq{# About\n\nThis is my about page\n},
);

$id = $be->create( pages => \%about_page );
is $id, 'about', 'id is returned';
ok -e $temp->child( "$id.markdown" ), 'created about page exists';
$item = $be->get( pages => $id );
ok $item, 'id from create() works for get()';
is_deeply $item,
    {
        %about_page,
        html => qq{<h1>About</h1>\n\n<p>This is my about page</p>\n},
    },
    'returned page is complete and correct';

my $result = $be->list( 'pages' );
is $result->{total}, 2, 'list() reports two pages total';
is_deeply $result->{items},
    [
        {
            %about_page,
            html => qq{<h1>About</h1>\n\n<p>This is my about page</p>\n},
        },
        {
            %index_page,
            html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
        }
    ],
    'list() reports correct items';

$result = $be->list( pages => { path => 'index' } );
is $result->{total}, 1, 'list() reports one page matching path "index"';
is_deeply $result->{items},
    [
        {
            %index_page,
            html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
        }
    ],
    'list() reports correct items matching path "index"';

$result = $be->list( pages => { path => { -like => 'in%' } } );
is $result->{total}, 1, 'list() reports one page matching path "in%"';
is_deeply $result->{items},
    [
        {
            %index_page,
            html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
        }
    ],
    'list() reports correct items matching path "index"';

$result = $be->list( 'pages', {}, { order_by => { -desc => 'path' } } );
is $result->{total}, 2, 'list() reports two pages total';
is_deeply $result->{items},
    [
        {
            %index_page,
            html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
        },
        {
            %about_page,
            html => qq{<h1>About</h1>\n\n<p>This is my about page</p>\n},
        },
    ],
    'list() reports correct items in correct order';

$result = $be->list( 'pages', {}, { order_by => { -desc => 'path' }, limit => 1 } );
is $result->{total}, 2, 'list() with limit still reports two pages total';
is_deeply $result->{items},
    [
        {
            %index_page,
            html => qq{<h1>Index</h1>\n\n<p>This is my index page</p>\n},
        },
    ],
    'list() returns only 1 item, because of limit';

$result = $be->list( 'pages', {}, { order_by => { -desc => 'path' }, offset => 1, limit => 1 } );
is $result->{total}, 2, 'list() with limit+offset still reports two pages total';
is_deeply $result->{items},
    [
        {
            %about_page,
            html => qq{<h1>About</h1>\n\n<p>This is my about page</p>\n},
        },
    ],
    'list() returns only 1 item, the 2nd item, because of limit+offset';

$result = $be->list( 'pages', {}, { order_by => { -desc => 'path' }, offset => 1, limit => 50 } );
is $result->{total}, 2, 'list() with limit+offset beyond the end still reports two pages total';
is_deeply $result->{items},
    [
        {
            %about_page,
            html => qq{<h1>About</h1>\n\n<p>This is my about page</p>\n},
        },
    ],
    'list() returns only 1 item, the 2nd item, even when limit wants more';

$success = $be->set( pages => 'index', { markdown => '# Index' } );
ok $success, 'partial set was successful';
$item = $be->get( pages => 'index' );
is_deeply $item,
    {
        %index_page,
        markdown => "# Index\n",
        html => qq{<h1>Index</h1>\n},
    },
    'set item is correct';

my %contact_page = (
    path => 'contact',
    title => 'Contact',
    markdown => qq{# Contact Me\n},
);

$success = $be->set( pages => 'contact', \%contact_page );
ok $success, 'create set was successful';
$item = $be->get( pages => 'contact' );
is_deeply $item,
    {
        %contact_page,
        html => qq{<h1>Contact Me</h1>\n},
    },
    'set item is correct';

$success = $be->set( pages => 'contact', { path => 'contact-different-path' } );
ok $success, 'partial set changing a path was successful';
$item = $be->get( pages => 'contact-different-path' );
is_deeply $item,
    {
        %contact_page,
        html => qq{<h1>Contact Me</h1>\n},
        path => 'contact-different-path',
    },
    'set item is correct';
ok !-f $temp->child( "contact.markdown" ), 'file is deleted';

$success = $be->delete( pages => 'about' );
ok $success, 'delete was successful';
ok !-f $temp->child( "about.markdown" ), 'file is deleted';

$item = $be->get( pages => '/' );
is_deeply $item,
    {
        %index_page,
        markdown => "# Index\n",
        html => qq{<h1>Index</h1>\n},
    },
    'get item with trailing slash works correctly';

done_testing;
