=head1 NAME

XAO::DO::Web::TextTable - plain text tables

=head1 SYNOPSIS

 <%TextTable mode="start"
             format=" l | r | l "
 %>

 <%TextTable mode="head"
             cell.1.template="Name"
             cell.2.template="Price"
             cell.3.template="Description"
 %>

 <%TextTable mode="ruler" symbol="-"%>

 <%TextTable cell.1.template="Fubar"
             cell.2.template={<%Styler/f dollars="123.34"%>}
             cell.3.path="/bits/show-description
             cell.3.ID="123456"
 %>

 <%TextTable mode="render" width="70"%>

=cut

###############################################################################
package XAO::DO::Web::TextTable;
use strict;
use XAO::Utils;
use XAO::Objects;
use Text::FormatTable;

use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: TextTable.pm,v 2.1 2005/01/14 01:39:57 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=head1 DESCRIPTION

Web::TextTable object allows to create simple pre-formatted text only
tables out of various dynamic content. It currently uses David
Schweikert's Text::FormatTable module internally.

Due to rendering requirements generating a table is a multi-step process:

=over

=item 1

First you declare a new text table and specify its format. Arguments
accepted on that step are:

 mode   => 'start'
 format => format string as descriped in L<Text::FormatTable>

=item 2

You fill the table by using mode equal to 'row' (default mode), 'head'
or 'ruler'.

Modes for 'row' and 'head' take the same arguments and currently display
exactly the same results:

 mode            => 'head' or 'row'
 cell.X.template => inline template for cell X of the row (see below)
 cell.X.path     => path to a template
 cell.X.pass     => pass all current arguments to the template
 cell.X.VAR      => make 'VAR' available to the template with the given
                    content

Here 'X' may be anything as long as alphanumerically ordered cell.*.*
lines give exactly the required number of columns. It is recommended to
use single digits in incrementing order to designate rows:

 <%TextTable mode="head"
             cell.1.template="Fubar"
             cell.2.path="/bits/show-price"
             cell.2.PRICE="123.23"
             cell.3.path="/bits/show-description
             cell.3.ID="123456"
 %>

For 'ruler' mode the only optional argument is 'symbol' - what symbol to
use to draw the ruler. The default is '-'.

=item 3

Final step is to use 'render' mode to actually draw the table. One
optional argument is 'width' -- the final width of the table. Default
width is 75 characters.

 <%TextTable mode="render"%>

=back

Tables can be nested as long as there is a 'render' for each 'start'.

Internally Web::TextTable uses clipboard variable located at
'/var/TextTable'.

B<Note:> You need to be careful with extra spaces and newlines. One
way of dealing with it is to enclose table preparation into an unused
variable brackets to just throw away extra space:

<%SetArg name="UNUSED" value={
 <%TextTable ....%>
 <%TextTable ....%>
 <%TextTable ....%>
}%><%TextTable mode="render"%>


=cut

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'row';

    if($mode eq 'start') {
        $self->table_start($args);
    }
    elsif($mode eq 'head') {
        $self->table_head($args);
    }
    elsif($mode eq 'ruler' || $mode eq 'rule') {
        $self->table_ruler($args);
    }
    elsif($mode eq 'row') {
        $self->table_row($args);
    }
    elsif($mode eq 'render') {
        $self->table_render($args);
    }
    else {
        $self->check_mode($args);
    }
}

sub table_start ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $format=$args->{format} ||
        throw $self "table_start - no 'format' argument";

    my $table=Text::FormatTable->new($format);

    my $tstack=$self->get_tstack;
    unshift(@$tstack,$table);
}

sub table_head ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $tstack=$self->get_tstack;
    
    $tstack->[0] ||
        throw $self "table_head - no current table (start/render mismatch)";

    $tstack->[0]->head($self->generate_row($args));
}

sub table_row ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $tstack=$self->get_tstack;
    
    $tstack->[0] ||
        throw $self "table_row - no current table (start/render mismatch)";

    $tstack->[0]->row($self->generate_row($args));
}

sub table_ruler ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $tstack=$self->get_tstack;
    
    $tstack->[0] ||
        throw $self "table_ruler - no current table (start/render mismatch)";

    $tstack->[0]->rule(defined($args->{symbol}) ? $args->{symbol} : '-');
}

sub table_render ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $tstack=$self->get_tstack;
    
    $tstack->[0] ||
        throw $self "table_render - no current table (start/render mismatch)";

    $self->textout(shift(@$tstack)->render($args->{width} || 75));
}

sub get_tstack ($) {
    my $self=shift;
    my $tstack=$self->clipboard->get('/var/TextTable');

    if(!$tstack) {
        $tstack=[];
        $self->clipboard->put('/var/TextTable' => $tstack);
    }

    return $tstack;
}

sub generate_row ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my %params;
    foreach my $name (keys %$args) {
        next unless $name =~ /^cell\.(\w+)\.(.*)$/;
        $params{$1}->{$2}=$args->{$name};
    }

    my @row;
    foreach my $name (sort keys %params) {
        my $p=$params{$name};

        my $objname=$p->{'objname'} || 'Page';

        $p=$self->pass_args($p->{'pass'},$p) if $p->{'pass'};

        my $obj=$self->object(objname => $objname);

        push(@row,$obj->expand($p));
    }

    return @row;
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<Text::FormatTable>.
