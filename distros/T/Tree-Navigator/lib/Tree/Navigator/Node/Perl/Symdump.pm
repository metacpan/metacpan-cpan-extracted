package Tree::Navigator::Node::Perl::Symdump;
use utf8;
use Moose;
extends 'Tree::Navigator::Node';

use Devel::Symdump;
use namespace::autoclean;

has '+mount_point'
  => ( required => 0, default => sub { {} } );



sub _symdump {
  my $package = shift || '';
  $package =~ s[/][::]g;
  my @args = $package ? ($package) : ();
  return Devel::Symdump->new(@args);
}

sub children {
  my $self  = shift;
  (my $package = $self->path) =~ s[/][::]g;
  my $symdump = _symdump($self->path);
  my @sub_packages = $symdump->packages;

  s/^${package}::// foreach @sub_packages;
  return sort @sub_packages;
}


sub _child {
  my ($self, $child_path) = @_;
  my $class = ref $self;

  my $path = $self->_join_path($self->path, $child_path);
  die "no package '$child_path'" if !_symdump($path);

  return $class->new(mount_point => $self->mount_point, 
                     path        => $path);
}


sub response {
  my $self = shift;

  my $html = "<body><h1>" . $self->full_path . "</h1>\n";

  my $symdump = _symdump($self->path);
  $html .= $symdump->as_HTML . "</body>";
  return [200, ['Content-Type'   => 'text/html'], [$html]];
}



__PACKAGE__->meta->make_immutable;


1; # End of Tree::Navigator::Node::Perl::Symdump

__DATA__
<head>
  <link href="[% req.base %]/_gva/GvaScript.css" rel="stylesheet" type="text/css">
  <script src="[% req.base %]/_gva/prototype.js"></script>
  <script src="[% req.base %]/_gva/GvaScript.js"></script>
  <script>
    var treeNavigator;
    function setup() {
      treeNavigator 
        = new GvaScript.TreeNavigator('TN_tree', {tabIndex:-1});
    }
    document.observe('dom:loaded', setup);
  </script>
</head>
<body>
<h1>[% node.fullpath %]</h1>
  <div id='TN_tree' onPing='displayContent'>
    [% FOREACH item IN ['packages', 'scalars', 'arrays', 'hashes',
                        'functions', 'ios'];
         INCLUDE $item IF sym.$item;
       END; %]
  </div>
</body>

[% BLOCK packages; %]
  <div class="TN_node" id="packages">
    <h2 class="TN_label">Packages</h2>
    <div class="TN_content">
     [% FOREACH package IN sym.packages; %]
       <a href="[% package %]">[% package %]</a>
     [% END; # FOREACH package IN sym.packages; %]
    </div>
  </div>
[% END; # BLOCK packages %]

[% BLOCK scalars %]
  <div class="TN_node" id="scalars">
    <h2 class="TN_label">Scalars</h2>
    <div class="TN_content">
     [% FOREACH scalar IN sym.scalars; %]
       [% scalar %]
     [% END; # FOREACH scalar IN sym.scalars; %]
    </div>
  </div>
[% END; # BLOCK scalara %]

[% BLOCK arrays %]
[% END; # BLOCK arrays %]

[% BLOCK hashes %]
[% END; # BLOCK hashes %]

[% BLOCK functions %]
[% END; # BLOCK functions %]

[% BLOCK ios %]
[% END; # BLOCK ios %]

__END__

=encoding utf8

=head1 NAME

Tree::Navigator::Node::Perl::Symdump - navigating in a perl symbol table



