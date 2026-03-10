package Yote::Spiderpup;

use strict;
use warnings;

our $VERSION = '0.07';

use CSS::LESSp;
use Data::Dumper;
use IO::Socket::INET;
use JSON::PP;
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use YAML;

use Yote::Spiderpup::SFC qw(parse_sfc);

use Yote::Spiderpup::Transform qw(
    transform_dollar_vars
    transform_expression
    extract_arrow_params
    add_implicit_this
    parse_html
);

# HTML void tags (self-closing)
my %VOID_TAGS = map { $_ => 1 } qw(area base br col embed hr img input meta param source track wbr);

sub new {
    my ($class, %args) = @_;
    my $www_dir     = $args{www_dir} // die "www_dir required";
    my $webroot_dir = $args{webroot_dir} // File::Spec->catdir($www_dir, 'webroot');
    my $self = bless {
        www_dir      => $www_dir,
        pages_dir    => File::Spec->catdir($www_dir, 'pages'),
        recipes_dir  => File::Spec->catdir($www_dir, 'recipes'),
        webroot_dir  => $webroot_dir,
        js_dir       => File::Spec->catdir($webroot_dir, 'js'),
        static_dir   => $www_dir,
        base_url_path => $args{base_url_path} // '',
        file_mtimes  => {},
        last_change_time => 0,
    }, $class;
    make_path($self->{js_dir}) unless -d $self->{js_dir};
    return $self;
}

#----------------------------------------------------------------------
# File change tracking
#----------------------------------------------------------------------

sub _scan_yaml_dir {
    my ($self, $dir, $changed_ref) = @_;
    opendir(my $dh, $dir) or return;
    while (my $entry = readdir($dh)) {
        next if $entry =~ /^\./;
        my $path = File::Spec->catfile($dir, $entry);
        if (-d $path) {
            $self->_scan_yaml_dir($path, $changed_ref);
        } elsif ($entry =~ /\.(yaml|pup)$/) {
            my $mtime = (stat($path))[9];
            if (!exists $self->{file_mtimes}{$path} || $self->{file_mtimes}{$path} != $mtime) {
                $self->{file_mtimes}{$path} = $mtime;
                $$changed_ref = 1;
            }
        }
    }
    closedir($dh);
}

sub update_file_mtimes {
    my ($self) = @_;
    my $changed = 0;

    $self->_scan_yaml_dir($self->{recipes_dir}, \$changed);
    $self->_scan_yaml_dir($self->{pages_dir}, \$changed);

    if ($changed) {
        $self->{last_change_time} = time();
    }
    return $changed;
}

sub is_dev_mode {
    return $ENV{SPIDERPUP_DEV} ? 1 : 0;
}

#----------------------------------------------------------------------
# Component file helpers (.yaml / .pup)
#----------------------------------------------------------------------

sub _find_component_file {
    my ($self, $dir, $name) = @_;
    my $yaml = File::Spec->catfile($dir, "$name.yaml");
    return $yaml if -f $yaml;
    my $pup = File::Spec->catfile($dir, "$name.pup");
    return $pup if -f $pup;
    return undef;
}

sub _load_component_data {
    my ($self, $file_path) = @_;
    if ($file_path =~ /\.pup$/) {
        open my $fh, '<', $file_path or die "Cannot open $file_path: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        return parse_sfc($content);
    }
    return YAML::LoadFile($file_path);
}

#----------------------------------------------------------------------
# Path resolution
#----------------------------------------------------------------------

