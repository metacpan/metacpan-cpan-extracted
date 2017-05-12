use strict;
use Test::More;

BEGIN { 
	plan tests => 26;
}

no warnings;   # SAVERRR used only once
open SAVEERR, ">&STDERR" or die "can't dup stderr";
use warnings;
my $errors;
close STDERR;
open STDERR, '>', \$errors or die "can't stderr: $!";
eval 'use XML::XPathScript';
open STDERR, ">&SAVEERR";    # return to normal
is $errors => undef, 'late inclusion of XML::XPathScript';

sub test_xml {
	my( $xml, $style, $result, $comment ) = @_;
    my $xps = new XML::XPathScript( xml => $xml, stylesheet => $style );
	my $buffer;
	$xps->process( \$buffer );

	is $buffer => $result, $comment ;
}


test_xml( '<doc>dummy</doc>', 'working', 'working', 'empty run' );

test_xml( '<doc>dummy</doc>', '<%= apply_templates() %>', 
	'<doc>dummy</doc>', 'simple in/out');

test_xml( '<doc>dummy</doc>', '<% print "Hello!" %>', 'Hello!', 
	'rogue print statement' );

test_xml( '<doc><!-- hello world --></doc>', <<'EOT', "<doc>comment: hello world </doc>\n", 'processing a comment' );
<% $t->{'#comment'}{pre} = "comment:"; %><%= apply_templates() %>
EOT

test_xml( '<doc><!-- hello world --></doc>', <<'EOT', "<doc></doc>\n", 'masking a comment' );
<% $t->{'#comment'}{testcode} = sub{ 0 } %><%= apply_templates() %>
EOT

############################################################
# Interpolation

my $xml = "<doc><node color='blue'>Hello</node></doc>";
my $xps = <<'EOT';
<% 
	set_interpolation( 0 );
	$t->{node}{testcode} = sub { 
		my( $n, $t ) = @_; 
		$t->{pre} = '{@color}'; 
		return DO_SELF_ONLY
	}; 
%>
<%= apply_templates() %>
EOT
test_xml( $xml, $xps, "\n<doc>{\@color}</doc>\n", 'Interpolation (disabled)'  );

$xps = <<'EOT';
<% 
	$XML::XPathScript::DoNotInterpolate = 0; 
	$t->{node}{testcode} = sub
	{ 
		my( $n, $t ) = @_; 
		$t->{pre} = '{@color}'; 
		return DO_SELF_ONLY() 
	}; %>
<%= apply_templates() %>
EOT

test_xml( $xml, $xps, "\n<doc>blue</doc>\n", 'Interpolation (enabled)'  );

############################################################
# double interpolation 

$xps = <<'EOT';
<% 
	$XML::XPathScript::DoNotInterpolate = 0; 
	$t->{node}{testcode} = sub
	{ 
		my( $n, $t ) = @_; 
		$t->{pre} = '{@color}:{@color}'; 
		return DO_SELF_ONLY() 
	}; %>
<%= apply_templates() %>
EOT
test_xml( $xml, $xps, "\n<doc>blue:blue</doc>\n", 'Double interpolation'  );

############################################################
# interpolation regex

test_xml( '<doc arg="stuff" />', <<'XPS' , "stuff\n", 'interpolation regex' );
<%
	set_interpolation_regex( qr/\[\[(.*?)\]\]/ );
	$t->{doc}{pre} = '[[@arg]]';
%><%= apply_templates() %>
XPS


test_xml( '<doc><apple/><banana/></doc>', <<'EOT', "<doc>!<apple></apple><banana></banana>?</doc>\n", 'Prechildren and Postchildren tags, with children' );
<%
	$t->{doc}{prechildren} = '!';
	$t->{doc}{postchildren} = '?';
	$t->{doc}{showtag} = 1;
%><%= apply_templates() %>
EOT

test_xml( '<doc></doc>', <<'EOT', "<doc></doc>\n", 'Prechildren and Postchildren tags, without children' );
<%
	$t->{doc}{prechildren} = '!';
	$t->{doc}{postchildren} = '?';
	$t->{doc}{showtag} = 1;
%><%= apply_templates() %>
EOT

test_xml( '<doc><apple/><banana/></doc>', <<'EOT', "<doc>!<apple></apple>?!<banana></banana>?</doc>\n", 'Prechild and Postchild tags' );
<%
	$t->{doc}{prechild} = '!';
	$t->{doc}{postchild} = '?';
	$t->{doc}{showtag} = 1;
