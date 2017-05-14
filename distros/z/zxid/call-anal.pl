#!/usr/bin/perl
# $Id: call-anal.pl,v 1.8 2009-08-25 16:22:44 sampo Exp $
# 16.6.2003, Sampo Kellomaki <sampo@iki.fi>
# 25.6.2003, fixed C++ destructor handling, improved origin centered call graphs --Sampo
# 14.12.2003, added function number initialization facility --Sampo
# 4.10.2008,  added capability to extract documentation comments --Sampo
# 2.6.2009,   optimize away single node call graphs --Sampo
#
# Perform total call graph analysis
#  - produce graph with graphviz
#  - annotate the source with comments to effect /* Called by: ... */
#
# Some simplifying assumptions are made:
#  - Function calls are assumed to be of form
#        func(...), or
#        name::space::func(...), or
#        ->func(...), or
#        .func(...)
#  - Function definitions are assumed to be of form
#        type func(struct...
#        type func(int...
#        type func(void...

$usage = <<USAGE;
Usage: ./call-anal.pl [opts] */*.c */*.cc >graph.dot
        -n  perform simulation, do not alter the source

dot -Tps graph.dot -o graph.ps && gv graph.ps
http://www.research.att.com/sw/tools/graphviz/download.html
USAGE
    ;

$project = 'ZXID';

$dot_header = <<DOT;
// Generated graph. Do not edit. Any changes will be lost.
// dot -Tps graph.dot -o graph.ps && gv graph.ps
// http://www.research.att.com/sw/tools/graphviz/download.html
DOT
    ;

$write = 1;
if ($ARGV[0] eq '-n') {
    shift;
    $write = 0;
}
die $USAGE if $ARGV[0] =~ /^-/;
undef $/;

# Function at origin of graph => call depth from the function
#%local_graphs = ( main => 6,     # the start
#		  yyparse => 3,  # center of compiler
#		  );
%local_graphs = ( hi_shuffle => 10,
		  zxbus_listen_msg => 4,
		  zxid_simple_cf => 4);

# N.B. names in all upper case, i.e. macros, are always ignored
@ignore_callee = qw(for if return sizeof switch while);
push @ignore_callee,
    qw(accept atoi close fclose fcntl fprintf fputs ftruncate free
       getpid getuid getegid htons htonl getenv gmtime_r inetaton
       lseek dlsym dlopen
       malloc memchr memcpy memcmp memmove memset mmap munmap
       new open printf poll
       closedir opendir rewinddir pow
       perror pthread_mutex_init pthread_mutex_lock pthread_mutex_unlock
       pthread_cancel pthread_detach pthread_setcanceltype pthread_setspecific
       read sleep sort sprintf strcat strchr strcmp strcpy strdup strerror
       sscanf strlen strncmp strncpy strspn strtok toupper tolower
       va_end va_start vprintf vsnprintf vsprintf vsyslog
       write writev);

push @ignore_callee,
    qw(name_from_path vname_from_path open_fd_from_path vopen_fd_from_path close_file
       zx_CreateFile write_all_fd write_all_fd_fmt
       write_all_path_fmt write2_or_append_lock_c_path
       read_all_fd read_all hexdump read_all_alloc get_file_size
       sha1_safe_base64 zxid_nice_sha1
       zx_strf zx_ref_str zx_ref_len_str zx_dup_str zx_dup_len_str zx_dup_cstr
       zx_new_len_str zx_str_to_c
       zx_ref_attr zx_ref_len_attr zx_attrf zx_dup_attr zx_dup_len_attr
       zx_new_str_elem zx_ref_elem zx_ref_len_elem
       zx_url_encode zx_url_encode_len zx_url_encode_raw unbase64_raw
       zx_rand zx_report_openssl_err zx_memmem zxid_mk_self_sig_cert zxid_extract_private_key );

push @ignore_callee,
    qw(hi_pdu_alloc hi_dump nonblock setkernelbufsizes zxid_get_ent_ss zx_pw_authn
       xmtp_decode_resp test_ping http_decode smtp_decode_req smtp_decode_resp );

push @ignore_callee, qw(new_zx_ei);

select STDERR; $|=1; select STDOUT;

