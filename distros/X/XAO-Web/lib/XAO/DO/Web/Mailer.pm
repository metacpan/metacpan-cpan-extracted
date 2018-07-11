=head1 NAME

XAO::DO::Web::Mailer - executes given template and sends results via e-mail

=head1 SYNOPSIS

 <%Mailer
   to="foo@somehost.com"
   from="bar@otherhost.com"
   subject="Your order '<%ORDER_ID/f%>' has been shipped"
   text.path="/bits/shipped-mail-text"
   html.path="/bits/shipped-mail-html"
   ORDER_ID="<%ORDER_ID/f%>"
 %>

=head1 DESCRIPTION

Displays nothing, just sends message.

Arguments are:

 to          => e-mail address of the recepient; default is taken from
                userdata->email if defined.
 cc          => optional e-mail addresses of secondary recepients
 bcc         => optional e-mail addresses of blind CC recepients
 from        => optional 'from' e-mail address, default is taken from
                'from' site configuration parameter.
 subject     => message subject;
 [text.]path => text-only template path (required);
 html.path   => html template path;
 date        => optional date header, passed as is;
 pass        => pass parameters of the calling template to the mail template;
 ARG         => VALUE - passed to Page when executing templates;

If 'to', 'from' or 'subject' are not specified then get_to(), get_from()
or get_subject() methods are called first. Derived class may override
them. 'To', 'cc' and 'bcc' may be comma-separated addresses lists.

To send additional attachments along with the email pass the following
arguments (where N can be any alphanumeric tag):

 attachment.N.type        => MIME type for attachment (image/gif, text/plain, etc)
 attachment.N.filename    => download filename for the attachment (optional)
 attachment.N.disposition => attachment disposition (optional, 'attachment' by default)
 attachment.N.path        => path to a template for building the attachment
 attachment.N.template    => inline template for building the attachment
 attachment.N.unparsed    => use the template literally, without xao-parsing
 attachment.N.pass        => pass all arguments of the calling template
 attachment.N.ARG         => VALUE - passed literally as ARG=>VALUE to the template

