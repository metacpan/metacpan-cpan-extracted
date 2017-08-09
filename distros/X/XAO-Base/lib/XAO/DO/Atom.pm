=head1 NAME

XAO::DO::Atom - recommended base object for all XAO dynamic objects

=head1 SYNOPSIS

Throwing an error from XAO object:

 throw $self "method - no 'foo' parameter";

=head1 DESCRIPTION

Provides some very basic functionality and common methods for all XAO
dynamic objects.

Atom (XAO::DO::Atom) was introduced in the release 1.03 mainly to
make error throwing uniform in all objects. There are many objects
currently not derived from Atom, but that will eventually change.

All new XAO dynamic object should use Atom as their base if they are not
already based on dynamic object.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Atom;
use strict;
use XAO::Utils;
use XAO::Errors;

###############################################################################

=item new (%)

Generic new - just stores everything that it gets in a hash. Can be
overriden if an object uses something different then a hash as a base or
needs a different behavior.

=cut

sub new ($%) {
    my $proto=shift;
    my $self=merge_refs(get_args(\@_));
    bless $self,ref($proto) || $proto;
}

###############################################################################

=item objname

Returns the shorthand objname that was passed to XAO::Objects->new()
when creating this object. It is not the same as the fully qualified
class name.

=cut

sub objname ($) {
    return $_[0]->{'objname'};
}

###############################################################################

=item throw ($)

Helps to write code like:

 sub foobar ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $id=$args->{id} || throw $self "foobar - no 'id' given";
    ...
 }

It is recommended to always use text messages of the following format:

 "function_name - error description starting with a lowercase letter"
 or
 "- error description starting with a lowercase letter"
 or
 "(arg1,arg2) - error description"

There is no need to print class name, it will be prepended to the front
of your error message automatically. If the message starts with '- ' or '('
then the function name is taken from the stack and added automatically
too.

=cut

sub throw ($@) {
    my $self=shift;
    my $text=join('',map { defined $_ ? $_ : '<UNDEF>' } @_);

    my $class;
    if(eval { $self->{'objname'} } && !$@) {
        $class='XAO::DO::' . $self->{'objname'};
    }
    else {
        $class=ref($self);
    }

    if($text =~ /^\s*-\s+/) {
        (my $fname=(caller(1))[3])=~s/^.*://;
        $text=$fname . ' ' . $text;
    }
    elsif($text =~ /^\s*\(/) {
        (my $fname=(caller(1))[3])=~s/^.*://;
        $text=$fname . $text;
    }

    $text.=" (file ".((caller(0))[1]).", line ".((caller(0))[2]).", called from ".((caller(1))[1]).", line ".((caller(1))[2]).")\n";

    XAO::Errors->throw_by_class($class,$text);
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2002 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

L<XAO::Objects>
