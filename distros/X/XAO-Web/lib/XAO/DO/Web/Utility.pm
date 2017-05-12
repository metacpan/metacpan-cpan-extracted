=head1 NAME

XAO::DO::Web::Utility - Miscellaneous utility displayable functions

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

This is a collection of various functions that do not fit well into
other objects and are not worth creating separate objects for them (at
least at present time).

=head1 METHODS

Utility object is based on Action object (see L<XAO::DO::Web::Action>)
and therefor what it does depends on the "mode" argument.

For each mode there is a separate method with usually very similar
name. See below for the list of mode names and their method
counterparts.

=over

=cut

###############################################################################
package XAO::DO::Web::Utility;
use strict;
use POSIX qw(mktime);
use XAO::Utils qw(:args :debug :html);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Utility.pm,v 2.3 2006/03/07 18:14:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub check_mode ($$) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode};
    if($mode eq "select-time-range") {
        $self->select_time_range($args);
    }
    elsif($mode eq "tracking-url") {
        $self->tracking_url($args);
    }
    elsif($mode eq "config-param") {
        $self->config_param($args);
    }
    elsif($mode eq "pass-cgi-params") {
        $self->pass_cgi_params($args);
    }
    elsif($mode eq "current-url") {
        $self->show_current_url($args);
    }
    elsif($mode eq "base-url") {
        $self->show_base_url($args);
    }
    elsif($mode eq "show-pagedesc") {
        $self->show_pagedesc($args);
    }
    elsif($mode eq "number-ordinal-suffix") {
        $self->number_ordinal_suffix($args);
    }
    else {
        $self->throw("check_mode - Unknown mode '$mode'");
    }
}

###############################################################################

=item 'tracking-url' => tracking_url (%)

Displays tracking URL for given carrier and tracking number.

Arguments are "carrier" and "tracknum". Supported carriers are:

=over

=item * 'usps'

=item * 'ups'

=item * 'fedex'

=item * 'dhl'

=item * 'yellow' (see http://www.yellowcorp.com/)

=back

Example:

 <%Utility mode="tracking-url" carrier="usps" tracknum="VV1234567890"%>

Would display:

 http://www.framed.usps.com/cgi-bin/cttgate/ontrack.cgi?tracknbr=VV1234567890

=cut

sub tracking_url ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $carrier=$args->{'carrier'} || '';
    my $tracknum=$args->{tracknum} || '';

    my $url;

    if(lc($carrier) eq 'usps') {
        $url='https://tools.usps.com/go/TrackConfirmAction.action?tRef=fullpage&tLc=1&tLabels=' . t2hq($tracknum);
    }
    elsif(lc($carrier) eq 'ups') {
        $url='http://wwwapps.ups.com/etracking/tracking.cgi?tracknum=' . t2hq($tracknum);
    }
    elsif(lc($carrier) eq 'fedex') {
        $url='https://www.fedex.com/apps/fedextrack/?action=track&tracknumbers=' . t2hq($tracknum);
    }
    elsif(lc($carrier) eq 'dhl') {
        $url='http://www.dhl-usa.com/cgi-bin/tracking.pl' .
             '?AWB=' . t2hq($tracknum) .
             'LAN=ENG&TID=US_ENG&FIRST_DB=US';
    }
    elsif(lc($carrier) eq 'yellow') {
        $tracknum=sprintf('%09u',int($tracknum));
        $url='http://www2.yellowcorp.com/cgi-bin/gx.cgi/applogic+yfsgentracing.E000YfsTrace' .
             '?diff=protrace&PRONumber=' . t2hq($tracknum);
    }
    else {
        eprint "Unknown carrier '$carrier'";
        $url='';
    }

    $self->textout($url);
}

###############################################################################

=item 'config-param' => config_param (%)

Displays site configuration parameter with given "name". Example:

 <%Utility mode="config-param" name="customer_support" default="aa@bb.com"%>

