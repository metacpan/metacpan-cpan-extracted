=head1 NAME

XAO::DO::Web::IdentifyUser - class for user identification and verification

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

!!XXX!!TODO!! - document key_list_uri and multi-key logons in general!

IdentifyUser class is used for user identification and verification
purposes. In 'login' mode it logs a user in while in 'logout' mode, it
logs a user out. In 'check' mode it determines the identification status
of the user using cookies.

Possible user identification status are:

=over

=item * anonymous - user cannot be identified

=item * identified - user has been identified

=item * verified - user has recently been positively identified

=back

The 'IdentifyUser' class takes the following parameters:

=over 4

=item * mode

Indicates how 'IdentifyUser' will be used. Possible values are

=over 12

=item - check: (default) check the identification status

=item - login: log user in

=item - logout: Log current user out

=back

=item * anonymous.path

Template to display if user has not been identified.

=item * identified.path

Template to display if user has been identified, but not verified.

=item * verified.path

Template to display if user has been identified.

=item * hard_logout

If 'true' in logout mode, this parameter not only unverifies the
user, but erases identification cookies too. The default is to retain
identified status.

=item * stop

Directive indicating that if a specified template is displayed, the
remainder of the current template must not be displayed.

=back

The 'IdentifyUser' class relies on some site configuration values. These
values are available in the form of a reference to a hash obtained as
follows:

 my $config=$page->siteconfig->get('identify_user');

where $page is a 'Page' object. The keys of such a hash correspond to
the 'type' parameter of the 'IdentifyUser' class. An example of a
$config hash with all required parameters is presented below:

 customer => {
    list_uri            => '/Customers',
    id_cookie           => 'id_customer',
    id_cookie_expire    => 126230400,       # (seconds) optional,
                                            # default is 10 years
    id_cookie_type      => 'name',          # optional, see below
    user_prop           => 'email',         # optional, see below
    alt_user_prop       => 'logname',       # deprecated, see below
    pass_prop           => 'password',
    pass_encrypt        =>  'md5',          # optional, see below
    vf_key_prop         => 'verify_key',    # optional, see below
    vf_key_cookie       => 'key_customer',  # optional, see below
    vf_time_prop        => 'verify_time',   # time of last verification
    vf_expire_time      => '600',           # seconds
    cb_uri              => 'IdentifyUser/customer' # optional
 }

=over

=item list_uri

URI of users list (see L<XAO::FS> and L<XAO::DO::FS::List>).

=item id_cookie

Name of cookie that IdentifyUser sets to identificate the user in the
future

=item id_cookie_expire

Expiration time for the identification cookie (default is 4 years).

=item id_cookie_type

Can be either 'name' (default), 'key', or 'id'. Determines what is
stored in the cookie on the client browser's side -- in 'name' mode it
stores user name (possibly different in caseness from what was entered
on login form), in 'key' mode it stores the key within 'key_list_uri',
and in 'id' mode the internal id (container_key) of the user object is
stored.

Downside to storing names is that some browsers fail to return
exactly the stored value if it had international characters in the
name. Downside to storing IDs is that you expose a bit of internal
structure to the outside world. Usually its harmless though.

If 'user_prop' is not used then it does not matter, as the name and id
are the same thing.

=item user_prop

Name attribute of a user object. If there is no 'user_prop' parameter in
the configuration it is assumed that user ID is the key for the given
list.

An interesting capability is to specify name as a URI style path, for
instance if a member has many alternative names that all can be used to
log-in and these names are stored in a list called Nicknames on each
member object, then the following might be used:

 user_prop => 'Nicknames/nickname'

See below for how to access deeper objects and ids (the object in
'Nicknames' list in that case).

It is possible to set user_prop to an array reference. In that case
each element of the array is assumed to be a potential key. They are
checked in order they are listed and if exactly one match is found
(with user_condition in effect) then this is the user whose password is
checked.

This is useful to let users log in with either an email or a log name
for example.

=item alt_user_prop

If this is given then on login the username is checked against this
database property. If there is exactly one match it is used, otherwise
(no matches or multiple matches) the logic goes back to user_prop, etc.

Using this is deprecated -- pass an array reference to user_prop
instead.

=item user_condition

This is an optional condition that if present must be satisfied for user
name to match user prop. The condition is added with an 'and' to the
user_prop search similarly to this:

    $list->search(
        [ $user_prop,'eq',$user_name ],
        'and',
        $user_condition
    );

This can be used to narrow down the entities in the list that are
supposed to be able to log in. For instance if the same list contains
customers of different types with different login schemas.

The 'user_condition' argument can be an array (directly passed into
search), or a hash. If it is a hash then the keys are user_prop values,
and the values are user conditions. This can be used to set different
conditions for different user props.

To avoid checking user_condition a non-zero 'skip_user_condition'
argument can be passed to login().

=item pass_prop

Password attribute of user object.

=item pass_encrypt

Encryption method for the password. The value can be one or more comma
separated algorithm tags. The password in login() is checked against
each in order (unless the stored password has a specific algorithm
code embedded in it, as do all digest algorithm password built with
data_password_encrypt() call).

Available algorithms:

    'bcrypt'      - bcrypt digest with salt & cost support (recommended)
    'sha256'      - SHA-256 digest
    'sha1'        - SHA-1 digest
    'md5'         - MD5 digest (deprecated, do not use)
    'crypt'       - system crypt() call (do not use)
    'custom'      - use login_password_encrypt() call
                    that must be overridden in a derived object
    'plaintext'   - no encryption at all, plain text (default)

In most situations using 'bcrypt' is a good choice. The default cost
parameter is 8, can be changed with pass_encrypt_cost.

Sha256, Sha1, and md5 do not support "cost", can be easily
hardware-accelerated, and as such are not recommended.

When creating a database record use data_password_encrypt() to properly
encrypt a password.

=item pass_encrypt_cost

This parameter is currently only used in 'bcrypt' mode. See the
explanation in L<Digest::Bcrypt::cost()> method. On an Intel i5-4670K
CPU @ 3.40GHz the default cost 8 results in about 15ms per password
encryption.

=item pass_pepper

An optional string that is added to passwords when they are encrypted.
The actual encrypted password would use a combination of a random "salt"
(stored with the password), a static "pepper" (not stored with the
password), and the password itself.

The point of adding a pepper value is to make the database content alone
not be enough to crack passwords unless the site code/config is also
known. This adds an extra protection layer in case the database content
is stolen, but the site code is not.

=item vf_key_prop

The purpose of two optional parameters 'vf_key_cookie' and 'vf_key_prop'
is to limit verification to just one computer at a time. When
these parameters are present in the configuration on login success
'IdentifyUser' object generates random key, stores it into user's
profile, and creates a cookie named according to 'vf_key_cookie' with
the value of the generated key.

=item vf_key_cookie

Temporary verifiction key cookie.

=item vf_time_prop

Attribute of user object which stores the time of latest verified access.

=item vf_expire_time

Time period for which user remains verified.

