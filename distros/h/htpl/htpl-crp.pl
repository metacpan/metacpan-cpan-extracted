#!/usr/local/bin/perl

use strict vars;
use vars qw($glob_ary $subname);

require "parse-exp.pl";
require "perf.pl";

use XML::Parser;
my $parser = new XML::Parser(Style => 'Tree');

my (%scopes, @subs);

# Parse input

my @files;
push(@files, $ARGV[0] ||  (-f 'macros.xpl' ? 'macros.xpl' : 'htpl.subs'));
foreach (qw(/usr/share/htpl-site.xpl /usr/local/share/htpl-site.xpl
		htpl-site.xpl)) {
	push(@files, $_) if (-f $_);
}

my @nodes;

foreach (@files) {
    my $tree = $parser->parsefile($_);
    die "Root must be HTPL" unless($tree->[0] eq 'HTPL');
    my @these = @{$tree->[1]};
    shift @these;
    push(@nodes, @these);
}

my $result = ['HTPL', [{}, @nodes]];

# Output parser

open(OP, ">htpl-parse.c");

select(OP);

print <<EOM;
/** HTPL Macro parser **********************************
 ** This file is created automatically by htpl-crp.pl **
 ** Do not attempt to edit *****************************/

#define __HTPARSE__
#include "htpl.h"
#include "htpl-sh.h"
#include "perf.h"

#define RETURN(x) {int v = (x); destroypersist(); return v;}
#define numtokens (persist->tokens->num)

EOM

# Recurse over tree


&recur($result);

select(STDOUT);
close(OP);

# Output header file

my $nmacs = $#subs + 1;

open(O, ">htpl-sh.h");
print O "typedef int (*parser)(STR, int);\n";
foreach (@subs) {
    next unless ($_);
    print O "int parse_$_(STR, int);\n";
}

my @thescopes = keys %scopes;
unshift(@thescopes, "none");
$scopes{"none"} = "no_scope";
if (@thescopes) {
    print O "\nenum scopevalues {" . join(",\n    ", (map {$scopes{$_};}
         @thescopes)) . "};\n";
    print O "#ifdef __HTPARSE__\n";
    print O "char *scope_names[] = {\"" . join("\",\n    \"", @thescopes)
           . "\"};\n";
    print O "int scope_ids[] = {" . join(", ", map {"0"} @thescopes)
         . "};\n";
    print O <<EOI
#else
extern char *scope_names[];
extern int scope_ids[];
#endif
EOI
}

print O "\n#define NUM_MACROS $nmacs\n";
close(O);

print $nmacs . " macros compiled.\n";

