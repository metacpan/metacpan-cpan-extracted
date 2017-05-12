##############################################################################
# FormMail                        Version 1.92                               #
# Copyright 1996-2002 Matt Wright mattw@scriptarchive.com                    #
# Created 06/09/95                Last Modified 04/21/02                     #
# Matt's Script Archive, Inc.:    http://www.scriptarchive.com/              #
##############################################################################
# If you run into any problems while trying to configure this scripts, help  #
# is available.  The steps you should take to get the fastest results, are:  #
#       1) Read this file thoroughly.                                        #
#       2) Consult the Matt's Script Archive Frequently Asked Questions:     #
#               http://www.scriptarchive.com/faq/                            #
#       3) If you are still having difficulty installing this script,        #
#          you may wish to look at the resources listed here:                #
#               http://www.scriptarchive.com/help/                           #
#                                                                            #
# Hopefully that will be able to help you solve your problems.  Due to time  #
# constraints I can no longer offer technical support for this code.         #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1995 - 2002 Matthew M. Wright  All Rights Reserved.              #
#                                                                            #
# FormMail may be used and modified free of charge by anyone so long as this #
# copyright notice and the comments above remain intact.  By using this      #
# code you agree to indemnify Matthew M. Wright from any liability that      #
# might arise from its use.                                                  #
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.	In all cases copyright and header must remain intact #
##############################################################################

FormMail is a universal WWW form to E-mail gateway.  There is only one
required form input tag which must be specified in order for this script to
work with your existing forms.  Other hidden configuration fields can also
be used to enhance the operation of FormMail on your site.  The end of this
file has a history that will explain the various changes FormMail has made
throughout its lifetime.  Version 1.91 was an update attempting to get rid
of the worst problems that have been made public in:
        http://www.monkeys.com/anti-spam/formmail-advisory.pdf
Version 1.92 fixed a couple more bugs, which you can read about in the
history located at the end of this file.

The script, FormMail.pl, needs to be placed in your server's cgi-bin and the 
anonymous WWW user must have the ability to read/execute the script.  If 
you do not have access to your server's cgi-bin, yet you can execute cgi 
scripts, you may want to try adding a .cgi extension to the FormMail.pl, 
renaming it to FormMail.cgi. This is probably the more common option.

Setting Up the FormMail Script:
===============================

The FormMail.pl script does not have to be extensively configured in order 
to work.  There are only two variables in the perl file which you will 
need to define along with changing the top line of your script to match 
the location of you Perl interpreter.