Please note, that the cookie with the customer key will be set to expire
in 10 years and actual expiration will only be checked using the content
of 'vf_time_prop' field value. The reason for such behavior is that many
(if not all) versions of Microsoft IE have what can be considered a
serious bug -- they compare the cookie expiration time to the local time
on the computer. And therefore if customer computer is accidentally set
to some future date the cookie might expire immediately and prevent this
customer from logging into the system at all. Most (if not all) versions
of Netscape and Mozilla do not have this problem.

Therefore, when possible we do not trust customer's computer to measure
time for us and do that ourselves.

=item cb_uri

URI of clipboard where IdentifyUser stores identification and
verification information about user and makes it globally available.

=back

=head1 RESULTS

In addition to displaying the correct template, results of user
verification or identification are stored in the clipboard. Base
clipboard location is determined by 'cb_uri' configuration parameter and
defaults to '/IdentifyUser/TYPE', where TYPE is the type of user.

Parameters that are stored into the clipboard are:

=over

=item id

The internal ID of the user object (same as returned by container_key()
method on the object).

=item name

Name as used in the 'login' mode. If 'user_prop' configuration parameter
is not used then it is always the same as 'id'.

=item object

Reference to the user object loaded from the database.

=item verified

This is only set when user has 'verified' status.

=back

Additional information will also be stored if 'user_prop'
refers to deeper objects. For example, if user_prop is equal to
'Nicknames/nickname' then it is assumed that there is a list inside
of user objects called Nicknames and there is a property in that list
called 'nickname'. It is also implied that the 'nickname' is unique
throughout all objects of its class.

Information that gets stored in the clipboard in that case is:

=over

=item list_prop

Name of the list property of the user object that is used in
'user_prop'. In our example it will be 'Nicknames'.

=item Nicknames (only for the example above)

Name of the list property is used to store a hash containing 'id',
'object' and probably 'list_prop' for the next object in the 'user_prop'
path (although in practice it is hard to imagine a situation where more
then one level is required).

=back

=head1 EXAMPLES

Now, let us look at some examples that show how each mode works.

=head2 LOGIN MODE

 <%IdentifyUser mode="login"
   type="customer"
   username="<%CgiParam param="username" %>
   password="<%CgiParam param="password" %>
   anonymous.path="/bits/login.html"
   verified.path="/bits/thankyou.html"
 %>

=head2 LOGOUT MODE

 <%IdentifyUser mode="logout"
   type="customer"
   anonymous.path="/bits/thankyou.html"
   identified.path="/bits/thankyou.html"
   hard_logout="<%CgiParam param="hard_logout" %>"
 %>

=head2 CHECK MODE

 <%IdentifyUser mode="check"
   type="customer"
   anonymous.path="/bits/login.html"
   identified.path="/bits/order.html"
   verified.path="/bits/order.html"
 %>

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Web::IdentifyUser;
use strict;
use Data::Entropy::Algorithms qw(rand_bits);
use Digest::Bcrypt qw();
use Digest::MD5 qw(md5_base64);
use Digest::SHA qw(sha1_base64 sha256_base64);
use Error qw(:try);
use MIME::Base64 qw(encode_base64 decode_base64);
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::IdentifyUser);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
$VERSION=2.16;

###############################################################################

sub check_mode($;%);
sub check ($@);
sub before_display ($@);
sub display_results ($$$;$);
sub _get_user_props($$$);
sub find_user ($$$;$);
sub login_errstr ($@);
sub login ($;%);
sub login_password_encrypt ($@);
sub login_check ($%);
sub logout ($@);
sub data_password_check ($@);
sub data_password_encrypt ($@);
sub _get_config ($@);
sub verify_check ($%);

###############################################################################

=item check_mode (%)

Checks operation mode and redirects to a method accordingly.

=cut

sub check_mode($;%){
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{'mode'} || 'check';

    if($mode eq 'check') {
        $self->check($args);
    }
    elsif($mode eq 'login') {
        $self->login($args);
    }
    elsif($mode eq 'logout') {
        $self->logout($args);
    }
    else {
        throw $self "- no such mode '$mode'";
    }
}

##############################################################################

=item check ()

Checks identification/verification status of the user.

To determine identification status, first check clipboard to determine
if there is such object present. If so, then that object identifies the
user.

If not, then depending on 'id_cookie_type' parameter (that defaults to
'name') check whether there is an identification cookie or key cookie
and if so, perform a search for object in database. If this search
yields a positive result, the user's status is 'identified' and an
attempt to verify user is made, otherwise the status is 'anonymous'.

Identification by key only works when keys are stored in a separate list.

Once identity is established, to determine verification status, first
check the clipboard to determine if there is a 'verified' flag set. If
so, then the user's status is 'verified'. If not, check whether the
difference between the current time and the time of the latest visit is
less than vf_expire_time property. If so, the user status considered
'verified', a new time is stored.

If optional 'vf_key_prop' and 'vf_key_cookie' parameters are present in
the configuration then one additional check must be performed before
changing status to 'verified' - the content of the key cookie and
apropriate field in the user profile must match.

=cut

