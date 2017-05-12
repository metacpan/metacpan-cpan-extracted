use strict;
use warnings;

use Test::More 0.88 ();
use Test::Most;

plan skip_all => 'These tests requires HTML::Tidy'
    unless eval { require HTML::Tidy; 1 };

use File::Slurp qw( read_file );
use Path::Class qw( file );
use Text::TOC::HTML;

{
    my $gen = Text::TOC::HTML->new();
    my $file = file( 't', 'corpus', 'headers.html' );
    $gen->add_file( file => $file );

    my $toc_html = <<'EOF';
<ul>
  <li>
    <a href="#H2_A-0">H2 A</a>
    <ul>
      <li>
        <a href="#H3_A-1">H3 A</a>
        <ul>
          <li>
            <a href="#H4_A-2">H4 A</a>
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <a href="#H2_B-3">H2 B</a>
  </li>
  <li>
    <a href="#H2_C-4">H2 C</a>
  </li>
  <li>
    <a href="#H2_D-5">H2 D</a>
    <ul>
      <li>
        <ul>
          <li>
            <a href="#H4_B-6">H4 B</a>
          </li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'unordered list for single-document TOC'
    );

    my $page_html = <<'EOF';
<h1>Page Title</h1>

<p>
Some content.
</p>

<h2><a name="H2_A-0"></a>H2 A</h2>

<p>
More content.
</p>

<h3><a name="H3_A-1"></a>H3 A</h3>

<p>
More content.
</p>

<h4><a name="H4_A-2"></a>H4 A</h4>

<p>
More content.
</p>

<h5>H5 A</h5>

<p>
More content.
</p>

<h6>H6 A</h6>

<p>
More content.
</p>

<h2><a name="H2_B-3"></a>H2 B</h2>

<p>
More content.
</p>

<h2><a name="H2_C-4"></a>H2 C</h2>

<p>
More content.
</p>

<h2><a name="H2_D-5"></a>H2 D</h2>

<p>
More content.
</p>

<h4><a name="H4_B-6"></a>H4 B</h4>

<p>
More content.
</p>
EOF

    html_output_ok(
        $gen->html_for_document($file),
        $page_html,
        'unordered list for single-document TOC'
    );

    html_output_ok(
        $gen->html_for_document_body($file),
        $page_html,
        'unordered list for single-document TOC'
    );
}

{
    my $gen = Text::TOC::HTML->new();
    my $file = file( 't', 'corpus', 'headers.html' );
    $gen->add_file(
        file    => $file,
        content => scalar read_file( $file->stringify() ),
    );

    my $toc_html = <<'EOF';
<ul>
  <li>
    <a href="#H2_A-0">H2 A</a>
    <ul>
      <li>
        <a href="#H3_A-1">H3 A</a>
        <ul>
          <li>
            <a href="#H4_A-2">H4 A</a>
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <a href="#H2_B-3">H2 B</a>
  </li>
  <li>
    <a href="#H2_C-4">H2 C</a>
  </li>
  <li>
    <a href="#H2_D-5">H2 D</a>
    <ul>
      <li>
        <ul>
          <li>
            <a href="#H4_B-6">H4 B</a>
          </li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'unordered list for single-document TOC - content as string'
    );
}

{
    my $gen = Text::TOC::HTML->new( style => 'ordered' );
    $gen->add_file( file => file( 't', 'corpus', 'headers.html' ) );

    my $toc_html = <<'EOF';
<ol>
  <li>
    <a href="#H2_A-0">H2 A</a>
    <ol>
      <li>
        <a href="#H3_A-1">H3 A</a>
        <ol>
          <li>
            <a href="#H4_A-2">H4 A</a>
          </li>
        </ol>
      </li>
    </ol>
  </li>
  <li>
    <a href="#H2_B-3">H2 B</a>
  </li>
  <li>
    <a href="#H2_C-4">H2 C</a>
  </li>
  <li>
    <a href="#H2_D-5">H2 D</a>
    <ol>
      <li>
        <ol>
          <li>
            <a href="#H4_B-6">H4 B</a>
          </li>
        </ol>
      </li>
    </ol>
  </li>
</ol>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'ordered list for single-document TOC'
    );
}

