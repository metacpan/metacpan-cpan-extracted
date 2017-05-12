package WWW::Bugzilla;

$WWW::Bugzilla::VERSION = '1.5';

use strict;
use warnings;
use WWW::Mechanize;
use Fatal qw(:void open opendir);
use Carp qw(croak carp);

use constant FIELDS => qw( bugzilla_version bugzilla_version_minor version component status resolution dup_id assigned_to summary bug_number description os platform severity priority cc url add_cc target_milestone status_whiteboard keywords depends_on blocks additional_comments );
 
my %new_field_map = (   product => 'product',
                        version => 'version',
                        component => 'component',
                        assigned_to => 'assigned_to',
                        summary => 'short_desc',
                        description => 'comment',
                        os => 'op_sys',
                        platform => 'rep_platform',
                        severity => 'bug_severity',
                        priority => 'priority',
                        cc => 'cc',
                        url => 'bug_file_loc' );

my %other_field_map = (
    resolution => 'resolution_knob_5',
    );

my %update_field_map = (product => 'product',
#                        bug_number => 'id', 	# this cannot be updated
                        platform => 'rep_platform',
                        os => 'op_sys',
                        add_cc => 'newcc',
                        component => 'component',
                        version => 'version',
#                        cc => 'cc', 	# this field should not be updated, use add_cc
                        status => 'knob',
                        priority => 'priority',
                        severity => 'bug_severity',
                        target_milestone => 'target_milestone',
                        url => 'bug_file_loc',
                        summary => 'short_desc',
                        status_whiteboard => 'status_whiteboard',
                        keywords => 'keywords',
                        depends_on => 'dependson',
                        blocks => 'blocked',
                        additional_comments => 'comment' );

=head1 NAME

WWW::Bugzilla - Handles submission/update of bugzilla bugs via WWW::Mechanize.

=head1 SYNOPSIS

    use WWW::Bugzilla;

    # create new bug
    my $bz = WWW::Bugzilla->new(    server => 'www.mybugzilla.com', 
                                    email => 'buguser@bug.com',
                                    password => 'mypassword' );

    # enter info into some fields and save new bug

    # get list of available version choices
    my @versions = $bz->available('version');

    # set version
    $bz->version( $versions[0] );

    # get list of available products
    my @products = $bz->available('product');

    # set product
    $bz->product( $products[0] );

    # get list of components available
    my @components = $bz->available('component');

    # set component
    $bz->component( $components[0] );

    # optionally do the same for platform, os, priority, severity.

    $bz->assigned_to( 'joeschmoe@whatever.com' );
    $bz->summary( $some_text );
    $bz->description( $some_more_text );

    # submit bug, returning new bug number
    my $bug_number = $bz->commit;

    # all of the above could have been done in a much easier
    # way, had we known what values to use. See below:

    my $bz = WWW::Bugzilla->new(    server => 'www.mybugzilla.com',
                                    email => 'buguser@bug.com',
                                    password => 'mypassword' 
                                    version => 'Alpha',
                                    product => 'MyProduct',
                                    component => 'API',
                                    assigned_to => 'joeschmoe@whatever.com',
                                    summary => $some_text,
                                    description => $some_more_text);

    my $bug_number = $bz->commit;

    # Below is an example of how one would update a bug.

    my $bz = WWW::Bugzilla->new(    server => 'www.mybugzilla.com',
                                    email => 'buguser@bug.com',
                                    password => 'mypassword' 
                                    bug_number => 46 );

    # show me the chosen component
    my $component = $bz->component;

    # change component
    $bz->component( 'Test Failures' );

    $bz->add_cc( 'me@me.org' );

    $bz->add_attachment(    filepath => '/home/me/file.txt',
                            description => 'description text',
                            is_patch => 0,
                            comment => 'comment text here' );

    $bz->additional_comments( "comments here");

    # below are examples of changing bug status
    $bz->change_status("assigned");
    $bz->change_status("fixed");
    $bz->change_status("later");
    $bz->mark_as_duplicate("12");
    $bz->reassign("someone@else.com");

    $bz->commit;

=head1 DESCRIPTION

WWW::Bugzilla currently provides an API to posting new Bugzilla
bugs, as well as updating existing Bugzilla bugs.

=head1 INTERFACE

=head2 METHODS

=over

=item new()