sub check ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my ($config,$type)=$self->_get_config($args);

    my $clipboard=$self->clipboard;

    my $cookie_domain=$config->{'domain'};

    # These are useful for both verification and identification cookies.
    #
    my $vf_time_prop=$config->{'vf_time_prop'} ||
        throw $self "No 'vf_time_prop' in the configuration";
    my $current_time=time;
    my $last_vf;

    # Checking if we already have user in the clipboard. If not -- checking
    # the cookie and trying to load from the database.
    #
    my $cb_uri=$config->{'cb_uri'} || "/IdentifyUser/$type";
    my $id_cookie_type=$config->{'id_cookie_type'} || 'name';
    my $key_list_uri=$config->{'key_list_uri'};
    my $key_ref_prop=$config->{'key_ref_prop'};

    my $data=$clipboard->get($cb_uri);
    my $user=$data ? $data->{'object'} : undef;
    my $key_object=$data ? $data->{'key_object'} : undef;

    if(!$data || !$user) {
        $data=undef;

        my $id_cookie=$config->{'id_cookie'} ||
            throw $self "- no 'id_cookie' in the configuration";

        my $cookie_value=$self->siteconfig->get_cookie($id_cookie);

        if(!$cookie_value) {
            return $self->display_results($args,'anonymous');
        }

        my $list_uri=$config->{'list_uri'} ||
            throw $self "- no 'list_uri' in the configuration";

        # With key we may have multiple logins from the same user at the
        # same time. Finding the specific key and verifying.
        #
        if($id_cookie_type eq 'key') {
            $key_list_uri || throw $self "- key_list_uri required";
            $key_ref_prop || throw $self "- key_ref_prop required";

            my $user_list=$self->odb->fetch($list_uri);
            my $key_list=$self->odb->fetch($key_list_uri);
            my $user_id;
            my $user_obj;
            try {
                $key_list->check_name($cookie_value) ||
                    throw $self "- invalid cookie value";

                $key_object=$key_list->get($cookie_value);

                ($user_id,$last_vf)=$key_object->get($key_ref_prop,$vf_time_prop);

                $user_obj=$user_list->get($user_id);
            }
            otherwise {
                my $e=shift;
                dprint "IGNORED(OK): $e";
            };

            $user_obj || return $self->display_results($args,'anonymous');

            $data={
                object          => $user_obj,
                id              => $user_id,
                name            => $cookie_value,
                key_object      => $key_object,
            };
        }

        # When cookie is based on ID we can't use find_user() as the
        # value in cookie is not the same as what was given in login.
        #
        elsif($id_cookie_type eq 'id') {
            my $list=$self->odb->fetch($list_uri);

            # This works for both deep paths and single IDs.
            #
            my @ids=split(/\/+/,$cookie_value);

            my $user_props=$self->_get_user_props($config,$list);

            foreach my $user_prop (@$user_props) {
                my @names=split(/\/+/,$user_prop);

                next unless scalar(@names)==scalar(@ids);

                my %d;

                try {
                    my $obj;
                    my $dref=\%d;

                    for(my $i=0; $i!=@names; $i++) {
                        my $name=$names[$i];
                        my $id=$ids[$i];

                        my $obj=$list->get($id);

                        $dref->{'object'}=$obj;
                        $dref->{'id'}=$id;

                        $list=$obj->get($name);

                        if(ref $list) {
                            $dref->{'list_prop'}=$name;
                            $dref=$dref->{$name}={};
                        }
                        else {
                            $d{'name'}=$list;
                        }
                    }
                }
                otherwise {
                    my $e=shift;
                    dprint "IGNORED(OK): $e";
                    %d=();
                };

                if($d{'object'}) {
                    $d{'property'}=$user_prop;
                    $data=\%d;
                    last;
                }
            }
        }
        elsif($id_cookie_type eq 'name') {
            $data=$self->find_user($config,$cookie_value,$args->{'skip_user_condition'});
        }
        else {
            throw $self "- unknown id_cookie_type ($id_cookie_type)";
        }

        if(!$data) {
            return $self->display_results($args,'anonymous');
        }

        # This is mostly useful for multi-key logins
        #
        $data->{'cookie_value'}=$cookie_value;

        # Saving identified user to the clipboard
        #
        $clipboard->put($cb_uri => $data);
        $user=$data->{'object'};

        # Updating cookie
        #
        my $id_cookie_expire=$config->{'id_cookie_expire'} || 4*365*24*60*60;
        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => $cookie_value,
            -path    => '/',
            -expires => '+' . $id_cookie_expire . 's',
            -domain  => $cookie_domain,
        );
    }

    # Checking clipboard to determine if 'verified' flag is set and
    # if so user's status is 'verified'.
    #
    my $verified=$clipboard->get("$cb_uri/verified");
    if(!$verified) {
        my $vcookie;

        # If we have a list of keys find the key that belongs to this
        # browser. If there is not one, assume at most 'identified'
        # status.
        #
        my $vf_key_cookie=$config->{'vf_key_cookie'};
        my $key_expire_ext_prop=$config->{'key_expire_ext_prop'};
        my $extended;
        if(!$key_list_uri) {
            $last_vf=$user->get($vf_time_prop);
        }
        else {
            if(!$key_object) {
                $vf_key_cookie ||
                    throw $self "- either vf_key_cookie or id_cookie_type=key required for key_list_uri";

                my $key_list=$self->odb->fetch($key_list_uri);

                my $key_id=$self->siteconfig->get_cookie($vf_key_cookie);

                if($key_id && $key_list->check_name($key_id)) {
                    try {
                        $key_object=$key_list->get($key_id);
                    }
                    otherwise {
                        my $e=shift;
                        dprint "IGNORED(OK): $e";
                        $key_object=undef;
                    };
                }
            }

            if(!$key_object) {
                $last_vf=0;
            }
            else {
                my ($key_user_id,$key_last_vf);

                if($key_expire_ext_prop) {
                    ($key_user_id,$key_last_vf,$extended)=$key_object->get($key_ref_prop,$vf_time_prop,$key_expire_ext_prop);
                    $data->{'extended'}=$extended;
                }
                else {
                    ($key_user_id,$key_last_vf)=$key_object->get($key_ref_prop,$vf_time_prop);
                }

                if($key_user_id eq $user->container_key) {
                    $last_vf=$key_last_vf;
                }
                else {
                    $key_object=undef;
                    $last_vf=0;
                }
            }

            $clipboard->put("$cb_uri/key_object" => $key_object);
        }

        # Checking the difference between the current time and the time
        # of last verification
        #
        my $vf_expire_time=$config->{'vf_expire_time'} ||
            throw $self "No 'vf_expire_time' in the configuration";

        my $vf_expire_ext_time=$config->{'vf_expire_ext_time'} || 0;

        $vf_expire_time=$vf_expire_ext_time if $extended && $vf_expire_ext_time;

        if($last_vf && $current_time - $last_vf <= $vf_expire_time) {

            # If optional 'vf_key_prop' and 'vf_key_cookie' parameters
            # are present checking the content of the key cookie and
            # appropriate field in the user profile
            #
            if(!$key_list_uri && $config->{'vf_key_prop'} && $vf_key_cookie) {
                my $web_key=$self->siteconfig->get_cookie($vf_key_cookie) || '';
                my $db_key=$user->get($config->{'vf_key_prop'}) || '';
                if($web_key && $db_key eq $web_key) {
                    $verified=1;

                    $vcookie={
                        -name    => $config->{'vf_key_cookie'},
                        -value   => $web_key,
                        -path    => '/',
                        -expires => '+4y',
                        -domain  => $cookie_domain,
                    };
                }
            }
            else {
                $verified=1;
            }
        }

        # Calling external overridable function to check if it is OK to
        # verify that user.
        #
        if($verified) {
            my $errstr=$self->verify_check(
                args    => $args,
                object  => $user,
                type    => $type,
            );
            if(!$errstr) {
                $clipboard->put("$cb_uri/verified" => 1);

                if($key_object) {
                    my $key_expire_prop=$config->{'key_expire_prop'} ||
                        throw $self "- key_expire_prop required";

                    $key_object->put(
                        $vf_time_prop       => $current_time,
                        $key_expire_prop    => $current_time+$vf_expire_time,
                    );

                    if($config->{'vf_time_user_prop'}) {
                        $user->put($config->{'vf_time_user_prop'} => $current_time);
                    }
                }
                else {
                    $user->put($vf_time_prop => $current_time);
                }
                if($vcookie) {
                    $self->siteconfig->add_cookie($vcookie);
                }
            }
            else {
                $verified=0;
            }
        }
    }

    # If we failed to verify we remove the verification cookie.
    # That might help better track verification from browser side
    # applications and should not hurt anything else.
    #
    my $expire_mode=$config->{'expire_mode'} || 'keep';
    if(!$verified && $expire_mode eq 'clean') {
        if($id_cookie_type eq 'key') {
            $self->siteconfig->add_cookie(
                -name    => $config->{'id_cookie'},
                -value   => 0,
                -path    => '/',
                -expires => '-1d',
                -domain  => $cookie_domain,
            );
        }
        elsif($config->{'vf_key_cookie'}) {
            $self->siteconfig->add_cookie(
                -name    => $config->{'vf_key_cookie'},
                -value   => 0,
                -path    => '/',
                -expires => '-1d',
                -domain  => $cookie_domain,
            );
        }
    }

    # Displaying results
    #
    my $status=$verified ? 'verified' : 'identified';

    $self->display_results($args,$status);
}

