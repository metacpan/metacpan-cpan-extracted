package Tree::Navigator;
use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'Plack::Component';


# TODO : check Path::Resolver


use Alien::GvaScript;
use Plack::MIME;
use Plack::Request;
use Plack::Util;
use Scalar::Util qw/weaken/;
use Tree::Navigator::Node;

our $VERSION = '0.06';

has root  => (
  is      => 'ro',
  isa     => 'Tree::Navigator::Node',
  handles => [qw/mount children child descendent/],
);

has can_be_killed => (
  is      => 'ro',
);

sub BUILD {
  my $self = shift;
  my $mount_point = {navigator => $self};
  weaken $mount_point->{navigator};

  $self->{root} ||= Tree::Navigator::Node->new(
    mount_point => $mount_point,
    path        => '',
   );

  my $gvascript_dir = Alien::GvaScript->path
    or die "Alien::GvaScript is not installed";
  $self->mount('_gva', 
               Filesys => {mount_point => {root => $gvascript_dir}},
               {hidden => 1});
               # TODO: options to specify an 'Expires' header
}


sub call { # request dispatcher (see L<Plack::Component>)
  my ($self, $env) = @_;

  my $req  = Plack::Request->new($env);
  my $path = $req->path;
  $path =~ s[^/][];

  # URLs for the global frameset and for the Table Of Contents
  !$path               and return $self->frameset($req);
  $path =~ s[^_toc/][] and return $self->toc($path, $req);

  # URL to stop this server (needed by L<Tree::Navigator::App::PerlDebug>)
  $path =~ /^_KILL/ and $self->can_be_killed 
    and $env->{'psgix.harakiri.commit'} = 1 # see L<HTTP::Server::PSGI> v1.004
    and return [200, ['Content-type' => 'text/html'],
                     ["server killed upon user request"]];

  # otherwise, other URLs
  my $node = $self->descendent($path) or die "no such node : $path";
  return $node->response($req);
}



sub frameset {
  my ($self, $req) = @_;

  # initial page to open
  my $ini     = $req->param('open') || $self->{initial_page} || '';
  my $ini_toc = $ini ? "_toc/?open=$ini" : "_toc/";

  # HTML title
  my $title = escape_html($self->{title} || 'Tree Navigator');

  my $body = <<__EOHTML__;
<html>
  <head><title>$title</title></head>
  <frameset cols="25%, 75%">
    <frame name="tocFrame"     src="$ini_toc">
    <frame name="contentFrame" src="$ini">
  </frameset>
</html>
__EOHTML__

  return [200, ['Content-type' => 'text/html'], [$body]];
}


sub toc {
  my ($self, $path, $req) = @_;

  return $path ? $self->sub_toc($path, $req)
               : $self->main_toc($req);
}

sub main_toc {
  my ($self, $req) = @_;

  my $base       = $req->script_name;
  my $root_nodes = $self->mk_root_nodes;
  my $resp       = $req->new_response(200, [ 'Content-Type' => 'text/html' ]);

  my $kill_serv = ! $self->can_be_killed ? "" 
    : q{<a href="/_KILL" style="float:right;color:red">Stop debugging</a>};

  $resp->body(<<__EOHTML__);
<html>
<head>
  <base target="contentFrame">
  <link href="$base/_gva/GvaScript.css" rel="stylesheet" type="text/css">
  <script src="$base/_gva/prototype.js"></script>
  <script src="$base/_gva/GvaScript.js"></script>
  <script>
    var treeNavigator;

    function open_nodes(first_node, rest) {

      var node = \$(first_node);
      if (!node || !treeNavigator) return;

      // shift to next node in sequence
      first_node = rest.shift();

      // build a handler for "onAfterLoadContent" (closure on first_node/rest)
      var open_or_select_next = function() { 

        // delete handler that might have been placed by previous call
        delete treeNavigator.onAfterLoadContent;

        // 
        if (rest.length > 0) {
          open_nodes(first_node, rest) 
        }
        else {
          treeNavigator.openEnclosingNodes(\$(first_node));
          treeNavigator.select(\$(first_node));
        }
      };


      // if node is closed and currently has no content, we need to register
      // a handler, open the node so that it gets its content by Ajax,
      // and then execute the handler to open the rest after Ajax returns
      if (treeNavigator.isClosed(node)
          && !treeNavigator.content(node)) {
        treeNavigator.onAfterLoadContent = open_or_select_next;
        treeNavigator.open(node);
      }
      // otherwise just a direct call 
      else {
        open_or_select_next();
      }

    }

    function setup() {
      treeNavigator 
        = new GvaScript.TreeNavigator('TN_tree', {tabIndex:-1});
    }

    document.observe('dom:loaded', setup);

    function displayContent(event) {
        var label = event.controller.label(event.target);
        if (label && label.tagName == "A") {
          label.focus();
          return Event. stopNone;
        }
    }
  </script>
  <style>
   BODY         {margin:0px; font-size: 70%; overflow-x: hidden} 
   DIV          {margin:0px; width: 100%}
   .mount_point {color: midnightblue; font-weight: bold;}
  </style>
</head>

<body>
  $kill_serv
  <div id='TN_tree' onPing='displayContent'>
    $root_nodes
  </div>
</body>
</html>
__EOHTML__

  return $resp->finalize;
}