Initialize WWW::Bugzilla object.  If bug_number is passed in, 
will initialize as existing bug. Will croak() unless the 
Bugzilla login page on server specified returns a 200 or 404.
new() supports the following name-value parameters.

=over

=item server (required)

URL of the bugzilla server you wish to interface with. Do not 
place http:// or https:// in front of the url (see 'use_ssl' option
below)

=item email (required)

Your email address used by bugzilla, in other words your
bugzilla login.

=item password (required)

Bugzilla password.

=item use_ssl (optional)

If set, will use https:// protocol, defaults to http://.  

NOTE: This option requires Crypt::SSLeay.

=item product

Bugzilla product name, required if entering new bug
(not updating).

=item bug_number (optional)

If you mean to update an existing bug (not create a new one)
include a valid bug number here.

=item version component status assigned_to resolution dup_id assigned_to summary bug_number description os platform severity priority cc url add_cc target_milestone status_whiteboard keywords depends_on blocks additional_comments

These are fields that can be initialized on new(), useful for new bugs.
Please note that some of these fields apply only to bugs being updated,
and if you set them here, they will be overridden if the value is already
set in the actual bug on the server.  These fields also have thier own
get/set methods (see below).

=back

=cut 

use Class::MethodMaker
    new_with_init => 'new',
    new_hash_init => 'hash_init',
    get_set       => [ FIELDS ];

sub init {
    my $self = shift;
    my %args = @_;
   
    croak("'server', 'email', and 'password' are all required arguments.") if ( (not $args{server}) or (not $args{email}) or (not $args{password}) ); 

#    croak("'product' required for new bug.") if ( (not $args{product}) and (not $args{bug_number}) );
    $self->{'product'} = $args{'product'} if (defined($args{'product'}));

    $self->{mech} =  WWW::Mechanize->new();

    $self->{protocol} = delete($args{use_ssl}) ? 'https' : 'http';

    $self->{server} = $args{server};                                                                              
    $self->_login( delete $args{server}, delete $args{email}, delete $args{password});
    
    # finish the object
    $self->hash_init(%args);

    if ($self->{bug_number}) {
        $self->_get_update_page();
    } elsif ($self->{product}) {
        $self->_get_new_page();
    }

    $self->check_error();
    return $self;
}

sub _get_new_page {
    my $self = shift;
                                                                  
    my $mech = $self->{mech};
    my $new_page = $self->{protocol}.'://'.$self->{server}.'/enter_bug.cgi?product='.$self->{product};
    $mech->get($new_page);
    $self->check_error();
    $mech->form_name('Create') if ($self->bugzilla_version == 3);

    # bail unless OK or Redirect happens
    croak("Cannot open page $new_page") unless ( ($mech->status == '200') or ($mech->status == '404') );
}

sub _get_update_page {
    my $self = shift;

    my $mech = $self->{mech};
    $self->_get_form_by_field('quicksearch');
    $mech->field('quicksearch', $self->{bug_number});
    $mech->submit();
    $self->check_error();
    
    $mech->form_name("changeform");
    # set fields to chosen values
    foreach my $field ( keys %update_field_map ) {
        if ($mech->current_form->find_input($update_field_map{$field})) {    
            $self->{$field} = $mech->current_form->value( $update_field_map{$field} );
        } else {
#            warn "# Couldn't find $field";
        }
    }
}

# based on the current page, set the current form to the first form with a specified field
sub _get_form_by_field {
    my ($self, $field) = @_;
    croak("invalid field") if !$field;

    my $mech = $self->{mech};
    my $i = 1;
    foreach my $form ($mech->forms()) {
        if ($form->find_input($field)) {
            $mech->form_number($i);
            return;
        }
        $i++;
    }
    croak("No form with the field $field available");
}

sub _login {
    my $self = shift;
    my ($server, $email, $password) = @_;

    my $mech = $self->{mech};

    my $login_page = $self->{protocol}.'://'.$server.'/query.cgi?GoAheadAndLogIn=1';
    
    $mech->get( $login_page ); 

    # bail unless OK or Redirect happens
    croak("Cannot open page $login_page") unless ( ($mech->status == '200') or ($mech->status == '404') );

    $self->_get_form_by_field('Bugzilla_login');
    $mech->field('Bugzilla_login', $email);
    $mech->field('Bugzilla_password', $password);
    $mech->submit_form();

    
    $mech->get($self->{protocol}.'://'.$server.'/');

    if ($mech->content() =~ /<span>Version (\d+)\.(\d+)(\.\d+)?\+?<\/span>/) {
        $self->bugzilla_version($1);
        $self->bugzilla_version_minor($2);
    } elsif ($mech->content() =~ /<p class="header_addl_info">version (\d+)\./smi) {
        $self->bugzilla_version($1);
    } else {
        croak("Unable to verify bugzilla version.");
    }

    if ($self->bugzilla_version > 2) {
        $update_field_map{'status'} = 'bug_status';
        $other_field_map{'resolution'} = 'resolution';
    }
}