sub parse_page_path {
    my ($self, $path) = @_;

    $path =~ s|^/+||;
    $path =~ s|\.html$||;
    $path =~ s|\.yaml$||;
    $path =~ s|\.pup$||;

    return 'index' if $path eq '' || $path eq 'index';

    my @segments = split(/\//, $path);
    if (@segments == 1) {
        my $subdir = File::Spec->catdir($self->{pages_dir}, $segments[0]);
        if (-d $subdir) {
            return "$segments[0]/index";
        }
    }

    return $path;
}

sub load_page {
    my ($self, $path) = @_;

    $path =~ s|^/+||;
    $path =~ s|\.html$||;
    $path =~ s|\.yaml$||;
    $path =~ s|\.pup$||;
    $path = 'index' if $path eq '' || $path eq 'index.html';

    my $component_file;

    if ($path =~ s|^recipes/||) {
        $component_file = $self->_find_component_file($self->{recipes_dir}, $path);
    } else {
        $component_file = $self->_find_component_file($self->{pages_dir}, $path);
    }

    return undef unless $component_file;

    my $page_data = $self->_load_component_data($component_file);
    my $relative_path = File::Spec->abs2rel($component_file, $self->{www_dir});
    $page_data->{yaml_path} = $relative_path;

    return $page_data;
}

sub resolve_recipe_name {
    my ($self, $import_path) = @_;

    $import_path =~ s|^/+||;
    $import_path =~ s|\.yaml$||;
    $import_path =~ s|\.pup$||;

    my ($module_name, $is_page);
    if ($import_path =~ m|^recipes/(.+)$|) {
        $module_name = $1;
        $is_page = 0;
    } else {
        $module_name = $import_path;
        my $page_file = $self->_find_component_file($self->{pages_dir}, $module_name);
        $is_page = $page_file ? 1 : 0;
    }

    my $class_name = $module_name;
    $class_name =~ s|/|_|g;
    $class_name =~ s/-(.)/\U$1/g;
    $class_name = ucfirst($class_name);

    my $js_path = $is_page ? "/js/pages/$module_name.js" : "/js/$module_name.js";

    return ($module_name, $class_name, $js_path, $is_page);
}

#----------------------------------------------------------------------
# Caching
#----------------------------------------------------------------------

sub get_cache_paths {
    my ($self, $page_name) = @_;
    return (
        html => File::Spec->catfile($self->{webroot_dir}, "$page_name.html"),
        meta => File::Spec->catfile($self->{webroot_dir}, "$page_name.meta"),
    );
}

sub get_recipe_cache_paths {
    my ($self, $module_name) = @_;
    return (
        js   => File::Spec->catfile($self->{js_dir}, "$module_name.js"),
        meta => File::Spec->catfile($self->{js_dir}, "$module_name.js.meta"),
    );
}

sub collect_yaml_files {
    my ($self, $page_data, $page_name, $collected) = @_;
    $collected //= {};

    my $component_file;
    if ($page_name =~ /^recipes\/(.+)$/) {
        $component_file = $self->_find_component_file($self->{recipes_dir}, $1);
    } else {
        $component_file = $self->_find_component_file($self->{pages_dir}, $page_name);
    }
    if ($component_file) {
        $collected->{$component_file} = (stat($component_file))[9];
    }

    my $imports = $page_data->{import} // {};
    for my $namespace (keys %$imports) {
        my $import_path = $imports->{$namespace};
        $import_path =~ s|^/+||;
        $import_path =~ s|\.yaml$||;
        $import_path =~ s|\.pup$||;

        my $import_file;
        if ($import_path =~ /^recipes\/(.+)$/) {
            $import_file = $self->_find_component_file($self->{recipes_dir}, $1);
        } else {
            $import_file = $self->_find_component_file($self->{pages_dir}, $import_path);
        }
        next unless $import_file;
        next if exists $collected->{$import_file};

        my $imported_page = $self->load_page($import_path);
        if ($imported_page) {
            $self->collect_yaml_files($imported_page, $import_path, $collected);
        }
    }

    return $collected;
}

sub is_cache_valid {
    my ($self, $page_name, $page_data) = @_;

    my %paths = $self->get_cache_paths($page_name);

    return 0 unless -f $paths{html} && -f $paths{meta};

    open my $fh, '<', $paths{meta} or return 0;
    my $meta_content = do { local $/; <$fh> };
    close $fh;

    my $cached_mtimes;
    eval { $cached_mtimes = decode_json($meta_content); };
    return 0 if $@ || !$cached_mtimes;

    my $current_mtimes = $self->collect_yaml_files($page_data, $page_name);

    return 0 if keys %$cached_mtimes != keys %$current_mtimes;

    for my $file (keys %$cached_mtimes) {
        return 0 unless exists $current_mtimes->{$file};
        return 0 if $current_mtimes->{$file} != $cached_mtimes->{$file};
    }

    return 1;
}

sub get_cached_html {
    my ($self, $page_data, $page_name) = @_;

    if ($ENV{SPIDERPUP_NO_CACHE}) {
        return $self->build_html($page_data, $page_name);
    }
    my %paths = $self->get_cache_paths($page_name);

    if ($self->is_cache_valid($page_name, $page_data)) {
        print "CACHED $page_name\n";
        open my $fh, '<', $paths{html} or goto BUILD;
        my $html = do { local $/; <$fh> };
        close $fh;
        return $html;
    }
    print "not cached $page_name\n";

    BUILD:
    my $html = $self->build_html($page_data, $page_name);

    my $mtimes = $self->collect_yaml_files($page_data, $page_name);

    my $dir = dirname($paths{html});
    make_path($dir) unless -d $dir;

    eval {
        open my $html_fh, '>', $paths{html} or die "Cannot write $paths{html}: $!";
        print $html_fh $html;
        close $html_fh;

        open my $meta_fh, '>', $paths{meta} or die "Cannot write $paths{meta}: $!";
        print $meta_fh encode_json($mtimes);
        close $meta_fh;
    };
    warn "Cache write failed: $@" if $@;

    return $html;
}

#----------------------------------------------------------------------
# Class generation
#----------------------------------------------------------------------

sub _save_block {
    my ($self, $result, $key, $mode, $multiline, $map, $array) = @_;
    return unless defined $key;

    if ($mode eq 'multiline') {
        $result->{$key} = join("\n", @$multiline);
    } elsif ($mode eq 'array') {
        $result->{$key} = [ @$array ];
    } elsif ($mode eq 'map') {
        $result->{$key} = { %$map };
    }
}

sub generate_single_class {
    my ($self, $class_name, $page, $page_imports_obj) = @_;

    my @method_names = $page->{methods} ? keys %{$page->{methods}} : ();
    my $known_methods = {map { $_ => 1 } @method_names};

    my $title = $page->{title} // '';
    my $yaml_path = $page->{yaml_path} // '';
    my $html_raw = $page->{html} // '';
    my $html = $html_raw;
    $title =~ s/\\/\\\\/g; $title =~ s/'/\\'/g;
    $yaml_path =~ s/\\/\\\\/g; $yaml_path =~ s/'/\\'/g;
    $html =~ s/\\/\\\\/g; $html =~ s/'/\\'/g;
    $html =~ s/\n/\\n/g;

    my $structure = parse_html($html_raw, $known_methods);

    my $structure_json = encode_json($structure);

    # remove quotes around functions so they are interpreted as javascript functions
    # handles both function() and arrow function () => styles
    $structure_json =~ s/"\*([a-z_]+":)"(function\([^"]+)"/"$1$2/g;
    $structure_json =~ s/"\*([a-z_]+":)"(\([^"]*\)\s*=>[^"]*)"/"$1$2/g;

    # Build alternate structures for html_* variant keys
    my @variant_entries;
    for my $key (sort keys %$page) {
        if ($key =~ /^html_(\w+)$/) {
            my $variant_name = $1;
            my $variant_html_raw = $page->{$key};
            my $variant_structure = parse_html($variant_html_raw, $known_methods);
            my $variant_json = encode_json($variant_structure);
            $variant_json =~ s/"\*([a-z_]+":)"(function\([^"]+)"/"$1$2/g;
            $variant_json =~ s/"\*([a-z_]+":)"(\([^"]*\)\s*=>[^"]*)"/"$1$2/g;
            push @variant_entries, "$variant_name: $variant_json";
        }
    }
    my $structures_js = @variant_entries ? '{ ' . join(', ', @variant_entries) . ' }' : '{}';

    my $imports_obj = $page_imports_obj // '{}';

    my $vars_json = '{}';
    my @var_methods;
    if ($page->{vars} && keys %{$page->{vars}}) {
        my %vars_copy = %{$page->{vars}};
        for my $var_name (keys %vars_copy) {
            my $value = $vars_copy{$var_name};
            if (defined $value && !ref($value) && $value =~ /^-?\d+\.?\d*$/) {
                $vars_copy{$var_name} = $value + 0;
            }
        }
        $vars_json = encode_json(\%vars_copy);
        for my $var_name (sort keys %{$page->{vars}}) {
            push @var_methods, "    get_$var_name(defaultValue) { return this.get('$var_name', defaultValue); }";
            push @var_methods, "    set_$var_name(value) { return this.set('$var_name', value); }";
        }
    }

    my @custom_methods;
    if ($page->{methods} && keys %{$page->{methods}}) {
        for my $method_name (sort keys %{$page->{methods}}) {
            my $method_code = transform_expression($page->{methods}{$method_name}, $known_methods);
            push @custom_methods, "    $method_name = $method_code;";
        }
    }

    my @computed_methods;
    if ($page->{computed} && keys %{$page->{computed}}) {
        for my $computed_name (sort keys %{$page->{computed}}) {
            my $computed_code = transform_expression($page->{computed}{$computed_name}, $known_methods);
            push @computed_methods, "    get_$computed_name() { return ($computed_code).call(this); }";
        }
    }

    my @lifecycle_methods;
    if ($page->{lifecycle} && keys %{$page->{lifecycle}}) {
        for my $hook_name (sort keys %{$page->{lifecycle}}) {
            my $hook_code = transform_expression($page->{lifecycle}{$hook_name}, $known_methods);
            push @lifecycle_methods, "    $hook_name = $hook_code;";
        }
    }

    my $initial_store_js = '';
    if ($page->{'initial_store'} && keys %{$page->{'initial_store'}}) {
        my $store_json = encode_json($page->{'initial_store'});
        $initial_store_js = "    _initialStore = $store_json;";

        my $has_onmount = 0;
        my $existing_onmount_code = '';
        for my $i (0 .. $#lifecycle_methods) {
            if ($lifecycle_methods[$i] =~ /^\s*onMount\s*=\s*(.+);$/s) {
                $has_onmount = 1;
                $existing_onmount_code = $1;
                splice(@lifecycle_methods, $i, 1);
                last;
            }
        }

        if ($has_onmount) {
            push @lifecycle_methods, "    onMount = () => { store.init(this._initialStore); ($existing_onmount_code).call(this); };";
        } else {
            push @lifecycle_methods, "    onMount = () => { store.init(this._initialStore); };";
        }
    }

    my $methods_str = '';
    if (@var_methods || @custom_methods || @computed_methods || @lifecycle_methods) {
        $methods_str = "\n" . join("\n", @var_methods, @custom_methods, @computed_methods, @lifecycle_methods) . "\n";
    }

    my $routes_js = 'null';
    if ($page->{routes} && keys %{$page->{routes}}) {
        my @route_entries;
        for my $route_path (sort keys %{$page->{routes}}) {
            my $component_name = $page->{routes}{$route_path};
            my $component_class = $component_name;
            $component_class =~ s/-(.)/\U$1/g;
            $component_class = ucfirst($component_class);
            my $pattern = $route_path;
            my @param_names;
            while ($pattern =~ /:(\w+)/g) {
                push @param_names, $1;
            }
            $pattern =~ s#:(\w+)#([^/]+)#g;
            $pattern =~ s#/#\\/#g;
            $pattern = "^$pattern\$";
            my $params_js = '[' . join(', ', map { "'$_'" } @param_names) . ']';
            push @route_entries, "{ path: '$route_path', pattern: /$pattern/, component: $component_class, params: $params_js }";
        }
        $routes_js = '[' . join(', ', @route_entries) . ']';
    }

    my $css_str = '';
    my $css = $page->{css} // '';
    my $less = $page->{less};
    if ($less) {
        eval {
            $css .= join("", CSS::LESSp->parse($less));
        };
        warn "LESS compilation failed for $class_name: $@" if $@;
    }
    if ($css) {
        $css =~ s/^\s+//;
        $css =~ s/\s+$//;
        $css =~ s/\\/\\\\/g;
        $css =~ s/'/\\'/g;
        $css =~ s/\n/\\n/g;
        $css_str = "\n    _css = '$css';";
    }

    my $initial_store_line = $initial_store_js ? "\n$initial_store_js" : '';

    return <<"CLASS";
