use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Text::Tmpl',
    'VERSION_FROM' => 'Tmpl.pm',
    'OBJECT'       => 'context.o default_tags.o nclist.o parser.o '
                    . 'staglist.o tagplist.o template.o varlist.o '
                    . 'tokens.o perl_tags.o Tmpl.o',
    'OPTIMIZE'     => '-O3',
    'INC'          => '-I.',
    'MAN3PODS'     => {
                        'Tmpl.pm'             => 'blib/man3/Text::Tmpl.3',
                        'libtmpl.pod'         => 'blib/man3/libtmpl.3',
                        'template_extend.pod' => 'blib/man3/template_extend.3',
                        'template_syntax.pod' => 'blib/man3/template_syntax.3',
                      },
);