The configuration for Web::Mailer is kept in a hash stored in the site
configuration under 'mailer' name. Normally it is not required, the
default is to use sendmail for delivery. The parameters are:

 method     => either 'local' or 'smtp'
 agent      => server name for `smtp' or binary path for `local'
 from       => either a hash reference or a scalar with the default
                `from' address.
 override_from
            => if set overrides the from address
 override_to
            => if set overrides all to addresses and always sends to
               the given address. Useful for debugging.
 override_except
            => addresses listed here are OK to go through. Matching
               is done on substrings ingoring case. This options makes
               sense only in pair with override_to.
 subject_prefix
            => optional fixed prefix for all subjects
 subject_suffix
            => optional fixed suffix for all subjects

If `from' is a hash reference then the content of `from' argument to the
object is looked in keys and the value is used as actual `from'
address. This can be used to set up rudimentary aliases:

 <%Mailer
   ...
   from="customer_support"
   ...
 %>

 mailer => {
    from => {
        customer_support => 'support@foo.com',
        technical_support => 'tech@foo.com',
    },
    ...
 }

In that case actual from address will be `support@foo.com'. By default
if `from' in the configuration is a hash and there is no `from'
parameter for the object, `default' is used as the key.

=cut

###############################################################################
package XAO::DO::Web::Mailer;
use strict;
use Encode;
use MIME::Lite 2.117;
use XAO::Objects;
use XAO::Utils;
use base XAO::Objects->load(objname => 'Web::Page');

our $VERSION='2.011';

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('/mailer') || {};

    my $to=$args->{'to'} ||
           $self->get_to($args) ||
           throw $self "display - no 'to' given";

    my $cc=$args->{'cc'} || '';
    my $bcc=$args->{'bcc'} || '';

    my @ovhdr;
    if(my $override_to=$config->{'override_to'}) {
        my $to_new;

        if(my $override_except=$config->{'override_except'}) {
            $override_except=[ split(/\s*[,;]\s*/,$override_except) ] unless ref($override_except) eq 'ARRAY';
            $override_except=[ map { lc } @$override_except ];

            my %pass;
            my %override;
            foreach my $email (split(/\s*[,;]+\s*/,"$to,$cc,$bcc")) {
                if(grep { index(lc($email),$_)>=0 } @$override_except) {
                    $pass{$email}=1;
                }
                else {
                    $override{$email}=1;
                }
            }

            $to_new=join(', ',(keys %pass),(%override ? ($override_to) : ()));
        }
        else {
            $to_new=$override_to;
        }

        dprint ref($self)."::display - overriding to='$to', cc='$cc', bcc='$bcc' with to='$to_new', cc='', bcc=''";

        push(@ovhdr,('X-XAO-Web-Mailer-To' => $to)) if $to;
        push(@ovhdr,('X-XAO-Web-Mailer-Cc' => $cc)) if $cc;
        push(@ovhdr,('X-XAO-Web-Mailer-Bcc' => $bcc)) if $bcc;

        $to=$to_new;
        $cc='';
        $bcc='';
    }

    my $from=$args->{'from'};
    if(!$from) {
        $from=$config->{'from'};
        $from=$from->{'default'} if ref($from);
    }
    else {
        $from=$config->{'from'}->{$from} if ref($config->{'from'}) &&
                                            $config->{'from'}->{$from};
    }
    $from || throw $self "display - no 'from' given";

    if(my $override_from=$config->{'override_from'}) {
        if($override_from ne $from) {
            dprint ref($self)."::display - overriding from='$from' with '$override_from'";

            push(@ovhdr,('X-XAO-Web-Mailer-From' => $from));

            $from=$override_from;
        }
    }

    my $from_hdr=$from;
    if($from =~ /^\s*.*\s+<(.*\@.*)>\s*$/) {
        $from=$1;
    }
    elsif($from =~ /^\s*(.*\@.*)\s+\(.*\)\s*$/) {
        $from=$1;
    }
    else {
        $from=~s/^\s*(.*?)\s*$/$1/;
    }

    my $subject=$args->{'subject'} || $self->get_subject() || 'No subject';

    if(my $subject_prefix=$config->{'subject_prefix'}) {
        $subject=$subject_prefix.($subject_prefix=~/\s$/ ? '':' ').$subject;
    }

    if(my $subject_suffix=$config->{'subject_suffix'}) {
        $subject=$subject.($subject_suffix=~/\s$/ ? '':' ').$subject_suffix;
    }

    # Charset for outgoing mail. Either /mailer/charset or /charset
    #
    my $charset=$config->{'charset'} || $self->siteconfig->get('charset') || undef;
    ### dprint "...mailer charset=",$charset;

    # Subject might contain 8-bit characters, but being a header it
    # needs to be 7-bit. MIME::Lite does not do that.
    #
    if(Encode::is_utf8($subject)) {
        $subject=Encode::encode('MIME-Q',$subject);

        # The output from MIME-Q is a multi-line string separated by \r\n
        # and that \r appears to be duplicated by some MTA implementations.
        # The rest of MIME::Lite headers are output with \n, so sticking to
        # that.
        #
        $subject=~s/\r//sg;
    }

    # Encoding by default in MIME::Lite is "binary", which means no
    # processing at all. That might break on some gateway and MIME
    # validator at https://tools.ietf.org/tools/msglint/ balks
    # at it. Keeping "binary" here for compatibility with older
    # deployments, but allowing to override it.
    #
    my $transfer_encoding=$config->{'transfer_encoding'} || 'binary';
    ### dprint "...mailer transfer_encoding=",$transfer_encoding;

    # Getting common args from the parent template if needed.
    #
    my $common=$self->pass_args($args->{'pass'});

    # Parsing text template
    #
    my $page=$self->object;
    my $text;
    if($args->{'text.path'} || $args->{'path'} || $args->{'text.template'} || $args->{'template'}) {
        $text=$page->expand($args,$common,{
            path        => $args->{'text.path'} || $args->{'path'},
            template    => $args->{'text.template'} || $args->{'template'},
        });
    }

    # Parsing HTML template
    #
    my $html;
    if($args->{'html.path'} || $args->{'html.template'}) {
        $html=$page->expand($args,$common,{
            path        => $args->{'html.path'},
            template    => $args->{'html.template'},
        });
    }

    defined $text || defined $html ||
        throw $self "- no text for either html or text part";

    # Preparing attachments if any
    #
    my @attachments;
    foreach my $k (sort keys %$args) {
        next unless $k=~/^attachment\.(\w+)\.type$/;
        my $id=$1;

        my %data=(
            Type        => $args->{$k},
            Filename    => $args->{'attachment.'.$id.'.filename'} || '',
            Disposition => $args->{'attachment.'.$id.'.disposition'} || 'attachment',
        );

        if($args->{'attachment.'.$id.'.template'} || $args->{'attachment.'.$id.'.path'}) {
            my $objargs={ };
            foreach my $kk (keys %$args) {
                next unless $kk =~ /^attachment\.$id\.(.*)$/;
                $objargs->{$1}=$args->{$kk};
            }

            my $content;
            if($args->{'attachment.'.$id.'.unparsed'}) {
                if(defined $args->{'attachment.'.$id.'.template'}) {
                    $content=$args->{'attachment.'.$id.'.template'};
                }
                elsif(defined $args->{'attachment.'.$id.'.path'}) {
                    $content=$self->object->expand(
                        path        => $args->{'attachment.'.$id.'.path'},
                        unparsed    => 1,
                    );
                }
            }
            else {
                my $obj=$self->object(objname => ($objargs->{'objname'} || 'Page'));
                delete $objargs->{'objname'};

                if($args->{'attachment.'.$id.'.pass'}) {
                    $objargs=$self->pass_args($args->{'attachment.'.$id.'.pass'},$objargs);
                }

                $content=$obj->expand($objargs);
            }

            # The content should be bytes, but if it is in
            # characters it needs to be converted or MIME::Lite will
            # croak.
            #
            $content=Encode::encode($charset || 'utf8',$content) if utf8::is_utf8($content);

            $data{'Data'}=$content;
        }
        elsif($args->{'attachment.'.$id.'.file'}) {
            throw $self "- attaching files not implemented";
        }
        else {
            throw $self "- no path/template/file given for attachment '$id'";
        }

        push(@attachments,\%data);
    }

    # Preparing mailer and storing content in.
    #
    # MIME::Lite does not do anything with encoding and does not really
    # support perl unicode. It does not apply any filtering to its
    # output streams. With that in mind, we need to supply it with
    # bytes, so doing our own encoding.
    #
    # Thanks Brian Mielke for catching this!
    #
    # TODO: Switch to Email::MIME instead of MIME::Lite!
    #
    my @stdhdr=(
        From        => $from_hdr,
        FromSender  => $from,
        To          => $to,
        Subject     => $charset && utf8::is_utf8($subject) ? Encode::encode($charset,$subject) : $subject,
    );

    push(@stdhdr,@ovhdr);

    my $mailer;

    # Simple case, HTML only, no attachments
    #
    if(defined $html && !defined $text && !@attachments) {
        $mailer=MIME::Lite->new(
            @stdhdr,
            Type        => 'text/html',
            Data        => $charset && utf8::is_utf8($html) ? Encode::encode($charset,$html) : $html,
            Datestamp   => 0,
            Encoding    => $transfer_encoding,
        );
        $mailer->attr('content-type.charset' => $charset) if $charset;
    }

    # TEXT only, no attachments
    #
    elsif(defined $text && !defined $html && !@attachments) {
        $mailer=MIME::Lite->new(
            @stdhdr,
            Type        => 'text/plain',
            Data        => $charset && utf8::is_utf8($text) ? Encode::encode($charset,$text) : $text,
            Datestamp   => 0,
            Encoding    => $transfer_encoding,
        );
        $mailer->attr('content-type.charset' => $charset) if $charset;
    }

    # HTML, TEXT, and/or attachments
    #
    else {
        my $text_part;
        if(defined $text) {
            $text_part=MIME::Lite->new(
                Type        => 'text/plain',
                Data        => $charset && utf8::is_utf8($text) ? Encode::encode($charset,$text) : $text,
                Encoding    => $transfer_encoding,
            );

            $text_part->delete('X-Mailer');
            $text_part->delete('Date');

            $text_part->attr('content-type.charset' => $charset) if $charset;
        }

        my $html_part;
        if(defined $html) {
            $html_part=MIME::Lite->new(
                Type        => 'text/html',
                Data        => $charset && utf8::is_utf8($html) ? Encode::encode($charset,$html) : $html,
                Encoding    => $transfer_encoding,
            );

            $html_part->delete('X-Mailer');
            $html_part->delete('Date');

            $html_part->attr('content-type.charset' => $charset) if $charset;
        }

        $mailer=MIME::Lite->new(
            @stdhdr,
            Type        => @attachments ? 'multipart/mixed' : 'multipart/alternative',
            Datestamp   => 0,
        );

        if($text_part && $html_part && @attachments) {
            my $alt_part=MIME::Lite->new(
                Type        => 'multipart/alternative',
                Datestamp   => 0,
            );

            $alt_part->delete('X-Mailer');
            $alt_part->delete('Date');

            $alt_part->attach($text_part);
            $alt_part->attach($html_part);

            $mailer->attach($alt_part);
        }
        else {
            $mailer->attach($text_part) if $text_part;
            $mailer->attach($html_part) if $html_part;
        }

        # Adding attachments if any
        #
        foreach my $adata (@attachments) {
            $mailer->attach(%$adata);
        }
    }

    $mailer->add(Date => $args->{'date'}) if $args->{'date'};
    $mailer->add(Cc => $cc) if $cc;
    $mailer->add(Bcc => $bcc) if $bcc;
    $mailer->add('Reply-To' => $args->{'replyto'}) if $args->{'replyto'};

    # Sending
    #
    ### dprint $mailer->as_string;
    my $method=$config->{'method'} || 'local';
    my $agent=$config->{'agent'};
    if(lc($method) eq 'local') {
        if($agent) {
            $mailer->send('sendmail',$agent);
        }
        else {
            $mailer->send('sendmail');
        }
    }
    else {
        $mailer->send('smtp',$agent || 'localhost');
    }
}

###############################################################################

sub get_to ($%) {
    return '';
}

###############################################################################

sub get_from ($%) {
    return '';
}

###############################################################################

sub get_subject ($%) {
    return '';
}

###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
