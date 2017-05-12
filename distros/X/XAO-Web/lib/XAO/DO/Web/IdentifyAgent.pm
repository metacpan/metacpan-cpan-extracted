=head1 NAME

XAO::DO::Web::IdentifyAgent - class for agent (i.e. browser) identification.

=head1 SYNOPSYS

 <%IdentifyAgent%>

=head1 DESCRIPTION

The 'IdentifyAgent' class is used for agent identification purposes. It
relies on some site configuration values which are available in the form
of a reference to a hash. An example of this hash with all possible
parameters is presented below, it should be stored in the site
configuration under '/identify_agent':

 cb_uri           => 'IdentifyAgent', #opt., default is '/IdentifyAgent'
 id_cookie        => 'id_agent',      #optional, default is 'agent_id'
 id_cookie_expire => 126230400,       #optional, default is 4y
 list_uri         => '/Browsers',     #optional, see below
 access_time_prop => 'latest_access', #required if 'list_uri' present
 list_expire      => 126230400,       #opt., default is 'id_cookie_expire'

When a given 'IdentifyAgent' object is instantiated, it first checks the
clipboard to determine if there is an agent id present, indicating that
the agent has already been identified in the current session. If so, the
work here is done.

If the agent has not already been identified, it checks whether there
is a cookie named as 'id_cookie' parameter value ('id_agent' in
example). If there is, the value of this cookie is the agent ID and
saves to the clipboard. Otherwise, cookie is set to a unique agent ID
value. The expiration time is set to 'id_cookie_expire' value if it is
present and to 4 years otherwise.

Once the agent cookie is retrieved or an unique agent ID is generated
for setting a new agent cookie a call is made to an 'IdentifyAgent'
method called 'save_agent_id()'. This method first checks if there is
a 'list_uri' parameter. If 'list_uri' is present then the agent ID
is saved to this list, using agent ID as the list's key unless an
entry for the agent already exists in the list. Otherwise, nothing is
saved. Whenever saving an agent to the list, the access time is also
saved in the database. Saving the access time also happens every time
the agent is identified by a cookie.

Agent object is stored to clipboard under 'object' name if there is a
'list_uri' parameter. Otherwise, agent object remains undefined and only
agent ID is stored under 'name' name.

=head1 METHODS

There are two methods available only. First of them is overriden display
method that displays nothing but identifies user agent. And last of them
is save_agent_id. See description below.

=over

=cut

package XAO::DO::Web::IdentifyAgent;
use strict;
use XAO::Utils qw(:debug :keys);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: IdentifyAgent.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item display (%)

Method displays nothing :-) but identifies user agent

=cut

sub display($){
	my $self=shift;
	my $config=$self->siteconfig->get('/identify_agent');
	my $clipboard_uri=$config->{cb_uri} || "/IdentifyAgent";

	# Checking the clipboard to determine if there is an agent id present.
	# If so, the work here is done.
    #
	return if $self->clipboard->get("$clipboard_uri/name");

    # Checking cookie named 'id_cookie' and trying to save whatever we
    # got. Saving method should be careful to check for valid IDs and so
    # on.
    #
    # On return save methods gives us saved object.
    #
    my $id_cookie=$config->{id_cookie} || 'agent_id';
	my $agent_id=$self->siteconfig->get_cookie($id_cookie);
    my $agent_object=$self->save_agent_id($agent_id);
    if($agent_object) {
        $agent_id=$agent_object->container_key;
    }
    elsif(!$agent_id) {
        $agent_id=generate_key();
    }

    ##
    # Storing into clipboard
    #
	$self->clipboard->put("$clipboard_uri/name" => $agent_id);
    $agent_object &&
        $self->clipboard->put("$clipboard_uri/object" => $agent_object);

    dprint "IdentifyAgent(id=$agent_id, object=$agent_object)";

    ##
    # Setting cookie
    #
	my $expire=$config->{id_cookie_expire} ? "+$config->{id_cookie_expire}s"
                                           : "+4y";
	$self->siteconfig->add_cookie(
        -name    => $id_cookie,
        -value   => $agent_id,
        -path    => '/',
        -expires => $expire,
    );
}

##############################################################################

=item save_agent_id ($$)

Method saves agent ID to database if 'list_uri' parameter
present. Returns agent object or undef. May be overriden if more
sophisticated agent data storage is required.

=cut

sub save_agent_id ($$){
    my $self=shift;
    my $id=shift;
    my $config=$self->siteconfig->get('/identify_agent');

    ##
    # Checking whether there is a 'list_uri' parameter.
    #
    my $list_uri=$config->{list_uri};
    my $at_prop=$config->{access_time_prop};
    return undef unless $list_uri && $at_prop;

    ##
    # Agent id is saved to the list and current time is saved to access
    # time property. We check if the given ID is valid and existing.
    #
    my $list=$self->odb->fetch($list_uri);
    if($id && $list->check_name($id) && $list->exists($id)) {
        my $agent=$list->get($id);
        $agent->put($at_prop => time);
        return $agent;
    }

    ##
    # If there is no ID or ID is not good
    #
    my $agent=$list->get_new();
    $agent->put($at_prop => time);
    return $list->get($list->put($agent));
}

##############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2003-2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2001,2002 XAO, Inc.

Ilya Lityuga <ilya@boksoft.com>, Marcos Alves <alves@xao.com>,
Andrew Maltsev <am@xao.com>

=head1 SEE ALSO

Recommended reading:

L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::FS>,
