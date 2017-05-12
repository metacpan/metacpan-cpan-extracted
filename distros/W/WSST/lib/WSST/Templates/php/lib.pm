use POSIX qw(strftime);
use Digest::MD5 ();

# sort files
{
    my @package_xml = grep(/package\.xml\.tmpl$/, @$files);
    my @other = grep(!/package\.xml\.tmpl$/, @$files);
    push(@other, @package_xml);
    @$files = @other;
}

sub package_name {
    return sprintf("Services_%s_%s",
                   $tmpl->get('company_name'),
                   $tmpl->get('service_name'));
}

sub package_dir {
    return sprintf("Services/%s/%s",
                   $tmpl->get('company_name'),
                   $tmpl->get('service_name'));
}

sub php_license_uri {
    return $schema->{php_license_uri} || {
        'PHP' => 'http://www.php.net/license/',
        'Apache' => 'http://www.apache.org/licenses/',
        'LGPL' => 'http://www.gnu.org/copyleft/lesser.html',
        'BSD style' => 'http://www.opensource.org/licenses/bsd-license.php',
        'BSD' => 'http://www.opensource.org/licenses/bsd-license.php',
        'MIT' => 'http://www.opensource.org/licenses/mit-license.html',
    }->{$tmpl->get('license')};
}

sub php_channel {
    return $schema->{php_channel} || "__uri";
}

sub php_copyright {
    return $schema->{php_copyright} || "";
}

sub php_link {
    return $schema->{php_link} || sprintf("http://localhost/%s", &package_name);
}

sub php_license_abstract {
    return $schema->{php_license_abstract} || "";
}

sub make_params_conf {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $conf = {};
    
    foreach my $param (@{$method->{params}}) {
        next if $param->{fixed};
        push(@{$conf->{'keys'}}, $param->{name});
    }
    
    foreach my $param (@{$method->{params}}) {
        if ($param->{'require'}) {
            $conf->{'notnull'}->{$param->{name}}++;
        }
        
        if ($param->{default}) {
            $conf->{defaults}->{$param->{name}} = $param->{default};
        }

        if ($param->{fixed}) {
            $conf->{fixed}->{$param->{name}} = $param->{fixed};
        }
    }
    
    if (exists $conf->{'notnull'}) {
        $conf->{'notnull'} = [sort keys %{$conf->{'notnull'}}];
    }
    
    my $result = make_php_array($conf, $indent, $indstr);
    $result =~ s/^\s+//;
    
    return $result;
}

sub make_response_conf {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $conf = {};

    my $que = [[$method->{'return'}]];
    while (@$que) {
        my $node = shift(@$que);
        foreach my $n (@$node) {
            if (exists $n->{children}) {
                push(@$que, $n->{children});
            }
            if ($n->{multiple}) {
                $conf->{'force_array'}->{$n->{name}}++;
            }
        }
    }
    
    if (exists $conf->{'force_array'}) {
        $conf->{'force_array'} = [sort keys %{$conf->{'force_array'}}];
    }
    
    if (exists $method->{'error_status'}) {
        $conf->{'error_status'} = [@{$method->{'error_status'}}];
    }
    
    my $result = make_php_array($conf, $indent, $indstr);
    $result =~ s/^\s+//;
    
    return $result;
}

sub make_php_array {
    my ($data, $indent, $indstr, $join) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    $join ||= "\n";
    
    sub rec_func {
        my ($dd, $ii, $is) = @_;
        
        my $pf = $is x $ii;
        
        my $ref = ref $dd;
        if ($ref eq 'HASH') {
            my $res = [];
            push(@$res, "${pf}array(");
            foreach my $ddd (sort keys %$dd) {
                my $dddd = rec_func($dd->{$ddd}, $ii+1, $is);
                $dddd =~ s/^$pf$is//;
                push(@$res, "$pf$is'$ddd' => $dddd,");
            }
            push(@$res, "${pf})");
            return join($join, @$res);
        } elsif ($ref eq 'ARRAY') {
            my $res = [];
            push(@$res, "${pf}array(");
            foreach my $ddd (@$dd) {
                push(@$res, rec_func($ddd, $ii+1, $is) . ",");
            }
            push(@$res, "${pf})");
            return join($join, @$res);
        }
        
        return "$pf'$dd'";
    }
    
    return rec_func($data, $indent, $indstr);
}

