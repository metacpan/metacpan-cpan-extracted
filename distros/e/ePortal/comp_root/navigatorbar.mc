%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%init>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      # backgroup color of navigator
      bgcolor => {type => SCALAR, optional => 1},
      # width of <table> element
      width   => {type => SCALAR, optional => 1},
      # ARRAYREF of items to display
      # { title => ...
      #   href => ...
      #   alt => ...
      #   bold => 1     # make the item bold
      #   hidden => 1   # make invisible
      # }
      items   => {type => ARRAYREF},
      # Truncate long titles to this length
      truncate => { type => SCALAR, optional => 1},
      # separator between items
      separator => {type => SCALAR, optional => 1},
      # Highlight bold first or last item of navigator?
      bold_first => {type => BOOLEAN, optional => 1},
      bold_last  => {type => BOOLEAN, optional => 1},
      # show not more than N last items
      truncate_items => {type => SCALAR, optional => 1},
    });  
  }
  $ARGS{bgcolor} ||= '#FFEEEE';
  $ARGS{width}   ||= '100%';
  $ARGS{truncate} = 30            if ! exists $ARGS{truncate};
  $ARGS{separator} = '&nbsp;|&nbsp;'   if ! exists $ARGS{separator};
  $ARGS{truncate_items} = 3       if ! exists $ARGS{truncate_items};

  my $counter = 0;
  my $items_total = scalar(@{$ARGS{items}});
  foreach my $item (@{$ARGS{items}}) {
    $counter ++;
    throw ePortal::Exception::Fatal(-text =>"[items] parameters should be ARRAYREF of HASHREF")
      if ( ref($item) ne 'HASH' );

    # Name something unnamed items
    $item->{title} = pick_lang(rus => "Без имени", eng => "No name")
      if ( $item->{title} eq '' );

    # Truncate long titles
    if ( $ARGS{truncate} ) {
      if ( length($item->{title}) > $ARGS{truncate} ) {
        $item->{alt} = $item->{title} if $item->{alt} eq '';
        $item->{title} = truncate_string( $item->{title}, $ARGS{truncate} )
      }
    }

    # make the item bold
    $item->{bold} = 1
      if ( $ARGS{bold_first} and $counter == 1 );
    $item->{bold} = 1
      if ( $ARGS{bold_last} and $counter == $items_total );
  }

  # Very deep navigator truncate to short one
  # Always show first item and N last
  if ( $items_total > $ARGS{truncate_items}+1 ) {
    $ARGS{items}->[1] = { title => '...' }
  }
  if ( $items_total > $ARGS{truncate_items}+2 ) {
    for ( 1 .. $items_total - $ARGS{truncate_items} - 2 ) {
      delete $ARGS{items}->[2];
    }
  }
</%init>
%if ( $ePortal::DEBUG ) {
<!-- start of /navigatorbar.mc -->
%}
<table border=0 bgcolor="<% $ARGS{bgcolor} %>" width="<% $ARGS{width} %>"><tr><td align="left">

<div style="text-indent: -3cm; margin-left: 3cm;">
%$counter = 0;
%foreach my $item (@{$ARGS{items}}) {
% $counter++;
% next if $item->{hidden};
<% $counter > 1 ? $ARGS{separator} : undef %>
%if ($item->{href}) {
<a href="<% $item->{href} %>" title="<% $item->{alt} %>">
%}
<% $item->{bold} ? '<b>' : undef %>\
<% $item->{title} |h %>\
<% $item->{bold} ? '</b>' : undef %>\
<% $item->{href} ? '</a>' : undef %>\
% }
</div>

</td></tr></table>
%if ( $ePortal::DEBUG ) {
<!-- end of /navigatorbar.mc -->
%}
