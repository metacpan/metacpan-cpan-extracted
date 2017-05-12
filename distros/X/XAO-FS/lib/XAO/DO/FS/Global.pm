=head1 NAME

XAO::DO::FS::Global - root node of objects tree

=head1 SYNOPSIS

 use XAO::Objects;

 my $global=XAO::Objects->new(objname => 'FS::Global');
 $global->connect($dbh);

=head1 DESCRIPTION

FS::Global is a XAO dynamicaly overridable object that serves as
a root node in objects tree. It is not recommended to override it for
specific site unless you're positive there is no way to avoid that and
you know enough about object server internalities.

=cut

###############################################################################
package XAO::DO::FS::Global;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Hash');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Global.pm,v 2.1 2005/01/14 00:23:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

sub new ($%) {
    my $class=shift;
    my $self=$class->SUPER::new(@_);
    $$self->{unique_id}=1;
    $$self->{detached}=0;
    $self;
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).