Would display whatever is set in site's Config.pm modules for variable
"customer_support" or "aa@bb.com" if it is not set.

=cut

sub config_param ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $config=$self->siteconfig;
  $args->{name} || throw XAO::E::DO::Web::Utility
                         "config_param - no 'name' given";
  my $value=$config->get($args->{name});
  $value=$args->{default} if !defined($value) && defined($args->{default});
  $self->textout($value) if defined $value;
}

###############################################################################

=item 'pass-cgi-params' => pass_cgi_params (%)

Builds a piece of HTML code containing current CGI parameters in either
form or query formats depending on "result" argument (values are "form"
or "query" respectfully).

List of parameters to be copied must be in "params" arguments and may
end with asterisk (*) to include parameters by template. In addition
to that you can exclude some parameters that wer listed in "params" by
putting their names (or name templates) into "except" argument.

Form example:

 <FORM METHOD="GET">
 <%Utility mode="pass-cgi-params" result="form" params="aa,bb,cc"%>
 <INPUT NAME="dd">
 </FORM>

Would produce:

 <FORM METHOD="GET">
 <INPUT TYPE="HIDDEN" NAME="aa" VALUE="current value of aa">
 <INPUT TYPE="HIDDEN" NAME="bb" VALUE="current value of bb">
 <INPUT TYPE="HIDDEN" NAME="bb" VALUE="current value of cc">
 <INPUT NAME="dd">
 </FORM>

Actual output would be slightly different because no carriage return
symbol would be inserted between hidden <INPUT> tags. This is done for
rare situations when your code is space sensitive and you do not want to
mess it up.

Query example:

 <A HREF="report.html?sortby=price&<%Utility
                                     mode="pass-cgi-params"
                                     result="query"
                                     params="*"
                                     except="sortby"
                                   %>">Sort by price</A>

If current page arguments were "sku=123&category=234&sortby=vendor" then
the output would be:

 <A HREF="report.html?sortby=price&sku=123&category=234">Sort by price</A>

For 'query' results it is convenient to also provide a 'prefix'
parameter that would be included in the output only if there are
parameters to copy. This allows to cleanly format URLs without extra '?'
or '&' symbols.

All special symbols in parameter values would be properly escaped, you
do not need to worry about that.

=cut

sub pass_cgi_params ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    # Creating list of exceptions
    #
    my %except;
    foreach my $param (split(/[,\s]/,$args->{except} || '')) {
        $param=~s/\s//gs;
        next unless length($param);
        if(index($param,'*') != -1) {
            $param=substr($param,0,index($param,'*'));
            foreach my $p ($self->cgi->param) {
                next unless index($p,$param) == 0;
                $except{$p}=1;
            }
            next;
        }
        $except{$param}=1;
    }

    # Expanding parameters in list
    #
    my @params;
    foreach my $param (split(/[,\s]/,$args->{params})) {
        $param=~s/\s//gs;
        next unless length($param);
        if(index($param,'*') != -1) {
            $param=substr($param,0,index($param,'*'));
            foreach my $p ($self->cgi->param) {
                next unless defined $p;
                next unless index($p,$param) == 0;
                push @params,$p;
            }
            next;
        }
        push @params,$param;
    }

    # Creating HTML code that will pass these parameters.
    #
    my $html;
    my $result=$args->{result} || 'query';
    foreach my $param (@params) {
        next if $except{$param};

        my $value=$self->cgi->param($param);
        next unless defined $value;

        if($result eq 'form') {
            $html.='<INPUT TYPE="HIDDEN" NAME="' . t2hf($param) . '" VALUE="' . t2hf($value) . '">';
        }
        else {
            $html.='&' if $html;
            $html.=t2hq($param) . '=' . t2hq($value);
        }
    }

    # No output if there are no parameters
    #
    if(defined $html) {
        $self->textout($args->{'prefix'}) if $args->{'prefix'};
        $self->textout($html);
    }
}

###############################################################################

