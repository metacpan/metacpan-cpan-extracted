package XS::Install;
use strict;
use warnings;
use Config;
use Cwd qw/getcwd abs_path/;
use Exporter 'import';
use ExtUtils::MakeMaker;
use XS::Install::Deps;
use XS::Install::Util;
use XS::Install::Payload;

our $VERSION = '1.2.4';
my $THIS_MODULE = 'XS::Install';

our @EXPORT_OK = qw/write_makefile not_available/;
our @EXPORT;

if ($0 =~ /Makefile.PL$/) {
    @EXPORT = qw/write_makefile not_available/;
    _require_makemaker();
}

my $xs_mask  = '*.xs';
my $c_mask   = '*.c *.cc *.cpp *.cxx';
my $h_mask   = '*.h *.hh *.hpp *.hxx';
my $map_mask = '*.map';
my $win32    = $^O eq 'MSWin32';
my $linux    = $^O eq 'linux';
my $freebsd  = $^O eq 'freebsd';

sub write_makefile {
    _require_makemaker();
    
    my ($main_params, $test_params) = makemaker_args(@_);
    
    MY::init_methods();
    WriteMakefile(%$main_params);
    
    if ($test_params) {
        MY::init_methods();
        WriteMakefile(%$test_params);
    }
}

sub makemaker_args {
    my $params = ref($_[0]) eq 'HASH' ? $_[0] : {@_};
    _sync();
    die "You must define a NAME param" unless $params->{NAME};
    
    pre_process($params);
    process_FROM($params);
    process_REQUIRES($params);    
    process_BIN_DEPS($params);
    process_PARSE_XS($params);
    process_binary($params);
    process_PM($params);
    process_PAYLOAD($params);
    process_CLIB($params);
    process_BIN_SHARE($params);
    attach_BIN_DEPENDENT($params);
    warn_BIN_DEPENDENT($params);
    process_CPLUS($params);
    process_CCFLAGS($params);
    $params->{OPTIMIZE} = merge_optimize($Config{optimize}, '-O2', $params->{OPTIMIZE});
    process_LD($params);
    
    my $test_mm_args;
    if ($params->{_XSTEST}) {
        process_test_makefile($params);
    } else {
        $test_mm_args = process_test($params);
    }
    
    post_process($params);
    
    return ($params, $test_mm_args) if wantarray();
    return $params;
}

sub pre_process {
    my $params = shift;
    
    my $postamble = $params->{postamble};
    if ($postamble) {
        my $ref = ref $postamble;
        if    (!$ref)           { $postamble = [$postamble] }
        elsif ($ref eq 'HASH')  { $postamble = [values %$postamble] }
        elsif ($ref ne 'ARRAY') { die "postamble must be string or array ref" }
    }
    $postamble ||= [];
    $params->{postamble} = $postamble;

    $params->{clean} ||= {};
    $params->{clean}{FILES} ||= '';
    
    if (my $comp = ($ENV{COMPILER} || $ENV{CC})) {
        $params->{CC} = $comp;
    }
    
    if (my $opt = $ENV{OPTIMIZE}) {
        $params->{OPTIMIZE} = $opt;
    }
    
    canonize_array_split($params->{TYPEMAPS});
    canonize_array_split($params->{PARSE_XS});
    
    my $module_info = XS::Install::Payload::binary_module_info($params->{NAME}) || {};
    $params->{MODULE_INFO} = {
        BIN_DEPENDENT => $module_info->{BIN_DEPENDENT},
        SHARED_LIBS   => [],
        SELF_INC      => $params->{INC} || '',
    };
}

sub process_FROM {
    my $params = shift;
    my $module = $params->{NAME} or die "You must define a NAME param";
    
    if (my $file = delete $params->{ALL_FROM}) {
        $params->{VERSION_FROM}  = $file unless $params->{VERSION};
        $params->{ABSTRACT_FROM} = $file unless $params->{ABSTRACT};
    }
    
    my $pm = 'lib/'._pkg_file($module);
    my $pod = 'lib/'._pkg_slash($module).'.pod';
    
    $params->{VERSION_FROM}  ||= $pm unless $params->{VERSION};
    $params->{ABSTRACT_FROM} ||= (-f $pod) ? $pod : $pm unless $params->{ABSTRACT};
    
}