##############################################################################

=item before_display (%)

Overridable method that gets called just before displaying results after
all checks are done. Parameters it gets are:

 status     - one of 'anonymous', 'identified', or 'verified'
 type       - user type
 cbdata     - reference to clipboard data for the user
 config     - reference to the config for the user
 errstr     - error string, only available when called as part of login

Typically the method is used to add some other useful data to the
clipboard on successful checks and logins. By default does nothing.

=cut

sub before_display ($@) {
    return;
}

##############################################################################

=item display_results ($$;$)

Displays template according to the given status. Third optinal parameter
may include the content of 'ERRSTR'.

=cut

sub display_results ($$$;$) {
    my ($self,$args,$status,$errstr)=@_;

    my ($config,$type)=$self->_get_config($args);

    my $cb_uri=$config->{'cb_uri'} || "/IdentifyUser/$type";
    my $clipboard=$self->clipboard;

    $self->before_display(
        type        => $type,
        config      => $config,
        cbdata      => $clipboard->get($cb_uri) || { },
        status      => $status,
        errstr      => $errstr,
    );

    if($args->{"$status.template"} || $args->{"$status.path"}) {
        my $page=$self->object;
        $page->display($args,{
            path        => $args->{"$status.path"},
            template    => $args->{"$status.template"},
            CB_URI      => $cb_uri || '',
            ERRSTR      => $errstr || '',
            TYPE        => $type,
            NAME        => $clipboard->get("$cb_uri/name") || '',
            VERIFIED    => $clipboard->get("$cb_uri/verified") || '',
        });

        $self->finaltextout('') if $args->{'stop'};
    }
}

###############################################################################

sub _get_user_props($$$) {
    my ($self,$config,$list)=@_;

    my $user_props=$config->{'user_props'} || $config->{'user_prop'};

    # The default user name property is the list object key.
    #
    if(!$user_props) {
        my $obj=$list->get_new;
        my @x=grep { $obj->describe($_)->{'type'} eq 'key' } ($obj->keys);

        @x==1 || throw $self "- keyless list '".$list->uri."'";

        $user_props=\@x;
    }

    # User prop is a scalar or an array
    #
    if(!ref $user_props) {
        $user_props=[$user_props];
    }

    # This is a (deprecated) optional parameter to make it possible for
    # users to log in using this property as well as the default method.
    #
    my $alt_user_prop=$config->{'alt_user_prop'};
    if($alt_user_prop) {
        ref $alt_user_prop && throw $self "- 'alt_user_prop' needs to be a scalar";

        unshift(@$user_props,$alt_user_prop);
    }

    return $user_props;
}

##############################################################################

=item find_user ($$;$)

Searches for the user in the list according to the configuration:

    my $data=$self->find_user($config,$username);

Sets the same parameters in the returned hash as stored in the clipboard
except 'verified'.

=cut

