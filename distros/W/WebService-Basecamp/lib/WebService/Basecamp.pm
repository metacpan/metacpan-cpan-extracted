package WebService::Basecamp;

use strict;
use LWP::UserAgent;
use XML::Simple;

our $VERSION = 0.1.4;

=pod

=head1 NAME

WebService::Basecamp - Perl interface to the Basecamp API webservice

=head1 SYNOPSIS

 use WebService::Basecamp;
 
 my $bc = WebService::Basecamp->new( url  => 'http://mysite.clientsection.com',
                                     user => 'username',
                                     pass => 'password'    );

 my $test = $bc->ping || die $bc->error();

 my $projects = $bc->projects;  # a list of all projects


=head1 DESCRIPTION

Basecamp is a web based project collaboration tool that makes it simple to 
communicate and collaborate on projects. Basecamp is built on the Ruby on Rails 
platform but provides a webservice API to many of the application functions. 
WebService::Basecamp is a Perl interface to the Basecamp web service API.

For more information on Basecamp, visit the Basecamp website. 
http://www.basecamphq.com.

This module does much of the heavy lifting for you when accessing the Basecamp 
API. Once initialising a WebService::Basecamp object you can access the API 
function via method calls. The module takes care of the creation and parsing of 
the XML (using XML::Simple) that relays the data across the web service, however 
there is an option to access the XML directly (see new()).

The documentation for this module is based on the Basecamp API docs available at 
http://www.basecamphq.com/api. It is recommended you read the official docs to 
become familiar with the data reference. 

=head1 METHODS

=over 4

=item new(url => $url, user => $username, pass => $password, [ xml => $xml ])

Call new() to create a new Basecamp object. You must pass the url of your 
Basecamp account, a username and password.

 my $bc = WebService::Basecamp->new( url  => 'http://mysite.clientsection.com', 
                                     user => $username, 
                                     pass => $password );

By default, all methods return a data reference. If you would prefer to receive 
the raw XML from the webservice you can pass the 'xml' parameter. E.g.

 my $bc = WebService::Basecamp->new( url  => 'http://mysite.clientsection.com', 
                                     user => $username, 
                                     pass => $password,
                                     xml  => 1 );

=cut

sub new {
    my $class = shift;
    my %hash = @_;
    if (!defined($hash{'url'}) || !defined($hash{'user'}) || !defined($hash{'pass'}) ) {
        die "Must define a url, user and pass to initialise object";
    }
    my $self = {    _burl  => $hash{'url'}, 
                    _buser => $hash{'user'}, 
                    _bpass => $hash{'pass'}, 
                    _xml   => $hash{'xml'} 
                };
    return bless($self, $class);
}

###############################################################
#
# ERROR MESSAGES
#

=pod

=item error()

Returns any error messages as a string.

=cut

sub error {
    return shift->{'_error'};
}

###############################################################
#
# CONNECTION TEST
#

=pod

=item ping()

Tests the connection with the Basecamp web service. Returns 1 for success.

=cut

sub ping {
    my $self    = shift;
    my $result = $self->projects ? 1 : 0;
    return $result;
}

###############################################################
#
# GENERAL QUERIES
#

=pod 

=back

=head2 General Queries

=over 4

=item projects([$key])

This will return a list of all active, on-hold, and archived
projects that you have access to. The list is not ordered.

This method returns a reference to a hash containing an array of file category
names and id.

 use Data::Dumper;
 my $projects = $bc->projects;
 print Dumper($projects);

 returns: 

 $VAR1 = [
          {
            'start-page' => 'all',
            'show-writeboards' => 'false',
            'status' => 'active',
            'name' => 'Create World Peace',
            'created-on' => '2004-05-31',
            'last-changed-on' => '2004-09-07T02:49:12Z',
            'id' => '123456',
            'announcement' => {},
            'show-announcement' => 'false',
            'company' => {
                           'name' => 'Earth',
                           'id' => '888'
                         }
          },
          {
            'start-page' => 'log',
            'show-writeboards' => 'false',
            'status' => 'active',
            'name' => 'Basecamp CPAN Module',
            'created-on' => '2006-07-26',
            'last-changed-on' => '2006-07-29T04:08:34Z',
            'id' => '654321',
            'announcement' => {},
            'show-announcement' => 'false',
            'company' => {
                           'name' => 'Internal',
                           'id' => '555'
                         }
          }
        ];

