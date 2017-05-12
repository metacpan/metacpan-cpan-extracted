# vim:set ft=perl ts=4 sw=4 et fdm=marker:

package UML::Class::Simple;

use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '0.22';

#use Smart::Comments;
use Carp qw(carp confess);
use Class::Inspector;
use Devel::Peek ();
use File::Spec;
use IPC::Run3;
use List::MoreUtils 'any';
use Template;
use XML::LibXML ();

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    classes_from_runtime classes_from_files
    exclude_by_paths grep_by_paths
);

my $tt = Template->new;
my $dot_template;

sub classes_from_runtime {
    my ($modules, $pattern) = @_;
    $modules = [$modules] if $modules and !ref $modules;
    $pattern = '' if !defined $pattern;
    for (@$modules) {
        eval "use $_;";
        if ($@) { carp $@; return (); }
    }
    grep { /$pattern/ } _runtime_packages();
}

sub _normalize_path ($) {
    my $path = shift;
    $path = File::Spec->rel2abs($path);
    if (File::Spec->case_tolerant()) {
        $path = lc($path);
    } else {
        $path;
    }
}

sub exclude_by_paths ($@) {
    my $rclasses = shift;
    my @paths = map { _normalize_path($_) } @_;
    my @res;
    #_extend_INC();
    for my $class (@$rclasses) {
        #warn $class;
        my $filename = Class::Inspector->resolved_filename($class);
        #warn "[0] ", $filename, "\n";
        if (!$filename && $INC{$class}) {
            $filename = Class::Inspector->loaded_filename($class);
        }
        if (!$filename) { next; }
        #warn "[1] ", $filename, "\n";
        $filename = _normalize_path($filename);
        #warn "[2] ", $filename, "\n";
        #my $value = $INC{$key};
        if (any { substr($filename, 0, length) eq $_ } @paths) {
            #warn "!!! ignoring $filename\n";
            next;
        }
        #warn "adding $filename <=> @paths\n";
        push @res, $class;
    }
    @res;
}

sub grep_by_paths ($@) {
    my $rclasses = shift;
    my @paths = map { _normalize_path($_) } @_;
    my @res;
    #_extend_INC();
    for my $class (@$rclasses) {
        my $filename = Class::Inspector->resolved_filename($class);
        if (!$filename && $INC{$class}) {
            $filename = Class::Inspector->loaded_filename($class);
        }
        if (!$filename) { next; }
        $filename = _normalize_path($filename);
        #my $value = $INC{$key};
        if (any { substr($filename, 0, length) eq $_ } @paths) {
            #warn "adding $filename <=> @paths\n";
            push @res, $class;
            next;
        }
        #warn "!!! ignoring $filename\n";
    }
    @res;
}

sub _runtime_packages {
    no strict 'refs';
    my $pkg_name = shift || '::';
    my $cache = shift || {};
    return if $cache->{$pkg_name};
    $cache->{$pkg_name} = 1;
    for my $entry (keys %$pkg_name) {
        next if $entry !~ /\:\:$/ or $entry eq 'main::';
        my $subpkg_name = $pkg_name.$entry;
        #warn $subpkg_name;
        _runtime_packages($subpkg_name, $cache);
        $cache->{$subpkg_name} = 1;
    }
    map { s/^::|::$//g; $_ } keys %$cache;
}

sub classes_from_files {
    require PPI;
    my ($list, $pattern, $read_only) = @_;
    $list = [$list] if $list and !ref $list;
    $pattern = '' if !defined $pattern;
    my @classes;
    my $cache = {};
    for my $file (@$list) {
        _gen_paths($file, $cache);
        my $doc = PPI::Document->new( $file );
        if (!$doc) {
            carp "warning: Can't parse $file: ", PPI::Document->errstr;
            next;
        }
        my $res = $doc->find('PPI::Statement::Package');
        next if !$res;
        push @classes, map { $_->namespace } @$res;
        _load_file($file) if !$read_only;
    }
    @classes = grep { /$pattern/ } @classes;
    #@classes = sort @classes;
    wantarray ? @classes : \@classes;
}

sub _gen_paths {
    my ($file, $cache) = @_;
    $file =~ s{\\+}{/}g;
    my $dir;
    while ($file =~ m{(?x) \G .+? /+ }gc) {
        $dir .= $&;
        next if $cache->{$dir};
        $cache->{$dir} = 1;
        #warn "pushing ~~~ $dir\n";
        unshift @INC, $dir;
    }
}

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $rclasses = shift || [];
    my $self = bless {
        class_names => $rclasses,
        node_color  => '#f1e1f4',
        display_inheritance => 1,
        display_methods => 1,
    }, $class;
    $self->{inherited_methods} = 1;
    my $options = shift;
    if (ref($options) eq 'HASH') {
        $self->{inherited_methods} = $options->{inherited_methods};
        if (defined $options->{xmi_model}) {
            $self->_xmi_load_model($options->{xmi_model});
        }
    }
    #$self->_build_dom;
    $self;
}

