# 
# This is a home-grown POD-to-HTML translator, because Pod::Simple::HTML does
# not work properly.
# 



package Web::DataService::PodParser;

use strict;


# new ( options )
# 
# Create a new POD parser.

sub new {

    my ($class, $options) = @_;
    
    my $new = { default => { } };
    bless $new, $class;
    
    $new->init_doc;
    
    return $new;
}


# init_doc ( )
# 
# Initialize the parser with a new empty document model.

sub init_doc {
    
    my ($self) = @_;
    
    $self->{encoding} = 'ISO-8859-1';	# This is the default for POD
    $self->{line_no} = 0;
    $self->{body} = [];
    $self->{stack} = [$self];
    $self->{errors} = [];
    $self->{current} = undef;
    $self->{list_level} = 0;
    $self->{format_lavel} = 0;
}


# add_pod ( doc_string )
# 
# This routine takes in a document string that should be in POD format, parses
# it, and adds it to the current document model.  This routine may be called
# multiple times to add additional document content.  Note, however, that if
# you want the line numbers to mean anything then the entire source document
# must be presented in one or more calls to this method.

sub parse_pod {
    
    my $self = $_[0];
    
    my $mode = 'skip';
    my $format;
    
    # Now process the input one line at a time.
    
    foreach my $line (split /\r?\n/, $_[1])
    {
	$self->next_line;
	
	# If we are in 'skip' mode, then ignore everything until we encounter
	# a command paragraph.
	
	if ( $mode eq 'skip' )
	{
	    next unless $line =~ /^=(pod|head?|over|item|back|begin|end|for|encoding|cut)/;
	    $mode = 'pod';
	}
	
	# If we are in 'format' mode, then pass everything through literally
	# until we encounter an '=end format'.
	
	elsif ( $mode eq 'format' )
	{
	    unless ( $line =~ /^=end\s+(\w+)/ )
	    {
		$self->add_content($line);
		next;
	    }
	    
	    # If the =end didn't match the =begin, just keep going.
	    
	    unless ( $1 eq $format )
	    {
		$self->add_content($line);
		next;
	    }
	    
	    $self->end_format;
	    $mode = 'pod';
	}
	
	# If we get here, then we're in 'pod' mode.  A blank line ends a paragraph.
	
	if ( $line eq '' )
	{
	    $self->end_node;
	    next;
	}
	
	# If we've found a verbatim line, then add it to the document as
	# such.
	
	elsif ( $line =~ /^([ \t]+)(.*)/ )
	{
	    $self->add_verbatim($1, $2);
	    next;
	}
	
	# If we've got a command paragraph, process it.
	
	elsif ( $line =~ /^=(\w+)\s*(.*)/ )
	{
	    my $cmd = $1;
	    my $content = $2;
	    
	    # If this command is anything but =over, delete any pending column
	    # definitions.
	    
	    delete $self->{pending} if $cmd ne 'over';
	    
	    # If the line starts with "=for wds_nav", then just pass the
	    # remainder of the line through.  This command indicates content
	    # that should be ignored for POD output, because its purpose is
	    # web-page navigation.
	    
	    if ( $cmd eq 'for' && $content =~ qr{ ^ wds_nav \s+ (.*) }xs )
	    {
		my $rest = $1;
		
		if ( $rest =~ qr{ ^ = (\w+) \s* (.*) }xs )
		{
		    $cmd = $1;
		    $content = $2;
		}
		
		else
		{
		    $self->add_content($rest);
		    next;
		}
	    }
	    
	    # Otherwise, process the commands as we find them.
	    
	    if ( $cmd =~ /head([1-9])/ )
	    {
		$self->add_heading($1, $content);
	    }
	    
	    elsif ( $cmd eq 'over' )
	    {
		$self->add_list($content);
	    }
	    
	    elsif ( $cmd eq 'item' )
	    {
		$self->add_item($content);
	    }
	    
	    elsif ( $cmd eq 'back' )
	    {
		$self->end_list;
	    }
	    
	    elsif ( $cmd eq 'encoding' )
	    {
		$self->set_encoding($content);
	    }
	    
	    elsif ( $cmd eq 'begin' )
	    {
		$mode = 'format';
		$format = $content;
		$self->add_format($format);
	    }
	    
	    elsif ( $cmd eq 'for' )
	    {
		if ( $content =~ qr{ ^ wds_ }x )
		{
		    $self->add_directive($content);
		}
		
		elsif ( $content =~ qr{ ^ (\w+) \s+ (.*) }x )
		{
		    $self->add_format($1);
		    $self->add_content($2);
		}
		
		elsif ( $content =~ qr{ ^ (\w+) $ } )
		{
		    $self->add_format($1);
		}
	    }
	    
	    elsif ( $cmd eq 'end' )
	    {
	        $self->end_format($1);
	    }
	    
	    elsif ( $cmd eq 'cut' )
	    {
		$mode = 'skip';
	    }
	    
	    # If we have an unrecognized command, emit an error but collect up
	    # whatever's in the paragraph anyway.
	    
	    else
	    {
		$self->add_error("unrecognized command: =$cmd");
		$self->add_content($content);
	    }
	}
	
	# If we get down to here, then we've found an ordinary paragraph.  So
	# just add it to the document model.
	
	else
	{
	    $self->add_content($line);
	}
    }
    
    $self->end_node;
    
    if ( $self->{list_level} )
    {
	$self->add_error("unclosed =over section");
    }
    
    if ( $self->{format_level} )
    {
	$self->add_error("unclosed =begin section");
    }
}