Necessary Variables:
--------------------

  $mailprog = '/usr/lib/sendmail -i -t';
    This variable must define the location to your server's sendmail 
    program.  If this is incorrect, form results will not be mailed to you.
    Specifying the parameters in this variable is new in v1.91, and we have
    included the -i parameter so that a single period on a line by itself
    will not end the message. -t instructs sendmail to read the recipient list
    from the message text.

  @referers = ('scriptarchive.com','YOUR_IP');
    This array allows you to define the domains one which you allow forms
    to reside and use this installation of FormMail.  If a user tries to 
    put a form on another server, that is not scriptarchive.com, they 
    will receive an error message when someone tries to fill out their form.
    By placing scriptarchive.com in the @referers array, this also allows
    www.scriptarchive.com, ftp.scriptarchive.com, any other http address
    with scriptarchive.com in it and scriptarchive.com's IP address to access
    this script as well, so no users will be turned away.

    NOTE: This is not a security check. Referer headers can EASILY be faked.
          Rather, it prevents someone on xyznotyou.com from using the FormMail
          on your server to process forms on their server on a regular basis.
          It remains in the script as a remnant of earlier versions when it
          was used for security, but the @recipients variable is now used
          to specify exactly who can receive e-mail from this installation.

    As of version 1.7, the domains listed here are also used as the defaults
    when checking valid recipient e-mail addresses.  You should either
    include all domain names that you wish to have FormMail send e-mails to
    in your @referers array or tailor the @recipients array by hand.

  @valid_ENV = ('REMOTE_HOST','REMOTE_ADDR','REMOTE_USER','HTTP_USER_AGENT');
    This array allows the administrator to specify a list of environment
    variables that the user may request be added into the e-mail.  This is
    a security patch that was advised at http://www.securityfocus.com/bid/1187
    and was implemented by Peter D. Thompson Yezek at 
    http://www.securityfocus.com/archive/1/62033.

    Only environment variables listed in this array may be included in the
    form field env_report.  So if you wanted to also know what URL a user was
    submitting from, you could change @valid_ENV to:
       @valid_ENV = ('REMOTE_HOST','REMOTE_ADDR','REMOTE_USER',
                     'HTTP_USER_AGENT','HTTP_REFERER');
    and then include HTTP_REFERER in your env_report form field.

  @recipients = &fill_recipients(@referers);
    If you wish to only allow e-mail addresses at the domain names in 
    @referers to receive form results, you probably do not need to change this
    variable.  However, if you get any 'Error: Bad/No Recipient' messages when
    running FormMail, you may have to revisit @recipients and make sure you
    have correctly listed all domains or configured this variable.

    @recipients is the most important variable you need to configure.  It is an
    array of regular expressions defining all valid recipients that can be 
    specified.  In order for an e-mail to be sent to the recipient defined in
    a form, the recipient e-mail address must match one of the elements in the
    @recipients array.

    SIMPLE SETUP:

    For the most simple setup, place any domain name that you wish to send
    form results to in the @referers array.  Warning: This allows those domains
    to also access your FormMail script and utilize it to process their own
    forms, but likely this is what you intended anyway.  If so, you can leave:

    @recipients = &fill_recipients(@referers);

    NO, THAT IS NOT WHAT I INTENDED!

    Another alternative, then, is to set @recipients equal to the return value
    of the fill-recipients function and pass this function all of the domains
    to which e-mail may be addressed:

    @recipients = &fill_recipients('domain.com','sub.domain.com','another.com');

    You are now allowing e-mail to any username (provided it contains only A-Z,
    a-z, 0-9, _, - or .) at those three domains.

    Similarly, since @recipients is just an array, you could even do:

    @recipients = (&fill_recipients('domain.com','sub.domain.com'),
                   '^otheruser1@otherhost\.com','^otheruser2@otherhost\.com');

    This would allow any recipient at domain.com and sub.domain.com similar
    to the previous example, but would also allow your friends otheruser1 and
    otheruser2 on otherhost.com to use your FormMail! Of course, you will need
    to add otherhost.com into your @referers array if a form is on their host!

    HOW DOES THAT WORK?

    When the fill_recipients function is called on an array of domain names,
    it turns them into regular expressions. These regular expressions will only
    allow e-mail messages to go to a recipient with an e-mail address in the
    following format:

        [A-Za-z0-9_-\.]+@domain.com

    where domain.com is specified in @referers. For any IP addresses
    in @referers, the following address formats are valid:

        [A-Za-z0-9_-\.]+@[192.168.1.1]

    where 192.168.1.1 is the specified IP address in @referers.

    What this means in english is that the only valid addresses are those
    to usernames that include only letters, numbers, underscores, dashes or 
    periods and an exact domain name or IP address that was specified in the
    @referers array.  Depending on your needs, this may be too broad or not
    broad enough.

    WHAT IF YOU NEED MORE FLEXIBILITY??

    The way FormMail validates a recipient address is to check the supplied
    recipient(s) in the submitted form against each element in the array
    @recipients (which is a list of Perl regular expressions). If any valid
    recipients are found, they will receive a copy of the message.

    Using the examples of @referers = ('domain.com','192.168.1.1'); and the
    default usage of setting @recipients = &fill_recipients(@referers), the
    contents of @recipients are now the same as if you had written:

    @recipients = ('^[\w\-\.]+\@domain\.com', '^[\w\-\.]+\@\[192\.168\.1\.1\]');

    What these regular expressions instruct FormMail to do is require that any
    e-mail address passed in as a recipient of the form submission match at
    least one of those two formats. The following are examples of valid
    and invalid recipients for this exact setup:

       VALID:
         user@domain.com, First.Last@domain.com, Last-First@domain.com
         user_name@domain.com, user023@domain.com, etc.
         user@[192.168.1.1], First.Last@[192.168.1.1], Last-First@[192.168.1.1]
         user_name@[192.168.1.1], user023@[192.168.1.1], etc.

       INVALID: (using these in your form field 'recipient' will trigger error)
         user%name@domain.com, user(name)@domain.com, first:last@domain.com
         <user@domain.com>, <user@other.com>domain.com, user@192.168.1.1
         user@newdomain.com, user@sub.domain.com, user@domainname.com

    Essentially, it only allows A-Z, a-z, 0-9, _, - and . in the local address
    area (before the @, represented as [\w\-\.]+ in regular expression speak)
    and requires the domain name to match exactly. When mailing to an IP 
    address, it must be enclosed in [].

    BUT I NEED TO MATCH MORE CHARACTERS IN THE USERNAME!

    Let's say you need to be able to deliver e-mail to an address like:
        last:first@domain.com

    This requires that the ':' character now be allowed into the portion of
    the recipient field before the domain name.  You could then modify
    @recipients to read:

    @recipients = ('^[\w\-\.\:]+\@domain\.com');

    BUT BE CAREFUL!!!!

    Allowing certain characters could be VERY dangerous, especially if the
    characters are: %, <, >, (, ) or any newlines.  You can read:
        http://web.nps.navy.mil/~miller/percent-hack.html
    for information on exactly why the % character could be dangerous. And
    the document that prompted 1.91 explains why some of the others could
    lead to problems:
        http://www.monkeys.com/anti-spam/formmail-advisory.pdf

    I ONLY WANT CERTAIN ADDRESSES TO WORK!

    Let's say you only want yourself@yourdomain.com to be able to receive
    any form submissions.  You should then set the @recipients array to:

    @recipients = ('^yourself\@yourdomain\.com');

    Now the only valid recipient is that one e-mail address.

    If there are several, simply do:

    @recipients = ('^user1\@yourdomain\.com','^user2\@their\.domain\.com');

    CAN I USE SOMETHING EASIER?

    Prior versions of FormMail recommended settings for @recipients like:

        @recipients = ('domain.com','192.168.1.1');  OR
        @recipients = ('^joe@somewhereelse.com');

    The first is bad because it can be easily tricked by submitting a recipient
    such as spamvictim%elsewhere.com@domain.com.  The second is MUCH better,
    but since it is used as a regular expression, and '.' can mean ANY
    character, a hacker could use joe@somewhereelseXcom to get past a valid
    recipient check. This is not a very big deal in most cases.

    WHAT IS THIS ^ CHARACTER AND WHY SO MANY \'s??

    In regular expressions, the ^ means "beginning of string". By default,
    FormMail places a $ at the end of the match, which means "end of string".
    By using both ^ and $ in regular expression matching, FormMail can match a
    string exactly.  You only need to worry about including the ^, which is
    STRONGLY recommended for all regular expressions in the array.

    The \ character is used to escape a character that otherwise means 
    something special in regular expressions. For instance, you now see every
    '.' being escaped with a '\', as '.' means ANY CHARACTER, whereas '\.'
    requires that it match ONLY a period.

    If you need a regular expression matching solution even more specific than
    the above examples explain, I recommend picking up a book on Perl.

