package Webservice::Sendy::API;

use v5.10;
use strict;
use warnings;

our $VERSION = 0.5;

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise ddd HTTPTiny2h2o h2o ini2h2o o2d/;

sub new {
    my $pkg = shift;
    my $params = { @_, ua => HTTP::Tiny->new };
    my $self = baptise $params, $pkg, qw/config/;
    if (not $self->config) {
      my $HOME = (getpwuid($<))[7];
      $self->config("$HOME/.sendy.ini");
    }
    if (not -e $self->config) {
      die sprintf "Webservice::Sendy::API requires a configuration file! (looking for, '%s')\n", $self->config;
    }
    # update config field with contents of the config file
    $self->config(ini2h2o $self->config);
    return $self;
}

sub form_data {
  my $self = shift;
  return {
    api_key => $self->config->defaults->api_key,
    @_,
  };
}

sub create_campaign {
  my $self     = shift;
  my $params   = {@_};

  my @required = qw/from_name from_email reply_to title subject html_text
                  list_ids brand_id track_opens track_clicks send_campaign/;
  my @optional = qw/plain_text segment_ids exclude_list_ids query_string schedule_date_time schedule_timezone/;

  h2o $params, @required, @optional;

  # FATAL error if title, subject, and html_text is not provided; the other fields
  # required by the API can use defaults in the configuration file, listed after
  # the check:

  # look up hash for defaults to use
  my $required_defaults = h2o {
    title         => undef,
    subject       => undef,
    html_text     => undef,
    from_name     => $self->config->campaign->from_name,
    from_email    => $self->config->campaign->from_email,
    reply_to      => $self->config->campaign->reply_to,
    brand_id      => $self->config->defaults->brand_id,
    list_ids      => $self->config->defaults->list_id,
    track_clicks  => ($params->no_track_clicks) ? 0 : 1, # --no_track_clicks
    track_opens   => ($params->no_track_opens)  ? 0 : 1, # --no_track_opens
    send_campaign => 0,
  };


  my $required_options = {};
  foreach my $param (keys %$required_defaults) { 
    if (not defined $params->$param and defined $required_defaults->$param) {
      $params->$param($required_defaults->$param);
    }
    # FATAL for anything in $required_defaults set to 'undef'
    elsif (not defined $params->$param and not defined $required_defaults->$param) {
      die sprintf "[campaign] Missing '%s' flag; creation requires: %s'\n", $param, join(",", keys %$required_defaults);
    }
    $required_options->{$param} = $params->$param;
  }

  # processing other white-listed options in @optional
  my $other_options = {}; 
  foreach my $opt (@optional) {
    if (defined $params->$opt) {
      $other_options->{$opt} = $params->$opt;
    }
  }

  my $form_data = $self->form_data(%$required_options, %$other_options);
  my $URL       = sprintf "%s/api/campaigns/create.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/Already|missing|not|valid|Unable/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[campaign] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return $resp->content;
}

sub subscribe {
  my $self     = shift;
  my $params   = {@_};
  my @required = qw/email list_id/;
  my @optional = qw/name country ipaddress referrer gdpr silent hp/;
  h2o $params, @required, @optional;

  #NOTE - Util::H2O::More::ini2h2o needs a "autoundef" option! Workaround is use of "exists" and ternary
  if (not $params->list_id) {
     $params->list_id('');
     if ($self->config->defaults->{list_id}) {
       $params->list_id($self->config->defaults->list_id);
     }
  }
  die "email required!\n" if not $params->email;

  # processing other white-listed options
  my $other_options = {}; 
  foreach my $opt (@optional) {
    if (defined $params->$opt) {
      $other_options->{$opt} = $params->$opt;
    }
  }

  my $form_data = $self->form_data(list => $params->list_id, email => $params->email, boolean => "true", %$other_options);
  my $URL       = sprintf "%s/subscribe", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/Already|missing|not|valid|Bounced|suppressed/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[subscribe] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return sprintf "%s %s %s\n", ($resp->content eq "1")?"Subscribed":$resp->content, $params->list_id, $params->email;
}

#NOTE: this call is different from "delete_subscriber" in that it just marks the
# subscriber as unsubscribed; "delete_subscriber" fully removes it from the list (in the DB)
#NOTE: this call uses a different endpoint than the others ...
sub unsubscribe {
  my $self      = shift;
  my $params    = {@_};

  #NOTE - Util::H2O::More::ini2h2o needs a "autoundef" option! Workaround is use of "exists" and ternary
  my $list_id   = $params->{list_id};
  if (not $list_id) {
     $list_id = '';
     if ($self->config->defaults->{list_id}) {
       $list_id = $self->config->defaults->list_id;
     }
  }
  my $email     = $params->{email};
  die "email required!\n" if not $email;

  my $form_data = $self->form_data(list => $list_id, email => $email, boolean => "true");
  my $URL       = sprintf "%s/unsubscribe", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/Some|valid|not/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[unsubscribe] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return sprintf "%s %s %s\n", ($resp->content == 1)?"Unsubscribed":$resp->content, $list_id, $email;
}