If you pass the optional $key parameter to the method you will
recieve a keyed hash of the project data. The key must be 
either 'name' or 'id', e.g.:

 use Data::Dumper
 my $projects = $bc->projects('name');
 print Dumper($projects);
 
 returns: 

 $VAR1 = [
          'Create World Peace' => {
                    'start-page' => 'all',
                    'status' => 'active',
                    'show-writeboards' => 'false',
                    'created-on' => '2004-05-31',
                    'last-changed-on' => '2004-09-07T02:49:12Z',
                    'show-announcement' => 'false',
                    'id' => '123456',
                    'announcement' => {},
                    'company' => {
                                   'name' => 'Earth',
                                   'id' => '888'
                                 }
                  },
          'Basecamp CPAN Module' => {
                      'start-page' => 'log',
                      'status' => 'active',
                      'show-writeboards' => 'false',
                      'created-on' => '2006-07-26',
                      'last-changed-on' => '2006-07-29T04:08:34Z',
                      'show-announcement' => 'false',
                      'id' => '654321',
                      'announcement' => {},
                      'company' => {
                                     'name' => 'Internal',
                                     'id' => '555'
                                   }
                    }
        ];

=cut

sub projects {
    my $self        = shift;
    my $key            = shift;
    my @keyoptions = qw(name id);
    return 0 unless $self->_key_val($key,\@keyoptions);
    my $qs            = "/project/list";
    return $self->_perform($qs, 'project', $key);
}

=pod

=item file_categories($project_id [,$key])

This will return an alphabetical list of all file categories in the referenced 
project. Requires the $project_id to be passed as an argument. 

By default this method returns a reference to an array of hashes. If you would 
prefer a keyed hash, you can specify the optional key. The available key options 
are 'name' or 'id'.

=cut

sub file_categories {
    my $self        = shift;
    my $project_id    = shift ||    return $self->_val_error('project');
    my $key            = shift;
    my @keyoptions = qw(name id);
    return 0 unless $self->_key_val($key,\@keyoptions);
    my $qs = '/projects/'.$project_id.'/attachment_categories';
    return $self->_perform($qs, 'attachment-category',$key);
}

=pod

=item message_categories($project_id [,$key])

This will return an alphabetical list of all message categories in the 
referenced project. Requires the $project_id to be passed as an argument. 

By default this method returns a reference to an array of hashes. If you would 
prefer a keyed hash, you can specify the optional key. The available key options 
are 'name' or 'id'.

=cut

sub message_categories {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $key            = shift;
    my @keyoptions = qw(name id);
    return 0 unless $self->_key_val($key,\@keyoptions);
    my $qs = '/projects/'.$project_id.'/post_categories';
    return $self->_perform($qs,'post-category',$key);
}


###############################################################
#
# MESSAGES AND COMMENTS
#

=pod

=back

=head2 Messages and Comments

=over 4

=item comment($comment_id)

Retrieve a specific comment by its id.

=cut

sub comment {
    my $self        = shift;
    my $comment_id    = shift || return $self->_val_error('comment');
    my $qs            = "/msg/comment/$comment_id";
    return $self->_perform($qs);
}

=pod

=item comments($message_id)

Return the list of comments associated with the specified message.

=cut

sub comments {
    my $self        = shift;
    my $message_id    = shift || return $self->_val_error('message');
    my $qs            = "/msg/comments/$message_id";
    return $self->_perform($qs, 'comment');
}

=pod

=item create_comment($message_id, $comment)

Create a new comment, associating it with a specific message. Returns a hash 
containing all of the comment details.

 my $message_id    = 1234;
 my $comment       = "This looks too easy!";
 my $new_comment   = $bc->create_comment($message_id, $comment);

=cut

sub create_comment {
    my $self        = shift;
    my $message_id    = shift || return $self->_val_error('message');
    my $comment        = shift;
    my $qs            = "/msg/create_comment";
    my $xml            = <<XML;
<request>
  <comment>
    <post-id>$message_id</post-id>
    <body>$comment</body>
  </comment>
</request>
XML
    $self->{'_content'} =  $xml;
    return $self->_perform($qs);
}

=pod

=item create_message($project_id, $message)

Creates a new message, optionally sending notifications to a selected list of 
people. The available fields are;

 category_id      - the id of the message category
 title            - message title
 body             - summary text of main message
 extended_body    - the main body of the message
 textile          - optional boolean value. Set to '1' to use Basecamp's 
                    textile formatting for your message. Defaults to '0'.
 private          - optional boolean value. Set to '1' to make this message 
                    visible only to the logged in user. Defaults to '0'.
 notify           - optional list of person ids. Each person in this list will 
                    receive an email notification of the message. 

