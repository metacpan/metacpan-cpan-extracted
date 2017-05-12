=head1 NAME

XAO::DO::Web::Search - XAO::Web Database Search

=head1 SYNOPSIS

Useful in XAO::Web site context.

=head1 DESCRIPTION

OBSOLETE, TO BE REMOVED. Use <%FS mode='search' ...%> instead.

Accepts the following arguments:

=over

=item db_list or db_class => '/Customers'

Database (object) name (path).  If 'db_list' is used, a normal search
is performed.  If 'db_class' is used,  a collection search is
performed

=item index_1..N => 'first_name|last_name'

Name of database field(s) to perform search on.
Multiple field names are separated by | (pipe character)
and treated as a logical 'or'.

=item value_1..N => 'Ann|Lonnie'

Keywords you want to search for in field(s) of corresponding index.
Multiple sets of keywords are separated by | (pipe character)
and treated as a logical 'or'.

=item compare_1..N => 'ws'

Comparison operator to be used in matching index to value.
Supported comparison operators are:
    eq  True if equal.
    
    ge  True if greater or equal.
    
    gt  True if greater.
    
    le  True if less or equal.
    
    lt  True if less.

    ne  True if not equal.
    
    gtlt True if greater than             'a' and less than 'b'

    gtle True if greater than             'a' and less than or equal to 'b'

    gelt True if greater than or equal to 'a' and less than             'b'

    gele True if greater than or equal to 'a' and less than or equal to 'b'
    
    wq  (word equal)True if contains given word completely.
    
    ws  (word start) True if contains word that starts with the given string.

    cs  (contains string) True if contains string.

=item expression => [ [ 1 and 2 ] and [ 3 or 4] ]

Logical expression, as shown above, that indicates how to
combine index/value pairs.  Numbers are used to indicate
expressions specified by corresponding index/value pairs
and brackets are used so that only one logical operator
(and, or) is contained within a pair of brackets.

=item orderby => '+last_name|-first_name'

Optional field to use for sorting output. If field name is preceded
by - (minus sign), sorting will be done in descending order for that
field, otherwise it will be done in ascending order. For consistency
and clarity, a + (plus sign) may precede a field name to expicitly
indicate sorting in ascending order.  Multiple fields to sort by are
separated by | (pipe character) and are listed in order of priority.

=item distinct => 'first_name'

This eliminates duplicate matches on a given field, just like
SQL distinct.

=item start_item => 40

Number indicating the first query match to fetch.

=item items_per_page => 20

Number indicating the maximum number of query matches to fetch.

=back

Example:

 <%Search db_list="/Customers"

          index_1="first_name|last_name"
          value_1="Linda|Mary Ann|Steven"
          compare_1="wq"

          index_2="gender"
          value_2="female"
          compare_2="wq"

          index_3="age"
          value_3="21|30"
          compare_3="gelt"

          expression="[ [ 1 and 2 ] and 3 ]"
          orderby="age|first_name+desc"
          start_item="40"
          items_per_page="20"
 %>

=head1 SUPPORTED CONFIGURATION VALUES

=item default_search_args

The value of this configuration value is a reference to a hash.
In this hash each key is a database (object) path (name) whose
corresponding value is a reference to a hash containing the
default arguments for searching on the specified of data.
These default arguments are added unless they are specified by
input arguments.

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2003-2005 Andrew Maltsev

Copyright (c) 2001-2003 Marcos Alves, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>.

=cut

