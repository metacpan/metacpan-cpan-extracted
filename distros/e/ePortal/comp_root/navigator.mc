%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%perl>
my %NAV = %ARGS;

# Pseudo item [root]
$NAV{root}{description} = $NAV{description};
$NAV{root}{title}       = $NAV{title};

# Discover menu items of 1st level
my $spacer1 = '&nbsp;&gt;&gt;&nbsp;';
my $spacer2 = '&nbsp;&middot;&nbsp;';
my (@htmlDescr, @htmlMenu, @htmlSubmenu);

push @htmlDescr, $m->scomp("SELF:item_descr", id => 'root', NAV => \%NAV);
$NAV{url} =~ s/#([^#]+)#/$NAV{$1}/eg;         # replace #id# in URL
foreach my $menu ( @{$NAV{items}} ) {

  # Check for existance of menu HASH
  if (ref($NAV{$menu}) ne 'HASH') {
    throw ePortal::Exception(-text => "Menu $menu is not defined");
  }

  $NAV{$menu}{url}   =~ s/#([^#]+)#/$NAV{$1}/eg;         # replace #id# in URL
  $NAV{$menu}{title} =~ s/^(.{25,25})(.*)$/$1.../o;   # truncate long menu names
  $NAV{$menu}{depend} ||= [];                         # disable when dependency isn't defined
  foreach ( @{$NAV{$menu}{depend}} ) {
    $NAV{$menu}{disabled} = 1 if ! $NAV{$_};
  }
  $NAV{$menu}{disabled} = 1 if $NAV{$menu . '_disabled'};

  # make description
  push @htmlDescr, $m->scomp("SELF:item_descr", id => $menu, NAV => \%NAV);

  # make menu item
  if ( $NAV{$menu}{disabled} ) {
    push @htmlMenu, $m->scomp("SELF:item_menu_disabled",  id => $menu, NAV => \%NAV);

  } elsif ($NAV{$menu}{url}) {
    push @htmlMenu, $m->scomp("SELF:item_menu_with_url",  id => $menu, NAV => \%NAV);
    next; # NO SUBMENU !!!

  } elsif (ref($NAV{$menu}{items}) ne 'ARRAY') {
    throw ePortal::Exception(-text => "Menu $menu doesn't have submenu items nor nave URL");

  } else {
    push @htmlMenu, $m->scomp("SELF:item_menu_with_submenu",  id => $menu, NAV => \%NAV);
  }

  # Discover all menu items of 2nd level
  my @htmlSubmenuItems;
  foreach my $submenu ( @{$NAV{$menu}{items}} ) {
    if (ref($NAV{$submenu}) ne 'HASH') {
      throw ePortal::Exception(-text => "SubMenu $submenu of menu $menu is not defined");
    }
    $NAV{$submenu}{disabled} = 1 if $NAV{$menu}{disabled};
    $NAV{$submenu}{url}   =~ s/#([^#]+)#/$NAV{$1}/eg;         # replace #id# in URL
    $NAV{$submenu}{title} =~ s/^(.{25,25})(.*)$/$1.../o;   # truncate long menu names
    $NAV{$submenu}{depend} ||= [];                         # disable when dependency isn't defined
    foreach ( @{$NAV{$submenu}{depend}} ) {
      $NAV{$submenu}{disabled} = 1 if ! $NAV{$_};
    }
    $NAV{$submenu}{disabled} = 1 if $NAV{$submenu . '_disabled'};

    push @htmlDescr, $m->scomp("SELF:item_descr", id => $submenu, NAV => \%NAV);
    if ( $NAV{$submenu}{disabled} ) {
      push @htmlSubmenuItems, $m->scomp("SELF:item_submenu_disabled", id => $submenu, NAV => \%NAV);
    } else {
      push @htmlSubmenuItems, $m->scomp("SELF:item_submenu", id => $submenu, NAV => \%NAV);
    }
  }
  push @htmlSubmenu, $m->scomp("SELF:item_submenu_bar", id => $menu, NAV => \%NAV,
        items => join($spacer2, @htmlSubmenuItems));
}


</%perl>

% if (not $gdata{navigator_JavaScript} ++) {
  <& SELF:JavaScript &>
% }

%#==========================================================================
<table width="100%" cellpadding="0" cellspacing="0" class="nav_title">

%#==========================================================================
%# Description bar
%#==========================================================================
<tr>
  <td width="10%">
    <span class="nav_descr">&nbsp;</span>
  </td>
  <td width="90%" class="nav_descr" nowrap>
    <% join "\n", @htmlDescr %>
  </td>
</tr>

%#==========================================================================
%# Menu bar
%#==========================================================================
<tr>
  <td nowrap width="10%">
    <span class="nav_title"><a href="<% $NAV{url} %>" class="nav_title"
          onMouseOver="JavaScript:nav_command('root')"><%
        $NAV{title} %></a>&nbsp;
    </span>
  </td>

  <td nowrap width="90%" class="nav_command">
    <% join $spacer2, @htmlMenu %>
  </td>
</tr>

%#==========================================================================
%# submenu bar
%#==========================================================================
<tr>
    <td>
      <span class="nav_command">&nbsp;</span>
    </td>
    <td>
      <% join "\n", @htmlSubmenu %>
    </td>
</tr>
</table>

