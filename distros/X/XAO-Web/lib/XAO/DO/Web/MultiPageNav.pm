=head1 NAME

XAO::DO::Web::MultiPageNav - Multi page navigation display

=head1 SYNOPSYS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

The 'MultiPageNav' object is a part of some 'Search' object that
displays a header template, a search results template for each search
result, and a footer template. The header and footer templates
includes MultiPageNav object. There are three parameters available
for substitution: START_ITEM, ITEMS_PER_PAGE and TOTAL_ITEMS. These
parameters can be used to display subsequent links with the MultiPageNav
object

The parameters for the MultiPageNav object are defined as follows:

=over

=item start_item - Count of first item of current page

Note: count of first item of first page is 1.

=item items_per_page

Maximum number of items per page

=item total_items

Total number of items

=item n_edge_pages

Maximum number of first few and last few numbered page links

=item n_adjacent_pages

Maximum number of numbered page links immediately preceding and following current page

=item n_block_pages

Maximum number of numbered page links in blocks between 'edge' and 'adjacent' links

=item max_blocks

Maximum number of page link blocks (not including 'edge' and 'adjacent' links)

=item min_period

Minimum number of pages between blocks

=item previous_page.path

Path to template for displaying link to previous page

=item noprevious_page.path

Path to template for display when there is no previous page

=item next_page.path

Path to template for displaying link to next page

=item nonext_page.path

Path to template for display when there is no next page

=item current_page.path

Path to template for displaying (non)link to current page

=item numbered_page.path

Path to template for displaying link to numbered pages

=item spacer.path

Path to template for displaying spacer between numbered page links

=item path

Path to template for displaying all multi-page nav links

=back

The 'MultiPageNav' object performs all necessary calculations and
template substitutions (using xxx.path templates). The values for these
parameters so that a list of parameters is available to the 'path'
template. The values for this parameters correspond to the navigation
display content. Following is a listing of said parameters with a
description of thier values' display contents:

=over

=item PREVIOUS

Link to previous page

=item FIRSTFEW

Links to first few pages

=item PREVIOUS_BLOCKS

Blocks of links to pages between first few and previous adjacent pages
includingspacers

=item PREVIOUS_ADJACENT

Links to pages immediately preceding current page

=item CURRENT

(Non)link to current page

=item NEXT_ADJACENT

Links to pages immediately following current page

=item NEXT_BLOCKS

Blocks of links to pages between next adjacent and last few pages
including spacers

=item LASTFEW

Links to last few pages

=item NEXT

Link to next page

=back

The CGI parameters that are necessary for creating links in the
'xxx.path' templates are available via XAO::DO::Web::Utility object.
Also, the following parameters available to these templates:

=over

=item PAGE_START_ITEM

The count of the first item to appear on the page the link points to

=item PAGE_NUMBER

The page number the link points to

=item PAGE_TYPE

Type of page the link points to. Values can be PREVIOUS, FIRSTFEW,
PREVIOUS_BLOCKS, PREVIOUS_ADJACENT, CURRENT, NEXT_ADJACENT, NEXT_BLOCKS,
LASTFEW, NEXT

=back

=head1 EXAMPLE

This example shows how a header or footer template might use this object:

 <%MultiPageNav
   start_item="<%START_ITEM%>"
   items_per_page="<%ITEMS_PER_PAGE%>"
   total_items="<%TOTAL_ITEMS%>"
   n_adjacent_pages="2"
   n_edje_pages="3"
   n_block_pages="2"
   max_blocks="4"
   min_period="7"
   path="/bits/multi_page_nav/base"
   previous_page.path="/bits/multi_page_nav/prev"
   next_page.path="/bits/multi_page_nav/next"
   current_page.path="/bits/multi_page_nav/current"
   numbered_page.path="/bits/multi_page_nav/page"
   spacer.path="/bits/multi_page_nav/spacer"
 %>

File /bits/multi_page_nav/page contents:

