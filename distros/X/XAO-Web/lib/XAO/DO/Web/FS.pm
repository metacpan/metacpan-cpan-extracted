=head1 NAME

XAO::DO::Web::FS - XAO::Web front end object for XAO::FS

=head1 SYNOPSIS

 <%FS uri="/Categories/123/description"%>

 <%FS mode="show-list"
      base.clipboard="cached-list"
      base.database="/Foo/test/Bars"
      fields="*"
      header.path="/bits/foo-list-header"
      path="/bits/foo-list-row"
      default.path="/bits/foo-list-default"
 %>

 <%FS mode="search"
      uri="/Orders"
      index_1="status"
      value_1="submitted"
      compare_1="wq"
      expression="1"
      orderby="place_time"
      fields="*"
      header.path="/bits/admin/order/list-header"
      path="/bits/admin/order/list-row"
      footer.path="/bits/admin/order/list-footer"
      default.path="/bits/foo-list-default"
 %>

=head1 DESCRIPTION

Web::FS allows web site developer to directly access XAO Foundation
Server from templates without implementing specific objects.

=head1 SEARCH MODE

Accepts the following arguments:

=over

=item uri => '/Customers'

Database object path.

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
    
    wq  (word equal) True if contains given word completely.
    
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

=item limit => 10

Allows to limit the number of matches to a specified number.

=item start_item => 40

Number indicating the first query match to fetch.

=item items_per_page => 20

Number indicating the maximum number of query matches to fetch.

=back

Example:

 <%FS mode="search
      uri="/Customers"
      fields="*"

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

      header.path="/bits/admin/order/list-header"
      path="/bits/admin/order/list-row"
      footer.path="/bits/admin/order/list-footer"
      default.template="No matches found."
 %>

=head2 CONFIGURATION VALUES SUPPORTED IN SEARCH MODE

=over

=item default_search_args

The value of this configuration value is a reference to a hash.
In this hash each key is a database (object) path (name) whose
corresponding value is a reference to a hash containing the
default arguments for searching on the specified of data.
These default arguments are added unless they are specified by
input arguments.

=back

=head1 METHODS

FS provides a useful base for other displayable object that work with
XAO::FS data.

=over

=cut

###############################################################################
package XAO::DO::Web::FS;
use strict;
use Digest::MD5 qw(md5_base64);
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::FS);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: FS.pm,v 2.4 2008/03/15 02:59:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item get_object (%)

Returns an object retrieved from either clipboard or the database.
Accepts the following arguments:

 base.clipboard     clipboard uri
 base.database      XAO::FS object uri
 uri                XAO::FS object URI relative to `base' object
                    or root if no base.* is given

If both base.clipboard and base.database are set then first attempt is
made to get object from the clipboard and then from the database. If the
object is retrieved from the database then it is stored in clipboard.
Next call with the same arguments will get the object from clipboard.

=cut

sub get_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $object;

    my $cb_base=$args->{'base.clipboard'};
    my $db_base=$args->{'base.database'};

    $object=$self->clipboard->get($cb_base) if $cb_base;
    !$object || ref($object) ||
        throw $self "get_object - garbage in clipboard at '$cb_base'";
    my $got_from_cb=$object;
    $object=$self->odb->fetch($db_base) if $db_base && !$object;

    if($cb_base) {
        $db_base || $object ||
            throw $self "get_object - no object in clipboard and" .
                        " no base.database to retrieve it";

        ##
        # Caching object in clipboard if we have both base.clipboard and
        # base.database.
        #
        if($object && !$got_from_cb) {
            $self->clipboard->put($cb_base => $object);
        }
    }

    my $uri=$args->{uri};
    if($object && $uri && $uri !~ /^\//) {
        
        ##
        # XXX - This should be done in FS
        #
        foreach my $name (split(/\/+/,$uri)) { $object=$object->get($name); }
    }
    elsif(defined($uri) && length($uri)) {
        $object=$self->odb->fetch($uri);
    }

    $cb_base || $db_base || $uri ||
        throw $self "get_object - at least one location parameter must present";

    $object;
}

###############################################################################

=back

Here is the list of accepted 'mode' arguments and corresponding method
names. The default mode is 'show-property'.

=over

=cut

###############################################################################

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'show-property';

    if   ($mode eq 'search')          { $self->search($args); }
    elsif($mode eq 'delete-property') { $self->delete_property($args); }
    elsif($mode eq 'show-hash')       { $self->show_hash($args); }
    elsif($mode eq 'show-list')       { $self->show_list($args); }
    elsif($mode eq 'show-property')   { $self->show_property($args); }
    elsif($mode eq 'delete-object')   { $self->delete_object($args); }
    elsif($mode eq 'edit-object')     { $self->edit_object($args); }
    else {
        throw $self "check_mode - unknown mode '$mode'";
    }
}

###############################################################################

=item delete-property => delete_property (%)

Deletes an object or property pointed to by `name' argument.

