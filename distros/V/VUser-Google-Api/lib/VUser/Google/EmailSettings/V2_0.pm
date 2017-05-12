package VUser::Google::EmailSettings::V2_0;
use warnings;
use strict;

# Copyright (C) 2009 Randy Smith, perlstalker at vuser dot org

our $VERSION = '0.1.0';

use Moose;
extends 'VUser::Google::EmailSettings';

# BUG: This should work but doesn't seem to. WTF?
#has '+google' => (isa => 'VUser::Google::ApiProtocol::V2_0');
has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/emailsettings/2.0/');

## Methods
# Constructor
sub BUILD {}

override 'CreateLabel' => sub {
    my $self = shift;
    my %options = @_;

    my $label = $options{'label'};

    $self->google()->Login();
    my $url = $self->base_url().$self->google()->domain().'/'.$self->user().'/label';

    my $post = "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<atom:entry xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:apps=\"http://schemas.google.com/apps/2006\">
    <apps:property name=\"label\" value=\"$label\" />
</atom:entry>";

    return $self->google->Request('POST', $url, $post);
};

override 'CreateFilter' => sub {
    my $self = shift;
    my %options = @_;

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/filter';
    my $post = '<?xml version="1.0" encoding="utf-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    ## Add criteria
    if (defined $options{hasAttachment}) {
	$options{hasAttachment} = $options{hasAttachment}? 'true':'false';
    }

    foreach my $crit qw(from to subject hasTheWord doesNotHaveTheWord hasAttachment) {
	if (defined $options{$crit}) {
	    $post .= sprintf ("<apps:property name=\"%s\" value=\"%s\" />",
			      $crit, $options{$crit});
	}
    }

    ## Add actions
    foreach my $act qw(shouldMarkAsRead shouldArchive) {
	$options{$act} = $options{$act}? 'true':'false';
    }

    foreach my $act qw(label shouldMarkAsRead shouldArchive) {
	if (defined $options{$act}) {
	    $post .= sprintf ("<apps:property name=\"%s\" value=\"%s\" />",
			      $act, $options{$act});
	}
    }

    $post .= '</atom:entry>';

    return $self->google->Request('POST', $url, $post);
};

override 'CreateSendAsAlias' => sub {
    my $self = shift;
    my %options = @_;

    my $name         = $options{'name'};
    my $address      = $options{'address'};
    my $reply_to     = $options{'replyTo'};
    my $make_default = $options{'makeDefault'};

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/sendas';
    my $post = '<?xml version="1.0" encoding="utf-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    $post .= "<apps:property name='name' value='$name' />";
    $post .= "<apps:property name='address' value='$address' />";

    if (defined $reply_to) {
	$post .= "<apps:property name='replyTo' value='$reply_to' />";
    }

    if (defined $make_default) {
	$post .= sprintf("<apps:property name='makeDefault' value='%s' />",
			 $make_default? 'true' : 'false'
			 );
    }

    $post .= '</atom:entry>';

    return $self->google->Request('POST', $url, $post);

};

override 'UpdateWebClip' => sub {
    my $self = shift;
    my %options = @_;

    my $enable = $options{'enable'};

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/webclip';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';
    $post .= sprintf('<apps:property name="enable" value="%s" />',
		     $enable ? 'true' : 'false'
		     );
    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);
};

override 'UpdateForwarding' => sub {
    my $self = shift;
    my %options = @_;

    my $enable     = $options{'enable'};
    my $forward_to = $options{'forwardTo'};
    my $action     = $options{'action'};

    $action = uc($action);

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/forwarding';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    if (defined $enable) {
	$post .= sprintf('<apps:property name="enable" value="%s" />',
			 $enable ? 'true' : 'false');
    }

    if ($enable) {
	if ($forward_to) {
	    $post .= "<apps:property name='forwardTo' value='$forward_to' />";
	}

	if ($action) {
	    if ($action ne 'KEEP'
		and $action ne 'ARCHIVE'
		and $action ne 'DELETE'
		) {
		die "action must be KEEP, ARCHIVE or DELETE";
	    }

	    $post .= "<apps:property name='action' value='$action' />";
	}
    }

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);
};