sub sub_toc {
  my ($self, $path, $req) = @_;

  my $node    = $self->descendent($path) or die "no such node : $path";
  my $resp    = $req->new_response(200);
  $resp->body($self->_TOC_entry($node));
  return $resp->finalize;
}



my $TOC_tmpl = q{
[% SET full_path = node.full_path;
   SET subnodes_and_leaves = node.subnodes_and_leaves;
   FOREACH subnode IN subnodes_and_leaves.0;
     SET path = "$full_path/$subnode" | url; %]
      <div class='TN_node TN_closed' TN:contentURL='[% path %]'>
        <a href='../[% path %]' class='TN_label'>[% subnode %]</a>
      </div>
[% END; # FOREACH subnode ~%]

[% FOREACH leaf IN subnodes_and_leaves.1;
     SET path = "$full_path/$leaf" | url; %]
      <div class='TN_leaf'>
        <a href='../[% path %]' class='TN_label'>[% leaf %]</a>
      </div>
[% END; # FOREACH leaf %]
};

sub _TOC_entry {
  my ($self, $node) = @_;

  my $view     = $self->view(TT2 => \$TOC_tmpl);
  my $request  = undef;
  my $response = $view->render($node, $request);
  my $toc_html = $response->[2][0];
  return $toc_html;
}



my $default_tmpl = q{
<head>
  <style>
    BODY, TD {
      font-family: Verdana, Arial, Helvetica;
      font-size: 85%;
    }
    H1, H2, H3, H4, H5, H6 {
      display:inline;
      margin: 0;
    }
    .attrs TH     { text-align: right; padding-right: 1ex}
    .attrs TH, TD { font-size: 80%; }
    .highlight    { background: lightgreen }
  </style>
  [% SET base = request.script_name %]
  <link href="[% base %]/_gva/GvaScript.css" rel="stylesheet" type="text/css">
  <script src="[% base %]/_gva/prototype.js"></script>
  <script src="[% base %]/_gva/GvaScript.js"></script>
  <script>
    var treeNavigator;
    function setup() {
      treeNavigator 
        = new GvaScript.TreeNavigator('TN_tree', {tabIndex:-1});
    }
    document.observe('dom:loaded', setup);


    function follow_link(event) {
        var label = event.controller.label(event.target);
        if (label && label.tagName == "A") {
          label.focus();
          return Event. stopNone;
        }
    }

  </script>
</head>
<body>
  <div id='TN_tree' onPing='follow_link'>
    <div class='TN_node'>
      <h1 class="TN_label">[% node.full_path %]</h1>
      <div class="TN_content">

        [% IF data.attributes.size %]
          <div class="TN_node">
            <h2 class="TN_label">Attributes</h2>
            <div class="TN_content">
              <em>[% INCLUDE attrs attrs=data.attributes %]</em>
            </div>
          </div>
        [% END; # IF data.attributes.size %]

        [% IF data.children.size %]
          <div class="TN_node">
            <h2 class="TN_label">Children</h2>
            <div class="TN_content">
              [% INCLUDE child FOREACH child IN data.children %]
            </div>
          </div>
        [% END; # IF data.children.size %]

        [% IF data.content_text %]
          <div class="TN_node">
            <h2 class="TN_label">Content</h2>
            <div class="TN_content">
              <pre>
                [%- data.content_text -%]
              </pre>
            </div>
          </div>
        [% END; # IF data.content %]

      </div>
    </div>
  </div>
</body>

[%~ BLOCK child; %]
  <div class="[% child.attributes.size ? 'TN_node TN_closed' : 'TN_leaf' %]">
    <a class="TN_label"
       href="[% node.last_path _ '/' _ child.name | url %]">
         [%~ child.name ~%]
    </a>
    [% IF child.attributes.size %]
       <div class="TN_content">
         [% INCLUDE attrs attrs=child.attributes %]
       </div>
    [% END; # IF child.attributes.size %]
  </div>
[%~ END; # BLOCK child; %]

[%~ BLOCK attrs;
    IF attrs.size; %]
      <table class="attrs">
        [% FOREACH attr IN attrs; %]
           <tr><th>[% attr.key %]</th><td>[% attr.value %]</td></tr>
        [% END; # FOREACH attr IN attrs; %]
      </table>
[%  END; # IF
   END; # BLOCK ~%]
};








sub mk_root_nodes {
  my ($self) = @_;

  my $html = "";

  foreach my $path ($self->children) {
    my $node  = $self->child($path) or die "absent root: '$path'";
    my $title = escape_html($node->attributes->{title} || '');
    $title    = " title='$title'" if $title;

    my $node_content = $self->_TOC_entry($node);
    my $node_html = "<a href='../$path' class='TN_label mount_point'$title>$path</a>";
    $node_html   .= "<div class='TN_content'>$node_content</div>" if $node_content;
    $html .= "<div class='TN_node'>$node_html</div>";
  }

  $html or die "no mounted nodes";

  return $html;
}



#======================================================================
# UTILITIES
#======================================================================

my %escape_entity = ('&' => 'amp',
                     '<' => 'lt',
                     '>' => 'gt',
                     '"' => 'quot');

my $entity_regex = "([" . join("", keys %escape_entity) . "])";
sub escape_html {
  my $html = shift;
  $html =~ s/$entity_regex/&$escape_entity{$1};/g;
  return $html;
}

#======================================================================
# WORK IN PROGRESS
#======================================================================

sub view {
  my $self = shift;
  my ($view_class, @args) = @_ ? @_ : (TT2 => \$default_tmpl);

  my $class = Plack::Util::load_class($view_class, "Tree::Navigator::View");
  return $class->new(@args);
}


__PACKAGE__->meta->make_immutable;



1; # End of Tree::Navigator

__END__

=head1 NAME

Tree::Navigator - Generic navigation in various kinds of trees

=head1 SYNOPSIS

Create a file F<treenav.psgi> like this :

  # create a navigator, then mount various kinds of nodes as shown below
  use Tree::Navigator;
  my $tn = Tree::Navigator->new;

  # example 1 : browse through the filesystem
  $tn->mount(Files => Filesys 
                   => {attributes => {label => 'My Web Files'},
                       mount_point => {root  => '/path/to/files'}});

  # example 2 : inspect tables and columns in a database
  my $dbh = DBI->connect(...);
  $tn->mount(MyDB => 'DBI' => {mount_point => {dbh => $dbh}});

  # example 3 : browse through the Win32 registry
  $tn->mount(HKCU => 'Win32::Registry' => {mount_point => {key => 'HKCU'}});

  # example 4 : browse through Perl internals
  $tn->mount(Ref => 'Perl::Ref' => {mount_point => {ref => $some_ref}});
  $tn->mount(Stack => 'Perl::StackTrace' => {mount_point => {}});
  $tn->mount(Symdump => 'Perl::Symdump' => {});

  # create the application
  my $app = $tn->to_app;

Then run the app

  plackup treenav.psgi

or mount the app in Apache

  <Location /treenav>
    SetHandler perl-script
    PerlResponseHandler Plack::Handler::Apache2
    PerlSetVar psgi_app /path/to/treenav.psgi
  </Location>

and use your favorite web browser to navigate through your data.


=head1 DESCRIPTION

=head2 Disclaimer

This distribution is still in an early stage, with incomplete
documentation and tests, and an unstabilized API. Use for experiments,
not yet for production code.


=head2 Introduction

This is a set of tools for navigating within various kinds of
I<trees>; a tree is just a set of I<nodes>, where each node may have a
I<content>, may have I<attributes>, and may have I<children>
nodes. Examples of such structures are filesystems, FTP sites, email
boxes, Web sites, HTML pages, XML documents, etc.

The distribution provides

=over

=item *

an L<abstract class for nodes|Tree::Navigator::Node>, with a few
concrete classes for some of the examples just mentioned above

=item *

a server application for exposing the tree structure to
web clients or command-line clients (the present module).

=item *

a shell client [TODO]

=item *

an L<application|Tree::Navigator::App::PerlDebug>
that uses the Tree Navigator to navigate into the
memory of a running Perl program.

=back

=head2 Definitions

  - node
  - subnode
  - leaf
  - attribute
  - content


=head1 METHODS

TODO


=head1 DEPENDENCIES

This application uses L<Plack> and L<Moose>.


=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-navigator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Navigator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SEE ALSO

L<Tree::Simple>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Navigator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Navigator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Navigator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Navigator>

=item * Search CPAN

L<https://metacpan.org/dist/Tree-Navigator/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 TODO

- check proper handling of SCRIPT_NAME
- display node, show attrs & use IFRAME for content
- option to toogle leaves in treeNav
- export dir data as JSON/yaml
- menu of actions on nodes

- Node types: 
    - HTML viewer, build tree from H1, h2, etc. nodes; href links are leaves
    - Obj in memory
    - Process tree
    - LDAP
    - POM
    - Catalyst Actions
    - WWW mechanize
    - XML Schema
    - Smb Client, FTP, FTPS, SVN, GIT

- Shell : use Plack::Client

- Operation:
    - ls
    - cat
    - grep / ack
    - search / find (from attributes)

- fix utf8 bug in content


- apps
   - doc avec MsWordHTML
   - doc avec Latex


API
  app/_frameset              => basic layout (frameset)
  app/_tn/             => tree TOC
  app/_tn/path/to/node => subtree TOC

  app/path/to/node?children
  app/path/to/node?subnodes
  app/path/to/node?content&view=html
    accept: text/html
  app/path/to/node?content&view=
     accept: binary
  app/path/to/node?html

     => right panel
  app/path/to/node?source (PPW, )



Cli
===
  cd
  ls
  cat
  pwd
  find
  grep/ack
  