class $class_name extends Recipe {
    title      = '$title';
    yamlPath   = '$yaml_path';
    structure  = $structure_json;
    structures = $structures_js;
    vars       = $vars_json;
    imports    = $imports_obj;
    routes     = $routes_js;$css_str$initial_store_line
    $methods_str
}
CLASS
}

#----------------------------------------------------------------------
# Recipe compilation
#----------------------------------------------------------------------

sub compile_recipe {
    my ($self, $module_name) = @_;

    my $component_file = $self->_find_component_file($self->{recipes_dir}, $module_name);
    return unless $component_file;

    my $page_data = $self->_load_component_data($component_file);
    $page_data->{yaml_path} = File::Spec->abs2rel($component_file, $self->{www_dir});

    my $class_name = $module_name;
    $class_name =~ s/-(.)/\U$1/g;
    $class_name = ucfirst($class_name);

    my @import_lines;
    my @import_pairs;
    my $imports = $page_data->{import} // {};

    for my $namespace (sort keys %$imports) {
        my $import_path = $imports->{$namespace};
        my ($dep_mod_name, $dep_class_name, $dep_js_path) = $self->resolve_recipe_name($import_path);

        my $dep_data = $self->load_page($import_path);
        my @exported_classes = ($dep_class_name);

        if ($dep_data && $dep_data->{recipes} && ref($dep_data->{recipes}) eq 'HASH') {
            for my $recipe_name (sort keys %{$dep_data->{recipes}}) {
                push @exported_classes, "${dep_class_name}_${recipe_name}";
            }
        }

        my $imports_list = join(', ', @exported_classes);
        push @import_lines, "import { $imports_list } from './$dep_mod_name.js';";

        my $ns_lower = lc($namespace);
        push @import_pairs, "$ns_lower: $dep_class_name";

        if ($dep_data && $dep_data->{recipes}) {
            for my $recipe_name (sort keys %{$dep_data->{recipes}}) {
                my $dot_name = "$ns_lower.$recipe_name";
                my $sub_class = "${dep_class_name}_${recipe_name}";
                push @import_pairs, "\"$dot_name\": $sub_class";
            }
        }
    }

    if ($page_data->{recipes} && ref($page_data->{recipes}) eq 'HASH') {
        for my $recipe_name (sort keys %{$page_data->{recipes}}) {
            my $sub_class = "${class_name}_${recipe_name}";
            $sub_class = ucfirst($sub_class);
            push @import_pairs, "$recipe_name: $sub_class";
        }
    }

    my $imports_obj = @import_pairs ? '{ ' . join(', ', @import_pairs) . ' }' : '{}';

    my @classes;

    if ($page_data->{recipes} && ref($page_data->{recipes}) eq 'HASH') {
        for my $recipe_name (sort keys %{$page_data->{recipes}}) {
            my $sub_recipe = $page_data->{recipes}{$recipe_name};
            my $sub_class_name = "${class_name}_${recipe_name}";
            $sub_class_name = ucfirst($sub_class_name);
            push @classes, "export " . $self->generate_single_class($sub_class_name, $sub_recipe, '{}');
        }
    }

    push @classes, "export " . $self->generate_single_class($class_name, $page_data, $imports_obj);

    my $js_content = '';
    if (@import_lines) {
        $js_content .= join("\n", @import_lines) . "\n\n";
    }
    $js_content .= join("\n", @classes);

    my $js_file = File::Spec->catfile($self->{js_dir}, "$module_name.js");
    open my $fh, '>', $js_file or die "Cannot write $js_file: $!";
    print $fh $js_content;
    close $fh;

    my $meta_file = File::Spec->catfile($self->{js_dir}, "$module_name.js.meta");
    my %mtimes;
    $mtimes{$component_file} = (stat($component_file))[9];
    for my $namespace (keys %$imports) {
        my $import_path = $imports->{$namespace};
        my ($dep_mod_name) = $self->resolve_recipe_name($import_path);
        my $dep_file = $self->_find_component_file($self->{recipes_dir}, $dep_mod_name);
        $mtimes{$dep_file} = (stat($dep_file))[9] if $dep_file;
    }
    open my $meta_fh, '>', $meta_file or die "Cannot write $meta_file: $!";
    print $meta_fh encode_json(\%mtimes);
    close $meta_fh;

    print "  Compiled recipe: $module_name -> webroot/js/$module_name.js\n";
    return $js_content;
}