Your FormMail program is now configured.

-----------------------------------------------------------------------------

Form Configuration:
===================

The action of your form needs to point towards this script (obviously), and 
the method must be POST or GET in capital letters.  Version 1.5 of FormMail 
offers many new ways to code your form to tailor the resulting HTML page 
and the way the script performs.  Below is a list of form fields you can 
use and how to implement them.

Necessary Form Fields:
======================

There is only one form field that you must have in your form, for 
FormMail to work correctly.  This is the recipient field.

Field:       recipient

Description: This form field allows you to specify to whom you wish for your
             form results to be mailed.  Most likely you will want to
             configure this option as a hidden form field with a value equal
             to that of your e-mail address. 
             As of version 1.8, You can include multiple recipients by 
             separating the values with commas. 

Syntax:
             <input type=hidden name="recipient" value="email@your.host.com">
             OR  <input type=hidden name="recipient" 
                                value="user@yourhost.com,user2@yourhost.com">

-----------------------------------------------------------------------------

Optional Form Fields:
=====================

Field:       subject

Description: The subject field will allow you to specify the subject that you
             wish to appear in the e-mail that is sent to you after this form
             has been filled out.  If you do not have this option turned on,
             then the script will default to a message subject: WWW Form
             Submission

Syntax:
             If you wish to choose what the subject is:
              <input type=hidden name="subject" value="Your Subject">

             To allow the user to choose a subject:
              <input type=text name="subject">

-----------------------------------------------------------------------------

Field:       email

Description: This form field will allow the user to specify their return
             e-mail address.  If you want to be able to return e-mail to your
             user, I strongly suggest that you include this form field and
             allow them to fill it in.  This will be put into the From:
             field of the message you receive.  If you want to require an
             email address with valid syntax, add this field name to the
             'required' field.