Returns a hash containing all of the message details.

 my $project_id = 1234;
 my $message    = { category_id   => 654321, 
                    title         => 'New Message Title', 
                    body          => 'This text is a summary of the message', 
                    extended_body => 'This is the main body of the message', 
                    textile       => 1,    # optional field
                    private       => 0,    # optional field
                    notify        => qw(1234 5678) # optional field
                    };
 my $data       = $bc->create_message($project_id,$message);

=cut

sub create_message {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $data        = shift;
    my $qs            = "/projects/$project_id/msg/create";
    my $category_id = int($data->{'category_id'});
	my $milestone_id	= int($data->{'milestone_id'});
    my $title        = $data->{'title'};
    my $body        = $data->{'body'};
    my $extended_body = $data->{'extended_body'};
    my $textile        = defined $data->{'textile'} ? '1' : '0';
    my $private        = defined $data->{'private'} ? '1' : '0';
    my $notify        = $data->{'notify'};
    my $xml            = <<XML;
<request>
  <post>
    <category-id>$category_id</category-id>
    <title>$title</title>
    <body>$body</body>
    <extended-body>$extended_body</extended-body>
    <use-textile>$textile</use-textile>
    <private>$private</private>
XML
	if ($milestone_id) {
		$xml .= "<milestone-id>$milestone_id</milestone-id>\n";
	}
	$xml .= "</post>";
    foreach my $pid (@$notify) {
        $pid = int($pid);
        $xml .= "<notify>$pid</notify>";
    }
    $xml .= "</request>\n";
    
    $self->{'_content'}= $xml;
    return $self->_perform($qs);
}

=pod

=item delete_comment($comment_id)

Delete the comment with the given id.

=cut

sub delete_comment {
    my $self        = shift;
    my $comment_id    = shift || return $self->_val_error('comment');
    my $qs            = "/msg/delete_comment/$comment_id";
    return $self->_perform($qs);
}

=pod

=item delete_message($message_id)

Delete the specified message from the project.

=cut

sub delete_message {
    my $self        = shift;
    my $message_id    = shift || return $self->_val_error('message');
    my $qs            = "/msg/delete/$message_id";
    return $self->_perform($qs);
}

=pod

=item message('$message_id, [$message_id2, $message_id3, ...]')

This will return information about the referenced message. If the id is given as 
a comma-delimited list, one record will be returned for each id. In this way you 
can query a set of messages in a single request. Note that you can only give up 
to 25 ids per request--more than that will return an error.

=cut

sub message {
    my $self        = shift;
    my $message_id    = shift || return $self->_val_error('message');
    my $qs            = "/msg/get/$message_id";
    return $self->_perform($qs);
}

=pod

=item message_archive($project_id)

This will return a summary record for each message in a project. If you specify 
a category_id, only messages in that category will be returned. (Note that a 
summary record includes only a few bits of information about a post, not the 
complete record.)

=cut

sub message_archive {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $category_id    = shift;
    my $qs            = "/projects/$project_id/msg/archive";
    my $xml = "<request><project-id>".int($project_id)."</project-id>";
    $xml .= "<category-id>".int($category_id)."</category-id>" if 
int($category_id);
    $xml .= "</request>\n";
    $self->{'_content'}= $xml;
    return $self->_perform($qs);
}

=pod

=item message_archive_per_category($project_id, $category_id)

This will return a summary record for each message in a particular category. 
(Note that a summary record includes only a few bits of information about a 
post, not the complete record.)

=cut

sub message_archive_per_category {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $category_id    = shift;
    return $self->_val_error('category') unless $category_id;
    my $qs            = "/projects/$project_id/msg/cat/$category_id/archive";
    return $self->_perform($qs);
}

=pod

=item update_comment($comment_id, $comment)

Update a specific comment. This can be used to edit the content of an existing 
comment. Returns a hash containing all of the comment details.

 my $comment_id  = 99999;
 my $comment     = "This looks too easy!!";
 my $new_comment = $bc->update_comment($comment_id, $comment);

=cut

sub update_comment {
    my $self        = shift;
    my $comment_id    = shift || return $self->_val_error('comment');
    my $comment        = shift;
    my $qs            = "/msg/update_comment";
    $self->{'_content'} = 
"<request><comment_id>$comment_id</comment_id><comment><body>$comment</body>
</comment></request>";
    return $self->_perform($qs);
}

=pod

=item update_message($message_id, $message)

Updates an existing message, optionally sending notifications to a selected list 
of people. Available fields are as per the create_message method.

Returns a hash containing all of the message details.

=cut

