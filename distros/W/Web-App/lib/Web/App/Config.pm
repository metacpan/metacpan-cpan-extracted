package Web::App::Config;
# $Id: Config.pm,v 1.31 2009/06/07 20:57:49 apla Exp $

use Class::Easy;

use Storable qw(retrieve nstore);

use XML::LibXML;

use Web::App::Config::Screen;

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

=pod

=head1 NAME

Web::App::Config - parsing Web::App configuration

=head1 DESCRIPTION

Web::App 

=cut

sub path_to_val {
	my ($data, $path)  = @_;
	
	my @path  = split '/', $path;
	foreach (@path) {
		$data = $data->[$_], next
			if ref $data eq 'ARRAY';
		$data = $data->{$_};
	}
	return $data;
}

sub assign_path {
	my ($data, $path, $value)  = @_;

	my @path = split '/', $path;
	my $last = pop @path;
	foreach (@path) {
		unless (exists $data->{$_}) {
			# debug "$path => $_";
			$data->{$_} = {};
		}

		$data = $data->{$_};
    }
    $data->{$last} = $value;
}


# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub last_modified_since {
	my $self = shift;
	my $last_modified = shift;
	
	my $config_file = $self->file;
	my $config_dir  = ($config_file =~ /^(.*\/)[^\/]+$/)[0]; 
	
	my $config_files = [$config_file, map {"$config_dir$_"} @{$self->int->{'files'}}];
	
	debug "compare timestamps of the config file '$config_file' and module Web::App::Config";

	my $configuration_package_file = $INC {'Web/App/Config.pm'};
	
	my $package_change = (stat ($configuration_package_file))[9];
	my $config_change  = 0;

	foreach $config_file (@$config_files) {
		my $mtime = (stat ($config_file))[9];
		$config_change = $mtime 
			if $mtime > $config_change;
	}
	
	my $outdated = 0;

	# workaround for configuration init
	if (not defined $last_modified or $last_modified == 0) {
		debug "initial configuration";
		$last_modified = $config_change;
	}
	
	if ($config_change > $last_modified) {
		debug "config changed since last modified";
		# debug "config (" . scalar localtime ($config_change) . ") changed since last modified (".scalar localtime ($last_modified).")";
		$last_modified = $config_change;
		$outdated = $last_modified;
	}

	if ($package_change > $last_modified) {
		debug "module are newer than configuration";
		# debug "module (" . scalar localtime ($package_change) . ") are newer than configuration (".scalar localtime ($last_modified).")";
		$last_modified = $package_change;
		$outdated = $last_modified;
	}
  
	return $outdated;
	
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
has 'app',  is => 'ro';
has 'file', is => 'ro';
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub int {
	return shift->{'internals'};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub screens {
	return shift->{'internals'}->{'screens'};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub modules {
	return shift->{'internals'}->{'modules'};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub presenters {
	return shift->{'internals'}->{'presenters'};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub get {
	my $class = shift;
	my $app   = shift;
	my $config_file  = shift;
	
	# first we need to check existing config in web::app
	# then we check 
	
	my $bin_config_file = $config_file . '.binary';

	my $self = {
		'file'  => $config_file,
		'app'   => $app,
		'mtime' => 0,
		'internals' => {
			'screens' => {},
			'modules' => {},
			'presenters' => {},
			'files' => {},
		}
	};
	
	my $mtime_config_binary = 0;
	my $loaded = 0;
	
	if (-f $bin_config_file) {
		$self->{'mtime'} = $mtime_config_binary = (stat ($bin_config_file))[9];
		
		debug "loading configuration binary";
		eval {
			$self->{'internals'} = retrieve ($bin_config_file);
			$loaded = 1;
		};
		
	};
	
	unless (-f $config_file) {
		critical "Can't read config from file $config_file";
	}
	
	bless $self, $class;
	
	if (not $loaded or $self->last_modified_since ($mtime_config_binary)) {
		debug 'parsing configuration';
	
		$self->parse_file ($app);
		
		nstore ($self->{'internals'}, $bin_config_file)
			or debug ("cannot write binary config to '$bin_config_file'");
		
	}
		
	# reload mtime after store or retrieve
	$self->{'mtime'} = (stat ($bin_config_file))[9];
	
	return $self;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub init_modules {
	my $self = shift;
	
	my $app  = $self->app;
	
	my $dump_separators = ',;:\/ ';
	
	foreach my $module (keys %{$self->modules}) {
		next unless $module;
		
		my $t = timer ("$module require");
		
		debug "$@"
			unless try_to_use ($module);
		
		my $params = $self->modules->{$module};
		
		my $dump = 'all';
		
		if (ref $params eq 'HASH') {
			
			if ($module->can ('init') and $params->{type} ne 'use') {
				$t->lap ("$module init");
				$module->init ($params);
			} else {
				# debug "module $module doesn't have 'init' method";
			}
		}
		
		$t->end;
	}
	
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub screen {
	my $self = shift;
	my $screen_name = shift;
	
	return $self->screens->{$screen_name};
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
sub parse_file {
	my $self = shift;
	my $app  = shift;
	
	my $screen_config_path = $self->{'file'};
	
	debug 'loading screens configuration';
	
	my $parser = new XML::LibXML;
	my $xp = $parser->parse_file ($screen_config_path);
	
	my @files = $xp->findnodes ('/config/xi:include');
	
	$self->int->{'files'} = [map {$_->getAttribute ('href')} @files];
	$parser->processXIncludes ($xp);
	
	my @plugin_list = $xp->findnodes ('/config/*[local-name() = "extension" or local-name() = "presenter" or local-name() = "use" or local-name() = "request" or local-name() = "session"]');
	
	my $modules = $self->int->{'modules'} = {};
	
	foreach my $plugin (@plugin_list) {
		my @arguments = $plugin->findnodes ('@*');
		
		my $module_params = {'type' => ''};
		
		foreach (@arguments) {
			#$module = $module->string_value;
			#debug "found '" . $plugin->nodeName . "'in module: '$module'";
			
			$module_params->{$_->localname} = $_->nodeValue;
		}
		
		my $defined_type = $module_params->{'type'};
		my $computed_type = $plugin->nodeName;
		$computed_type .= ':' . $defined_type
			if defined $defined_type and $defined_type ne '';
		
		$module_params->{'type'} = $computed_type;
		
		my $module_name = delete $module_params->{'pack'};
		
		# after parsing, store module config
		$modules->{$module_name} = $module_params;
		
		debug "found $module_name in ", $plugin->localname;
	}
	
	my $screens_node = $xp->findnodes ('/config/screens')->get_node(1);
	
	my $screens = $self->int->{'screens'} = {};
	
	$screens->{'#base-uri'} = $screens_node->findvalue ('base-url/text()');
	$screens->{'#separators'} = $screens_node->findvalue ('request-queue/@separators');
	
	$screens->{'#user-name-separator'} =
		$screens_node->findvalue ('request-queue/user-name/@separator-symbol');
	
	$screens->{'#user-name-position'} =
		$screens_node->findvalue ('request-queue/user-name/@name-position');
	
	my @screen_nodes_list = $screens_node->findnodes ('screen');
	# find all paragraphs
	
	#my $presenters_dir = $self->{'home'} . '/share/presentation/' .
	#					 $self->{'template-set'} . '/';
	
	#debug 'presenters in \'' . $presenters_dir . '\'';
	
	foreach my $screen (@screen_nodes_list) {

		my $id = $screen->getAttribute ('id');
		next
			unless defined $id;
		
		my $screen_object = Web::App::Config::Screen->create ($id);
		
		$screen_object->{auth} = $screen->getAttribute ('auth');
		
		if ($id ne '') {
			assign_path ($screens, "$id/?", $screen_object);
			$screens->{$id}->{'?'} = $screen_object
				unless defined $screens->{$id};
		} else { 
			assign_path ($screens, "?", $screen_object);
		}
		
		my $presenter_attrs = ();
		foreach my $presenter_attr (($screen->findnodes ('presentation'))[0]->attributes) {
			$presenter_attrs->{$presenter_attr->localName} =
				$presenter_attr->value;
		}
		
		die "Can't locate presenter type in screen '$id', ", $screen->toString (1)
			unless $presenter_attrs->{type};
		
		my $regexp = $screen->findvalue ('@regexp');
		$screen_object->{regexp} = $regexp
			if $regexp;
		
		$screen_object->presentation ($presenter_attrs);
		
		my $req_max_size = $screen->findvalue ('@request-max-size');
		$screen_object->request->{'max-size'} = $req_max_size
			if defined $req_max_size and $req_max_size =~ /\d+/;
		
		foreach my $context ('call', 'init/call', 'process/call') {
			my @call_nodes = $screen->findnodes ($context);
			
			my $type = ($context =~ /^(?:(init|process)\/)?call$/)[0];
			my $call = 'add_call';
			$call = "add_${type}_call"
				if defined $type;
			
			foreach my $call_node (@call_nodes) {
				my @param_attrs = $call_node->findnodes ('@*');
				
				my $params = {};
				
				foreach (@param_attrs) {
					
					my $param_name  = $_->localname;
					my $param_value = $_->nodeValue; 
					
					$params->{$param_name} = $param_value;
				}
				
				if (exists $params->{'sub'}) {
				
					my $sub = $params->{'sub'};
					$screen_object->$call ($params);
					# debug "added $call to $sub";
					my $module = ($sub =~ /(.*)(?:->|::)/)[0];
					
					if ($module =~ /^\$([^:]+)/ and $app->can ($1)) {
						# debug 'this is a call for web app internals';
					} else {
						$modules->{$module} = {type => 'use'};
					}
					
					# try_to_use ($module);
				}
			}
		}
		
		$screen_object->{'params'} = [];
		
		my @param_nodes = $screen->findnodes ('param'); 
		
		foreach my $param (@param_nodes) {
			my $field_params = {
				'name'     => undef,
				'required' => undef, 
				'type'     => undef, # regexp:... or email, as example. available types in request.pm
				'multi'    => undef, # multivalued parameter
				'filter'   => undef, # trim-space, as example. available types in request.pm
				'default'  => undef, # default values for this object
			};
			push @{$screen_object->{'params'}}, $field_params;
			
			foreach my $var (keys %$field_params) {
				$field_params->{$var} = $param->getAttribute ($var)
					if $param->hasAttribute ($var);
			}
			
			if ($field_params->{name}) {
				$screen_object->{'params_hash'}->{$field_params->{name}} = $field_params;
			}
			
			$field_params->{'default'} = [$field_params->{'default'}]
				if defined $field_params->{'default'};
			$field_params->{'default'} = []
				if $param->findvalue ('count(default)') > 0;
			
			foreach my $defaults ($param->findnodes ('default')) {
				push @{$field_params->{'default'}}, $defaults->textContent;
			}
		}
	}
	
	# use Data::Dumper;
	# debug Dumper $self;
	
	return;
}
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

=pod

sub path_from_request

this procedure return screen object and path info.

example:

request is: http://some.com/web-app/admin/article/12345

configuration is:

<config>
  ...
  <screens>
	...
	<base-url>/web-app</base-url>
	...
	<screen id='admin'>
	  <presentation type='xslt' filename='not-found.xsl'/>
	</screen>

	<screen id='admin/article'>
	  <presentation type='xslt' filename='not-found.xsl'/>
	</screen>
	...

  </screens>
</config>

sub return screen object for screen with
id = 'admin/article' and path info = '12345'

=cut
 
sub screen_from_request {
	my $self = shift;
	my $path = shift;
	
	my $screens = $self->screens;
	
	my $separators = $screens->{'#separators'};
	
	$separators =~ s/([\/\[\]\(\)])/\\$1/g;
	
	my $screen = $screens;
	
	my $matches = [];
	
	while (1) {
		my ($path_element, $tail) = split /[$separators]/, $path, 2;
		
		#debug "path element: $path_element, tail: $tail";
		
		return ($screen->{'?'}, $path, $matches)
			unless defined $path_element;
		
		if (defined $screen->{$path_element} and $screen->{$path_element}->{'?'}) {
			$screen = $screen->{$path_element};
			$path = $tail;
		} else {
			# try to find screen by regexp
			
			my $matched = 0;
			
			my @children_screen = grep {!/[\/\#\?]/} keys %$screen;

			# use Data::Dumper;
			# debug Dumper \@children_screen;
			
			foreach my $match (@children_screen) {
				my $is_regexp = $screen->{$match}->{'?'}->{regexp};
				
				next unless $is_regexp;
				
				if ($path_element =~ /$match/i and $screen->{$match}->{'?'}) {
					$screen = $screen->{$match};
					$path = $tail;
					push @$matches, $1
						if defined $1;
					$matched = 1;
				}
			}
			
			return ($screen->{'?'}, $path, $matches)
				unless $matched;
		}
	}
}

1;
