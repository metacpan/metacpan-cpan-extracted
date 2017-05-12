#
# Web::DataService::Plugin::TemplateToolkit.pm
# 
# This plugin provides Web::DataService with the ability to use Template.pm as
# its templating engine.  Web::DataService uses the foundation framework
# to parse HTTP requests, to marshall and send back HTTP responses, and to
# provide configuration information for the data service.
# 
# Other plugins will eventually be developed to fill this same role using
# Mojolicious and other frameworks.
# 
# Author: Michael McClennen <mmcclenn@cpan.org>


use strict;

package Web::DataService::Plugin::TemplateToolkit;

use Carp qw( carp croak );



# initialize_service ( ds )
# 
# This method is called automatically whenever a new data service instance is
# created.

sub initialize_service {
    
    my ($plugin, $ds) = @_;
    
    # Set the suffix used when auto-generating template file names from URL paths.
    
    $ds->{template_suffix} = '.tt';
}


# new_engine ( ds, config, attrs )
# 
# This method is called automatically to initialize the necessary template
# processing engines.

sub new_engine {
    
    my ($plugin, $ds, $attrs) = @_;
    
    # Start with a set of default attributes. 
    
    my $engine_attrs = {
	TAG_STYLE => 'asp',
	EVAL_PERL => 1,
    };
    
    # These can be overridden by attributes in the configuration file.
    
    my $tt_config = $ds->config_value('engines')->{template_toolkit} // $ds->config_value('template_toolkit') // {};
    
    foreach my $key ( keys %$tt_config )
    {
	$engine_attrs->{$key} = $tt_config->{$key};
    }
    
    # Add the include directory specified by the parameters to this call.
    
    my $include_value = $engine_attrs->{INCLUDE_PATH} // '';
    
    my @include_list = ref $include_value eq 'ARRAY' ? @$include_value : split(/:/, $include_value);
    
    unshift @include_list, $attrs->{template_dir};
    
    $engine_attrs->{INCLUDE_PATH} = \@include_list;
    
    # Then create a template engine.
    
    my $tt = Template->new($engine_attrs) or croak(Template->error . "\n");
    
    return $tt;
}


# render_template ( plugin, ds, engine, vars, templates )
# 
# Render the specified template (preceded by defs and/or header, and followed
# by footer) using the specified variables.

sub render_template {

    my ($plugin, $ds, $engine, $vars, $templates) = @_;
    
    # First, determine the list of templates to render, by unpacking the
    # $templates hash.
    
    my $base = '';
    
    $base .= "<% PROCESS '$templates->{defs}' %>\n" if $templates->{defs};
    $base .= "<% PROCESS '$templates->{header}' %>\n" if $templates->{header};
    $base .= "<% PROCESS '$templates->{main}' %>\n" if $templates->{main};
    $base .= "<% PROCESS '$templates->{footer}' %>\n" if $templates->{footer};
    
    # Then construct a special template to render them in order.
    
    #my $list = join(' + ', @templates);
    #my $base = "<% PROCESS $list %>";
    
    # Process it and return the result.
    
    my $output = '';
    
    $engine->process(\$base, $vars, \$output) or croak($engine->error . "\n");
    
    return $output;
}


1;