sub process_func {
    my ($fn, $func, $body) = @_;
    #warn "process_func($fn,$func,".length($body).")";
    $func =~ s/^~/D_/;
    push @{$def{$func}}, $fn;     # where is function defined
    push @{$funcs_in_file{$fn}}, $func;
      
    ### Analyze body to detect function calls: first eliminate confusing junk
    
    $body =~ s{/\*.*?\*/}{}gs;    # strip comments
    $body =~ s{"[^\n\"]+?"}{}gs;  # strip strings (debug output)
    $body =~ s{if\s*\(}{}gs;
    $body =~ s{while\s*\(}{}gs;
    $body =~ s{for\s*\(}{}gs;
    $body =~ s{switch\s*\(}{}gs;
    
    #                        01     1     0
    @func_calls = $body =~ m%((~?\w+)\s*\()%sg;
    while (@func_calls) {
	$callee = $func_calls[1];
	next if $callee =~ /^[A-Z0-9_]+$/;   # Ignore macros
	next if $callee =~ /^[A-Z0-9_]{3,}/; # Ignore all caps starts
	next if grep $callee eq $_, @ignore_callee;
	$callee =~ s/^~/D_/;
	#warn "zxlex2() body: >$callee< >>$func_calls[0]<<" if $func eq 'zxlex2';
	$called_by{$callee}{$func}++;
	$calls{$func}{$callee}++;
	#warn "zx_scan_identifier x zxlex2: `$called_by{$callee}{$func}' `$calls{$func}{$callee}'" if ($func eq 'zxlex2') && ($callee eq 'zx_scan_identifier');
	$fnf{$fn}{$func}{$callee}++;
	#warn "fn=$fn func=$func callee=$callee: $fnf{$fn}{$func}{$callee}";
    } continue {
	splice @func_calls, 0, 2;
    }
}

#$watch1 = 'zxid_extract_issuer';        # zxiddec.c
#$watch2 = 'zxid_decode_redir_or_post';  # zxiddec.c

sub process_doc {
    my ($fn, $func, $doc_flag, $doc, $params) = @_;
    return if $doc_flag =~ /-/;   # (-) suppresses function from documentation
    warn "DOC1 FUNC($func) ($doc)" if $func eq $watch1 || $func eq $watch2;
    #$doc =~ s/\n\/\*\sCalled\sby:[^\*\/]*?\*\/)?//;
    $doc =~ s/\n\/\*\sCalled\sby:.*$//s;
    warn "DOC2($doc)" if $func eq $watch1 || $func eq $watch2;
    $doc =~ s/\*\/$//gs;
    warn "DOC3($doc)" if $func eq $watch1 || $func eq $watch2;
    $doc =~ s/\n ?\* ?/\n/gs;
    warn "DOC4($doc)" if $func eq $watch1 || $func eq $watch2;
    $local_graphs{$func} = 1;  # Cause call graph (2 deep) to be generated for this function
    ++$n_fn;
    $params =~ s%\/\*.*?\*\/%%g; # zap comments
    my @param = split /\s*,\s*/, $params;
    for $_ (@param) {
	s%^[\w\*:\[\]\s\/.&]+?[\t ]+\**(\w+)[\[\]]*([\t ]*=[\w:.-]*?)?$%$1%g;
    }
    $params = join ', ', @param;
    my $javaname = $func;
    $javaname =~ s%^zxid_%%;
    $javaname = "Java name: zxidjni.$javaname()";
    my $perlname = $func;
    $perlname =~ s%^zxid_%%;
    $perlname = "Perl name: Net::SAML::$perlname()";
    my $src_file = "Source file: $fn" unless $no_srcfile;
    #<<img: $func-call,H,: Call graph for $func()>>
    my $img = qq(<<img: $func-call,R: >>) if $call_size{$func};
    open F, ">ref/$func.pd" or die "Can't write(ref/func.pd): $!";
    print F <<PD;
1.3.$n_fn $func($params)
~~~~~~~~~~~~~~~~~~~~

$doc

$javaname

$perlname

$src_file

$img

PD
;
    close F;

    $doc{$func} = $doc;
    ++$func{$func};
    ++$important{$func} if $doc_flag =~ /i/;
    ++$struct{$func}    if $doc_flag =~ /s/;
}

sub match_funcs {
    my ($x) = @_;

    # 0=whole match, 1=proto, 2=ret type, 3=rtc, 4=name, 5=namespace, 6=local name, 7=params, 8=body
    #            0123               3 245     5 6   64 .7                    7 ,1    :8   8   ;0
    #@fx = $x =~ /(((([\w\*:\[\]]+\s+)+)((\w+::)*(\w+))\(([\w\(\)\*:\[\],\s]*?)\))\s*\{(.+?)\n\})/sg;  # version 1, requires comment removal
    
    # 0=whole match, 1=proto, 2=ret type, 3=name, 4=namespace, 5=local name, 6=params, 7=body
    #                                             0  12                  2                              34     4 5   53       .6                    6 ,1                                                 :7   7   ;0
    #@fx = $x =~ m%(?:\n/\* Called by:[^\*/]*?\*/)?(\n((\w[\w\*:\[\] \t]+?)(?:[ \t]*/\*[^\*/\n]*?\*/)?\s+((\w+::)*(\w+))[ \t]*\(([\w\*:\[\],\s/.&=]*?)\))\s*(?:YYPARSE_PARAM_DECL)?(?:/\*[^\*/]*?\*/)?\s*\{(.+?)\n\})%sg;  # version 2, comment tolerant
    
    # a-z0-9*/ \n:;,.!?<>(){}\[\]\#=~-     ((?:[^\*/]+[\*/]?)+)
    # perl seg faults on: ((?:[^/]+?/?)+)
    #              (?:\s*?\n)*                         (?# Potential empty lines )

    if (0) {
    my @fx = $x =~
	#       /*() Doc string           */
	m<(?:\n\/\*\((\w*)\)\s*([^{}]+?)\*\/)? (?# 0=doc-flag, 1=doc )
                  (\n\n?(                             (?# 2=whole, 3=proto )
                      (\w[\w\*:\[\] \t]+?)            (?# 4=ret type spec)
                      (?:[ \t]*\/\*[^\*\/\n]*?\*\/)?\s+  (?# ignore /* some comment */ )
                      ((\w+::)*(\w+))                 (?# 5=full name, 6=namespace, 7=localname )
                      [ \t]*\(                        (?# start parameter list )
                      ([\w\*:\[\],\s\/.&=]*?) \)      (?# 8=the parameters )
                     )\s*                             (?# close 3-proto )
                     (?:YYPARSE_PARAM_DECL)?          (?# Whatever? )
                     (?:\/\*[^\*\/]*?\*\/)?           (?# Comments between proto and body )
                     \s*\{(.+?)\n\}                   (?# 9=body )
                  )>gsx;  # close 2-whole  ;; version 3, plaindoc and comment tolerant
    }
    my @fx = $x =~
	#       /*() Doc string              */
	m<(?:\n\/\*\(([\w-]*)\)\s*([^{}]+?)\*\/)?     (?# 0=doc-flag, 1=doc )
                  (\n\n?(                             (?# 2=whole, 3=proto )
                      (\w[\w\*:\[\] \t]+?)            (?# 4=ret type spec)
                      (?:[ \t]*\/\*[^\*\/\n]*?\*\/)?\s+  (?# ignore /* some comment */ )
                      ((\w+::)*(\w+))                 (?# 5=full name, 6=namespace, 7=localname )
                      [ \t]*\((                       (?# start parameter list-8 )
                        (?:\s*[\w\*:\[\]\s\/.&]*?[\t ]+   (?# param type )
                           \**\w+[\t \[\]=\w:.-]*,?   (?# param_name[] = default assignment?, )
                           (?:\s*\/\*[^{}]*?\*\/)? )+ (?# /* param comment */? )
                        (?:\s*\.\.\.)?                (?# more va params ... )
                      \s*)\))\s*                      (?# close 8-parameters, close 3-proto )
                     (?:YYPARSE_PARAM_DECL)?          (?# Whatever? )
                     (?:\/\*[^{}]*?\*\/)?             (?# Comments between proto and body )
                     \s*\{(.+?)\n\}                   (?# 9=body )
                  )>gsx;  # close 2-whole  ;; version 3, plaindoc and comment tolerant
    return @fx;
}

# Process files, grabbing what looks like function calls
# and what looks like function definitions

$0 = "reading input";
for $fn (@ARGV) {
    next if $fn =~ /~$/;  # Ignore backups
    next if $fn =~ /CVS/; # Ignore files in CVS special directories
    open F, "<$fn" or die "Can't read `$fn': $!";
    $x = <F>;
    close F;
    warn "Analyzing $fn...\n";
    
    #$x =~ s{/\*.*?\*/}{}gs;  # strip comments
    
    @fx = match_funcs($x);
    
    # Constructors and destructors  *** this probably needs update to account for plaindoc
    # 0=whole match, 1=proto, 2=name, 3=namespace, 4=local name, 5=params, 6=body
    #                                             0  123   3  4    42       .5                    5 ,1                          :6   6   ;0
    @fy = $x =~ m%(?:\n/\* Called by:[^\*/]*?\*/)?(\n(((\w+)::(~?\4))[ \t]*\(([\w\*:\[\],\s/.&=]*?)\))\s*(?:/\*[^\*/]*?\*/)?\s*\{(.+?)\n\})%sg;  # version 2, comment tolerant
    
    while (@fx) {
	#warn "  $fx[4]()\n";
#WHOLE >>$fx[3]<<
#BODY: >$fx[9]<
	print <<DEBUG if 0;
FX =================================================================
DOCFLAG: >>$fx[0]<<
DOC: >>$fx[1]<<
PROTO: >$fx[3]<
RET TYPE: >$fx[4]<
NAME: >$fx[5]<
NAMESPACE: >$fx[6]<
LOCALNAME: >$fx[7]<
PARAMS: >$fx[8]<

DEBUG
    ;
	process_func($fn, $fx[7], $fx[9]);
	warn "fx($fx[7]) static?($fx[4])";
	#process_doc($fn, $fx[7], $fx[0], $fx[1], $fx[8]) if $fx[1] || $fx[4] !~ /^static /;
	splice @fx, 0, 10;
  }

  while (@fy) {
      #warn "  $fy[4]()\n";
#WHOLE >>$fy[0]<<
#BODY >>$fy[6]<<
      print <<DEBUG if 0;
FY =================================================================
WHOLE >>$fy[0]<<
PROTO: >$fy[1]<
NAME: >$fy[2]<
NAMESPACE: >$fy[3]<
LOCALNAME: >$fy[4]<
PARAMS: >$fy[5]<

DEBUG
    ;
      process_func($fn, $fy[4], $fy[6]);
      splice @fy, 0, 7;
  }
}

$callee = 'zx_scan_id';
$func = 'zxlex2';
#warn "zx_scan_id x zxlex2: `$called_by{$callee}{$func}' `$calls{$func}{$callee}'";

$0 = "generating output";
warn "Generating output...\n";

open F, ">function.list" or die "Cant write function.list: $!";
print F map qq(ZXFUNC_DEF("$_","$def{$_}[0]")\n), sort keys %def;
close F;

open F, ">file.list" or die "Cant write file.list: $!";
print F map qq(ZXFILE_DEF("$_")\n), sort keys %fnf;
close F;

print "$dot_header\n// Files of definition\n// =====\n";

for $k (sort keys %def) {
    print "// $k:\t" . join(',', @{$def{$k}}) . "\n";
}

print "\n// Called by\n// =========\n";

for $callee (sort keys %called_by) {
    $s = '';
    for $k (sort keys %{$called_by{$callee}}) {
	$s .= "$k $called_by{$callee}{$k}, ";
    }
    chop $s; chop $s;
    print "// $callee:\t$s\n";
}

###
### Draw the call graph
###

print <<DOT;
digraph CALL_GRAPH {
rankdir=LR;
ratio=compress;
//size="10,7"; orientation=landscape;
//size="7,10";
//ranksep=2;
//nodesep=0.1;
//page="8,11";
compound=true;
concentrate=true;

DOT
    ;
$0 = "generating dot";
for $fn (sort keys %fnf) {
    ($fn2 = $fn) =~ tr[A-Za-z0-9][_]c;
    print "subgraph cluster_$fn2 {\n  label=\"$fn\";\n";
    for $f (sort keys %{$fnf{$fn}}) {
	next if !$def{$f};
	if ($f =~ /^zxvm/) {
	    print "  $f [style=filled,color=red];\n";  # [shape=box]
	} elsif ($f =~ /^zx/) {
	    print "  $f [style=filled,color=yellow];\n";  # [shape=box]
	} elsif ($f eq 'main') {
	    print "  $f [style=filled,color=red, shape=octagon];\n";  # [shape=box]
	} else {
	    print "  $f;\n";  # [shape=box]
	}
	for $c (sort keys %{$fnf{$fn}{$f}}) {
	    if ($fnf{$fn}{$f}{$c} > 1) {
		print "  $f -> $c [label=\"$fnf{$fn}{$f}{$c}\"];\n";
	    } else {
		print "  $f -> $c;\n";
	    }
	}
    }
    print "}\n\n";
}

print "}\n\n//EOF\n";

###
### Draw function oriented call graphs (recursive by level)
###

# Generate files listing such that its not too wide

sub gen_files {
    my ($f) = @_;
    my $fns = '';
    my $n = 1;
    for $fn (@{$def{$f}}) {
	$fns .= $fn;
	if ($n++ % 2) {
	    $fns .= ", ";
	} else {
	    $fns .= ",%";
	}
    }
    chop $fns; chop $fns;
    $fns =~ s/%/\\n/g;
    return $fns;
}

sub render_level {
    my ($point, $level) =@_;
    my %seen_here = ();
    my $callee;
    my $size = 0;  # Size of the call graph 

    return 0 if !$level;
    
    for $callee (sort keys %{$calls{$point}}) {
	next if !$def{$callee};
	next if $seen{$callee};
	++$size;
	$seen{$callee} = 1;
	$seen_here{$callee} = 1;
	$files = gen_files($callee);
	if ($level == $local_graphs{$origin}) {
	    print F "$callee [style=filled,color=yellow,label=\"$callee\\n<$files>\"];\n";
	} else {
	    print F "$callee [label=\"$callee\\n<$files>\"];\n";
	}
    }
    
    for $callee (sort keys %{$calls{$point}}) {
	next if !$def{$callee};
	if ($level) {
	    if ($calls{$point}{$callee} > 1) {
		print F "$point -> $callee [label=\"$calls{$point}{$callee}\"];\n";
	    } else {
		print F "$point -> $callee;\n";
	    }
	} else {
	    if ($calls{$point}{$callee} > 1) {
		print F "$point -> $callee [style=dotted,label=\"$calls{$point}{$callee}\"];\n";
	    } else {
		print F "$point -> $callee [style=dotted];\n";
	    }
	}
    }
    
    --$level;
    for $callee (sort keys %{$calls{$point}}) {
	next if !$def{$callee};
	next if !$seen_here{$callee} && $seen{$callee};
	render_level($callee, $level);
    }
    return $size;
}

for $origin (sort keys %local_graphs) {
    open F, ">ref/$origin-call.dot" or die "Can't write `ref/$origin-call.dot': $!";
    $files = gen_files($origin);
    print F <<DOT;
$dot_header
digraph CALLS_$origin {
rankdir=LR;
ratio=compress;
//size="10,7"; orientation=landscape;
//size="7,10";
//ranksep=2;
//nodesep=0.1;
//page="8,11";
compound=true;
concentrate=true;

$origin [shape=octagon,style=filled,color=red,label="$origin\\n<$files>"];
DOT
    ;

    %seen = ($origin, 1);

    # render abbreviated "callers" graph

    for $cb (sort keys %{$called_by{$origin}}) {
	next if !$def{$cb};
	++$call_size{$origin};
	warn "ORIGIN($origin)";
	$seen{$cb} = 1;
	$files = gen_files($cb);
	print F "$cb [label=\"$cb\\n<$files>\"];\n";
	if ($called_by{$func}{$cb} > 1) {
	    print F "$cb -> $origin [label=\"$called_by{$origin}{$cb}\"]\n";
	} else {
	    print F "$cb -> $origin;\n";
	}
    }

    # render down stream call graph

    $call_size{$origin} += render_level($origin, $local_graphs{$origin});

    print F "}\n//EOF\n";
    close F;
    warn "Wrote $origin-call.dot\n";
}

###
### Generate function specific documentation
###

$0 = "generating func specific docu";
for $fn (@ARGV) {
    next if $fn =~ /~$/;  # Ignore backups
    next if $fn =~ /CVS/; # Ignore files in CVS special directories
    open F, "<$fn" or die "Can't read `$fn': $!";
    $x = <F>;
    close F;
    warn "Re-Analyzing $fn...\n";
    
    @fx = match_funcs($x);
    while (@fx) {
	#warn "  $fx[4]()\n";
#WHOLE >>$fx[3]<<
#BODY >>$fx[7]<<
	print <<DEBUG if 0;
FX2 =================================================================
NAME: >$fx[5]<
NAMESPACE: >$fx[6]<
LOCALNAME: >$fx[7]<
DOCFLAG: >>$fx[0]<<
DOC: >>$fx[1]<<
PROTO: >$fx[3]<
RET TYPE: >$fx[4]<
PARAMS: >$fx[8]<

DEBUG
    ;
	process_doc($fn, $fx[7], $fx[0], $fx[1], $fx[8]) if $fx[1] || $fx[4] !~ /^static /;
	splice @fx, 0, 10;
    }
}

### Annotate the source files with comments indicating where
### each defined function is called from so that M-. (ESC-.) in
### emacs allows you to navigate by callgraph.

sub gen_called_by {
    my ($func) = @_;
    my $cb = '';
    $func =~ s/^~/D_/;
    my $y = "\n/* Called by:  ";
    for $cb (sort keys %{$called_by{$func}}) {
	next if !$def{$cb};
	if ($called_by{$func}{$cb} > 1) {
	    $y .= "$cb x$called_by{$func}{$cb}, ";
	} else {
	    $y .= "$cb, ";
	}
    }
    chop $y; chop $y;
    return $y . " */";
}

for $fn (sort keys %fnf) {
    next unless $fn;
    print STDERR "Annotating $fn ... ";
    open F, "<$fn" or die "Can't read `$fn': $!";
    $x = <F>;
    close F;

  # 0=whole match, 1=proto, 2=ret type, 3=name, 4=namespace, 5=local name, 6=params, 7=body
  #                                             0  12                  2                              34     4 5   53       .6                    6 ,1                          :7   7   ;0
  $n  = $x =~ s%(?:\n/\* Called by:[^\*/]*?\*/)?(\n((\w[\w\*:\[\] \t]+?)(?:[ \t]*/\*[^\*/\n]*?\*/)?\s+((\w+::)*(\w+))[ \t]*\(([\w\*:\[\],\s/.&=]*?)\))\s*(?:/\*[^\*/]*?\*/)?\s*\{(.+?)\n\})%gen_called_by($6).$1%sge;  # version 2, comment tolerant

  # Constructors and destructors
  # 0=whole match, 1=proto, 2=name, 3=namespace, 4=local name, 5=params, 6=body
  #                                             0  123   3  4    42       .5                    5 ,1                          :6   6   ;0
  $m  = $x =~ s%(?:\n/\* Called by:[^\*/]*?\*/)?(\n(((\w+)::(~?\4))[ \t]*\(([\w\*:\[\],\s/.&=]*?)\))\s*(?:/\*[^\*/]*?\*/)?\s*\{(.+?)\n\})%gen_called_by($5).$1%sge;  # version 2, comment tolerant
    
    if (($n || $m) && $write) {
	open F, ">$fn" or die "Can't write `$fn': $!";
	print F $x;
	close F;
	warn "wrote $n changes in $fn\n";
    } else {
	warn "$n changes. Nothing written.\n";
    }
}

###
### Generate documentation index page
###

open M, ">ref/ref.pd" or die "Cant write ref/ref.pd: $!";
open F, ">ref/index.pd" or die "Cant write ref/index.pd: $!";

# Doc preamble and structs

print M <<PD;
<<if: ZXIDBOOK>>
<<else: >>$project Reference
##################
<<author: Generated by call-anal.pl from comments in code.>>
<<class: article!a4paper,10pt!!$project Ref>>
<<version:ref: 03>>

See also

<<../ref-inc.pd>>

<<maketoc: 1>>

1 Reference
===========
<<fi: >>

1.1 Structures
--------------

PD
    ;
print F <<PD;          # Meant to generate HTML
<<if: ZXIDBOOK>>
<<else: >>$project Reference Index
########################
<<author: Generated by call-anal.pl from comments in code>>
<<class: article!a4paper,10pt!!$project Ref>>
<<version:ref: 03>>

See also

<<../ref-inc.pd>>
<<fi: >>

1 Structures
============

PD
    ;

for $k (sort keys %struct) {
    print M "<<$k.pd>>\n";
    print F "* <<link:$k.html: $k>>\n";
}

# Important functions index

print M <<PD;

1.3 Important Functions
-----------------------

PD
    ;

print F <<PD;

2 Important Functions
=====================

PD
    ;

for $k (sort keys %important) {
    if (!length $doc{$k}) {
	warn "Important function($k) without documentation";
	next;
    }
    print M "<<$k.pd>>\n";
    print F "* <<link:$k.html: $k>>\n";
    ++$func_seen{$k};
}

# All functions index

print M <<PD;

1.4 Other Functions
-------------------

PD
    ;
print F <<PD;

3 Functions Alphabetical
========================

PD
    ;

for $k (sort keys %func) {
    if (!length $doc{$k}) {
	warn "function($k) without documentation";
	next;
    }
    print F qq(<<html: <a href="$k.html">$k</a><br> >>\n);
    if ($func_seen{$k}) {
	warn "function($k) already seen";
	next;
    }
    print M "<<$k.pd>>\n";
}

print M <<PD;
<<makeindex: 1>>
<<ignore: EOF: >>
PD
    ;
print F <<PD;
<<ignore: EOF: >>
PD
    ;

close M;
close F;

#EOF call-anal.pl
