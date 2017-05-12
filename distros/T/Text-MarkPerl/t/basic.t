use Modern::Perl;
use Test::More; 
use Test::Differences;
use Capture::Tiny ':all';

BEGIN {
  use_ok 'Text::MarkPerl','parse';
}

my ($markperl, $test);

#-------------------------------------------------------------------------------
$test = "strong";
$markperl = capture_stdout sub { parse(<<'EOF');
this is $strong
this is ${strong text}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
this is <strong>strong</strong><br/>
this is <strong>strong text</strong><br/>
EOF
#-------------------------------------------------------------------------------
$test = "emphasis";
$markperl = capture_stdout sub { parse(<<'EOF');
this is @emphasis
this is @{emphasis text}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
this is <em>emphasis</em><br/>
this is <em>emphasis text</em><br/>
EOF
#-------------------------------------------------------------------------------
$test = "tag";
$markperl = capture_stdout sub { parse(<<'EOF');
this is *{img}{src=""}{text text}
this is *{img}{}{text text}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
this is <img src="">text text</img><br/>
this is <img >text text</img><br/>
EOF
#-------------------------------------------------------------------------------
$test = "empty tag";
$markperl = capture_stdout sub { parse(<<'EOF');
this is %{a}{href="http://www.google.com"}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
this is <a href="http://www.google.com"/><br/>
EOF
#-------------------------------------------------------------------------------
$test = "code block";
$markperl = capture_stdout sub { parse(<<'EOF');
{
  use File::Temp;

  if (x > y) {
    z << c;
  }
}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
<pre><code>
  use File::Temp;

  if (x &gt; y) {
    z &lt;&lt; c;
  }
</pre></code>
<br/>
EOF
#-------------------------------------------------------------------------------
$test = "block quote";
$markperl = capture_stdout sub { parse(<<'EOF');
q{
 this 
 will appear
 as a <blockquote>
}
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
<blockquote>
 this 
 will appear
 as a &lt;blockquote&gt;
</blockquote>
<br/>
EOF
#-------------------------------------------------------------------------------
$test = "heading";
$markperl = capture_stdout sub { parse(<<'EOF');
===heading===
will appear
EOF
};
eq_or_diff $markperl, <<'EOF', $test;
<h3>heading</h3>
will appear<br/>
EOF
#-------------------------------------------------------------------------------
ddone_testing();
