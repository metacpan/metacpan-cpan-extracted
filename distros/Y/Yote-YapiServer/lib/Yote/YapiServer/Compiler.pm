package Yote::YapiServer::Compiler;

use strict;
use warnings;

use YAML;
use File::Path qw(make_path);
use File::Basename;
use File::Find;
use Yote::YapiServer::YapiDef;

#======================================================================
# Public API
#======================================================================

sub compile {
    my ($input, $outdir) = @_;

    my @files;
    if (-d $input) {
        find(sub { push @files, $File::Find::name if /\.(ya?ml|ydef)$/ }, $input);
    } elsif (-f $input) {
        @files = ($input);
    } else {
        die "Input not found: $input\n";
    }

    die "No definition files found\n" unless @files;

    for my $file (@files) {
        print "Compiling $file...\n";

        my @defs;
        if ($file =~ /\.ydef$/) {
            @defs = @{ Yote::YapiServer::YapiDef::parse_file($file) };
        } else {
            @defs = (YAML::LoadFile($file));
        }

        for my $yaml (@defs) {
            my $type = $yaml->{type} // 'app';

            my @outputs;  # list of [package, content] pairs
            if ($type eq 'app') {
                @outputs = compile_app($yaml);
            } elsif ($type eq 'object') {
                @outputs = ( [$yaml->{package}, compile_object($yaml)] );
            } elsif ($type eq 'server') {
                @outputs = ( [$yaml->{package}, compile_server($yaml)] );
            } else {
                die "Unknown type '$type' in $file\n";
            }

            for my $pair (@outputs) {
                write_output($pair->[0], $pair->[1], $outdir);
            }
        }
    }

    print "Done.\n";
}