sub recur {
    my ($node, @stack) = @_;
    my @array = @$node;

    my $item;

    my $code;

    my $atref = {};

    $atref = shift @array unless ($#array % 2);
# $atref contains the tag 

# Convert sub tags to hash for quick find

    my %hash = @array;


# Create function name

    my $sub = join("_", @stack);

    $sub =~ s/-/_/g;

    $subname = uc(join(" ", grep {!/^__/} @stack[1 .. $#stack]));

# Create function header
    push (@subs, $sub);

# Initialize scoping

    my $precode = '';
    my $postcode = '';

    my ($max, $min);

# Check if this macro has minimum/maximum parameters
    if (defined($max = $atref->{'MAX'}) + ($min = $atref->{'MIN'})) {
# + and not ||, so both sides are evaluated
        $code .= &outparamcount($min, $max, $subname);
    }

    if ($atref->{'ASSERT'}) {
        $code .= &outassert($atref->{'ASSERT'}, $subname);
    }

# Check if this macro can be used by the user, or is it for inner use only
# The attribute PRIVATE limits a macro to calling from another macro

    if ($atref->{'PRIVATE'}) {
        $code .= &outensurenest;
    }

# Check if this domain has prerequisites
# Code under __PRE sub tag will be evaluated once for every script in
# first occurunce. Useful for requiring optional modules

    my $pre = $hash{'__PRE'};
    
    $code .= &outpre(&juice($pre)) if ($pre);

# Check if this macro is aliased    
# __ALIAS reduced a macro to a unification of another macro

    my $alias = $hash{'__ALIAS'};

    if ($alias) {
        $precode = &outpersist . $precode;
        my ($todo, %that) = &juice($alias);
        $code .= &outterminal($subname);
        $postcode = $postcode . &outsuccess;
        foreach (split(/\n/, $todo)) {
            $code .= &outunify($_, $that{'DIR'});
        }
        goto done ;
    }


# SCOPE is an attribute used to group perl code in { } to enable scoping
# Not usable in areas

    if (($atref->{'SCOPE'} || $atref->{'PARAMS'}) && !$atref->{'AREA'}) {
        $precode .= &outcode("{");
        $postcode = &outcode("}") . $postcode;
    }

# PARAMS is an attribute used for tags in SGML notion

    if ($atref->{'PARAMS'}) {
        $precode .= &outgettags($atref->{'MANDATORY'}, $subname);
    }

# The FRIEND attribute is used for non blocking macros, and allows them to
# masquerade another scope. This is useful only for calling other macros.

    if ($atref->{'FRIEND'} && !$atref->{'AREA'}) {
        $precode .= &outpush($atref->{'FRIEND'}, 1);
        $postcode = &outpop($atref->{'FRIEND'}, $subname) . $postcode;
    }

# The BROTHER attribute on a non blocking macro (or on a blocking macro
# inherited to the forward tag enforces a SCOPE in the entrance to a
# macro. An Additional CHANGE attribute might be specified to change the
# current scope to a different one once verified

    if ($atref->{'BROTHER'} && !$atref->{'AREA'}) {
        if ($atref->{'CHANGE'}) {
            $code .= &outpop($atref->{'BROTHER'}, $subname)
               . &outpush($atref->{'CHANGE'});
        } else {
            if ($atref->{' SYS '} eq '__REV') {
                $postcode = &outnopop($atref->{'BROTHER'}, $subname) . $postcode;
            } else {
                $precode .= &outnopop($atref->{'BROTHER'}, $subname);
            }
        }
    }

# The POP attribute enforces a scope check in the entrance for a macro,
# and pops the scope from the stack

    if ($atref->{'POP'}) {
        $postcode = &outpop($atref->{'POP'}, $subname) . $postcode;
    }

# The PUSH attribute supplies a scope to be pushed into the stack

    if ($atref->{'PUSH'}) {
        $code .= &outpush($atref->{'PUSH'});
    }

    if ($atref->{'ONCE'} && !$atref->{'AREA'}) {
        $code .= &outonce($subname);
    }

# Now lets's check if this tag is a leaf - if so, we should reduce to the
# code

    my $this = $hash{'0'};

    if ($this =~ /\S+/) {
        $precode = &outpersist . $precode;
        $code .= &outcode($this, $atref);
        $postcode .= &outsuccess();
        goto done;
    }

    my $codet = &operations($sub, \%hash, @array);

    if ($codet || $atref->{'NOOP'}) {
        $precode = &outpersist . $precode;
        $postcode .= &outsuccess;
        $code .= $codet;
        goto done;
    }

# This tag is a nonterminal

    my @ks = keys %hash;
    my ($key, $ref);

# IF this is a blocking tag

    if ($atref->{'AREA'}) {
        my %tiny = qw(__FWD PUSH __REV POP);
        foreach $key (qw(__FWD __REV)) {
            $ref = $hash{$key};
            my @ary = @$ref;
            my $attr = shift @ary;
            $attr->{$tiny{$key}} = $atref->{'BLOCK'} if ($atref->{'BLOCK'});
	    $attr->{'ONCE'} = 1 if ($atref->{'ONCE'} && $key eq 'FWD');
            $attr->{'BROTHER'} = $atref->{'BROTHER'};
            $attr->{' SYS '} = $key;
            if ($atref->{'SCOPE'}) {
                @ary = makedo($ary[1]) if ($#ary == 1 && $ary[0] eq '0');
                unshift(@ary, makedo("{")) if ($key eq '__FWD');
                push(@ary, makedo("}")) if ($key eq '__REV');
            }
            unshift(@ary, $attr);
            &recur(\@ary, (@stack, lc($key)));
        }
	$code .= &outarea($sub);
        goto done;
    }


# This is a matching node

    $code .= &outnonterminal;

# Check all children

    my @subs;
    foreach $key (@ks) {
        next if ($key =~ /^__/ || $key eq '0');
#        $code .= &outtoken(lc($key), @stack);
        push(@subs, lc($key));
        $ref = $hash{$key};
        my @ary = @$ref;
#        shift @ary;
        &recur(\@ary, (@stack, lc($key)));
    }
    @subs = sort @subs;
    $code .= &outhash(\@subs, @stack);

# Add a check for unification failure

#    $code .= outendsub(0);
done:
    print &outheader($sub) . $precode . $code . $postcode . &outfooter($sub);
    print "\n";
}

sub outheader {
    my $sub = shift;
    return <<EOM;
int parse_$sub(stack, untag)
    int untag;
    STR stack; {

    TOKEN token;
    static done = 0;
    STR buff;
    int code;
    static int nesting = 0;
    static int refcount = 0;

    refcount++;
    makepersist(stack);
EOM
}

sub outnonterminal {
    return <<EOM;
    eat(&stack, token);
EOM
}

sub outfooter {
    return "}\n";
}

sub outpre {
    my $code = &escape(shift);
    return <<EOM;
    if (!done) {
        done = 1;
        printcode("$code");
    }
EOM
}

sub outbeginsub {
    return <<EOM;
    code = 1;
EOM
}

sub outterminal {
    my $sub = shift;
    return <<EOM;
    nesting++;
    if (nesting > 1) RETURN(croak("Infinite loop in $sub"))
EOM
}

sub outunify {
    my $alias = &escape(shift, 1);
    $alias =~ s/\\n$//;
    my $dir = shift;
    my $dn = "untag";
    $dn = "0" if ($dir eq 'FWD');
    $dn = "1" if ($dir eq 'REV');
    my $alias_parsed = &wrapcode(&assemble($alias));
    return <<EOM;
    kludge_reunifying = 1;
    asprintf(&buff, $alias_parsed);
    kludge_reunifying = 0;
    nest++;
    code = parse_htpl(buff, $dn);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);

EOM
}

sub outcond {
    my $code = shift;
    my ($min, $max, $assert, $scope, $sub) = @_;
    my $txt;

    return $code unless (join("", @_) ne "");

    die "Non numeric minimum $min in $sub" if ($min && $min !~ /^\d+$/);
    die "Non numeric maximum $max in $sub" if ($max && $max !~ /^\d+$/);

    my $ret = "";
    if ($min =~ /\d/ || $max =~ /\d/) {
        $ret .= <<EOM;
EOM
    }
    my @conds;
    push(@conds, "numtokens >= $min") if ($min =~ /\d/);
    push(@conds, "numtokens <= $max") if ($max =~ /\d/);
    push(@conds, &code2c($assert)) if ($assert);
    push(@conds, &ifscope($scope)) if ($scope);

    return $code unless(@conds);   

    my @lines = split(/\n/, $code);
    @lines = map {"    $_";} @lines;
    $code = join("\n", @lines);
    $ret = "    " . &wrapcode("if (" . join(" && ", @conds) . ") ") . " {
$code
    }
";
    return $ret;
}

sub ifscope {
    my @scopes = map {&getscope($_)} split(/,\s*/, shift);
    my @conds = map {"currscope->scope == $_"} @scopes;
    return "currscope && (" . join(" || ", @conds) . ")";
}

sub outcode {
    my ($code, $atts) = @_;
    my @p = @_;
    my $txt;
    $atts ||= {};
    my $favours = !($atts->{'NOFAVORS'} || $atts->{'NOFAVOURS'});

    my ($ret, $scode, $tcode, $l); 
    foreach $l (split(/\r?\n/, $code)) {
        next unless ($l);
        if ($favours && $l !~ /^\s*#/) {
            $l =~ s/qw\(%(\d+)\*%\)/%$1#%/g;
            $l =~ s/\$%(\d+)%/\${"%$1%"}/g;
            $l =~ s/'%(\d+)%'/"%$1%"/g;
        }

        $tcode = &escape($l);
        $scode = &wrapcode(&assemble($tcode));
        if ($l =~ /^\s*\#\w/) {
            $ret .= <<EOM;
    asprintf(&buff, $scode);
    nest++;
    code = parse_htpl(strchr(buff, '#') + 1, 0);
    nest--;
    if (!code) {
        croak("Unification of '%s' failed", buff);
        free(buff);
        RETURN(0)
    }
    free(buff);
EOM
            next;
        } 
        $scode =~ s/(\s+)%#/$1#/;
        if ($glob_ary) {
            $ret .= <<EOM;
    printfcode($scode);
EOM
        } else {
            $tcode =~ s/\%\%/%/g;
            $ret .= <<EOM;
    printcode("$tcode");
EOM
        }
    }
    $ret;
}

sub outtoken {
    my ($this, @stack) = @_;
    my $uthis = uc($this);
    my $sub2 = join("_", (@stack, $this));
    $sub2 =~ s/-/_/g;
    return <<EOM;
    if (!strcasecmp(token, "$uthis")) RETURN(parse_$sub2(stack, untag));
EOM
}

sub juice {
    my $obj = shift;
#    return $obj unless (ref($obj));
    my @ary = @$obj;
    my $att = shift @ary;
#    return $att unless (ref($att));
    my %hash = @ary;
    return ($hash{'0'}, %$att);
}

sub escape {
    my $s = shift;
    $s .= "\n" unless ($s =~ /\n$/ || $_[0]);
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/^\n//;
    $s .= "\n";
    $s =~ s/\n+/\n/g;
    $s =~ s/\n/\\n/g;
    return $s;
}

sub outsuccess {
    return <<EOM;
    nesting = 0;
    RETURN(1)
EOM
}

sub outensurenest {
    return <<EOM;
    if (!nest) RETURN(0)
EOM
}

sub outgettags {
    my $mand = shift;
    my $sub = shift;
    my $ret = &outcode("my %%tags = &HTML::HTPL::Sys::parse_tags('%1*%\');");
    $ret .= &outcode("&publish(&proper(sub {uc(\$_);}, %%tags));");
    $ret .= &outcode("&HTML::HTPL::Sys::enforce_tags('$mand', '$sub', %%tags);") if ($mand);
    $ret;
}

sub outarea {
    my $sub = shift;
    return <<EOM;
    if (!untag) RETURN(parse_${sub}___fwd(stack, untag))
        else RETURN(parse_${sub}___rev(stack, untag))
EOM
}

sub outassert {
    my ($assert, $sub) = @_;

    my $c = &code2c($assert);

    my $ret = <<EOM;
    if (!($c)) {
        RETURN(croak("Assert failed on $sub: $assert"));
    }
EOM
    $ret;
}

sub outparamcount {
    my ($min, $max, $sub) = @_;
    die "Non numeric minimum $min in $sub" if ($min && $min !~ /^\d+$/);
    die "Non numeric maximum $max in $sub" if ($max && $max !~ /^\d+$/);
    my $ret;
    my $p;
    $p = '(untag ? "/" : ""), ';
    my %hash = qw(min < max >);
    foreach (keys %hash) {
        my $val = eval "\$$_";
        my $op = $hash{$_};
        $ret .= <<EOM if ($val);
    if (numtokens $op $val) RETURN(croak("%s$sub called with %d arguments, ${_}imum needed is $val", ${p}numtokens))
EOM
    }
    $ret;
}

sub outpop {
    return &outnopop(@_) . <<EOM;
    popscope();
EOM
}

sub outnopop {
    my ($scope, $sub) = @_;
    my ($sym, $op) = ("!=", "&&");
    ($sym, $op) = ("==", "||") if ($scope =~ s/^\!\s*//);
    my @conds = map {
          "currscope->scope $sym " . &getscope($_)
      } split(/,\s*/, $scope);
    my $cond = join(" $op ", @conds);
    my $ret = <<EOM;
    if (!currscope) RETURN(croak("Unexpected $sub"))
    if ($cond) RETURN(croak("Now in scope %s from %d and met $sub, expecting: $scope", scope_names[currscope->scope], currscope->nline))
EOM
    $ret;
}

sub outpush {
    my ($scope, $noinc) = @_;
    $noinc = $noinc * 1;
    my $code = &getscope($scope);
    return <<EOM;
    pushscope($code, $noinc);
EOM
}

sub getscope {
    my $name = shift;
    return $scopes{$name} if ($scopes{$name});
    my $val = $name;
    $val =~ tr/A-Z/a-z/;
    $val =~ s/[^a-z0-9]/_/g;
    $val = "scope_$val";
    $scopes{$name} = $val;
    $val;
}

sub outconst {
    my $val = shift;
    return <<EOM;
    return $val;
EOM
}

sub outc {
    my $code = shift;
    return <<EOM;
{
    $code
}
EOM
}

sub outpersist {
return "";
"    makepersist(stack);\n";
}

sub makedo {
  ('__DO', [{}, "0", shift]);
}

sub outendsub {
    my $code = shift;
    return <<EOM;
    return $code;
EOM
}

sub outxfer {
    my ($dir, $var, $scope) = @_;
    return <<EOM;
    if (!${dir}var("$var", "$scope")) RETURN(croak("Scope $scope not found in stack"));
EOM
}

sub outset {
    my ($var, $val) = @_;
    my $s = expandstr($val);
    return <<EOM;
    setvar("$var", $s);
EOM
}

sub outcroak {
    my $scode = &wrapcode(&assemble(shift));
    return <<EOM;
    RETURN(croak($scode))
EOM
}

sub operations {

# Now let's iterate over all the sons and process them
# $flag is turned if we found out this token was a terminal
# $this is the contents of the tag
# %that ts the attributes
# $codet gets the code
# All of this tags can be used with MIN or MAX to apply a parameter count
# condition. Otherwise the tag will not execute but the macro will not
# fail. ASSERT can be used to check the parameters.

    my $sub = shift;
    my $superhash = shift;
    my @a = @_;
    my $code = "";
    while (@a) {
        my $key = shift @a;
        my $this = shift @a;
        my ($todo, %that);
        ($todo, %that) = &juice($this);
        my @params = @that{qw(MIN MAX ASSERT BROTHER)};
        my $codet = undef;
        my $doneterminal = undef;


        if ($key eq '__MACRO') {
            my $atts = $this->[0];
            my $name = $atts->{'NAME'} || $atts->{'ID'};
            delete $atts->{'NAME'};
            delete $atts->{'ID'};
            $superhash->{$name} = $this;
            next;
        }
# __INCLUDE parses another macro and includes it

        if ($key eq '__INCLUDE') {
            if (!$doneterminal) {
                $codet = &outbeginsub;
                $doneterminal = 1;
            }
            foreach (split(/\n/, $todo)) {
                $codet .= &outunify($_, $that{'DIR'});
            }
        }

# __BROTHER is an operative simillar to the BROTHER attribute
# It enables verifying scopes in the middle of a macro

        if ($key eq '__BROTHER') {
            $codet = &outnopop(&juice($this), $subname);
        }

# __TRUE makes a macro succeed

	if ($key eq '__TRUE') {
            $codet = &outconst(1);
	}

# __FALSE makes a macro fail

	if ($key eq '__FALSE') {
            $codet = &outconst(0);
	}

# __DO adds actual code to the buffer

        if ($key eq '__DO') {
            $codet = &outcode($todo, \%that);
        }

# __POP pops a scope

        if ($key eq '__POP') {
            $codet = &outpop($that{'SCOPE'} || $todo, $subname);
        }

# __PUSH pushes a scope

        if ($key eq '__PUSH') {
            $codet = &outpush($that{'SCOPE'} || $todo);
        }

        if ($key eq '__SET') {
            $codet = &outset($that{'VAR'} || $todo, $that{'VALUE'}
			|| $that{'VAL'});
        }

        if ($key eq '__IMPORT') {
            $codet = &outxfer('import', $that{'VAR'} || $todo, $that{'SCOPE'});
        }

        if ($key eq '__EXPORT') {
            $codet = &outxfer('export', $that{'VAR'} || $todo, $that{'SCOPE'});
        }

# __C adds C code to the parser

        if ($key eq '__C') {
            $codet = &outc($todo);
        }

        if ($key eq '__NOOP') {
		$codet = "/* do nothing */\n";
        }

	if ($key eq '__BLOCK') {
                my @those = @$this;
                shift @those;
                $codet =  &operations($sub, $superhash, @those);
        }

        if ($key eq '__CROAK') {
            $codet = &outcroak($that{'MSG'} || $todo);
        }

        if ($codet) {
            $code .= &outcond($codet, @params, $sub);
        }
    }
    return $code;
}

sub outhash {
    my ($words, @stack) = @_;
    my $sub2 = join("_", "parse", @stack);
    my $pre = $stack[-1] || "htpl";
    my $hash = &makehash($pre, "        static", map {uc($_);} @$words);
    $hash =~ s/\t/            /g;
    my @subs = map { "${sub2}_$_" } @$words;
    my $subs = join(", ", @subs);
    my $code = <<EOM;
    {
$hash
        static parser funs[] = { $subs };
        int n;
        parser fun;
        n = search_hash(&${pre}_hash, token, 0);
        if (n < 0) RETURN(0)
        fun = funs[n];
        RETURN(fun(stack, untag))
    }
EOM
    return $code;
}

sub outonce {
    my $subname = shift;
    return <<EOM;
    if (refcount > 1) {
        croak("$subname may be called only once");
    }
EOM
}