sub compile_recipe_if_stale {
    my ($self, $module_name) = @_;
    my %paths = $self->get_recipe_cache_paths($module_name);

    if (-f $paths{js} && -f $paths{meta} && !$ENV{SPIDERPUP_NO_CACHE}) {
        open my $fh, '<', $paths{meta} or goto COMPILE;
        my $meta = do { local $/; <$fh> };
        close $fh;
        my $cached = eval { decode_json($meta) };
        if ($cached) {
            my $valid = 1;
            for my $file (keys %$cached) {
                if (!-f $file || (stat($file))[9] != $cached->{$file}) {
                    $valid = 0;
                    last;
                }
            }
            return if $valid;
        }
    }

    COMPILE:
    $self->compile_recipe($module_name);
}

#----------------------------------------------------------------------
# Page JS compilation
#----------------------------------------------------------------------

sub compile_page_js {
    my ($self, $page_name) = @_;

    my $component_file = $self->_find_component_file($self->{pages_dir}, $page_name);
    return unless $component_file;

    my $page_data = $self->_load_component_data($component_file);
    $page_data->{yaml_path} = File::Spec->abs2rel($component_file, $self->{www_dir});

    my $class_name = $page_name;
    $class_name =~ s|/|_|g;
    $class_name =~ s/-(.)/\U$1/g;
    $class_name = ucfirst($class_name);

    my @segments = split(m|/|, $page_name);
    my $depth = scalar(@segments);
    my $prefix = '../' x $depth;

    my @import_lines;
    my @import_pairs;
    my $imports = $page_data->{import} // {};

    for my $namespace (sort keys %$imports) {
        my $import_path = $imports->{$namespace};
        my ($dep_name, $dep_class_name, $dep_js_path, $dep_is_page) = $self->resolve_recipe_name($import_path);

        if ($dep_is_page) {
            $self->compile_page_js_if_stale($dep_name);
        } else {
            $self->compile_recipe_if_stale($dep_name);
        }

        my $dep_data = $self->load_page($import_path);
        my @exported_classes = ($dep_class_name);

        if ($dep_data && $dep_data->{recipes} && ref($dep_data->{recipes}) eq 'HASH') {
            for my $recipe_name (sort keys %{$dep_data->{recipes}}) {
                push @exported_classes, "${dep_class_name}_${recipe_name}";
            }
        }

        my $imports_list = join(', ', @exported_classes);

        my $rel_path;
        if ($dep_is_page) {
            $rel_path = "${prefix}pages/$dep_name.js";
        } else {
            $rel_path = "${prefix}$dep_name.js";
        }
        push @import_lines, "import { $imports_list } from './$rel_path';";

        my $ns_lower = lc($namespace);
        push @import_pairs, "$ns_lower: $dep_class_name";

        if ($dep_data && $dep_data->{recipes}) {
            for my $recipe_name (sort keys %{$dep_data->{recipes}}) {
                my $dot_name = "$ns_lower.$recipe_name";
                my $sub_class = "${dep_class_name}_${recipe_name}";
                push @import_pairs, "\"$dot_name\": $sub_class";
            }
        }
    }

    if ($page_data->{recipes} && ref($page_data->{recipes}) eq 'HASH') {
        for my $recipe_name (sort keys %{$page_data->{recipes}}) {
            my $sub_class = "${class_name}_${recipe_name}";
            $sub_class = ucfirst($sub_class);
            push @import_pairs, "$recipe_name: $sub_class";
        }
    }

    my $imports_obj = @import_pairs ? '{ ' . join(', ', @import_pairs) . ' }' : '{}';

    my @classes;

    if ($page_data->{recipes} && ref($page_data->{recipes}) eq 'HASH') {
        for my $recipe_name (sort keys %{$page_data->{recipes}}) {
            my $sub_recipe = $page_data->{recipes}{$recipe_name};
            my $sub_class_name = "${class_name}_${recipe_name}";
            $sub_class_name = ucfirst($sub_class_name);
            push @classes, "export " . $self->generate_single_class($sub_class_name, $sub_recipe, '{}');
        }
    }

    push @classes, "export " . $self->generate_single_class($class_name, $page_data, $imports_obj);

    my $js_content = '';
    if (@import_lines) {
        $js_content .= join("\n", @import_lines) . "\n\n";
    }
    $js_content .= join("\n", @classes);

    my $js_file = File::Spec->catfile($self->{js_dir}, 'pages', "$page_name.js");
    my $js_dir = dirname($js_file);
    make_path($js_dir) unless -d $js_dir;

    open my $fh, '>', $js_file or die "Cannot write $js_file: $!";
    print $fh $js_content;
    close $fh;

    my $meta_file = File::Spec->catfile($self->{js_dir}, 'pages', "$page_name.js.meta");
    my %mtimes;
    $mtimes{$component_file} = (stat($component_file))[9];
    for my $namespace (keys %$imports) {
        my $import_path = $imports->{$namespace};
        my ($dep_name, undef, undef, $dep_is_page) = $self->resolve_recipe_name($import_path);
        my $dep_dir = $dep_is_page ? $self->{pages_dir} : $self->{recipes_dir};
        my $dep_file = $self->_find_component_file($dep_dir, $dep_name);
        $mtimes{$dep_file} = (stat($dep_file))[9] if $dep_file;
    }
    open my $meta_fh, '>', $meta_file or die "Cannot write $meta_file: $!";
    print $meta_fh encode_json(\%mtimes);
    close $meta_fh;

    print "  Compiled page JS: $page_name -> webroot/js/pages/$page_name.js\n";
    return $js_content;
}