=item 'current-url' => show_current_url ()

Prints out current page URL without parameters. Accepts the same
arguments as Page's pageurl method and displays the same value.

=cut

sub show_current_url ($;%) {
    my $self=shift;
    $self->textout($self->pageurl(@_));
}

###############################################################################

=item 'base-url' => show_base_url ()

Prints out base site URL without parameters. Accepts the same arguments
as Page's base_url() method and displays the same value.

=cut

sub show_base_url ($;%) {
    my $self=shift;
    $self->textout($self->base_url(@_));
}

###############################################################################

=item 'number-ordinal-suffix' => number_ordinal_suffix (%)

Displays a two-letter suffix to make a number into an ordinal, i.e. 2
into "2-nd", 43 into "43-rd", 1001 into "1001-st" and so on.

Takes one argument -- 'number'.

=cut

sub number_ordinal_suffix ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    use integer;
    my $number=int($args->{number} || 0);
    $number=-$number if $number<0;
    $number=$number % 100;
    my $nl=$number%10;
    my $suffix;
    if(($number>10 && $number<20) || $nl==0 || $nl>3) {
        $suffix='th';
    }
    elsif($nl == 1) {
        $suffix='st';
    }
    elsif($nl == 2) {
        $suffix='nd';
    }
    elsif($nl == 2) {
        $suffix='nd';
    }
    else {
        $suffix='rd';
    }

    $self->textout($suffix);
}

###############################################################################

=item 'show-pagedesc' => show_pagedesc (%)

Displays value of pagedesc structure (see L<XAO::Web>) with the given
"name". Default name is "fullpath". Useful for processing tree-to-object
mapped documents.

=cut

sub show_pagedesc ($) {
    my $self=shift;
    my $args=get_args(\@_);
    my $name=$args->{name} || 'fullpath';
    $self->textout($self->clipboard->get('pagedesc')->{$name} || '');
}

###############################################################################

=item 'select-time-range' => select_time_range(%)

Displays a list of <OPTION ...> tags for the given time range.

Exact output depends on "type" argument that can be:

=over

=item "days"

Lists days of month from optional "start" day (default is "1") to
optional "end" day (default is the number of days in the current month).

=item "quorters"

Two optional arguments "start" and "end" set start and end date for the
time range. The format is YYYY-Q, where YYYY is a year in four digits
format and Q is quarter number from 1 to 4.

If "end" is not set the current quorter is assumed.

=over

Special argument "current" will have select_time_range() add "SELECTED"
option to the appropriate entry in the final list. The format is the
same as for "start" and "end".

Default sorting is from most recent down, but this can be changed with
non-zero "ascend" argument.

Example:

 <SELECT NAME="qqq">
 <%Utility mode="select-time-range"
           type="quarters"
           start="2000-1"
           current="2000-3"%>
 </SELECT>

Would produce something like:

 <SELECT NAME="qqq">
 <OPTION VALUE="2001-1">2001, 1-st Qtr
 <OPTION VALUE="2000-4">2000, 4-th Qtr
 <OPTION VALUE="2000-3" SELECTED>2000, 3-rd Qtr
 <OPTION VALUE="2000-2">2000, 2-nd Qtr
 <OPTION VALUE="2000-1">2000, 1-st Qtr
 </SELECT>

=cut

