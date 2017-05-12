# $Id: WWW-Scraper-Yahoo360.t 168 2009-05-31 11:51:37Z cosimo $

use Test::More tests => 44;

BEGIN {
    use_ok('WWW::Scraper::Yahoo360')
}

# Enable debug mode
# $WWW::Scraper::Yahoo360::DEBUG = 1;

my $y360 = WWW::Scraper::Yahoo360->new({
    username => 'fake',
    password => 'even-more-fake',
});


# ---------------------------------------------------
# Parsing of blog posts and comments
# ---------------------------------------------------

diag("Parsing a standard blog page");

my $blog_page = File::Slurp::read_file(q{./t/blog.html});
my $blog_info = $y360->blog_info($blog_page);
#iag( JSON::XS->new->pretty->encode($blog_info) );

is (
    $blog_info->{link},
    'http://blog.360.yahoo.com/blog-jfCUH8k5fqpqLD7PHOY4YMCi5eU-?cq=1',
    'Blog permanent link is correctly extracted'
);

is (
    $blog_info->{sharing},
    'public',
    'Blog sharing level is correctly extracted'
);

is (
    $blog_info->{count}, 13,
    'Blog posts count is correctly extracted'
);

ok(
    $blog_info->{start} == 1 && $blog_info->{end} == 5,
    'Blog posts start/end is correctly extracted'
);

is(
    $blog_info->{title},
    'Dieu Anh&#39;s Blog',
    'Title of the blog is extracted correctly'
);

#
# get_blog_posts() tests
#
my $posts = $y360->get_blog_posts($blog_page, start=>1, end=>5, count=>5);
is(scalar @{$posts}, 5, 'Parsed 5 blog posts in the blog main page');

my $first = $posts->[0];

ok(
	ref $first eq 'HASH',
	'First blog post is a hashref'
);

ok(
	$first->{title},
	'Title is parsed correctly (' . $first->{title} . ')'
);

is(
	$first->{comments}, 0,
	'Number of comments is correct'
);

like(
	$first->{tags},
	qr{^myopera},
	'Tags parsed correctly (' . $first->{tags} . ')'
);

like(
	$first->{description},
	qr{<img src="http://files\.myopera\.com/myfrenchopera/files/sitelanguage\.jpg"/></div>$},
	'Blog post is not truncated'
);

is(
	$first->{pubDate},
	'Tue, 16 Dec 2008 13:11:00 GMT',
	'Blog post date is parsed correctly'
);