sub set_encoding {
    
    my ($self, $encoding) = @_;
    
    $self->{encoding} = $encoding;
}


sub next_line {
    
    my ($self) = @_;
    
    $self->{line_no}++;
}


sub add_node {

    my ($self, $attrs) = @_;
    
    $self->end_node;
    
    my $node = $attrs;
    $node->{line_no} = $self->{line_no};
    bless $node, 'PodParser::Node';
    
    push @{$self->{stack}[-1]{body}}, $node;
    $self->{current} = $node;
    
    return $node;
}


sub add_heading {

    my ($self, $level, $content) = @_;
    
    if ( $self->{list_level} )
    {
	$self->add_error("you are either missing a =back, or you put a =head in the wrong place");
	$self->end_list while $self->{list_level};
    }
    
    $self->add_node({ type => 'head', level => $level, content => $content });
}


sub add_list {

    my ($self, $indent) = @_;
    
    $self->{list_level}++;
    
    my $list_node = $self->add_node({ type => 'list', level => $self->{list_level}, indent => $indent,
				      body => [], list_type => '' });
    
    $list_node->{column_spec} = $self->{pending}{column_spec};
    $list_node->{no_header} = $self->{pending}{no_header};
    
    delete $self->{pending};
    
    push @{$self->{stack}}, $list_node;
    $self->{current} = undef;
}


sub add_item {

    my ($self, $content) = @_;
    
    unless ( $self->{list_level} )
    {
	$self->add_error("misplaced =item: should not occur except between =over and =back");
	$self->add_list(4);
    }
    
    $self->add_node({ type => 'item', content => $content });
    
    my $current_list = $self->{stack}[-1];
    
    unless ( $current_list->{list_type} )
    {
	if ( $content eq '*' )
	{
	    $current_list->{list_type} = '*';
	}
	
	elsif ( $content =~ /^[0-9][.,)]?$/ )
	{
	    $current_list->{list_type} = '1';
	}
	
	else
	{
	    $current_list->{list_type} = 'g';
	}
    }
}


sub end_list {

    my ($self) = @_;
    
    unless ( $self->{list_level} )
    {
	$self->add_error("you have a mismatched =back here");
	return;
    }
    
    $self->{list_level}--;
    pop @{$self->{stack}};
    $self->{current} = undef;
}


sub add_format {
    
    my ($self, $format) = @_;
    
    my $format_node = $self->add_node({ type => 'format', format => $format, body => [] });
    
    push @{$self->{stack}}, $format_node;
    $self->{format_level}++;
    
    $self->{current} = $self->add_node({ type => 'literal', content => '' });
}


sub end_format {
    
    my ($self) = @_;
    
    if ( $self->{format_level} )
    {
	$self->{format_level}--;
	pop @{$self->{stack}};
	$self->{current} = undef;
    }
}