=item product() version() component() status() assigned_to() resolution() dup_id() assigned_to() summary() bug_number() description() os() platform() severity() priority() cc() url() add_cc() target_milestone() status_whiteboard() keywords() depends_on() blocks() additional_comments()

get/set the value of these bug fields.  Some apply only to new bugs, some 
only to bugs being updated. commit() must be called to save these 
permanently.

=item available() 

Returns list of available options for field requested. Below are known
valid fields:

product
platform
os
version
priority
severity
component
target_milestone

=cut

sub available {
    my $self = shift;
    my $field_choice = shift;
    my $mech = $self->{mech};

    # we handle product seperately because bugzilla requires it to be handled 
    # seperately on bug creation
    if ('product' eq lc($field_choice)) {
        return $self->get_products();
    }

    # make sure that we've set a product before we do any of the other stuff
    croak("available() needs a valid product to be specified") if not $self->{'product'};
 
    # note that we are using %new_field map regardless if this is a new bug
    # or not.  this should work, as these fields should be the same for
    # both new and old, but look here if problems occur!
    
    if (my $item = $mech->current_form->find_input( $new_field_map{$field_choice} )) {
        return $item->possible_values();
    } else {
        return undef;
    }
}

=item product()

Set the Product for the bug

=cut

sub product {
    my ($self, $product) = @_;

    if ($product) {
        $self->{'product'} = $product;
        if ($self->{bug_number}) {
            $self->_get_update_page();
        } elsif ($self->{'product'}) {
            $self->_get_new_page();
        }
    }
    return ($self->{'product'});
}


=item reassign() 

Mark bug being updated as reassigned to another user. Takes email 
address as parameter.  Status/resolution will not be updated 
until commit() is called.

=cut

sub reassign {
    my $self = shift;
    my $email = shift;
   
     croak("reassign() needs a bug number passed in as a parameter") if not $email;
                                                                             
    croak("reassign() may not be called until the bug is committed for the first time") if not $self->{bug_number};

    $self->{status} = 'reassign';
    $self->{assigned_to} = $email;  
}

=item mark_as_duplicate() 

Mark bug being updated as duplicate of another bug number.
Takes bug number as argument.
Status/resolution will not be updated until commit() is called.

=cut 

sub mark_as_duplicate {
    my $self = shift;
    my $dup_id = shift;

    croak("mark_as_duplicate() needs a bug number passed in as a parameter") if not $dup_id;
    
    croak("mark_as_duplicate() may not be called until the bug is committed for the first time") if not $self->{bug_number};

    $self->{status} = 'RESOLVED';
    $self->{resolution} = 'DUPLICATE';
    $self->{dup_id} = $dup_id;    
}

=item change_status()

Change status of bug being updated.  Status/resolution will not
be updated until commit() is called.  The following are valid 
options (case-insensitive):

assigned
fixed
invalid
wontfix
later
remind
worksforme
reopen
verified
closed

=cut

sub change_status {
    my ($self, $status) = @_;

    croak("change_status() may not be called until the bug is committed for the first time") if not $self->{bug_number};

    $status = uc($status);

    my %status = (
            'ASSIGNED'  => 'accept', 
            'REOPENED'    => 'reopen',
            'VERIFIED'  => 'verify',
            'CLOSED'    => 'close'
            );

    my %resolution = (
            'FIXED'     => 1,
            'INVALID'   => 1,
            'WONTFIX'   => 1,
            'LATER'     => 1,
            'REMIND'    => 1,
            'DUPLICATE' => 1,
            'WORKSFORME' => 1   
            );

    croak ("$status is not a valid status.") if not ($resolution{$status} or $status{$status});

    if ($status{$status}) {
        $self->{status} = $status;
        $self->{resolution} = '';
        # $status{$status};
    } else {
        $self->{status} = "RESOLVED";
        $self->{resolution} = $status;
    }

    return 1;
}

