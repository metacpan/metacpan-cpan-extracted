=head1 NAME

XAO::Errors - throwable errors namespace support

=head1 SYNOPSIS

 package XAO::Fubar;
 use XAO::Errors qw(XAO::Fubar);

 sub foo {
    ...
    throw XAO::E::Fubar "foo - wrong arguments";
 }

=head1 DESCRIPTION

Magic module that creates error namespaces for caller's. Should be
used in situations like that. Say you create a XAO module called
XAO::DO::Data::Product and want to throw errors from it. In order for
these errors to be distinguishable you need separate namespace for
them -- that's where XAO::Errors comes to rescue.

In the bizarre case when you want more then one namespace for
errors - you can pass these namespaces into XAO::Errors and it will
make them throwable. It does not matter what to pass to XAO::Errors -
the namespace of an error or the namespace of the package, the result
would always go into XAO::E namespace.

=cut

###############################################################################
package XAO::Errors;
use strict;
use Error;

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Errors.pm,v 2.1 2005/01/13 22:34:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

use vars qw(%errors_cache);

sub load_e_class ($) {
    my $module=shift;
    my $em;
    if($module=~/^XAO::E((::\w+)+)$/) {
        $em=$module;
        $module='XAO' . $1;
    }
    elsif($module=~/^XAO((::\w+)+)$/) {
        $em='XAO::E' . $1;
    }
    else {
        throw Error::Simple "Can't import error module for $module";
    }

    return $em if $errors_cache{$em};

    eval <<END;

package $em;
use strict;
use Error;
use vars qw(\@ISA);
\@ISA=qw(Error::Simple);

sub throw {
    my \$self=shift;
    my \$text=join('',map { defined(\$_) ? \$_ : '<UNDEF>' } \@_);
    \$self->SUPER::throw('${module}::' . \$text);
}

1;
END
    throw Error::Simple $@ if $@;
    $errors_cache{$em}=1;

    return $em;
}

sub import {
    my $class=shift;
    my @list=@_;

    foreach my $module (@list) {
        load_e_class($module);
    }
}

sub throw_by_class ($$$) {

    @_==2 || @_==3 ||
        throw Error::Simple "throw_by_class - number of arguments is not 2 or 3";

    my $self=(@_==3) ? shift : 'XAO::Errors';
    my $class=shift;
    $class=ref($class) if ref($class);

    my $text=shift;

    my $em=load_e_class($class);

    ##
    # Most probably will screw up stack trace, need to check and fix!
    #
    no strict 'refs';
    $em->throw($text);
}

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.