sub update_message {
    my $self        = shift;
    my $message_id    = shift || return $self->_val_error('message');
    my $data        = shift;
    my $qs            = "/msg/update/$message_id";
    my $category_id = int($data->{'category_id'});
    my $title        = $data->{'title'};
    my $body        = $data->{'body'};
    my $extended_body = $data->{'extended_body'};
    my $textile        = defined $data->{'textile'} ? '1' : '0';
    my $private        = defined $data->{'private'} ? '1' : '0';
    my $notify        = $data->{'notify'};
    my $xml = "<request><post>";
    $xml .= "<category-id>$category_id</category-id>" if $category_id;
    $xml .= "<title>$title</title>" if $title;
    $xml .= "<body>$body</body>" if $body;
    $xml .= "<extended-body>$extended_body</extended-body>" if $extended_body;
    $xml .= "<use-textile>$textile</use-textile>";
    $xml .= "<private>$private</private>";
    $xml .= "</post>";
    foreach my $pid (@$notify) {
        $pid = int($pid);
        $xml .= "<notify>$pid</notify>";
    }
    $xml .= "</request>\n";
    
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}


###############################################################
#
# TO-DO LISTS AND ITEMS
#

=pod

=back

=head2 To-Do Lists and Items

=over 4

=item complete_item($item_id)

Marks the specified item as "complete". If the item is already completed, this 
does nothing.

=cut

sub complete_item {
    my $self        = shift;
    my $item_id        = shift || return $self->_val_error('item');
    my $qs            = "/todos/complete_item/$item_id";
    return $self->_perform($qs);
}

=pod

=item create_item($list_id, $item_data)

This call lets you add an item to an existing list. The item is added to the 
bottom of the list. If a person is responsible for the item, give their id as 
the party_id value. If a company is responsible, prefix their company id with a 
'c' and use that as the party_id value. If the item has a person as the 
responsible party, you can use the notify key to indicate whether an email 
should be sent to that person to tell them about the assignment.

 my $list_id   = 4321;
 my $item_data = { content     => "Turn the lights out",
                   party_id    => 555,
                   notify      => 1 };
 my $new_item  = $bc->create_item($list_id, $item_data);

Returns a hash containing all of the item details.

=cut

