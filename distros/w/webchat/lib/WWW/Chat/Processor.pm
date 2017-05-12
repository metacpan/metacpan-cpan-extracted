package WWW::Chat::Processor;
$VERSION = '0.62';
use strict;
use Config qw(%Config);



sub parse
{
	my ($script, $file) = @_; 	 # get the script as a single $calar
					 # plus the file name (optional)
	$file ||= '[unknown]';		 # set the default filename	 
	my $output = '';		 # initialise the output
	my @LINES = split /\n/, $script; # split the script up into lines
	undef $script;			 # and undef the script to save memory

	my $progname = $0;		 # get the progname name for diagnostics	
	$progname =~ s,.*[\\/],,;        # and loose the path

	$output .=  "$Config{'startperl'} -w\n";  # get the shebang line

	$output .=  "# !!! DO NOT EDIT !!!\n";    # add some cruft
	$output .=  "# This program was automatically generated from '$file' by $progname\n";

# .... and awwaaaaaay we go
$output .=  <<'EOT';

use strict;

use URI ();
use HTTP::Request ();
use LWP::UserAgent ();
#use LWP::Debug qw(+);

use HTML::Form ();
use WWW::Chat;

use vars qw($ua $uri $base $req $res $status $ct @forms $form @links $TRACE);

$base ||= "http://localhost";
unless ($ua) {
    $ua  = LWP::UserAgent->new;
    $ua->agent("webchat/0.61 " . $ua->agent);
    $ua->env_proxy;
}

$TRACE = $ENV{WEBCHAT_TRACE};

EOT

	$output .=  "#line 1 \"$file\"\n";

	use Data::Dump qw(dump);

	my $seen_end;	
	my $level = 0;
	my $line =  2;
	for ($line=0; $line < scalar @LINES; $line++) 
	{
		$_ = $LINES[$line];
	    	if ($seen_end) 
		{
			$output .= $_."\n";
			next;
    		}

    		if (/^(\s*)GET\s+(\S+)\s*$/) {
			my $indent = $1;
			my $uri = $2;
			$uri = dump($uri) unless $uri =~ /^\$/;
			$output .=  "$indent#GET $uri\n";
			$output .=  "${indent}eval {\n";
			$level++;
        		$output .=  "$indent    local \$uri = URI->new_abs($uri, \$base);\n";
			$output .=  "$indent    local \$req = HTTP::Request->new(GET => \$uri);\n";
			$output .= request("$indent    ");
			$output .= line($line, $file);

		} elsif (/^(\s*)FOLLOW\s(.*)/) {
			my $indent = $1;
			my $what = $2;
			$what =~ s/\s+$//;
			$output .=  "${indent}# FOLLOW $what\n";
			$output .=  "${indent}eval {\n";
			$level++;
			if ($what =~ m,^/,) {
			    $output .=  "$indent    local \$uri;\n";
			    $output .=  "$indent    for (\@links) { \$uri = \$_->[0], last if \$_->[1] =~ $what }\n";
			    my $text = dump("FOLLOW $what");
			    $output .=  "$indent    WWW::Chat::fail($text, \$res, \$ct) unless defined \$uri;\n";
			    $output .=  "$indent    \$uri = URI->new_abs(\$uri, \$base);\n";
			} else {
			    $what = dump($what);
			    $output .=  "$indent    local \$uri = WWW::Chat::locate_link($what, \\\@links, \$base);\n";
			}
			$output .=  "$indent    local \$req = HTTP::Request->new(GET => \$uri);\n";
			$output .= request("$indent    ");
			$output .= line($line, $file);

		 } elsif (/^(\s*)FORM:?(\d+)?(?:\s+(\S+))?\s*$/) {
			my $indent = $1;
			my $form_no = $2 || 1;
		        my $uri = $3;
			$uri = dump($uri) if !defined($uri) || $uri !~ /^\$/;
			$output .=  $indent. "\$form = WWW::Chat::findform(\\\@forms, $form_no, $uri);\n";

		 } elsif (/^(\s*)EXPECT\s+(.*)$/) {
			my $indent = $1;
			my $what = $2;
			$what =~ s/;$//;
			# $output .=  "$indent#EXPECT $what\n";
			my $text = dump($what);
			$what =~ s/(OK|ERROR)/WWW::Chat::$1(\$status)/g;
			$output .=  $indent. "WWW::Chat::fail($text, \$res, \$ct) unless $what;\n";

    		} elsif (/^(\s*)BACK(?:\s+(ALL|\d+))?\s*$/) {
			my $indent = $1;
			my $done = $2 || "1";
			$output .= done($indent, $done, $line, $file, \$level);
	
    		} elsif (/^(\s*)F\s+([\w.:\-*\#]+)\s*=\s*(.*)/) {
			my $indent = $1;
			my $name   = $2;
			my $val    = dump ("$3");

			my $no = 1;
			$no = $1 if $name =~ s/:(\d+)$//;
			$name = dump($name);

			if ($no == 1) {
	    			$output .=  "$indent\$form->value($name => $val);\n";
			} else {
	    			$output .=  "$indent\$form->find_input($name, $no)->value($val);\n";
			}

    		} elsif (/^(\s*)(?:CLICK|SUBMIT)(?:\s+(\w+))?\s+(?:(\d+)\s+(\d+))?/) {
			my $indent = $1;
			my $name = $2;
			$name = dump($name);
			my $x = $3;
			my $y = $4;
			for ($x, $y) { $_ = 1 unless defined; }
			$output .=  "$indent#CLICK $name $x $y\n";
			$output .=  $indent. "eval {\n";
			$level++;
			$output .=  $indent. "    local \$uri = \$form->uri;\n";
			$output .=  $indent. "    local \$req = \$form->click($name, $x, $y);\n";
			$output .= request("$indent    ");
			$output .= line($line, $file);

    		} elsif (/^__END__$/) {
			$output .= done("", "ALL", $line, $file, \$level) if $level;
			$output .= $_."\n";
			$seen_end++;

		} else {
			$output .= $_."\n";
    		}
	}
	$output .= done("", "ALL", $line, $file, \$level) if $level;
	return $output;
}


sub done
{
    my($indent, $done, $line, $file, $rlevel) = @_;
    $done = $$rlevel if $done eq "ALL" || $done > $$rlevel;
    $$rlevel -= $done;
    my $output = '';
    for (1 .. $done) {
	$output .=  $indent. "}; WWW::Chat::check_eval(\$@);\n";
    }
    $output .=  line($line, $file) if ($done > 1);
    return $output;
}

sub request
{
    my ($indent) = @_;
    my $output = '';
    $output .=  $indent. "local \$res = WWW::Chat::request(\$req, \$ua, \$TRACE);\n";
    $output .=  $indent. "#print STDERR \$res->as_string;\n";
    $output .=  $indent. "local \$status = \$res->code;\n";
    $output .=  $indent. "local \$base = \$res->base;\n";
    $output .=  $indent. "local \$ct = \$res->content_type || \"\";\n";
    $output .=  $indent. "local \$_ = \$res->content;\n";
    $output .=  $indent. "local(\@forms, \$form, \@links);\n";
    $output .=  $indent. "if (\$ct eq 'text/html') {\n";
    $output .=  $indent. "    \@forms = HTML::Form->parse(\$_, \$res->base);\n";
    $output .=  $indent. "    \$form = \$forms[0] if \@forms;\n";
    $output .=  $indent. "    \@links = WWW::Chat::extract_links(\$_);\n";
    $output .=  $indent. "}\n";
    return $output;
}

sub line
{
    my ($line, $file) = @_;
    $line+=2;
    return  qq(#line $line "$file"\n);
}

1;
__END__

=pod

=head1 NAME

WWW::Chat::Processor - module for processing web chat script into Perl.

=head1 SYNOPSIS
  
  use WWW::Chat::Processor;

  my $perl_script = WWW::Chat::Processor::parse ($webchat);

  eval $perl_script;
  warn $@ if $@; 

=head1 DESCRIPTION

The C<webchatpp> program is a preprocessor that turns chat scripts
into plain perl scripts.  When this script is fed to perl it will
perform the chatting.  The I<webchat language> consist of perl code
with some lines interpreted and expanded by B<WWW::Chat::Processor>.

See L<webchatpp> for more details on the syntax of the webchat language.

This module implements the functionality of the B<webchatpp> script in the 
parse method in order to make it easier to use B<webchat> in your own 
programs. It also fixes problems the original B<webchatpp> had with 
being package safe however it retains backwards compatability with 
the old version. 
 
Basically - it's a huge hack and this could soooo be done better.

=head1 SEE ALSO
    
L<webchatpp>, L<WWW::Chat>, L<LWP>, L<HTML::Form>
    
=head1 COPYRIGHT
  
Copyright 2001 Simon Wistow <simon@thegestalt.org>.

Based on code originally by Gisle Aas.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
