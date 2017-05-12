WWW::Mailgun
===================
#### Perl wrapper for Mailgun (http://mailgun.org)

### SYNOPSIS

    use Mailgun;


### DESCRIPTION

Mailgun is a email service which provides email over a http restful API.
These bindings goal is to create a perl interface which allows you to
easily leverage it.

    use WWW::Mailgun;

    my $mg = WWW::Mailgun->new({ 
        key => 'key-yOuRapiKeY',
        domain => 'YourDomain.mailgun.org',
        from => 'elb0w <elb0w@YourDomain.mailgun.org>' # Optionally set here, you can set it when you send
    });
   
    # Get stats http://documentation.mailgun.net/api-stats.html
    my $obj = $mg->stats; 

    # Get logs http://documentation.mailgun.net/api-logs.html
    my $obj = $mg->logs; 

    

### USAGE

#### new({key => 'mailgun key', domain => 'your mailgun domain', from => 'optional from')

Creates your mailgun object

from => the only optional field, it can be set in the message.



#### send($data)

Send takes in a hash of settings
Takes all specificed here http://documentation.mailgun.net/api-sending.html
'from' is optionally set here, otherwise you can set it in the constructor and it can be used for everything

##### Send a HTML message with an attachment using a filename
    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          html => '<html><h3>hello</h3><strong>world</strong></html>',
          attachment => ['/Users/elb0w/GIT/Personal/Mailgun/test.pl']
    });

##### Send a HTML message with an attachment using raw data
    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          html => '<html><h3>hello</h3><strong>world</strong></html>',
          attachment => [ undef, 'something.txt', 'Hello from inside the file' ],
    });

#### Send a HTML message with multiple attachments
    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          html => '<html><h3>hello</h3><strong>world</strong></html>',
          attachments => [
                [ '/Users/elb0w/GIT/Personal/Mailgun/test.pl' ],
                [ undef, 'something.txt', 'Hello from inside the file' ],
          ],
    });

##### Send a text message
    $mg->send({
          to => 'some_email@gmail.com',
          subject => 'hello',
          text => 'Hello there',
    });

##### Send a MIME multipart message
    $mg->send({
          to      => 'some_email@gmail.com',
          subject => 'hello',
          text    => 'Hello there',
          html    => '<b>Hello there</b>'
    });

#### unsubscribes, bounces, spam

Helper methods all take a method argument (del, post, get)
#http://documentation.mailgun.net/api_reference.html
Post optionally takes a hash of properties

##### Unsubscribes
    
    # View all unsubscribes http://documentation.mailgun.net/api-unsubscribes.html
    my $all = $mg->unsubscribes; 

    # Unsubscribe user from all 
    $mg->unsubscribes('post',{address => 'user@website.com', tag => '*'});

    # Delete a user from unsubscriptions
    $mg->unsubscribes('del','user@website.com');

    # Get a user from unsubscriptions
    $mg->unsubscribes('get','user@website.com');

    
##### Complaints
    
    # View all spam complaints http://documentation.mailgun.net/api-complaints.html
    my $all = $mg->complaints; 

    # Add a spam complaint for a address
    $mg->complaints('post',{address => 'user@website.com'});

    # Remove a complaint
    $mg->complaints('del','user@website.com');

    # Get a complaint for a adress
    $mg->complaints('get','user@website.com');

##### Bounces

    # View the list of bounces http://documentation.mailgun.net/api-bounces.html
    my $all = $mg->bounces; 

    # Add a permanent bounce
    $mg->bounces('post',{
        address => 'user@website.com',
        code => 550, #This is default
        error => 'Error Description' #Empty by default
    });

    # Remove a bounce
    $mg->bounces('del','user@website.com');

    # Get a bounce for a specific address
    $mg->bounces('get','user@website.com');

#### TODO

Mailboxes
Campaigns
Mailing Lists
Routes

--Add Moose version

#### Author

George Tsafas <elb0w@elbowrage.com>


#### Support

elb0w on irc.freenode.net #perl


#### Resources

http://documentation.mailgun.net/


