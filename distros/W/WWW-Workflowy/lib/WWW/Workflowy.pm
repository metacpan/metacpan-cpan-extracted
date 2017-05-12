
package WWW::Workflowy;

use strict;
use warnings;

use LWP;
use LWP::UserAgent;

use Data::Dumper;
use JSON::PP;
use POSIX 'floor';
use Carp;

our $VERSION = '0.6';

# XXX need a public get_parent( $node ), and other traversal stuff.  we have a _find_parent() (which uses the recursive find logic).
# notes in /home/scott/projects/perl/workflowy_notes.txt

# use autobox::Closure::Attributes;  # XXX hacked up local copy that permits lvalue assigns

=head1 NAME

WWW::Workflowy - Faked up API interface to the workflowy.com collaborative outlining webapp

=head1 SYNOPSIS

B<This module does not use an official Workflowy API!  Consult workflowy.com's Terms of Service before deciding if it is okay to access their servers programmatically!>

    use WWW::Workflowy;

    my $wf = WWW::Workflowy->new( 
        # username => '',    # optional:  login credentials for private workflowies
        # password => '',
        url => 'https://workflowy.com/shared/b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25/',
        # or instead of url:  guid => 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25',
    );

    $node = $wf->dump;

    $node = $wf->find(
        sub {
            my $node = shift;
            my @parent_nodes = @{ shift() };
            return 1 if $node->{nm} eq 'The node you are looking for';
            return 1 if $node->{id} eq 'Jxn637Zp-uA5O-Anw2-A4kq-4zqKx7WuJNBN';
        },
    );

    $node_id = $wf->create( 
        parent_id => 'Jxn637Zp-uA5O-Anw2-A4kq-4zqKx7WuJNBN',
        priority  => 3,    # which position in the list of items under the parent to insert this node
        text      => "Don't forget to shave the yak",
    );


    $node = $wf->edit(
        save_id => 'Jxn637Zp-uA5O-Anw2-A4kq-4zqKx7WuJNBN',
        text      => "Think of an idea for a color for the bikeshed",
    );

    $wf->delete( $node->{id} );

    sleep $wf->polling_interval;  $wf->sync;

    $wf->fetch;

=head1 DESCRIPTION

All methods C<Carp::confess> on error.  Trap errors with L<Try::Tiny>, C<eval { }>, or similar to attempt to recover from them.

Each node has this structure:

  {
    'lm' => 1270,                                     # time delta last modified; usually not too interesting
    'nm' => 'Test 2.1',                               # text
    'id' => '63c98305-cd96-2016-4c4f-a20f7384ad9c'    # id
  }

It may also have a C<'ch'> containing an arrayref of additional nodes.
To make things interesting, the root node does not have a C<'ch'> of nodes under it.
Use the C<get_children()> method to avoid dealing with this special case.

The value from the C<id> field is used as the value for C<save_id>, C<node_id>, or C<parent_id>
in other calls.

=head2 new

Takes an optional C<username> and C<password> to access Workflowies that aren't shared.

Takes C<url> resembling C<https://workflowy.com/shared/b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25/> or a L<Workflowy> C<guid> such as C<b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25>.

May also be initialized from a serialized copy of a previous C<$wf->outline>.  See C<t/002-concurrent-remote-ops.t> for an example of that.

Returns a coderef.

=head2 dump

Produces an ASCII representation of the outline tree.

=head2 find

Recurses through the entire outline tree, calling the callback for each item.  The callback is passed the node currently being examined and an
arrayref of parents, top most parent first.

=head2 edit

Changes the text of a node.

=head2 create

Created a new node.

=head2 delete

Deletes a node.

=head2 move

No class method yet.  The thing handles C<move> commands sent down by the L<Workflowy> server (when data was moved by another L<Workflowy> client) but doesn't
yet let you send that command to the server.

=head2 sync

C<sync> fetches changes other people have made to the current L<Workflowy> outline and attempts to merge them into the local outline.

C<create>, C<edit>, and C<delete> minipulate data locally but only queue it to later be sent to the L<Workflowy> server.
Executing a C<sync> causes pending operations to be sent.