sub find_user ($$$;$) {
    my ($self,$config,$username,$skip_user_condition)=@_;

    my $list_uri=$config->{'list_uri'} ||
        throw $self "- no 'list_uri' in the configuration";

    my $list=$self->odb->fetch($list_uri);

    my $user_props=$self->_get_user_props($config,$list);

    # We may optionally get a user selection condition in case the same
    # list contains elements not supposed to be used for log ins.
    #
    my $user_condition=$skip_user_condition ? undef : $config->{'user_condition'};

    # Finding the user.
    #
    foreach my $user_prop (@$user_props) {

        my $cond=[$user_prop,'eq',$username];

        # The user condition can be a hash or an array
        #
        my $ucond=$user_condition;
        if($ucond && ref($ucond) eq 'HASH') {
            $ucond=$ucond->{$user_prop};
        }
        if($ucond) {
            $cond=[$cond,'and',$ucond];
        }

        my $sr=$list->search($cond,{
            result => [ '#id',$user_prop ],
        });

        # Found?
        #
        if(@$sr==1) {
            my $obj=$list->get($sr->[0]->[0]);

            # Real username can be different even though we used
            # 'eq' to get to it (if props are not case sensitive).
            #
            my $real_username=$sr->[0]->[1];

            if($config->{'id_case_sensitive'}) {
                if($real_username ne $username) {
                    eprint "Case difference between '$real_username' and '$username'";
                    return undef;
                }
            }
            else {
                $username=$real_username;
            }

            my $result={
                object      => $obj,
                id          => $obj->container_key,
                name        => $username,
                property    => $user_prop,
            };

            # For deep level props (Nicknames/nickname) we need to
            # provide the path to the final object on the returned data.
            #
            # For Nicknames/nickname matching on "foo" we return:
            #
            #   list_prop   => Nicknames
            #   Nicknames   => {
            #       "object" => "nickname object",
            #       "id"     => "nickname object"->container_key,
            #   }
            #
            if($user_prop=~/\//) {
                if($ucond) {
                    throw $self "- deep user_prop ($user_prop) is not supported with user_condition";
                }

                my @p=split(/\/+/,$user_prop);

                $list=$obj->get($p[0]);

                $result->{'list_prop'}=$p[0];
                my $d=$result->{$p[0]}={};

                for(my $i=1; $i<@p; ++$i) {
                    my $prop=join('/',@p[$i...$#p]);

                    ### dprint ".searching i=$i '$username' in '$prop'";

                    my $psr=$list->search($prop,'eq',$username);
                    @$psr==1 ||
                        throw $self "- internal logic problem: no '$username' in '$prop' of '$user_prop'";

                    my $id=$psr->[0];
                    $d->{'id'}=$id;
                    $d->{'object'}=$list->get($id);

                    if($i!=$#p) {
                        my $name=$p[$i];
                        $d->{'list_prop'}=$name;
                        $d=$d->{$name}={};
                    }
                }
            }

            ### use JSON;
            ### dprint ''.(JSON->new->allow_unknown->allow_blessed->pretty->encode($result));

            return $result;
        }

        # More than one match? This is typically not a good sign, warning.
        #
        elsif(@$sr>1) {
            eprint "More than one match on '$user_prop' with '$username'";
        }
    }

    # Not found after all props?
    #
    return undef;
}

###############################################################################

=item login_errstr ($)

Overridable method to translate login error codes to human readable
strings. Can be used to for example translate messages into other
languages.

Receives the following arguments:

    type    => user type
    object  => user object (or undef if not known)
    errcode => one of NO_INFO, NO_PASSWORD, BAD_PASSWORD, FAIL_LOCKED

=cut

our %login_errstr_table=(
    NO_INFO         => 'No information found',
    NO_PASSWORD     => 'No password given',
    BAD_PASSWORD    => 'Password mismatch',
    FAIL_LOCKED     => 'The account is temporarily locked',
);

sub login_errstr ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $errcode=$args->{'errcode'};
    $errcode || eprint "login_errstr - no 'errcode' given";

    my $errstr=$login_errstr_table{$errcode};
    if(!$errstr) {
        eprint "login_errstr - untranslatable error code '$errcode'";
        $errstr=$errcode;
    }

    return $errstr;
}

##############################################################################

=item login ()

Logs in user. Saves current time to vf_time_prop database field.
Generates pseudo unique key and saves its value into either vf_key_prop
or creates a record in key_list_uri. Sets identification cookies
accordingly.

There is a parameter named 'force' that allows to log in a user without
checking the password. One should be very careful not to abuse this
possibility! For security reasons 'force' will only have effect when
there is no 'password' parameter at all.

If an 'extended' parameter is present and is true, then the key is
marked as extended with a potentially longer expiration time. This
requires a configuration support as well (without configuration the
presense of 'extended' is ignored):

    vf_expire_time_ext  => extended expiration period
    key_expire_ext_prop => db property where to store extended flag

'Extended' option is only supported with multiple keys per user
('key_list_uri' option).

=cut

sub login ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my ($config,$type)=$self->_get_config($args);

    my $extended=$args->{'extended'} || 0;

    my $id_cookie=$config->{'id_cookie'} ||
        throw $self "- no 'id_cookie' in the configuration";

    my $id_cookie_type=$config->{'id_cookie_type'} || 'name';

    my $cookie_domain=$config->{'domain'};

    # Looking for the user in the database
    #
    my $username=$args->{'username'} ||
        throw $self "- no 'username' given";

    my $data=$self->find_user($config,$username,$args->{'skip_user_condition'});

    # Since MySQL is not case sensitive by default on text fields, there
    # was a glitch allowing people to log in with names like 'JOHN'
    # where the database entry would be keyed 'john'. Later on, if site
    # code compares user name to the database literally it does not
    # match leading to strange problems and inconsistencies.
    #
    my $errstr;
    my $user;
    if($data) {
        $user=$data->{'object'};
        $username=$data->{'name'};
    }
    else {
        $errstr=$self->login_errstr(
            type    => $type,
            object  => $user,
            errcode => 'NO_INFO',
        );
    }

    # Controls for when login fails more than a number of times in a
    # certain periof of time.
    #
    my $fail_time_prop=$config->{'fail_time_prop'};
    my $fail_count_prop=$config->{'fail_count_prop'};
    my $fail_expire=$config->{'fail_expire'};
    my $fail_max_count=$config->{'fail_max_count'};
    my $fail_locked;

    # Checking password
    #
    my $password=$args->{'password'};
    if($user) {
        $data->{'id'}=$user->container_key;

        # If available we first check if the user if locked due to
        # previous login failures
        #
        if(!$args->{'force'} && $fail_count_prop && $fail_max_count) {
            my $fail_count=$user->get($fail_count_prop);
            if($fail_count>$fail_max_count) {
                if($fail_time_prop && $fail_expire && (time-$user->get($fail_time_prop))>$fail_expire) {
                    # Ok to go on, failure has expired
                }
                else {
                    $errstr=$self->login_errstr(
                        type    => $type,
                        object  => $user,
                        errcode => 'FAIL_LOCKED',
                    );
                    $fail_locked=1;
                }
            }
        }

        # If the account is locked due to repeated failures we stop at
        # that, to avoid passing any indication of whether the password
        # matches or not to the outside. This is the purpose - to
        # prevent brute-force password guessing.
        #
        if(!$fail_locked) {
            if(!defined($password)) {
                if($args->{'force'}) {
                    # success!
                }
                else {
                    $errstr=$self->login_errstr(
                        type    => $type,
                        object  => $user,
                        errcode => 'NO_PASSWORD',
                    );
                }
            }
            else {
                my $pass_prop=$config->{'pass_prop'} ||
                    throw $self "- no 'pass_prop' in the configuration";

                my $dbpass=$user->get($pass_prop);

                my $password_matches;

                my $errcode;

                try {
                    my $pwdata=$self->data_password_check(
                        type            => $type,
                        object          => $user,
                        config          => $config,
                        #
                        username        => $username,
                        password        => $password,
                        password_stored => $dbpass,
                    );

                    $pwdata ||
                        throw $self "- {{INTERNAL: No data returned}}";

                    $password_matches=$pwdata->{'password_matches'};
                }
                otherwise {
                    my $etext=''.shift;
                    $etext=$2 if $etext=~/\{\{\s*(?:([A-Z0-9_]+):\s*)?(.*)\}\}/;
                    $errcode=$1 || 'BAD_PASSWORD';
                    $password_matches=0;
                };

                # Empty passwords are never accepted
                #
                if(!length($dbpass) || $errcode || !$password_matches) {
                    $errstr=$self->login_errstr(
                        type    => $type,
                        object  => $user,
                        errcode => ($errcode || 'BAD_PASSWORD'),
                    );
                }
            }
        }
    }

    # Calling overridable function that can check some additional
    # conditions. Return a string with the suggested error message or an
    # empty string on success.
    #
    if(!$errstr) {
        $errstr=$self->login_check(
            name        => $username,
            object      => $user,
            password    => $password,
            type        => $type,
            cbdata      => $data,
            force       => $args->{'force'},
        );
    }

    # We know our fate at this point. Displaying anonymous path and
    # bailing out if there were errors.
    #
    # Also updating the count of failures if available.
    #
    my $clipboard=$self->clipboard;
    my $cb_uri=$config->{'cb_uri'} || "/IdentifyUser/$type";
    if($errstr) {

        # Anonymous user should not propagate anything identifyable -
        # resetting the data
        #
        $data={
            fail_locked => $fail_locked,
        };

        # We only increase failure counts when it's really a failure,
        # not when the account is locked
        #
        if($user) {
            if($fail_locked) {
                $data->{'fail_count'}=$user->get($fail_count_prop);
                $data->{'fail_max_count'}=$fail_max_count;
                $data->{'fail_max_count_reached'}=1;
            }
            else {
                my %ud;

                $ud{$fail_time_prop}=time if $fail_time_prop;

                if($fail_count_prop) {
                    $ud{$fail_count_prop}=($user->get($fail_count_prop) || 0) + 1;

                    # Making sure that the new failure count does not
                    # cross the maximum storable value.
                    #
                    my $fail_count_prop_maxvalue=$user->describe($fail_count_prop)->{'maxvalue'};
                    $ud{$fail_count_prop}=$fail_count_prop_maxvalue
                        if $fail_count_prop_maxvalue && $ud{$fail_count_prop}>$fail_count_prop_maxvalue;

                    $data->{'fail_count'}=$ud{$fail_count_prop};

                    if($fail_max_count) {
                        $data->{'fail_max_count'}=$fail_max_count;
                        $data->{'fail_max_count_reached'}=1 if $ud{$fail_count_prop}>$fail_max_count;
                    }
                }

                $user->put(\%ud) if %ud;
            }
        }

        $clipboard->put($cb_uri => $data);

        # A failure to login resets existing key cookies
        #
        if($id_cookie_type eq 'key') {
            $self->siteconfig->add_cookie(
                -name    => $id_cookie,
                -value   => '0',
                -path    => '/',
                -expires => '-1d',
                -domain  => $cookie_domain,
            );
        }
        elsif($config->{'vf_key_cookie'}) {
            $self->siteconfig->add_cookie(
                -name    => $config->{'vf_key_cookie'},
                -value   => '0',
                -path    => '/',
                -expires => '-1d',
                -domain  => $cookie_domain,
            );
        }

        # Returning anonymouse, failed login verification
        #
        return $self->display_results($args,'anonymous',$errstr);
    }

    # Success!
    #
    # When we get here it means a successful login. Removing failure
    # time & count if needed.
    #
    if($fail_time_prop || $fail_count_prop) {
        $user->put(
            ($fail_time_prop ? ($fail_time_prop => 0) : ()),
            ($fail_count_prop ? ($fail_count_prop => 0) : ()),
        );
    }

    # If we have key_list_uri we store verification key there and ignore
    # vf_key_prop even if it exists.
    #
    my $vf_time_prop=$config->{'vf_time_prop'} ||
        throw $self "- no 'vf_time_prop' in the configuration";

    my $key_list_uri=$config->{'key_list_uri'};

    if($key_list_uri) {
        my $key_ref_prop=$config->{'key_ref_prop'} ||
            throw $self "- key_ref_prop required";
        my $key_expire_prop=$config->{'key_expire_prop'} ||
            throw $self "- key_expire_prop required";
        my $vf_expire_time=$config->{'vf_expire_time'} ||
            throw $self "- no vf_expire_time in the configuration";

        my $key_expire_ext_prop=$config->{'key_expire_ext_prop'};

        my $vf_expire_ext_time=$config->{'vf_expire_ext_time'} || 0;

        $vf_expire_time=$vf_expire_ext_time if $extended && $vf_expire_ext_time;

        my $key_id;
        my $vf_key_cookie=$config->{'vf_key_cookie'};
        if($id_cookie_type eq 'key') {
            $key_id=$self->siteconfig->get_cookie($id_cookie);
        }
        elsif($vf_key_cookie) {
            $key_id=$self->siteconfig->get_cookie($vf_key_cookie);
        }
        else {
            throw $self "- id_cookie_type!=key and there is no vf_key_cookie";
        }

        my $key_list=$self->odb->fetch($key_list_uri);
        my $key_obj;
        if($key_id) {
            try {
                $key_obj=$key_list->get($key_id);
                if($key_obj->get($key_ref_prop) ne $user->container_key) {
                    $key_obj=undef;
                }
            }
            otherwise {
                my $e=shift;
                dprint "IGNORED(OK): $e";
            };
        }

        my $now=time;
        my %key_data=(
            $key_expire_prop    => $now+$vf_expire_time,
            $vf_time_prop       => $now,
        );

        if($key_expire_ext_prop) {
            $key_data{$key_expire_ext_prop}=$extended ? 1 : 0;
        }

        if(!$key_obj) {
            $key_obj=$key_list->get_new;
            $key_obj->put(\%key_data,{
                $key_ref_prop       => $user->container_key,
            });
            $key_id=$key_list->put($key_obj);
            $key_obj=$key_list->get($key_id);
        }
        else {
            $key_obj->put(\%key_data);
        }

        if($config->{'vf_time_user_prop'}) {
            $user->put($config->{'vf_time_user_prop'} => $now);
        }

        $data->{'key_object'}=$key_obj;

        if($id_cookie_type eq 'key') {
            $self->siteconfig->add_cookie(
                -name    => $id_cookie,
                -value   => $key_id,
                -path    => '/',
                -expires => '+10y',
                -domain  => $cookie_domain,
            );
            $data->{'cookie_value'}=$key_id;
        }
        elsif($config->{'vf_key_cookie'}) {
            $self->siteconfig->add_cookie(
                -name    => $config->{'vf_key_cookie'},
                -value   => $key_id,
                -path    => '/',
                -expires => '+10y',
                -domain  => $cookie_domain,
            );
        }
        else {
            throw $self "- either id_cookie_type=key or vf_key_cookie is needed with key_list_uri";
        }

        # Auto expiring some keys
        #
        my $key_expire_mode=$config->{'key_expire_mode'} || 'auto';
        if($key_expire_mode eq 'auto') {
            my $cutoff=time - 10*$vf_expire_time;
            my $tr_active=$self->odb->transact_active;
            $self->odb->transact_begin unless $tr_active;
            my $sr=$key_list->search($key_expire_prop,'lt',$cutoff,{ limit => 5 });
            foreach my $key_id (@$sr) {
                $key_list->delete($key_id);
            }
            $self->odb->transact_commit unless $tr_active;
        }
    }
    elsif($config->{'vf_key_prop'} && $config->{'vf_key_cookie'}) {
        my $random_key=XAO::Utils::generate_key();
        $user->put($config->{'vf_key_prop'} => $random_key);
        $self->siteconfig->add_cookie(
            -name    => $config->{'vf_key_cookie'},
            -value   => $random_key,
            -path    => '/',
            -expires => '+10y',
            -domain  => $cookie_domain,
        );
    }

    # Setting login time
    #
    if(!$key_list_uri) {
        $user->put($vf_time_prop => time);
    }

    # Setting user name cookie depending on id_cookie_type parameter.
    #
    my $expire=$config->{'id_cookie_expire'} ? "+$config->{'id_cookie_expire'}s"
                                             : '+10y';

    if($id_cookie_type eq 'id') {
        my $cookie_value=$data->{'id'};
        my $r=$data;
        while($r->{'list_prop'}) {
            $r=$r->{$r->{'list_prop'}};
            $cookie_value.="/$r->{'id'}";
        };
        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => $cookie_value,
            -path    => '/',
            -expires => $expire,
            -domain  => $cookie_domain,
        );
        $data->{'cookie_value'}=$cookie_value;
    }
    elsif($id_cookie_type eq 'name') {
        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => $username,
            -path    => '/',
            -expires => $expire,
            -domain  => $cookie_domain,
        );
        $data->{'cookie_value'}=$username;
    }
    elsif($id_cookie_type eq 'key') {
        # already set above
    }
    else {
        throw $self "- unsupported id_cookie_type ($id_cookie_type)";
    }

    # Yay! Verified.
    #
    $data->{'verified'}=1;

    $data->{'extended'}=($extended ? 1 : 0);

    # Storing values into the clipboard
    #
    $clipboard->put($cb_uri => $data);

    # Displaying results
    #
    $self->display_results($args,'verified');
}