sub add_content { 

    my ($self, $content) = @_;
    
    if ( $self->{current} && ( $self->{current}{type} eq 'head' || 
			       $self->{current}{type} eq 'para' ||
			       $self->{current}{type} eq 'item' ||
			       $self->{current}{type} eq 'literal' ) )
    {
	$self->{current}{content} .= "\n$content";
    }
    
    else
    {
	$self->add_node({ type => 'para', content => $content });
    }
}


sub add_verbatim {

    my ($self, $indent, $content) = @_;
    
    $indent =~ s{\t}{        }g;
    my $indl = length($indent);
    
    if ( $self->{current} && $self->{current}{type} eq 'verbatim' )
    {
	my $extra = '';
	
	if ( $indl > $self->{current}{indent} )
	{
	    $extra = ' ' x ( $indl - $self->{current}{indent} );
	}
	
	$self->{current}{content} .= "\n$extra$content";
    }
    
    else
    {    
	$self->add_node({ type => 'verbatim', indent => $indl, content => $content });
    }
}


sub end_node {

    my ($self) = @_;
    
    if ( $self->{current} and ( $self->{current}{type} eq 'head' ||
				$self->{current}{type} eq 'para' ||
				$self->{current}{type} eq 'item' ) )
    {
	$self->{current}{content} = $self->decode_content($self->{current}{line_no}, $self->{current}{content})
    }
    
    elsif ( $self->{current} and $self->{current}{type} eq 'literal' )
    {
	$self->end_format;
    }
    
    $self->{current} = undef;
}


sub add_directive {

    my ($self, $directive) = @_;
    
    if ( $directive =~ /^(wds_table_(?:no_)?header)\s+(.*)/ )
    {
	my $cmd = $1;
	my $column_spec = $2;
	my @columns = split qr{ \s+ \| \s+ }x, $column_spec;
	
	$self->{pending}{column_spec} = \@columns;
	$self->{pending}{no_header} = 1 if $cmd eq 'wds_table_no_header';
    }
    
    elsif ( $directive =~ qr{ ^ wds_nav }xs )
    {
	# ignore this, as it would have been processed above had it had an
	# argument.
    }
    
    elsif ( $directive =~ qr{ ^ wds_title \s+ (.+) }xs )
    {
	$self->{html_title} = $1;
    }
    
    else
    {
	$self->add_error("invalid directive '$directive'");
    }
}


sub decode_content {
    
    my ($self, $line_no, $input) = @_;
    
    return '' unless defined $input;
    return $input unless $input =~ qr{ [A-Z]< }x;
    
    my @stack;
    
    while ( $input )
    {
	if ( $input =~ qr{ ^ ( [A-Z] <{1,4} ) (.*) }xs )
	{
	    $input = $2;
	    push @stack, $1;
	}
	
	elsif ( $input =~ qr{ ^ > (.*) }xs )
	{
	    $input = $1;
	    if ( $stack[-1] =~ qr{ ^ > }x ) {
		$stack[-1] .= '>';
	    } else {
		push @stack, '>';
	    }
	    
	    # try to reduce
	    
	    my $match = 0;
	    
	    foreach my $i (2..@stack)
	    {
		$match = $i, last if
		    defined $stack[-$i] &&
		    !ref $stack[-$i] &&
		    $stack[-$i] =~ qr{ ^ [A-Z] < }x &&
		    length($stack[-$i]) == length($stack[-1]) + 1;
	    }
	    
	    if ( $match )
	    {
		my $cn = { code => substr($stack[-$match], 0, 1) };
		pop @stack;
		my @content = splice @stack, -($match - 2), $match - 2;
		pop @stack;
		
		if ( $cn->{code} eq 'L' && @content )
		{
		    if ( $content[-1] =~ qr{ (.*?) \| (.*) $ }x )
		    {
			$content[-1] = $1;
			$cn->{target} = $2;
		    }
		    else
		    {
			$cn->{target} = $content[-1];
			@content = ();
		    }
		}
		
		if ( @content == 0 ) {
		    $cn->{content} = '';
		} elsif ( @content == 1 ) {
		    $cn->{content} = $content[0];
		} else {
		    $cn->{content} = \@content;
		}
		
		push @stack, $cn;
	    }
	}
	
	elsif ( $input =~ qr{ ^ (.+?) ( (?: [A-Z]< | > | $ ) .*) }xs )
	{
	    $input = $2;
	    push @stack, $1;
	}
	
	else
	{
	    push @stack, $input;
	    last;
	}
    }
	
    return \@stack;
}


