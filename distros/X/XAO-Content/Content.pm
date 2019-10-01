=head1 NAME

XAO::DO::Web::Content -- Dynamic content management for XAO::Web

=head1 SYNOPSIS

 <%Content name="about_us"%>

=head1 DESCRIPTION

B<Obsolete! Do not use in new development.>

For installation and usage instruction see "INSTALLATION AND USAGE"
chapter below.

Content object allows to embed editable content stored in a database
into a web page or any other part of a system based on XAO::Web. There
are virtually no limitations as to how content can be used.

For instance the text on "News" page of the site might be a Content
element. In that case site administrator would not need to modify any
templates, but can edit, preview and publish news using web interface
only.

Another example could be storing complete product description template
as a Content object. In that case modifying all product pages at once
would be controlled by modifying just one template over the web in
content editor.

A content element is identified by a name that has the same set of
restrictions as a XAO::FS ID - up to 30 characters, alpha-numeric and
underscore characters only.

Every bit of content has multiple values associated with it arranged
by date of their modification. Most current version of content can be
in one of two states - published and unpublished. If it is unpublished
then it can only be seen if the special preview mode is turned on. That
gives an ability to a site administrator to preview changes and probably
make corrections before making these changes available for regular site
visitors.

A configuration for Content objects can be provided as a part of site
configuration. Its URI is '/content' and parameters are:

 list_uri    => uri of content storage in the XAO FS, defaults
                to '/Content'

 cache_time  => for how long to keep retrieved content in memory cache,
                default is 5 minutes

 cache_size  => the size of memory cache in KB, default is 1024

 flag_cb_uri => location of a flag in clipboard that indicates whether
                or not the preview mode is on

=head1 INSTALLATION AND USE

The easiest way to install XAO Content is to use CPAN. Usually you would
need to do something like this:

 sudo perl -MCPAN -e'install XAO::DO::Web::Content'

If you downloaded archive and want to install it manually then usual
four commands will do:

 perl Makefile.PL
 make
 make test
 sudo make install

During execution of Makefile.PL you will be asked for a test database
DSN, username and password. If you want to skip the tests enter 'none'
for DSN or otherwise give it any disposable database DSN. In most cases
OS:MySQL_DBI:test will do. B<Note:> That database content will be
completely destroyed after tests.

Once installed the XAO Content is ready to be used. There are two
scenarios to start using it -- if you already have a site where you want
to add dynamic content functionality and if you do not have a site and
want to just see XAO Content in action.

=head2 TEST SITE TO SEE XAO CONTENT IN ACTION

Here are the steps you need to follow to get a simple working site that
uses XAO Content:

=over

=item 1

Sym-link or recursively copy the 'sample' directory from the XAO Content
distribution to your 'projects' directory in XAO installation path
(usually /usr/local/xao/projects). The name you use for sym-linking is
the name of your site -- /usr/local/xao/projects/content would mean
'content' as the site name.

=item 2

Create an empty MySQL database for your site (providing MySQL
username/password if required). Inour example we use 'content' as the
database name.

 mysqladmin create content

=item 3

Create empty XAO::FS database on top of MySQL database:

 xao-fs --dsn=OS:MySQL_DBI:content init

=item 4

Go to /usr/local/xao/projects/content and run configure script:

 cd /usr/local/xao/projects/content
 perl ./configure.pl

Enter OS:MySQL_DBI:content as the database DSN and username/password of
a user that has full access to that database.

=item 5

Create database layout required by XAO Content:

 ./bin/build-structure

=item 6

Configure a virtual server in your Apache config:

 <VirtualHost SOME_HOST_NAME>
   ServerName SOME_HOST_NAME

   <Directory /usr/local/xao/handlers>
     Options ExecCGI
     SetHandler cgi-script
   </Directory>

   RewriteEngine on
   RewriteRule   ^/(.*)$  \
                 /usr/local/xao/handlers/xao-apache.pl/content/$1  \
                 [L]
 </VirtualHost>