#======================================================================
# Compile an app YAML into Perl
#======================================================================
sub compile_app {
    my ($yaml) = @_;
    merge_method_shorthands($yaml);
    my $pkg = $yaml->{package};
    my $base = $yaml->{base} // 'Yote::YapiServer::App::Base';

    my @out;

    # Package header
    push @out, "package $pkg;";
    push @out, "";
    push @out, "use strict;";
    push @out, "use warnings;";
    push @out, "use base '$base';";

    # Extra uses
    if ($yaml->{uses}) {
        push @out, "";
        for my $mod (@{$yaml->{uses}}) {
            push @out, "use $mod;";
        }
    }

    # Use nested object packages so their tables get created
    if ($yaml->{objects}) {
        push @out, "";
        for my $obj_name (sort keys %{$yaml->{objects}}) {
            push @out, "use ${pkg}::${obj_name};";
        }
    }

    push @out, "";

    # Columns - merge with base
    push @out, "# Inherit base columns and add our own";
    push @out, "our \%cols = (";
    push @out, "    \%${base}::cols,";
    if ($yaml->{cols}) {
        for my $col (sort keys %{$yaml->{cols}}) {
            my $val = expand_col_type($yaml->{cols}{$col}, $pkg);
            push @out, "    $col => '$val',";
        }
    }
    push @out, ");";

    push @out, "";

    # Methods
    push @out, "# Method access control";
    push @out, "our \%METHODS = (";
    if ($yaml->{methods}) {
        my @pub; my @auth; my @admin;
        for my $name (sort keys %{$yaml->{methods}}) {
            my $def = $yaml->{methods}{$name};
            my $access = $def->{access} // 'auth';
            if (ref $access eq 'HASH') {
                push @auth, [$name, $def]; # compound access goes with auth
            } elsif ($access eq 'public') {
                push @pub, [$name, $def];
            } elsif ($access eq 'admin_only') {
                push @admin, [$name, $def];
            } else {
                push @auth, [$name, $def];
            }
        }
        if (@pub) {
            push @out, "    # Public - no auth required";
            for my $item (@pub) {
                my ($name, $def) = @$item;
                my $pad = pad_to($name, \@pub, \@auth, \@admin);
                push @out, "    $name$pad => " . method_hash_str($def, 'public') . ",";
            }
            push @out, "" if @auth || @admin;
        }
        if (@auth) {
            push @out, "    # Authenticated users";
            for my $item (@auth) {
                my ($name, $def) = @$item;
                my $pad = pad_to($name, \@pub, \@auth, \@admin);
                push @out, "    $name$pad => " . method_hash_str($def, 'auth') . ",";
            }
            push @out, "" if @admin;
        }
        if (@admin) {
            push @out, "    # Admin only";
            for my $item (@admin) {
                my ($name, $def) = @$item;
                my $pad = pad_to($name, \@pub, \@auth, \@admin);
                push @out, "    $name$pad => " . method_hash_str($def, 'admin_only') . ",";
            }
        }
    }
    push @out, ");";

    push @out, "";

    # Field access - merge with base
    push @out, "# Field visibility";
    push @out, "our \%FIELD_ACCESS = (";
    push @out, "    \%${base}::FIELD_ACCESS,";
    if ($yaml->{field_access}) {
        for my $field (sort keys %{$yaml->{field_access}}) {
            my $rule = $yaml->{field_access}{$field};
            push @out, "    $field => " . format_access_hash($rule) . ",";
        }
    }
    push @out, ");";

    push @out, "";

    # Public vars
    push @out, "# Public vars exposed on connect";
    push @out, "our \%PUBLIC_VARS = (";
    if ($yaml->{public_vars}) {
        for my $k (sort keys %{$yaml->{public_vars}}) {
            my $v = $yaml->{public_vars}{$k};
            push @out, "    $k => " . perl_value($v) . ",";
        }
    }
    push @out, ");";

    # Package-level scalar vars
    if ($yaml->{vars}) {
        push @out, "";
        for my $var (sort keys %{$yaml->{vars}}) {
            my $v = $yaml->{vars}{$var};
            push @out, "our \$$var = " . perl_value($v) . ";";
        }
    }

    # Method implementations
    if ($yaml->{methods}) {
        # Group by access for section headers
        my @pub_methods; my @auth_methods; my @admin_methods;
        for my $name (sort keys %{$yaml->{methods}}) {
            my $def = $yaml->{methods}{$name};
            my $access = $def->{access} // 'auth';
            my $access_str = ref $access ? 'auth' : $access;
            if ($access_str eq 'public') {
                push @pub_methods, $name;
            } elsif ($access_str eq 'admin_only') {
                push @admin_methods, $name;
            } else {
                push @auth_methods, $name;
            }
        }

        for my $group (['Public methods', \@pub_methods],
                       ['Authenticated methods', \@auth_methods],
                       ['Admin methods', \@admin_methods]) {
            my ($label, $names) = @$group;
            next unless @$names;
            push @out, "";
            push @out, "#" . "-" x 70;
            push @out, "# $label";
            push @out, "#" . "-" x 70;
            for my $name (@$names) {
                push @out, "";
                my $code = $yaml->{methods}{$name}{code};
                push @out, "sub $name {";
                push @out, indent_code($code);
                push @out, "}";
            }
        }
    }

    # Non-API subs
    if ($yaml->{subs}) {
        push @out, "";
        push @out, "#" . "-" x 70;
        push @out, "# Utility methods";
        push @out, "#" . "-" x 70;
        for my $name (sort keys %{$yaml->{subs}}) {
            push @out, "";
            push @out, "sub $name {";
            push @out, indent_code($yaml->{subs}{$name});
            push @out, "}";
        }
    }

    push @out, "";
    push @out, "1;";

    push @out, "";
    push @out, "__END__";

    my @outputs = ( [$pkg, join("\n", @out) . "\n"] );

    # Nested objects - each gets its own file
    if ($yaml->{objects}) {
        for my $obj_name (sort keys %{$yaml->{objects}}) {
            my $obj_def = $yaml->{objects}{$obj_name};
            my $obj_pkg = "${pkg}::${obj_name}";
            my $obj_content = compile_nested_object($obj_pkg, $obj_def, $pkg);
            push @outputs, [$obj_pkg, $obj_content . "\n"];
        }
    }

    return @outputs;
}