sub add_error {
    
    my ($self, $errmsg) = @_;
    
    push @{$self->{errors}}, { line_no => $self->{line_no}, msg => $errmsg };
    
    $self->add_node({ type => 'error', line_no => $self->{line_no}, content => $errmsg });
}


sub generate_html {

    my ($self, $attrs) = @_;
    
    my $output = '';
    my $encoding = $self->{encoding} eq 'utf8' ? 'UTF-8' : $self->{encoding};
    my $css = $attrs->{css};
    
    $self->{generate_tables} = $attrs->{tables};
    $self->{url_generator} = $attrs->{url_generator};
    $self->{html_list_level} = 0;
    $self->{html_expect_subhead} = 0;
    $self->{html_stack} = ["<body>"];
    
    return $output unless ref $self->{body} eq 'ARRAY';
    
    # Start by going through the document and finding some basic information.
    
    unless ( $self->{html_title} )
    {
	foreach my $node ( @{$self->{body}} )
	{
	    if ( $node->{type} eq 'head' )
	    {
		$self->{html_title} = $self->generate_text_content($node->{content});
		last;
	    }
	}
	
	$self->{html_title} ||= '';
    }
    
    # Now add a header.
    
    $output .= "<html><head><title>$self->{html_title}</title>\n";
    $output .= "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=$encoding\" >\n";
    $output .= "<link rel=\"stylesheet\" type=\"text/css\" title=\"pod_stylesheet\" href=\"$css\">\n" if $css;
    $output .= "</head>\n\n";
    
    # Now the body.
    
    $output .= "<body class=\"pod\">\n\n";
    $output .= "<!-- generated by Web::DataService::PodParser.pm - do not change this file, instead alter the code that produced it -->\n";
    
    foreach my $node ( @{$self->{body}} )
    {
	$output .= $self->generate_html_node($node);
    }
    
    # If any error messages occurred, note this now.
    
    if ( ref $self->{errors} eq 'ARRAY' && @{$self->{errors}} )
    {
	$output .= "\n<h2>Errors occurred when generating this document.  Check the HTML source for details.</h2>\n\n";
    }
    
    $output .= "\n</body>\n";
    $output .= "</html>\n";
    
    return $output;
}


sub generate_html_node {

    my ($self, $node) = @_;
    
    my $output = '';
    
    if ( $node->{type} eq 'head' )
    {
	my $tag = "h$node->{level}";
	my $name = $self->generate_text_content($node->{content});
	my $content = $self->generate_html_content($node->{content});
	
	$output .= "<$tag class=\"pod_heading\"><a name=\"$name\">$content</a></$tag>\n\n";
    }
    
    elsif ( $node->{type} eq 'para' )
    {
	$output .= "<p class=\"pod_para\">" . $self->generate_html_content($node->{content}) . "</p>\n\n";
    }
    
    elsif ( $node->{type} eq 'verbatim' )
    {
	$output .= $self->generate_html_verbatim($node);
    }
    
    elsif ( $node->{type} eq 'list' )
    {
	$output .= $self->generate_html_list($node);
    }
    
    elsif ( $node->{type} eq 'format' )
    {
	if ( $node->{format} eq 'html' )
	{
	    $output .= $self->generate_html_literal($node->{body});
	}
    }
    
    elsif ( $node->{type} eq 'error' )
    {
	$output .= $self->generate_html_error($node);
    }
    
    else
    {
	$output .= "<!-- skipped node type '$node->{type}' -->\n";
    }
    
    return $output;
}


