# sort files
{
    my @tmp = grep(m#t/{test_seq\(\)}_{service_name}\.t\.tmpl$#, @$files);
    my @other = grep(!m#t/{test_seq\(\)}_{service_name}\.t\.tmpl$#, @$files);
    push(@other, @tmp);
    @$files = @other;

    @tmp = grep(m#t/00_pod\.t\.tmpl$#, @$files);
    @other = grep(!m#t/00_pod\.t\.tmpl$#, @$files);
    push(@other, @tmp);
    @$files = @other;

    @tmp = grep(m/MANIFEST\.tmpl$/, @$files);
    @other = grep(!m#t/{n}_{service_name}\.t\.tmpl$#, @$files);
    push(@other, @tmp);
    @$files = @other;
}

# register listeners
#{
#    push(@{$listeners->{post_generate}}, \&exec_make_dist_sh);
#}

sub package_name {
    return sprintf("WebService::%s::%s",
                   $tmpl->get('company_name'),
                   $tmpl->get('service_name'));
}

sub package_dir {
    return sprintf("WebService/%s/%s",
                   $tmpl->get('company_name'),
                   $tmpl->get('service_name'));
}

sub make_query_fields {
    my ($method) = @_;
    
    my $query_fields = [];
    
    foreach my $param (@{$method->{params}}) {
        next if $param->{fixed};
        push(@$query_fields, $param->{name});
    }
    
    return join(", ", map {"'$_'"} @$query_fields);
}

sub make_default_param {
    my ($method) = @_;
    
    my $default_param = {};
    
    foreach my $param (@{$method->{params}}) {
        $default_param->{$param->{name}} = $param->{default}
            if $param->{default};

        $default_param->{$param->{name}} = $param->{fixed}
            if $param->{fixed};
    }
    
    return join(", ", map {"'$_' => '$default_param->{$_}'"} keys %$default_param);
}

sub make_notnull_param {
    my ($method) = @_;
    
    my $notnull = [];
    
    foreach my $param (@{$method->{params}}) {
        push(@$notnull, $param->{name}) if $param->{'require'};
    }
    
    return join(", ", map {"'$_'"} @$notnull);
}

sub make_elem_fields {
    my ($method) = @_;
    
    my $blocks = {};
    
    my $rets = [$method->{'return'}, $method->{'error'}];
    while (@$rets) {
        my $ret = shift(@$rets);
        next unless ref $ret->{children};
        foreach my $child (@{$ret->{children}}) {
            push(@{$blocks->{$ret->{name}}}, $child->{name});
            push(@$rets, $child);
        }
    }
    
    my $result = "";
    foreach my $key (sort keys %$blocks) {
        $result .= "    '$key' => [";
        $result .= join(", ", map {"'$_'"} @{$blocks->{$key}});
        $result .= "],\n";
    }
    
    $result =~ s/^\s+//;
    
    return $result;
}

sub make_force_array {
    my ($method) = @_;
    
    my $force_array = {};
    
    my $que = [[$method->{'return'}]];
    while (@$que) {
        my $node = shift(@$que);
        foreach my $n (@$node) {
            if (exists $n->{children}) {
                push(@$que, $n->{children});
            }
            if ($n->{multiple}) {
                $force_array->{$n->{name}}++;
            }
        }
    }
    
    return join(", ", map {"'$_'"} sort keys %$force_array);
}

sub make_pod_test_files {
    my @libs = grep(m#^\Q$odir\E/lib/#, @$result);
    return join("\n", map { s#^\Q$odir\E/##; "    $_" } @libs);
}

#sub exec_make_dist_sh {
#    local $tmp_dir = $tmp_dir;
#    $tmp_dir =~ s/([\&\;\`\'\\\"\|\*\?\~\<\>\^\(\)\[\]\{\}\$\n\r ])/\\$1/g;
#    local $odir = $odir;
#    $odir =~ s/([\&\;\`\'\\\"\|\*\?\~\<\>\^\(\)\[\]\{\}\$\n\r ])/\\$1/g;
#    print STDERR ">>> exec make-dist.sh\n";
#    `$tmpl_dir/make-dist.sh $odir >&2`;
#    die "failed exec_make_dist_sh: ret=$?" if $?;
#    print STDERR "<<< done make-dist.sh\n\n";
#}

my $test_seq_val = 4;
sub test_seq {
    return sprintf("%02d", $test_seq_val++);
}

sub make_env_params_check {
    my ($methods) = @_;

    $methods = [$methods] if ref($methods) ne 'ARRAY';
    
    my $env_params = {};
    foreach my $method (@$methods) {
        foreach my $test (@{$method->{tests}}) {
            foreach my $param (values %{$test->{params}}) {
                next unless $param =~ /^\$(.*)$/;
                $env_params->{$1}++;
            }
        }
    }
    
    return "" unless keys %$env_params;

    my $keys = join(", ", map {"'$_'"} sort keys %$env_params);
    my $result =<<EOS;
{
    my \$errs = [];
    foreach my \$key ($keys) {
        next if exists \$ENV{\$key};
        push(\@\$errs, \$key);
    }
    plan skip_all => sprintf('set %s env to test this', join(", ", \@\$errs))
        if \@\$errs;
}
EOS
    
    $result =~ s/\s+$//;
    
    return $result;
}

sub make_test_count {
    my ($base_cnt, $methods) = @_;

    $methods = [$methods] if ref($methods) ne 'ARRAY';
    
    my $cnt = $base_cnt;
    
    foreach my $method (@$methods) {
        foreach my $test (@{$method->{tests}}) {
            if ($test->{type} eq 'lib_error') {
                # die
                $cnt++;
            } elsif ($test->{type} eq 'error') {
                # die / is_error
                $cnt += 2;
            } else {
                # die / is_error / root
                $cnt += 3;
                
                # each element's can_ok / ok
                $cnt += _calc_ret_elms($method->{return});
            }
        }
    }
    
    return $cnt;
}

sub join {
    my $str = shift;
    my $arrayref = shift;
    return CORE::join($str, @$arrayref);
}

sub sort_keys {
    my $hashref = shift;
    return sort keys %$hashref;
}

sub env_param {
    return sub {
        my $val = shift;
        unless ($val =~ s/^\$(.*)$/\$ENV{'$1'}/) {
            $val = "'$val'";
        }
        return $val;
    };
}

sub tree_to_array {
    my $tree = shift;

    my $array = [$tree];
    my $stack = [[$tree, 0]];
    while (my $val = pop(@$stack)) {
        my ($node, $i) = @$val;
        for (; $i < @{$node->{children}}; $i++) {
            my $child = $node->{children}->[$i];
            push(@$array, $child);
            if ($child->{children}) {
                push(@$stack, [$node, $i+1]);
                push(@$stack, [$child, 0]);
                last;
            }
        }
    }

    return $array;
}

sub count {
    my $arrayref = shift;
    return scalar(@$arrayref);
}

sub node_nullable {
    my $node = shift;
    my $path = $node->path;
    foreach my $p (@$path) {
        return 1 if $p->nullable;
    }
    return 0;
}

sub node_access {
    my $node = shift;
    return "" if $node->depth < 2;
    my $path = $node->path(2);
    my $access = [""];
    foreach my $p (@$path) {
        push(@$access, $p->name);
        push(@$access, "[0]") if $p->multiple && $p != $node;
    }
    return join("->", @$access);
}

sub _calc_ret_elms {
    my ($ret_root) = @_;
    
    my $result = 0;
    my $ret_elms = [@{$ret_root->{children}}];
    while (my $ret = shift(@$ret_elms)) {
        next if $ret->{nullable};
        $result += 1;
        $result++ if $ret->{multiple};
        next unless $ret->{children};
        push(@$ret_elms, @{$ret->{children}});
    }
    
    return $result;
}

1;