###############################################################################

sub login_password_encrypt ($@) {
    my $self=shift;
    throw $self "- this method must be implemented in a derived class";
}

###############################################################################

=item login_check ()

A method that can be overriden in a derived object to check additional
conditions for letting a user in. Gets the following arguments as its
input:

 name       => name of user object
 password   => password
 object     => reference to a database object containing user info
 type       => user type
 cbdata     => reference to a hash that will be stored in clipboard on
               successful login

This method is called after all standard checks - it is guaranteed that
user object exists and password matches its database record.

Must return empty string on success or suggested error message on
failure. That error message will be passed in ERRSTR argument to the
templates.

=cut

sub login_check ($%) {
    return '';
}

###############################################################################

=item logout ()

Logs the user out.

Resets vf_time_prop if there is no vf_key_prop set as it is our only
proof of authentication in this case. If vf_key_prop is in use then we
clear the key, but leave the time alone -- helps to see when this user
last logged in.

Clears identification cookie as well fo hard logout mode. Sets user
status to 'anonymous' (hard logout mode) or 'identified'.

Will install data into clipboard in soft logout mode just the same way
as mode='check' does.

=cut

sub logout ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my ($config,$type)=$self->_get_config($args);

    my $cookie_domain=$config->{'domain'};

    # Logging in the user first. Skipping if 'logged_in' to avoid
    # recursion when we need to log the user out after some failed
    # checks.
    #
    $self->check(type => $type) unless $args->{'logged_in'};

    # Checking if we're currently logged in at all -- either verified or
    # identified.
    #
    my $clipboard=$self->clipboard;
    my $cb_uri=$config->{'cb_uri'} || "/IdentifyUser/$type";
    my $cb_data=$clipboard->get($cb_uri);
    my $user=$cb_data->{'object'};

    # If there is no user at all -- then we're already logged out
    #
    $user || return $self->display_results($args,'anonymous');

    # Removing user last verification time only as a last resort --
    # it's useful to have it to know when the user last logged in. When
    # possible removing either the key from the list, or the key
    # property.
    #
    my $vf_time_prop=$config->{'vf_time_prop'} ||
        throw $self "- no 'vf_time_prop' in the configuration";
    my $key_list_uri=$config->{'key_list_uri'};
    my $vf_key_prop=$config->{'vf_key_prop'};
    my $vf_key_cookie=$config->{'vf_key_cookie'};
    my $deleted;

    if($vf_key_prop && $vf_key_cookie) {
        $user->put($vf_key_prop => '');
        $deleted=1;
    }

    my $key_object=$cb_data->{'key_object'};

    if($key_object) {
        $key_object->put($vf_time_prop => 0);
        $clipboard->delete("$cb_uri/key_object");
        $clipboard->delete("$cb_uri/extended");
        $deleted=1;
    }

    if(!$deleted && $cb_data->{'verified'}) {
        if($key_list_uri) {
            my $vf_time_user_prop=$config->{'vf_time_user_prop'};
            if($vf_time_user_prop) {
                $user->put($vf_time_user_prop => 0);
            }
            else {
                throw $self "- no key and no vf_time_user_prop in logout";
            }
        }
        else {
            $user->put($vf_time_prop => 0);
        }
    }

    # Deleting verification status from the clipboard
    #
    $clipboard->delete("$cb_uri/verified");

    # Not sure, but setting value to an empty string triggered a bug
    # somewhere, setting it to '0' instead and expiring it immediately.
    #
    # This is mainly so the user does not feel paranoid -- if if we were
    # to keep this cookie the user won't be in verified status any more
    # because last verification time was dropped to zero.
    #
    if($vf_key_cookie) {
        $self->siteconfig->add_cookie(
            -name    => $vf_key_cookie,
            -value   => '0',
            -path    => '/',
            -expires => '-1d',
            -domain  => $cookie_domain,
        );
    }

    # Deleting user identification if hard_logout is set.
    #
    if($args->{'hard_logout'}) {
        $clipboard->delete($cb_uri);

        if($key_object) {
            $key_object->container_object->delete($key_object->container_key);
            $clipboard->delete("$cb_uri/key_object");
        }

        my $id_cookie=$config->{'id_cookie'} ||
            throw $self "- no 'id_cookie' in the configuration";

        $self->siteconfig->add_cookie(
            -name    => $id_cookie,
            -value   => '0',
            -path    => '/',
            -expires => '-1d',
            -domain  => $cookie_domain,
        );

        return $self->display_results($args,'anonymous');
    }

    # We only get here if user is known, so returning 'identified'
    # status.
    #
    return $self->display_results($args,'identified');
}