sub size {
    my $self = shift;
    if (@_) {
        my ($width, $height) = @_;
        if (!$width || !$height || ($width . $height) !~ /^[\.\d]+$/) {
            carp "invalid width and height";
            return undef;
        } else {
            $self->{width}  = $width;
            $self->{height} = $height;
            return 1;
        }
    } else {
        return ($self->{width}, $self->{height});
    }
}

sub node_color {
    my $self = shift;
    if (@_) {
        $self->{node_color} = shift;
    } else {
        $self->{node_color};
    }
}

sub dot_prog {
    my $self = shift;
    if (@_) {
        my $cmd = shift;
        can_run($cmd) or die "ERROR: The dot program ($cmd) cannot be found or be run.\n";
        $self->{dot_prog} = $cmd;
    } else {
        $self->{dot_prog} || 'dot';
    }
}

# copied from IPC::Cmd. Copyright by IPC::Cmd's author.
sub can_run {
    my $command = shift;

    # a lot of VMS executables have a symbol defined
    # check those first
    if ( $^O eq 'VMS' ) {
        require VMS::DCLsym;
        my $syms = VMS::DCLsym->new;
        return $command if scalar $syms->getsym( uc $command );
    }

    require Config;
    require File::Spec;
    require ExtUtils::MakeMaker;

    if( File::Spec->file_name_is_absolute($command) ) {
        return MM->maybe_command($command);

    } else {
        for my $dir (
            (split /\Q$Config::Config{path_sep}\E/, $ENV{PATH}),
            File::Spec->curdir
        ) {
            my $abs = File::Spec->catfile($dir, $command);
            return $abs if $abs = MM->maybe_command($abs);
        }
    }
}

sub _property {
    my $self = shift;
    my $property_name = shift;
    if (@_) {
        $self->{$property_name} = shift;
        $self->_build_dom(1);
    } else {
        $self->{$property_name};

    }
}

sub public_only {
    my $self = shift;
    $self->_property('public_only', @_);
}

sub inherited_methods {
    my $self = shift;
    $self->_property('inherited_methods', @_);
}

sub as_png {
    my $self = shift;
    $self->_as_image('png', @_);
}

sub as_gif {
    my $self = shift;
    $self->_as_image('gif', @_);
}

sub as_svg {
    my $self = shift;
    $self->_as_image('svg', @_);
}

sub _as_image {
    my ($self, $type, $fname) = @_;
    my $dot = $self->as_dot;
    #if ($fname eq 'fast00.png') {
        #warn "==== $fname\n";
        #warn $dot;
        #use YAML::Syck;
        #$self->_build_dom(1);
        #warn Dump($self->as_dom);
    #}
    my @cmd = ($self->dot_prog(), '-T', $type);
    #my @cmd = ('dot', '-T', $type);
    if ($fname) {
        push @cmd, '-o', $fname;
    }
    my ($img_data, $stderr);
    my $success = run3 \@cmd, \$dot, \$img_data, \$stderr;
    if ($stderr) {
        if ($? == 0) {
            carp $stderr;
        } else {
            Carp::croak $stderr;
        }
    }
    if (!$fname) {
        return $img_data;
    }
}

sub as_dom {
    my $self = shift;
    $self->_build_dom;
    { classes => $self->{classes} };
}

sub set_dom ($$) {
    my $self = shift;
    $self->{classes} = shift->{classes};
    1;
}

sub moose_roles ($) {
    my $self = shift;
    $self->{'moose_roles'} = shift;
}

sub display_methods ($) {
    my $self = shift;
    $self->{'display_methods'} = shift;
}

sub display_inheritance ($) {
    my $self = shift;
    $self->{'display_inheritance'} = shift;
}