sub compile_page_js_if_stale {
    my ($self, $page_name) = @_;

    my $js_file = File::Spec->catfile($self->{js_dir}, 'pages', "$page_name.js");
    my $meta_file = File::Spec->catfile($self->{js_dir}, 'pages', "$page_name.js.meta");

    if (-f $js_file && -f $meta_file && !$ENV{SPIDERPUP_NO_CACHE}) {
        open my $fh, '<', $meta_file or goto COMPILE;
        my $meta = do { local $/; <$fh> };
        close $fh;
        my $cached = eval { decode_json($meta) };
        if ($cached) {
            my $valid = 1;
            for my $file (keys %$cached) {
                if (!-f $file || (stat($file))[9] != $cached->{$file}) {
                    $valid = 0;
                    last;
                }
            }
            return if $valid;
        }
    }

    COMPILE:
    $self->compile_page_js($page_name);
}

#----------------------------------------------------------------------
# SSR rendering
#----------------------------------------------------------------------

sub ssr_substitute_vars {
    my ($self, $func_str, $vars) = @_;
    my $text = $func_str;
    $text =~ s/^function\(\)\{return\s*`(.*)`\}$/$1/s;
    $text =~ s/\$\{this\.get_(\w+)\(\)\}/defined $vars->{$1} ? $self->_html_escape($vars->{$1}) : ''/ge;
    return $text;
}

sub _html_escape {
    my ($self, $text) = @_;
    return '' unless defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;
    return $text;
}

sub render_ssr_body {
    my ($self, $structure, $vars, $recipes_map, $slot_children, $slot_vars, $slot_recipes_map) = @_;
    my $html = '';
    my $children = $structure->{children} // [];
    for my $i (0 .. $#$children) {
        $html .= $self->render_ssr_node($children, $i, $vars, $recipes_map, $slot_children, $slot_vars, $slot_recipes_map, {}, undef);
    }
    return $html;
}

