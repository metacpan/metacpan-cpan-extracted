
package Apache::Request::Controller;

use strict;
use APR::Table;
use Apache::RequestRec;
use Apache::RequestIO;
use Apache::SubRequest;

use Apache::Const qw(:common :methods :http);
#use Exception qw(:all);

use Carp qw(cluck);

# /* create */ {{{
sub create
{
    my $self  = shift;
    my $table = $self->__openTable();

    my $row = $self->_constructRow($table);
    if (defined($self->{'apr'}->param('action')) && lc($self->{'apr'}->param('action')) eq 'create')
    {
        if ($row->insert())
        {
            return $self->_internalRedirect($table->componentName() . '/list');
        }
        # validation failed - redisplay the form.
    }
    return $self->_createResponse($table, $row);
}
# /* create */ }}}

# /* _createResponse */ {{{ 
sub _createResponse
{
    my $self = shift;

    my $table = shift;
    my $row   = shift;

    $self->{'request'}->status(HTTP_OK);
    $self->{'request'}->content_type('text/html');

    $self->{'template'}->process(ucfirst(lc($table->name())) . "/create.tt2",
                                 {TABLE => $table,
                                  ROW   => $row}) or do {  print $self->{'template'}->error } ;
    return OK;
}
# /* _createResponse */ }}} 

# /* _constructRow */ {{{ 
sub _constructRow
{
    my $self = shift;
    my $table = shift;

    my $obj = {};
    foreach my $field ($table->fields)
    {
        if ($table->field($field)->{'is_array'})
        {
            my @values = split(/\,/, $self->{'apr'}->param($field));
            $obj->{$field} = \@values;
        }
        else
        {
            $obj->{$field} = $self->{'apr'}->param($field);
        }
    }
    return $table->constructRow($obj);
}
# /* _constructRow */ }}} 

# /* _get */ {{{
sub _get
{
    my $self = shift;
    my $table = shift;
    
    my @pkeys;
    foreach my $pkey ($table->primaryKeys)
    {
        push @pkeys, $self->{'apr'}->param($pkey);
    }
    return $table->getRowByPKey(@pkeys);
}
# /* _get */ }}}

# /* show */ {{{
sub show
{
    my $self       = shift;
    my $table      = $self->__openTable();

    my $row = $self->_get($table);

    return $self->_showResponse($table, $row);
}
# /* show */ }}}

# /* _showResponse */ {{{ 
sub _showResponse
{
    my $self = shift;

    my $table = shift;
    my $row   = shift;
    $self->{'request'}->status(HTTP_OK);
    $self->{'request'}->content_type('text/html');
    $self->{'template'}->process(ucfirst(lc($table->name())) . "/show.tt2",
                                 {TABLE => $table,
                                  ROW   => $row}) or do { print $self->{'template'}->error };
    return OK;
}
# /* _showResponse */ }}} 

# /* edit */ {{{
sub edit
{
    my $self  = shift;
    my $table = $self->__openTable();
    my $row = $self->_get($table);

    return $self->_editResponse($table, $row);
}
# /* edit */ }}}

# /* _editResponse */ {{{ 
sub _editResponse
{
    my $self = shift;

    my $table = shift;
    my $row = shift;

    $self->{'request'}->status(HTTP_OK);
    $self->{'request'}->content_type('text/html');
    $self->{'template'}->process(ucfirst(lc($table->name())) . "/edit.tt2",
                                 {TABLE => $table,
                                  ROW   => $row}) or do { print $self->{'template'}->error };
    return OK;
}
# /* _editResponse */ }}} 

# /* update */ {{{
sub update
{
    my $self       = shift;
    my $table      = $self->__openTable();

    my $row = $self->_get($table);

    $self->_updateRow($table, $row);
    unless ($row->update())
    {
        return $self->_editResponse($table, $row);
    }
    return $self->_internalRedirect($table->componentName() . '/list');
}
# /* update */ }}}

# /* _updateRow */ {{{ 
sub _updateRow
{
    my $self = shift;

    my $table = shift;
    my $row   = shift;

    foreach my $field ($table->fields)
    {
        $row->$field($self->{'apr'}->param($field));
    }
}
# /* _updateRow */ }}} 

# /* delete */ {{{
sub delete
{
    my $self       = shift;
    my $table      = $self->__openTable();

    my $row = $self->_get($table) || return $self->list;
    $row->delete();

    return $self->list;
}
# /* delete */ }}}

# /* list */ {{{
sub list
{
    my $self       = shift;
    my $table      = $self->__openTable();

    my @rows = $table->getRowsByPKey();

    my $book = $self->_constructBook($table, \@rows);

    return $self->_listResponse($table, \@rows, $book);
}
# /* list */ }}}

# /* _constructBook */ {{{ 
sub _constructBook
{
    my $self  = shift;
    my $table = shift;
    my $rows  = shift;

    my $numRows  = scalar(@{$rows});
    my $pageNum  = $self->{'apr'}->param('pageNum');
    my $pageSize = $self->{'apr'}->param('pageSize');

    if ($pageNum eq '')
    {
        $pageNum = $self->{'session'}->{$table->name}->{'pageNum'};
        $pageNum = 1 if ($pageNum eq '');
    }

    if ($pageSize eq '')
    {
        $pageSize = $self->{'session'}->{$table->name}->{'pageSize'};
        $pageSize = 10 if ($pageSize eq '');
    }
    elsif ($pageSize == 0)
    {
        $pageSize = $numRows;
    }

    $self->{'session'}->{$table->name}->{'pageNum'}  = $pageNum;
    $self->{'session'}->{$table->name}->{'pageSize'} = $pageSize;

    my $book = { rows     => $numRows,
                 pageNum  => $pageNum,
                 pageSize => $pageSize };
    return $book;
}
# /* _constructBook */ }}} 

# /* _listResponse */ {{{ 
sub _listResponse
{
    my $self = shift;

    my $table = shift;
    my $rows  = shift;
    my $book  = shift;
    my $pattern = shift;

    $self->{'request'}->status(HTTP_OK);
    $self->{'request'}->content_type('text/html');
    $self->{'template'}->process(ucfirst(lc($table->name())) . "/list.tt2",
                                 {TABLE   => $table,
                                  ROWS    => $rows,
                                  BOOK    => $book,
                                  PATTERN => $pattern}) or do { print $self->{'template'}->error };
    return OK;
}
# /* _listResponse */ }}} 

# /* search */ {{{ 
sub search
{
    my $self = shift;

    my $table = $self->__openTable();
    my $pattern = $self->{'apr'}->param('pattern') || '';
    unless ($pattern)
    {
        return $self->list;
    }

    my @rows = $table->searchRowsByString($pattern);
    my $book = $self->_constructBook($table, \@rows);

    return $self->_listResponse($table, \@rows, $book, $pattern);
}
# /* search */ }}} 

# /* _internalRedirect */ {{{ 
sub _internalRedirect
{
    my $self        = shift;
    my $relativeUri = shift;
    my $location = $self->{'request'}->location;

    $self->{'request'}->uri("$location/$relativeUri");
    $self->{'request'}->internal_redirect("$location/$relativeUri");
    return OK;
}
# /* _internalRedirect */ }}} 

# /* _externalRedirect */ {{{ 
sub _externalRedirect
{
    my $self = shift;

    my $relativeUri = shift;
    my $location = $self->{'request'}->location;

    $self->{'request'}->headers_out->set(Location => "$location/$relativeUri");
    return HTTP_MOVED_TEMPORARILY;
}
# /* _externalRedirect */ }}} 

1;