Syntax:
             <input type=text name="email">

-----------------------------------------------------------------------------

Field:       realname

Description: The realname form field will allow the user to input their real
             name.  This field is useful for identification purposes and will
             also be put into the From: line of your message header.

Syntax: 
             <input type=text name="realname">

-----------------------------------------------------------------------------

Field:       redirect

Description: If you wish to redirect the user to a different URL, rather than
             having them see the default response to the fill-out form, you
             can use this hidden variable to send them to a pre-made HTML
             page.

Syntax:
             To choose the URL they will end up at:
               <input type=hidden name="redirect" 
                                  value="http://your.host.com/to/file.html">

             To allow them to specify a URL they wish to travel to once the
             form is filled out:
               <input type=text name="redirect">

-----------------------------------------------------------------------------

Field:       required

Version:     1.3 & Up

Description: You can now require for certain fields in your form to be filled
             in before the user can successfully submit the form.  Simply
             place all field names that you want to be mandatory into this
             field.  If the required fields are not filled in, the user will
             be notified of what they need to fill in, and a link back to
             the form they just submitted will be provided.

             To use a customized error page, see 'missing_fields_redirect'

Syntax:
             If you want to require that they fill in the email and phone
             fields in your form, so that you can reach them once you have
             received the mail, use a syntax like:

               <input type=hidden name="required" value="email,phone">

-----------------------------------------------------------------------------

Field:       env_report

Version:     1.3 & Up

Description: Allows you to have Environment variables included in the
             e-mail message you receive after a user has filled out your
             form.  Useful if you wish to know what browser they were using,
             what domain they were coming from or any other attributes
             associated with environment variables.  The following is a short
             list of valid environment variables that might be useful:

             REMOTE_HOST     - Sends the hostname making a request.
             REMOTE_ADDR     - Sends the IP address of the remote host making
                               the request.
             REMOTE_USER     - If server supports authentication and script
                               is protected, this is the username they have
                               authenticated as. *This is not usually set.*
             HTTP_USER_AGENT - The browser the client is using to send the
                               request.  

             There are others, but these are a few of the most useful.  For
             more information on environment variables, see:

            http://www.cgi-resources.com/Documentation/Environment_Variables/

Syntax:
             If you wanted to find the remote host and browser sending the
             request, you would put the following into your form:

              <input type=hidden name="env_report" value="REMOTE_HOST,
                                                           HTTP_USER_AGENT">

-----------------------------------------------------------------------------

Field:       sort

Version:     1.4 & Up

Description: This field allows you to choose the order in which you wish 
             for your variables to appear in the e-mail that FormMail
             generates.  You can choose to have the field sorted
             alphabetically or specify a set order in which you want the
             fields to appear in your mail message.  By leaving this field
             out, the order will simply default to the order in which the 
             browsers sends the information to the script (which is usually
             the exact same order as they appeared in the form.)  When
             sorting by a set order of fields, you should include the phrase
             "order:" as the first part of your value for the sort field, and
             then follow that with the field names you want to be listed in
             the e-mail message, separated by commas.  Version 1.6 allows a
             little more flexibility in the listing of ordered fields, in
             that you can include spaces and line breaks in the field without
             it messing up the sort.  This is helpful when you have many form
             fields and need to insert a line wrap.

Syntax:
             To sort alphabetically:
               <input type=hidden name="sort" value="alphabetic">

             To sort by a set field order:
               <input type=hidden name="sort" value="order:name1,name2,
                                                   name3,etc...">

-----------------------------------------------------------------------------

Field:       print_config

Version:     1.5 & Up

Description: print_config allows you to specify which of the config 
             variables you would like to have printed in your e-mail message.
             By default, no config fields are printed to your e-mail.  This
             is because the important form fields, like email, subject, etc.
             are included in the header of the message.  However some users
             have asked for this option so they can have these fields printed
             in the body of the message.  The config fields that you wish to
             have printed should be in the value attribute of your input tag
             separated by commas.

Syntax:
             If you want to print the email and subject fields in the body of
             your message, you would place the following form tag:

              <input type=hidden name="print_config" value="email,subject">

-----------------------------------------------------------------------------

Field:       print_blank_fields

Version:     1.6

