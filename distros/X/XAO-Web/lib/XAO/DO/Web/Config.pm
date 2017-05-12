=head1 NAME

XAO::DO::Web::Config - XAO::Web site configuration object

=head1 SYNOPSIS

 sub init {
     my $self=shift;

     my $webconfig=XAO::Objects->new(objname => 'Web::Config');

     $self->embed(web => $webconfig);
 }

=head1 DESCRIPTION

This object provides methods specifically for XAO::Web objects. It is
supposed to be embedded into XAO::DO::Config object by a web server
handler when site is initialized.

=cut

###############################################################################
package XAO::DO::Web::Config;
use CGI::Cookie;
use XAO::Utils;
use XAO::Cache;
use POSIX qw(mktime);
use XAO::Errors qw(XAO::DO::Web::Config);

# Prototypes
#
sub add_cookie ($@);
sub cgi ($$);
sub cleanup ($);
sub clipboard ($);
sub cookies ($);
sub disable_special_access ($);
sub embeddable_methods ($);
sub enable_special_access ($);
sub header ($@);
sub header_args ($@);
sub get_cookie ($$;$);
sub new ($@);

##
# Package version for checks and reference
#
use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Config.pm,v 2.4 2007/12/05 23:49:21 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=head1 METHODS

=over

=cut

###############################################################################

=item add_cookie (@)

Adds an HTTP cookie into the internal list. Parameters are a hash in the
same format as for CGI->cookie() method (see L<CGI>).

If a cookie with the same name, path (and domain if set) is already in
the list from a previous call to add_cookie() then it gets replaced.

Think of it as if you are adding cookies to you final HTTP response as
XAO::Web handler will get all the cookies collected during template
processing and send them out for you.

Examples:

 $config->add_cookie($cookie);

 $config->add_cookie(-name => 'sessionID',
                     -value => 'xyzzy',
                     -expires=>'+1h');

For convenience, if there is a '-domain' argument and it refers to a
list of domains the cookie is expanded into a set of cookies for all
these domains.

The get_cookie() method takes into consideration values set with
add_cookie() as a priority over CGI cookies received.

=cut

sub add_cookie ($@) {
    my $self=shift;
    my $cookie=(@_==1 ? $_[0] : get_args(\@_));

    # We should only be getting hash based cookie data. Attempting to
    # unbake it if we got a baked one.
    #
    if(!ref($cookie)) {
        eprint "Passing baked cookies to ".$self."::add_cookie() is STRONGLY DEPRECATED!";

        use CGI::Util qw();

        # Expecting something like:
        # foo=bar; path=/; expires=Wed, 16-Dec-2015 03:32:33 GMT
        #
        my ($nv,@params)=split(/\s*;\s*/,$cookie);

        my ($name,$value);
        if($nv=~/^\s*(.+)\s*=\s*(.*?)\s*$/) {
            $name=CGI::Util::unescape($1);
            $value=[map { CGI::Util::unescape($_) } split(/&/,$2)];
            $value=$value->[0] if @$value==1;
        }
        else {
            eprint "Unparsable baked cookie '$cookie' in add_cookie(), NOT SET";
            return;
        }

        my %chash=(
            -name   => $name,
            -value  => $value,
        );

        foreach my $p (@params) {
            $p=~/^\s*(.+)\s*=\s*(.*?)\s*$/ || next;
            my ($pn,$pv)=(lc($1),$2);
            if   ($pn eq 'domain')  { $chash{'-domain'}=$pv; }
            elsif($pn eq 'path')    { $chash{'-path'}=$pv; }
            elsif($pn eq 'expires') { $chash{'-expires'}=$pv; }
            elsif($pn eq 'max-age') { $chash{'-max-age'}=$pv; }
            elsif($pn eq 'secure')  { $chash{'-secure'}=$pv; }
            elsif($pn eq 'httponly'){ $chash{'-httponly'}=$pv; }
        }

        $cookie=\%chash;
    }

    # Recursively expanding if multiple domains are given.
    #
    if($cookie->{'-domain'} && ref($cookie->{'-domain'})) {
        my $dlist=$cookie->{'-domain'};
        foreach my $domain (@$dlist) {
            $self->add_cookie(merge_refs($cookie,{
                -domain     => $domain,
            }));
        }
        return;
    }

    # If the new cookie has the same name, domain and path
    # as previously set one - we replace it.
    #
    if($self->{'cookies'}) {
        my $cnew=CGI::Cookie->new($cookie);

        for(my $i=0; $i!=@{$self->{'cookies'}}; $i++) {
            my $c=$self->{'cookies'}->[$i];

            next unless ref($c) && ref($c) eq 'HASH';

            my $cstored=CGI::Cookie->new($c);

            my $dnew=$cnew->domain();
            my $dstored=$cstored->domain();

            ### dprint "...comparing ".$cnew->name()." with ".$cstored->name();

            next unless
                $cnew->name() eq $cstored->name() &&
                $cnew->path() eq $cstored->path() &&
                ((!defined($dnew) && !defined($dstored)) || (defined($dnew) && defined($dstored) && $dnew eq $dstored));

            ### dprint "....override!";

            $self->{'cookies'}->[$i]=$cookie;

            return $cookie;
        }
    }

    push(@{$self->{'cookies'}},$cookie);

    return $cookie;
}