sub process_REQUIRES {
    my $params = shift;
    
    $params->{CONFIGURE_REQUIRES} ||= {};
    $params->{BUILD_REQUIRES} ||= {};
    
    $params->{TEST_REQUIRES} ||= {};
    $params->{TEST_REQUIRES}{'Test::Simple'} ||= '0.96';
    $params->{TEST_REQUIRES}{'Test::More'}   ||= 0;
    $params->{TEST_REQUIRES}{'Test::Deep'}   ||= 0;
    
    $params->{PREREQ_PM} ||= {};
    
    unless ($params->{NAME} eq $THIS_MODULE) { # skip when building XS::Install itself
        $params->{CONFIGURE_REQUIRES}{$THIS_MODULE} ||= $VERSION;
        $params->{PREREQ_PM         }{$THIS_MODULE} ||= $VERSION;
    }
}

sub process_PM {
    my $params = shift;
    return if $params->{PM}; # user-defined value overrides defaults
    
    my $instroot = _instroot($params);
    my @name_parts = split '::', $params->{NAME};
    $params->{PMLIBDIRS} ||= ['lib', $name_parts[-1]];
    my $pm = $params->{PM} = {};
    
    foreach my $dir (@{$params->{PMLIBDIRS}}) {
        next unless -d $dir;
        foreach my $file (_scan_files('*.pm *.pl *.pod', $dir)) {
            my $rel = $file;
            $rel =~ s/^$dir//;
            my $instpath = "$instroot/$rel";
            $instpath =~ s#[/\\]{2,}#/#g;
            $pm->{$file} = $instpath;
        }
    }
}

sub process_PAYLOAD {
    my $params = shift;
    my $payload = delete $params->{PAYLOAD} or return;
    _process_map($payload, '*');
    _install($params, $payload, 'payload');
}

sub process_BIN_DEPS {
    my $params = shift;
    my $bin_deps = delete $params->{BIN_DEPS};
    canonize_array_split($bin_deps);
    push @$bin_deps, $THIS_MODULE unless $params->{NAME} eq $THIS_MODULE;
    
    my $typemaps = $params->{TYPEMAPS};
    $params->{TYPEMAPS} = [];
    my $seen = {};
    _apply_BIN_DEPS($params, $_, $seen) for @$bin_deps;
    push @{$params->{TYPEMAPS}}, @$typemaps;
}