<A HREF="/search.html?<%Utility
                mode="pass-cgi-params"
                params="*"
                except="start_item"
                result="query"
              %>&start_item=<%PAGE_START_ITEM%>"><%PAGE_NUMBER%></A>

File /bits/multi_page_nav/prev contents:

<A HREF="/search.html<%Utility
                mode="pass-cgi-params"
                params="*"
                except="start_item"
                result="query"
              %>&start_item=<%PAGE_START_ITEM%>">&lt;&lt;prev</A>

File /bits/multi_page_nav/spacer contents: ...

File /bits/multi_page_nav/current contents:

[<%PAGE_NUMBER%>]

File /bits/multi_page_nav/base contents:

<%PREVIOUS%> <%FIRSTFEW%> <%PREVIOUS_BLOCKS%> <%PREVIOUS_ADJACENT%> <%CURRENT%> <%NEXT_ADJACENT%> <%NEXT_BLOCKS%> <%LASTFEW%> <%NEXT%>

If the value of START_ITEM, ITEMS_PER_PAGE and TOTAL_ITEMS are 250, 10
and 500 respactively text representation result of this example looks
like

<<prev 1 2 ... 11 12 ... 22 23 24 [25] 26 27 28 ... 38 39 ... 49 50 next>>

=head1 METHODS

No publicly available methods except overriden display()

=head1 EXPORTS

Nothing

=head1 AUTHOR

Copyright (c) 2003-2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2001-2003 Marcos Alves, XAO Inc.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>,
L<XAO::DO::Web::CgiParam>,
L<XAO::DO::Web::Utility>.

=cut