Description: print_blank_fields allows you to request that all form fields
             are printed in the return HTML, regardless of whether or not
             they were filled in.  FormMail defaults to turning this off, so
             that unused form fields aren't e-mailed.

Syntax:

             If you want to print all blank fields:
              <input type=hidden name="print_blank_fields" value="1">

----------------------------------------------------------------------------

Field:       title

Version:     1.3 & Up

Description: This form field allows you to specify the title and header that
             will appear on the resulting page if you do not specify a
             redirect URL.

Syntax:
             If you wanted a title of 'Feedback Form Results':
              <input type=hidden name="title" value="Feedback Form Results">

-----------------------------------------------------------------------------

Field:       return_link_url

Version:     1.3 & Up

Description: This field allows you to specify a URL that will appear, as
             return_link_title, on the following report page.  This field
             will not be used if you have the redirect field set, but it is
             useful if you allow the user to receive the report on the
             following page, but want to offer them a way to get back to
             your main page.

Syntax:
             <input type=hidden name="return_link_url" 
				             value="http://your.host.com/main.html">

-----------------------------------------------------------------------------

Field:       return_link_title

Version:     1.3 & Up

Description: This is the title that will be used to link the user back to the
             page you specify with return_link_url.  The two fields will be
             shown on the resulting form page as:

             <ul>
              <li><a href="return_link_url">return_link_title</a>
             </ul>

Syntax:
             <input type=hidden name="return_link_title"
                                                  value="Back to Main Page">

-----------------------------------------------------------------------------

Field:       missing_fields_redirect

Version:     1.6

Description: This form field allows you to specify a URL that users will be
             redirected to if there are fields listed in the required form
             field that are not filled in.  This is so you can customize an
             error page instead of displaying the default.

Syntax:
             <input type=hidden name="missing_fields_redirect"
                                    value="http://your.host.com/error.html">

-----------------------------------------------------------------------------

Field:       background

Version:     1.3 & Up

Description: This form field allow you to specify a background image that
             will appear if you do not have the redirect field set.  This
             image will appear as the background to the form results page.

Syntax:
             <input type=hidden name="background"
                                     value="http://your.host.com/image.gif">

-----------------------------------------------------------------------------

Field:       bgcolor

Version:     1.3 & Up

Description: This form field allow you to specify a bgcolor for the form
             results page in much the way you specify a background image.
             This field should not be set if the redirect field is.

Syntax:
             For a background color of White:
              <input type=hidden name="bgcolor" value="#FFFFFF">

-----------------------------------------------------------------------------

Field:       text_color

Version:     1.3 & Up

Description: This field works in the same way as bgcolor, except that it
             will change the color of your text.

Syntax:
             For a text color of Black:
              <input type=hidden name="text_color" value="#000000">

-----------------------------------------------------------------------------

Field:       link_color

Version:     1.3 & Up

Description: Changes the color of links on the resulting page.  Works in the
             same way as text_color.  Should not be defined if redirect is.

Syntax:
             For a link color of Red:
              <input type=hidden name="link_color" value="#FF0000">

-----------------------------------------------------------------------------

Field:       vlink_color

Version:     1.3 & Up

Description: Changes the color of visited links on the resulting page. Works
             exactly the same as link_color.  Should not be set if redirect
             is.

Syntax:
             For a visited link color of Blue:
              <input type=hidden name="vlink_color" value="#0000FF">

-----------------------------------------------------------------------------

Field:       alink_color

Version:     1.4 & Up

Description: Changes the color of active links on the resulting page. Works
             exactly the same as link_color.  Should not be set if redirect
             is.

Syntax:
             For a visited link color of Blue:
              <input type=hidden name="alink_color" value="#0000FF">

-----------------------------------------------------------------------------

Any other form fields that appear in your script will be mailed back to 
you and displayed on the resulting page if you do not have the redirect 
field set.  There is no limit as to how many other form fields you can 
use with this form, except the limits imposed by browsers and your server.

-----------------------------------------------------------------------------

Some of the possible uses of this script are:

1) You want to have a form that will be mailed to you, but aren't sure how to 
   write the CGI script for it.
2) You are the webmaster of your site and want to allow users to use forms, 
   but not to have their own cgi-bin directories, which can cause 
   security risks to your system.  You can set this script up and then 
   allow all users to run off of it.
3) Want to have one script to parse all of your html forms and mail them 
   to you.

-----------------------------------------------------------------------------