Here you replace SOME_HOST_NAME with a something that you have in your
DNS or at least in /etc/hosts file. At the last line of RewriteRule the
last part of the path is the site name that you used -- you need to
change it if you used a different name.

=item 7

Done! Restart Apache and go to SOME_HOST_NAME in your browser to see how
content management works.

=back

=head2 INTEGRATING XAO CONTENT INTO AN EXISTING SITE

To integrate XAO Content into an existing site you shoul follow these
steps (depending on your site setup not all of them might be
applicable):

=over

=item 1

Copy content*.html files from sample/templates/admin/ to your site's
admin directory and modify them to your taste. In general you should
make sure that an administrator is logged in before he/she has access to
the content editor.

=item 2

Edit your Config.pm (or Config.pm.proto if you use prototypes) and add
the following code to your build_structure() method:

 my $cobj=XAO::Objects->new(objname => 'Web::Content');
 $cobj->build_structure;

=item 3

Re-build your data structure using bin/build-structure script or any
other tools that you use.

=item 4

Optionally copy files from sample/bits/content/*, sample/bits/hint-link
and sample/hints/* to your site and modify them appropriately. The idea
of these files is to show how you can customize default templates used
by content editor and to provide useful "Hints" functionality.

=item 5

In your header file that you include in all you pages (if you have one)
add a call to /bits/content/set-preview. That template displays nothing,
but sets preview mode to support content editor.

=item 6

Look into various files in sample/templates for ideas and sample code.

=back

=head1 METHODS

Content is based in Web::Action object and such depends on 'mode'
argument, with the default mode being 'show'.

All methods if not stated otherwise support the following set of
arguments that defines which content object to use:

 name       => Name of content
 data_id    => ID of a specific version (optional, rarely used)
 preview    => if non-zero then unpublished version of content will
               be used. If that argument is not present then the
               clipboard preview flag is used (see flag_cb_uri above)

The following list of methods also shows 'mode' as the first element
(order alphabetically).

=over

=cut

###############################################################################
package XAO::DO::Web::Content;
use strict;
use Error qw(:try);
use XAO::Utils;
use XAO::Objects;

use vars qw($VERSION);
$VERSION='1.06';

use base XAO::Objects->load(objname => 'Web::FS');

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'content-data';

    if($mode eq 'content-add') {
        $self->content_add($args);
    }
    elsif($mode eq 'content-data') {
        $self->content_data($args);
    }
    elsif($mode eq 'content-if-preview') {
        $self->content_if_preview($args);
    }
    elsif($mode eq 'content-publish') {
        $self->content_publish($args);
    }
    elsif($mode eq 'content-publish-all') {
        $self->content_publish_all($args);
    }
    elsif($mode eq 'content-revert') {
        $self->content_revert($args);
    }
    elsif($mode eq 'content-revert-all') {
        $self->content_revert_all($args);
    }
    elsif($mode eq 'content-set-preview') {
        $self->content_set_preview($args);
    }
    elsif($mode eq 'content-show') {
        $self->content_show($args);
    }
    elsif($mode eq 'content-show-dates') {
        $self->content_show_dates($args);
    }
    elsif($mode eq 'content-store') {
        $self->content_store($args);
    }
    else {
        my $config=$self->siteconfig('/content');

        $self->SUPER::check_mode(merge_refs({
            'base.database'     => $config->{list_uri} || '/Content',
            'uri'               => $args->{name},
        }, $args));
    }
}

###############################################################################

=item 'content-add' => content_add (%)

Displays a form for creating new content and when the form is filled --
creates that content accordingly.

Arguments are:

 form.path      => path to form template
 success.path   => path to success template

=cut

sub content_add ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $list_uri=$config->{list_uri} || '/Content';
    my $content_list=$self->odb->fetch($list_uri);

    my @fields=(
        {   name        => 'name',
            style       => 'text',
            required    => 1,
            minlength   => 3,
            maxlength   => 30,
            param       => 'NAME',
            text        => 'Name',
        },
        {   name        => 'description',
            style       => 'text',
            required    => 1,
            maxlength   => 100,
            param       => 'DESCRIPTION',
            text        => 'Description',
        },
        {   name        => 'instruction',
            style       => 'text',
            required    => 0,
            maxlength   => 1000,
            param       => 'INSTRUCTION',
            text        => 'Instruction',
        },
        {   name        => 'preview_url',
            style       => 'text',
            required    => 0,
            maxlength   => 200,
            param       => 'PREVIEW_URL',
            text        => 'Preview URL',
        },
        {   name        => 'comment',
            style       => 'text',
            required    => 0,
            maxlength   => 100,
            param       => 'COMMENT',
            text        => 'Initial Comment',
        },
        {   name        => 'text',
            style       => 'text',
            required    => 0,
            maxlength   => 100000,
            param       => 'TEXT',
            text        => 'Initial Text',
        },
        {   name        => 'mime_type',
            style       => 'text',
            required    => 0,
            maxlength   => 50,
            param       => 'MIME_TYPE',
            text        => 'Initial MIME Type',
        },
    );

    my $form=XAO::Objects->new(objname => 'Web::FilloutForm');

    $form->setup(
        fields => \@fields,
        check_form => sub {
            my $fo=shift;

            my $name=$fo->field_desc('name')->{value};
            $content_list->check_name($name) ||
                return ('Wrong content name','name');
            $content_list->exists($name) &&
                return ('That name is already in use','name');

            return '';
        },
        form_ok => sub {
            my $fo=shift;

            my $nc=$content_list->get_new();
            $nc->put(description => $fo->field_desc('description')->{value});
            $nc->put(instruction => $fo->field_desc('instruction')->{value});
            $nc->put(preview_url => $fo->field_desc('preview_url')->{value});

            my $name=$fo->field_desc('name')->{value};
            $content_list->put($name => $nc);
            $nc=$content_list->get($name);

            my $nd=$nc->get('Data')->get_new();
            $nd->put(effective_time => time);
            $nd->put(mod_time   => time);
            $nd->put(comment    => $fo->field_desc('comment')->{value} || '');
            $nd->put(text       => $fo->field_desc('text')->{value} || '');
            $nd->put(mime_type  => $fo->field_desc('mime_type')->{value} || 'text/plain');
            my $id=$nc->get('Data')->put($nd);
            $nc->put('current_id' => $id);

            $self->object->display(merge_refs($args,{
                path => $args->{"success.path"},
                template => $args->{"success.template"},
            }));
        },
    );

    my $form_args=merge_refs($args);
    delete @{$form_args}{qw(mode update)};
    $form->display($form_args);
}

###############################################################################

=item 'content-data' => content_data (%)

Displays data text by name according to preview argument or clipboard
flag.

By default it just outputs the content literally without any
processing. If 'parse' argument is true then the content will be parsed
as if it were a template. Arguments given to 'content-data' will be
available to that template in this case.

If there is a 'default.path' or 'default.template' arguments then they
will be displayed in case where there is no content object by that name
exists in the database. If default is not given and there is no content
found in the database then an error will be thrown.

Example:

 <%Content name="about_us"%>

 <%Content name="about_us" parse="1" REAL_NAME="John Silver"%>

 <%Content name="about_us"
           parse="1"
           default.path="/bits/default-about-us"
           REAL_NAME="John Silver"
 %>

=cut

sub content_data ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $flag_cb_uri=$config->{flag_cb_uri} || '/content/preview_flag';
    my $preview=$args->{preview} ||
                $self->clipboard->get($flag_cb_uri) ||
                '';

    my $text;
    if($preview) {
        if($args->{'default.path'} || defined($args->{'default.template'})) {
            use XAO::Errors qw(XAO::E::DO::FS::List);

            try {
                my ($content,$data)=$self->get_content($args);
                $text=$data->get('text');
            }
            catch XAO::E::DO::FS::List with {
                $text=$self->object->expand(
                    path        => $args->{'default.path'},
                    template    => $args->{'default.template'},
                    unparsed    => 1,
                );
            };
        }
        else {
            my ($content,$data)=$self->get_content($args);
            $text=$data->get('text');
        }
    }
    else {
        if($args->{'default.path'} || defined($args->{'default.template'})) {
            use XAO::Errors qw(XAO::E::DO::FS::List);

            try {
                $text=$self->cache->get($self,$args);
            }
            catch XAO::E::DO::FS::List with {
                $text=$self->object->expand(
                    path        => $args->{'default.path'},
                    template    => $args->{'default.template'},
                    unparsed    => 1,
                );
            };
        }
        else {
            $text=$self->cache->get($self,$args);
        }
    }

    if($args->{parse}) {
        $self->object->display(merge_refs($args,{ template => $text }));
    }
    else {
        $self->textout($text);
    }
}

###############################################################################

=item 'content-if-preview' => content_if_preview (%)

Checks if preview mode is currently on and displays given 'path' or
'template' if it is.

=cut

sub content_if_preview ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $flag_cb_uri=$config->{flag_cb_uri} || '/content/preview_flag';

    if($self->clipboard->get($flag_cb_uri)) {
        $self->object->display(template => $args->{template},
                               path     => $args->{path});
    }
    elsif($args->{'default.path'} || defined($args->{'default.template'})) {
        $self->object->display(template => $args->{'default.template'},
                               path     => $args->{'default.path'});
    }
}

###############################################################################

=item 'content-publish' => content_publish (%)

Makes preview data block current for the given content. If there were
no modifications to the content (no preview data block) then nothing is
modified.

Arguments are:

 name           => content name
 path/template  => what to display in case of success, optional

=cut

sub content_publish ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $content=$self->get_content($args);
    my $name=$args->{name};

    my $preview_id=$content->get('preview_id');
    if($preview_id) {
        $self->cache->drop(name => $name);

        my $data=$content->get('Data')->get($preview_id);
        $data->put(effective_time => time);
        $content->put(current_id => $preview_id);
        $content->put(preview_id => '');
    }

    if($args->{path} || defined($args->{template})) {
        $self->object->display(
            path        => $args->{path},
            template    => $args->{template},
            NAME        => $name,
            CURRENT_ID  => $preview_id || '',
        );
    }
}

###############################################################################

=item 'content_publish_all' => content_publish_all (%)

Makes preview data blocks current for all content elements.

=cut

sub content_publish_all ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $list_uri=$config->{list_uri} || '/Content';
    my $content_list=$self->odb->fetch($list_uri);

    foreach my $name ($content_list->keys) {
        $self->content_publish(
            name => $name,
        );
    }

    if($args->{path} || defined($args->{template})) {
        $self->object->display(
            path        => $args->{path},
            template    => $args->{template},
        );
    }
}

###############################################################################

=item 'content-revert' => content_revert (%)

Reverts given content to older date by creating or replacing preview
data block with a copy of old content.

Date does not have to match exactly, the data block with closest date
equal to or preceeding the given date will be used.  If as a result of
that the current content is to be used anf there is no preview block
defined then no modifications are made.

If given content did not exist at all at the given time then no
modifications are made as well.

Arguments are:

 name       => content name
 time       => time to revert to

=cut

sub content_revert ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $content=$self->get_content($args);

    ##
    # Looking for the source data block id
    #
    my $time=$args->{'time'} ||
        throw $self "content_revert - useless without 'time' argument";
    my $content_data=$content->get('Data');
    my $sr=$content_data->search('effective_time','le',$time,
                                 { orderby => [ descend => 'effective_time' ]
                                 });

    my $preview_id;
    if(@$sr) {
        my $id=$sr->[0];
        if($id ne $content->get('current_id')) {
            my $olddata=$content_data->get($id);
            my $newdata=$content_data->get_new();
            my ($text,$mime_type,$comment)=
                $olddata->get(qw(text mime_type comment));
            $newdata->put(text => $text);
            $newdata->put(mime_type => $mime_type);
            $newdata->put(comment => $comment);
            $newdata->put(mod_time => time);

            $preview_id=$content->get('preview_id');
            if($preview_id) {
                $content_data->put($preview_id => $newdata);
            }
            else {
                $preview_id=$content_data->put($newdata);
                $content->put(preview_id => $preview_id);
            }
        }
        elsif($preview_id=$content->get('preview_id')) {
            $content->put(preview_id => '');
            $content_data->delete($preview_id);
            $preview_id='';
        }
    }

    if($args->{path} || defined($args->{template})) {
        $self->object->display(
            path        => $args->{path},
            template    => $args->{template},
            NAME        => $args->{name},
            PREVIEW_ID  => $preview_id || '',
        );
    }
}

###############################################################################

=item 'content_revert_all' => content_revert_all (%)

Loads older date content for all content elements at once.

=cut

sub content_revert_all ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $list_uri=$config->{list_uri} || '/Content';
    my $content_list=$self->odb->fetch($list_uri);

    foreach my $name ($content_list->keys) {
        $self->content_revert(
            name    => $name,
            time    => $args->{time},
        );
    }

    if($args->{path} || defined($args->{template})) {
        $self->object->display(
            path        => $args->{path},
            template    => $args->{template},
        );
    }
}

###############################################################################

=item 'content-set-preview' => content_set_preview (%)

Sets or drop preview flag in the clipboard indicating whether all
subsequent calls to the Content should return current or preview
content.

Usually this is used somewhere in the page header on all pages to check
for a specific cookie or a CGI parameter to turn on site 'preview' mode.

Example:

 <%Content
   mode="content-set-preview"
   value={<%Condition
            a.cgiparam="preview_mode"
            a.template="1"
            b.cookie="preview_mode"
            b.template="1"
            default.template="0"
          %>}
 %>

=cut

sub content_set_preview ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $flag_cb_uri=$config->{flag_cb_uri} || '/content/preview_flag';

    $self->clipboard->put($flag_cb_uri => $args->{value} ? 1 : 0);
}

###############################################################################

=item 'content-show' => content_show (%)

Displays the content by a given name and optionally an ID of a specific
release of that content.

Passes the following parameters to the given template:

 COMMENT        => comment for data
 CURRENT_ID     => current published element ID
 DATA_ID        => ID of data block being used
 DESCRIPTION    => content description
 EFFECTIVE_TIME => publication effective time
 INSTRUCTION    => instruction
 MIME_TYPE      => content data MIME type
 MOD_TIME       => last modification time
 NAME           => content name
 PREVIEW_ID     => id of unpublished data or empty string if published
 PREVIEW_URL    => URL of a preview page
 TEXT           => content data

=cut

sub content_show ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my ($content,$data)=$self->get_content($args);

    my ($description,$instruction,$preview_id,$preview_url,$current_id)=
        $content->get(qw(description instruction
                         preview_id preview_url current_id));

    my ($comment,$text,$eff_time,$mod_time,$mime_type)=
        $data->get(qw(comment text effective_time mod_time mime_type));

    if(!$eff_time && $current_id) {
        $eff_time=$content->get('Data')->get($current_id)->get('effective_time');
    }

    $self->object->display(
        path            => $args->{path},
        template        => $args->{template},
        COMMENT         => $comment || '',
        CURRENT_ID      => $current_id || '',
        DATA_ID         => $data->container_key,
        DESCRIPTION     => $description || '',
        EFFECTIVE_TIME  => $eff_time || 0,
        INSTRUCTION     => $instruction || '',
        MIME_TYPE       => $mime_type || '',
        MOD_TIME        => $mod_time || 0,
        NAME            => $content->container_key,
        PREVIEW_ID      => $preview_id || '',
        PREVIEW_URL     => $preview_url || '',
        TEXT            => defined($text) ? $text : '',
    );
}

###############################################################################

=item 'content-show-dates' => content_show_dates (%)

Displays all publication dates in order from most recent to least
recent. If 'name' parameter is given then dates are restricted to that
specific element otherwise global list of dates is shown.

Example:

 <SELECT NAME="xxx">
 <%Content mode="content-show-dates"
           path="/bits/content-date-option"%>
 </SELECT>

=cut

sub content_show_dates ($%) {
    my $self=shift;
    my $args=get_args(\@_);


    my $config=$self->siteconfig('/content');
    my $list_uri=$config->{list_uri} || '/Content';

    my $list=$self->odb->fetch($list_uri);

    if($args->{name}) {
        $list=$list->get($args->{name})->get('Data');
    }
    else {
        my $t=$list->get_new();
        my $class=$t->describe('Data')->{class};
        $list=$self->odb->collection(class => $class);
    }

    my %dates;
    foreach my $id ($list->keys) {
        my ($time,$cmt)=$list->get($id)->get('effective_time','comment');
        $dates{$time || 0}=$cmt;
    }

    my $page=$self->object;
    foreach my $date (sort { $b <=> $a } keys %dates) {
        next unless $date;
        $page->display(
            path            => $args->{path},
            template        => $args->{template},
            EFFECTIVE_TIME  => $date,
            COMMENT         => $dates{$date} || '',
        );
    }
}

###############################################################################

=item 'content-store' => content_store (%)

Stores new content by either replacing current content in the preview
data block or by creating a new preview data block if there is no one
currently.

Arguments are:

 name           => content name
 comment        => comment for that release
 text           => full text for that release; stripped of whitespace
                   in the end and in the beginning
 mime_type      => MIME type, default is text/plain

=cut

sub content_store ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{name} ||
        throw $self "content_store - no 'name' given";
    my $comment=$args->{comment} || '';
    my $mime_type=$args->{mime_type} || 'text/plain';
    my $text=$args->{text} || '';

    $text=~s/^\s*(.*?)\s*$/$1/;

    my $content=$self->get_content($args);
    my $data_list=$content->get('Data');
    my $data=$data_list->get_new();

    $data->put(
        text        => $text,
        comment     => $comment,
        mime_type   => $mime_type,
        mod_time    => time,
    );

    my $preview_id=$content->get('preview_id');
    if($preview_id) {
        $data_list->put($preview_id => $data);
    }
    else {
        $preview_id=$data_list->put($data);
        $content->put(preview_id => $preview_id);
    }

    if($args->{template} || $args->{path}) {
        $self->object->display(
            path        => $args->{path},
            template    => $args->{template},
            NAME        => $name,
            DATA_ID     => $preview_id,
        );
    }
}

###############################################################################

=back

=head1 INTERNAL METHODS

The following methods are not available through 'mode' argument and
serve various internal purposes.

=over

=cut

###############################################################################

=item build_structure ()

Builds supporting structure in the database. Does not destroy existing
data -- safe to call on already populated database.

Usually should be called in Config.pm's build_structure() method.

=cut

sub build_structure ($) {
    my $self=shift;

    $self->odb->fetch('/')->build_structure($self->data_structure);
}

###############################################################################

=item cache ()

Returns content cache reference.

=cut

sub cache ($) {
    my $self=shift;
    my $config=$self->siteconfig('/content');
    $self->SUPER::cache(
        name        => 'content',
        retrieve    => sub {
            my $s=shift;
            my $a=get_args(\@_);

            my $n=$a->{name};
            my $def_path=$a->{'default.path'};
            my $def_template=$a->{'default.template'};

            my $cf=$self->siteconfig('/content');
            my $luri=$cf->{list_uri} || '/Content';

            if($def_path || defined($def_template)) {
                my $cn=$self->odb->fetch($luri);
                if($cn->exists($n)) {
                    $cn=$cn->get($n);
                    my $id=$cn->get('current_id');
                    return $cn->get('Data')->get($id)->get('text');
                }
                else {
                    return $self->object->expand(
                        path        => $def_path,
                        template    => $def_template,
                        unparsed    => 1,
                    );
                }
            }
            else {
                my $cn=$self->odb->fetch("$luri/$n");
                my $id=$cn->get('current_id');
                return $cn->get('Data')->get($id)->get('text');
            }
        },
        coords      => ['name'],
        expire      => $config->{cache_time} || 5*60,
        size        => $config->{cache_size} || 1024,
    );
}

###############################################################################

=item data_structure ()

Returns a reference to a hash that describes database structure. Usually
you would add it to your database description in Config.pm:

 my $cobj=XAO::Objects->new(objname => 'Web::Content');

 my %structure=(
     MyData => {
         ...
     },

     %{$cobj->data_structure},

     MyOtherData => {
         ...
     }
 );

If that looks ugly (it is ugly) then look at build_structure() method
description instead.

=cut

sub data_structure ($) {
    my $self=shift;

    my %structure=(
        Content => {
            type        => 'list',
            class       => 'Data::Content',
            key         => 'name',
            structure   => {
                Data => {
                    type        => 'list',
                    class       => 'Data::ContentData',
                    key         => 'id',
                    structure   => {
                        comment => {
                            type        => 'text',
                            maxlength   => 100,
                        },
                        effective_time => {
                            type        => 'integer',
                            minvalue    => 0,
                        },
                        mime_type => {
                            type        => 'text',
                            maxlength   => 50,
                        },
                        mod_time => {
                            type        => 'integer',
                            minvalue    => 0,
                        },
                        text => {
                            type        => 'text',
                            maxlength   => 100000,
                        },
                    },
                },
                current_id => {
                    type        => 'text',
                    maxlength   => 30,
                },
                description => {
                    type        => 'text',
                    maxlength   => 100,
                },
                instruction => {
                    type        => 'text',
                    maxlength   => 1000,
                },
                preview_id => {
                    type        => 'text',
                    maxlength   => 30,
                },
                preview_url => {
                    type        => 'text',
                    maxlength   => 200,
                },
            },
        },
    );

    return \%structure;
}

###############################################################################

=item get_content ($%)

This method returns a Data::Content and Data::Content objects using
standard content location definition arguments described in METHODS
section preface. It is used in almost every other method to get the data
of a content object.

If called in scalar context then returns only content object, without
data.

Arguments it accepts are (as stated above):

 name       => Name of content (required)
 data_id    => ID of a specific version (optional, rarely used)
 preview    => if non-zero then unpublished version of content will
               be used. If that argument is not present then the
               clipboard preview flag is used (see flag_cb_uri above)

=cut

sub get_content ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig('/content');
    my $list_uri=$config->{list_uri} || '/Content';
    my $flag_cb_uri=$config->{flag_cb_uri} || '/content/preview_flag';

    my $name=$args->{name};
    my $data_id=$args->{data_id} || '';
    my $preview=$args->{preview} ||
                $self->clipboard->get($flag_cb_uri) ||
                '';

    my $content=$self->odb->fetch("$list_uri/$name");

    return $content unless wantarray;

    if($data_id) {
        # Nothing
    }
    elsif($preview) {
        my $cid;
        ($data_id,$cid)=$content->get('preview_id','current_id');
        $data_id=$cid unless $data_id;
    }
    else {
        $data_id=$content->get('current_id');
    }

    $data_id || throw $self "get_data - no data_id for name=$name, data_id=$data_id, preview=$preview";

    ($content,$content->get('Data')->get($data_id));
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2000-2002 XAO Inc.

Andrew Maltsev <am@xao.com>

=head1 SEE ALSO

Recommended reading:
L<XAO::DO::Web::Content>,
L<XAO::FS>,
L<XAO::Web>.