###############################################################################
package XAO::DO::Web::Search;
use strict;
use Carp;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Search.pm,v 2.2 2007/09/13 00:17:51 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
sub display ($;%)
{
  my $self=shift;

  my $rh_args = get_args(\@_);
  my $rh_conf = $self->siteconfig;

  #############
  #
  # PROCESS INPUT ARGUMENTS
  #
  #############

  my $db_uri = $rh_args->{db_list} || $rh_args->{db_class}; # 'normal' or 'collection' search

  #
  # Add default arguments unless they are specified by input aarguments.
  #
  my $rh_defaults     = $rh_conf->{default_search_args};
  my $rh_default_args = $rh_defaults->{$db_uri};
  if (ref($rh_default_args) eq 'HASH')
  {
    foreach (keys %$rh_default_args)
    {
      next if defined $rh_args->{$_};
      $rh_args->{$_}  = $rh_default_args->{$_};
      #dprint "*** Add Default Argument: $_ = $rh_default_args->{$_}";
    }
  }

  if ($rh_args->{debug})
  {
    #dprint '*** Processed Parameters:';
    #foreach (sort keys %$rh_args) { dprint " arg> $_: $rh_args->{$_}"; }
    #dprint '';
  }

  #############
  #
  # DO SEARCH
  #
  #############

  my $odb = $rh_conf->odb();
  my $db  = $odb->fetch($db_uri) || croak "Can't fetch database $db_uri";

  #dprint "*** ODB: $odb";
  #dprint "*** DB:  $db";
  #dprint "*** Go Search...\n\n";

  my $ra_query       = $self->_create_query($rh_args, $rh_conf);
  my $ra_all_ids     = $db->search(@$ra_query);
  my $ra_ids         = $ra_all_ids;
  my $total          = $#{$ra_all_ids}+1;
  my $items_per_page = $rh_args->{items_per_page} || 0;
  my $limit_reached  = $items_per_page && $total>$items_per_page;
  if ($rh_args->{start_item} || $items_per_page)
  {
    my $start_item = int($rh_args->{start_item}) > 1 ? $rh_args->{start_item}-1 : 0;
    my $stop_item  = $total-1;
    if (int($rh_args->{items_per_page}))
    {
      my $max    = $rh_args->{items_per_page} + $start_item;
      $stop_item = $max if $stop_item > $max;
    }
    $ra_ids = [ @{$ra_all_ids}[$start_item..$stop_item] ];
  }

  #############
  #
  # DISPLAY ITEMS
  #
  #############

  my $page = $self->object(objname => 'Page');
  my $basetype;

  #
  # Display header
  #
  $page->display(path           => $rh_args->{'header.path'},
                 template       => $rh_args->{'header.template'},
                 START_ITEM     => $rh_args->{start_item} || 0,
                 ITEMS_PER_PAGE => $rh_args->{items_per_page} || 0,
                 TOTAL_ITEMS    => $total,
                 LIMIT_REACHED  => $limit_reached,
                ) if $rh_args->{'header.path'} || $rh_args->{'header.template'};

  #
  # Display items
  #

  $basetype = $rh_args->{template} ? 'template' : 'path';
  my $count = 1;
  #dprint "\n*** Search Results (" . scalar(@$ra_ids) . " matches)";
  foreach (@$ra_ids)
  {
    #dprint " $count> display $_";
    #dprint " $count> use $basetype: $rh_args->{$basetype}" if $basetype eq 'path';
    $page->display(
                    $basetype => $rh_args->{$basetype},
                    ID        => $_,
                    COUNT     => $count,
                  );
    $count++;
  }

  #
  # Display footer
  #
  $page->display(path           => $rh_args->{'footer.path'},
                 template       => $rh_args->{'footer.template'},
                 START_ITEM     => $rh_args->{start_item} || 0,
                 ITEMS_PER_PAGE => $rh_args->{items_per_page} || 0,
                 TOTAL_ITEMS    => $total,
                 LIMIT_REACHED  => $limit_reached,
                ) if $rh_args->{'footer.path'} || $rh_args->{'footer.template'};
}
###############################################################################
sub _create_query
{
  my $self=shift;
  my ($rh_args, $rh_conf) = @_;

  #dprint "*** _create_query START";

  my $i=1;
  my @expr_ra;
  while ($rh_args->{"index_$i"})
  {
    my $index      = $rh_args->{"index_$i"};
    my $value      = $rh_args->{"value_$i"};
    my $compare_op = $rh_args->{"compare_$i"};

    #dprint "\n  ** $i **";
    #dprint "  ## index:            $index";
    #dprint "  ## value:            $value";
    #dprint "  ## compare operator: $compare_op";

    #
    # Create ref to array w/ object expression for index/value pair
    #
    my @indexes = split(/\|/, $index);
    if ($compare_op eq 'wq' || $compare_op eq 'ws')
    {
      if ($value =~ /\|/)
      {
        my @value_list = split(/\|/, $value);
        $value         = \@value_list;
      }
      $expr_ra[$i]   = $self->_create_expression(\@indexes, $compare_op, $value);
    }
    elsif ($compare_op =~ /^(g[et])(l[et])$/)
    {
      my ($lo, $hi) = split(/\|/, $value);
      foreach (@indexes)
      {
        my $ra_temp  = [ [$_, $1, $lo] and [$_, $2, $hi] ];
        $expr_ra[$i] = ref($expr_ra[$i]) eq 'ARRAY'
                     ? [$expr_ra[$i], 'or', $ra_temp] : $ra_temp;
      }
    }
    else
    {
      $expr_ra[$i] = $self->_create_expression(\@indexes, $compare_op, $value);
    }

    $i++;
  }

  #
  # At this point we have a bunch of expressions (1..N) in @expr_ra
  # that need to be put together as specified in the 'expression'
  # argument.  If the 'expression' argument does not match the
  # the format (described in documentation above) then the only
  # expression used will be the first one provided.
  #
  #dprint "\n  ## EXPRESSION: $rh_args->{expression}";
  my $regex = '\[\s*(\d+)\s+(\w+)\s+(\d+)\s*\]';
  if ($rh_args->{expression} =~ /$regex/)
  {
    $rh_args->{expression} =~ s{$regex}
                               {
                                 $self->_interpret_expression(\@expr_ra,
                                                              $rh_args->{expression},
                                                              \$i, $1, $2, $3,
                                                              $regex);
                               }eg;
    $i--;
    ###########################################################################
    sub _interpret_expression
    {
      my $self = shift;
      my ($ra_expr_ra, $expression, $r_i, $i1, $i2, $i3, $regex) = @_;
    
      $ra_expr_ra->[$$r_i] = [ $ra_expr_ra->[$i1], $i2, $ra_expr_ra->[$i3] ];
      #dprint "  ## $$r_i = [ $i1 $i2 $i3 ]";
      $expression =~ s/\[\s*$i1\s+$i2\s+$i3\s*\]/$$r_i/;
      #dprint "  ## new expr = $expression";
      ${$r_i}++;
      $self->_interpret_expression($ra_expr_ra,
                                   $expression,
                                   $r_i, $1, $2, $3,
                                   $regex) if $expression =~ /$regex/;
    }
    ###########################################################################
  }
  else
  {
    $expr_ra[$i] = $expr_ra[1];
  }

  #
  # Add any extra search options
  #
  if ($rh_args->{orderby} || $rh_args->{distict})
  {
    my $rh_options = {};

    #
    # Sort specifications
    #
    if ($rh_args->{orderby})
    {
      my $ra_orderby = [];
      foreach (split(/\|/, $rh_args->{orderby}))
      {
        my $direction = /^-/ ? 'descend' : 'ascend';
        s/\W//g;
        push @$ra_orderby, ($direction => $_);
      }
      $rh_options->{orderby} = $ra_orderby;
    }

    #
    # Distinct searching
    #
    $rh_options->{distinct} = $rh_args->{distict} if $rh_args->{distict};

    push @{$expr_ra[$i]}, $rh_options;
  }

  #dprint "\n  ## QUERY START ##"
  #     . $self->_searcharray2str($expr_ra[$i], '')
  #     . "\n  ## QUERY STOP  ##\n"
  #     . "\n*** _create_query STOP\n\n";

  $expr_ra[$i];
}
###############################################################################
sub _create_expression
{
  my $self=shift;
  my ($ra_indexes, $compare_op, $value) = @_;
  my $ra_expr;
  foreach my $index (@$ra_indexes)
  {
    my $ra_temp = [$index, $compare_op, $value];
    $ra_expr    = ref($ra_expr) eq 'ARRAY' ? [$ra_expr, 'or', $ra_temp] : $ra_temp;
  }
  $ra_expr;
}
###############################################################################
sub _searcharray2str()
{
  my $self=shift;
  my ($ra, $indent) = @_;

  my $indent_new = $indent . ' ';
  my $i=0;
  my $innermost=1;
  my $str= "\n" . $indent . "[";
  foreach (@$ra)
  {
    $str .= ' ';
    if    (ref($_) eq 'ARRAY')
    {
      $str .=  $self->_searcharray2str($_, $indent_new);
    }
    elsif (ref($_) eq 'HASH')
    {
      $str .= '{ ';
      foreach my $key (keys %$_) { $str .= qq!'$key' => '$_->{$key}', !; }
      $str .= ' },';
    }
    else
    {
      if (($i==1) && (/and/ or /or/))
      {
        $str      .= "\n$indent " if ($i==1) && (/and/ or /or/);
        $innermost = 0;
      }
      $str .= "'$_',";
    }
    $i++;
  }
  $str .= ' ';
  $str .= "\n$indent" unless $innermost;
  $str .= ']';
  $str .= ',' if $indent;
  $str;
}
###############################################################################
1;