override 'UpdatePOP' => sub {
    my $self = shift;
    my %options = @_;

    my $enable     = $options{'enable'};
    my $enable_for = $options{'enableFor'};
    my $action     = $options{'action'};

    $action = uc($action);

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/pop';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    if (defined $enable) {
	$post .= sprintf('<apps:property name="enable" value="%s" />',
			 $enable ? 'true' : 'false');
    }

    if ($enable) {
	if ($enable_for) {
	    $post .= "<apps:property name='enableFor' value='$enable_for' />";
	}

	if ($action) {
	    if ($action ne 'KEEP'
		and $action ne 'ARCHIVE'
		and $action ne 'DELETE'
		) {
		die "action must be KEEP, ARCHIVE or DELETE";
	    }

	    $post .= "<apps:property name='action' value='$action' />";
	}
    }

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);

};

override 'UpdateIMAP' => sub {
    my $self = shift;
    my %options = shift;

    my $enable = $options{'enable'};

    $self->google()->Login();
    my $url = $self->base_url().$self->google->domain().'/'.$self->user().'/imap';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    if (defined $enable) {
	$post .= sprintf('<apps:property name="enable" value="%s" />',
			 $enable ? 'true' : 'false');
    }

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);

};

override 'UpdateVacationResponder' => sub {
    my $self = shift;
    my %options = @_;

    my $enable   = $options{'enable'};
    my $subject  = $options{'subject'};
    my $message  = $options{'message'};
    my $contacts = $options{'contactsOnly'};

    $self->google->Login();
    my $url = $self->base_url().$self->google->domain.'/'.$self->user.'/vacation';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    $post .= sprintf('<apps:property name="enable" value="%s" />',
		     $enable ? 'true' : 'false');

    if (defined $enable) {
	$post .= sprintf('<apps:property name="subject" value="%s" />',
			 defined $subject ? $subject : '');

	$post .= sprintf('<apps:property name="message" value="%s" />',
			 defined $message ? $message : '');

	$post .= sprintf('<apps:property name="contactsOnly" value="%s" />',
			 $contacts ? 'true' : 'false');

    }

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);
};

override 'UpdateSignature' => sub {
    my $self = shift;
    my %options = shift;

    my $sig = $options{'signature'};

    $self->google->Login();
    my $url = $self->base_url().$self->google->domain.'/'.$self->user.'/signature';

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    $post .= sprintf('<apps:property name="signature" value="%s" />',
		     $sig ? $sig : '');

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);

};

override 'UpdateLanguage' => sub {
    my $self = shift;
    my %options = shift;

    my $lang = $options{'language'};

    $self->google->Login();
    my $url = $self->base_url().$self->google->domain.'/'.$self->user.'/language';

    if ($lang !~ /^\w\w(?:-\w\w)?/i) {
	$lang = 'en-US';
    }

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    $post .= sprintf('<apps:property name="language" value="%s" />',
		     $lang ? $lang : '');

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);

};

override 'UpdateGeneral' => sub {
    my $self    = shift;
    my %options = @_;

    $self->google->Login();
    my $url = $self->base_url().$self->google->domain.'/'.$self->user.'/general';

    foreach my $opt qw(shortcuts arrows snippets unicode) {
	$options{$opt} = $options{$opt}? 'true':'false';
    }

    my $post = '<?xml version="1.0" encoding="utf-8"?>';
    $post .= '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:apps="http://schemas.google.com/apps/2006">';

    foreach my $opt (keys %options) {
	if (defined $options{$opt}) {
	    $post .= sprintf ("<apps:property name=\"%s\" value=\"%s\" />",
			      $opt, $options{$opt});
	}
    }

    $post .= '</atom:entry>';

    return $self->google->Request('PUT', $url, $post);

};

no Moose;
1;

__END__

=head1 NAME

VUser::Google::EmailSettings::V2_0 - Support version 2.0 of the Google Email Settings API

=head1 SEE ALSO

L<VUser::Google::EmailSettings>, L<VUser::Google::ApiProtocol>,
L<VUser::Google::ApiProtocol::V2_0>

=over 4

=item Google Email Settings API

http://code.google.com/apis/apps/email_settings/developers_guide_protocol.html

=back

=head1 BUGS

Report bugs at http://code.google.com/p/vuser/issues/list.

=head1 AUTHOR

Randy Smith, perlstalker at vuser dot net

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