###############################################################################

# Looping through possibly multiple password encryption algorithms to
# find the one potentially matching the stored password

sub data_password_check ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $pass_encrypt=$args->{'pass_encrypt'};
    my $pass_pepper=$args->{'pass_pepper'};

    if(!$pass_encrypt || !$pass_pepper) {
        my $config=$self->_get_config($args);
        $pass_encrypt||=$config->{'pass_encrypt'};
        $pass_pepper||=$config->{'pass_pepper'};
    }

    my $password_stored=$args->{'password_stored'} ||
        throw $self "- no password_stored given";

    # New stored passwords follow this format:
    #
    #  $ALG$SALT$DIGEST
    #
    # It overrides whatever specs were given as that is what we need to
    # compare to.
    #
    if((!$pass_encrypt || $pass_encrypt ne 'plaintext') && $password_stored=~/^\$([\w-]+)\$(.*?)\$.+/) {
        $pass_encrypt=lc($1);
    }

    # The legacy compatibility default.
    #
    $pass_encrypt||='plaintext';
    $pass_pepper||='';

    # We might have a list of password encryption algorithms -- current
    # and older for instance.
    #
    if(ref $pass_encrypt) {
        # OK
    }
    elsif(index($pass_encrypt,',')>=0) {
        $pass_encrypt=[ split(/\s*,\s*/,$pass_encrypt,-1) ];
    }
    else {
        $pass_encrypt=[ $pass_encrypt ];
    }

    # Pepper value can also be a list.
    #
    if(ref $pass_pepper) {
        # OK
    }
    elsif(index($pass_pepper,',')>=0) {
        $pass_pepper=[ split(/\s*,\s*/,$pass_pepper,-1) ];
    }
    else {
        $pass_pepper=[ $pass_pepper ];
    }

    # We are checking against a list of possible encryption algorithms.
    #
    my $pwdata;
    foreach my $pass_encrypt_v (@$pass_encrypt) {
        foreach my $pass_pepper_v (@$pass_pepper) {
            ### dprint ".....TRYING '$pass_encrypt_v' / '$pass_pepper_v'";

            $pwdata=$self->data_password_encrypt($args,{
                pass_encrypt    => $pass_encrypt_v,
                pass_pepper     => $pass_pepper_v,
            });

            if($pwdata->{'encrypted'} eq $password_stored) {
                $pwdata->{'password_matches'}=1;
                return $pwdata;
            }
        }
    }

    $pwdata->{'password_matches'}=0;

    return $pwdata;
}

###############################################################################

=item data_password_encrypt (%)

Use this call to create a password for a user's database record. Call like so:

    my $pwdata=$identify_user->data_password_encrypt(
        type        => 'customer',
        password    => $plain_text_password,
    );

The resulting hash reference would have a member 'encrypted' that can be
directly stored in the database.

=cut