sub generate_html_list {
    
    my ($self, $node) = @_;
    
    $self->{html_list_level}++;
    
    my $output = '';
    my $in_item = 0;
    
    $output .= $self->generate_html_open_list($node);
    
    foreach my $subnode ( @{$node->{body}} )
    {
	if ( $subnode->{type} eq 'item' )
	{
	    $output .= $self->generate_html_close_item if $in_item;
	    $output .= $self->generate_html_open_item($node, $subnode);
	    $in_item = 1;
	}
	
	elsif ( $subnode->{type} eq 'para' )
	{
	    $output .= $self->generate_html_para($subnode);
	}
	
	elsif ( $subnode->{type} eq 'format' )
	{
	    if ( $subnode->{format} eq 'html' )
	    {
		$output .= $self->generate_html_literal($subnode->{body});
	    }
	}
	
	elsif ( $subnode->{type} eq 'verbatim' )
	{
	    $output .= $self->generate_html_verbatim($subnode);
	}
	
	elsif ( $subnode->{type} eq 'list' )
	{
	    $output .= $self->generate_html_list($subnode);
	}
	
	elsif ( $subnode->{type} eq 'error' )
	{
	    $output .= $self->generate_html_error($subnode);
	}
    }
    
    $output .= $self->generate_html_close_item if $in_item;
    $output .= $self->generate_html_close_list;
    $self->{html_list_level}--;
    return $output;
}



sub generate_html_open_list {

    my ($self, $node) = @_;
    
    my $class = $self->{html_list_level} > 1 ? "pod_list2" : "pod_list";
    
    if ( $self->{generate_tables} && $node->{list_type} ne '*' )
    {
	push @{$self->{html_stack}}, "<table>";
	my $output = "<table class=\"$class\">\n";
	
	if ( ref $node->{column_spec} eq 'ARRAY' )
	{
	    $self->configure_html_list($node, @{$node->{column_spec}});
	    $output .= $self->generate_html_list_header($node) unless $node->{no_header};
	}
	
	return $output;
    }
    
    elsif ( $node->{list_type} eq '*' )
    {
	push @{$self->{html_stack}}, "<ul>";
	return "<ul class=\"$class\">\n";
    }
    
    else
    {
	push @{$self->{html_stack}}, "<dl>";
	return "<dl class=\"$class\">\n";
    }
}


sub generate_html_close_list {

    my ($self) = @_;

    if ( $self->{html_stack}[-1] eq "<table>" )
    {
	$self->{html_first_item} = 0;
	pop @{$self->{html_stack}};
	return "</table>\n\n";
    }
    
    elsif ( $self->{html_stack}[-1] eq "<ul>" )
    {
	pop @{$self->{html_stack}};
	return "</ul>\n\n";
    }
    
    else
    {
	pop @{$self->{html_stack}};
	return "</dl>\n\n";
    }
}


sub configure_html_list {

    my ($self, $node, @headcol) = @_;
    
    $node->{heads} = [];
    $node->{subhead_count} = 0;
    $node->{columns} = [];
    
    my $has_subhead = 0;
    
    foreach my $col (@headcol)
    {
	my $span = undef;
	my $cols = 1;
	my $term = 0;
	
	my $column_rec = {};
	
	if ( $col =~ qr{ ^ (.*) / (\d+) $ }x )
	{
	    $col = $1;
	    if ( $2 > 1 )
	    {
		$span = $2;
		$cols = $2;
		$node->{subhead_count} += $2;
	    }
	}
	
	if ( $col =~ qr{ (.*) \* $ }x )
	{
	    $col = $1;
	    $column_rec->{term} = 1;
	}
	
	if ( $col =~ qr{ (.*) !anchor\(([^)]+)\) $ }x )
	{
	    $col = $1;
	    $column_rec->{anchor} = $2;
	}
	
	my $head_rec = { name => $col, span => $span };
	
	push @{$node->{heads}}, $head_rec;
	push @{$node->{columns}}, $column_rec foreach (1..$cols);
    }
}


sub generate_html_list_header {

    my ($self, $node) = @_;
    
    my $thclass = $self->{html_list_level} > 1 ? 'pod_th2' : 'pod_th';
    my $output .= "<tr class=\"$thclass\">";
    
    foreach my $col ( @{$node->{heads}} )
    {
	if ( $col->{span} )
	{
	    $output .= "<td colspan=$col->{span}>$col->{name}</td>";
	}
	
	elsif ( $node->{subhead_count} )
	{
	    $output .= "<td rowspan=2>$col->{name}</td>";
	}
	
	else
	{
	    $output .= "<td>$col->{name}</td>";
	}
    }
    
    $self->{expect_subhead} = 1 if $node->{subhead_count};
    
    $output .= "</tr>\n\n";
    return $output;
}