%><%= apply_templates() %>
EOT

test_xml( '<doc>empty</doc>', '<!--#include file="t/include.xps" -->', "#include works!\n", '<!--#include -->' );

test_xml( '<doc>empty</doc>', '<!--#include file="t/include2.xps" -->', "#include works!\n\n", '2 levels of <!--#include -->' );

close STDERR;
open STDERR, '>', \{ my $x };
test_xml( '<doc>empty</doc>', '<!--#include file="t/recursive.xps" -->', "Ooops.\n", 'recursive <!--#include -->' );

test_xml( '<doc>empty</doc>', '<!--#include file="t/include3.xps" -->', "Ooops.\n\n", '2 levels of <!--#include --> + recursion' );
open STDERR, ">&SAVEERR";    # return to normal

# override of printform
$xps = new XML::XPathScript( xml => '<doc/>', stylesheet => 'how about a shout-o-matic?' );
my $buffer;
$xps->process( sub{ $buffer .= uc shift } );

is $buffer => 'HOW ABOUT A SHOUT-O-MATIC?', 'override of printform';


test_xml( '<doc><a/><b/><c/></doc>', <<'EOXPS', "only b: <b></b>\n", 'xpath testcode return statement' );
<%
    $t->{doc}{pre} = 'only b: ';	
	$t->{doc}{testcode} = sub{ 'b'; }
%><%= apply_templates() %>
EOXPS


# encoding
#test_xml( '<doc>&#1000;</doc>', '<%= apply_templates() %>', '', 'Encoding' ); 

# testing for proper STDOUT management
{
	my $xps = new XML::XPathScript( xml => '<blah>hello</blah>', stylesheet => '<%= apply_templates()%>' );
	my $output_file = 't/output.xml';
	local *STDOUT;
	die "file $output_file shouldn't be there" if -f $output_file;
	open STDOUT, ">$output_file" or die $!;
	$xps->process;
	close STDOUT;
	open FILE, $output_file or die "$!";
	is <FILE> => '<blah>hello</blah>', 'STDOUT management';
	close FILE;
	unlink $output_file or die $!;
}

# get_xpath_of_node()

{
	my $xps = new XML::XPathScript( xml => '<coucou><bloh><blah /><blah>hello <em>world</em> ! </blah></bloh></coucou>',
									stylesheet => <<'STYLESHEET' );
<%
    $t->{'*'}{pre}="";
    $t->{'text()'}{testcode} = sub {
            my ($self, $t)=@_;
            $t->{pre} = get_xpath_of_node($self)."\n";
            return DO_SELF_ONLY;
    };
%><%= apply_templates() %>
STYLESHEET
	my $result=""; $xps->process(\$result);
	ok($result eq <<'EXPECTED') or warn $result;
/coucou[1]/bloh[1]/blah[2]/text()[1]
/coucou[1]/bloh[1]/blah[2]/em[1]/text()[1]
/coucou[1]/bloh[1]/blah[2]/text()[2]

EXPECTED
}


test_xml( '<rootnode><tag>0</tag></rootnode>', '<%= apply_templates() %>', '<rootnode><tag>0</tag></rootnode>', 'string "0" appears' );

{
my $xps = <<'XPS';
<%
	$t->{foo}{showtag} = 1;
	$t->{foo}{pre} = "before ";
	$t->{foo}{intro} = " post-opening ";
	$t->{foo}{prechildren} = "pre-children ";
	$t->{foo}{postchildren} = " post-children";
	$t->{foo}{extro} = " pre-closing ";
	$t->{foo}{post} = " post-closing";
%><%= apply_templates() %>
XPS

test_xml( '<foo><child/></foo>', $xps, 
	"before <foo> post-opening pre-children <child></child> post-children pre-closing </foo> post-closing\n", 
	'full template with child');

test_xml( '<foo></foo>', $xps, 
	"before <foo> post-opening  pre-closing </foo> post-closing\n", 
	'full template without child');


}

{
close STDERR;
my $errors;
open STDERR, '>', \$errors;

my $exp;
test_xml( '<foo />', '<% my $nothing; print $nothing;  %>', '',
            $exp = 'printing undefs should not trigger a warning' );

is $errors => undef, $exp;

open STDERR, ">&SAVEERR";    # return to normal

}