###############################################################################

=item cgi (;$)

Returns or sets standard CGI object (see L<CGI>). In future versions this
would probably be converted to CGI::Lite or something similar, so do not
rely to much on the functionality of CGI.

Obviously you should not call this method to set CGI object unless you
are 100% sure you know what you're doing. And even in that case you have
to call enable_special_access() in advance.

Example:

 my $cgi=$self->cgi;
 my $name=$cgi->param('name');

Or just:

 my $name=$self->cgi->param('name');

=cut

sub cgi ($$) {
    my ($self,$newcgi)=@_;

    return $self->{'cgi'} unless $newcgi;

    if($self->{'special_access'}) {
        $self->{'cgi'}=$newcgi;
        return $newcgi;
    }

    throw XAO::E::DO::Web::Config
          "cgi - storing new CGI requires enable_special_access()";
}

###############################################################################

=item cleanup ()

Removes CGI object, cleans up clipboard. No need to call manually,
usually is called as part of XAO::DO::Config cleanup().

=cut

sub cleanup ($) {
    my $self=shift;
    delete $self->{'cgi'};
    delete $self->{'clipboard'};
    delete $self->{'cookies'};
    delete $self->{'header_args'};
    delete $self->{'header_printed'};
    delete $self->{'special_access'};
}

###############################################################################

=item clipboard ()

Returns clipboard XAO::SimpleHash object. Useful to keep temporary data
between different XAO::Web objects. Cleaned up for every session.

=cut

sub clipboard ($) {
   my $self=shift;
   $self->{clipboard}=XAO::SimpleHash->new() unless $self->{clipboard};
   $self->{clipboard};
}

###############################################################################

=item cookies ()

Returns reference to an array of prepared cookies.

=cut

sub cookies ($) {
    my $self=shift;

    my @baked;
    foreach my $c (@{$self->{'cookies'}}) {
        if(ref($c) && ref($c) eq 'HASH') {
            push @baked,CGI::Cookie->new(%{$c});
        }
        else {
            push @baked,$c;
        }
    }

    return \@baked;
}

###############################################################################

=item disable_special_access ()

Disables use of cgi() method to set a new value.

=cut

sub disable_special_access ($) {
    my $self=shift;
    delete $self->{special_access};
}

###############################################################################

=item embeddable_methods ()

Used internally by global Config object, returns an array with all
embeddable method names -- add_cookie(), cgi(), clipboard(), cookies(),
header(), header_args().

=cut

sub embeddable_methods ($) {
    qw(add_cookie cgi clipboard cookies header header_args get_cookie);
}

###############################################################################

=item enable_special_access ()

Enables use of cgi() method to set a new value. Normally you do
not need this method.

Example:

 $config->enable_special_access();
 $config->cgi(CGI->new());
 $config->disable_special_access();

=cut

sub enable_special_access ($) {
    my $self=shift;
    $self->{special_access}=1;
}

###############################################################################

=item header (@)

Returns HTTP header. The same as $cgi->header and accepts the same
parameters. Cookies added before by add_cookie() method are also
included in the header.

Returns header only once, on subsequent calls returns undef.

B<NOTE:> In mod_perl environment CGI will send the header itself and
return empty string. Be carefull to check the result for
C<if(defined($header))> instead of just C<if($header)>!

As with the most of Web::Config methods you do not need this method
normally. It is called automatically by web server handler at the end of
a session before sending out session results.

=cut