sub make_package_contents {
    my $strs = [];
    
    my $md5 = Digest::MD5->new();
    
    foreach my $file (@$result) {
        my $cfile = $file;
        $cfile =~ s#^\Q$odir\E/##;
        
        my $md5sum = "";
        if (open(IN, $file)) {
            $md5->addfile(\*IN);
            $md5sum = sprintf(' md5sum="%s"', $md5->hexdigest);
            $md5->reset();
            close(IN);
        }
        
        my $role = 'php';
        $role = 'test' if $cfile =~ /tests/;
        $role = 'doc' if $cfile =~ /docs/;
        
        my $bid = "Services/" . $tmpl->get('company_name');
        
        my $ostr =<<EOS;
   <file baseinstalldir="$bid"$md5sum name="$cfile" role="$role">
    <tasks:replace from="\@package_version\@" to="version" type="package-info" />
   </file>
EOS
        push(@$strs, $ostr);
    }
    
    my $str = join("", @$strs);
    $str =~ s/\s+$//;
    
    return $str;
}

sub make_is_error {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    return "return false;" unless $method->{'error'};
    
    my $strs = [];
    push(@$strs, "\$data =& \$this->getData();");
    
    my $ret_test = [map {['', $_]} @{$method->{'error'}->{children}}];
    while (my $ret = shift(@$ret_test)) {
        next if $ret->[1]->{nullable};
        my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
        push(@$strs, ($indstr x $indent) . "if (!isset($php_var)) {");
        push(@$strs, ($indstr x ($indent + 1)) . "return false;");
        if ($ret->[1]->{'values'}) {
            my $php_array = sprintf('array(%s)', join(", ", map {qq|"$_"|} @{$ret->[1]->{'values'}}));
            push(@$strs, ($indstr x ($indent)) . "} elseif (!in_array($php_var, $php_array)) {");
            push(@$strs, ($indstr x ($indent + 1)) . "return false;");
        }
        push(@$strs, ($indstr x $indent) . "}");
        next unless $ret->[1]->{children};
        my $next_node = $ret->[0].'->'.$ret->[1]->{name};
        $next_node .= '[0]'
            if $ret->[1]->{multiple};
        push(@$ret_test, map {[$next_node, $_]} @{$ret->[1]->{children}});
    }

    push(@$strs, ($indstr x $indent) . "return true;");
    
    return join("\n", @$strs);
}

sub make_error_message {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $ret_test = [map {['', $_]} @{$method->{'error'}->{children}}];
    while (my $ret = shift(@$ret_test)) {
        next if $ret->[1]->{nullable};
        if ($ret->[1]->{error_message}) {
            my $strs = [];
            push(@$strs, "\$data =& \$this->getData();");
            my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
            if ($ret->[1]->{error_message_map}) {
                my $msg_map = $ret->[1]->{error_message_map};
                my $php_array = make_php_array($msg_map, $indent, $indstr);
                $php_array =~ s/^\s+//;
                push(@$strs, ($indstr x $indent) . "\$msg_map = $php_array;");
                push(@$strs, ($indstr x $indent) . "\$val = $php_var;");
                push(@$strs, ($indstr x $indent) . "if (array_key_exists(\$val, \$msg_map)) {");
                push(@$strs, ($indstr x ($indent + 1)) . "return \$msg_map[\$val];");
                push(@$strs, ($indstr x $indent) . "}");
                push(@$strs, ($indstr x ($indent)) . "return \$val;");
            } else {
                push(@$strs, ($indstr x $indent) . "return $php_var;");
            }
            return join("\n", @$strs);
        }
        next unless $ret->[1]->{children};
        my $next_node = $ret->[0].'->'.$ret->[1]->{name};
        $next_node .= '[0]'
            if $ret->[1]->{multiple};
        push(@$ret_test, map {[$next_node, $_]} @{$ret->[1]->{children}});
    }
    
    return "return 'Unknown error';";
}

sub make_total_entries {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $ret_test = [map {['', $_]} @{$method->{'return'}->{children}}];
    while (my $ret = shift(@$ret_test)) {
        next if $ret->[1]->{nullable};
        if ($ret->[1]->{page_total_entries}) {
            my $strs = [];
            push(@$strs, "\$data =& \$this->getData();");
            my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
            push(@$strs, ($indstr x $indent) . "return $php_var;");
            return join("\n", @$strs);
        }
        next unless $ret->[1]->{children};
        my $next_node = $ret->[0].'->'.$ret->[1]->{name};
        $next_node .= '[0]'
            if $ret->[1]->{multiple};
        push(@$ret_test, map {[$next_node, $_]} @{$ret->[1]->{children}});
    }
    
    return "return 0;";
}