sub _build_dom {
    my ($self, $force) = @_;
    # avoid unnecessary evaluation:
    return if $self->{classes} && !$force || !$self->{class_names};
    #warn "HERE";
    my @pkg = @{ $self->{class_names} };
    my @classes;
    $self->{classes} = \@classes;
    my $public_only = $self->{public_only};
    my %visited; # used to eliminate potential repetitions
    for my $pkg (@pkg) {
        #warn $pkg;
        $pkg =~ s/::::/::/g;
        if ($visited{$pkg}) { next; }
        $visited{$pkg} = 1;

        if (!Class::Inspector->loaded($pkg)) {
            #my $pmfile = Class::Inspector->filename($pkg);
            #warn $pmfile;
            #if ($pmfile) {
            #    if (! _load_file($pmfile)) {
            #        next;
            #    }
            #} else { next }
            next;
        }
        push @classes, {
            name => $pkg, methods => [],
            properties => [], subclasses => [],
        };
        my $from_class_accessor =
            $pkg->isa('Class::Accessor') ||
            $pkg->isa('Class::Accessor::Fast') ||
            $pkg->isa('Class::Accessor::Grouped');
        #accessor_name_for

        # If you want to gather only the functions defined in
        #  the current class only (w/o those inherited from ancestors),
        #  set inherited_methods property to false (default value is true).
        my $methods = Class::Inspector->methods($pkg, 'expanded');
        if ($methods and ref($methods) eq 'ARRAY') {
            if ($from_class_accessor) {
                my $i = 0;
                my %functions = map { $_->[2] => $i++ } @$methods; # create hash from array
                ### %functions
                #my @accessors = map { /^_(.*)_accessor$/; $1 } keys %functions;
                ### @accessors
                my $use_best_practice = delete $functions{'accessor_name_for'} && delete $functions{'mutator_name_for'};
                my %accessors;
                foreach my $meth (keys %functions) {
                    next unless $meth;
                    if ($meth =~ /^_(.*)_accessor$/) {
                        my $accessor = $1;
                        if (exists $functions{$accessor}) {
                            if ($self->{inherited_methods} or
                                $methods->[$functions{$accessor}]->[1] eq $pkg) {
                                push @{ $classes[-1]->{properties} }, $accessor;
                            }
                            delete $functions{$accessor};
                            delete $functions{"_${accessor}_accessor"};
                            #push @{ $classes[-1]->{properties} }, $accessor;
                        }
                        next;
                    }
                    if ($use_best_practice) {
                        if ($meth =~ /^(?:get|set)_(.+)/) {
                            my $accessor = $1;
                            delete $functions{$meth};
                            if (!$accessors{$accessor}) {
                                #push @{ $classes[-1]->{properties} }, $accessor;
                                if ($self->{inherited_methods} or
                                    $methods->[$functions{$accessor}]->[1] eq $pkg) {
                                     push @{ $classes[-1]->{properties} }, $accessor;
                                }
                                $accessors{$accessor} = 1;
                            }
                        }
                    }
                }
                @$methods = grep { exists $functions{$_->[2]} } @$methods;
            }
            @{ $classes[-1]->{properties} } = sort @{ $classes[-1]->{properties} };

            foreach my $method (@$methods) {
                next if $method->[1] ne $pkg;
                if (! $self->{inherited_methods}) {
                    my $source_name =  Devel::Peek::CvGV($method->[3]);
                    $source_name =~ s/^\*//;
                    next if $method->[0] ne $source_name;
                }
                $method = $method->[2];
                next if $public_only && $method =~ /^_/o;
                push @{$classes[-1]->{methods}}, $method;
            }
        }



        my $subclasses = Class::Inspector->subclasses($pkg);
        if ($subclasses) {
            no strict 'refs';
            my @child = grep {
                #warn "!!!! ", join ' ', @{"${_}::ISA"};
                any { $_ eq $pkg } @{"${_}::ISA"};
            } @$subclasses;

            if (@child) {
                $classes[-1]->{subclasses} = \@child;
            }
        }

        if (Class::Inspector->function_exists($pkg, 'meta')) {
            # at least Class::MOP
            my $meta = $pkg->meta();
            if ($meta->can('consumers')) {
                # Something like Moose::Meta::Role
                my @consumers = $meta->consumers();
                if (@consumers) {
                    $classes[-1]->{'consumers'} =  [ @consumers ];
                }
            }
        }
    }
    #warn "@classes";
}

sub _load_file ($) {
    my $file = shift;
    my $path = _normalize_path($file);
    #warn "!!! >>>> $path\n";
    if ( any {
                #warn "<<<<< ", _normalize_path($_), "\n";
                $path eq _normalize_path($_);
             } values %INC ) {
        #carp "!!! Caught duplicate module files: $file ($path)";
        return 1;
    }
    #my @a = values %INC;
    #warn "\n@a\n";
    #warn "!!! Loading $path...\n";
    eval {
        require $path;
    };
    carp $@ if $@;
    !$@;
}

