package t::lib::Util;
use strict;

use base qw(Exporter);
our @EXPORT = qw(compare_ast compare_render);

use Test::More;

use HTML::Template::Pro;
use Text::Xslate;
use Text::Xslate::Syntax::Metakolon;
use Text::Xslate::Syntax::HTMLTemplate;

use YAML;

Text::Xslate::Syntax::HTMLTemplate::install_Xslate_as_HTMLTemplate();

sub compare_ast {
    my($template_metakolon, $template_htp, %args) = @_;

    my $parser_metakolon = Text::Xslate::Syntax::Metakolon->new();
    my $parser_htp       = Text::Xslate::Syntax::HTMLTemplate->new();

    my $ast_metakolon = $parser_metakolon->parse($template_metakolon);
    my $ast_htp       = $parser_htp->parse($template_htp);

    my $yaml_metakolon = YAML::Dump($ast_metakolon);
    my $yaml_htp       = YAML::Dump($ast_htp);

    my @unwatch_filed = qw/can_be_modifier
                           column
                           counterpart
                           is_defined
                           is_logical
                           is_reserved
                           is_value
                           lbp
                           led
                           line
                           nud
                           ubp
                           std/;
    push(@unwatch_filed, @{$args{unwatch_filed}}) if($args{unwatch_filed});
    my $unwatch_filed_re = join('|', (map { quotemeta($_) } @unwatch_filed));
    foreach my $yaml (\$yaml_metakolon, \$yaml_htp){
        $$yaml =~ s/^.*($unwatch_filed_re):.*\n//gmx;
    }
    {
        eval {
            require Text::Diff or return;
            my $diff = Text::Diff::diff(\$yaml_metakolon, \$yaml_htp);
            if ($yaml_metakolon ne $yaml_htp) {
                print STDERR "XXX ast_metakolon:", $yaml_metakolon;
                print STDERR "XXX ast_htp:", $yaml_htp;
                print STDERR "==== diff begin ====\n", $diff, "\n==== diff end ====\n";
            }
        };
    }
    is($yaml_metakolon, $yaml_htp);

    compare_render($template_htp, %args);
}

sub compare_render {
    my($template, %args) = @_;

    $args{function} ||= {};
    $args{use_global_vars}              = 0 if(not exists $args{use_global_vars});
    $args{use_has_value}                = 0 if(not exists $args{use_has_value});
    $args{use_loop_context_vars}        = 0 if(not exists $args{use_loop_context_vars});
    $args{use_path_like_variable_scope} = 0 if(not exists $args{use_path_like_variable_scope});
    $args{params} ||= {};

    if($args{function}{html_escape}){
        Text::Xslate::Syntax::HTMLTemplate::_delegate::set_html_escape_function($args{function}{html_escape});
    }

    my $engine = HTML::Template::Pro->new_scalar_ref(\$template,
                                                     path => [ 't/template' ],
                                                     functions => $args{function},
                                                     global_vars => $args{use_global_vars},
                                                     loop_context_vars => $args{use_loop_context_vars},
                                                     path_like_variable_scope => $args{use_path_like_variable_scope},
                                                 );
    $engine->param($args{params});
    my $htp_output = $engine->output_original_HTMLTemplate();
    is($htp_output, $args{expected}, "htp == expected") if(exists $args{expected});

    my $tx_output = $engine->output();
    is($tx_output,  $args{expected}, "tx == expected") if(exists $args{expected});

    is($tx_output, $htp_output, "tx == htp");

}

1;
