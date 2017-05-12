=head1 NAME

XAO::DO::Web::MenuBuilder - building all sorts of menus

=head1 SYNOPSIS

 <%MenuBuilder
   base="/bits/top-menu"
   item.0="statistic"
   item.1="config"
   item.1.grayed
   item.2="password"
   item.2.grayed
   active="statistic"
 %>

 <%MenuBuilder
   base="/bits/top-menu"
   item.0="statistic"
   item.1="config"
   item.2="password"
   grayed="config,password"
   active="statistic"
 %>

=head1 DESCRIPTION

Assumes the following file structure at the `base':

 header           - static menu header (optional)
 footer           - static menu footer (optional)
 separator        - static menu items separator
 item-NAME-normal - normal item text
 item-NAME-grayed - grayed item text
 item-NAME-active - currently opened page

If "grayed" argument is "*" then all menu items are displayed in
"grayed" mode.

=cut

###############################################################################
package XAO::DO::Web::MenuBuilder;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Templates;

use base XAO::Objects->load(objname => 'Web::Page');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: MenuBuilder.pm,v 2.2 2006/09/30 03:08:07 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Base directory is required!
    #
    my $base=$args->{'base'} ||
        throw $self "display - no `base' defined";

    ##
    # Building the list of items to show
    #
    my %items;
    foreach my $item (keys %{$args}) {
        next unless $item =~ /^item.(\w+)$/;
        next unless $args->{$item};
        $items{$1}=$args->{$item};
    }

    ##
    # Now buiding the list of grayed out items
    #
    my %grayed;
    if($args->{'grayed'}) {
        if($args->{'grayed'} eq '*') {
            %grayed=map { $_ => 1 } values %items;
        }
        else {
            %grayed=map { $_ => 1 } split(/[,;\s]+/,$args->{'grayed'});
        }
    }
    else {
        foreach my $item (keys %items) {
            $grayed{$items{$item}}=1 if $args->{"item.$item.grayed"};
        }
    }

    ##
    # And finally displaying items.
    #
    my $page=$self->object;
    $page->display($args,{
        path => "$base/header",
    }) if XAO::Templates::filename("$base/header");

    my $first=1;
    my $sepexists=XAO::Templates::filename("$base/separator");
    foreach my $item (sort { ($a =~ /^\d+$/ && $b =~ /^\d+$/)
                                ? $a <=> $b
                                : $a cmp $b } keys %items) {
        my $name=$items{$item};
        $page->display(path => "$base/separator") if !$first && $sepexists;
        $first=0;

        my %params=(
            NORMAL  => '',
            ACTIVE  => '',
            GRAYED  => '',
        );
        my $subpath;
        if($grayed{$name}) {
            $subpath='grayed';
            $params{'GRAYED'}=1;
        }
        elsif(defined($args->{'active'}) && $name eq $args->{'active'}) {
            $subpath='active';
            $params{'ACTIVE'}=1;
        }
        else {
            $subpath='normal';
            $params{'NORMAL'}=1;
        }

        $params{'path'}="$base/item-$name-$subpath";

        if($subpath ne 'normal' && !XAO::Templates::filename($params{'path'})) {
            $params{'path'}="$base/item-$name-normal";
        }

        $page->display($args,\%params);
    }

    $page->display($args,{
        path => "$base/footer",
    }) if XAO::Templates::filename("$base/footer");
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
