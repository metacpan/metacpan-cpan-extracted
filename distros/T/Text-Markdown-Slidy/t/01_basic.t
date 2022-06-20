use strict;
use warnings;
use utf8;
use Test::More 0.98;
use Text::Markdown::Slidy;
use YAML::PP ();

my $tc_raw = do {
    local $/;
    <DATA>
};

my $test_cases = YAML::PP::Load($tc_raw);

for my $tc (@$test_cases) {
    subtest $tc->{name}, sub {
        my $md = markdown($tc->{input});
        is $md, $tc->{expect};

        my ($md2, $meta) = markdown($tc->{input});
        is $md2, $tc->{expect};
        my $expect_meta = $tc->{meta};
        if (!$expect_meta) {
            ok !$meta;
        } else {
            is_deeply $meta, $tc->{meta};
        }
    };
}

done_testing;

__DATA__
- name: plain
  input: |

    Title1
    ======
    abcde
    fg

    Title2
    ---
    hoge

    Title3
    ---

    Title4
    ----

    Title5
    ---  

  expect: |
    <div class="slide">
    <h1>Title1</h1>

    <p>abcde
    fg</p>
    </div>

    <div class="slide">
    <h2>Title2</h2>

    <p>hoge</p>
    </div>

    <div class="slide">
    <h2>Title3</h2>
    </div>

    <div class="slide">
    <h2>Title4</h2>
    </div>

    <div class="slide">
    <h2>Title5</h2>
    </div>
- name: loose frontmatter
  input: |
    hoge: fuga
    ---
    # Title

    Title2
    ---

    hoge
  expect: |
    <div class="slide">
    <h1>Title</h1>
    </div>

    <div class="slide">
    <h2>Title2</h2>

    <p>hoge</p>
    </div>
  meta:
    hoge: fuga
- name: strict frontmatter
  input: |
    ---
    hoge: fuga
    ---
    # Title

    Title2
    ---

    hoge
  expect: |
    <div class="slide">
    <h1>Title</h1>
    </div>

    <div class="slide">
    <h2>Title2</h2>

    <p>hoge</p>
    </div>
  meta:
    hoge: fuga
- name: hr as slide delimiter
  input: |
    ---
    hoge: fuga
    ---
    # Title

    Title2
    ---

    Contents
    - - -
    aiueo

    ---
    new slide

    hoge
  expect: |
    <div class="slide">
    <h1>Title</h1>
    </div>

    <div class="slide">
    <h2>Title2</h2>

    <p>Contents</p>

    <hr />
    </div>

    <div class="slide">
    <p>aiueo</p>

    <hr />
    </div>

    <div class="slide">
    <p>new slide</p>

    <p>hoge</p>
    </div>
  meta:
    hoge: fuga
