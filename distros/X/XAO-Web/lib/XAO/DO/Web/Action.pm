=head1 NAME

XAO::DO::Web::Action - base for mode-dependant displayable objects

=head1 SYNOPSIS

 package XAO::DO::Web::Fubar;
 use strict;
 use XAO::Objects;
 use XAO::Errors qw(XAO::DO::Web::Fubar);
 use base XAO::Objects->load(objname => 'Web::Action');


 # <%Fubar mode='foo'%>
 #
 sub display_foo ($@) {
    ...
 }

 # <%Fubar mode='kick' target='ass'%>
 #
 sub data_kick ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    my $target=$args->{'target'} || 'self';
    return {
        force   => $self->siteconfig->get("/targets/$target/force"),
        target  => $target,
    }
 }

 # Gets called with prepared data
 #
 sub display_kick ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    dprint "force=",$args->{'force'};
    ...
 }

 # Data only method, will output JSON
 # (will also set content-type to application/json!)
 #
 # <%Fubar mode='api'%>
 #
 # Data prepared as above, but displayed with a custom
 # display method:
 #
 # <%Fubar mode='api' displaymode='api-summary'%>
 #
 sub data_api ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    return $self->data_kick($args);
 }

 sub display_api_summary ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    return $self->textout($args->{'data'}->{'target'}.' will get kicked');
 }

 # This is obsolete, but still supported
 #
 sub check_mode ($$) {
     my $self=shift;
     my $args=get_args(\@_);
     my $mode=$args->{'mode'};
     if($mode eq "foo") {
         $self->foo($args);
     }
     elsif($mode eq "kick") {
         $self->kick($args);
     }
     else {
         $self->SUPER::check_mode($args);
     }
 }

=head1 DESCRIPTION

Very simple object with overridable check_mode method.
Simplifies implementation of objects with arguments like:

 <%Fubar mode="kick" target="ass"%>

The code will attempt to find and call a "data_kick" method first
(dashes in 'mode' are replaced with underscores). It needs to return
some data, a hash or an array reference typically. If there is no
matching data_* method found then no data is built.

The next step is to try finding a "display_kick" method. If it exists
it is called with original arguments plus "data" set to the data
received. If there is no data, then there is no extra argument added to
the display_* method (and should there be a 'data' argument it is not
modified).

The name of the data producing method is derived from 'datamode'
defaulting to 'mode' arguments. The name of display method is derived
from 'displaymode' defaulting to 'mode' arguments. This allows to reuse
the same data builder with various "views", aka display methods. You can
also force data display in the presense of a custom display method by
setting 'displaymode' to 'data'.

If there is a data_* method, but there is no display_* method, then the
default is to call display_data() -- which outputs the data in a format
given by 'format' argument (only JSON and XML is supported currently).

If there are both data_* and display_* methods then the output depends
on its content.

If there is no data_* and no display_* then a check_mode() method is
called that needs to work out what needs to be done. This is an obsolete
practice.

The default check_mode() method does not have any functionality and always
simply throws an error with the content of 'mode':

 throw $self "check_mode - unknown mode ($mode)";

Remember that using "throw $self" you actually throw an error that
depends on the namespace of your object and therefore can be caught
separately if required.

=cut

###############################################################################
package XAO::DO::Web::Action;
use strict;
use POSIX qw(strftime);
use JSON;
use Error qw(:try);
use XAO::Objects;
use XAO::Utils qw(:debug :args :math :html);

use base XAO::Objects->load(objname => 'Web::Page');

sub get_mode_sub ($$$$;$);

###############################################################################