Example of deleting an entry from Addresses list by ID:

 <%FS
   mode="delete-property"
   base.clipboard="/IdentifyUser/customer/object"
   uri="Addresses"
   name="<%ID/f%>"
 %>

=cut

sub delete_property ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $object=$self->get_object($args);

    my $name=$args->{name} ||
        throw $self "delete_property - no 'name'";

    if($object->objtype eq 'List') {
        $object->check_name($name) ||
            throw $self "delete_property - bad name '$name'";
    }
    else {
        $self->odb->check_name($name) ||
            throw $self "delete_property - bad name '$name'";
    }

    $object->delete($name);
}

###############################################################################

=item show-hash => show_hash (%)

Displays a XAO::FS hash derived object. Object location is the same as
described in get_object() method. Additional arguments are:

 fields     comma or space separated list of fields that are
            to be retrieved from each object in the list and
            passed to the template. Field names are converted
            to all uppercase when passed to template. For
            convenience '*' means to pass all
            property names (lists be passed as empty strings).

 path       path to the template that gets displayed with the
            given fields passed in all uppercase.

 extra_sub  reference to a subroutine that creates additional
            parameters for the template and returns them in
            a hash reference. For use in derived class
            methods.

Example:

 <%FS mode="show-hash" uri="/Customers/c123" fields="firstname,lastname"
      path="/bits/customer-name"%>

Where /bits/customer-name should be something like:

 Customer Name: <%FIRSTNAME/h%> <%LASTNAME/h%>

=cut

sub show_hash ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $hash=$self->get_object($args);

    my @fields;
    if($args->{fields}) {
        if($args->{fields} eq '*') {
            @fields=$hash->keys;
        }
        else {
            @fields=split(/\W+/,$args->{fields});
            shift @fields unless length($fields[0]);
        }
    }

    my %data=(
        ID          => $hash->container_key,
    );
    if(@fields) {
        my %t;
        @t{@fields}=$hash->get(@fields);
        foreach my $fn (@fields) {
            $data{uc($fn)}=defined($t{$fn}) ? $t{$fn} : '';
        }
    }

    if($args->{extra_sub}) {
        my $extra=&{$args->{extra_sub}}(object => $hash, data => \%data, args => $args);
        $self->object->display(merge_refs($args,$extra,\%data));
    }
    else {
        $self->object->display(merge_refs($args,\%data));
    }
}

###############################################################################

=item 'show-list' => show_list (%)

Displays an index for XAO::FS list. List location is the same as
described in get_object() method. Additional arguments are:

 fields             comma or space separated list of fields that are
                    to be retrieved from each object in the list and
                    passed to the template. Field names are converted
                    to all uppercase when passed to template. For
                    convenience '*' means to pass all
                    property names (lists be passed as empty strings).
 header.path        header template path
 path               path that is displayed for each element of the list
 footer.path        footer template path
 default.path       default template path, shown instead of  header,
                    path and footer in the case where there are no
                    items in list