#======================================================================
# Compile a standalone object YAML
#======================================================================
sub compile_object {
    my ($yaml) = @_;
    merge_method_shorthands($yaml);
    my $pkg = $yaml->{package};
    my $base = $yaml->{base} // 'Yote::YapiServer::BaseObj';

    my @out;

    push @out, "package $pkg;";
    push @out, "";
    push @out, "use strict;";
    push @out, "use warnings;";
    push @out, "use base '$base';";

    if ($yaml->{uses}) {
        push @out, "";
        for my $mod (@{$yaml->{uses}}) {
            push @out, "use $mod;";
        }
    }

    push @out, "";

    # Columns (no base merging for standalone objects)
    push @out, "# Database column definitions";
    push @out, "our \%cols = (";
    if ($yaml->{cols}) {
        for my $col (sort keys %{$yaml->{cols}}) {
            my $val = expand_col_type($yaml->{cols}{$col}, $pkg);
            push @out, "    $col => '$val',";
        }
    }
    push @out, ");";

    push @out, "";

    # Field access
    push @out, "# Field visibility rules for client serialization";
    push @out, "our \%FIELD_ACCESS = (";
    if ($yaml->{field_access}) {
        for my $field (sort keys %{$yaml->{field_access}}) {
            my $rule = $yaml->{field_access}{$field};
            push @out, "    $field => " . format_access_hash($rule) . ",";
        }
    }
    push @out, ");";

    push @out, "";

    # Methods
    push @out, "# Methods callable from client";
    push @out, "our \%METHODS = (";
    if ($yaml->{methods}) {
        for my $name (sort keys %{$yaml->{methods}}) {
            my $def = $yaml->{methods}{$name};
            push @out, "    $name => " . method_hash_str($def) . ",";
        }
    }
    push @out, ");";

    # field_access and method_defs inherited from Yote::YapiServer::BaseObj

    # Method implementations
    if ($yaml->{methods}) {
        push @out, "";
        push @out, "#" . "-" x 70;
        push @out, "# Client-callable methods";
        push @out, "#" . "-" x 70;
        for my $name (sort keys %{$yaml->{methods}}) {
            my $def = $yaml->{methods}{$name};
            next unless $def->{code};
            push @out, "";
            push @out, "sub $name {";
            push @out, indent_code($def->{code});
            push @out, "}";
        }
    }

    # Non-API subs
    if ($yaml->{subs}) {
        push @out, "";
        push @out, "#" . "-" x 70;
        push @out, "# Server-side utility methods";
        push @out, "#" . "-" x 70;
        for my $name (sort keys %{$yaml->{subs}}) {
            push @out, "";
            push @out, "sub $name {";
            push @out, indent_code($yaml->{subs}{$name});
            push @out, "}";
        }
    }

    push @out, "";
    push @out, "1;";

    push @out, "";
    push @out, "__END__";

    return join("\n", @out) . "\n";
}

#======================================================================
# Compile a server YAML
#======================================================================
sub compile_server {
    my ($yaml) = @_;
    my $pkg = $yaml->{package};
    my $base = $yaml->{base} // 'Yote::YapiServer::Site';

    my @out;

    push @out, "package $pkg;";
    push @out, "";
    push @out, "use strict;";
    push @out, "use warnings;";
    push @out, "use base '$base';  # extends Yote::SQLObjectStore::BaseObj";

    if ($yaml->{uses}) {
        push @out, "";
        for my $mod (@{$yaml->{uses}}) {
            push @out, "use $mod;";
        }
    }

    push @out, "";

    push @out, "our \%cols = (";
    push @out, "    \%${base}::cols,";
    push @out, ");";

    push @out, "";

    push @out, "our \%INSTALLED_APPS = (";
    push @out, "    \%${base}::INSTALLED_APPS,";
    if ($yaml->{apps}) {
        for my $name (sort keys %{$yaml->{apps}}) {
            push @out, "    $name => '$yaml->{apps}{$name}',";
        }
    }
    push @out, ");";

    push @out, "";
    push @out, "sub installed_apps {";
    push @out, "    return \\\%INSTALLED_APPS;";
    push @out, "}";

    push @out, "";
    push @out, "1;";

    return join("\n", @out) . "\n";
}