#NOTE: this call is different from "unsubscribe" in that it deletes the subscriber
# "unsubscribe" simply marks them as unsubscribed
sub delete_subscriber {
  my $self      = shift;
  my $params    = {@_};

  #NOTE - Util::H2O::More::ini2h2o needs a "autoundef" option! Workaround is use of "exists" and ternary
  my $list_id   = $params->{list_id};
  if (not $list_id) {
     $list_id = '';
     if ($self->config->defaults->{list_id}) {
       $list_id = $self->config->defaults->list_id;
     }
  }
  my $email     = $params->{email};
  die "email required!\n" if not $email;

  my $form_data = $self->form_data(list_id => $list_id, email => $email);
  my $URL       = sprintf "%s/api/subscribers/delete.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/No|valid|List|not/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[delete] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return sprintf "%s %s %s\n", ($resp->content == 1)?"Deleted":$resp->content, $list_id, $email;
}

sub get_subscription_status {
  my $self      = shift;
  my $params    = {@_};

  #NOTE - Util::H2O::More::ini2h2o needs a "autoundef" option! Workaround is use of "exists" and ternary
  my $list_id   = $params->{list_id};
  if (not $list_id) {
     $list_id = '';
     if ($self->config->defaults->{list_id}) {
       $list_id = $self->config->defaults->list_id;
     }
  }
  my $email     = $params->{email};
  die "email required!\n" if not $email;

  my $form_data = $self->form_data(list_id => $list_id, email => $email);
  my $URL       = sprintf "%s/api/subscribers/subscription-status.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # catch "Not Subscribed"
  if ($resp->content eq "Email does not exist in list") {
    return sprintf "Not Subscribed %s %s\n", $list_id, $email;
  }

  # report Error
  if ($resp->content and $resp->content =~ m/No|vlaid|not/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[status] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return sprintf "%s %s %s\n", $resp->content, $list_id, $email;
}

sub get_active_subscriber_count {
  my $self      = shift;
  my $params    = {@_};

  #NOTE - Util::H2O::More::ini2h2o needs a "autoundef" option! Workaround is use of "exists" and ternary
  my $list_id   = $params->{list_id};
  if (not $list_id) {
     $list_id = '';
     if ($self->config->defaults->{list_id}) {
       $list_id = $self->config->defaults->list_id;
     }
  }

  my $form_data = $self->form_data( list_id => $list_id);
  my $URL       = sprintf "%s/api/subscribers/active-subscriber-count.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/No|valid|not/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[count] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  return sprintf "%s %s\n", $resp->content // -1, $list_id;
}

sub get_brands() {
  my $self      = shift;
  my $form_data = $self->form_data();
  my $URL       = sprintf "%s/api/brands/get-brands.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/No|valid/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[brands] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  $resp = HTTPTiny2h2o o2d $resp;
  return $resp->content;
}

sub get_lists {
  my $self      = shift;
  my $params    = {@_};
  my $form_data = $self->form_data( brand_id => $params->{brand_id} // $self->config->defaults->brand_id // 1);
  my $URL       = sprintf "%s/api/lists/get-lists.php", $self->config->defaults->base_url;
  my $resp      = h2o $self->ua->post_form($URL, $form_data);

  # report Error
  if ($resp->content and $resp->content =~ m/No|valid|not/i) {
    my $msg = $resp->content;
    $msg =~ s/\.$//g;
    die sprintf "[lists] Server replied: %s!\n", $msg;
  }

  # report general failure (it is not clear anything other than HTTP Status of "200 OK" is returned)
  if (not $resp->success) {
    die sprintf("Server Replied: HTTP Status %s %s\n", $resp->status, $resp->reason);
  }

  $resp = HTTPTiny2h2o o2d $resp;
  return $resp->content;
}

777

__END__

=head1 NAME

Webservice::Sendy::API - Sendy's integration API Perl client and commandline
utility

=head1 SYNOPSIS

  use v5.10;
  use strict;
  use Webservice::Sendy::API qw//;
  
  # constructor looks for default config file if not provided ..
  my $sendy  = Webservice::Sendy::API->new;
  my $brands = $sendy->get_brands;
  
  foreach my $key (sort keys %$brands) {
    my $brand = $brands->$key;
    printf "%-3d  %s\n", $brand->id, $brand->name;
  }

B<NOTE:> This module requires a configuration file  (defaults to C<$HOME/.sendy.ini>)
to be set up. See the ENVIRONMENT section below to learn more.

  ; defaults used for specified options
  [defaults]
  api_key=sOmekeyFromYourSendy
  base_url=https://my.domain.tld/sendy
  brand_id=1
  list_id=mumdsQnpwnazscoOzKJ763Ow
  
  ; campaign information used for default brand_id 
  [campaign]
  from_name=List Sender Name
  from_email=your-email-list@domain.tld
  reply_to=some-other-reply-to@domain.tld

Save this file as C<$HOM/.sendy.ini>, and you may start to use the
C<sendy> commandline utility.

=head1 DESCRIPTION

This is a full implementation of Sendy's Web API, version 6.1.2. Please
alert author if this module has not been updated to support Sendy's latest
API version.

Sendy is a commercial self-hosted email marketing application that
integrates with Amazon SES (Simple Email Service) to send bulk emails at
a low cost. It provides a user-friendly interface for creating campaigns,
managing subscribers, and tracking email performance, making it a popular
choice for businesses looking for an affordable, scalable email marketing
solution. This module implements the Sendy API, which is based on simple HTTP
POST. Use the API to integrate Sendy programmatically with your website or
application. Some APIs may require the latest version of Sendy (currently
version 6.1.2). Sendy requires a license to use.

Some sanity checking is done in the wrapper functions, but Sendy's API tend
to do a good job of validation on the server side, and their error messages
are pretty clear about what the issue is. In most cases, little additional
validation is provided by this module and error messages are passed directly
to the caller.

Sendy's API is not really I<RESTful> because it doesn't use the HTTP status
field. All calls return a C<200 OK>, therefore the L<HTTP::Tiny> module
that is used as the user agent in this module is forced to assume all calls
are successful. In order to determine an error, the actual content of the
response must be checked. This module does do that.

=head1 METHODS

=over 4

=item C<create_campaign>

Creates an email campaign; which can be saved as a draft, scheduled for
sending, or sent immediately.

It is a FATAL error if title, subject, and html_text is not provided; the
other fields required by the API can use defaults in the configuration file,
listed after the check:

B<Required fields:> from_name*, from_email*, reply_to*, title, subject,
html_text, list_ids*, brand_id*, no_track_opens, no_track_clicks, send_campaign
(* = uses defaults in C<.sendy.ini>)

B<Optional fields:> plain_text, segment_ids, exclude_list_ids, query_string,
schedule_date_time, schedule_timezone

NOTE: Unless C<no_track_opens> and C<no_track_clicks> are set to I<1>
value, the campaign created will have them I<ON>, respectively. In the C<sendy>
tool, this means that to turn off tracking, you'd need to supply the flags,
C<--no_track_opens --no_track_clicks>; in a similar way, the default behavior
will always be to just create a draft. Therefore, to send the actual email
campaign via this command, the C<send_campaign> flag must be set to I<1>.
 
See more information about the call on Sendy's specification,
L<https://sendy.co/api#create-send-campaigns>.

=item C<subscribe>

Subscribes an email address to a list.

B<Required fields:> email, list_id

B<Optional fields:> name, country, ipaddress, referrer, gdpr, silent, hp*

* C<hp> is a I<honey pot> field, if it is populated then the server side
handler assumes it's been submitted by a bot, and will fail. So don't use
it unless you're a super smat AI bot.

For a full description of the fields is available at
L<https://sendy.co/api#subscribe>.

=item C<unsubscribe>

Unsubscribes an email address from a list, but keeps it in the list (marks
it inactive).

B<Required fields:> email, list_id

If not provided, C<list_id> is pulled from the configuration file (if set).

This method automatically sets the field I<boolean> to C<true>; this is so the
response if plain-text. There is no way to change this value without modifying
the module. The alternative is to parse through a mess of HTML. This can me
changed in future versions, but feedback is needed to know if this is useful.

For a full description of the fields is available at
L<https://sendy.co/api#unsubscribe>.

=item C<delete>

Deletes an email address from a list.

B<Required fields:> email, list_id

If not provided, C<list_id> is pulled from the configuration file (if set).

This method automatically sets the field I<boolean> to C<true>; this is so the
response if plain-text. There is no way to change this value without modifying
the module. The alternative is to parse through a mess of HTML. This can me
changed in future versions, but feedback is needed to know if this is useful.

For a full description of the fields is available at
L<https://sendy.co/api#delete-subscriber>.

=item C<get_subscriber_count>

Returns the number of active subscribers that are in a list.

B<Required fields:> list_id

If not provided, C<list_id> is pulled from the configuration file (if set).

For a full description of the fields is available at
L<https://sendy.co/api#subscriber-count>.

=item C<get_subscriber_status>

Returns the status of an email address with respect to a specific email list.

B<Required fields:> email, list_id

If not provided, C<list_id> is pulled from the configuration file (if set).

For a full description of the fields is available at
L<https://sendy.co/api#subscription-status>.

=item C<get_brands>

No fields are required, C<brands> are the highest level of entities available
to list. All other calls require either a C<brand_id> or C<list_id>(s)
to be specified.

Returns all brands. Brand Ids are numbers (1 through #brands).

For a full description of the fields is available at
L<https://sendy.co/api#get-brands>.

=item C<get_lists>

Returns all lists based on a specified brand id. List Ids are alphanumeric
hashes, therefore calls that operate using list specifier(s) do not also
need to know the associated C<brand_id>.

B<Required fields:> brand_id

For a full description of the fields is available at
L<https://sendy.co/api#get-brands>.

=back

=head1 C<sendy> COMMANDLINE CLIENT

When installed, this module provides the commandline client, C<sendy>. This
script is both a real tool and a reference implementation for a useful
client. It is meant for use on the commandline or in cron or shell
scripts. It's not intended to be used inside of Perl scripts. It is recommended
the library be used directly inside of the Perl scripts. Checkout the source
code of C<sendy> to see how to do it, if this documentation is not sufficient.

See the section on the ENVIRONMENT section below to learn how to set up
the required configuration file.

B<Commands>

=over 4

=item C<brands>

Returns list of brands by Id to C<STDOUT>.

Usage,

  sendy brands [--config alt-config.ini]

=item C<count>

Returns count of the specified list to C<STDOUT>.

Usage

  sendy lists [--config alt-config.ini] --brand_id BRANDID

=item C<create>

Creates an email campaign based on specified options. Status is returned
via C<STDOUT>.

By default full tracking is enabled. To turn off tracking, use the flags,
C<--no_track_opens> and C<--no_track_clicks>.

To send right away, rather than just creating a draft; use the
C<--send_campaign> flag. There is currently no support to schedule the
sending of a campaign at a later time. Please let me know if you need this
ability. Otherwise it'll get implemented if and when I needed it.

Usage,

  sendy create [--config alt-config.ini] --list_ids A,B,C,...

=item C<delete>

Deletes the provided email from provided list Id, returns status to C<STDOUT>.

Usage

  sendy delete [--config alt-config.ini] --list_id LISTID --email
  email@domain.tld

=item C<lists>

Returns list of email lists for provided brand Id to C<STDOUT>.

Usage

  sendy lists [--config alt-config.ini] --brandid BRAND

=item C<status>

Returns status of the provided email address to provided list Id, via
C<STDOUT>.

Usage

  sendy status [--config alt-config.ini] --list_id LISTID --email
  email@domain.tld

=item C<subscribe>

Subscribes the provided email address to the provided list Id, result returned
via C<STDOUT>.

Usage

  sendy subscribe [--config alt-config.ini] --list_id LISTID --email
  email@domain.tld

=item C<unsubscribe>

Unsubscribes the provided email address from the provided list Id, result
returned via C<STDOUT>.

Usage

  sendy unsubscribe [--config alt-config.ini] --list_id LISTID --email
  email@domain.tld

=back

=head1 ENVIRONMENT

This module requires a configuration file, which may sound unusual. But it's
the best way to manage API secrets. Please see below.

=head2 C<$HOME/.sendy.ini> Configuration

A configuration file is required. The default file is C<$HOME/.sendy.ini>.
It is I<highly> recommended that this file be C<chmod 600> (read only to
the C<$USER>. B<Note:> Future versions of this module may enforce this file
mode or automatically change permissions on the file.

  ; defaults used for specified options
  [defaults]
  api_key=sOmekeyFromYourSendy
  base_url=https://my.domain.tld/sendy
  brand_id=1
  list_id=mumdsQnpwnazscoOzKJ763Ow
  
  ; campaign information used for default brand_id 
  [campaign]
  from_name=List Sender Name
  from_email=your-email-list@domain.tld
  reply_to=some-other-reply-to@domain.tld

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

Find out about this client and more Perl API clients at L<https://PerlClientDirectory.com>.

=head1 BUGS

This module is meant to be used in production environments, but
it still needs some maturing. Please report any bugs ASAP, to
L<https://github.com/oodler577/p5-Webservice-Sendy-API/issues>.

Please also report an issue if this module no longer supports
Sendy's latest API version.

=head1 SEE ALSO

This module is meant to supercede L<Net::Sendy::API>, which has not been
updated since 2013.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
