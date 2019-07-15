package # hide from CPAN indexer
    XS::Install::ParseXS;
use strict;
use warnings;
use feature 'state';
no warnings 'redefine';
use ExtUtils::ParseXS;
use ExtUtils::ParseXS::Eval;
use ExtUtils::ParseXS::Utilities;
use ExtUtils::Typemaps;
use ExtUtils::Typemaps::InputMap;
use ExtUtils::Typemaps::OutputMap;

my (@pre_callbacks, @no_typemap_callbacks);
our ($top_typemaps, $cur_typemaps);
our $cplus = grep { /-C\+\+/ } @ARGV;
my $re_quot1 = qr/"(?:[^"\\]+|\\.)*"/;
my $re_quot2 = qr/'(?:[^'\\]+|\\.)*'/;
my $re_quot  = qr/(?:$re_quot1|$re_quot2)/;
my $re_comment_single = qr#//[^\n]*\n#;
my $re_comment_multi  = qr#/\*.*?\*/#ms;
my $re_ignored = qr/(?:$re_quot|$re_comment_single|$re_comment_multi)/ms;
my $re_braces = qr#(?<braces>\{(?>[^/"'{}]+|$re_ignored|(?&braces)|/)*\})#ms;
our $re_xsub = qr/(XS_EUPXS\(XS_[a-zA-Z0-9_]+\))[^{]+($re_braces)/ms;
our $re_boot = qr/(XS_EXTERNAL\(boot_[a-zA-Z0-9_]+\))[^{]+($re_braces)/ms; 

sub add_pre_callback        { push @pre_callbacks, shift; }
sub add_post_callback       { push @CatchEnd::post_callbacks, shift; }
sub add_no_typemap_callback { push @no_typemap_callbacks, shift; }

sub call {
	my ($cbs, @args) = @_;
	$_->(@args) for @$cbs;
}

sub code_start_idx {
	my $lines = shift;
    my $idx;
    for (my $i = 2; $i < @$lines; ++$i) {
        return $i+1 if $lines->[$i] =~ /^(PP)?CODE\s*:/;
    }
    die "code start not found";
}

sub code_end_idx {
    my $lines = shift;
    my $idx = code_start_idx($lines);
    for (; $idx < @$lines; ++$idx) {
        return $idx if $lines->[$idx] =~ /^[a-zA-Z0-9]+\s*:/;
    }
    return $idx;
}

sub is_empty {
    my $lines = shift;
    return code_start_idx($lines) == code_end_idx($lines);
}

sub insert_code_top {
	my ($parser, $code) = @_;
	my $lines = $parser->{line};
	my $linno = $parser->{line_no};
    my $idx = code_start_idx($lines);
    splice(@$lines, $idx, 0, $code);
    splice(@$linno, $idx, 0, $linno->[$idx] // $linno->[-1]);
}

sub insert_code_bottom {
	my ($parser, $code) = @_;
    my $lines = $parser->{line};
    my $linno = $parser->{line_no};
    my $idx = code_end_idx($lines);
    splice(@$lines, $idx, 0, $code);
    splice(@$linno, $idx, 0, $linno->[$idx] // $linno->[-1]);
}

my $orig_pmxl = \&ExtUtils::ParseXS::_process_module_xs_line;
*ExtUtils::ParseXS::_process_module_xs_line = sub {
    my ($self, $module, $pkg, $prefix) = @_;
	$orig_pmxl->(@_);
	$self->{xsi}{module} = $module;
	$self->{xsi}{inline_mode} = 0;
};

sub get_mode {
	return '' unless $_[0] =~ /^MODE\s*:\s*(\w+)\s*$/;
	return uc($1);
}

# pre process XS function
my $orig_fetch_para = \&ExtUtils::ParseXS::fetch_para;
*ExtUtils::ParseXS::fetch_para = sub {
    my $self = shift;
    my $ret = $orig_fetch_para->($self, @_);
    my $lines = $self->{line};
    my $linno = $self->{line_no};
    return $ret unless @$lines;
    
    if (get_mode($lines->[0]) eq 'INLINE') {
    	$self->{xsi}{inline_mode} = 1;
    	shift @$lines;
    	shift @$linno;
    }
    
    if ($self->{xsi}{inline_mode}) {
    	while (@$lines) {
    		my $line = shift @$lines;
    		shift @$linno;
    	    if (get_mode($line) eq 'XS') {
    	    	$self->{xsi}{inline_mode} = 0;
    	    	last;
    	    }
    	    print "$line\n";
    	}
    	return $ret unless @$lines;
    }
    
    # concat 2 lines codes (functions with default behaviour) to make it preprocessed like C-like synopsis
    if (@$lines == 2) {
        $lines->[0] .= ' '.$lines->[1];
        splice(@$lines, 1, 1);
        splice(@$linno, 1, 1);
    }
    
    if ($lines->[0] and $lines->[0] =~ /^([A-Z]+)\s*\{/) {
        $lines->[0] = "$1:";
        if ($lines->[-1] =~ /^\}/) { pop @$lines; pop @$linno; }
    }
    
    my %attrs;
    
    if ($lines->[0] and $lines->[0] =~ /^(.+?)\s+([^\s()]+\s*(\((?:[^()]|(?3))*\)))\s*(.*)/) {
        my ($type, $sig, $rest) = ($1, $2, $4);
        shift @$lines;
        my $deflinno = shift @$linno;
        
        my $remove_closing;
        if ((my $idx = index($rest, '{')) >= 0) { # move following text on next line
            $remove_closing = 1;
            my $content = substr($rest, $idx+1);
            substr($rest, $idx) = '';
            if ($content =~ /\S/) {
                unshift @$lines, $content;
                unshift @$linno, $deflinno;
            }
        } elsif ($lines->[0] and $lines->[0] =~ s/^\s*\{//) { # '{' on next line
            $remove_closing = 1;
            if ($lines->[0] !~ /\S/) { # nothing remains, delete entire line
                shift @$lines;
                shift @$linno;
            }
        }

        if ($remove_closing) {
            $lines->[-1] =~ s/}\s*;?\s*$//;
            if ($lines->[-1] !~ /\S/) { pop @$lines; pop @$linno; }
            
            if (!$lines->[0] or $lines->[0] !~ /\S/) { # no code remains, but body was present ({}), add empty code to prevent default behaviour
                $lines->[0] = ' ';
                $linno->[0] ||= $deflinno;
            }
        }
        
        if (length $lines->[0]) {
        	unshift @$lines, $type =~ /^void(\s|$)/ ? 'PPCODE:' : 'CODE:';
            unshift @$linno, $deflinno;
        }
        
        if ($rest =~ /:(.+)/) {
            my $attrs_str = $1;
            %attrs = ($attrs_str =~ /\s*([A-Za-z]+)\s*(?:\(([^()]*)\)|)\s*/g);
        }
        
        while (my ($attr, $val) = each %attrs) {
        	$attr = uc($attr);
        	if ($attr eq 'ALIAS' && (my @alias = split /\s*,\s*/, $val)) {
                foreach my $alias_entry (reverse @alias) {
                    unshift @$lines, "    $alias_entry";
                    unshift @$linno, $deflinno;
                }
                unshift @$lines, 'ALIAS:';
                unshift @$linno, $deflinno;
        	}
        	elsif ($attr eq 'CONST') { next }
        	elsif (defined $val) {
        		unshift @$lines, "$attr: $val";
                unshift @$linno, $deflinno;
        	}
        }

        unshift @$lines, $sig;
        unshift @$lines, $type;
        unshift @$linno, $deflinno for 1..2;
    }
    
    # make BOOT's code in personal scope
    if ($lines->[0] =~ /^BOOT\s*:/) {
        splice(@$lines, 1, 0, "    {");
        splice(@$linno, 1, 0, $linno->[0]);
        push @$lines, "    }";
        push @$linno, $linno->[-1];
    }
    
    map {
        s/\b__PACKAGE__\b/"$self->{Package}"/g;
        s/\b__MODULE__\b/"$self->{xsi}{module}"/g;
    } @$lines;
    
    my $out_type = $lines->[0] or return $ret;
    # filter out junk, because first line might be "BOOT:", "PROTOTYPES: ...", "INCLUDE: ...", "#ifdef", etc
    return $ret if !$out_type or $out_type =~ /^#/ or $out_type =~ /^[_A-Z]+\s*:([^:]|$)/;

    # parse signature -> $func and @args
    my $sig = $lines->[1];
    $sig =~ /^([^(]+)\((.*)\)\s*$/ or die "bad signature: '$sig', at $self->{filepathname}, function $self->{pname}";
    my $func = $1;
    my $args_str = $2;
    $func =~ s/^\s+//; $func =~ s/\s+$//;
    my @args;
    my $variadic;
    for my $str (split /\s*,\s*/, $args_str) {
    	my %info;
    	$info{default} = $1 if $str =~ s/\s*=\s*(.+)$//;
        $info{name}    = '';
    	$info{name}    = $1 if $str =~ s/([a-zA-Z0-9_\$]+)\s*$//;
        $info{type}    = $str;
    	if ($str eq '...') {
    		$variadic = 1;
    		next;
    	}
    	if (!$info{type}) { # arg with no name
            $info{type} = $info{name};
    		$info{name} = '';
    	}
    	
    	map { s/^\s+//; s/\s+$// } values %info;
    	push @args, \%info;
    }
    
    if ($func =~ s/^(.+):://) { # replace 'Class::meth' with 'meth(Class* THIS)'
        unshift @args, $func eq 'new' ? {name => 'CLASS', type => 'SV*', orig_type => $1} :
                                        {name => 'THIS',  type => "$1*"};
    }
    
    my $first_arg = $args[0];
    $first_arg->{type} = 'const '.$first_arg->{type} if exists($attrs{const}) or exists($attrs{CONST});
    my $is_method = $first_arg && $first_arg->{name} eq 'THIS';
    
    my $para = join("\n", @$lines);
    
    if ($para !~ /^(PP)?CODE\s*:/m) { # empty function, replace with $func(@args) or $first_arg->$func(@rest_args)
        my $void = $out_type =~ /^void(?:\s|$)/;
        push @$lines, $void ? 'PPCODE:' : 'CODE:';
        push @$linno, $linno->[-1];
        if ($func ne 'new' and ($func ne 'DESTROY' or !$is_method)) {
            my $code = '';
	        my @real_args = @args;
	        if ($is_method) {
	        	shift @real_args;
	        	$code = $first_arg->{name}.'->';
	        }
	        $code .= $func.'('.join(', ', map { $_->{name} } @real_args).')';
	        $code = "RETVAL = $code" unless $void;
            push @$lines, "        $code;";
            push @$linno, $linno->[-1];
        }
    	$para = join("\n", @$lines);
    }
    
    if ($para =~ /^CODE\s*:/m and $para !~ /^OUTPUT\s*:/m) { # add OUTPUT:RETVAL unless any
        push @$lines, 'OUTPUT:', '    RETVAL';
        push @$linno, $linno->[-1] for 1..2;
        $para = join("\n", @$lines);
    }
    
    my $cb_args = {
        ret      => $out_type,
        func     => $func,
        args     => \@args,
        variadic => $variadic,
    };
    call(\@pre_callbacks, $self, $cb_args);
    
    # form final signature for ParseXS
    my @args_lines = map { "$_->{type} $_->{name}".(defined($_->{default}) ? " = $_->{default}" : '') } @args;
    push @args_lines, '...' if $variadic;
    $sig = $func.' ('.join(', ', @args_lines).')';
    
    $lines->[0] = $out_type;
    $lines->[1] = $sig;
    
    if (is_empty($lines)) {
    	if ($func eq 'DESTROY' and $is_method) {
    		insert_code_top($self, "    delete THIS;");
    	}
    	elsif ($func eq 'new') {
    		insert_code_top($self, "    RETVAL = ".default_constructor($out_type, \@args).';');
    	}
    }
    
    return $ret;
};

sub default_constructor {
	my ($ret_type, $args) = @_;
    my @pass_args = @$args;
    my $fa = shift @pass_args;
    my $args_str = join(', ', map { $_->{name} } @pass_args);
    my $new_type = $fa->{orig_type};
    unless ($new_type) {
        $new_type = $ret_type;
        $new_type =~ s/\s*\*$//;
    }
    my $ret = "new $new_type($args_str)";
    
    $ret = "$ret_type($ret)" unless $ret_type =~ /\*$/;
    
    return $ret;
}

{
    my $orig_merge = \&ExtUtils::Typemaps::merge;
    my $orig_parse = \&ExtUtils::Typemaps::_parse;
    my $orig_get   = \&ExtUtils::Typemaps::get_typemap;
    
    *ExtUtils::Typemaps::get_typemap = sub {
        my $ret = $orig_get->(@_);
        return $ret if $ret;
        call(\@no_typemap_callbacks, @_);
        return $orig_get->(@_);
    };
    
    *ExtUtils::Typemaps::merge = sub {
        $top_typemaps = $_[0];
        return $orig_merge->(@_);
    };
    
    *ExtUtils::Typemaps::_parse = sub {
        local $cur_typemaps = $_[0];
        return $orig_parse->(@_);
    };
}

{
    # remove ugly default behaviour, it always overrides typemaps in xsubpp's command line
    *ExtUtils::ParseXS::Utilities::standard_typemap_locations = sub {
        my $inc = shift;
        my @ret;
        push @ret, 'typemap' if -e 'typemap';
        return @ret;
    };
}

{
    package # hide from CPAN
        CatchEnd;
    use strict;
    use feature 'say';
    
    our @post_callbacks;

    my ($out, $orig_stdout);
    open $orig_stdout, '>&', STDOUT;
    close STDOUT;
    open STDOUT, '>', \$out or die $!; # This shouldn't fail
    
    #post-process XS out
    sub END {
        $out //= '';
        select $orig_stdout;

        $out =~ s/^MODE\s*:.+//mg;
        
        # remove XS function C-prototype (it causes warnings on many compilers)
        $out =~ s/XS_EUPXS\(XS_[a-zA-Z0-9_]+\);.*\n/\n/mg;
        
        # remove XS BOOT function C-prototype
        $out =~ s/XS_EXTERNAL\(boot_[a-zA-Z0-9_]+\);.*\n/\n/mg;

        XS::Install::ParseXS::call(\@post_callbacks, \$out);
        print $out;
    }
}

{
	package #hide from CPAN
            ExtUtils::ParseXS;
	my $END = "!End!\n\n";
	my $BLOCK_regexp = '\s*(' . $ExtUtils::ParseXS::Constants::XSKeywordsAlternation . "|$END)\\s*:";
    # copy-paste from ExtUtils::ParseXS to fix Typemaps with references (&). ParseXS was simply removing it from type
    # only one line changed with regexp
    # my ($var_type, $var_addr, $var_name) = /^(.*?[^&\s])\s*(\&?)\s*\b(\w+)$/s
    *INPUT_handler = sub {
	  my $self = shift;
	  $_ = shift;
	  for (;  !/^$BLOCK_regexp/o;  $_ = shift(@{ $self->{line} })) {
	    last if /^\s*NOT_IMPLEMENTED_YET/;
	    next unless /\S/;        # skip blank lines
	
	    trim_whitespace($_);
	    my $ln = $_;
	
	    # remove trailing semicolon if no initialisation
	    s/\s*;$//g unless /[=;+].*\S/;
	
	    # Process the length(foo) declarations
	    if (s/^([^=]*)\blength\(\s*(\w+)\s*\)\s*$/$1 XSauto_length_of_$2=NO_INIT/x) {
	      print "\tSTRLEN\tSTRLEN_length_of_$2;\n";
	      $self->{lengthof}->{$2} = undef;
	      $self->{deferred} .= "\n\tXSauto_length_of_$2 = STRLEN_length_of_$2;\n";
	    }
	
	    # check for optional initialisation code
	    my $var_init = '';
	    $var_init = $1 if s/\s*([=;+].*)$//s;
	    $var_init =~ s/"/\\"/g;
	    # *sigh* It's valid to supply explicit input typemaps in the argument list...
	    my $is_overridden_typemap = $var_init =~ /ST\s*\(|\$arg\b/;
	
	    s/\s+/ /g;
	    my $var_addr = '';
	    my ($var_type, $var_name) = /^(.*?[^\s])\s*\b(\w+)$/s
	      or $self->blurt("Error: invalid argument declaration '$ln'"), next;
	
	    # Check for duplicate definitions
	    $self->blurt("Error: duplicate definition of argument '$var_name' ignored"), next
	      if $self->{arg_list}->{$var_name}++
	        or defined $self->{argtype_seen}->{$var_name} and not $self->{processing_arg_with_types};
	
	    $self->{thisdone} |= $var_name eq "THIS";
	    $self->{retvaldone} |= $var_name eq "RETVAL";
	    $self->{var_types}->{$var_name} = $var_type;
	    # XXXX This check is a safeguard against the unfinished conversion of
	    # generate_init().  When generate_init() is fixed,
	    # one can use 2-args map_type() unconditionally.
	    my $printed_name;
	    if ($var_type =~ / \( \s* \* \s* \) /x) {
	      # Function pointers are not yet supported with output_init()!
	      print "\t" . map_type($self, $var_type, $var_name);
	      $printed_name = 1;
	    }
	    else {
	      print "\t" . map_type($self, $var_type, undef);
	      $printed_name = 0;
	    }
	    $self->{var_num} = $self->{args_match}->{$var_name};
	
	    if ($self->{var_num}) {
	      my $typemap = $self->{typemap}->get_typemap(ctype => $var_type);
	      $self->report_typemap_failure($self->{typemap}, $var_type, "death")
	        if not $typemap and not $is_overridden_typemap;
	      $self->{proto_arg}->[$self->{var_num}] = ($typemap && $typemap->proto) || "\$";
	    }
	    $self->{func_args} =~ s/\b($var_name)\b/&$1/ if $var_addr;
	    if ($var_init =~ /^[=;]\s*NO_INIT\s*;?\s*$/
	      or $self->{in_out}->{$var_name} and $self->{in_out}->{$var_name} =~ /^OUT/
	      and $var_init !~ /\S/) {
	      if ($printed_name) {
	        print ";\n";
	      }
	      else {
	        print "\t$var_name;\n";
	      }
	    }
	    elsif ($var_init =~ /\S/) {
	      $self->output_init( {
	        type          => $var_type,
	        num           => $self->{var_num},
	        var           => $var_name,
	        init          => $var_init,
	        printed_name  => $printed_name,
	      } );
	    }
	    elsif ($self->{var_num}) {
	      $self->generate_init( {
	        type          => $var_type,
	        num           => $self->{var_num},
	        var           => $var_name,
	        printed_name  => $printed_name,
	      } );
	    }
	    else {
	      print ";\n";
	    }
	  }
	};
}

1;