History:
Version 1.0     06/11/95  -  This script was created.
Version 1.1     08/03/95  -  A major hole in the script which allowed users 
                             to run commands under your server's uid was 
                             disabled, thanks to Paul Phillips, who noticed
                             the error.
                          -  The ability to redirect the user to a specified
                             HTML file after they filled out a form was 
                             added.
Version 1.2     09/23/95  -  If the form field is one of the required or 
                             optional 'special' fields, such as redirect, 
                             recipient, subject, email, realname, etc... the
                             script will not print these fields to either
                             your mail message or to the user's screen when
                             they are returned to a generic form response.
                             It helps you so that things do not get 
                             duplicated.
Version 1.3     01/21/96  -  Much needed update finally completed
                          -  Added form fields: env_report, bgcolor, 
                             background, link_color, vlink_color, title,
                             text_color, return_link_title, return_link_url 
                             and required.
                          -  Security hole, which allowed any user on any 
                             system to bum off of your FormMail script, has
                             been plugged up with the @referers variable.
                          -  Report style in return html and e-mail touched 
                             up a bit.
Version 1.4     01/23/96  -  Added options: sort, alink_color 
                          -  Fixed a few bugs from Version 1.3, namely the 
                             fact that the link_colors weren't working well.
                          -  FormMail now supports both the GET and POST 
                             methods.
Version 1.5     02/05/96  -  Sorting of Fields in E-Mail Response Fixed.
                          -  print_config option added.
Version 1.6     05/02/97  -  Sorting of fields by default was fixed to now
                             sort in the order the fields are passed to
                             FormMail from the web browser, which is usually
                             the same order as they appear in the HTML form.
                          -  The sort order: directive, env_report and 
                             print_config parsing routines were made to 
                             better compensate for line breaks and extra
                             spaces in input for ease of use.
                          -  Redirect error causing the redirect option to
                             incorrectly work with https (secure servers)
                             was fixed.
                          -  Input of a '0' in a regular form field now
                             recognized as input and sent back to user.
                          -  Output of non-filled in form fields suppressed.
                          -  E-mail addresses checked for correct syntax if
                             designated a required field.
                          -  Fields only printed if they contain a value or
                             if the print_blank_fields option is set to 1.
                          -  missing_fields_redirect added so you can route
                             users who don't completely fill out the form to
                             a pre-made HTML page.
                          -  Parts of code optimized, especially in respect
                             to the way config variables are handled.
Version 1.7     07/27/01  -  Added in @recipients to defeat spamming attempts
                          -  Added in @valid_ENV to allow administrators to
                             specify what environment variables can be sent.
Version 1.8     08/02/01  -  Fixed the recipients code to allow multiple
                             recipients using the 'recipients' form field and
                             commas. Under certain cases in v1.7, spam could
                             still get through by appending a legit recipient
                             to the list of intended spam victims.
                          -  Moved send_email subroutine in front of 
                             return_html as many people reported their web
                             server would kill the FormMail process after the
                             redirect command was issued and no e-mail would
                             be sent.
Version 1.9     08/03/01  -  Added in a further anti-spam check which would
                             take advantage of newline characters in the 
                             subject to send invalid e-mail.
                          -  Removed a restriction when checking e-mail 
                             addresses for validity that required a 2 - 3
                             character domain extension.  With the new TLD's
                             becoming available, it can no longer apply.
Version 1.91    04/19/02  -  The same vulnerability that was patched in 1.9
                             with the subject field still existed in the email
                             and realname fields. Newline characters are no
                             longer allowed in any fields that are placed in
                             the header of the message.
                          -  Much stronger default regular expression checking
                             in the @recipients array is now implemented.  This
                             will combat the % hack and other known exploits.
                          -  The options for sendmail were moved into the
                             $mailprog variable and -i was added so that single
                             periods on a line will not cause the end of the
                             message.
Version 1.92    04/21/02  -  Removed cross-site scripting vulerabilities
                             by converting all <, >, & and " into their HTML
                             equivalents when displayed on a web page. These
                             characters are left intact in the e-mail message.
                          -  Now removes any null bytes from form input.
                          -  Fixed field recognition so that '0' is now a
                             valid input.  Supposedly fixed in v1.6.
                          -  Fixed print_blank_fields
-----------------------------------------------------------------------------
Matt Wright   -   mattw@scriptarchive.com   -   http://www.scriptarchive.com/