{
    my $gen = Text::TOC::HTML->new( multi => 1 );
    $gen->add_file( file => file( 't', 'corpus', 'headers.html' ) );

    my $toc_html = <<'EOF';
<ul>
  <li>
    <a href="file://t/corpus/headers.html#Page_Title-0">Page Title</a>
    <ul>
      <li>
        <a href="file://t/corpus/headers.html#H2_A-1">H2 A</a>
        <ul>
          <li>
            <a href="file://t/corpus/headers.html#H3_A-2">H3 A</a>
            <ul>
              <li>
                <a href="file://t/corpus/headers.html#H4_A-3">H4 A</a>
              </li>
            </ul>
          </li>
        </ul>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_B-4">H2 B</a>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_C-5">H2 C</a>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_D-6">H2 D</a>
        <ul>
          <li>
            <ul>
              <li>
                <a href="file://t/corpus/headers.html#H4_B-7">H4 B</a>
              </li>
            </ul>
          </li>
        </ul>
      </li>
    </ul>
  </li>
</ul>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'unordered list for multi-document TOC'
    );
}

{
    my $gen = Text::TOC::HTML->new( multi => 1 );
    $gen->add_file( file => file( 't', 'corpus', 'headers.html' ) );
    $gen->add_file( file => file( 't', 'corpus', 'more.html' ) );

    my $toc_html = <<'EOF';
<ul>
  <li>
    <a href="file://t/corpus/headers.html#Page_Title-0">Page Title</a>
    <ul>
      <li>
        <a href="file://t/corpus/headers.html#H2_A-1">H2 A</a>
        <ul>
          <li>
            <a href="file://t/corpus/headers.html#H3_A-2">H3 A</a>
            <ul>
              <li>
                <a href="file://t/corpus/headers.html#H4_A-3">H4 A</a>
              </li>
            </ul>
          </li>
        </ul>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_B-4">H2 B</a>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_C-5">H2 C</a>
      </li>
      <li>
        <a href="file://t/corpus/headers.html#H2_D-6">H2 D</a>
        <ul>
          <li>
            <ul>
              <li>
                <a href="file://t/corpus/headers.html#H4_B-7">H4 B</a>
              </li>
            </ul>
          </li>
        </ul>
      </li>
    </ul>
  </li>
  <li>
    <a href="file://t/corpus/more.html#More_Page-8">More Page!</a>
    <ul>
      <li>
        <a href="file://t/corpus/more.html#Header_2-9">Header 2</a>
      </li>
      <li>
        <a href="file://t/corpus/more.html#A-1001001-10">1001001</a>
      </li>
    </ul>
  </li>
</ul>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'unordered list for multi-document TOC with multiple documents'
    );
}

{
    my $gen = Text::TOC::HTML->new();
    my $file = file( 't', 'corpus', 'out-of-order-headers.html' );
    $gen->add_file( file => $file );

    my $toc_html = <<'EOF';
<ul>
  <li>
    <ul>
      <li>
        <a href="#H3_A-0">H3 A</a>
      </li>
    </ul>
  <li>
    <a href="#H2-1">H2</a>
    <ul>
      <li>
        <a href="#H3_B-2">H3 B</a>
      </li>
    </ul>
  </li>
</ul>
EOF

    html_output_ok(
        $gen->html_for_toc(),
        $toc_html,
        'can handle out of order headers (first h3 before first h2)'
    );
}

{
    my $gen = Text::TOC::HTML->new();
    my $file = file( 't', 'corpus', 'headers.html' )->stringify();

    lives_ok { $gen->add_file( file => $file ) }
    'Can pass a string path to add_file';
}

done_testing();

sub html_output_ok {
    my $got_html    = shift;
    my $expect_html = shift;
    my $desc        = shift;

    my $tidy = HTML::Tidy->new(
        {
            doctype           => 'transitional',
            'sort-attributes' => 'alpha',
        }
    );

    my $real_expect_html = <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
  <title></title>
</head>
<body>
$expect_html
</body>
</html>
EOF

    my ($got_body) = $tidy->clean($got_html) =~ m{<body>(.+)</body>}s;
    my ($expect_body)
        = $tidy->clean($real_expect_html) =~ m{<body>(.+)</body>}s;

    eq_or_diff(
        $got_body,
        $expect_body,
        $desc
    );
}