sub _xmi_get_new_id {
    my $self = shift;
    return 'xmi.' . $self->{_xmi}->{_id_counter}++;
}

sub _xmi_create_inheritance {
    my ($self, $class, $subclass_name) = @_;
    my $child_id = $self->{_xmi}->{_name2id}->{$subclass_name};
    my $id = $self->_xmi_get_new_id();

    my $element = XML::LibXML::Element->new('UML:Generalization');
    $self->{_xmi}->{_classes_root}->appendChild($element);
    $self->_xmi_set_default_attribute($element, 'isSpecification', 'false');
    $element->setAttribute('xmi.id', $id);

    my $child = XML::LibXML::Element->new('UML:Generalization.child');
    $element->appendChild($child);
    my $child_xml_class = XML::LibXML::Element->new('UML:Class');
    $child->appendChild($child_xml_class);
    $child_xml_class->setAttribute('xmi.idref', $child_id);

    my $parent = XML::LibXML::Element->new('UML:Generalization.parent');
    $element->appendChild($parent);
    $child_xml_class = XML::LibXML::Element->new('UML:Class');
    $parent->appendChild($child_xml_class);
    $child_xml_class->setAttribute('xmi.idref', $class->{xmi_id});

    my $xml_class = $self->{_xmi}->{_classes_hash}->{$subclass_name};
    return unless defined $xml_class;
    my $generalization = XML::LibXML::Element->new('UML:Generalization');
    $generalization->setAttribute('xmi.idref', $id);
    my $generalizableElement = XML::LibXML::Element->new('UML:GeneralizableElement.generalization');
    $generalizableElement->appendChild($generalization);
    $xml_class->appendChild($generalizableElement);
}

sub _xmi_write_method {
    my ($self, $parent_node, $class, $method) = @_;

    my $id = $self->_xmi_get_new_id();
    my $visibility = 'public';
    $visibility = 'private' if substr($method, 0, 1) eq '_';
    my $ownerScope = 'instance';
    $ownerScope = 'classifier' if $method =~ /^[A-Z]/o;

    my $xml_method = $self->_xmi_add_element($parent_node, 'UML:Operation', $method);

    $xml_method->setAttribute('xmi.id', $id);
    $xml_method->setAttribute('visibility', $visibility);
    $xml_method->setAttribute('ownerScope', $ownerScope);
    $self->_xmi_set_default_attribute($xml_method, 'concurrency', 'sequential');
    $self->_xmi_set_default_attribute($xml_method, $_, 'false') foreach qw(isSpecification isQuery isRoot isLeaf isAbstract);
}

sub _xmi_write_class {
    my ($self, $class) = @_;

    my $xml_class = $self->_xmi_add_element($self->{_xmi}->{_classes_root}, 'UML:Class', $class->{name});
    $self->{_xmi}->{_classes_hash}->{$class->{name}} = $xml_class;
    $xml_class->setAttribute('xmi.id', $class->{xmi_id});
    $xml_class->setAttribute('visibility', 'public');
    $self->_xmi_set_default_attribute($xml_class, $_, 'false') foreach qw(isSpecification isRoot isLeaf isAbstract isActive);

    my $uml_classifier =  XML::LibXML::Element->new('UML:Classifier.feature');
    $xml_class->appendChild($uml_classifier);

    $self->_xmi_write_method($uml_classifier, $class, $_) foreach @{$class->{methods}};
    $self->_xmi_create_inheritance($class, $_) foreach @{$class->{subclasses}};
}

sub _xmi_set_id {
    my ($self, $class) = @_;
    $class->{xmi_id} = $self->_xmi_get_new_id();
    $self->{_xmi}->{_name2id}->{$class->{name}} = $class->{xmi_id};
}

sub _xmi_add_element {
    my ($self, $parent, $class, $name) = @_;
    my $node;
    if (defined $name) {
        foreach $node ($parent->getElementsByTagName($class)) {
            if ($node->getAttribute('name') eq $name) {
                return $node;
            }
        }
    }
    $node = $self->{_xmi}->{_document}->createElement($class);
    $node->setAttribute('name', $name);
    $parent->appendChild($node);
    return $node;
}

sub _xmi_set_default_attribute {
    my ($self, $node, $name, $value) = @_;
    return if defined $node->getAttribute($name);
    $node->setAttribute($name, $value);
}

sub _xmi_load_model {
    my ($self, $fname) = @_;
    $self->{_xmi}->{_document} = XML::LibXML->new()->parse_file($fname);
}