sub display ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $data_sub=$self->get_mode_sub('data',$args->{'datamode'},$args->{'mode'});

    my $display_sub=$self->get_mode_sub('display',$args->{'displaymode'},$args->{'mode'},$data_sub);

    # Preparing the data, if data method is known
    #
    my $data;
    if($data_sub) {

        # We catch errors in generating data and we provide a storage
        # for default data.
        #
        my $default_data;
        try {
            $data=$data_sub->($self,$args,{
                default_data_ref    => \$default_data,
            });

            # Adding a status when possible to unify the results
            #
            if(ref $data eq 'HASH') {
                $data->{'status'}||='success';
            }
        }
        otherwise {
            my $e=shift;
            my $etext="$e";

            # If the error looks like {{CODE: Text}} or {{Text}}
            # we trust the thrower and take the code and the text from
            # within brackets.
            #
            my $ecode;
            if($etext=~/\{\{(?:([A-Z0-9_-]+):\s*)?(.*?)\s*\}\}/) {
                $ecode=$1;
                $etext=$2;
            }

            $ecode||='UNKNOWN';

            # If default data was populated by the routine we take it.
            #
            $data=$default_data || { };

            # If we had no data, or the default data does not have error
            # code and message -- adding them.
            #
            if(ref $data eq 'HASH') {
                $data->{'status'}||='error';
                $data->{'error_code'}||=$ecode;
                $data->{'error_message'}||=$etext;
                $data->{'error_time'}||=time;
            }
        };
    }

    # Displaying the data. There is always a display method, even if
    # it's a reference to default check_mode or display_data methods.
    #
    if($data) {
        $display_sub->($self,$args,{
            data    => $data,
        });
    }
    else {
        $display_sub->($self,$args);
    }
}

###############################################################################

sub get_mode_sub ($$$$;$) {
    my ($self,$prefix,$modecust,$modegen,$data_sub)=@_;

    my $mode=$modecust || $modegen || '-no-mode';

    my $subcache=$self->{'_sub_cache'};
    if(!$subcache) {
        $self->{'_sub_cache'}=$subcache={ };
    }

    my $subcachekey=$prefix.':'.$mode;
    if(exists $subcache->{$subcachekey}) {
        return $subcache->{$subcachekey};
    }

    # Converting mode to a sub name.
    #
    (my $subname=$mode)=~s/-/_/g;

    # Only lowercase alphanumerics are supported.
    #
    $subname=~/^[a-z0-9_]+$/ ||
        throw $self "- bad mode '$mode'";

    # There may be data producing method and/or a display
    # method. Checking for both.
    #
    my $subref=$self->can($prefix.'_'.$subname);

    # When a non-generic mode is given ('datamode' or 'displaymode') not
    # having a subroutine is a hard error.
    #
    if($modecust && !$subref) {
        throw $self "- no $prefix routine found for '$modecust'";
    }

    # When there is no display method we either call display_data
    # when there is data, or the check_mode if there is no data for
    # compatibility with legacy code.
    #
    if($prefix eq 'display' && !$subref) {
        if($data_sub) {
            $subref=$self->can('display_data');
        }
        else {
            $subref=$self->can('check_mode');
        }
    }

    # Storing to speed up future calls
    #
    $subcache->{$subcachekey}=$subref;

    return $subref;
}

###############################################################################

sub json ($) {
    my $self=shift;

    my $json=$self->{'cached_json'};

    return $json if $json;

    $json=JSON->new->utf8;

    if($self->siteconfig->get('test_site')) {
        $json->pretty->canonical;
    }

    return $self->{'cached_json'}=$json;
}

###############################################################################

# Default data display. Called by default for data_* methods and can
# also be called by other display_* methods as needed.

sub display_data ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $data=$args->{'data'} || throw $self "- no data";
    ref($data) || throw $self "- invalid data";

    my $format=$args->{'format'} || 'json';

    if($format eq 'json') {
        $self->object(objname => 'Web::Header')->expand(
            type        => 'application/json',
        );

        $self->finaltextout($self->json->encode($data));
    }
    elsif($format eq 'js' || $format eq 'json-embed') {

        # The trick with embedded JSON is that it is printed as
        # part of a larger page and as such has to be in characters that
        # are then encoded into bytes of the page final encoding.
        # JSON's to_json() call is exactly that, character output.
        #
        $self->textout(to_json($data));
    }
    elsif($format eq 'xml' || $format eq 'xml-embed') {
        my $xml_sub=$self->get_mode_sub('xml',$args->{'xmlmode'} || $args->{'mode'},$args->{'mode'});

        my $xml=$xml_sub->($self,$args,{
            data    => $data,
        });

        if($format eq 'xml') {
            $self->object(objname => 'Web::Header')->expand(
                type        => 'text/xml',
            );
        }

        $self->finaltextout($xml);
    }
    else {
        throw $self "- unknown format '$format'";
    }
}

###############################################################################

# Needs to be overriden in derived classes

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $mode=$args->{'mode'} || '<UNDEF>';
    throw $self "- unknown mode ($mode)";
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005-2013 Andrew Maltsev, Ejelta LLC

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