#======================================================================
# Compile a nested object (inside an app)
#======================================================================
sub compile_nested_object {
    my ($obj_pkg, $def, $parent_pkg) = @_;
    merge_method_shorthands($def);
    my @out;

    push @out, "package $obj_pkg;";
    push @out, "";
    push @out, "use strict;";
    push @out, "use warnings;";
    push @out, "use base 'Yote::YapiServer::BaseObj';";

    push @out, "";
    push @out, "our \%cols = (";
    if ($def->{cols}) {
        for my $col (sort keys %{$def->{cols}}) {
            my $val = expand_col_type($def->{cols}{$col}, $parent_pkg);
            push @out, "    $col => '$val',";
        }
    }
    push @out, ");";

    push @out, "";
    push @out, "our \%FIELD_ACCESS = (";
    if ($def->{field_access}) {
        for my $field (sort keys %{$def->{field_access}}) {
            my $rule = $def->{field_access}{$field};
            push @out, "    $field => " . format_access_hash($rule) . ",";
        }
    }
    push @out, ");";

    push @out, "";
    push @out, "our \%METHODS = ();";

    # field_access, method_defs, to_client_hash inherited from Yote::YapiServer::BaseObj

    # Auto-generate _client_class_name from object name
    my ($obj_name) = $obj_pkg =~ /::(\w+)$/;
    push @out, "";
    push @out, "sub _client_class_name { return '$obj_name'; }";

    # to_client_hash inherited from BaseObj; custom overrides via subs:

    # Object-level methods
    if ($def->{methods}) {
        for my $name (sort keys %{$def->{methods}}) {
            my $mdef = $def->{methods}{$name};
            push @out, "";
            push @out, "sub $name {";
            push @out, indent_code($mdef->{code} // $mdef);
            push @out, "}";
        }
    }

    # Non-API subs on objects
    if ($def->{subs}) {
        for my $name (sort keys %{$def->{subs}}) {
            push @out, "";
            push @out, "sub $name {";
            push @out, indent_code($def->{subs}{$name});
            push @out, "}";
        }
    }

    push @out, "";
    push @out, "1;";

    push @out, "";
    push @out, "__END__";

    return join("\n", @out);
}

#======================================================================
# Helpers
#======================================================================

# Merge methods_public and methods_auth into methods with implicit access
sub merge_method_shorthands {
    my ($yaml) = @_;
    for my $key (qw(methods_public methods_auth)) {
        next unless $yaml->{$key};
        my $access = $key eq 'methods_public' ? 'public' : 'auth';
        $yaml->{methods} //= {};
        for my $name (keys %{$yaml->{$key}}) {
            my $def = $yaml->{$key}{$name};
            # Accept bare code string or hash with code key
            if (!ref $def) {
                $def = { code => $def };
            }
            $def->{access} //= $access;
            $yaml->{methods}{$name} = $def;
        }
        delete $yaml->{$key};
    }
}

# Expand relative package references: *::Foo -> *Parent::Package::Foo
# Only expands when * is immediately followed by :: (relative ref)
# Leaves absolute refs like *Yote::YapiServer::User unchanged
sub expand_col_type {
    my ($type, $parent_pkg) = @_;
    # *::Name or *ARRAY_*::Name patterns
    $type =~ s/\*::/\*${parent_pkg}::/g;
    return $type;
}

# Build method hash string from definition, including files flag
sub method_hash_str {
    my ($def, $default_access) = @_;
    my $access = $def->{access} // $default_access // 'auth';
    my @parts;

    if (ref $access eq 'HASH') {
        push @parts, map { "$_ => $access->{$_}" } sort keys %$access;
    } elsif ($access eq 'public') {
        push @parts, "public => 1";
    } elsif ($access eq 'admin_only') {
        push @parts, "admin_only => 1";
    } else {
        push @parts, "auth => 1";
    }

    push @parts, "files => 1" if $def->{files};

    return "{ " . join(", ", @parts) . " }";
}

# Format access rule as Perl hash ref
sub format_access_hash {
    my ($rule) = @_;
    if (ref $rule eq 'HASH') {
        my @parts = map { "$_ => $rule->{$_}" } sort keys %$rule;
        return "{ " . join(", ", @parts) . " }";
    }
    # Simple string like "public", "auth", "never", "owner_only", "admin_only"
    return "{ $rule => 1 }";
}

# Format a Perl value (string or number)
sub perl_value {
    my ($v) = @_;
    return $v if $v =~ /^\d+$/;   # integer
    return "'$v'";                  # string
}

# Indent code block for insertion into sub body
sub indent_code {
    my ($code) = @_;
    return "" unless defined $code;
    chomp $code;
    my @lines = split /\n/, $code;
    return join("\n", map { "    $_" } @lines);
}

# Calculate padding for alignment
sub pad_to {
    my ($name, @groups) = @_;
    my $max = 0;
    for my $group (@groups) {
        for my $item (@$group) {
            my $n = ref $item eq 'ARRAY' ? $item->[0] : $item;
            $max = length($n) if length($n) > $max;
        }
    }
    my $pad = $max - length($name);
    return $pad > 0 ? ' ' x $pad : '';
}

# Write generated Perl to the correct file path
sub write_output {
    my ($package, $content, $outdir) = @_;

    my $path = $package;
    $path =~ s/::/\//g;
    $path = "$outdir/$path.pm";

    my $dir = dirname($path);
    make_path($dir) unless -d $dir;

    open my $fh, '>', $path or die "Cannot write $path: $!\n";
    print $fh $content;
    close $fh;

    print "  -> $path\n";
}

1;