like(
	$first->{link},
	qr{^http://blog\.360\.yahoo\.com/},
	'Blog post link contains blog.360.yahoo.com',
);

#
# get_blogpost_comments() tests
#
my $blogpost_page = File::Slurp::read_file(q{./t/blogpost_with_1_comment.html});
my $comments = $y360->get_blogpost_comments(
    {link=>'http://360.yahoo.com/blah'}, # Pretend we have a link
    $blogpost_page
);

#iag( JSON::XS->new->pretty->encode($comments) );

is (ref $comments, 'ARRAY', 'comments extracted in an array ref');
is (@$comments, 1, 'found one comment');

my $comment = $comments->[0];

like (
    $comment->{link}, qr{http://.*360\.yahoo\.com/.*},
    'Found link to the original blog post (' . $comment->{link} . ')',
);

like (
    $comment->{'user-profile'}, qr{http://.*360\.yahoo\.com/.*},
    'Found link of the profile of the user that posted the comment',
);


like (
    $comment->{comment}, qr{^welcome u visit},
    'Found the comment body'
);

is (
    $comment->{username}, q{palbongro},
    'Found correct username'
);

# ---------------------------------------------------
# Parsing of a blog post with many comments
# ---------------------------------------------------

diag("Parsing a blog page with many comments");

$blogpost_page = File::Slurp::read_file(q{./t/blogpost_with_many_comments.html});
$comments = $y360->get_blogpost_comments({}, $blogpost_page);

#iag( JSON::XS->new->pretty->encode($comments) );

is (ref $comments, 'ARRAY', 'comments extracted in an array ref');
is (@$comments, 5, 'found correct number of comment');

is (
    $comments->[0]->{username}, 'Not gonna get us',
    'Username of first comment is correct. Extraction order is correct.'
);

# ---------------------------------------------------
# Parsing of dates
# ---------------------------------------------------

diag("Parsing of dates");

# Mon, 25 Aug 2008 12:28:00 GMT
my @dates = (
    [ q{Monday August 25, 2008 - 05:28am (PDT)}, 1219667280 ],
    [ q{Tuesday November 11, 2008 - 10:26pm (ICT)}, 1226417160 ],
    [ q{Wednesday February 4, 2009 - 12:00pm (ICT)}, 1233723600 ],
    [ q{Sunday May 24, 2009 - 12:27am (ICT)}, 1243099620 ],
);

for (@dates) {
    my ($date, $expected_result) = @$_;
    is (
        $y360->parse_date($date),
        $expected_result,
        'Date {' . $date . '} is parsed correctly'
    );
}

# -----------------------------------------------------
# A different page - parsing of blog posts and comments
# -----------------------------------------------------

diag("Parsing of alternative blog page");

$blog_page = File::Slurp::read_file(q{./t/blog2.html});
$blog_info = $y360->blog_info($blog_page);
#iag( JSON::XS->new->pretty->encode($blog_info) );

is(
    $blog_info->{title}, 'Test Blog',
    'Title of blog extracted correctly'
);

is(
    $blog_info->{sharing}, 'private',
    'Blog sharing set to private should be parsed correctly',
);


$posts = $y360->get_blog_posts($blog_page, start=>1, end=>4, count=>4);
is(scalar @{$posts}, 4, 'Parsed 4 blog posts in the alternative test page');
my $post = $posts->[0];

is(
    $post->{title}, 'Entry for March 17, 2007',
    'Title of post extracted correctly'
);

is(
    $post->{link}, 'http://blog.360.yahoo.com/blog-cqkAz2HmPNV3F9wncqkA-?cq=1&p=5',
    'Link to blog post extracted correctly'
);

# Check parsing of pictures
unlike(
    $post->{description},
    qr{<img \s src=}mx,
    'Picture is not added when not present',
);

# Blog post content should be just blog post, no empty newlines or <div>s for picture
is(
    $post->{description},
    '<p>Chuyen sang ngoi nha moi</p> <p>http://my.opera.com/testuser2</p>',
	'Blog post contents with no picture are extracted correctly',
);

$post = $posts->[3];
like(
    $post->{description},
    qr{<img \s src=}mx,
    'Picture is parsed correctly'
);

#iag( JSON::XS->new->pretty->encode($posts) );


# -----------------------------------------------------
# Page that used to hang, only 1 blog post
# -----------------------------------------------------

diag("Parsing of page with just 1 blog post");

$blog_page = File::Slurp::read_file(q{./t/blog3.html});
$blog_info = $y360->blog_info($blog_page);
#iag( JSON::XS->new->pretty->encode($blog_info) );

is(
    $blog_info->{title}, 'Hang test',
    'Title of blog extracted correctly when page has only 1 post'
);

is(
    $blog_info->{sharing}, 'public',
    'Blog sharing parsed correctly when page has only 1 post'
);

# Catch infinite loop parsing regressions
eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 5;
    $posts = $y360->get_blog_posts($blog_page, start=>1, end=>1, count=>1);
    alarm 0;
};
if ($@) {
    ok(0, "Regression: get_blog_posts() should not hang when there's only 1 blog post");
}
else {
    is(scalar @{$posts}, 1, 'Parsed 1 blog post page correctly');
}

$post = $posts->[0];

is(
    $post->{title}, 'Blog chuyển sang Opera!',
    'Title of post extracted correctly'
);

is(
    $post->{link}, 'http://blog.360.yahoo.com/blog-w7QmVu4cfGV4rfrQdjX5O6--?cq=1&p=1',
    'Link to blog post extracted correctly'
);


# -----------------------------------------------------
# Another page that used to hang
# -----------------------------------------------------

diag("Parsing another crash-me page with no blog entries");

$blog_page = File::Slurp::read_file(q{./t/blog4.html});
$blog_info = $y360->blog_info($blog_page);
#iag( JSON::XS->new->pretty->encode($blog_info) );

like($blog_page, qr(There are no blog entries), 'No blog entries for this page');

is(
    $blog_info->{title}, 'Test4',
    'Title of blog extracted correctly when page has no posts'
);

is(
    $blog_info->{sharing}, 'public',
    'Blog sharing parsed correctly when page has no posts'
);

# Catch infinite loop parsing regressions
eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 5;
    $posts = $y360->get_blog_posts($blog_page, start=>1, end=>1, count=>1);
    alarm 0;
};
if ($@) {
    ok(0, "Regression: get_blog_posts() should not hang when there's no blog posts");
}
else {
    is(scalar @{$posts}, 0, 'Found no blog posts');
}

