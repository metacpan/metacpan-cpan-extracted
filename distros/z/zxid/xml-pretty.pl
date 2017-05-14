#!/usr/bin/perl
# 4.9.2009, Sampo Kellomaki (sampo@iki.fi)
# $Id: xml-pretty.pl,v 1.1 2009-09-05 02:23:41 sampo Exp $
#
# Pretty Print XML  --  Make XML almost human readable
#
# Usage: cat foo.saml | ./zxdecode | ./xml-pretty.pl
# tailf /var/zxid/log/xml.dbg | ./xml-pretty.pl
use Data::Dumper;

$ascii = 2;

# See https://wiki.archlinux.org/index.php/Color_Bash_Prompt
sub red   { $ascii > 1 ? "\e[1;31m$_[0]\e[0m" : $_[0]; }  # red text
#sub green { $ascii > 1 ? "\e[1;32m$_[0]\e[0m" : $_[0]; }
#sub red    { $ascii > 1 ? "\e[1;41m$_[0]\e[0m" : $_[0]; }  # red background, black bold text
sub green  { $ascii > 1 ? "\e[1;42m$_[0]\e[0m" : $_[0]; }
sub redy   { $ascii > 1 ? "\e[41m$_[0]\e[0m" : $_[0]; }    # red background, black text (no bold)
sub greeny { $ascii > 1 ? "\e[42m$_[0]\e[0m" : $_[0]; }
sub yely { $ascii > 1 ? "\e[43m$_[0]\e[0m" : $_[0]; }
sub bluy { $ascii > 1 ? "\e[46m$_[0]\e[0m" : $_[0]; }

$indent = '';

sub xml_pretty {
    my $res = '';
    my ($x,$at,$noindent);
    #warn "start res($res) indent($indent) data($_[0])";  # tail dup seems perl error
    for $x (split /(<\/?\w.*?>)/, $_[0]) {
	next if !length $x;
	#print "*";
	if ($x !~ /^</) {
	    $last_tag = undef;
	    if (length $x < 40) {
		if ($x =~ /^\s*$/s) {
		    #$res .= "\n";
		    #warn "HERE1($x)";
		} else {
		    #warn "HERE3($x)";
		    chomp $res;
		    $res .= green($x);
		}
		$noindent = 1;
	    } else {
		my $xx = $x;
		chomp $xx;
		if ($xx =~ /^\s*$/s) {
		    $res .= "\n";
		    #warn "HERE($xx)";
		} else {
		    #warn "HERE2($xx)";
		    $res .= $indent.greeny($xx)."\n";
		}
	    }
	    next;
	}
	if ($x =~ /^<!--/) {
	    $last_tag = undef;
	    $x =~ s/\e\[\d+m//g;
	    $res .= bluy($x)."\n";
	    $indent = '';
	    next;
	}
	if ($x =~ /^<\?/) {
	    $last_tag = undef;
	    $res .= "$indent$x\n";
	    next;
	}
	if ($x =~ /^<\//) {           # close tag
	    substr($indent,-2) = '';
	    $rx = red($x);
	    if ($noindent) {
		$res .= "</>";
	    } else {
		$xx = substr($x,2,-1);
		#warn "       x($xx)      indent($indent)\nlast_tag($last_tag) last_indent($last_indent)";
		if ($xx eq $last_tag && $indent eq $last_indent) {
		    die "Res does not end in > res($res)" if substr($res,-2) ne ">\n";
		    chop $res;
		    chop $res;
		    $res .= "/>\n";
		} else {
		    $res .= "$indent$rx\n";
		}
	    }
	    $last_tag = undef;
	    next;
	}
	if ($noindent) {
	    $noindent = 0;
	    $res .= "\n";
	}
	#            1               12   3   32 4  4
	if ($x =~ /^<([A-Za-z0-9_:-]+)(\s+(.*?))?(\/)?>$/) {
	    $last_tag = $1;
	    $last_indent = $indent;
	    $res .= "$indent<".red($1);
	    my @ats = split / /, $3;
	    if ($#ats == 0) {
		my ($name,$val) = split /=/, $ats[0], 2;
		$res .= " $name=".yely($val);
	    } else {
		for $at (@ats) {
		    my ($name,$val) = split /=/, $at, 2;
		    $res .= "\n$indent    $name=".yely($val);
		}
	    }
	    if ($4) {
		$res .= "/>\n";   
		$last_tag = undef;
	    } else {
		$res .= ">\n";   
		$indent .= '  ';
	    }
	} else {
	    die "unprocessable start tag($x) (tag must be completely on one line)";
	}
    }
    return $res;
}

while (defined($line = <STDIN>)) {
    #$line =~ tr[\r][];
    print xml_pretty($line);
}

__END__
