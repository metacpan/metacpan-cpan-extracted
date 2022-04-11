=head1 NAME

XAO::DO::Web::Clipboard - clipboard value retrieval object.

=head1 SYNOPSIS

Currently is only useful in XAO::Web site context.

=head1 DESCRIPTION

Clipboard object is based on Action object (see L<XAO::DO::Web::Action>)
and therefor what it does depends on the "mode" argument.

For each mode there is a separate method with usually very similar
name. The list below lists mode names and their method counterparts.

=over

=cut

###############################################################################
package XAO::DO::Web::Clipboard;
use strict;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Clipboard);
use base XAO::Objects->load(objname => 'Web::Action');

our $VERSION='2.001';

sub check_mode ($$) {
    my $self = shift;
    my $args = get_args(\@_);
    my $mode = $args->{mode} || 'show';

    if ($mode eq 'set') {
        $self->clipboard_set($args);
    }
    elsif ($mode eq 'show') {
        $self->clipboard_show($args);
    }
    elsif ($mode eq 'array-push') {
        $self->clipboard_array_push($args);
    }
    elsif ($mode eq 'array-size') {
        $self->clipboard_array_size($args);
    }
    elsif ($mode eq 'array-pop') {
        $self->clipboard_array_pop($args);
    }
    elsif ($mode eq 'array-list') {
        $self->clipboard_array_list($args);
    }
    else {
        throw XAO::E::DO::Web::Clipboard "check_mode - unknown mode '$mode'";
    }
}

###############################################################################

=item 'set' => clipboard_set (%)

Sets a value in the clipboard. Example:

 <%Clipboard mode='set' name='foo' value='bar'%>

If there is no 'value' argument it puts 'undef' into the clipboard, but
does not remove the named record.

=cut

sub clipboard_set ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $name=$args->{name} ||
        throw XAO::E::DO::Web::Clipboard "clipboard_set - no 'name' given";

    $self->clipboard->put($name => $args->{value});
}

###############################################################################

=item 'show' => clipboard_show (%)

Displays clipboard parameter with the given "name". Example:

 <%Clipboard mode="show" name="username" default="aa@bb.com"%>

Would display whatever is set in the Clipboard for variable
"username" or "aa@bb.com" if it is not set.

=cut

sub clipboard_show ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $clipboard = $self->clipboard;
    $args->{name} ||
        throw XAO::E::DO::Web::Clipboard "clipboard_show - no 'name' given";

    my $value = $clipboard->get($args->{name});
    $value    = $args->{default} if !defined($value) || ref($value);

    $self->textout($value) if defined $value;
}

###############################################################################

=item 'array-push' => clipboard_array_push (%)

Push a value into an array with the given "name". Example:

 <%Clipboard mode='array-push' name='elements' value='Something'%>

Displays nothing.

=cut

sub clipboard_array_push ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $name = $args->{'name'} ||
        throw $self "- no 'name' given";

    my $clipboard = $self->clipboard;

    my $array = $clipboard->get($name);

    if(!ref $array || ref $array ne 'ARRAY') {
        undef $array;
    }

    if(!defined $array) {
        $array = [];
        $clipboard->put($name => $array);
    }

    push(@$array, $args->{'value'});
}

###############################################################################

=item 'array-pop' => clipboard_array_pop (%)

Output the topmost element of the given array.

 <%Clipboard mode='array-pop' name='elements'%>

If there is no array at that location, there is an empty array, or there
is a non-array value, then there is no output.

=cut

sub clipboard_array_pop ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $name = $args->{'name'} ||
        throw $self "- no 'name' given";

    my $array = $self->clipboard->get($name);

    if(ref $array && ref $array eq 'ARRAY' && @$array) {
        $self->textout(pop @$array);
    }
}

###############################################################################

=item 'array-list' => clipboard_array_list (%)

Iterate over all array elements, displaying each element with the given
template or path.

 <%Clipboard mode='array-list' name='elements' template='<$VALUE$>'%>

=cut

sub clipboard_array_list ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $name = $args->{'name'} ||
        throw $self "- no 'name' given";

    my $array = $self->clipboard->get($name);

    (ref $array && ref $array eq 'ARRAY') ||
        return;

    my $page=$self->object;

    for(my $i=0; $i < @$array; ++$i) {
        $page->display($page->pass_args($args->{'pass'}, $args),{
            path        => $args->{'path'},
            template    => $args->{'template'},
            VALUE       => $array->[$i] // '',
            INDEX       => $i,
            SIZE        => scalar @$array,
        });
    }
}

###############################################################################

=item 'array-size' => clipboard_array_size (%)

Output the number of elements in the given array.

 <%Clipboard mode='array-size' name='elements'%>

If there is no array at that location or there is a non-array value,
then there is no output.

=cut

sub clipboard_array_size ($%) {
    my $self = shift;
    my $args = get_args(\@_);

    my $name = $args->{'name'} ||
        throw $self "- no 'name' given";

    my $array = $self->clipboard->get($name);

    if(ref $array && ref $array eq 'ARRAY') {
        $self->textout(scalar(@$array));
    }
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2003-2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>, Marcos Alves <alves@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
