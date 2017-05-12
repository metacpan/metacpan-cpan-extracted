package Web::App::Presenter::XSLT;
# $Id: XSLT.pm,v 1.18 2009/06/09 08:14:43 apla Exp $

use Class::Easy;

use Web::App::Presenter;
use base qw(Web::App::Presenter);

use XML::LibXML;
use XML::LibXSLT;

use Data::Dump::XML;
use Data::Dump::XML::Parser;

use IO::Easy;
use File::Spec;

use Web::App;

has 'template_dir';

our $PARSED = {};

sub headers {
	my $app = Web::App->app;
	my $headers = $app->response->headers;
	$headers->header ('Content-Type'  => 'text/html; charset=utf-8');
	$headers->header ('Cache-Control' => 'no-store');
}


# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub web_app_expand {
	my $object = shift;
}

sub _init {
	my $self = shift;
	
	my $app = Web::App->app;
	
	my $template_set = $self->{'template-set'};
	my $local_path = $self->{'local-path'};
	$local_path = 'share/presentation'
		unless defined $local_path;
	
	debug "local path is: '$local_path'";
	
	my $dir = IO::Easy->new ($app->root);
	$dir->append_in_place ($local_path, $template_set);
	
	$self->{template_dir} = $dir;
	
	$dir->as_dir->scan_tree (sub {
		my $file = shift;
		
		return 1 if $file->type eq 'dir';
		
		return if ! $file->extension or $file->extension !~ /xslt?/;
		
		$self->parse_stylesheet ($file);
	});
}

sub locate_stylesheet {
	my $self = shift;
	my $app  = shift;
	
	my $presentation = shift;
	
	my $file = $presentation->{'file'};
	 
	critical "Web::App::Request not defined: we can't detect stylesheet file name"
		unless $app->request;
	
	if (File::Spec->file_name_is_absolute ($presentation->{'file'})) {
		$file = IO::Easy->new ($presentation->{'file'});
	} else {
		$file = $self->template_dir->append ($presentation->{'file'});
	}

	# avoid usage of disk i/o
	return $file
		if exists $PARSED->{$file};
	
	my $index_path = $self->template_dir->append ($app->request->screen->id, 'index.xsl');
	
	$index_path = $self->template_dir->append ($app->request->screen->id . '.xsl')
		unless -f $index_path;
	
	return $index_path
		if exists $PARSED->{$index_path};
	
	unless (-f $file) {
		$file = $index_path;
		# warn "$file";
	}

	critical "we can't find stylesheet file '$file'"
		unless -f $file;
	
	return $file;
	
}

sub parse_stylesheet {
	my $self = shift;
	my $file = shift;
	
	my $production = shift || 0;
	
	# always return parsed stylesheet when in production
	if (exists $PARSED->{$file} and $production) {
		return $PARSED->{$file}->{s};
	}

	my $mtime = (stat $file)[9];
	
	return $PARSED->{$file}->{s}
		if exists $PARSED->{$file} and $PARSED->{$file}->{m} == $mtime; # and !$Class::Easy::DEBUG;
	
	my $xslt = XML::LibXSLT->new;

	my $stylesheet;
	
	my $t = timer ("parsing $file");
	
	eval {
		$stylesheet = $xslt->parse_stylesheet_file ($file);
		critical "can't parse stylesheet"
			unless $stylesheet;
	};
	
	$t->end;
	
	if ($@) {
		critical "Can't parse stylesheet: $file.  Please report to administrator: $@";
	}
	
	debug $mtime;
	
	$PARSED->{$file} = {s => $stylesheet, m => $mtime};

	return $stylesheet;
}

sub process {
	my $self = shift;
	my $app  = shift;
	my $data = shift;
	my %params = @_;
	
	my $t = timer ('dumping xml');
	
	my $xml = Data::Dump::XML->new;
	my $source = $xml->dump_xml ($data);
	
	#$t->lap ('xml to string');
	#my $xml_string = $source->toString (1);
	#debug $xml_string;
	#$app->root->append ('xml.xml')->as_file->store ($xml_string);
	
	# $t->lap ('xml from string');
	# my $parser = Data::Dump::XML::Parser->new;
	# $parser->parse_string ($xml_string);
	
	# $t->lap ('dom from string');
	# $parser = XML::LibXML->new;
	# $parser->parse_string ($xml_string);
	
	$t->lap ('locating stylesheet');
	
	my $file = $self->locate_stylesheet ($app, \%params);
	
	debug "using stylesheet $file to generate some content";
	
	my $production = $app->project->config->{production};
	
	my $stylesheet = $self->parse_stylesheet ($file, $production);
	
	$t->lap ('processing data transformation');
	
	my $result_object;
	my $result;
	
	eval {
		$result_object = $stylesheet->transform ($source, XML::LibXSLT::xpath_to_string (@_));
		$result = $stylesheet->output_as_chars ($result_object);
	};
	
	debug "result length = ", length $result;
	
	if ($@ or not $result_object or not $result ) {
		debug $source->toString (1);
		critical "Can't transform data:\n<strong>$@</strong>";
	}
	
	# $result = Encode::decode_utf8 ($result);
	
	unless (defined $result or $result ne '' or $result !~ m!body></body!) {
		debug "presenter's transformation result is empty";
	}
	
	$t->end;
	
	return $result;

}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub wrap_log {
	my $self = shift;
	my $content = shift;
	
	return join '', "\n<pre>\n", $content, "\n</pre>\n";
}

1;