Show_list() supplies 'NUMBER' argument to header and footer containing
the number of elements in the list.

At least 'ID' and 'NUMBER' are supplied to the element template.
Additional arguments depend on 'field' content.

=cut

sub show_list ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $list=$self->get_object($args);
    $list->objname eq 'FS::List' || throw $self "show_list - not a list";

    my @keys=$list->keys;
    my $number=scalar(@keys);
    my @fields;
    if($args->{fields}) {
        if($args->{fields} eq '*') {
            my $n=$list->get_new;
            @fields=map { $n->describe($_)->{type} eq 'list' ? () : $_ } $n->keys;
        }
        else {
            @fields=split(/\W+/,$args->{fields});
            shift @fields unless length($fields[0]);
        }
    }

    my $page=$self->object;

    if (!$number && ($args->{'default.path'} || defined($args->{'default.template'}))) {
        $page->display(merge_refs($args,{
            path        => $args->{'default.path'},
            template    => $args->{'default.template'},
            NUMBER      => $number,
        }));
    }
    else {
        $page->display(merge_refs($args,{
            path        => $args->{'header.path'},
            template    => $args->{'header.template'},
            NUMBER      => $number,
        })) if $args->{'header.path'} || $args->{'header.template'};

        foreach my $id (@keys) {
            my %data=(
                path        => $args->{path},
                ID          => $id,
                NUMBER      => $number,
            );

            if(defined($args->{current})) {
                $data{IS_CURRENT}=($args->{current} eq $id) ? 1 : 0;
            }

            if(@fields) {
                my %t;
                @t{@fields}=$list->get($id)->get(@fields);
                foreach my $fn (@fields) {
                    $data{uc($fn)}=defined($t{$fn}) ? $t{$fn} : '';
                }
            }
            $page->display(merge_refs($args,\%data));
        }

        $page->display(
            merge_refs(
                $args,
                {
                    path     => $args->{'footer.path'},
                    template => $args->{'footer.template'},
                    NUMBER   => $number,
                }
            )
        ) if $args->{'footer.path'} || $args->{'footer.template'};
    }
}

###############################################################################

=item show-property => show_property (%)

Displays a property of the given object. Does not use any templates,
just displays the property using textout(). Example:

 <%FS uri="/project"%>

=cut

sub show_property ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $value=$self->get_object($args);
    $value=$args->{default} unless defined $value;
    $value='' unless defined $value;

    $self->textout($value);
}

###############################################################################