sub render_ssr_node {
    # $parent_component_vars: vars of the component that is doing the current rendering
    # Used so nested components in slot content know their parent component's vars
    my ($self, $siblings, $idx, $vars, $recipes_map, $slot_children, $slot_vars, $slot_recipes_map, $seen, $parent_component_vars) = @_;
    $seen //= {};
    return '' if $seen->{$idx};

    my $node = $siblings->[$idx];
    return '' unless $node;

    if (exists $node->{content}) {
        return $self->_html_escape($node->{content});
    }

    if (exists $node->{'*content'}) {
        return $self->ssr_substitute_vars($node->{'*content'}, $vars);
    }

    my $tag = $node->{tag} // '';
    my $attrs = $node->{attributes} // {};
    my $children = $node->{children} // [];

    if ($tag eq 'if') {
        for my $j (($idx + 1) .. $#$siblings) {
            my $sib = $siblings->[$j];
            last unless $sib && $sib->{tag} && ($sib->{tag} eq 'elseif' || $sib->{tag} eq 'else');
            $seen->{$j} = 1;
            last if $sib->{tag} eq 'else';
        }
        return '<div data-sp-if></div>';
    }

    return '' if $tag eq 'elseif' || $tag eq 'else';

    # <slot/> tag: render the slot children with the parent's vars
    # Pass $vars (component's own vars) as parent_component_vars so nested
    # components in slot content know their "parent component" for scoping
    # Named slots only render children with matching slot="name" attribute;
    # default (unnamed) slots only render children without a slot attribute.
    if ($tag eq 'slot') {
        if ($slot_children && @$slot_children) {
            my $slot_name = $attrs->{name};
            my $slot_html = '';
            my $child_seen = {};
            for my $i (0 .. $#$slot_children) {
                my $child = $slot_children->[$i];
                next unless $child;
                my $child_slot = ($child->{attributes} // {})->{slot};
                if ($slot_name) {
                    next unless defined $child_slot && $child_slot eq $slot_name;
                } else {
                    next if defined $child_slot;
                }
                $slot_html .= $self->render_ssr_node(
                    $slot_children, $i,
                    $slot_vars // $vars,
                    $slot_recipes_map // $recipes_map,
                    undef, undef, undef, $child_seen,
                    $vars  # parent_component_vars = slot-owning component's vars
                );
            }
            return "<slot>$slot_html</slot>";
        }
        return '<slot></slot>';
    }

    if ($recipes_map && $recipes_map->{$tag}) {
        my $mod_info = $recipes_map->{$tag};
        my $mod_data = $mod_info->{data};
        my $mod_vars = {};

        if ($mod_data->{vars}) {
            %$mod_vars = %{$mod_data->{vars}};
        }

        for my $attr (keys %$attrs) {
            next if $attr =~ /^\*/;
            next if $attr eq 'for' || $attr eq 'slot';
            next if $attr =~ /^!/;
            $mod_vars->{$attr} = $attrs->{$attr};
        }

        my $variant = $node->{variant};
        my $mod_html_raw;
        if ($variant && $mod_data->{"html_$variant"}) {
            $mod_html_raw = $mod_data->{"html_$variant"};
        } else {
            $mod_html_raw = $mod_data->{html} // '';
        }
        my $mod_structure = parse_html($mod_html_raw, {});

        my $sub_modules_map = $self->_build_recipes_map($mod_data);

        # Slot content scopes to the parent of the slot-owning component.
        # $parent_component_vars reflects the component that created this component
        # (like parentModule in the JS runtime). Falls back to $vars (current context).
        my $parent_vars = $parent_component_vars // $vars;

        # Pass slot children and parent vars so <slot/> tags can render them with correct scoping
        my $component_html = $self->render_ssr_body(
            $mod_structure, $mod_vars, $sub_modules_map,
            $children, $parent_vars, $recipes_map
        );

        # Render slot children after template if component has no explicit <slot/> tag
        # parent_component_vars = mod_vars (this component's vars) so nested components
        # know their parent component for slot scoping
        if ($children && @$children && !$self->_has_slot_tag($mod_structure)) {
            my $child_seen = {};
            for my $i (0 .. $#$children) {
                $component_html .= $self->render_ssr_node(
                    $children, $i, $parent_vars, $recipes_map, undef, undef, undef, $child_seen, $mod_vars
                );
            }
        }

        return $component_html;
    }

    if ($tag eq 'link') {
        my $to = $attrs->{to} // '/';
        my $base = $self->{base_url_path} || '';
        my $html_to = ($to eq '/') ? '/' : "$to.html";
        my $href = $self->_html_escape($base . $html_to);
        my $inner = '';
        my $child_seen = {};
        for my $i (0 .. $#$children) {
            $inner .= $self->render_ssr_node($children, $i, $vars, $recipes_map, $slot_children, $slot_vars, $slot_recipes_map, $child_seen, $parent_component_vars);
        }
        return "<a href=\"$href\">$inner</a>";
    }

    if ($tag eq 'router') {
        return '<div data-router-view></div>';
    }

    if ($attrs->{'*for'}) {
        my $static_attrs = $self->_render_static_attrs($attrs);
        return "<$tag$static_attrs data-sp-for></$tag>";
    }

    my $static_attrs = $self->_render_static_attrs($attrs);

    if ($VOID_TAGS{$tag}) {
        return "<$tag$static_attrs />";
    }

    my $inner = '';
    my $child_seen = {};
    for my $i (0 .. $#$children) {
        $inner .= $self->render_ssr_node($children, $i, $vars, $recipes_map, $slot_children, $slot_vars, $slot_recipes_map, $child_seen, $parent_component_vars);
    }
    return "<$tag$static_attrs>$inner</$tag>";
}

sub _render_static_attrs {
    my ($self, $attrs) = @_;
    my $result = '';
    for my $attr (sort keys %$attrs) {
        next if $attr =~ /^\*/;
        next if $attr eq 'for' || $attr eq 'slot' || $attr eq 'condition';
        next if $attr =~ /^!/;
        my $val = $attrs->{$attr};
        next if ref $val;
        $result .= ' ' . $self->_html_escape($attr) . '="' . $self->_html_escape($val) . '"';
    }
    return $result;
}

sub _has_slot_tag {
    my ($self, $structure) = @_;
    my $children = $structure->{children} // [];
    for my $child (@$children) {
        return 1 if ($child->{tag} // '') eq 'slot';
        return 1 if $self->_has_slot_tag($child);
    }
    return 0;
}

sub _build_recipes_map {
    my ($self, $page_data) = @_;
    my $imports = $page_data->{import} // {};
    my $recipes_map = {};

    for my $namespace (keys %$imports) {
        my $import_path = $imports->{$namespace};
        my $mod_data = $self->load_page($import_path);
        next unless $mod_data;

        my ($mod_name, $mod_class) = $self->resolve_recipe_name($import_path);
        my $ns_lower = lc($namespace);
        $recipes_map->{$ns_lower} = { data => $mod_data, class_name => $mod_class };

        if ($mod_data->{recipes} && ref($mod_data->{recipes}) eq 'HASH') {
            for my $recipe_name (keys %{$mod_data->{recipes}}) {
                $recipes_map->{"$ns_lower.$recipe_name"} = {
                    data => $mod_data->{recipes}{$recipe_name},
                    class_name => "${mod_class}_${recipe_name}",
                };
            }
        }
    }

    if ($page_data->{recipes} && ref($page_data->{recipes}) eq 'HASH') {
        for my $recipe_name (keys %{$page_data->{recipes}}) {
            $recipes_map->{$recipe_name} = {
                data => $page_data->{recipes}{$recipe_name},
                class_name => $recipe_name,
            };
        }
    }

    return $recipes_map;
}

#----------------------------------------------------------------------
# Page compilation (HTML with ES module imports)
#----------------------------------------------------------------------

sub collect_external_assets {
    my ($self, $page_data) = @_;

    my @css_files;
    my @js_files;

    my $import_css = $page_data->{'import-css'} // [];
    for my $css_file (@$import_css) {
        push @css_files, $css_file;
    }

    my $import_js = $page_data->{'import-js'} // [];
    for my $js_file (@$import_js) {
        push @js_files, $js_file;
    }

    return (\@css_files, \@js_files);
}

sub collect_inline_js {
    my ($self, $page_data) = @_;

    my @js_contents;
    my $include_js = $page_data->{'include-js'} // [];
    for my $js_file (@$include_js) {
        my $file_path = File::Spec->catfile($self->{static_dir}, $js_file);
        if (-f $file_path) {
            open my $fh, '<', $file_path or do {
                warn "Cannot open include-js file $file_path: $!";
                next;
            };
            my $content = do { local $/; <$fh> };
            close $fh;
            push @js_contents, "/* include-js: $js_file */\n$content";
        } else {
            warn "include-js file not found: $file_path";
        }
    }

    return \@js_contents;
}

sub build_html {
    my ($self, $page_data, $page_name) = @_;
    $page_name //= 'index';

    my $title = $page_data->{title} // 'Untitled';

    my $class_name = $page_name;
    $class_name =~ s|/|_|g;
    $class_name =~ s/-(.)/\U$1/g;
    $class_name = ucfirst($class_name);

    $self->compile_page_js_if_stale($page_name);

    my $css = $page_data->{css} // '';
    my $less = $page_data->{less};
    if ($less) {
        eval { $css .= join("", CSS::LESSp->parse($less)); };
        warn "LESS compilation failed for page $page_name: $@" if $@;
    }
    my $style = '';
    if ($css) {
        $css =~ s/^\s+//;
        $css =~ s/\s+$//;
        $style = "<style>\n.$page_name { $css }\n</style>";
    }

    my ($external_css, $external_js) = $self->collect_external_assets($page_data);
    my $inline_js = $self->collect_inline_js($page_data);

    my $css_links = '';
    for my $css_file (@$external_css) {
        $css_links .= qq{    <link rel="stylesheet" href="$css_file">\n};
    }

    my $js_scripts = '';
    for my $js_file (@$external_js) {
        $js_scripts .= qq{    <script src="$js_file"></script>\n};
    }

    my $inline_js_script = '';
    if (@$inline_js) {
        my $inline_content = join("\n\n", @$inline_js);
        $inline_js_script = "    <script>\n$inline_content\n    </script>\n";
    }

    my $base_url_path = $self->{base_url_path} || '';
    my $spiderpup_src = $base_url_path ? "$base_url_path/js/spiderpup.js" : "/js/spiderpup.js";

    my $recipes_map = $self->_build_recipes_map($page_data);
    my $page_html_raw = $page_data->{html} // '';
    my $page_structure = parse_html($page_html_raw, {});
    my $page_vars = $page_data->{vars} // {};
    my $ssr_body = $self->render_ssr_body($page_structure, $page_vars, $recipes_map);

    # Skip SSR hydration if body has no meaningful content (only empty placeholders)
    my $ssr_test = $ssr_body;
    $ssr_test =~ s/<div data-sp-if><\/div>//g;
    $ssr_test =~ s/\s//g;
    my $ssr_attr = $ssr_test ne '' ? ' data-sp-ssr' : '';

    return <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$title</title>
    $css_links
    $style
    $js_scripts
    $inline_js_script
    <script src="$spiderpup_src"></script>
    <script type="module">
import { $class_name } from '$base_url_path/js/pages/$page_name.js';

window.SPIDERPUP_BASE_PATH = '$base_url_path';
document.addEventListener('DOMContentLoaded', function() {
    const page = new $class_name();
    page.pageName = '$page_name';
    document.body.classList.add('$page_name');
    if (document.body.hasAttribute('data-sp-ssr')) {
        page.hydrateUI();
    } else {
        page.initUI();
    }
});
    </script>
</head>
<body$ssr_attr>$ssr_body</body>
</html>
HTML
}

#----------------------------------------------------------------------
# Request handling
#----------------------------------------------------------------------

sub load_page_from_path {
    my ($self, $path) = @_;

    my $response = '';

    my $page_data;
    my $load_error;
    my $page_name = $self->parse_page_path($path);

    eval {
        $page_data = $self->load_page($page_name);
        print "Loaded page: $page_name\n";
    };
    $load_error = $@ if $@;

    if ($load_error) {
        my $escaped_error = $load_error;
        $escaped_error =~ s/&/&amp;/g;
        $escaped_error =~ s/</&lt;/g;
        $escaped_error =~ s/>/&gt;/g;
        $escaped_error =~ s/\n/<br>/g;

        my $error_html = <<"ERRORHTML";
<!DOCTYPE html>
<html>
<head>
    <title>Spiderpup Error</title>
    <style>
        .sp-error-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.9);
            color: #fff;
            font-family: monospace;
            padding: 40px;
            overflow: auto;
            z-index: 99999;
        }
        .sp-error-title {
            color: #ff6b6b;
            font-size: 24px;
            margin-bottom: 20px;
        }
        .sp-error-message {
            background: #1a1a2e;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #ff6b6b;
            white-space: pre-wrap;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="sp-error-overlay">
        <div class="sp-error-title">Spiderpup Compilation Error</div>
        <div class="sp-error-message">$escaped_error</div>
    </div>
</body>
</html>
ERRORHTML

        my $content_length = length($error_html);
        $response = "HTTP/1.1 500 Internal Server Error\r\n";
        $response .= "Content-Type: text/html; charset=utf-8\r\n";
        $response .= "Content-Length: $content_length\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $response .= $error_html;
    } elsif (defined $page_data) {
        my $body;
        eval {
            print "GET ($path) -> page=$page_name\n";
            $body = $self->get_cached_html($page_data, $page_name);
        };
        if ($@) {
            my $escaped_error = $@;
            $escaped_error =~ s/&/&amp;/g;
            $escaped_error =~ s/</&lt;/g;
            $escaped_error =~ s/>/&gt;/g;
            $escaped_error =~ s/\n/<br>/g;

            $body = <<"ERRORHTML";
<!DOCTYPE html>
<html>
<head>
    <title>Spiderpup Error</title>
    <style>
        .sp-error-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.9);
            color: #fff;
            font-family: monospace;
            padding: 40px;
            overflow: auto;
            z-index: 99999;
        }
        .sp-error-title {
            color: #ff6b6b;
            font-size: 24px;
            margin-bottom: 20px;
        }
        .sp-error-message {
            background: #1a1a2e;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #ff6b6b;
            white-space: pre-wrap;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="sp-error-overlay">
        <div class="sp-error-title">Spiderpup Build Error</div>
        <div class="sp-error-message">$escaped_error</div>
    </div>
</body>
</html>
ERRORHTML
        }

        my $content_length = length($body);
        $response = "HTTP/1.1 200 OK\r\n";
        $response .= "Content-Type: text/html; charset=utf-8\r\n";
        $response .= "Content-Length: $content_length\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $response .= $body;
    } else {
        my $not_found = "<!DOCTYPE html><html><body><h1>404 Not Found</h1></body></html>";
        my $content_length = length($not_found);
        $response = "HTTP/1.1 404 Not Found\r\n";
        $response .= "Content-Type: text/html; charset=utf-8\r\n";
        $response .= "Content-Length: $content_length\r\n";
        $response .= "Connection: close\r\n";
        $response .= "\r\n";
        $response .= $not_found;
    }
    return $response;
}