sub _xmi_init_xml {
    my ($self, $fname) = @_;
    unless (defined $self->{_xmi}->{_document}) {
        $self->{_xmi}->{_document} = XML::LibXML::Document->new('1.0', 'UTF-8');
    }
    my $doc = $self->{_xmi}->{_document};

    my $xmi_root = $doc->createElement('XMI');
    $xmi_root->setAttribute('xmi.version', '1.2');
    $xmi_root->setAttribute('xmlns:UML', 'org.omg.xmi.namespace.UML');
    my $generate_time = POSIX::asctime(localtime(time()));
    chomp($generate_time);
    $xmi_root->setAttribute('timestamp', $generate_time);
    $doc->setDocumentElement($xmi_root);

    my $xmi_content = $doc->createElement('XMI.content');
    $xmi_root->appendChild($xmi_content);

    my $uml_model = $self->_xmi_add_element($xmi_content, 'UML:Model', $fname || '');
    $uml_model->setAttribute('xmi.id', $self->_xmi_get_new_id());
    $self->_xmi_set_default_attribute($uml_model, $_, 'false') foreach qw(isSpecification isRoot isLeaf isAbstract);

    $self->{_xmi}->{_classes_root} = $doc->createElement('UML:Namespace.ownedElement');
    $uml_model->appendChild($self->{_xmi}->{_classes_root});

    return $doc;
}

sub as_xmi {
    my ($self, $fname) = @_;
    $self->_build_dom;
    $self->{_xmi} ||= {};
    $self->{_xmi}->{_id_counter} = 1;
    $self->{_xmi}->{_name2id} = {};
    $self->_xmi_set_id($_) foreach @{$self->{classes}};
    my $doc = $self->_xmi_init_xml($fname);
    $self->_xmi_write_class($_) foreach @{$self->{classes}};
    if ($fname) {
        $doc->toFile($fname, 2);
    } else {
        return $doc;
    }
}

sub as_dot {
    my ($self, $fname) = @_;
    $self->_build_dom;
    if ($fname) {
        $tt->process(\$dot_template, $self, $fname)
            || carp $tt->error();
    } else {
        my $dot;
        $tt->process(\$dot_template, $self, \$dot)
            || carp $tt->error();
        $dot;
    }
}

sub set_dot ($$) {
    my $self = shift;
    $self->{dot} = shift;
}

$dot_template = <<'_EOC_';
digraph uml_class_diagram {
  [%- IF width && height %]
    size="[% width %],[% height %]";
  [%- END %]
    node [shape=record, style="filled"];
    edge [color=red, dir=none];

[%- name2id = {} %]
[%- id = 1 %]
[%- FOREACH class = classes %]
    [%- name = class.name %]
    [%- name2id.$name = id %]
    class_[% id %] [shape=plaintext, style="", label=<
<table BORDER="0" CELLBORDER="1" CELLSPACING="0" CELLPADDING="4">
  <tr><td port="title" bgcolor="[% node_color %]">[% name %]</td></tr>
  <tr>
    <td>
    <table border="0" cellborder="0" cellspacing="0" cellpadding="1">
      <tr>
    <td>[% IF class.properties.size > 0 %]<font color="red">
    [%- FOREACH property = class.properties %]
      [%- property.match("^_") ? "-" : "+" %]<br align="left"/>

    [%- END %]</font>[% END %]</td>
    <td port="properties" bgcolor="white" align="left">
    [%- FOREACH property = class.properties %]
      [%- property %]<br align="left"/>

    [%- END %]</td>
      </tr>
    </table>
    </td>
  </tr>
  <tr>
    <td port="methods" >
    [%- IF display_methods %]
    <table border="0" cellborder="0" cellspacing="0" cellpadding="0">
      <tr>
    <td>[% IF class.methods.size > 0 %]<font color="red">
    [%- FOREACH method = class.methods %]
      [%- method.match("^_") ? "-" : "+" %]<br align="left"/>

    [%- END %]</font>[% END %]</td>
    <td bgcolor="white" align="left">
    [%- FOREACH method = class.methods %]
      [%- method %]<br align="left"/>

    [%- END %]</td>
      </tr>
    </table>
    [%- END %]
    </td>
  </tr>
</table>>];
  [%- id = id + 1 %]
[% END %]
[%- class_id = id %]

[%- first = 1 %]
[%- id = 0 %]
[%- IF display_inheritance %]
  [%- FOREACH class = classes %]
    [%- id = id + 1 %]
    [%- super = class.name %]
    [%- NEXT IF !class.subclasses.size -%]

    [%- IF first -%]
     node [shape="triangle", fillcolor=yellow, height=0.3, width=0.3];
      [%- first = 0 %]
    [%- END -%]

     angle_[% id %] [label=""];

    [%- super_id = name2id.$super %]
     class_[% super_id %]:methods -> angle_[% id %]

    [%- FOREACH child = class.subclasses %]
      [%- child_id = name2id.$child %]
      [%- IF !child_id %]
     class_[% class_id %] [shape=record, label="[% child %]" fillcolor="#f1e1f4", style="filled"];
     angle_[% id %] -> class_[% class_id %]
        [%- class_id = class_id + 1 %]
      [%- ELSE %]
     angle_[% id %] -> class_[% child_id %]:title
      [%- END %]
    [%- END %]
  [%- END %]
[%- END %]

[%- IF moose_roles %]
[%- first = 1 %]
     edge [color=blue, dir=none];
  [%- FOREACH class = classes %]
    [%- id = id + 1 %]
    [%- NEXT IF !class.consumers.size -%]
    [%- role = class.name %]
    [%- role_id = name2id.$role %]
    [%- IF first %]
     node [shape="triangle", fillcolor=orange, height=0.3, width=0.3];
      [%- first = 0 %]
    [%- END %]

     angle_[% id %] [label=""];
     class_[% role_id %]:methods -> angle_[% id %]

    [%- FOREACH consumer = class.consumers %]
      [%- consumer_id = name2id.$consumer %]
     angle_[% id %] -> class_[% consumer_id %]:title
    [%- END %]
  [%- END %]
[%- END %]

}
_EOC_