sub search ($;%) {

    my $self=shift;

    my $args = get_args(\@_);
    my $rh_conf = $self->siteconfig;

    #############
    #
    # PROCESS INPUT ARGUMENTS
    #
    #############

    #
    # Add default arguments as specified in configuration
    # unless there are input arguments to override them.
    #
    my $uri             = $args->{uri} || 'no_uri';
    my $rh_defaults     = $rh_conf->{default_search_args};
    my $rh_default_args = $rh_defaults->{$uri};
    if (ref($rh_default_args) eq 'HASH') {
        $args=merge_refs($rh_default_args,$args);
    }

    #############
    #
    # DO SEARCH
    #
    #############

    my $list = $self->get_object($args);
    $list->objname eq 'FS::List' ||
        $list->objname eq 'FS::Collection' ||
        throw $self "search - '$uri' must be a list or a collection";

    #dprint "*** Go Search...\n\n";
    my $ra_query   = $self->_create_query($args, $rh_conf);
    my $ra_all_ids = $list->search(@$ra_query);

    my $last_item_idx  = $#{$ra_all_ids};
    my $total          = scalar(@$ra_all_ids);
    my $items_per_page = int($args->{'items_per_page'} || 0);
    $items_per_page    = 0 if $items_per_page < 1; # show all items in page
    $items_per_page    = 10 if $items_per_page>10000;
    my $start_item     = int($args->{start_item} || 1);
    $start_item        = 1 if $start_item < 1;
    my $limit_reached  = $items_per_page && $total>$items_per_page;

    $start_item=0 if $start_item>1000000000;    # avoiding perl's "panic: memory wrap"

    my $ra_ids;
    if ($items_per_page) {
        my $start_idx = $start_item - 1;
        my $stop_idx  = $start_idx + $items_per_page - 1;
        $stop_idx     = $last_item_idx if $last_item_idx < $stop_idx;
        $ra_ids       = [ @{$ra_all_ids}[$start_idx..$stop_idx] ];
    }
    else {
        $ra_ids = $ra_all_ids;
    }

    #dprint "*** START_ITEM     = $start_item";
    #dprint "*** ITEMS_PER_PAGE = $items_per_page";
    #dprint "*** TOTAL_ITEMS    = $total";
    #dprint "*** LIMIT_REACHED  = $limit_reached";

    #############
    #
    # DISPLAY ITEMS
    #
    #############

    my $page     = $self->object(objname => 'Page');
    my $basetype = '';

    if (!$total && ($args->{'default.path'} || defined($args->{'default.template'}))) {
        #
        # Display default if appropriate
        #
        my $default = '';
        if(defined($args->{'default.template'})) {
            $basetype = 'template';
            $default  = $args->{'default.template'};
        }
        elsif ($args->{'default.path'}) {
            $basetype = 'path';
            $default  = $args->{'default.path'};
        }
        $page->display(
            merge_refs(
                $args,
                {
                    $basetype      => $default,
                    START_ITEM     => $start_item,
                    ITEMS_PER_PAGE => $items_per_page,
                    TOTAL_ITEMS    => $total,
                    LIMIT_REACHED  => $limit_reached,
                }
            )
        );
    }
    else {
        
        $page->display(merge_refs($args, {
            template        => $args->{'header.template'},
            path            => $args->{'header.path'},
            START_ITEM      => $start_item,
            ITEMS_PER_PAGE  => $items_per_page,
            TOTAL_ITEMS     => $total,
            LIMIT_REACHED   => $limit_reached,
        })) if $args->{'header.path'} || $args->{'header.template'};

        #
        # Display items
        #
        my @fields;
        if($args->{fields}) {
            if($args->{fields} eq '*') {
                my $n=XAO::Objects->new(
                    objname => $list->describe->{class},
                    glue    => $self->odb,
                );
                @fields=map { $n->describe($_)->{type} eq 'list' ? () : $_ } $n->keys;
            }
            else {
                @fields=split(/\W+/,$args->{fields});
                shift @fields unless length($fields[0]);
            }
        }
        my @ucfields=map { uc($_) } @fields;

        my $have_sep=($args->{'separator.path'} || $args->{'separator.template'});

        my $group_have_header=($args->{'group.header.path'} || $args->{'group.header.template'});
        my $group_have_footer=($args->{'group.footer.path'} || $args->{'group.footer.template'});
        my $group_items=$args->{'group.items_count'} || 0;
        $group_items=0 unless $group_have_header || $group_have_footer;

        my $count=1;
        my $pass=merge_refs($args);
        foreach my $id (@$ra_ids) {
            @{$pass}{qw(ID COUNT MATCH_NUMBER)}=
                ($id,$count,$count+($start_item-1));

            ##
            # Displaying group-header if needed
            #
            if($group_items && $group_have_header) {
                if((($count-1) % $group_items)==0) {
                    my $group_count=int(($count-1)/$group_items);
                    $page->display($args,{
                        path        => $args->{'group.header.path'},
                        template    => $args->{'group.header.template'},
                        GROUP_COUNT => $group_count,
                        IS_FIRST    => $group_count ? 0 : 1,
                        IS_LAST     => int((scalar(@$ra_ids)-1)/$group_items)<=$group_count ? 1 : 0,
                    });
                 }
            }

            if(@fields) {
                my $item=$list->get($id);
                @{$pass}{@ucfields}=$item->get(@fields);
            }
            $page->display($pass);

            ##
            # Displaying separator if given.
            #
            my $last_item=($count>=scalar(@$ra_ids) ? 1 : 0);
            if($have_sep && $count < scalar(@$ra_ids)) {
                $page->display(merge_refs($pass,{
                    path        => $args->{'separator.path'},
                    template    => $args->{'separator.template'},
                }));
            }

            ##
            # Displaying group-footer if needed
            #
            if($group_items && $group_have_footer) {
                if($last_item || ($count % $group_items)==0) {
                    my $group_count=int(($count-1)/$group_items);
                    $page->display($args,{
                        path        => $args->{'group.footer.path'},
                        template    => $args->{'group.footer.template'},
                        GROUP_COUNT => $group_count,
                        IS_FIRST    => $group_count ? 0 : 1,
                        IS_LAST     => $last_item,
                    });
                 }
            }
        }
        continue {
            $count++;
        }

        $page->display(merge_refs($args, {
            template        => $args->{'footer.template'},
            path            => $args->{'footer.path'},
            START_ITEM      => $start_item,
            ITEMS_PER_PAGE  => $items_per_page,
            TOTAL_ITEMS     => $total,
            LIMIT_REACHED   => $limit_reached,
        })) if $args->{'footer.path'} || $args->{'footer.template'};
    }   
}
###############################################################################
sub _create_query {

    my $self=shift;

    my ($args, $rh_conf) = @_;

    #dprint "*** _create_query START";

    my $i=1;
    my @expr_ra;
    while ($args->{"index_$i"}) {

        my $index      = $args->{"index_$i"} =~ /\S+/
                       ? $args->{"index_$i"}
                       : throw $self "_create_query - condition $i missing index";
        my $value      = exists $args->{"value_$i"}
                       ? $args->{"value_$i"}
                       : throw $self "_create_query - condition $i missing value";
        my $compare_op = exists $args->{"compare_$i"} && $args->{"compare_$i"} =~ /\S+/
                       ? $args->{"compare_$i"}
                       : throw $self "_create_query - condition $i missing comparison operator";

        #dprint "\n  ** $i **";
        #dprint "  ## index:            $index";
        #dprint "  ## value:            $value";
        #dprint "  ## compare operator: $compare_op";

        #
        # Create ref to array w/ object expression for index/value pair
        #
        my @indexes = split(/\|/, $index);
        if ($compare_op eq 'wq' || $compare_op eq 'ws') {
            if ($value =~ /\s/) {
                my @value_list=split(/\s+/, $value);
                shift(@value_list) if @value_list && length($value_list[0])==0;
                $value=\@value_list;
            }
            $expr_ra[$i]=$self->_create_expression(\@indexes, $compare_op, $value);
        }
        elsif ($compare_op =~ /^(g[et])(l[et])$/) {
            my ($lo, $hi) = split(/\|/, $value);
            foreach (@indexes) {
                my $ra_temp  = [ [$_, $1, $lo] and [$_, $2, $hi] ];
                $expr_ra[$i] = ref($expr_ra[$i]) eq 'ARRAY'
                             ? [$expr_ra[$i], 'or', $ra_temp] : $ra_temp;
            }
        }
        else {
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
    #$i+=100;

    my $expression =  lc($args->{expression} || '');
    if ($expression) {
        $expression =~ s/^\s+//;
        $expression =~ s/\s+$//;
        $expression =~ s/\[\s+/\[/g;
        $expression =~ s/\s+\]/\]/g;
        $expression =~ s/\s+/ /g;
        $expression =~ s/(.+)/[$1]/ unless $expression =~ /^\[.+\]$/;
    }
    else {
        if ($i == 2 && ref($expr_ra[1]) eq 'ARRAY') {
            $expression = '[1]';
        }
        elsif ($i < 2) {
            $expression = '';
        }
        else {
            throw $self "_create_query - conditions present without expression";
        }
    }
    #dprint "\n    ## EXPRESSION: '$expression'";

    my $regex = '\[(\d+) ([andor]+) (\d+)\]'; #was: '\[\s*(\d+)\s+(\w+)\s+(\d+)\s*\]';
    if ($expression =~ /$regex/) {
        $self->_interpret_expression(
            \@expr_ra,
            \$expression,
            \$i, $1, $2, $3,
            $regex,
        );
        $i--;
        ###########################################################################
        sub _interpret_expression {
            my $self = shift;
            my ($ra_expr_ra, $r_expr, $r_i, $i1, $i2, $i3, $regex) = @_;
            if ($i2 ne 'and' && $i2 ne 'or') {
                throw $self "_create_query - syntax error [$i1 $i2 $i3]";
            }
            elsif (ref($ra_expr_ra->[$i1]) ne 'ARRAY') {
                throw $self "_create_query - condition '$i1' in expression is not specified";
            }
            elsif (ref($ra_expr_ra->[$i3]) ne 'ARRAY') {
                throw $self "_create_query - condition '$i3' in expression is not specified";
            }
            $ra_expr_ra->[$$r_i] = [ $ra_expr_ra->[$i1], $i2, $ra_expr_ra->[$i3] ];
            #dprint "    ## $$r_i = '[$i1 $i2 $i3]'";
            $$r_expr =~ s/\[$i1 $i2 $i3\]/$$r_i/; #was: s/\[\s*$i1\s+$i2\s+$i3\s*\]/$$r_i/;
            #dprint "    ## new EXPRESSION: '$$r_expr' ($r_expr)";
            ${$r_i}++;
            $$r_expr = "[$$r_expr]" if $$r_expr =~ /^\d+ [andor]+ \d+$/;
            unless ($$r_expr =~ /\[\d+ and \d+\]/
                 || $$r_expr =~ /\[\d+ or \d+\]/
                 || $$r_expr =~ /^\d+$/) {
                throw $self "_create_query - syntax error";
            }
            return unless $$r_expr =~ /$regex/;
            $self->_interpret_expression(
                $ra_expr_ra,
                $r_expr,
                $r_i, $1, $2, $3,
                $regex,
            );
        }
        ###########################################################################
    }
    else {
        #dprint "    ## NO REGEX";
        if ($expression =~ /^\[(\d+)\]$/) {
            unless (ref($expr_ra[$1]) eq 'ARRAY') {
                throw $self "_create_query - condition '$1' not specified";
            }
            $expr_ra[$i] = $expr_ra[$1];
        }
        elsif (!$expression) {
            $expr_ra[$i] = [];
        }
        else {
            throw $self "_create_query - syntax error";
        }
    }

    #
    # Add any extra search options
    #
    if ($args->{orderby} || $args->{distinct} || $args->{limit} || $args->{debug}) {
        my $rh_options = {};

        if($args->{debug}) {
            $rh_options->{debug}=1;
        }

        #
        # Sort specifications
        #
        if ($args->{orderby}) {
            my $ra_orderby = [];
            foreach (split(/\|/, $args->{orderby})) {
                my $direction = /^-/ ? 'descend' : 'ascend';
                s/[\s\+-]+//g;
                push @$ra_orderby, ($direction => $_);
            }
            $rh_options->{orderby} = $ra_orderby;
        }

        #
        # Distinct searching
        #
        $rh_options->{distinct} = $args->{distinct} if $args->{distinct};

        #
        # Limit on total amount of results
        #
        $rh_options->{limit} = $args->{limit} if $args->{limit};

        push @{$expr_ra[$i]}, $rh_options;
    }

    #dprint "\n    ## QUERY START ##"
    #     . $self->_searcharray2str($expr_ra[$i], '')
    #     . "\n    ## QUERY STOP  ##\n"
    #     . "\n*** _create_query STOP\n\n";

    $expr_ra[$i];
}
###############################################################################
sub _create_expression {
    my $self=shift;
    my ($ra_indexes, $compare_op, $value) = @_;
    my $ra_expr;
    foreach my $index (@$ra_indexes) {
        my $ra_temp = [$index, $compare_op, $value];
        $ra_expr    = ref($ra_expr) eq 'ARRAY' ? [$ra_expr, 'or', $ra_temp] : $ra_temp;
    }
    $ra_expr;
}
###############################################################################
sub _searcharray2str() {
    my $self=shift;
    my ($ra, $indent) = @_;
    my $indent_new = $indent . ' ';
    my $i=0;
    my $innermost=1;
    my $str= "\n" . $indent . "[";
    foreach (@$ra) {
        $str .= ' ';
        if    (ref($_) eq 'ARRAY') {
            $str .=  $self->_searcharray2str($_, $indent_new);
        }
        elsif (ref($_) eq 'HASH') {
            $str .= '{ ';
            foreach my $key (keys %$_) { $str .= qq!'$key' => '$_->{$key}', !; }
            $str .= ' },';
        }
        else {
            if (($i==1) && (/and/ or /or/)) {
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
sub delete_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $list=$self->get_object($args);
    my $id=$args->{id} || throw $self "delete_object - no 'id'";
    $list->delete($id);
}

###############################################################################

sub edit_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $list   = $self->get_object($args);
    my @fields = @{$self->form_fields};

    #
    # If we have ID then we're editing this object
    # otherwise we're creating a new one.
    #
    my $id = $args->{id} || '';
    my %values;
    if ($id) {
        my @fnames_to_get;
        foreach my $fdata (@fields) {
            next if $fdata->{style} eq 'password';
            push @fnames_to_get, $fdata->{name};
        }
        my $object=$list->get($id);
        @values{@fnames_to_get}=$object->get(@fnames_to_get);
    }

    my @unique_fields;
    foreach my $fdata (@fields) {
        push @unique_fields, $fdata->{name} if exists($fdata->{unique})
                                            && $fdata->{unique};
    }

    my $form = $self->object(objname => 'Web::FilloutForm');
    $form->setup(
        fields      => \@fields,
        values      => \%values,
        submit_name => $id ? 'done' : undef,
        check_form  => sub {
            my $form = shift;
            foreach my $fieldname (@unique_fields) {
                my $results = $list->search(
                                    $fieldname,
                                    'eq',
                                    $form->field_desc($fieldname)->{value}
                              );
                if(($id && @$results>1) || (!$id && @$results)) {
                    my $field_text = 'Unique Identifier';
                    foreach my $fdata (@fields) {
                        if ($fdata->{name} eq $fieldname) {
                            $field_text = $fdata->{text};
                            last;
                        }
                    }
                    return "This '$field_text' is already taken";
                }
            }
            return '';
        },
        form_ok     => sub {
            my $form   = shift;
            my $object = $id ? $list->get($id) : $list->get_new();
            foreach my $name (map { $_->{name} } @fields) {
                my $fdata = $form->field_desc($name);
                my $value = $fdata->{value};
                if ($fdata->{style} eq 'password') {
                    next unless $fdata->{pair};
                    if(!$fdata->{encrypt} || $fdata->{encrypt} eq 'md5') {
                        $value=md5_base64($value);
                    }
                    elsif($fdata->{encrypt} eq 'plaintext') {
                        # nothing
                    }
                    else {
                        throw $self "edit_object - unknown encryption '$fdata->{encrypt}'";
                    }
                }
                $object->put($name => $value);
            }
            $id ? $list->put($id => $object) : $list->put($object);
            $self->object->display(path => $args->{'success.path'});
        },
    );

    $form->display($args);
}
###############################################################################
#
# This method should be overwritten to include form specs
# since they depend on data structure.
#
sub form_fields {
    my $self=shift;
    return [ ];
}
###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2003-2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2000-2002 XAO, Inc.

Andrew Maltsev <am@xao.com>, Marcos Alves <alves@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