sub _apply_BIN_DEPS {
    my ($params, $module, $seen) = @_;
    my $stop_sharing;
    $stop_sharing = 1 if $module =~ s/^-//;
    
    return if $seen->{$module}++;
    
    my $installed_version = binary_module_version($module)
        or die "[XS::Install] binary dependency '$module' must be installed to proceed\n";
    $params->{CONFIGURE_REQUIRES}{$module}  ||= $installed_version;
    $params->{PREREQ_PM}{$module}           ||= $installed_version;
    $params->{MODULE_INFO}{BIN_DEPS}{$module} = $installed_version;
    push @{$params->{MODULE_INFO}{VISIBLE_BIN_DEPS} ||= []}, $module unless $stop_sharing;
    
    # add so/dll to linker list
    my $shared_list = $params->{MODULE_INFO}{SHARED_LIBS};
    my $module_path = $module;
    $module_path =~ s#::#/#g;
    die "SHOULDN'T EVER HAPPEN" unless $module =~ /([^:]+)$/;
    my $module_last_name = $1;
    foreach my $dir (@INC) {
        my $lib_path = "$dir/auto/$module_path/$module_last_name.$Config{dlext}";
        next unless -f $lib_path;
        push @$shared_list, abs_path($lib_path);
        last;
    }
    
    my $info = XS::Install::Payload::binary_module_info($module)
        or die "[XS::Install] this module wants '$module' as a binary dependence, however '$module' doesn't provide any binary interface\n";
    
    if ($info->{INCLUDE}) {
        my $incdir = XS::Install::Payload::include_dir($module);
        _string_merge($params->{INC}, "-I$incdir");
    }
    
    _string_merge($params->{INC},     $info->{INC});
    _string_merge($params->{CCFLAGS}, $info->{CCFLAGS});
    _string_merge($params->{DEFINE},  $info->{DEFINE});
    _string_merge($params->{XSOPT},   $info->{XSOPT});
    
    if (my $add_libs = $info->{LIBS}) {{
        last unless @$add_libs;
        my $libs = $params->{LIBS} or last;
        $libs = [$libs] unless ref($libs) eq 'ARRAY';
        if ($libs and @$libs) {
            my @result;
            foreach my $l1 (@$libs) {
                foreach my $l2 (@$add_libs) {
                    push @result, "$l1 $l2";
                }
            }
            $params->{LIBS} = \@result;
        }
        else {
            $params->{LIBS} = $add_libs;
        }
    }}
    
    if (my $passthrough = $info->{PASSTHROUGH}) {
        _apply_BIN_DEPS($params, $_, $seen) for @$passthrough;
    }
    
    if (my $typemaps = $info->{TYPEMAPS}) {
        my $tm_dir = XS::Install::Payload::typemap_dir($module);
        foreach my $typemap (@$typemaps) {
            my $tmfile = "$tm_dir/$typemap";
            $tmfile =~ s#[/\\]{2,}#/#g;
            push @{$params->{TYPEMAPS} ||= []}, $tmfile;
        }
    }
    
    $params->{CPLUS} = $info->{CPLUS} if $info->{CPLUS} and (!$params->{CPLUS} or $params->{CPLUS} < $info->{CPLUS});
    
    if (my $parsexs = $info->{PARSE_XS}) {
    	push @{$params->{PARSE_XS}||=[]}, @$parsexs;
    }
}

sub process_PARSE_XS { # inject ParseXS plugins into xsubpp
    my $params = shift;
    my $list = $params->{PARSE_XS};
    return unless @$list;
    _uniq_list($list);
    my $inc = join ' ', map { "-M$_" } @$list;
    push @{$params->{postamble}}, "XSUBPPRUN = \$(PERLRUN) -Ilib $inc \$(XSUBPP)";
}