sub select_time_range ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $type=$args->{type};

    ##
    # Quorters
    #
    if($type eq 'quarters') {
        ##
        # Start date
        #
        my $year;
        my $quarter;
        if($args->{start}) {
            my ($y,$q)=($args->{start} =~ /^(\d+)\D+(\d+)$/);
            if($y>1000 && $q>0 && $q<5) {
                $year=$y;
                $quarter=$q;
            }
            else {
                eprint "Bad year ($y) or quarter ($q) in '$args->{start}'";
            }
        }
        if(!$year) {
            $year=2000;	# Kind of birthday of XAO::Web :)
            $quarter=1;
        }
        my $lastyear;
        my $lastquarter;
        if($args->{end}) {
            my ($y,$q)=($args->{end} =~ /^(\d+)\D+(\d+)$/);
            if($y>1000 && $q>0 && $q<5) {
                $lastyear=$y;
                $lastquarter=$q;
            }
            else {
                eprint "Bad last year ($y) or quarter ($q) in '$args->{end}'";
            }
        }
        if(!$lastyear) {
            $lastyear=(gmtime)[5]+1900;
            $lastquarter=(gmtime)[4]/3+1;
        }
        if($year>$lastyear || ($year == $lastyear && $quarter>$lastquarter)) {
            eprint "Start date ($year-$quarter) is after end date ($lastyear-$lastquarter)";
            $lastyear=$year;
            $lastquarter=$quarter;
        }
        my $obj=$self->object;
        my @qq=('1-st Qtr', '2-nd Qtr', '3-rd Qtr', '4-th Qtr');
        if($args->{ascend}) {
            while($year<$lastyear ||
                  ($year==$lastyear && $quarter<=$lastquarter)) {
                my $value="$year-$quarter";
                $obj->display(
                    template => '<OPTION VALUE="<%VALUE%>"<%SELECTED%>><%TEXT%>',
                    VALUE => $value,
                    SELECTED => $args->{current} && $args->{current} eq $value ? " SELECTED " : "",
                    TEXT => $year . ', ' . $qq[$quarter-1],
                    YEAR => $year,
                    QUARTER => $quarter
                );
                $quarter++;
                if($quarter>4) {
                    $quarter=1;
                    $year++;
                }
            }
        }
        else {
            while($lastyear>$year ||
                  ($year==$lastyear && $lastquarter>=$quarter)) {
                my $value="$lastyear-$lastquarter";
                $obj->display(
                    template => '<OPTION VALUE="<%VALUE%>"<%SELECTED%>><%TEXT%>',
                    VALUE => $value,
                    SELECTED => $args->{current} && $args->{current} eq $value ? " SELECTED " : "",
                    TEXT => $lastyear . ', ' . $qq[$lastquarter-1],
                    YEAR => $lastyear,
                    QUARTER => $lastquarter
                );
                $lastquarter--;
                if($lastquarter<1) {
                    $lastquarter=4;
                    $lastyear--;
                }
            }
        }
    }

    ##
    # Days of month
    #
    elsif($type eq 'days') {
        use integer;

        my $start=int($args->{start} || '1');
        my $end=$args->{end};

        if(!$end) {
            my @ct=localtime;
            $ct[0]=30;
            $ct[1]=$ct[2]=0;
            $ct[3]=1;
            $ct[4]+=1;
            if($ct[4]>=12) {
                $ct[4]=0;
                $ct[5]++;
            }
            my $nm=mktime(@ct);
            $end=(localtime($nm-120*60))[3];
        }
        $end=int($end);

        my $cmp;
        my $inc;
        if($args->{ascend}) {
            if($end<$start) {
                my $t=$start;
                $start=$end;
                $end=$t;
            }
            $cmp=sub {
                return $_[0] <= $end;
            };
            $inc=1;
        }
        else {
            if($end>$start) {
                my $t=$start;
                $start=$end;
                $end=$t;
            }
            $cmp=sub {
                return $_[0] >= $end;
            };
            $inc=-1;
        }

        my $page=$self->object;
        for(my $day=$start; &{$cmp}($day); $day+=$inc) {
            $page->display(
                template    => '<OPTION VALUE="<%VALUE%>"<%SELECTED%>><%TEXT%>',
                VALUE       => $day,
                SELECTED    => $args->{current} && $args->{current} == $day ? " SELECTED " : "",
                TEXT        => $day,
            );
        }
    }

    ##
    # Unknown type
    #
    else {
        throw $self "select_time_range - unknown range type ($type)";
    }
}

###############################################################################
1;
__END__

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