1;
__END__

=encoding utf-8

=head1 NAME

UML::Class::Simple - Render simple UML class diagrams, by loading the code

=head1 VERSION

This document describes C<UML::Class::Simple> 0.22 released by 18 December 2016.

=head1 SYNOPSIS

    use UML::Class::Simple;

    # produce a class diagram for Alias's PPI
    # which has already installed to your perl:

    @classes = classes_from_runtime("PPI", qr/^PPI::/);
    $painter = UML::Class::Simple->new(\@classes);
    $painter->as_png('ppi.png');

    # produce a class diagram for your CPAN module on the disk

    @classes = classes_from_files(['lib/Foo.pm', 'lib/Foo/Bar.pm']);
    $painter = UML::Class::Simple->new(\@classes);

    # we can explicitly specify the image size
    $painter->size(5, 3.6); # in inches

    # ...and change the default title background color:
    $painter->node_color('#ffffff'); # defaults to '#f1e1f4'

    # only show public methods and properties
    $painter->public_only(1);

    # hide all methods from parent classes
    $painter->inherited_methods(0);

    $painter->as_png('my_module.png');

=head1 DESCRIPTION

C<UML::Class::Simple> is a Perl CPAN module that generates UML class
diagrams (PNG format, GIF format, XMI format, or dot source) automatically
from Perl 5 source or Perl 5 runtime.

Perl developers can use this module to obtain pretty class diagrams
for arbitrary existing Perl class libraries (including modern perl OO
modules based on Moose.pm), by only a single command. Companies can
also use the resulting pictures to visualize the project hierarchy and
embed them into their documentation.

The users no longer need to drag a mouse on the screen so as to draw
figures themselves or provide any specs other than the source code of
their own libraries that they want to depict. This module does all the
jobs for them! :)

Methods created on-the-fly (in BEGIN or some such) can be inspected. Accessors created by modules L<Class::Accessor>, L<Class::Accessor::Fast>, and
L<Class::Accessor::Grouped> are recognized as "properties" rather than "methods". Intelligent distingishing between Perl methods and properties other than that is not provided.

You know, I was really impressed by the outputs of L<UML::Sequence>, so I
decided to find something to (automatically) get pretty class diagrams
too. The images from L<Autodia>'s Graphviz backend didn't quite fit my needs
when I was making some slides for my presentations.

I think most of the time you just want to use the command-line utility
L<umlclass.pl> offered by this module (just like me). See the
documentation of L<umlclass.pl> for details.

=head1 SAMPLE OUTPUTS

=over

=item PPI

L<https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/ppi_small.png>

=begin html

<img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/ppi_small.png">

=end html

(See also F<samples/ppi_small.png> in the distribution.)

=item Moose

L<https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/moose_small.png>

=begin html

<img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/moose_small.png">

=end html

(See also F<samples/moose_small.png> in the distribution.)

=item FAST

L<https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/fast.png>

=begin html