sub process_binary {
    my $params = shift;

    $params->{XS}  ||= $params->{_XSTEST} ? [] : [_scan_files($xs_mask)];
    $params->{C}   ||= $params->{_XSTEST} ? [] : [_scan_files($c_mask)];
    
    canonize_array_split($params->{SRC});
    
    if (ref($params->{XS}) ne 'HASH') {
        canonize_array_files($params->{XS});
        $params->{XS} = { map {$_ => undef} @{$params->{XS}} };
    }

    foreach my $xsfile (keys %{$params->{XS}}, map { _scan_files($xs_mask, $_) } @{$params->{SRC}}) {
        next if $params->{XS}{$xsfile};
        my $cext = $params->{CPLUS} ? 'cc' : 'c';
        my $cfile = $xsfile;
        $cfile =~ s/\.xs$/.xs.$cext/ or next;
        $params->{XS}{$xsfile} = $cfile;

        my $suffix = $cfile;
        $suffix =~ s/^[^.]+//;
        
        my $xsi_deps = XS::Install::Deps::find_xsi_deps([$xsfile])->{$xsfile} || [];

        push @{$params->{postamble}}, "$cfile : $xsfile @$xsi_deps \$(FIRST_MAKEFILE)\n".
            "\t\$(XSUBPPRUN) \$(XSPROTOARG) \$(XSUBPPARGS) -csuffix $suffix \$(XSUBPP_EXTRA_ARGS) $xsfile > ${xsfile}c\n".
            "\t\$(MV) ${xsfile}c $cfile";
    }

    canonize_array_files($params->{C});
    push @{$params->{C}}, values %{$params->{XS}};
    push @{$params->{C}}, _scan_files($c_mask, $_) for @{$params->{SRC}};
    _uniq_list($params->{C});
    
    my $cdeps = XS::Install::Deps::find_header_deps({
        files   => $params->{C},
        headers => ['./'],
        inc     => [map { s/^-I//; $_ } split(' ', $params->{MODULE_INFO}{SELF_INC})],
    });
    
    canonize_array_files($params->{OBJECT});
    foreach my $cfile (@{$params->{C}}) {
        my $ofile = c2obj_file($cfile);
        push @{$params->{OBJECT}}, $ofile;
        
        my $deps = $cdeps->{$cfile};
        if ($deps && @$deps) {
            push @{$params->{postamble}},
                "$ofile : @$deps";
        }
    }
    _uniq_list($params->{OBJECT});
    delete $params->{H}; # prevent MM from making O_FILES depend on all H_FILES
    
    $params->{clean}{FILES} .= ' $(O_FILES)';
}

sub process_CLIB {
    my $params = shift;
    my $clibs = '';
    my $clib = delete $params->{CLIB} or return;
    $clib = [$clib] unless ref($clib) eq 'ARRAY';
    return unless @$clib;
    
    foreach my $info (@$clib) {
        my $build_cmd = $info->{BUILD_CMD};
        my $clean_cmd = $info->{CLEAN_CMD};
        
        unless ($build_cmd) {
            my $make = '$(MAKE)';
            $make = 'gmake' if $info->{GMAKE} and $^O eq 'freebsd';
            $info->{TARGET} ||= '';
            $info->{FLAGS} ||= '';
            $build_cmd = "$make $info->{FLAGS} $info->{TARGET}";
            $clean_cmd = "$make clean";
        }
        
        my $path = $info->{DIR}.'/'.$info->{FILE};
        $clibs .= "$path ";
        
        push @{$params->{postamble}}, "$path : ; cd $info->{DIR} && $build_cmd\n";
        push @{$params->{postamble}}, "clean :: ; cd $info->{DIR} && $clean_cmd\n" if $clean_cmd;
        push @{$params->{OBJECT}}, $path;
    }
    push @{$params->{postamble}}, "linkext:: $clibs";
}

sub process_BIN_SHARE {
    my $params = shift;
    my $bin_share = delete $params->{BIN_SHARE} or return;
    return unless %$bin_share;
    return if $params->{_XSTEST};
    
    my $typemaps = delete($bin_share->{TYPEMAPS}) || {};
    _process_map($typemaps, $map_mask);
    _install($params, $typemaps, 'tm');
    $bin_share->{TYPEMAPS} = [values %$typemaps] if scalar keys %$typemaps;
    
    my $include = delete($bin_share->{INCLUDE}) || {};
    _process_map($include, $h_mask);
    _install($params, $include, 'i');
    $bin_share->{INCLUDE} = 1 if scalar(keys %$include);
    
    $bin_share->{LIBS} = [$bin_share->{LIBS}] if $bin_share->{LIBS} and ref($bin_share->{LIBS}) ne 'ARRAY';
    
    if (my $list = $params->{MODULE_INFO}{BIN_DEPENDENT}) {
        $bin_share->{BIN_DEPENDENT} = $list if @$list;
    }
    
    if (my $vinfo = $params->{MODULE_INFO}{BIN_DEPS}) {
        $bin_share->{BIN_DEPS} = $vinfo if %$vinfo;
    }
    
    $bin_share->{PARSE_XS} = [$bin_share->{PARSE_XS}] if $bin_share->{PARSE_XS} and ref($bin_share->{PARSE_XS}) ne 'ARRAY';
    
    return unless %$bin_share;
    
    if (my $vbd = $params->{MODULE_INFO}{VISIBLE_BIN_DEPS}) {
        my $pt = 
        _uniq_list($vbd);
        $bin_share->{PASSTHROUGH} = $vbd;
    }
    
    $bin_share->{LOADABLE} = has_binary($params);
    
    $bin_share->{CPLUS} //= $params->{CPLUS} if $params->{CPLUS};
    
    # generate info file
    mkdir 'blib';
    my $infopath = 'blib/info';
    XS::Install::Util::module_info_write($infopath, $bin_share);
    _install($params, {$infopath => 'info'}, '');
}

sub attach_BIN_DEPENDENT {
    my $params = shift;
    my @deps = keys %{$params->{MODULE_INFO}{BIN_DEPS} || {}};
    return unless @deps;
    
    push @{$params->{postamble}}, "sync_bin_deps:\n".
        "\t\$(PERL) -M${THIS_MODULE}::Util -e '${THIS_MODULE}::Util::cmd_sync_bin_deps()' $params->{NAME} @deps";
    push @{$params->{postamble}}, "install :: sync_bin_deps";
}

sub warn_BIN_DEPENDENT {
    my $params = shift;
    return unless $params->{VERSION_FROM};
    my $module = $params->{NAME};
    return if $module eq $THIS_MODULE;
    my $list = $params->{MODULE_INFO}{BIN_DEPENDENT} or return;
    return unless @$list;
    my $installed_version = binary_module_version($module) or return;
    my $new_version = MM->parse_version($params->{VERSION_FROM}) or return;
    return if $installed_version eq $new_version;
    warn << "EOF";
******************************************************************************
$THIS_MODULE: There are XS modules that binary depend on current XS module $module.
They were built with currently installed $module version $installed_version.
If you install $module version $new_version, you will have to reinstall all XS modules that binary depend on it:
cpanm -f @$list
******************************************************************************
EOF
}

sub process_CPLUS {
    my $params = shift;
    my $use_cpp = $params->{CPLUS} or return;
    
    my $cppv = int($use_cpp);
    $cppv = 11 if $cppv < 11;
    _string_merge($params->{CCFLAGS}, "-std=c++$cppv");
        
    $params->{CC} = _get_cplusplus($params->{CC}, $cppv);
    $params->{LD} ||= '$(CC)';
    _string_merge($params->{XSOPT}, '-C++');
    
    # prevent C++ from compile errors on perls <= 5.18, as perl had buggy <perl.h> prior to 5.20
    _string_merge($params->{CCFLAGS}, "-Wno-reserved-user-defined-literal -Wno-literal-suffix -Wno-unknown-warning-option") if $^V < v5.20;
}

sub process_CCFLAGS {
    my $params = shift;
    _string_merge($params->{CCFLAGS}, '-o $@');
    $params->{CCFLAGS} = "$Config{ccflags} $params->{CCFLAGS}" if $params->{CCFLAGS};
    _string_merge($params->{CCFLAGS}, '-Wno-unused-parameter') if $win32; # on Strawberry's mingw PERL_UNUSED_DECL doesn't work
}

sub process_LD {
    my $params = shift;

    $params->{LDFROM} ||= '$(OBJECT)';
    
    if ($^O ne 'darwin') { # MacOSX doesn't allow for linking with bundles :(
        my %seen;
        my @shared_libs = grep {!$seen{$_}++} reverse @{$params->{MODULE_INFO}{SHARED_LIBS}};
        my $str = join(' ', @shared_libs);
        $params->{MODULE_INFO}{SHARED_LIBS_LINKING} = $str;
        $params->{LDFROM} .= ' '.$str if $str;
    }
}

sub process_test {
    my $params = shift;
    my $tp = $params->{test} or return;
    return unless $tp->{SRC} or $tp->{XS};
    
    canonize_array_split($tp->{$_}) for qw/TYPEMAPS BIN_DEPS/;

    my $array_merge = sub {
        my $a1 = shift || [];
        my $a2 = shift || [];
        return [@$a1, @$a2];
    };
    
    my %args = (
        NAME      => $tp->{NAME} || 'MyTest',
        VERSION   => $tp->{VERSION} || '0.0.0',
        ABSTRACT  => "test module",
        SRC       => $tp->{SRC},
        XS        => $tp->{XS},
        BIN_DEPS  => $array_merge->([keys %{$params->{MODULE_INFO}{BIN_DEPS}||{}}], $tp->{BIN_DEPS}),
        TYPEMAPS  => $array_merge->($params->{TYPEMAPS}, $tp->{TYPEMAPS}),
        CPLUS     => $tp->{CPLUS} // $params->{CPLUS},
        CC        => $tp->{CC} || $params->{CC},
        LD        => $tp->{LD} || $params->{LD},
        LDFROM    => '$(OBJECT) '.module_so($params),
        INC       => string_merge($params->{MODULE_INFO}{SELF_INC}, $tp->{INC}),
        CCFLAGS   => string_merge($params->{CCFLAGS}, $tp->{CCFLAGS}),
        DEFINE    => string_merge($params->{DEFINE}, $tp->{DEFINE}),
        XSOPT     => string_merge($params->{XSOPT}, $tp->{XSOPT}),
        LIBS      => $params->{LIBS},
        MAKEFILE  => 'Makefile.test',
        OPTIMIZE  => merge_optimize($params->{OPTIMIZE}, "-O0", $tp->{OPTIMIZE}, $ENV{TEST_OPTIMIZE}),
        PARSE_XS  => $tp->{PARSE_XS} || $params->{PARSE_XS},
        XS        => {},
        NO_MYMETA => 1,
        _XSTEST   => 1,
    );
    
    my $make_params = '';
    $make_params .= ' --no-print-directory' if $linux;
    my $cmd = "\@\$(MAKE)$make_params -f Makefile.test";
    
    push @{$params->{postamble}},
        '# --- XS::Install tests compilation section',
        "ctest_object : ; $cmd object",
        "ctest_ld : ctest_object \$(INST_DYNAMIC); $cmd",
        'subdirs-test_dynamic :: ctest_object ctest_ld',
        'ctest :: ctest_object ctest_ld',
        "clean :: ; $cmd veryclean",
    ;
    
    my $mm_args = makemaker_args(%args);
    return has_binary($mm_args) ? $mm_args : undef;
}

sub process_test_makefile {
    my $params = shift;
    push @{$params->{postamble}}, 'object : $(OBJECT)';
}

sub post_process {
    my $params = shift;
    my $postamble = $params->{postamble};
    my $mi = $params->{MODULE_INFO};
    
    delete @$params{qw/C H OBJECT XS CCFLAGS LDFROM OPTIMIZE XSOPT/} unless has_binary($params);
    delete @$params{qw/CPLUS PARSE_XS SRC MODULE_INFO _XSTEST/};
    
    # convert array to hash for postamble
    $params->{postamble} = {};
    my $i = 0;
    $params->{postamble}{++$i} = $_ for @$postamble;
}

sub canonize_array {
    if    (!$_[0])                { $_[0] = [] }
    elsif (ref($_[0]) ne 'ARRAY') { $_[0] = [$_[0]] }
}

sub canonize_array_split {
    canonize_array($_[0]);
    @{$_[0]} = map { split ' ' } @{$_[0]};
}

sub canonize_array_files {
    canonize_array_split($_[0]);
    @{$_[0]} = map { glob } @{$_[0]};
}

# returns version of binary module which was installed with XS::Install without loading it
sub binary_module_version {
    my $module = shift;
    # user might use his own module for it's Makefile.PL (very rare case but possible, for example this module does it)
    # to avoid finding it, and find only installed pm, we must se if it has data dir (Module.x) in the same folder
    # so we will just find the data folder and get the pm from there
    my $ddir = XS::Install::Payload::data_dir($module) or return 0;
    my $pm = $ddir;
    $pm =~ s#\.x$#.pm#;
    return 0 unless -f $pm;
    return MM->parse_version($pm) || 0;
}

sub has_c      { return $_[0]->{C} && scalar(@{$_[0]->{C}}) ? 1 : 0 }
sub has_object { return $_[0]->{OBJECT} && scalar(@{$_[0]->{OBJECT}}) ? 1 : 0 }
sub has_xs     { return $_[0]->{XS} && scalar(keys %{$_[0]->{XS}}) ? 1 : 0 }
sub has_binary { return has_c($_[0]) || has_object($_[0]) || has_xs($_[0]) }

sub merge_optimize {
    my $to = shift;
    $to ||= '';
    my @singleton = (qr/-O[0-9]/, qr/-g[0-9]?/);
    foreach my $from (@_) {
        next unless $from;
        foreach my $tok (split ' ', $from) {
            foreach my $qr (@singleton) {
                next unless $tok =~ /^$qr$/;
                $to =~ s/(^|\s)$qr(\s|$)/ /g;
            }
            $to .= " $tok";
        }
    }
    $to =~ s/^\s+//;
    $to =~ s/\s+$//;
    $to =~ s/\s{2,}/ /g;
    return $to;
}

sub _install {
    my ($params, $map, $path) = @_;
    return unless %$map;
    my $instroot = _instroot($params);
    my $pm = $params->{PM} ||= {};
    while (my ($source, $dest) = each %$map) {
        my $instpath = "$instroot/\$(FULLEXT).x/$path/$dest";
        $instpath =~ s#[/\\]{2,}#/#g;
        $pm->{$source} = $instpath;
    }
}

sub _instroot { return has_binary($_[0]) ? '$(INST_ARCHLIB)' : '$(INST_LIB)' }

sub module_so {
    my $params = shift;
    return undef unless has_binary($params);
    return _instroot($params).'/auto/'._pkg_slash($params->{NAME}).'/'._pkg_last($params->{NAME}).'.'.$Config{dlext};
}

sub _sync {
    no strict 'refs';
    my $from = 'MYSOURCE';
    my $to = 'MY';
    foreach my $method (keys %{"${from}::"}) {
        next unless defined &{"${from}::$method"};
        *{"${to}::$method"} = \&{"${from}::$method"};
    }
}

sub _scan_files {
    my ($mask, $dir) = @_;
    return grep {_is_file_ok($_)} glob($mask) unless $dir;
    
    my @list = grep {_is_file_ok($_)} glob(join(' ', map {"$dir/$_"} split(' ', $mask)));
    
    opendir(my $dh, $dir) or die "Could not open dir '$dir' for scanning: $!";
    while (my $entry = readdir $dh) {
        next if $entry =~ /^\./;
        my $path = "$dir/$entry";
        next unless -d $path;
        push @list, _scan_files($mask, $path);
    }
    closedir $dh;
    
    return @list;
}

sub _is_file_ok {
    my $file = shift;
    return unless -f $file;
    return if $file =~ /\#/;
    return if $file =~ /~$/;             # emacs temp files
    return if $file =~ /,v$/;            # RCS files
    return if $file =~ m{\.swp$};        # vim swap files
    return 1;
}

sub _process_map {
    my ($map, $mask) = @_;
    foreach my $source (keys %$map) {
        my $dest = $map->{$source} || $source;
        if (-f $source) {
            $dest .= $source if $dest =~ m#[/\\]$#;
            $dest =~ s#[/\\]{2,}#/#g;
            $dest =~ s#^[/\\]+##;
            $map->{$source} = $dest;
            next;
        }
        next unless -d $source;
        
        delete $map->{$source};
        my @files = _scan_files($mask, $source);
        foreach my $file (@files) {
            my $dest_file = $file;
            $dest_file =~ s/^$source//;
            $dest_file = "$dest/$dest_file";
            $dest_file =~ s#[/\\]{2,}#/#g;
            $dest_file =~ s#^[/\\]+##;
            $map->{$file} = $dest_file;
        }
    }
}

sub _uniq_list {
	my $list = shift;
	my %uniq;
	@$list = grep { !$uniq{$_}++ } @$list;
}

sub _string_merge {
    return unless $_[1];
    $_[0] ||= '';
    $_[0] .= $_[0] ? " $_[1]" : $_[1];
}

sub string_merge {
    my $s = shift;
    $s //= '';
    $s .= ($_ // '') for @_;
    return $s;
}

sub c2obj_file {
    my $file = shift;
    $file =~ s/\.[^.]+$//;
    return $file.'$(OBJ_EXT)';
}

{
    package
        MY;
    use Config;

    my $gcc_compliant = $Config{cc} =~ /\b(gcc|clang)\b/i ? 1 : 0;
    
    sub init_methods {
        no warnings 'redefine';
        
        *postamble = sub {
            my $self = shift;
            my %args = @_;
    
            my @list;        
            my $i = 1;
            while (1) {
                last unless exists $args{$i};
                push @list, $args{$i};
                ++$i;
            }
            
            return join("\n\n", @list);
        };
        
        if ($freebsd) { # freebsd's make has a bug: wrong value of $* when building in parallel, we use $< instead
            *c_o = sub {
                my $self = shift;
                my $ret = $self->SUPER::c_o(@_);
                $ret =~ s/\$\*\.c(c|pp|xx)?[ \t]*$/\$</gism;
                return $ret;
            };
        }
        
        if ($win32) {
            *dynamic_lib = sub {
                my ($self, %attribs) = @_;
                my $code = $self->SUPER::dynamic_lib(%attribs);
                
                unless ($gcc_compliant) {
                    warn(
                        "$THIS_MODULE: to maintain UNIX-like shared library behaviour on windows (export all symbols by default), we need gcc-compliant linker. ".
                        "$THIS_MODULE-dependant modules should only be installed on perls with MinGW shell (like strawberry perl), or at least having gcc compiler. ".
                        "I will continue, but this module's binary dependencies may not work."
                    );
                    return $code;
                }
                return $code unless $code;
        
                # remove .def-related from code, remove double DLL build, remove dll.exp from params, add export all symbols param.
                my $DLLTOOL = $Config{dlltool} || 'dlltool';
                my (@out, $last_ld);
                map { $last_ld = $_ if /\$\(LD\)\s/ } split /\n/, $code;
                foreach my $line (split /\n/, $code) {
                    next if $line =~ /$DLLTOOL/; # drop dlltool calls (we dont need .def file)
                    if ($line =~ /\$\(LD\)\s/) {
                        next if $line ne $last_ld;
                        $line =~ s/\$\(LD\)\s/\$(LD) -Wl,--export-all-symbols /;
                        $line =~ s/\bdll\.exp\b//;
                    }
                    $line =~ s/\$\(EXPORT_LIST\)//g; # remove <PACKAGE>.def from target dependency
                    push @out, $line;
                }
                
                $code = join("\n", @out);
                return $code;
            };
            
            *dlsyms = sub {
                my ($self, %attribs) = @_;
                return '' if $gcc_compliant; # our dynamic_lib target doesn't need any .def files with gcc
                return $self->SUPER::dlsyms(%attribs);
            };
        };
    }
}

sub _require_makemaker {
    unless ($INC{'ExtUtils/MakeMaker.pm'}) {
        require ExtUtils::MakeMaker;
        ExtUtils::MakeMaker->import();
    }
}

sub not_available {
    my $msg = shift;
    die "OS unsupported: $msg\n";
}

sub _get_cplusplus {
    my ($cpp, $minstd) = @_;
    $cpp ||= 'c++'; # exists on most platforms/compilers
    
    # check compiler existance
    my $v_out = `$cpp -v 2>&1`;
    not_available("C++ compiler not available") unless defined $v_out;
    
    #check if C++ compiler supports -std=XXX
    mkdir 'tmp';
    my $tmpfile = 'tmp/__xs_install_check_cpp.cc';
    my $outfile = 'tmp/__xs_install_check_cpp.out';
    if (open my $fh, '>', $tmpfile) {
        print $fh "int main () { return 0; }\n";
        close $fh;
        unlink $outfile;
        `$cpp -c -std=c++$minstd -o $outfile $tmpfile 2>&1`;
        my $success = -f $outfile;
        unlink $tmpfile, $outfile;
        rmdir 'tmp';
        not_available("C++ compiler does not support -std=c++$minstd") unless $success;
    }
    
    #check exceptions
    not_available(
        "SJLJ compiler detected\n".
        "***************************************************************\n".
        "You are using c++ compiler with SJLJ exceptions enabled.\n".
        "It makes it impossible to use C++ exceptions and perl together.\n".
        "You need to use compiler with DWARF2 or SEH exceptions configured.\n".
        "If you are using Strawberry Perl, install Strawberry 5.26 or higher\n".
        "where they use mingw with SEH exceptions.\n".
        "***************************************************************"
    ) if $v_out =~ /--enable-sjlj-exceptions/;
    
    return $cpp;
}

sub _pkg_slash {
    my $pkg = shift;
    $pkg =~ s#::#/#g;
    return $pkg;
}

sub _pkg_last {
    my $pkg = shift;
    return unless $pkg =~ /([^:]+)$/;
    return $1;
}

sub _pkg_file { return _pkg_slash(shift).'.pm'  }

1;
