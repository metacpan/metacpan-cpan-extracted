
use Test;
BEGIN { plan tests => 1 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use base 'Waft';

my $template = << 'END_OF_TEMPLATE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<title>compile_template.t</title>
<script type="text/javascript"><!-- <![CDATA[
    var test = '<%j= "\t" %>' + '<%jsstr= "\x0A" %>'
               + '<% j= "\x0D" %>' + '<% jsstr= q{"} %>'
               + '<%j = q{&} %>' + '<%jsstr = q{'} %>'
               + '<% j = q{/\\} %>' + '<% jsstr = q{<>} %>';
    // ]]> -->
</script>
</head>
<body>
<p>
<%p= "\t" %><%plain= "\x0A" %>
<% p= "\x0D" %><% plain= q{"} %>
<%p = q{&} %><%plain = q{'} %>
<% p = q{/\\} %><% plain = q{<>} %>
</p>
<p>
<%t= "\t" %><%text= "\x0A" %>
<% t= "\x0D" %><% text= q{"} %>
<%t = q{&} %><%text = q{'} %>
<% t = q{/\\} %><% text = q{<>} %>
</p>
<p>
<%w= "\t" %><%word= "\x0A" %>
<% w= "\x0D" %><% word= q{"} %>
<%w = q{&} %><%word = q{'} %>
<% w = q{/\\} %><% word = q{<>} %>
</p>
<p>
<%= "\t" %><%= "\x0A" %>
<%= "\x0D" %><%= q{"} %>
<% = q{&} %><% = q{'} %>
<% = q{/\\} %><% = q{<>} %>
</p>
</body>
</html>
END_OF_TEMPLATE

my $filtered = << 'END_OF_FILTERED';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<title>compile_template.t</title>
<script type="text/javascript"><!-- <![CDATA[
    var test = '	' + '\n'
               + '\r' + '\"'
               + '&' + '\''
               + '\/\\' + '\x3C\x3E';
    // ]]> -->
</script>
</head>
<body>
<p>
	

"
&'
/\<>
</p>
<p>
&nbsp; &nbsp; &nbsp; &nbsp; <br />

<br />&quot;
&amp;&#39;
/\&lt;&gt;
</p>
<p>
	

&quot;
&amp;&#39;
/\&lt;&gt;
</p>
<p>
	

&quot;
&amp;&#39;
/\&lt;&gt;
</p>
</body>
</html>
END_OF_FILTERED

my $output = q{};

sub output {
    ( undef, my @strings ) = @_;

    $output .= join q{}, @strings;

    return;
}

my $self = __PACKAGE__->new->initialize;

my $coderef = $self->compile_template($template, $0, __PACKAGE__);
$self->$coderef();

ok( $output eq $filtered );
