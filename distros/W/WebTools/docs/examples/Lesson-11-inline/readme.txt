~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                              Inline example 				   		!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

What is template?
-----------------

[Definition]: Template is small or big piece of data that could be replaced with dynamic data.

      Well is that sound familar to you? 
 In lesson 8 we pass over templates and xreader. Now I want to demonstrate build-in capability
of WebTools and xreader in templates. Here you can find how simple could be writting of 
perl code that process templates and even SQL templates. Let's get started!

  What is 'INLINE' mean?
 First of all INLINE mean freedom to write templates and secondary comfort!
 
 Let see follow simple example to understand what I'm talking about!

<HTML>
<?perl
 require 'xreader.pl';
 $dbh = sql_connect();
 xreader_dbh($dbh);
 $data = xreader(1,'xread/xr.jhtml',200,'July');
 print $data;
?>
</HTML>

That was trivial way (shown in Lesson 8), but we can economize some minutes with follow code:

<HTML>
<!--©INLINE©><XREADER:1:xread/xr.jhtml:200,July></©INLINE©-->
</HTML>

or even using scalar variables!:

<HTML>
<?perl
  my $width = 200;
  my $text = 'July';
?>
<!--©INLINE©><XREADER:1:xread/xr.jhtml:$width,$text></©INLINE©-->
</HTML>

I hope you have aleady interested of this unique feature? Let complicate example:

What could you say about this ???

<HTML>
<?perl
  $mytable = 'webtools_users';
  <!--©INPERL©><S©L:1:"select USER,ID from $mytable where id=0;":1:1:1:1:S©L></©INPERL©-->
  print $_;            # Result of previous (NOTE) inPERL template is saved in $_ variable!
?>
</HTML>

When I wrote this I sad "WOW" :-)))

Next example will be the top of icecreem:

<HTML>
<?perl
  $mytable = 'webtools_users';
  @DB_VALUES = ("Y","N","-");
  @TEMPLATE_NUMBERS = (1,2,3);
  @HTML_VALUES = ("checked","");
  $ref1=\@DB_VALUES;
  $ref2=\@TEMPLATE_NUMBERS;
  $ref3=\@HTML_VALUES;
  $sqlq = "!N";
  $SOURCE  = '<input type="radio" name="Male" value="Y" <§TEMPLATE:1§>>Yes<br>';
  $SOURCE .= '<input type="radio" name="Male" value="N" <§TEMPLATE:2§>>No';
  $SOURCE .= '<input type="radio" name="Male" value="-" <§TEMPLATE:3§>>Unknown :-)';
?>
User: "<!--©INLINE©><S©L:1:"select USER,ID from $mytable where id=0;":1:1:1:1:S©L></©INLINE©-->"<BR>
"<!--©INLINE©><S©LVAR:1:S©L></©INLINE©-->" has ID: <!--©INLINE©><S©L:2:"":1:1:2:1:S©L></©INLINE©--><BR>
Also see follow checkboxes!<BR>
<!--©INLINE©><MENUSELECT:$SOURCE:$sqlq:$ref1:$ref2:$ref3:$dbh:></©INLINE©-->
</HTML>

Please note that $sqlq could be normal SQL query that fetch current state of check/select
and so on...tag. In our case we use saved in memmory state of check/select! To use 
memmory style however you need to shift "!" at entry of variable.

Code above show how possitive can be INLINE and INPERL feature of WebTools, however TEMPLATES
continue to be hard part of Web programming.

At the end I would like to reference your attention to complete template's documentation at docs/templates/index.html !
Enjoy!


*******************************
 Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com