<img src="https://raw.githubusercontent.com/agentzh/uml-class-simple-pm/master/samples/fast.png">

=end html

(See also F<samples/fast.png> in the distribution.)

=back

=head1 SUBROUTINES

=over

=item classes_from_runtime($module_to_load, $regex?)

=item classes_from_runtime(\@modules_to_load, $regex?)

Returns a list of class (or package) names by inspecting the perl runtime environment.
C<$module_to_load> is the I<main> module name to load while C<$regex> is
a perl regex used to filter out interesting package names.

The second argument can be omitted.

=item classes_from_files($pmfile, $regex?)

=item classes_from_files(\@pmfiles, $regex?)

Returns a list of class (or package) names by scanning through the perl source files
given in the first argument. C<$regex> is used to filter out interesting package names.

The second argument can be omitted.

=item exclude_by_paths

Excludes package names via specifying one or more paths where the corresponding
modules were installed into. For example:

    @classes = exclude_by_paths(\@classes, 'C:/perl/lib');

    @classes = exclude_by_paths(\@classes, '/home/foo', '/System/Library');

=item grep_by_paths

Filters out package names via specifying one or more paths where the corresponding
modules were installed into. For instance:

    @classes = grep_by_paths(\@classes, '/home/malon', './blib/lib');

=back

All these subroutines are exported by default.

=head1 METHODS

=over

=item C<< $obj->new( [@class_names] ) >>

Create a new C<UML::Class::Simple> instance with the specified class name list.
This list can either be constructed manually or by the utility functions
C<classes_from_runtime> and C<classes_from_files>.

=item C<< $obj->as_png($filename?) >>

Generate PNG image file when C<$filename> is given. It returns
binary data when C<$filename> is not given.

=item C<< $obj->as_svg($filename?) >>

Generate SVG image file when C<$filename> is given. It returns
binary data when C<$filename> is not given.

=item C<< $obj->as_gif($filename?) >>

Similar to C<as_png>, bug generate a GIF-format image. Note that, for many graphviz installations, C<gif> support is disabled by default. So you'll probably see the following error message:

    Format: "gif" not recognized. Use one of: bmp canon cmap cmapx cmapx_np
        dia dot fig gtk hpgl ico imap imap_np ismap jpe jpeg jpg mif mp
        pcl pdf pic plain plain-ext png ps ps2 svg svgz tif tiff vml
        vmlz vtx xdot xlib

=item C<< $obj->as_dom() >>

Return the internal DOM tree used to generate dot and png. The tree's structure
looks like this:

  {
    'classes' => [
                   {
                     'subclasses' => [],
                     'methods' => [],
                     'name' => 'PPI::Structure::List',
                     'properties' => []
                   },
                   {
                     'subclasses' => [
                                       'PPI::Structure::Block',
                                       'PPI::Structure::Condition',
                                       'PPI::Structure::Constructor',
                                       'PPI::Structure::ForLoop',
                                       'PPI::Structure::Unknown'
                                     ],
                     'methods' => [
                                    '_INSTANCE',
                                    '_set_finish',
                                    'braces',
                                    'content',
                                    'new',
                                    'refaddr',
                                    'start',
                                    'tokens'
                                  ],
                     'name' => 'PPI::Structure',
                     'properties' => []
                   },
                   ...
                ]
  }

You can adjust the data structure and feed it back to C<$obj> via
the C<set_dom> method.

=item C<< $obj->set_dom($dom) >>

Set the internal DOM structure to C<$obj>. This will be used to
generate the dot source and thus the PNG/GIF images.

=item C<< $obj->as_dot() >>

Return the Graphviz dot source code generated by C<$obj>.

=item C<< $obj->set_dot($dot) >>

Set the dot source code used by C<$obj>.

=item C<< $obj->as_xmi($filename) >>

Generate XMI model file when C<$filename> is given. It returns
XML::LibXML::Document object when C<$filename> is not given.

=item C<< can_run($path) >>

Copied from L<IPC::Cmd> to test if $path is a runnable program. This code
is copyright by IPC::Cmd's author.

=item C<< $prog = $obj->dot_prog() >>

=item C<< $obj->dot_prog($prog) >>

Get or set the dot program path.

=back

=head1 PROPERTIES

=over

=item C<< $obj->size($width, $height) >>

=item C<< ($width, $height) = $obj->size >>

Set/get the size of the output images, in inches.

=item C<< $obj->public_only($bool) >>

=item C<< $bool = $obj->public_only >>

When the C<public_only> property is set to true, only public methods or properties
are shown. It defaults to false.