%#=== @metags item_menu_with_submenu===========================================
<%method item_menu_with_submenu>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<span id="nid_<% $id %>_menu" class="nav_command"><a
      href="javascript:nav_command('<% $id %>',1);" onMouseOver="javascript:nav_command('<% $id %>',1)"><%
        $NAV->{$id}{title} %></a>
    </span>
</%method>

%#=== @metags item_menu_with_url===========================================
<%method item_menu_with_url>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<span id="nid_<% $id %>_menu" class="nav_command"><a class="nav_command"
      href="<% $NAV->{$id}{url} %>" onMouseOver="javascript:nav_command('<% $id %>',1)"><%
        $NAV->{$id}{title} %></a>
    </span>
</%method>



%#=== @metags item_submenu_bar ====================================================
<%method item_submenu_bar>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
% my $items = $ARGS{items};
<span id="nid_<% $id %>_submenu" class="nav_command" style="display:none;">
<% $items %>
</span>
</%method>

%#=== @METAGS item_submenu ====================================================
<%method item_submenu>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<a href="<% $NAV->{$id}{url} %>" class="nav_command" onMouseOver="javascript:nav_command('<% $id %>')"><%
    $NAV->{$id}{title} %></a>
</%method>


%#=== @METAGS item_submenu_disabled ====================================================
<%method item_submenu_disabled>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<a href="javascript:void(0);" class="nav_disabled" onMouseOver="javascript:nav_command('<% $id %>')"><%
    $NAV->{$id}{title} %></a>
</%method>


%#=== @METAGS item_descr ====================================================
<%method item_descr>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<span id="nid_<% $id %>_descr" class="nav_descr" style="display:none;"><%
   $NAV->{$id}{description} %></span>
</%method>

%#=== @metags item_menu_disabled ====================================================
<%method item_menu_disabled>
% my $NAV = $ARGS{NAV};
% my $id = $ARGS{id};
<span id="nid_<% $id %>_menu" class="nav_disabled"><a class="nav_disabled"
      href="javascript:nav_command('<% $id %>',1);" onMouseOver="javascript:nav_command('<% $id %>',1)"><%
        $NAV->{$id}{title} %></a>
    </span>
</%method>



%#=== @metags JavaScript ====================================================
<%method JavaScript>
<script language="JavaScript">
<!--
/*****************************************************************
  Helper function for navigator.mc
*****************************************************************/
var nav_last_cmd;   // last used command (submenu) id
var nav_last_menu;  // last used menu id
function nav_command( cmd, is_menu ) {
  // Hide last shown menu and submenu
  if ( nav_last_cmd != null ) {
    style_display('nid_' + nav_last_cmd + '_descr', 'none');
  }
  if ( nav_last_menu != null) {
    style_display('nid_' + nav_last_menu + '_descr', 'none');
    if ( is_menu == 1) {
      style_display('nid_' + nav_last_menu + '_submenu', 'none');
      style_display('nid_' + nav_last_menu + '_menu', null, 'normal');
    }
  }

  // Show description
  style_display('nid_' + cmd + '_descr', 'inline');

  // show menu and submenu
  if ( is_menu ==1 ) {
    style_display('nid_' + cmd + '_submenu', 'inline');
    style_display('nid_' + cmd + '_menu', null, 'bold');
    nav_last_menu = cmd;
  } else {
    nav_last_cmd = cmd;
  }

}  // nav_command
// -->
</script>
</%method>
<%doc>

=head1 NAME

navigator.mc - JavaScript menu navigator

=head1 SYNOPSIS

HTML::Mason component to implement JavaScript three-bar horizontal menu.

=head1 USAGE

 <& /naviagtor.mc, parameters hash, ... &>

 Produces the following:


             Description bar
 nav title:  <menu1>  menu2  menu3
             submenu1   submenu2  submenu3


=head1 Parameters hash

Each node of menu consists of hash of parameters.

 <& /navigator.mc, (navigator parameters),
      menu1 => { menu1 parameters},
      menu2 => { menu2 parameters},
      &>

=over 4

=item * title

The name of the menu or navigator itself.

=item * description

Description text to place on description bar

=item * url

URL for the menu or navigator. To add a parameter to URL use a string like 
#param# and add C<param> parameter to the hash.

 <& /navigator.mc, ..., url => '/index.htm?object=#param#', ..., param => 15 &>
 produces 
 /index.htm?object=15


=item * items

Array ref of menu or submenu names. This parameter is not valid for submenu 
item. 

 <& /navigator.mc, ..., items => ['menu1','menu2'],
       menu1 => { 
            title => '...',
            url => 'somefile.htm?p=#param#',
            description => 'menu description',
            depend => ['param'],
            items => ['submenu1', 'submenu2'],
         },
       param => $ARGS{param},
       menu2 => { parameters of menu2 },
       submenu1 => { parameters of submenu1 },
       submenu2 => { parameters of submenu2 },
       &>


=item * disabled

Disable this menu item if true. Menu item 'xxx' is disabled if parameter named
C<xxx_disabled> is true.

 <& /navigator.mc, ..., items => ['menu1','menu2'],
      menu2_disabled => 1 &>

=item * depend

Array ref of parameters names. Make this menu disabled if any of listed 
parameters is not true

 <& /navigator.mc, ..., items => ['menu1','menu2'],
      menu1 => { ..., depend => [param], ...},
      param => $ARGS{param},
  &>


=back

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

</%doc>
