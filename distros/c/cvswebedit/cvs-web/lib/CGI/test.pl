#!/usr/local/bin/perl

push(@INC,'..');
require CGI::Form;

$query = new CGI::Form;
print $query->header;
&print_head;
&print_prompt($query);
&do_work($query);
&print_tail;

sub print_head {
    print <<END;
<HTML><HEAD>
<TITLE>Example CGI::Form</TITLE>
</HEAD><BODY>
<H1>Example CGI::Form</H1>
END
}

sub print_prompt {
    local($query) = @_;

    print $query->startform;
    print "<EM>What's your name?</EM><BR>";
    print $query->textfield('name');
    print $query->checkbox('Not my real name');

    print "<P><EM>Where can you find English Sparrows?</EM><BR>";
    print $BLANK;
    print $query->checkbox_group('Sparrow locations',
				 [England,France,Spain,Asia,Hoboken],
				 [England,Asia]);

    print "<P><EM>How far can they fly?</EM><BR>",
           $query->radio_group('how far',
			       ['10 ft','1 mile','10 miles','real far'],
			       '1 mile');

    print "<P><EM>What's your favorite color?</EM>  ";
    print $query->popup_menu('Color',['black','brown','red','yellow'],'red');

    print $query->hidden('Reference','Monty Python and the Holy Grail');

    print "<P><EM>What have you got there?</EM>  ";
    print $query->scrolling_list('possessions',
				 ['A Coconut','A Grail','An Icon',
				  'A Sword','A Ticket'],
				 undef,
				 10,
				 'true');

    print "<P><EM>Any parting comments?</EM><BR>";
    print $query->textarea('Comments',undef,10,50);

    print "<P>",$query->reset;
    print $query->defaults;
    print $query->submit('Action','Shout');
    print $query->submit('Action','Scream');
    print $query->endform;
    print "<HR>\n";
}

sub do_work {
    local($query) = @_;
    local(@values,$key);
    print "<H2>Here are the current settings in this form</H2>";
    foreach $key ($query->param) {
	print "<STRONG>$key</STRONG> -> ";
	@values = $query->param($key);
	print join(", ",@values),"<BR>\n";
    }
}

sub print_tail {
    print <<END;
<HR>
<ADDRESS>Lincoln D. Stein</ADDRESS><BR>
<A HREF="/">Home Page</A>
END
}
#######################################################################