sub data_password_encrypt ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $pass_encrypt=$args->{'pass_encrypt'};
    my $pass_pepper=$args->{'pass_pepper'};

    if((!defined($pass_encrypt) || !defined($pass_pepper)) && ($args->{'config'} || $args->{'type'})) {
        my $config=$self->_get_config($args);
        $pass_encrypt=$config->{'pass_encrypt'} unless defined $pass_encrypt;
        $pass_pepper=$config->{'pass_pepper'} unless defined $pass_pepper;
    }

    # When called to create a password we won't have a stored
    # password. But when encrypting internally to check the password we
    # do get a stored password and that password might have an algorithm
    # and salt embedded in it. That overrides the configuration to make
    # it possible to change the config later to a different hashing
    # function without changing all database stored passwords.
    #
    # In plaintext we don't analyze the stored password, to avoid
    # clashing with what might have been entered by the user.
    #
    my $password_stored=$args->{'password_stored'};
    my $salt=$args->{'salt'};
    my $pass_wrap=1;
    if(defined $password_stored && (!$pass_encrypt || $pass_encrypt ne 'plaintext')) {

        # New stored passwords follow this format:
        #
        #  $ALG$SALT$DIGEST
        #
        if($password_stored=~/^\$([\w-]+)\$(.*?)\$.+/) {
            $pass_encrypt=lc($1);
            $salt=$2;
        }

        # Old MD5 based passwords were bare, not including salt. We
        # still need to be able to check against them.
        #
        else {
            $salt='';
            $pass_wrap=0;
        }
    }

    # Historically the default password encryption is plain text.
    #
    $pass_encrypt||='plaintext';

    $pass_encrypt=lc($pass_encrypt) unless ref $pass_encrypt;

    # With multi-algorithm values we encrypt using the
    # first one. This would typically be something like
    # 'sha256,md5,plaintext' -- i.e. the current algo and
    # fall-backs for older passwords.
    #
    if(ref($pass_encrypt)) {
        $pass_encrypt=$pass_encrypt->[0];
    }
    elsif($pass_encrypt=~/^(.*?),/) {
        $pass_encrypt=$1;
    }

    # Pepper is empty by default
    #
    $pass_pepper||='';

    # The same story is with pepper -- we encrypt using the first value
    # if there is a list.
    #
    if(ref($pass_pepper)) {
        $pass_pepper=$pass_pepper->[0] || '';
    }
    elsif($pass_pepper=~/^(.*?),/) {
        $pass_pepper=$1;
    }

    # Encrypting (which is actually a misnomer, hashing would be a
    # better word, but it's already called "encrypt" everywhere else).
    #
    my $password=$args->{'password'};

    defined $password ||
        throw $self "- {{INTERNAL: No password argument}}";

    my $encrypted;

    if($pass_encrypt eq 'plaintext') {
        $encrypted=$password;
        $pass_wrap=0;
    }
    elsif($pass_encrypt eq 'crypt') {
        $salt=$password_stored if !defined($salt) || !length($salt);
        if(!defined $salt || length($salt)<2) {
            my $saltchars=join('',map { chr($_) } ((ord('0')..ord(9)),(ord('a')..ord('z')),(ord('A')..ord('Z')),ord('.'),ord('/')));
            $salt=substr($saltchars,rand()*length($saltchars),1).substr($saltchars,rand()*length($saltchars),1);
        }
        $salt=substr($salt,0,2);
        $encrypted=crypt($password.$pass_pepper,$salt);
        $pass_wrap=0;
        if(length($password)>8) {
            eprint "Only first 8 characters of ".length($password)."-character password are used in 'crypt' mode";
        }
    }
    elsif($pass_encrypt eq 'md5') {
        $salt=XAO::Utils::generate_key() unless defined $salt;
        $encrypted=md5_base64($salt.$password.$pass_pepper);
    }
    elsif($pass_encrypt eq 'sha1') {
        $salt=XAO::Utils::generate_key() unless defined $salt;
        $encrypted=sha1_base64($salt.$password.$pass_pepper);
    }
    elsif($pass_encrypt eq 'sha256') {
        $salt=XAO::Utils::generate_key() unless defined $salt;
        $encrypted=sha256_base64($salt.$password.$pass_pepper);
    }
    elsif($pass_encrypt eq 'bcrypt') {
        my $salt_bits;
        my $cost;

        if($salt) {
            $salt=~/^(\d{1,2})-(.{22})$/ ||
                throw $self "- unusable salt for bcrypt algorithm";
            $cost=$1;
            $salt_bits=decode_base64($2.'==');
        }
        else {
            $cost=$args->{'pass_encrypt_cost'};

            if(!$cost && ($args->{'type'} || $args->{'config'})) {
                $cost=$self->_get_config($args)->{'pass_encrypt_cost'};
            }

            $cost||=8;  # About 15ms per digest on Intel(R) Core(TM) i5-4670K CPU @ 3.40GHz

            $salt_bits=rand_bits(16*8);

            $salt=sprintf('%u-%s',$cost,substr(encode_base64($salt_bits,''),0,22));
        }

        my $bcrypt=Digest::Bcrypt->new();

        $bcrypt->salt($salt_bits);

        $bcrypt->cost($cost);

        $bcrypt->add($password.$pass_pepper);

        $encrypted=$bcrypt->b64digest;
    }
    elsif($pass_encrypt eq 'custom') {
        $pass_wrap=0;

        my ($config,$type)=($args->{'config'} || $args->{'type'} ? ($self->_get_config($args)) : (undef,undef));

        my $errcode;

        $encrypted=$self->login_password_encrypt($args,{
            type                => $type,
            config              => $config,
            pass_encrypt        => $pass_encrypt,
            pass_pepper         => $pass_pepper,
            #
            password            => $password,
            password_typed      => $password,
            password_stored     => $password_stored,
            salt                => $salt,
            #
            error_message_ref   => \$errcode,
        });

        if($errcode) {
            throw $self "- {{$errcode: Password encryption error}}";
        }
    }
    else {
        throw $self "- {{INTERNAL: Unknown encryption mode}}";
    }

    ### dprint "...pass_encrypt=$pass_encrypt pass_wrap=$pass_wrap salt=$salt encrypted=$encrypted";

    # Wrapping to include salt and algorithm
    #
    if($pass_wrap) {
        $encrypted='$'.$pass_encrypt.'$'.$salt.'$'.$encrypted;
    }

    return {
        encrypted       => $encrypted,
        salt            => $salt,
        pass_encrypt    => $pass_encrypt,
    };
}

###############################################################################

sub _get_config ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('identify_user') ||
        throw $self "- no 'identify_user' configuration";

    my $type=$args->{'type'} ||
        throw $self "- no 'type' given";

    $config=$config->{$type} ||
        throw $self "- no 'identify_user' configuration for '$type'";

    return wantarray ? ($config,$type) : $config;
}

##############################################################################

=item verify_check (%)

Overridable method that is called from check() after user is identified
and verified. May check for additional conditions, such as privilege
level or something similar.

Gets the following arguments as its input:

 args       => arguments as passed to the check() method
 object     => reference to a database object containing user info
 type       => user type

Must return empty string on success.

=cut

sub verify_check ($%) {
    return '';
}

##############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2001-2004 XAO Inc.

Andrew Maltsev <am@ejelta.com>,
Marcos Alves <alves@xao.com>,
Ilya Lityuga <ilya@boksoft.com>.

=head1 SEE ALSO

Recommended reading:

L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::FS>.