sub generate_html_open_item {
    
    my ($self, $list_node, $node) = @_;
    
    my $termclass = $self->{html_list_level} > 1 ? "pod_term2" : "pod_term";
    my $defclass = $self->{html_list_level} > 1 ? "pod_def2" : "pod_def";
    
    if ( $self->{html_stack}[-1] eq "<table>" )
    {
	my $thclass = $self->{html_list_level} > 1 ? "pod_th2" : "pod_th";
	
	unless ( ref $list_node->{heads} eq 'ARRAY' )
	{
	    my $content = $self->generate_html_content($node->{content});
	    return "<tr><td class=\"$termclass\">$content</td>\n<td class=\"$defclass\">"
	}
	
	my $text = $self->generate_html_content($node->{content});
	$text =~ s/ \)$//;
	
	my @fields = split qr{ [()/|] }, $text;
	
	if ( $self->{expect_subhead} )
	{
	    $self->{expect_subhead} = 0;
	    
	    my $output = "<tr class=\"$thclass\">";
	    
	    foreach my $i (0..$list_node->{subhead_count}-1)
	    {
		my $text = $fields[$i] || '';
		$output .= "<td>$text</td>";
	    }
	    
	    $output .= "</tr>\n\n";
	    return $output;
	}
	
	else
	{
	    my $output = "<tr>";
	    
	    foreach my $i (0..$#{$list_node->{columns}}-1)
	    {
		my $text = $fields[$i] || '';
		my $col = $list_node->{columns}[$i];
		my $class = $col->{term} ? $termclass : $defclass;
		$text = $self->generate_html_anchor($text, $col->{anchor}) if $col->{anchor};		
		$output .= "<td class=\"$class\">$text</td>";
	    }
	    
	    $output .= "\n<td class=\"$defclass\">";
	    return $output;
	}
    }
    
    elsif (  $self->{html_stack}[-1] eq "<ul>" )
    {
	return "<li class=\"$defclass\">"
    }
    
    else
    {
	my $content = $self->generate_html_content($node->{content});
	return "<dt class=\"$termclass\">$content</dt><dd class=\"$defclass\">\n";
    }
}


sub generate_html_close_item {
    
    my ($self) = @_;
    
    if ( $self->{html_stack}[-1] eq "<table>" )
    {
	return "</td></tr>\n\n"
    }
    
    elsif ( $self->{html_stack}[-1] eq "<ul>" )
    {
	return "</li>\n"
    }
    
    else
    {
	return "</dd>\n";
    }
}


sub generate_html_para {

    my ($self, $node) = @_;
    
    my $output = "<p class=\"pod_para\">";
    $output .= $self->generate_html_content($node->{content});
    $output .= "</p>\n";
    
    return $output;
}


sub generate_html_verbatim {
    
    my ($self, $node) = @_;
    
    my $output = "<pre class=\"pod_verbatim\">";
    $output .= $self->generate_text_content($node->{content});
    $output .= "</pre>\n";
}


my (%SUBST) = (
    '<' => '&lt;',
    '>' => '&gt;',
    '&' => '&amp;',
    '"' => '&quot;',
    "'" => '&apos;',
);


