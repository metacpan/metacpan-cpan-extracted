#===============================================================================
#
#  DESCRIPTION:  export to latex
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WriteAt::To::Latex;
use strict;
use warnings;
use Perl6::Pod::Utl;
use WriteAt::To;
use Perl6::Pod::To::Latex;
use base ( 'Perl6::Pod::To::Latex', 'WriteAt::To' );
use utf8;
our $VERSION = '0.01';

sub start_write {
    my $self = shift;
    my %tags = @_;
    $self->w->raw(<<'START');
\documentclass[a4paper,12pt,twoside]{report} %размер бумаги устанавливаем А4, шрифт 12пунктов
\usepackage[T2A]{fontenc}
\usepackage{multicol}
\usepackage[utf8]{inputenc}%включаем свою кодировку: koi8-r или utf8 в UNIX, cp1251 в Windows
\usepackage[english,russian]{babel}%используем русский и английский языки с переносами
\usepackage{amssymb,amsfonts,amsmath,mathtext,cite,enumerate,float} %подключаем нужные пакеты расширений
\usepackage[dvips]{graphicx} %хотим вставлять рисунки?
\graphicspath{{images/}}%путь к рисункам
\newcommand{\tocsecindent}{\hspace{7mm}}
\usepackage{makeidx}
\usepackage{index}
\newindex{aut}{adx}{and}{Name Index}
\makeindex
\makeatletter
\renewcommand{\@biblabel}[1]{#1.} % Заменяем библиографию с квадратных скобок на точку:
\makeatother

\usepackage{geometry} % Меняем поля страницы
\geometry{left=2cm}% левое поле
\geometry{right=1.5cm}% правое поле
\geometry{top=1cm}% верхнее поле
\geometry{bottom=2cm}% нижнее поле

\renewcommand{\theenumi}{\arabic{enumi}}% Меняем везде перечисления на цифра.цифра
\renewcommand{\labelenumi}{\arabic{enumi}}% Меняем везде перечисления на цифра.цифра
\renewcommand{\theenumii}{.\arabic{enumii}}% Меняем везде перечисления на цифра.цифра
\renewcommand{\labelenumii}{\arabic{enumi}.\arabic{enumii}.}% Меняем везде перечисления на цифра.цифра
\renewcommand{\theenumiii}{.\arabic{enumiii}}% Меняем везде перечисления на цифра.цифра
\renewcommand{\labelenumiii}{\arabic{enumi}.\arabic{enumii}.\arabic{enumiii}.}% Меняем везде перечисления на цифра.цифра

\begin{document}
START

        $self->title_page(%tags);
        $self->w->raw(
'\tableofcontents{} % auto toc
\newpage'
        );

}

sub end_write {
    my $self = shift;
    $self->w->raw(
        '\clearpage
\addcontentsline{toc}{chapter}{Index}
\printindex
'
    );
    $self->w->raw('\end{document}');
}

sub block_CHAPTER {
    my ( $self, $node ) = @_;
    my $attr = $node->get_attr;

    #close any section
    $self->switch_head_level(0);
    my $title = $node->childs->[0]->childs->[0];
    if ( $attr->{preface} ) {
        $self->w->raw( '\section*{' . $title . '}' );
        $self->w->raw(
            '\addcontentsline{toc}{section}
    {\tocsecindent{' . $title . '}}'
        );

    }
    else {
        $self->w->raw( '\section{' . $title . '}' );
    }
}

sub block_para {
    my ( $self, $el ) = @_;
    $self->visit( Perl6::Pod::Utl::parse_para( $el->childs->[0] ) );

}

sub title_page {
    my $self = shift;
    my %SEMS = @_;
    my %sems = ();

    #get text nodes;
    foreach my $k ( keys %SEMS ) {
        my $v = $SEMS{$k};
        foreach my $n (@$v) {
            for ( @{ $n->childs } ) {
                my $txt = $_->childs->[0];
                chomp $txt;
                push @{ $sems{$k} }, $txt;
            }

        }
    }
    $self->w->raw(<<'TEXT');
\begin{titlepage}
\newpage

\begin{center}
\end{center}
\vspace{6em}
\hrulefill

\begin{center}
TEXT
$self->w->raw('\Large '.$sems{TITLE}->[0]);
$self->w->raw(<<'TEXT');
\end{center}
\hrulefill

\vspace{2.5em}

\begin{center}
TEXT
    $self->w->raw('\textsc{\textbf{'.$sems{SUBTITLE}->[0].'}}');


    $self->w->raw('\begin{center}\textsc{');
foreach my $author (@{$sems{AUTHOR}}) {
    $self->w->raw( $author.  '\\\\');
}
    $self->w->raw('}\end{center}');
$self->w->raw('\end{center}');

$self->w->raw('
\vspace{\fill}

\begin{center}
\[ WriteAt \]
\end{center}

\end{titlepage}');
}
1;