=item add_attachment()

Adds attachment to existing bug - will not work for new 
bugs.  Below are available params:

=over

=item *

filepath (required)

=item *

description (required)

=item *

is_patch (optional boolean)

=item *

content_type - Autodetected if not defined.

=item *

comment (optional)

=item *

finished - will not return object to update form if set (optional boolean) 

=back

=cut

sub add_attachment {
    my $self = shift;
    my %args = @_;
    my $mech = $self->{mech};
    
    croak("add_attachment() may not be called until the bug is committed for the first time") if not $self->{bug_number};

    croak("You must include a filepath and description.") unless ($args{filepath} and $args{description});
 
    my $attach_page = $self->{protocol}.'://'.$self->{server}.'/attachment.cgi?bugid='.$self->{bug_number}.'&action=enter';
    
    $mech->get( $attach_page );
    $self->check_error();
    $mech->form_name('entryform');
    $mech->field( 'data', $args{'filepath'} );
    $mech->field( 'description', $args{description} );
    $mech->field( 'comment', $args{comment} ) if $args{comment};
    $mech->field( 'ispatch', 1 ) if $args{'is_patch'};

    if ($args{'bigfile'}) {
        if ($mech->current_form->find_input('bigfile', 'checkbox', 0)) {
            $mech->tick('bigfile', 'bigfile');
        } else {
            croak('Bigfile support is not available');
        }
    }
    if ( $args{content_type} ) {
        $mech->field( 'contenttypemethod', 'manual' );
        $mech->field( 'contenttypeentry', $args{content_type} );
    } else {
        $mech->field( 'contenttypemethod', 'autodetect' );
    }

    $mech->submit_form(); 
    $self->check_error();
    my $id;
    if ($mech->content =~ /created/i) {
        my $link = $mech->find_link(text_regex => qr/^Attachment #\d+$/);
        my $title = $link->attrs()->{'title'};
        
        if ($title ne "'" . $args{'description'} . "'" && $title ne $args{'description'}) {
            croak('attachment not created');
        }
        if ($link->text =~ /^Attachment #(\d+)$/) {
            $id = $1;
        } else {
            croak('attachment not created');
        }
    }

    $self->_get_update_page() unless ($args{finished});
    return $id;
}

=item list_attachments()

Lists attachments that are attached to an existing bug - will not work for new bugs.

=cut

sub list_attachments {
    my $self = shift;
    my $mech = $self->{mech};
    
    croak("list_attachments() may not be called until the bug is committed for the first time") if not $self->{bug_number};
    
    my $bug_page = $self->{protocol}.'://'.$self->{server}.'/show_bug.cgi?id='.$self->{bug_number};
    $mech->get($bug_page);
    $self->check_error();
    
    my (@attachments);
    my %seen;
    foreach my $link ($mech->find_all_links(url_regex => qr/attachment\.cgi\?id=\d+$/)) {
        if ($link->url() =~ /^attachment.cgi\?id=(\d+)$/) {
            my $id = $1;
            next if ($seen{$id});
            $seen{$id}++;
            my $i = $link->url();
            $i =~ s/\?/\\?/g;
            my $re = '<a(?: name="a\d+")? href="' . $i . '"(?:\s*title="View the content of the attachment">\s*<b>|>)?<span class="(bz_obsolete)">';
            my $obsolete = ($mech->content() =~ /$re/smi) ? 1 : 0;
            push (@attachments, { id => $id, name => $link->text(), obsolete => $obsolete });
        } else {
            croak("WWW::Mechanize find_all_links gave us a bogus URL");
        }
    }
    return (@attachments);
}

=item get_attachment()

Get the specified attachment from an existing bug - will not work for new bugs.

=cut

sub get_attachment {
    my $self = shift;
    my %args = @_;
    my $mech = $self->{mech};
    
    croak("get_attachment() may not be called until the bug is committed for the first time") if not $self->{bug_number};
    
    croak("You must provide either the 'id' or 'name' of the attachment you wish to retreive") unless ($args{id} || $args{name});
    
    my $bug_page = $self->{protocol}.'://'.$self->{server}.'/show_bug.cgi?id='.$self->{bug_number};
    $mech->get($bug_page);
    $self->check_error();
 
    my @links;
    if ($args{'id'}) {
        @links = $mech->find_all_links( url => 'attachment.cgi?id=' . $args{'id'} );
    } elsif ($args{'name'}) {
        @links = $mech->find_all_links( text => $args{'name'} );
        if (scalar(@links) > 1) {
            carp('multiple attachments have the same name, returning the first one');
        }
    }

    croak('No such attachment') if (!@links);
    $mech->get($links[0]);
    return $mech->content();
}

=item obsolete_attachment()

Mark the specified attachment obsolete.  - will not work for new bugs.

=cut

sub obsolete_attachment {
    my $self = shift;
    my %args = @_;
    my $mech = $self->{mech};
    
    croak("obsolete_attachment() may not be called until the bug is committed for the first time") if not $self->{bug_number};
    
    croak("You must provide either the 'id' or 'name' of the attachment you wish to obsolete") unless ($args{id} || $args{name});
    
    my $bug_page = $self->{protocol}.'://'.$self->{server}.'/show_bug.cgi?id='.$self->{bug_number};
    $mech->get($bug_page);
    $self->check_error();
 
    my @links;
    if ($args{'id'}) {
        @links = $mech->find_all_links( url => 'attachment.cgi?id=' . $args{'id'} );
    } elsif ($args{'name'}) {
        @links = $mech->find_all_links( text => $args{'name'} );
        if (scalar(@links) > 1) {
            carp('multiple attachments have the same name, returning the first one');
        }
    }
    croak('No such attachment') if (!@links);
    $links[0]->[0] = $links[0]->[0] . '&action=edit';
    $links[0]->[5]->{'href'} = $links[0]->[5]->{'href'} . '&action=edit';
    $mech->get($links[0]);
    $mech->form_with_fields('id', 'action', 'contenttypemethod');
    $mech->tick("isobsolete", 1);
    $mech->submit();
    return $mech->content();
}


=item commit()

Submits bugzilla new or update form. Returns bug_number. Optionally
takes parameter finished- if set will you are done updating the bug,
and wil not return you to the update page.

=cut 

sub commit {
    my $self = shift;
    my %args = @_;
    my $mech = $self->{mech};
 
#    print $mech->uri() . "\n";
    if ($mech->content() !~ /a href="index\.cgi\?logout=1">/) {
        croak("must be logged in to commit bugs");
    }

    if ($self->{bug_number}) {
        # bugzilla > 3.0
        if ($self->bugzilla_version() > 2) {
            if ($self->{resolution}) {
                $mech->field($update_field_map{'status'}, $self->{'status'});
                $mech->field($other_field_map{'resolution'}, $self->{resolution});
                $self->{resolution} = undef;
                $self->{status} = undef;
            } elsif ($self->{status}) {
                $mech->field('bug_status', $self->{'status'});
                $self->{resolution} = undef;
                $self->{status} = undef;
            }
        } else {
            if ($self->{resolution}) {
                $mech->field($update_field_map{'status'}, 'resolve');
                $mech->field($other_field_map{'resolution'}, $self->{resolution});
                $self->{resolution} = undef;
                $self->{status} = undef;
            } elsif ($self->{status}) {
                $mech->field($update_field_map{'status'}, $self->{status});
                $self->{status} = undef;
            }
        }
        
        if ($self->{dup_id}) {
            $mech->field('dup_id', $self->{dup_id});
            $self->{dup_id} = undef;
        }
        if ($self->{assigned_to}) {
            $mech->field('assigned_to', $self->{assigned_to});
            $self->{assigned_to} = undef;
        }
        foreach my $field ( keys %update_field_map ) {
            # field is missing
            if (!$mech->current_form->find_input($update_field_map{$field})) {
#                warn "# $field is missing";
                next;
            }
            
            # field is hidden 
            next if $mech->current_form->find_input($update_field_map{$field})->type eq 'hidden';
            $mech->field( $update_field_map{$field}, $self->{$field} ) if defined($self->{$field});
        }
    } else {
        foreach my $field ( keys %new_field_map ) {
            if ($mech->current_form->find_input($new_field_map{$field})) {
                # if field is defined and it has changed
                if ( defined($self->{$field}) ) {
                    $mech->field( $new_field_map{$field}, $self->{$field} ) if ($mech->current_form->value($new_field_map{$field}) ne $self->{$field});
                }
            } 
        }
    }

    # delete the comment such that we don't reuse the same comment again accidentally.
    delete($self->{'comment'});

    $mech->submit_form();
        
    # 3.3+ token checking
    if ($mech->content() =~ /You submitted changes to process_bug\.cgi with an invalid/) {
        $mech->form_name('check');
        $mech->submit_form();
    }


    $self->check_error();
    if (!$self->{bug_number}) {
        if ($mech->content() =~ /<h2>Bug (\d+) has been added to the database/) {
            $self->{bug_number} = $1;
        } elsif ($mech->content() =~ />Bug (\d+)<\/a><\/i> has been added to the database<\/dt>/) {
            $self->{bug_number} = $1;
        } elsif ($mech->content() =~ /Bug (\d+) Submitted</) {
            $self->{bug_number} = $1;
        } elsif ($mech->content() =~ /Bug&nbsp;(\d+) Submitted</) {
            $self->{bug_number} = $1;
        } else {
#           warn $mech->content();
            croak("bug was not saved");
        }
    }
    $self->_get_update_page() unless ($args{finished});

    return $self->{bug_number};
}

=item check_error ()

Checks if an error was given, croaking if it did.

=cut 

sub check_error {
    my ($self) = @_;
    my $mech = $self->{mech};
    
    if ($mech->content() =~ /<td bgcolor="#ff0000">[\s\r\n]*<font size="\+2">[\s\r\n]*(.*?)[\s\r\n]*<\/font>[\s\r\n]*<\/td>/smi) {
        croak("error : $1");
    } elsif ($mech->content() =~ /<td id="error_msg" class="throw_error">\s*(.*?)\s*<\/td>/smi) {
        croak("error : $1");
    } elsif ($mech->content() =~ /<div class="throw_error">\s*(.*?)<\/div>/smi) {
        croak("error : $1");
    }
}

=item get_products ()

Gets a list of products

=cut 

sub get_products {
    my ($self) = @_;
    my $mech = $self->{mech};
    
    my $url = $self->{protocol}.'://'.$self->{server}.'/enter_bug.cgi';
    # version >= 3.0
    if ($self->bugzilla_version == 3) {
        $url .= '?classification=__all';
    }
    $mech->get($url);
    $self->check_error();

    my @products;
    foreach my $product ($mech->find_all_links( url_regex => qr/enter_bug.cgi\?product=/)) {
        push (@products, $product->text());
    }

    return (@products);
}


=item get_comments()

Lists comments made on an existing bug - will not work for new bugs.

=cut

sub get_comments {
    my ($self) = @_;
    croak("get_comments() may not be called until the bug is committed for the first time") if not $self->{bug_number};
    
    my $mech = $self->{mech};
    my $bug_page = $self->{protocol}.'://'.$self->{server}.'/show_bug.cgi?id='.$self->{bug_number};
    $mech->get($bug_page);
    $self->check_error(); 

    my @comments;
    my $content = $mech->content();
    while ($content =~ m/<pre id="comment_text_\d+">(.*?)<\/pre>/smg) {
        my $comment = $1;
        chomp($comment);
        push (@comments, $comment);
    }

    # 3.3+
    while ($content =~ m/<pre class="bz_comment_text"  id="comment_text_\d+">\s*(.*?)<\/pre>/smg) {
        my $comment = $1;
        chomp($comment);
        push (@comments, $comment);
    }

    return (@comments);
}

=back

=head1 BUGS, IMPROVEMENTS

There may well be bugs in this module.  Using it as I have, I just have not run
into any.  In addition, this module does not support ALL of Bugzilla's
features.  I will consider any patches or improvements, just send me an email
at the address listed below.
 
=head1 AUTHOR

Maintained by:
    Brian Caswell, bmc@shmoo.com

Originally written by:
    Matthew C. Vella, the_mcv@yahoo.com

=head1 LICENSE
                                                                      
  WWW::Bugzilla - Module providing API to create or update Bugzilla bugs.
  Copyright (C) 2003 Matthew C. Vella (the_mcv@yahoo.com)

  Portions Copyright (C) 2006 Brian Caswell (bmc@shmoo.com)
                                                                      
  This module is free software; you can redistribute it and/or modify it
  under the terms of either:
                                                                      
  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,                                                                      
  or
                                                                      
  b) the "Artistic License" which comes with this module.
                                                                      
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
  the GNU General Public License or the Artistic License for more details.
                                                                      
  You should have received a copy of the Artistic License with this
  module, in the file ARTISTIC.  If not, I'll be glad to provide one.
                                                                      
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA

=cut

1;