package XAO::DO::Web::MultiPageNav;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::MultiPageNav);
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: MultiPageNav.pm,v 2.2 2005/09/14 22:05:43 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
# Displaying multi page navigation display
#
sub display ($;%) {
    #dprint "\n\n***\n***\n"
    #     . "*** XAO::DO::Web::MultiPageNav::display() START\n"
    #     . "***\n***";
    my $self = shift;
    my $args = $self->process_args(@_);
    my $params      = $self->expand_nav($args);
    $params->{path} = $args->{path};
    $self->object->display($params);
    #dprint "***\n***\n"
    #     . "*** XAO::DO::Web::Order::check_mode() STOP\n"
    #     . "***\n***";
}
###############################################################################
sub expand_nav {

    my $self = shift;
    my $args = shift;

    $args->{total_pages}  = int($args->{total_items}/$args->{items_per_page});
    $args->{total_pages}++  if  $args->{total_items} % $args->{items_per_page};
    $args->{current_page} = int($args->{start_item}/$args->{items_per_page});
    $args->{current_page}++ unless $args->{items_per_page} == 1;
    #dprint "    %% NUMERICAL ARGS:";
    #for (sort keys %$args){ dprint "    %% # $_ = $args->{$_}" unless /path$/; }

    my (%strt, %stop, $page, $type, $pgstart);
    my $obj    = $self->object;
    my $params = {};
    for ('PREVIOUS',
         'FIRSTFEW',
         'LASTFEW',
         'PREVIOUS_BLOCKS',
         'NEXT_BLOCKS',
         'PREVIOUS_ADJACENT',
         'NEXT_ADJACENT',
         'NEXT',
        ) { $params->{$_} = '';}

    #################
    # Current Block #
    #################

    # PREVIOUS_ADJACENT
    $type = 'PREVIOUS_ADJACENT';
    #dprint "*** $type";
    if ($args->{current_page} > 1) {
        $strt{$type} = $args->{current_page} - $args->{n_adjacent_pages};
        $strt{$type} = 1 if $strt{$type} < 1;
        $stop{$type} = $args->{current_page} - 1;
        $stop{$type} = 1 if $stop{$type} < 1;
        $pgstart     = int(($strt{$type}-1) * $args->{items_per_page}) + 1;
        foreach $page ($strt{$type}..$stop{$type}) {
            #dprint "    >> $page: $type; pgstart: $pgstart";
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => '$type',
                                });
            $pgstart += $args->{items_per_page};
        }
    }
    else {
        $strt{$type} = $stop{$type} = 0;
    }

    # PREVIOUS
    $type    = 'PREVIOUS';
    #dprint "*** $type";
    $page    = $args->{current_page} - 1;
    my $path =  $page > 0 ? $args->{'previous_page.path'}
                          : $args->{'noprevious_page.path'};
    #dprint "    >> $page: $type";
    my $prev_pgstart=int(($page-1) * $args->{items_per_page}) + 1;
    $params->{$type} = $obj->expand($args,{
                           path            => $path,
                           PAGE_START_ITEM => $prev_pgstart==1 ? 0 : $prev_pgstart,
                           PAGE_NUMBER     => $page,
                           PAGE_TYPE       => $type,
                       }) if $path;
    # CURRENT
    $type = 'CURRENT';
    #dprint "*** $type";
    #dprint "    >> $page: $type";
    $page = $args->{current_page};
    $params->{$type} = $obj->expand($args,{
                           path            => $args->{'current_page.path'},
                           PAGE_START_ITEM => int(($page-1) * $args->{items_per_page}),
                           PAGE_NUMBER     => $page,
                           PAGE_TYPE       => $type,
                       });

    # NEXT
    $type = 'NEXT';
    $page = $args->{current_page} + 1;
    #dprint "*** $type";
    $path = $page <= $args->{total_pages} ? $args->{'next_page.path'}
                                          : $args->{'nonext_page.path'};
    $pgstart = int(($page-1) * $args->{items_per_page}) + 1;
    $params->{$type} = $obj->expand($args,{
                           path            => $path,
                           PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                           PAGE_NUMBER     => $page,
                           PAGE_TYPE       => $type,
                       }) if $path;

    # NEXT_ADJACENT
    $type = 'NEXT_ADJACENT';
    #dprint "*** $type";
    if ($args->{current_page} < $args->{total_pages}) {
        $strt{$type} = $args->{current_page} + 1;
        $strt{$type} = $args->{total_pages} if $strt{$type} > $args->{total_pages};
        $stop{$type} = $args->{current_page} + $args->{n_adjacent_pages};
        $stop{$type} = $args->{total_pages} if $stop{$type} > $args->{total_pages};
        $pgstart     = int(($strt{$type}-1) * $args->{items_per_page}) + 1;
        foreach $page ($strt{$type}..$stop{$type}) {
            #dprint "     >> $page: $type";
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => '$type',
                                });
            $pgstart += $args->{items_per_page};
        }
    }
    else {
        $strt{$type} = $stop{$type} = 0;
    }

    #########################
    # First and Last Blocks #
    #########################

    # FIRSTFEW
    $type = 'FIRSTFEW';
    #dprint "*** $type";
    if ($strt{PREVIOUS_ADJACENT} > 1) {
        $strt{$type} = 1;
        $stop{$type} = $args->{n_edge_pages};
        $stop{$type} = $strt{PREVIOUS_ADJACENT} - 1 if $stop{FIRSTFEW} >= $strt{PREVIOUS_ADJACENT};
        $pgstart     = 1; # because int(($strt{$type}-1) * $args->{items_per_page}) + 1 == 1
        foreach $page ($strt{$type}..$stop{$type}) {
            #dprint "     >> $page: $type";
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => '$type',
                                });
            $pgstart += $args->{items_per_page};
        }
    }
    else {
        $strt{$type} = $stop{$type} = 0;
    }

    # LASTFEW
    $type = 'LASTFEW';
    #dprint "*** $type";
    if ($args->{current_page} < $args->{total_pages}) {
        $strt{$type} = $args->{total_pages} + 1 - $args->{n_edge_pages};
        $strt{$type} = $stop{NEXT_ADJACENT} + 1 if $stop{NEXT_ADJACENT} >= $strt{$type};
        $stop{$type} = $args->{total_pages};
        $pgstart     = int(($strt{$type}-1) * $args->{items_per_page}) + 1;
        foreach $page ($strt{$type}..$stop{$type}) {
            #dprint "     >> $page: $type";
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => $type,
                                });
            $pgstart += $args->{items_per_page};
        }
    }
    else {
        $strt{$type} = $stop{$type} = 0;
    }


    #################
    # Middle Blocks #
    #################

    # PREVIOUS_BLOCKS
    $type         = 'PREVIOUS_BLOCKS';
    $strt{$type}  = $stop{FIRSTFEW} + 1;
    $stop{$type}  = $strt{PREVIOUS_ADJACENT} - 1;
    my $last_page = $stop{FIRSTFEW};
    #dprint "*** $type";
    #dprint "*** $strt{PREVIOUS_ADJACENT} - $stop{FIRSTFEW} >= ".2*$args->{min_period};
    if (($strt{PREVIOUS_ADJACENT} - $stop{FIRSTFEW}) >= int(2*$args->{min_period})) {
        foreach $page ($self->midblock_pages(
                           $strt{$type},
                           $stop{$type},
                           $args->{min_period},
                           $args->{max_blocks},
                           $args->{n_block_pages},
                      )) {
            #dprint "     >> $page: $type";
            $params->{$type} .= $obj->expand($args,{
                path => $args->{'spacer.path'},
            }) if $page - $last_page > 1;
            $pgstart          = int(($page-1) * $args->{items_per_page}) + 1;
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => $type,
                                });
            $last_page = $page;
        }
    }
    $params->{$type} .= $obj->expand($args,{
        path => $args->{'spacer.path'},
    }) if $strt{PREVIOUS_ADJACENT} - $last_page > 1 &&
          $strt{PREVIOUS_ADJACENT} > 2;

    # NEXT_BLOCKS
    $type        = 'NEXT_BLOCKS';
    $strt{$type} = $stop{NEXT_ADJACENT} + 1;
    $stop{$type} = $strt{LASTFEW} - 1;
    $last_page   = $stop{NEXT_ADJACENT};
    #dprint "*** $type";
    if ($strt{LASTFEW} - $stop{NEXT_ADJACENT} >= 2*$args->{min_period}) {
        foreach $page ($self->midblock_pages(
                        $strt{$type},
                        $stop{$type},
                        $args->{min_period},
                        $args->{max_blocks},
                        $args->{n_block_pages},
                 )) {
            #dprint "     >> $page: $type";
            $params->{$type} .= $obj->expand($args,{
                path => $args->{'spacer.path'},
            }) if $page - $last_page > 1;
            $pgstart          = int(($page-1) * $args->{items_per_page}) + 1;
            $params->{$type} .= $obj->expand($args,{
                                    path            => $args->{'numbered_page.path'},
                                    PAGE_START_ITEM => $pgstart==1 ? 0 : $pgstart,
                                    PAGE_NUMBER     => $page,
                                    PAGE_TYPE       => $type,
                                });
            $last_page = $page;
        }
    }
    $params->{$type} .= $obj->expand($args,{
        path => $args->{'spacer.path'},
    }) if $strt{LASTFEW} - $last_page > 1;
    #for (
    #     'FIRSTFEW',
    #     'PREVIOUS_BLOCKS',
    #     'PREVIOUS_ADJACENT',
    #     'NEXT_ADJACENT',
    #     'NEXT_BLOCKS',
    #     'LASTFEW',
    #    ) { dprint "    %% $_: $strt{$_}, $stop{$_}";}

    return $params;
}
###############################################################################
sub process_args {

    my $self = shift;
    my $args = get_args(\@_);
    #dprint "    %% PASSED ARGS:";
    #for (sort keys %$args){ dprint "    %% * $_ = $args->{$_}"; }

    ##
    # Check template arguments
    #
    $args->{path}                 || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'path' template argument given";
    $args->{'previous_page.path'} || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'previous_page' template argument given";
    $args->{'current_page.path'}  || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no  'current_page' template argument given";
    $args->{'next_page.path'}     || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'next_page' template argument given";
    $args->{'numbered_page.path'} || throw XAO::E::DO::Web::MultiPageNav
                                     "display - no 'numbered_page' template argument given";
    $args->{'spacer.path'}        || throw XAO::E::DO::Web::MultiPageNav
    $args->{'nonext_page.path'}     = '' unless exists($args->{'nonext_page.path'});
    $args->{'noprevious_page.path'} = '' unless exists($args->{'noprevious_page.path'});

    ##
    # Check numerical arguments
    #
    $args->{start_item}     = exists($args->{start_item})
                            ? int($args->{start_item})
                            : throw XAO::E::DO::Web::MultiPageNav
                              "display - no 'start_item' argument given";
    $args->{items_per_page} = exists($args->{items_per_page}) && int($args->{items_per_page}) > 0
                            ? int($args->{items_per_page})
                            : throw XAO::E::DO::Web::MultiPageNav
                              "display - no 'items_per_page' argument given";
    $args->{total_items}    = exists($args->{total_items})
                            ? int($args->{total_items})
                            : throw XAO::E::DO::Web::MultiPageNav
                              "display - no 'total_items' argument given";

    ##
    # Set defaults if necessary
    #
    $args->{n_edge_pages}     = exists($args->{n_edge_pages})     ? int($args->{n_edge_pages})
                                                                  : 2;
    $args->{n_adjacent_pages} = exists($args->{n_adjacent_pages}) ? int($args->{n_adjacent_pages})
                                                                  : 3;
    $args->{n_block_pages}    = exists($args->{n_block_pages})    ? int($args->{n_block_pages})
                                                                  : 1;
    $args->{max_blocks}       = exists($args->{max_blocks})       ? int($args->{max_blocks})
                                                                  : 3;
    $args->{min_period}       = exists($args->{min_period})       ? int($args->{min_period})
                                                                  : 3;

    ##
    # Validate arguments
    #
    $args->{start_item} = 1                    if $args->{start_item} < 1;
    $args->{start_item} = $args->{total_items} if $args->{start_item} > $args->{total_items};

    return $args;
}
###############################################################################
sub midblock_pages() {

    my $self = shift;
    my ($pg_strt, $pg_stop, $min_period, $max_blocks, $n_blk_pages) = @_;

    my $tot_pages      = $pg_stop - $pg_strt;

    return if $tot_pages <= 1 || !$max_blocks;

    my $n_blks         = int($tot_pages/$min_period) || return;
    $n_blks            = $n_blks > $max_blocks ? $max_blocks : $n_blks;
    my $period         = int($tot_pages/$n_blks) || 1;
    #my $half_blk_pages = int($n_blk_pages/2);
    #my $min = $pg_strt + int($tot_pages/($n_blks+1));
    #$min   -= $half_blk_pages;
    #$min-- if $n_blk_pages%2;
    my $min            = $pg_strt + int($tot_pages/($n_blks+1));
    $min              -= int(($min-$pg_strt)/2);
    my $half_blk_pages = int($n_blk_pages/2);
#dprint "\n\n";
#dprint "    ** tot_pages   = $tot_pages";
#dprint "    ** n_blk_pages = $n_blk_pages";
#dprint "    ** n_blks      = $n_blks";
#dprint "    ** period      = $period";
#dprint "    ** pg_strt     = $pg_strt";
#dprint "    ** pg_stop     = $pg_stop";
#dprint "    ** min         = $min";
    my @pages = ();
    foreach my $blk (0..$n_blks-1) {
#dprint "    ** blk $blk ($min < $pg_stop ?)";
        last if $min >= $pg_stop;
        my $max = $min + $n_blk_pages;
        $max    = $pg_stop if $max > $pg_stop;
        $max--;
#dprint "       ^ $min..$max";
        foreach ($min..$max) { push @pages, $_; }
        $min += $period + $half_blk_pages;
    }
    @pages;
}
###############################################################################
1;