#----------------------------------------------------------------------
# HTTP server
#----------------------------------------------------------------------

sub run_server {
    my ($self, $port, %opts) = @_;
    $port //= 5000;

    $SIG{CHLD} = 'IGNORE';

    my $listener;
    my $is_ssl = $opts{ssl_cert} && $opts{ssl_key};

    if ($is_ssl) {
        require IO::Socket::SSL;
        $listener = IO::Socket::SSL->new(
            LocalAddr     => '0.0.0.0',
            LocalPort     => $port,
            Proto         => 'tcp',
            Listen        => SOMAXCONN,
            Reuse         => 1,
            SSL_cert_file => $opts{ssl_cert},
            SSL_key_file  => $opts{ssl_key},
        ) or die "Cannot create SSL socket: $! ($IO::Socket::SSL::SSL_ERROR)";
    } else {
        $listener = IO::Socket::INET->new(
            LocalAddr => '0.0.0.0',
            LocalPort => $port,
            Proto     => 'tcp',
            Listen    => SOMAXCONN,
            Reuse     => 1,
        ) or die "Cannot create socket: $!";
    }

    my $scheme = $is_ssl ? 'https' : 'http';
    print "Server running on $scheme://localhost:$port\n";
    print "Press Ctrl+C to stop.\n";

    my $base_url_path = $self->{base_url_path};

    while (my $conn = $listener->accept) {
        my $pid = fork();

        if (!defined $pid) {
            warn "Fork failed: $!";
            $conn->close;
            next;
        }

        if ($pid == 0) {
            $listener->close;

            eval {
                my $request = '';
                $conn->recv($request, 8192);
                print "RAW Request: $request\n";
                my ($request_line) = split(/\r?\n/, $request, 2);
                $request_line //= '';
                my ($method, $path, $version) = split(/\s+/, $request_line);

                print "Request: $method $path\n";

                $path =~ s~^/*$base_url_path~~;

                print "Path adjusted to $path\n";

                my $response;

                # Serve static files from webroot (JS, etc.)
                if ($path =~ /^\/?(.+\.js)$/) {
                    my $js_file = File::Spec->catfile($self->{webroot_dir}, $1);
                    if (-f $js_file) {
                        print "FOUND $js_file\n";
                        open my $fh, '<', $js_file or die "Cannot open $js_file: $!";
                        my $body = do { local $/; <$fh> };
                        close $fh;
                        my $content_length = length($body);
                        $response = "HTTP/1.1 200 OK\r\n";
                        $response .= "Content-Type: application/javascript; charset=utf-8\r\n";
                        $response .= "Content-Length: $content_length\r\n";
                        $response .= "Connection: close\r\n";
                        $response .= "\r\n";
                        $response .= $body;
                    } else {
                        print "missing $js_file\n";
                    }
                }

                # Serve raw YAML/PUP files
                if (!$response && $path =~ /\.(yaml|pup)$/) {
                    my $raw_path = $path;
                    $raw_path =~ s~^/~~;
                    my $raw_file = File::Spec->catfile($self->{www_dir}, $raw_path);
                    if (-f $raw_file) {
                        open my $fh, '<', $raw_file or die "Cannot open $raw_file: $!";
                        my $body = do { local $/; <$fh> };
                        close $fh;
                        my $content_type = $raw_file =~ /\.pup$/ ? 'text/plain' : 'text/yaml';
                        my $content_length = length($body);
                        $response = "HTTP/1.1 200 OK\r\n";
                        $response .= "Content-Type: $content_type; charset=utf-8\r\n";
                        $response .= "Content-Length: $content_length\r\n";
                        $response .= "Connection: close\r\n";
                        $response .= "\r\n";
                        $response .= $body;
                    }
                }

                # Load page from YAML file
                if (!$response) {
                    $response = $self->load_page_from_path($path);
                }

                $conn->send($response);
            };
            if ($@) {
                warn "Error handling request: $@";
            }

            $conn->close;
            exit(0);
        }

        $conn->close;
    }
}

#----------------------------------------------------------------------
# Batch compilation
#----------------------------------------------------------------------

sub find_yaml_files {
    my ($self, $dir, $prefix, $results) = @_;

    opendir(my $dh, $dir) or return;
    my @entries = readdir($dh);
    closedir($dh);

    for my $entry (@entries) {
        next if $entry =~ /^\./;
        my $path = File::Spec->catfile($dir, $entry);

        if (-d $path) {
            my $new_prefix = $prefix ? "$prefix/$entry" : $entry;
            $self->find_yaml_files($path, $new_prefix, $results);
        } elsif ($entry =~ /\.(yaml|pup)$/) {
            my $name = $entry;
            $name =~ s/\.(yaml|pup)$//;
            $name = $prefix ? "$prefix/$name" : $name;
            push @$results, $name;
        }
    }
}

sub compile_all {
    my ($self) = @_;
    print "Compiling all recipes and pages\n";

    make_path($self->{js_dir}) unless -d $self->{js_dir};

    my $count = 0;
    my @errors;

    # Phase 1: Compile all recipes to JS files
    print "--- Compiling recipes ---\n";
    opendir(my $mod_dh, $self->{recipes_dir}) or die "Cannot open $self->{recipes_dir}: $!";
    my @module_files = sort grep { /\.(yaml|pup)$/ } readdir($mod_dh);
    closedir($mod_dh);

    for my $mod_file (@module_files) {
        my $module_name = $mod_file;
        $module_name =~ s/\.(yaml|pup)$//;

        eval { $self->compile_recipe($module_name); };
        if ($@) {
            push @errors, "recipe $module_name: $@";
            warn "  ERROR: $@";
        } else {
            $count++;
        }
    }

    # Phase 2: Compile all pages to HTML files
    print "--- Compiling pages ---\n";
    my @page_files;
    $self->find_yaml_files($self->{pages_dir}, '', \@page_files);

    for my $page_name (sort @page_files) {
        print "  Compiling page: $page_name\n";

        eval {
            my $page_data = $self->load_page($page_name);
            if ($page_data) {
                my $html = $self->build_html($page_data, $page_name);
                my %paths = $self->get_cache_paths($page_name);

                my $dir = dirname($paths{html});
                make_path($dir) unless -d $dir;

                open my $html_fh, '>', $paths{html} or die "Cannot write $paths{html}: $!";
                print $html_fh $html;
                close $html_fh;

                my $mtimes = $self->collect_yaml_files($page_data, $page_name);
                open my $meta_fh, '>', $paths{meta} or die "Cannot write $paths{meta}: $!";
                print $meta_fh encode_json($mtimes);
                close $meta_fh;

                $count++;
            }
        };
        if ($@) {
            push @errors, "page $page_name: $@";
            warn "  ERROR: $@";
        }
    }

    print "\nCompiled $count items\n";
    if (@errors) {
        print "Errors:\n";
        print "  $_\n" for @errors;
    }
}

sub watch_and_compile {
    my ($self, $interval) = @_;
    $interval //= 5;

    print "Watching for changes every ${interval}s (Ctrl+C to stop)...\n";

    $self->compile_all();
    $self->update_file_mtimes();

    while (1) {
        sleep $interval;

        if ($self->update_file_mtimes()) {
            print "\n--- Changes detected at " . localtime() . " ---\n";
            $self->compile_all();
        }
    }
}

1;