sub header ($@) {
    my $self=shift;

    return undef if $self->{'header_printed'};

    $self->header_args(@_) if @_;
    $self->{'header_printed'}=1;

    # There is a silly bug (or a truly misguided undocumented feature)
    # in CGI. It works with headers correctly only if the first header
    # it gets starts with a dash. We used to supply CGI::header() with a
    # hash and that resulted in sometimes un-dashed elements getting to
    # be the first in the list, resulting in mayhem -- completely broken
    # header output like this sent without any warnings:
    #
    #    HTTP/1.0 foo
    #    Server: Apache
    #    Status: foo
    #    Window-Target: ARRAY(0xc5f5e8)
    #    P3P: policyref="/w3c/p3p.xml", CP="-expires"
    #    Set-Cookie: -cookie
    #    Expires: -Charset
    #    Date: Thu, 07 Aug 2014 22:41:35 GMT
    #    Content-Disposition: attachment; filename="no-cache"
    #    Now
    #    Content-Type: P3P; charset=-cache_control
    #
    # This never happened in years of using perl below version 5.18,
    # probably due to different internal hash algorithm that never
    # put undashed elements to the front.
    #
    # Using the always present '-cookie' header to fill the front row.
    #
    my $header_args=$self->{'header_args'} || { };
    my @headers=(
        '-cookie'   => ($header_args->{'-cookie'} || $header_args->{'Cookie'} || $self->cookies || []),
        %$header_args,
    );

    return $self->cgi->header(@headers);
}

###############################################################################

sub header_printed ($) {
    my $self=shift;
    return $self->{'header_printed'};
}

###############################################################################

=item header_args (%)

Sets some parameters for header generation. You can use it to change
page status for example:

 $config->header_args(-Status => '404 File not found');

Accepts the same arguments CGI->header() accepts.

Header names can be any of 'Header-Name', 'header-name', 'header_name',
or '-Header_name'. All variants are normalized to all-lowercase
underscored to make values assigned later in the code trump the earlier.

=cut

sub header_args ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    @{$self->{'header_args'}}{map {
        $_=lc($_);
        $_=~s/-/_/g;
        $_=~s/^_+//;
        $_;
    } keys %{$args}}=values %{$args};

    return $self->{'header_args'};
}

###############################################################################

=item get_cookie ($;$)

Return cookie value for the given cookie name. Unless the second
parameter is true, for cookies already set earlier in the same session
it would return the value as set, not the value as it was originally
received.

B<NOTE:> The path and domain of cookies is ignored when checking for
earlier set cookies!

=cut

sub get_cookie ($$;$) {
    my ($self,$name,$original)=@_;

    if(!defined $name || !length($name)) {
        eprint "No cookie name given to ".ref($self)."::get_cookie()";
        for(my $i=0; $i<3; ++$i) {
            dprint "..STACK: ".join('|',map { defined($_) ? $_ : '<UNDEF>' } caller($i));
        }
        return undef;
    }

    my $value;

    if(!$original) {
        foreach my $c (@{$self->{'cookies'}}) {
            my $cookie=CGI::Cookie->new($c);

            if($cookie->name() eq $name) {
                my $value=$cookie->value;

                my $expires_text=$cookie->expires;

                if($expires_text =~ /(\d{2})\W+([a-z]{3})\W+(\d{4})\W+(\d{2})\W+(\d{2})\W+(\d{2})/i) {
                    my $midx=index('janfebmaraprmayjunjulaugsepoctnovdec',lc($2));
                    if($midx>=0) {
                        $midx/=3;
                        local($ENV{'TZ'})='UTC';
                        my $expires=mktime($6,$5,$4,$1,$midx,$3-1900);
                        if($expires <= time) {
                            $value=undef;
                        }
                    }
                    else {
                        eprint "Invalid month '$2' in cookie '$name' expiration '$expires_text'";
                    }
                }
                else {
                    eprint "Invalid expiration '$expires_text' for cookie '$name'";
                }

                return $value;
            }
        }
    }

    my $cgi=$self->cgi;

    if(!$cgi) {
        eprint "Called get_cookie() before CGI is available";
        return undef;
    }

    return $self->cgi->cookie($name);
}

###############################################################################

=item new ($$)

Creates a new empty configuration object.

=cut

sub new ($@) {
    my $proto=shift;
    bless {},ref($proto) || $proto;
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Config>.