B<Check the return value!>  C<sync> returns B<false> and does nothing if C<< $wf->polling_interval >> seconds have not yet passed 
since the last request to the F<Workflowy> server.  Calling C<new> generally results in a request to the F<Workflowy> server.
To avoid C<sync> returning C<false> and doing nothing, use this idiom:

    sleep $wf->polling_interval;
    $wf->sync;

C<< $wf->last_poll_time >> contains a timestamp of the time that the last request was made.  
The value for C<< $wf->polling_interval >> may change in response to a request to the server.

=head2 fetch

Fetches the latest copy of the outline from the L<Workflowy> server, blowing away any local changes made to it that haven't yet been pushed up.
This happens automatically on C<new>.

=head2 get_children

Takes a node id.  Returns an arrayref of a node's children if it has children, or false otherwise.

=cut

package autobox::Closure::XAttributes::Methods;

use base 'autobox';
use B;
use PadWalker;

sub AUTOLOAD :lvalue {
    my $code = shift;
    (my $method = our $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';

    # we want the scalar unless the method name already a sigil
    my $attr = $method  =~ /^[\$\@\%\&\*]/ ? $method : '$' . $method;

    my $closed_over = PadWalker::closed_over($code);

    # is there a method of that name in the package the coderef was created in?
    # if so, run it.
    # give methods priority over the variables we close over.
    # XXX this isn't lvalue friendly, but sdw can't figure out how to make it be and not piss off old perls.

    my $stash = B::svref_2object($code)->STASH->NAME;
    if( $stash and $stash->can($method) ) {
        # t/003-live-test.t .............. Can't modify non-lvalue subroutine call at lib/WWW/Workflowy.pm line 170. in perl 5.14.2
        # goto apparently cheats lvalue detection; cheating detection is adequate for our purposes.
        # return $stash->can($method)->( $code, @_ ); 
        @_ = ( $code, @_ ); goto &{ $stash->can($method) };
    }

    exists $closed_over->{$attr} or Carp::croak "$code does not close over $attr";

    my $ref = ref $closed_over->{$attr};

    if (@_) {
        return @{ $closed_over->{$attr} } = @_ if $ref eq 'ARRAY';
        return %{ $closed_over->{$attr} } = @_ if $ref eq 'HASH';
        return ${ $closed_over->{$attr} } = shift;
    }

    $ref eq 'HASH' || $ref eq 'ARRAY' ? $closed_over->{$attr} : ${ $closed_over->{$attr} };  # lvalue friendly return

}

#
#
#

package WWW::Workflowy;

use autobox CODE => 'autobox::Closure::XAttributes::Methods'; # XXX temp since we can't 'use' it because it's inline

sub import {
    my $class = shift;
    $class->autobox::import(CODE => 'autobox::Closure::XAttributes::Methods');
}

sub new {

    my $package = shift;
    my %args = @_;

    #

    my $outline;
    my $client_id;
    my $date_joined;
    my $last_transaction_id;   # transaction ids are much alrger than the lastModified/lm values; eg 106551357; comes from initialMostRecentOperationTransactionId then $result_json->{results}->[0]->{new_most_recent_operation_transaction_id}
    my $operations = [];       # edits we've made but not yet posted
    my $polling_interval;      # from $outline->{initialPollingIntervalInMs} and then ->{results}->[0]->{new_polling_interval_in_ms}
    my $last_poll_time;

    #

    my $share_id;              # stands in temporarily for shared_projectid for newer style URLs that look like https://workflowy.com/s/123abcdeABCDE

    if( $args{guid} and ! $args{url} ) {
        # https://workflowy.com/shared/b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25/
        $args{url} = "http://workflowy.com/shared/$args{guid}/";
    } elsif( $args{url} and $args{url} =~ m{workflowy.com/s/\w+$} ) {
        ($share_id) = $args{url} =~ m{workflowy.com/s/(\w+)$};
    } elsif( ! $args{guid} and $args{url} ) {
        ($args{guid}) = $args{url} =~ m{/shared/(.*?)/\w*$} or confess "workflowy url doesn't match pattern of ``.*/shared/.*/''";
    } elsif( $args{guid} and $args{url} ) {
        confess "don't pass both guid and url parameters; pass one or the other";
    } elsif( $args{outline} ) {
        # testing -- pass in an outline
        $outline = delete $args{outline};
        $last_transaction_id = $outline->{initialMostRecentOperationTransactionId} or confess "no initialMostRecentOperationTransactionId in serialized outline";
        $date_joined = $outline->{dateJoinedTimestampInSeconds}; # XXX probably have to compute clock skew (diff between time() and this value) and use that when computing $client_timestamp
    } elsif( $args{username} and $args{password} ) {
        # okay, they'll get their home node and we can pick out the id from there
    } else {
        confess "pass guid or url, or else username and password";
    }

    my $workflowy_url = delete $args{url};
    my $shared_projectid = delete $args{guid};

    #

    my $username = delete $args{username};
    my $password = delete $args{password};

    #

    confess "unknown args to new(): " . join ', ', keys %args if keys %args;

    #

    my $user_agent = LWP::UserAgent->new(agent => "Mozilla/5.0 (Windows NT 5.1; rv:5.0.1) Gecko/20100101 Firefox/5.0.1");
    $user_agent->cookie_jar or $user_agent->cookie_jar( { } );

    # login

    if( $username and $password )  {

        # get a cookie assigned to us

        my $r = HTTP::Request->new( GET => "https://workflowy.com/" );
        my $response = $user_agent->request($r);
# warn $response->as_string();
# warn "cookie jar: " . $user_agent->cookie_jar->as_string();

        # send login info

        my $referer = 'https://workflowy.com/';

    try_login_again:

        $r = HTTP::Request->new( POST => "https://workflowy.com/accounts/login" );
        # $r->header( 'Content-Type'     => 'application/x-www-form-urlencoded; charset=UTF-8' );
        $r->header( 'Content-Type'     => 'application/x-www-form-urlencoded' );
        $r->header( Referer => $referer );
        $user_agent->cookie_jar->add_cookie_header( $r );
        my $post = '';
        $post .= 'username=' . _escape($username) . '&password=' . _escape($password);
        $r->content( $post );
# warn $r->as_string();
        $response = $user_agent->request($r);
        if( $response->is_error ) {
           confess "error: " . $response->error_as_HTML;
           return;
        }
# warn $response->as_string();
# warn "cookie jar: " . $user_agent->cookie_jar->as_string();
        $referer = 'https://workflowy.com/accounts/login';

        if( $response->code == 301 or $response->code == 302 ) {
            my $location = $response->header('Location') or die;
# warn "location: $location";   # should send us to https://workflowy.com
            if( $location eq 'https://workflowy.com/accounts/login' ) {
# warn "well, shit, trying to login again XXXX";
                goto try_login_again;
            } 
            $r = HTTP::Request->new( POST => $location );
            $r->header( 'Content-Type'     => 'application/x-www-form-urlencoded; charset=UTF-8' );
            $r->content( $post );
            $r->header( Referer => 'https://workflowy.com/accounts/login' );
            $user_agent->cookie_jar->add_cookie_header( $r );
            # warn $r->as_string();
            $response = $user_agent->request($r);
# warn $response->as_string();
            # warn "cookie jar: " . $user_agent->cookie_jar->as_string();
        }
    };

    #

    my $fetch_outline = sub {

        my $http_request;
        if( $shared_projectid) {
            # $http_request = HTTP::Request->new( GET => "https://workflowy.com/get_initialization_data?share_id=$shared_projectid&client_version=14" ); # do we have to start doing this instead?
            $http_request = HTTP::Request->new( GET => "https://workflowy.com/get_initialization_data?shared_projectid=$shared_projectid" );
        } elsif($share_id) {
            $http_request = HTTP::Request->new( GET => "https://workflowy.com/get_initialization_data?share_id=$share_id&client_version=14" );
        } else {
            $http_request = HTTP::Request->new( GET => "https://workflowy.com/get_initialization_data?client_version=14" );
        }
        $user_agent->cookie_jar->add_cookie_header( $http_request );
        $http_request->header( Accept => 'application/json, text/javascript, */*; q=0.01' );
        $http_request->header( 'Accept-Encoding' => 'gzip, deflate' );
        $http_request->header( Referer => 'https://workflowy.com/' );
        $http_request->header( 'X-Requested-With' => 'XMLHttpRequest' );

        # warn $http_request->as_string;
    
        my $response = $user_agent->request($http_request);
        if( $response->is_error ) {
           confess $http_request->uri ."\n" . $response->error_as_HTML ;
        }
    
        my $decoded_content = $response->decoded_content or die "no response content";

        my $response_json = decode_json $decoded_content or die "failed to decode response as JSON";

        $shared_projectid ||= $response_json->{projectTreeData}->{mainProjectTreeInfo}->{rootProject}->{id};  # happens with new style /s/123abcdefg style URLs that we don't know the shared_projectid until we etch it by the share_id

        $client_id = $response_json->{projectTreeData}->{clientId} or die "couldn't find clientId in project JSON";

        $outline = $response_json->{projectTreeData}->{mainProjectTreeInfo};

        $last_transaction_id = $outline->{initialMostRecentOperationTransactionId} or die "couldn't find initialMostRecentOperationTransactionId in project JSON";

        $date_joined = $outline->{dateJoinedTimestampInSeconds} or die "couldn't find dateJoinedTimestampInSeconds in project JSON"; # XXX probably have to compute clock skew (diff between time() and this value) and use that when computing $client_timestamp
        $outline->{initialPollingIntervalInMs} or die "couldn't find initialPollingIntervalInMs in project JSON";
        $polling_interval = $outline->{initialPollingIntervalInMs} / 1000;
        $last_poll_time = time;

        return $outline;
    
    };

    $fetch_outline->() if ! $outline;

    #
 
    my $get_client_timestamp = sub {
        # adapted from this JS:
        # var a = datetime.getCurrentTimeInMS() / 1E3 - this.dateJoinedTimestampInSeconds;    # / 1E3 should take it to seconds, I think
        # return Math.floor(a / 60)
        floor( ( time() - $date_joined ) / 60 );
    };

    my $local_create_node = sub {
        my %args = @_;
        my $parent_id = $args{parent_id} || $args{parent_node}->{id} or confess;
        my $new_node = $args{new_node} or confess;
        my $priority = $args{priority};  defined $priority or confess;
        my( $parent_node, $children ) = _find_node( $outline, $parent_id ) or confess "couldn't find node for $parent_id in edit in create_node";
        if( ! $children ) {
            if( $parent_id eq $shared_projectid ) {
                # root node
                $children = ( $outline->{rootProjectChildren} ||= [] );
            } else {
                $children = ( $parent_node->{ch} ||= [] );
            }
        }
        $priority = @$children if $priority > $#$children;
        splice @{ $children }, $priority, 0, $new_node;
        1;
    };

    my $local_edit_node = sub {
        my %args = @_;
        $args{node} ||= _find_node( $outline, $args{node_id} );
        my $node = $args{node} or confess "no node or node_id passed to local_edit_node, or can't find the node: " . Data::Dumper::Dumper \%args;
        exists $args{text} or confess;
        $node->{nm} = $args{text};
        $node->{lm} = $get_client_timestamp->();
        1;
    };

    my $local_delete_node = sub {
        my %args = @_;
        my $node_id = $args{node_id};
        $node_id = $args{node}->{id} if $args{node} and ! $node_id;
        $node_id or confess;
        my ( $parent_node, $node, $priority, $siblings ) = _find_parent($outline, $node_id );
        _filter_out( $siblings, $node_id );
        1;
    };

    my $local_move_node = sub {
        # XXX
        # executing ``move'' on data: $VAR1 = {
        #    'priority' => 0,
        #    'projectid' => 'acafae16-c8f0-b7a6-d44c-4672f68815da',
        #    'parentid' => 'c23ef558-3b78-cd2e-59df-7e578cded1e1'
        #  };
        my %args = @_;
        my $node_id = $args{node_id} or confess;
        my $parent_id = $args{parent_id} or confess;   # new parent
        my $priority = $args{priority};  defined $priority or confess;

        my $node = _find_node( $outline, $node_id ) or confess "couldn't find node for $node_id in local_move_node";

        # remove it from where it was
        $local_delete_node->( node_id => $node_id );

        # insert it where it's going
        $local_create_node->( parent_id => $parent_id, new_node => $node, priority => $priority, );

    };

    #

    my $update_outline = sub {

        # XXX currently only pushing changes up to workflowy, not merging in changes from workflowy; we have to re-fetch the outline to update our copy of it

        my %args = @_;
    
        my $cmd = delete $args{cmd};
        my $node_id = delete $args{node_id};
        my $text = delete $args{text};

        # for cmd=create and cmd=move
        my $parent_id = delete $args{parent_id};
        my $priority = delete $args{priority};

        # for cmd=move
        my $previous_parent_id = delete $args{previous_parent_id};
        my $previous_priority = delete $args{previous_priority};

        confess "unknown args to update_outline: " . join ', ', keys %args if keys %args;

        my $client_timestamp = $get_client_timestamp->();

        my $new_node_id; # set on cmd='create' # XXX should return the created/modified node

        if( $cmd eq 'edit' ) {

            my $node = _find_node( $outline, $node_id ) or confess "couldn't find node for $node_id in edit in update_outline";

            # queue the changes to get pushed up to workflowy

            push @$operations, {
                type => 'edit',
                client_timestamp => $client_timestamp,
                data => {
                    name      => $text,
                    projectid => $node_id,
                },
                undo_data => {
                    previous_last_modified => $node->{lm},
                    previous_name          => $node->{nm},
                },
            };

            $local_edit_node->( node => $node, text => $text );

        } elsif( $cmd eq 'move' ) {

            my $node = _find_node( $outline, $node_id ) or confess "couldn't find node for $node_id in move in update_outline";

            # queue the changes to get pushed up to workflowy

# [{"most_recent_operation_transaction_id":"186341078","operations":[{"type":"move","data":{"projectid":"1b3043b6-236d-dbd0-da7f-22c3cfcd1748","parentid":"0f60f496-5356-9040-72e6-2d3d5f94cd7c","priority":1},"client_timestamp":503732,"undo_data":{"previous_parentid":"0f60f496-5356-9040-72e6-2d3d5f94cd7c","previous_priority":4,"previous_last_modified":503353}}],"shared_projectid":"0af677e2-d205-22c8-bca6-2071a0e11ad7"}]

            push @$operations, {
                type => 'move',
                client_timestamp => $client_timestamp,
                data => {
                    projectid => $node_id,
                    parentid  => $parent_id,
                    priority  => $priority,
                },
                undo_data => {
                    previous_parentid => $previous_parent_id,
                    previous_priority => $previous_priority,
                },
            };

            $local_move_node->( node => $node, node_id => $node_id, parent_id => $parent_id, priority => $priority, );

        } elsif( $cmd eq 'create' ) {

            # my ( $parent_node, $node, $priority, $siblings) = _find_parent( $outline, $parent_id );
            # confess 'create cannot create additional root nodes' unless $parent_node;  # really, we can't, not even if we wanted to!  the array of siblings is faked up from the one root node ... but no, this can't happen, because the user is passing the parent's ID.  we don't want the parent's parent.

            my( $parent, $children ) = _find_node( $outline, $parent_id ) or confess "couldn't find node for $node_id in edit in update_outline";

            my $n_rand_chrs = sub {
                my $n = shift;
                join('', map { $_->[int rand scalar @$_] } (['a'..'z', 'A'..'Z', '0' .. '9']) x $n);
            };

            # 0da22641-65bf-9e96-70e7-dcc42c388cf3
            $new_node_id = join '-', map $n_rand_chrs->($_), 8, 4, 4, 4, 12;

            push @$operations, {
               type => 'create',
               undo_data => {},
               client_timestamp => $client_timestamp,
               data => {
                  priority  => $priority,
                  projectid => $new_node_id,
                  parentid  => $parent_id,
               },
            }, {
                type => 'edit',
                undo_data => {
                    previous_last_modified => $client_timestamp,
                    previous_name          => '',
                },
                client_timestamp => $client_timestamp,
                data => {
                    name      => $text,
                    projectid => $new_node_id,
                },
            };

            my $new_node = {
                id => $new_node_id,
                nm => $text,
                lm => $client_timestamp,
            };

            $local_create_node->( parent_node => $parent, new_node => $new_node, priority => $priority, );

        } elsif( $cmd eq 'delete' ) {

            my ( $parent_node, $node, $priority, $siblings ) = _find_parent($outline, $node_id );

            push @$operations, {
                undo_data => {
                    priority => $priority,
                    previous_last_modified => $node->{lm},
                    parentid => $parent_node ? $parent_node->{id} : 'None',
                },
                client_timestamp => $client_timestamp,
                type => 'delete',
                data => {
                    projectid => $node_id,   # the node id of the node being deleted; not the actual shared_projectid
                },
            };

            $local_delete_node->( node_id => $node_id );

        }

        #

        return $new_node_id;  # set if cmd = 'create'

    };

    #

    my $run_remote_operations = sub {
        my $run_ops = shift;
        $run_ops->{ops} or confess Data::Dumper::Dumper $run_ops;
        for my $op ( @{ $run_ops->{ops} } ) {

            my $type = $op->{type};
            my $data = $op->{data};

            if( $type eq 'create' ) {

                my $client_timestamp = $get_client_timestamp->();

                my $new_node = {
                    id => $data->{projectid},
                    nm => '',
                    lm => $client_timestamp,
                };

                my $parent_id = $data->{parentid};
                $parent_id = $shared_projectid if $parent_id eq 'None';

                $local_create_node->( parent_id => $parent_id, new_node => $new_node, priority => $data->{priority}, );
                
            } elsif( $type eq 'edit' ) {

                $local_edit_node->( node_id => $data->{projectid}, text => $data->{name}, );

            } elsif( $type eq 'delete' ) {

                $local_delete_node->( node_id => $data->{projectid}, );

            } elsif( $type eq 'move' ) {

                $local_move_node->( node_id => $data->{projectid}, parent_id => $data->{parentid}, priority => $data->{priority}, );

            }
        }

    };

    #

    my $sync_changes = sub {

        my $r = HTTP::Request->new( POST => "https://workflowy.com/push_and_poll" );
        $user_agent->cookie_jar->add_cookie_header( $r );

        $r->header( 'X-Requested-With' => 'XMLHttpRequest' );
        $r->header( 'Content-Type'     => 'application/x-www-form-urlencoded; charset=UTF-8' );
        $r->header( 'Referer'          => $workflowy_url );

        $last_transaction_id or confess "no value in last_transaction_id in sync_changes";

        my $push_poll_data = [{
            most_recent_operation_transaction_id => $last_transaction_id,
            # shared_projectid => $shared_projectid,
            operations => $operations,
        }];

        if( $share_id ) {
            $push_poll_data->[0]->{share_id} = $share_id; 
        } else {
            $push_poll_data->[0]->{shared_projectid} = $shared_projectid;
        }

        my $post = '';
        $post .= 'client_id=' . _escape($client_id);
        $post .= '&client_version=10';
        $post .= '&push_poll_id=' . join('', map { $_->[int rand scalar @$_] } (['a'..'z', 'A'..'Z', '0' .. '9']) x 8); # XX guessing; seems to work though
        $post .= '&shared_projectid=' . $shared_projectid;
        $post .= '&push_poll_data=' . _escape( encode_json( $push_poll_data ) );

        # warn "JSON sending: " . JSON::PP->new->pretty->encode( $push_poll_data );

        $r->content( $post );

        my $response = $user_agent->request($r);
        if( $response->is_error ) {
           confess "error: " . $response->error_as_HTML;
           return;
        }

        my $decoded_content = $response->decoded_content;

        my $result_json = decode_json $decoded_content;

        # "new_most_recent_operation_transaction_id": "106843573"
        # warn Data::Dumper::Dumper $result_json;

        # warn JSON::PP->new->pretty->encode( $push_poll_data ); # <--- good for debugging
        # warn JSON::PP->new->pretty->encode( $result_json );

        $result_json->{results}->[0]->{error} and die "workflowy.com request failed with an error: ``$result_json->{results}->[0]->{error}''; response was: $decoded_content\npush_poll_data is: " . JSON::PP->new->pretty->encode( $push_poll_data );

        $last_transaction_id = $result_json->{results}->[0]->{new_most_recent_operation_transaction_id} or confess "no new_most_recent_operation_transaction_id in sync changes\nresponse was: $decoded_content\npush_poll_data was: " . JSON::PP->new->pretty->encode( $push_poll_data );

        $polling_interval = ( $result_json->{results}->[0]->{new_polling_interval_in_ms} || 1000 )  / 1000; # XXX this was probably just undef when we ignored an error before the checking above was added
        $last_poll_time = time;

        #

        # $results->[*]->{server_run_operation_transaction_json} is what we already did to our own copy of the outline; not sure if we should double check

        # XXX call fetch_outline if the server sent us any deltas; or else attempt to mirror those changes

        my $run_operations = $result_json->{results}->[0]->{concurrent_remote_operation_transactions};
        for my $run_op ( @$run_operations ) {
            my $decoded_run_op = decode_json $run_op;
            $run_remote_operations->( $decoded_run_op );
        }

        #

        $operations = [];

    };

    #

    my $self = sub {

        my $action = shift;

        # important symbols

        $outline or confess "no outline";  # shouldn't happen
        $shared_projectid or confess "no shared_projectid"; # shouldn't happen

        if( $action eq 'edit' ) {
            my %args = @_;
            my $save_id = delete $args{save_id} or confess "pass a save_id parameter";
            my $text = delete $args{text} or confess "pass a text parameter";

            $update_outline->(
                cmd                     => 'edit',
                text                    => $text,
                node_id                 => $save_id,
            );

            return 1;
        }

# [{"most_recent_operation_transaction_id":"186341078","operations":[{"type":"move","data":{"projectid":"1b3043b6-236d-dbd0-da7f-22c3cfcd1748","parentid":"0f60f496-5356-9040-72e6-2d3d5f94cd7c","priority":1},"client_timestamp":503732,"undo_data":{"previous_parentid":"0f60f496-5356-9040-72e6-2d3d5f94cd7c","previous_priority":4,"previous_last_modified":503353}}],"shared_projectid":"0af677e2-d205-22c8-bca6-2071a0e11ad7"}]

        if( $action eq 'move' ) {

            my %args = @_;
            my $node_id = delete $args{node_id} or confess "pass a node_id parameter";
            my ( $parent_node, $node, $previous_priority, $siblings ) = _find_parent($outline, $node_id ) or confess "could not find node ``$node_id'' in ->move()";
            my $parent_id = delete $args{parent_id} || $parent_node->{id};   # useful if the user only wants to update the priority
            my $priority = delete $args{priority} || 0;  # useful if the user only wants to change the parent and is okay with it going to the head of the list

            return $update_outline->(
                cmd                     => 'move',
                node_id                 => $node_id,
                parent_id               => $parent_id,                 # for cmd=create
                priority                => $priority,                  # for cmd=create
                previous_parent_id      => $parent_node->{id},
                previous_priority       => $previous_priority,
            );

        }

        if( $action eq 'create' ) {

            # $update_outline returns the id of the newly created node for cmd='create'

            my %args = @_;
            my $parent_id = delete $args{parent_id};
            my $text = delete $args{text};
            my $priority = delete $args{priority};

            return $update_outline->(
                cmd                     => 'create',
                text                    => $text,
                parent_id               => $parent_id,                 # for cmd=create
                priority                => $priority,                  # for cmd=create
            );

        }

        if( $action eq 'delete' ) {
            my %args = @_;
            my $node_id = delete $args{node_id} or confess "pass a node_id parameter";

            $update_outline->(
                cmd                     => 'delete',
                node_id                 => $node_id,
            );

            return 1;

        }

        if( $action eq 'sync' ) {

            if( ( time - $last_poll_time ) < $polling_interval ) {
                return; 
            }

            $sync_changes->();

            return 1;
        }

        if( $action eq 'fetch' or $action eq 'read' or $action eq 'get' ) {
            # XXX reconcile this with sync
            $fetch_outline->();
            return 1;
        }

    };
}

sub edit { my $self = shift; $self->( 'edit', @_ ); }
sub move { my $self = shift; $self->( 'move', @_ ); }
sub create { my $self = shift; $self->( 'create', @_ ); }
sub delete { my $self = shift; my $node_id = ref($_[0]) ? $_[0]->{id} : $_[0]; $self->( 'delete', node_id => $node_id, ); }
sub sync { my $self = shift; $self->( 'sync', @_ ); }
sub fetch { my $self = shift; $self->( 'fetch', @_ ); }

sub find {
    # external API takes $self
    my $self = shift;
    my $cb = shift or confess "pass a callback";

    _find( $self->outline, $cb);
}

sub find_by_id {
    # external API takes $self
    my $self = shift;
    my $id = shift or confess "pass id";
    _find( $self->outline, sub { $_[0]->{id} eq $id } );
}

sub _find {
    my $outline = shift;
    my $cb = shift or confess "pass a callback";

    # $outline->{rootProject} points to the root node; $outline->{rootProjectChlidren} has its children; this is wonky; normally, $node->{ch} has a nodes children
    # temporarily put rootProjectChildren under rootProject so we can recurse through this nicely

    local $outline->{rootProject}->{ch} = $outline->{rootProjectChildren};
    my $fake_root = { lm => 0, nm => '', id => '0', ch => [ $outline->{rootProject} ], fake => 1, };

    return _find_inner( $fake_root, $cb, );
}


sub _find_inner {
    # there's no $self inside the coderef so stuff in there calls this directly
    my $node = shift;
    my $cb = shift or confess;
    my $stack = shift() || [ $node ];
    my $position = 0;
    for my $child ( @{ $node->{ch} } ) {
        return $child if $cb->( $child, $stack, $position );
        if( $child->{ch} ) {
            my $node = _find_inner( $child, $cb, [ @$stack, $child ], );
            return $node if $node;
        }
        $position++;
    }
}

sub _find_node {
    my $outline = shift;
    my $node_id = shift;

    my $node;
    my $children;  # since we temporarily attached the tree to the root node, $node->{ch} won't be valid if we return the root node

    _find( $outline, sub {
        my $child = shift;
        if( $child->{id} eq $node_id ) {
            $node = $child;
            $children = $node->{ch};
            return 1; # stop looking
        }
        return 0; # keep looking
    } );

   return wantarray ? ( $node, $children ) : $node;
}

sub _find_parent {
    my $outline = shift; # we want this
    my $node_id = shift;

    # return if $outline->{rootProject}->{id} eq $node_id;  # not an error, just no parent; rootProject->id is the same as $shared_projectid; should be redundant

    # $outline->{rootProject} points to the root node; $outline->{rootProjectChlidren} has its children; this is wonky; normally, $node->{ch} has a nodes children
    # temporarily put rootProjectChildren under rootProject so we can recurse through this nicely

    # $outline->{rootProject}->{ch} = $outline->{rootProjectChildren}; # _find doesthis now

    my $parent_node;
    my $node;
    my $priority;
    my $parents_children;  # since we temporarily attached the tree to the root node, $node->{ch} won't be valid if we return the root node

    _find( $outline, sub {
        my $child = shift;
        my @parent_nodes = @{ shift() };
        if( $child->{id} eq $node_id ) {
            $node = $child;
            $parent_node = @parent_nodes ? $parent_nodes[-1] : undef;
            $priority = shift;
            $parents_children = $parent_node->{ch};
            return 1; # stop looking
        }
        return 0; # keep looking
    } );

   # delete $outline->{rootProject}->{ch}; # _find handles this now

   $parent_node = undef if $parent_node->{fake};  # don't return our faked up root node

   return wantarray ? ( $parent_node, $node, $priority, $parents_children ) : $parent_node;

}

sub get_children {
    my $self = shift;
    my $node_id = shift or confess "pass a node id";
    (undef, my $children) = _find_node( $self->outline, $node_id ) or confess;
    return $children;
}

sub _filter_out {
    my $arr = shift or confess;
    my $node_id = shift or confess;
    for my $i ( 0 .. $#$arr ) {
        if( $arr->[$i]->{id} eq $node_id ) {
            splice @$arr, $i, 1, ();
            return 1;
        }
    }
}

sub dump {
    my $self = shift;

    my $output = '';

    $self->find( sub {
        my $child = shift;
        my @parent_nodes = @{ shift() };
        $output .= $child->{id} . '   ';
        $output .= '  ' x scalar @parent_nodes;
        $output .= $child->{nm} . "\n";
        0;
    } );

    return $output;

}

sub _escape {
    my $arg = shift;
    $arg =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    $arg;
}


=head1 SEE ALSO

=head1 BUGS

Remote changes are not merged with forgiveness.  For example, if you delete a node, someone else edits the node concurrently, and then you do a 
C<sync> operation, L<WWW::Workflowy> will blow up when it can't find the node to edit.  Forgiveness should be optional.

L<Workflowy> versions their protocol.  This module targets C<10>.  The protocol is not a documented API.  This module will likely stop working without
notice.  This module does things like parse out JSON from JavaScript code using regexen.

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

#
# pasted in copy of my hacked up autobox::Attribute::Closures
#



1;

__DATA__