=item C<< $obj->inherited_methods($bool) >>

=item C<< $bool = $obj->inherited_methods >>

When the C<inherited_methods> property is set to false, then all methods,
inherited from parent classes, are not shown.
It defaults to true.

=item C<< $obj->node_color($color) >>

=item C<< $color = $obj->node_color >>

Set/get the background color for the class nodes. It defaults to C<'#f1e1f4'>.

=item C<< $obj->moose_roles($bool) >>

When this property is set to true values, then relationships between Moose::Role packages and their consumers
will be drawn in the output. Default to false.

=item C<< $obj->display_methods($bool) >>

When this property is set to false, then class methods will not be shown in the output. Default to true.

=item C<< $obj->display_inheritance($bool) >>

When this property is set to false, then the class inheritance relationship
will not be drawn in the output. Default to false.

=back

=head1 INSTALLATION

Please download and intall a recent Graphviz release from its home:

L<http://www.graphviz.org/>

C<UML::Class::Simple> requires the HTML label feature which is only
available on versions of Graphviz that are newer than mid-November 2003.
In particular, it is not part of release 1.10.

Add Graphviz's F<bin/> path to your PATH environment. This module needs its
F<dot> utility.

Grab this module from the CPAN mirror near you and run the following commands:

    perl Makefile.PL
    make
    make test
    make install

For windows users, use C<nmake> instead of C<make>.

Note that it's recommended to use the C<cpan> utility to install CPAN modules.

=head1 LIMITATIONS

=over

=item *

It's pretty hard to distinguish perl methods from properties (actually they're both
implemented by subs in perl). Currently only accessors created by L<Class::Accessor>, L<Class::Accessor::Fast>, and L<Class::Accessor::Grouped> are provided. (Thanks to the patches from Adam Lounds and Dave Howorth!) If you have any other good idea on this issue, please drop me a line ;)

=item *

Only the inheritance relationships are shown in the images. I believe
other subtle
relations may mess up the Graphviz layouter. Hence the "::Simple" suffix in
this module name.

=item *

Unlike L<Autodia>, at this moment only Graphviz and XMI backends are provided.

=item *

There's no way to recognize I<real> perl classes automatically. After all, Perl 5's
classes are implemented by packages. I think Perl 6 will make my life much easier.

=item *

To prevent potential naming confusion. I'm using Perl's C<::> namespace
separator
in the class diagrams instead of dot (C<.>) chosen by the UML standard.
One can argue that following UML standards is more important since people
in the same team may
use different programming languages, but I think it's not the case for
the majority (including myself) ;-)

=back

=head1 TODO

=over

=item *

Add more unit tests.

=item *

Add support for more image formats, such as C<as_ps>, C<as_jpg>, and etc.

=item *

Plot class relationships other than inheritance on the user's request.

=item *

Provide backends other than Graphviz.

=back

Please send me your wish list by emails or preferably via the CPAN RT site.
I'll add them here or even implement them promptly if I'm also interested
in your (crazy) ideas. ;-)

=head1 BUGS

There must be some serious bugs lurking somewhere;
if you found one, please report
it to L<http://rt.cpan.org> or contact the author directly.

=head1 ACKNOWLEDGEMENT

I must thank Adam Kennedy (Alias) for writing the excellent L<PPI> and
L<Class::Inspector> modules. L<umlclass.pl> uses the former to extract
package names from user's F<.pm> files or the latter to retrieve the function list of a
specific package.

I'm also grateful to Christopher Malon since he has (unintentionally)
motivated me to turn the original hack into this CPAN module. ;-)

=head1 SOURCE CONTROL

You can always grab the latest version from the following GitHub
repository:

L<https://github.com/agentzh/uml-class-simple-pm>

It has anonymous access to all.

If you have the tuits to help out with this module, please let me know.
I have a dream to keep sending out commit bits like Audrey Tang. ;-)

=head1 AUTHORS

Yichun "agentzh" Zhang (章亦春) C<< <agentzh@gmail.com> >>, OpenResty Inc.

Maxim Zenin C<< <max@foggy.ru> >>.

=head1 COPYRIGHT

Copyright (c) 2006-2016 by Yichun Zhang (章亦春), OpenResty Inc.
Copyright (c) 2007-2014 by Maxim Zenin.

This library is free software; you can redistribute it and/or modify it under
the same terms as perl itself, either Artistic and GPL.

=head1 SEE ALSO

L<umlclass.pl>, L<Autodia>, L<UML::Sequence>, L<PPI>, L<Class::Inspector>, L<XML::LibXML>.