sub create_item {
    my $self        = shift;
    my $list_id        = shift;
    return $self->_val_error('list') unless $list_id;
    my $data        = shift;
    my $qs            = "/todos/create_item/$list_id";
    my $content        = $data->{'content'};
    my $party_id    = $data->{'party_id'};
    my $notify        = $data->{'notify'} ? 'true' : 'false';
    my $xml = "<request><content>$content</content>";
    if ($party_id) {
    $xml .= 
"<responsible-party>$party_id</responsible-party><notify>$notify</notify>";
    }
    $xml .= "</request>";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

=pod

=item create_list($project_id, $list_data)

This will create a new, empty list. You can create the list explicitly, or by 
giving it a list template id to base the new list off of. The available fields 
are:

 milestone_id   - optional id of an associated milestone
 private        - optional boolean value. Set to '1' to make this list visible
                  only to the logged in user. Defaults to '0'.
 track          - optional boolean value. Set to '1' to enable time tracking on 
                  items in this list. Defaults to '0';

Basecamp allows you to create list templates for easy creation of common task 
lists. When creating a new list using this method you can provide the id of a 
predefined list template:

 template_id    - id of predefined template

or pass the name and description for the list:

 name           - list title
 description    - optional description of list


 my $project_id = 654321;
 my $list_data  = { milestone_id    => 5436, 
                    private         => 0, 
                    track           => 1,
                    name            => 'Closing up procedures', 
                    };
 my $data       = $bc->create_list($project_id,$list_data);

=cut

sub create_list {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $data        = shift;
    my $qs            = "/projects/$project_id/todos/create_list";
    my $milestone_id = int($data->{'milestone_id'});
    my $private        = $data->{'private'} ? 'true' : 'false';
    my $tracked        = $data->{'track'} ? 'true' : 'false';
    my $name        = $data->{'name'};
    my $description = $data->{'description'};
    my $template_id    = int($data->{'template_id'});
    my $xml            = "<request>";
    $xml .= "<milestone-id>$milestone_id</milestone-id>" if $milestone_id;
    $xml .= "<private>$private</private><tracked>$tracked</tracked>";
    if ($template_id) {
        $xml .= 
"<use-template>true</use-template><template-id>$template_id</template-id
>";
    } else {
        $xml .= "<name>$name</name><description>$description</description>";
    }
    $xml .= "</request>\n";
    $self->{'_content'}= $xml;
    return $self->_perform($qs);
}

=pod

=item delete_item($item_id)

Deletes the specified item, removing it from its parent list.

=cut

sub delete_item {
    my $self        = shift;
    my $item_id     = shift || return $self->_val_error('item');
    my $qs          = "/todos/delete_item/$item_id";
    return $self->_perform($qs);
}

=pod

=item delete_list($list_id)

This call will delete the entire referenced list and all items associated with 
it. Use it with caution, because a deleted list cannot be restored!

=cut

sub delete_list {
    my $self        = shift;
    my $list_id     = shift || return $self->_val_error('list');
    my $qs          = "/todos/delete_list/$list_id";
    return $self->_perform($qs);
}

=pod

=item list($list_id)

This will return the metadata and items for a specific list.

=cut

sub list {
    my $self        = shift;
    my $list_id     = shift || return $self->_val_error('list');
    my $qs          = "/todos/list/$list_id";
    return $self->_perform($qs);
}

=pod

=item lists($project_id, [$filter], [$key])

This will return the metadata for all of the lists in a given project. You can 
further constrain the query to only return those lists that are "complete" (have 
no uncompleted items) or "uncomplete" (have uncompleted items remaining).

To receive only complete lists pass $filter = 'true'
To receive only incomplete lists, pass $filter = 'false'
To receive all lists do not pass $filter

Available keys for this method are 'name' and 'id'. (optional)

=cut

sub lists {
    my $self        = shift;
    my $project_id  = shift || return $self->_val_error('project');
    my $complete    = shift;
    my $key         = shift;
    my @keyoptions = qw(name id);
    return 0 unless $self->_key_val($key,\@keyoptions);
    $self->{'_content'} = "<request><complete>$complete</complete></request>" if $complete;
    my $qs            = "/projects/$project_id/todos/lists";
    return $self->_perform($qs, 'todo-list', $key);
}

=pod

=item move_item($item_id, $position)

Changes the position of an item within its parent list. It does not currently 
support reparenting an item. Position 1 is at the top of the list. Moving an 
item beyond the end of the list puts it at the bottom of the list.

=cut

sub move_item {
    my $self        = shift;
    my $item_id     = shift || return $self->_val_error('item');
    my $position    = shift;
    my $qs          = "/todos/move_item/$item_id";
    $self->{'_content'}= "<request><to>$position</to></request>";
    return $self->_perform($qs);
}

=pod

=item move_list($list_id, $position)

This allows you to reposition a list relative to the other lists in the project. 
A list with position 1 will show up at the top of the page. Moving lists around 
lets you prioritize. Moving a list to a position less than 1, or more than the 
number of lists in a project, will force the position to be between 1 and the 
number of lists (inclusive).

=cut

sub move_list {
    my $self        = shift;
    my $list_id     = shift || return $self->_val_error('list');
    my $position    = shift;
    my $qs          = "/todos/move_list/$list_id";
    $self->{'_content'}= "<request><to>$position</to></request>";
    return $self->_perform($qs);
}

=pod

=item move_list($item_id)

Marks the specified item as "uncomplete". If the item is already uncompleted, 
this does nothing.

=cut

sub uncomplete_item {
    my $self        = shift;
    my $item_id     = shift || return $self->_val_error('item');
    my $qs          = "/todos/uncomplete_item/$item_id";
    return $self->_perform($qs);
}

=pod

=item update_item($item_id, $item_data)

Modifies an existing item. Available fields are as per the create_item method.

=cut

sub update_item {
    my $self        = shift;
    my $item_id     = shift || return $self->_val_error('item');
    my $data        = shift;
    my $qs          = "/todos/update_item/$item_id";
    my $content     = $data->{'comment'};
    my $party_id    = $data->{'party_id'};
    my $notify      = $data->{'notify'} ? 'true' : 'false';
    my $xml = "<request><item><content>$content</content></item>";
    if ($party_id) {
    $xml .= 
"<responsible-party>$party_id</responsible-party><notify>$notify</notify>";
    }
    $xml .= "</request>";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

=pod

=item update_list($list_id, $list_data)

Modifies an the metadata for an existing list. Available fields are as per the 
create_list method, with the exclusion of the template_id.

=cut

sub update_list {
    my $self         = shift;
    my $list_id      = shift || return $self->_val_error('list');
    my $data         = shift;
    my $qs           = "/todos/update_list/$list_id";
    my $milestone_id = int($data->{'category_id'});
    my $private      = $data->{'private'} ? 'true' : 'false';
    my $tracked      = $data->{'track'} ? 'true' : 'false';
    my $name         = $data->{'name'};
    my $description  = $data->{'description'};
    my $template_id  = int($data->{'template_id'});
    my $xml          = "<request><list>";
    $xml .= "<name>$name</name>" if $name;
    $xml .= "<description>$description</description>" if $description;
    $xml .= "<milestone-id>$milestone_id</milestone-id>" if $milestone_id;
    $xml .= "<private>$private</private>" if $private;
    $xml .= "<tracked>$tracked</tracked>" if $tracked;
    $xml .= "</list></request>\n";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

###############################################################
#
# MILESTONES
#

=pod

=back

=head2 Milestones

=over 4

=item complete_milestone($milestone_id)

Marks the specified milestone as complete.

=cut

sub complete_milestone {
    my $self        = shift;
    my $milestone_id = shift || return $self->_val_error('milestone');
    my $qs            = "/milestones/complete/$milestone_id";
    return $self->_perform($qs);
}

=pod

=item create_milestone($project_id, $milestone_data)

Creates a single milestone. If a company is responsible, prefix their company id 
with a 'c' and use that as the party_id value. If the milestone has a person as 
the responsible party, you can use the notify key to indicate whether an email 
should be sent to that person to tell them about the milestone. The available 
fields are:

 title       - Title for the milestone
 deadline    - date the milestone is due to be completed. Must be in the format 
               of YYYYMMDD
 party_id    - id of a person or company responsible for the milestone. If it is 
               a company, prefix the id with a 'c', e.g. 'c123' 
 notify      - optional boolean value. Set to '1' to send an email about the     
               milestone to the responsible party.

 my $project_id     = 654321;
 my $milestone_data = { title       => 'Launch Party',
                        deadline    => '20060828',
                        party_id    => 555,
                        notify      => 1 };
 my $new_milestone  = $bc->create_milestone($project_id, $milestone_data);

Returns a hash containing all of the milestone details.

=cut

sub create_milestone {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $data        = shift;
    my $qs            = "/projects/$project_id/milestones/create";
    my $title        = $data->{'title'};
    my $deadline    = $data->{'deadline'};
    my $party_id    = $data->{'party_id'};
    my $notify        = $data->{'notify'} ? 'true' : 'false';
    my $xml            = <<XML;
<request>
  <milestone>
    <title>$title</title>
    <deadline type="date">$deadline</deadline>
    <responsible-party>$party_id</responsible-party>
    <notify>$notify</notify>
  </milestone>
</request>
XML
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

=pod

=item delete_milestone($milestone_id)

Deletes the given milestone from the project.

=cut

sub delete_milestone {
    my $self        = shift;
    my $milestone_id = shift || return $self->_val_error('milestone');
    my $qs            = "/milestones/delete/$milestone_id";
    return $self->_perform($qs);
}

=pod

=item list_milestones($project_id, [$filter])

This lets you query the list of milestones for a project. You can either return 
all milestones, or only those that are late, completed, or upcoming.

To receive only complete milestones pass $filter = 'complete'
To receive only upcoming milesones, pass $filter = 'upcoming'
To receive only late milesones, pass $filter = 'late'
To receive all milestones do not pass $filter

=cut

sub list_milestones {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $filter        = shift || 'all';
    $self->{'_content'} = "<request><find>$filter</find></request>";
    my $qs            = "/projects/$project_id/milestones/list";
    return $self->_perform($qs);
}

=pod

=item uncomplete_milestone($milestone_id)

Marks the specified milestone as uncomplete.

=cut

sub uncomplete_milestone {
    my $self        = shift;
    my $milestone_id = shift || return $self->_val_error('milestone');
    my $qs            = "/milestones/uncomplete/$milestone_id";
    return $self->_perform($qs);
}

=pod

=item update_milestone($milestone_id, $milestone_data)

Modifies a single milestone. You can use this to shift the deadline of a single 
milestone, and optionally shift the deadlines of subsequent milestones as well. 
The available fields are as per the create_milestone() method with the addition 
of two extra fields:

 move_upcoming    - optional boolean value. Set to '1' to move subsequent         
                    milestone deadlines whne updating the deadline for this 
                    milestone
 move_weekends    - optional boolean value. If using the 'move_upcoming' 
                    parameter, you can set this value to '1' to make sure that any 
                    subsequent milestone deadlines do not get moved to a Saturday 
                    or Sunday.

 my $milestone_id   = 98765;
 my $milestone_data = {     title            => 'Launch Party',
                            deadline         => '20061028',
                            party_id         => 555,
                            notify           => 1,
                            move_upcoming    => 1,
                            move_weekends    => 1 };
 my $new_milestone  = $bc->update_milestone($milestone_id, $milestone_data);

Returns a hash containing all of the milestone details.

=cut

sub update_milestone {
    my $self        = shift;
    my $milestone_id = shift || return $self->_val_error('milestone');
    my $data        = shift;
    my $qs            = "/milestones/update/$milestone_id}";
    my $title        = $data->{'title'};
    my $deadline    = $data->{'deadline'};
    my $party_id    = $data->{'party_id'};
    my $notify        = $data->{'notify'} ? 'true' : 'false';
    my $upcoming    = $data->{'move_upcoming'} ? 'true' : 'false';
    my $weekends    = $data->{'move_weekends'} ? 'true' : 'false';
    my $xml            = "<request><milestone>";
    $xml .= "<title>$title</title>" if $title;
    $xml .= "<deadline>$deadline</deadline>" if $deadline;
    $xml .= "<responsible-party>$party_id</responsible-party>" if $party_id;
    $xml .= "<notify>$notify</notify></milestone>";
    $xml .= "<move-upcoming-milestones>$upcoming</move-upcoming-milestones>" if 
$upcoming;
    $xml .= "<move-upcoming-milestones-off-weekends>" . 
"$weekends</move-upcoming-milestones-off-weekends>" if $weekends;
    $xml .= "</request>";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

###############################################################
#
# TIME TRACKING
#

=pod

=back

=head2 Time Tracking

=over 4

=item create_time($data)

With this method you can create a new time entry for a particular person and 
project. The available fields are:

 project_id  - id for the project associated with the task
 person_id   - id of the person who completed the work
 date        - date the work took place. Date format = YYYYMMDD, e.g. 20060801 
 hours       - time worked, in hours

If the task being time tracked is an existing item from a to do list, you can 
pass the item_id:

 item_id     - id of an existing to do list item

or you can provide a description of the task

 description - txt description of the task

 my $project_id = 654321;
 my $person_id  = 555;
 my $data       = { project_id  => $project_id,
                    person_id   => $person_id,
                    date        => '20060801',
                    hours       => '1.25',
                    description => 'Meeting with world leaders' };
 my $new_time   = $bc->create_time($data);


=cut

sub create_time {
    my $self        = shift;
    my $data        = shift;
    my $qs            = "/time/save_entry";
    my $project_id    = $data->{'project_id'};
    my $person_id    = $data->{'person_id'};
    my $date        = $data->{'date'};
    my $hours        = $data->{'hours'};
    my $item_id        = $data->{'item_id'};
    my $description    = $data->{'description'};
    my $xml            = <<XML;
<request>
  <entry>
    <project-id>$project_id</project-id>
    <person-id>$person_id</person-id>
    <date>$date</date>
    <hours>$hours</hours>
XML
    if ($item_id) {
        $xml .= "<todo-item-id>$item_id</todo-item-id>";
    } else {
        $xml .= "<description>$description</description>";
    }
    $xml .= "</entry></request>";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

=pod

=item delete_time($project_id, $time_id)

Deletes the identified time entry.

=cut

sub delete_time {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $time_id        = shift || return $self->_val_error('time');
    my $qs            = "/projects/$project_id/time/delete_entry/$time_id";
    return $self->_perform($qs);
}

=pod

=item report_time($person_id, $from, $to, [$filter])

This method lets you query the time entries in a variety of ways. If you do not 
want to query by $person_id, put a 0 in that position. Likewise for $from and 
$to (to use default from/to values). In no case can you query more than 90 days' 
worth of data. The $filter parameter can be blank, or an id number prefixed by a 
'p' (to filter by a specific project) or 'c' (to filter by a specific company).

 my $report = $bc->report_time(5,'20060101','20060207','c7');
    
 - would return all time entries for the person with id 5, for all projects 
 associated with the company with id 7, between the dates 2006-01-01 and 
 2006-02-07 (inclusive).

Date values passed for $from and $to must be in the format of YYYYMMDD

=cut

sub report_time {
    my $self        = shift;
    my $person_id    = shift || '0';
    my $from        = shift || '0';
    my $to            = shift || '0';
    my $filter        = shift;
    my $qs            = "/time/report/$person_id/$from/$to/$filter";
    return $self->_perform($qs);
}

=pod

=item update_time($time_id, $data)

With this method you can modify a specific time entry. The available fields are 
as per the create_time() method.

=cut

sub update_time {
    my $self        = shift;
    my $time_id        = shift || return $self->_val_error('time');
    my $data        = shift;
    my $qs            = "/time/save_entry/$time_id";
    my $project_id    = $data->{'project_id'};
    my $person_id    = $data->{'person_id'};
    my $date        = $data->{'date'};
    my $hours        = $data->{'hours'};
    my $item_id        = $data->{'item_id'};
    my $description    = $data->{'description'};
    my $xml            = "<request><entry>";
    $xml .= "<project-id>$project_id</project-id>" if $project_id;
    $xml .= "<person-id>$person_id</person-id>" if $person_id;
    $xml .= "<date>$date</date>" if $date;
    $xml .= "<hours>$hours</hours>" if $hours;
    $xml .= "<todo-item-id>$item_id</todo-item-id>" if $item_id;
    $xml .= "<description>$description</description>" if $description;
    $xml .= "</entry></request>";
    $self->{'_content'} = $xml;
    return $self->_perform($qs);
}

###############################################################
#
# CONTACT MANAGEMENT
#

=pod

=back

=head2 Contact Management

=over 4

=item companies()

Returns a list of all companies visible to the given person. This is only 
accessible to employees of the "firm" (the company assoicated with the account). 
Client employees will get a 403 response if they attempt to access this method.

=cut

sub companies {
    my $self        = shift;
    my $qs            = "/contacts/companies";
    return $self->_perform($qs);
}

=pod

=item company($company_id)

This will return the information for the referenced company.

=cut

sub company {
    my $self        = shift;
    my $company_id    = shift || return $self->_val_error('company');
    my $qs            = "/contacts/company/$company_id";
    return $self->_perform($qs);
}

=pod

=item people($company_id)

This will return all of the people in the given company.

=cut

sub people {
    my $self        = shift;
    my $company_id    = shift || return $self->_val_error('company');
    my $qs            = "/contacts/people/$company_id";
    return $self->_perform($qs);
}

=pod

=item people_per_project($project_id, $company_id)

This will return all of the people in the given company that can access the 
given project.

=cut

sub people_per_project {
    my $self        = shift;
    my $project_id    = shift || return $self->_val_error('project');
    my $company_id    = shift || return $self->_val_error('company');
    my $qs            = "/projects/$project_id/contacts/people/$company_id";
    return $self->_perform($qs);
}

=pod

=item person($person_id)

This will return information about the referenced person.

=cut

sub person {
    my $self        = shift;
    my $person_id    = shift || return $self->_val_error('person');
    my $qs            = "/contacts/person/$person_id";
    return $self->_perform($qs);
}

###############################################################
#
# PRIVATE METHODS
#

sub _perform {
    my $self    = shift;
    my $qs        = shift;
    my $list    = shift;
    my $key        = shift;
    my $url        = $self->{'_burl'}.$qs;
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(POST => $url);
    $req->header('Accept' => 'application/xml');
    $req->content_type('application/xml');
    $req->authorization_basic($self->{'_buser'}, $self->{'_bpass'});
	$req->content_length(length($self->{'_content'}));
    $req->content($self->{'_content'});
    my $body = $ua->request($req);
    my $data = {};
    if ($body->is_success) {
        return $body->content if $self->{'_xml'};
        $data = XMLin($body->content, keyattr => [$key], NoAttr => 1, NormaliseSpace => 2);
        if (!$key && $list) {
            if (ref $data->{$list} eq 'ARRAY') {
				return \@{$data->{$list}};
            } else {
                return [$data->{$list}];
            }        
		} elsif ($key && $list) {
            return $data->{$list};
        } else {
            return $data;
        }
    } else {
        $self->{'_error'} = $body->status_line;
        return 0;
    }
    return 0;
}

sub _val_error {
    my $self = shift;
    my $id     = shift;
    $self->{'_error'} = "Must provide a $id id";
    return 0;
}

sub _key_val {
    my $self    = shift;
    my $key        = shift;
    my $options = shift;
    return 1 if (!$key);
    foreach my $opt (@$options) {
        return 1 if ($key eq $opt);
    }
    my $option = join('|',@$options);
    $self->{'_error'} = "Invalid key ($key). Options: [$option]";
    return 0;
}

=pod

=back

=head1 TODO

This module does not currently support all of the Basecamp API functions. In 
particular, the following methods need to be added:

=over 4

=item

File uploads

=item

Attaching files to messages

=item

batch creation of milestones

=back

Add more tests

=head1 BUGS

This is alpha software and as such, the features and interface
are subject to change.  So please check the Changes file when upgrading.


=head1 SEE ALSO

L<http://www.basecamphq.com/api>, L<XML::Simple>


=head1 AUTHOR

David Baxter <david@sitesuite.com.au>

=head1 CREDITS

Thanks to SiteSuite (http://www.sitesuite.com.au) for funding the 
development of this plugin and for releasing it to the world.

Thanks to Patrick Mulvaney for contributions to this module.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE 
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE 
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE 
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND 
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, 
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY 
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE 
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, 
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT 
OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS 
OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD 
PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN 
IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGES.

=cut

1;