sub make_entries_per_page {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $ret_test = [map {['', $_]} @{$method->{'return'}->{children}}];
    while (my $ret = shift(@$ret_test)) {
        next if $ret->[1]->{nullable};
        if ($ret->[1]->{page_entries_per_page}) {
            my $strs = [];
            push(@$strs, "\$data =& \$this->getData();");
            my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
            push(@$strs, ($indstr x $indent) . "return $php_var;");
            return join("\n", @$strs);
        }
        next unless $ret->[1]->{children};
        my $next_node = $ret->[0].'->'.$ret->[1]->{name};
        $next_node .= '[0]'
            if $ret->[1]->{multiple};
        push(@$ret_test, map {[$next_node, $_]} @{$ret->[1]->{children}});
    }
    
    return "return 0;";
}

sub make_current_page {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $ret_test = [map {['', $_]} @{$method->{'return'}->{children}}];
    while (my $ret = shift(@$ret_test)) {
        next if $ret->[1]->{nullable};
        if ($ret->[1]->{page_current_page}) {
            my $strs = [];
            push(@$strs, "\$data =& \$this->getData();");
            my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
            push(@$strs, ($indstr x $indent) . "return $php_var;");
            return join("\n", @$strs);
        } elsif ($ret->[1]->{page_current_offset}) {
            my $orig = $ret->[1]->{page_current_offset_origin} ? " - $ret->[1]->{page_current_offset_origin}" : "";
            my $strs = [];
            push(@$strs, "\$data =& \$this->getData();");
            push(@$strs, ($indstr x $indent) . "\$epp = \$this->getEntriesPerPage();");
            push(@$strs, ($indstr x $indent) . "if (\$epp == 0) {");
            push(@$strs, ($indstr x ($indent + 1)) . "return 0;");
            push(@$strs, ($indstr x $indent) . "}");
            my $php_var = sprintf('$data%s->%s', $ret->[0], $ret->[1]->{name});
            push(@$strs, ($indstr x $indent) . "return (($php_var$orig) / \$epp) + 1;");
            return join("\n", @$strs);
        }
        next unless $ret->[1]->{children};
        my $next_node = $ret->[0].'->'.$ret->[1]->{name};
        $next_node .= '[0]'
            if $ret->[1]->{multiple};
        push(@$ret_test, map {[$next_node, $_]} @{$ret->[1]->{children}});
    }
    
    return "return 0;";
}

sub make_page_param {
    my ($method, $indent, $indstr) = @_;
    $indent ||= 0;
    $indstr ||= "    ";
    
    my $strs = [];
    
    foreach my $param (@{$method->{params}}) {
        if ($param->{page_param_number}) {
            push(@$strs, ($indstr x $indent) . "\$params['$param->{name}'] = \$page;");
        } elsif ($param->{page_param_offset}) {
            my $orig = $param->{page_param_offset_origin} ? " + $param->{page_param_offset_origin}" : "";
            push(@$strs, ($indstr x $indent) . "\$params['$param->{name}'] = (\$page - 1) * \$size$orig;");
        } elsif ($param->{page_param_size}) {
            push(@$strs, ($indstr x $indent) . "\$params['$param->{name}'] = \$size;");
        }
    }
    
    my $str = join("\n", @$strs);
    $str =~ s/^\s+//;
    
    return $str;
}

sub sort_keys {
    my $hashref = shift;
    return sort keys %$hashref;
}

sub env_param {
    return sub {
        my $val = shift;
        unless ($val =~ s/^\$(.*)$/getenv('$1')/) {
            $val = "'$val'";
        }
        return $val;
    };
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
    my $with_array = shift;
    return "" if $node->depth < 2;
    my $path = $node->path(2);
    my $access = [""];
    foreach my $p (@$path) {
        push(@$access, $p->name);
        $access->[-1] .= "[0]" if $p->multiple && ($with_array || $p != $node);
    }
    return join("->", @$access);
}

sub author_name {
    return sub {
        my $author = shift;
        my ($name, $email) = ($author =~ /^(.*?)\s+<(.*?)>$/);
        my $user = (split(/\@/, $email))[0];
        return $name;
    };
}

sub author_user {
    return sub {
        my $author = shift;
        my ($name, $email) = ($author =~ /^(.*?)\s+<(.*?)>$/);
        my $user = (split(/\@/, $email))[0];
        return $user;
    };
}

sub author_email {
    return sub {
        my $author = shift;
        my ($name, $email) = ($author =~ /^(.*?)\s+<(.*?)>$/);
        my $user = (split(/\@/, $email))[0];
        return $email;
    };
}

sub now_strftime {
    my $fmt = shift;
    return strftime($fmt, localtime());
}

1;