sub generate_html_content {

    my ($self, $content) = @_;
    
    return unless defined $content;
    
    unless ( ref $content )
    {
	$content =~ s{ ([<>&"']) }{$SUBST{$1}}xg;
	return $content;
    }
    
    elsif ( ref $content eq 'ARRAY' )
    {
	my $output = '';
	
	foreach my $subnode ( @$content )
	{
	    $output .= $self->generate_html_content($subnode);
	}
	
	return $output;
    }
    
    elsif ( ref $content eq 'HASH' )
    {
	my $code = $content->{code};
	my $subcontent = $self->generate_html_content($content->{content}) || '';
	my $href = $content->{target} || $content->{content} || '';
	
	if ( $code eq 'L' )
	{
	    # URIs of the form "node:..." or "path:..." are turned into site-relative
	    # URLs.
	    
	    if ( $href =~ qr{ ^ (?: node|op|path ) (abs|rel|site )? [:] }xs )
	    {
		my $target = $self->{url_generator}->($href) // '';
		my $blank = defined $1 && $1 eq 'abs' ? 'target="_blank"' : '';
		$subcontent ||= $target;
		return qq{<a class="pod_link" ${blank}href="$target">$subcontent</a>};
	    }
	    
	    else
	    {
		my $window = $href =~ qr{ ^ \w+ : }xs ? 'target="_blank"' : '';
		$subcontent ||= $href;
		return qq{<a class="pod_link" $window href="$href">$subcontent</a>};
	    }
	}
	
	elsif ( $code eq 'I' or $code eq 'F' )
	{
	    return "<em>" . $subcontent . "</em>";
	}
	
	elsif ( $code eq 'B' )
	{
	    return "<strong>" . $subcontent . "</strong>";
	}
	
	elsif ( $code eq 'C' )
	{
	    return "<tt>" . $subcontent . "</tt>";
	}
	
	elsif ( $code eq 'E' )
	{
	    return "&$subcontent;";
	}
    }
}


sub generate_html_anchor {
    
    my ($self, $content, $prefix) = @_;
    
    return $content if $self->{anchor_hash}{$content};
    $self->{anchor_hash}{$content} = 1;
    
    $prefix //= '';
    
    return qq{<a name="$prefix$content">$content</a>};
}


sub generate_text_content {

    my ($self, $content) = @_;
    
    unless ( ref $content )
    {
	$content =~ s{ ([<>&"']) }{$SUBST{$1}}xg;
	return $content;
    }
    
    elsif ( ref $content eq 'ARRAY' )
    {
	my $output = '';
	
	foreach my $subnode ( @$content )
	{
	    my $suboutput = $self->generate_text_content($subnode);
	    $output .= $suboutput if defined $suboutput;
	}
	
	return $output;
    }
    
    elsif ( ref $content eq 'HASH' )
    {
	my $code = $content->{code};
	
	if ( $code eq 'L' )
	{
	    return $content->{text};
	}
	
	elsif ( $code eq 'I' or $code eq 'F' or $code eq 'C' or $code eq 'B' )
	{
	    return $self->generate_text_content($content->{content});
	}
	
	elsif ( $code eq 'E' )
	{
	    return "&$content->{content};";
	}
    }
}


sub generate_html_literal {

    my ($self, $body) = @_;
    
    my $output = '';
    
    foreach my $subnode ( @$body )
    {
	$output .= $subnode->{content};
    }
    
    return $output
}


sub generate_html_error {

    my ($self, $node) = @_;
    
    my $line = $node->{line_no} ? " at line $node->{line_no}" : "";
    
    return "\n<!-- ERROR$line: $node->{content} -->\n\n";
}

1;


=head1 NAME

Web::DataService::PodParser - Pod parser module for Web::DataService

=head1 SYNOPSIS

This module provides an engine that can parse Pod and generate HTML, for use
in generating data service documentation pages.  It is used as follows:

    my $parser = Web::DataService::PodParser->new();
    
    $parser->parse_pod($doc_string);
    
    my $doc_html = $parser->generate_html({ attributes... });

=head1 METHODS

This module provides the following methods:

=head2 new

This class method creates a new instance of the parser.

=head2 parse_pod

This method takes a single argument, which must be a string containing Pod
text.  A parse tree is built from this input.

=head2 generate_html

This method uses the parse tree built by C<parse_pod> to create HTML content.
This content is returned as a single string, which can then be sent as the
body of a response message.

This method takes an attribute hash, which can include any of the following
attributes:

=head3 css

The value of this attribute should be the URL of a stylesheet, which will be
included via an HTML <link> tag.  It may be either an absolute or a
site-relative URL.

=head3 tables

If this attribute has a true value, then Pod lists will be rendered as HTML
tables.  Otherwise, they will be rendered as HTML definition lists using the
tags C<dl>, C<dt>, and C<dd>.

=head3 url_generator

The value of this attribute must be a code reference.  This is called whenever
an embedded link is encountered with one of the prefixes C<node:>, C<op:>, or
C<path:>, in order to generate a data service URL corresponding to the
remainder of the link (see
L<Web::DataService::Documentation|Web::DataService::Documentation/Embedded links>).


=head1 AUTHOR

mmcclenn "at" cpan.org

=head1 BUGS

Please report any bugs or feature requests to C<bug-web-dataservice at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Web-DataService>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2014 Michael McClennen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

