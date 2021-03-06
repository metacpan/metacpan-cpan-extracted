% mmds_let.sty -- LaTeX style for letters
%
% RCS Status      : $Id: sq_let.sty,v 1.6 1999-10-27 13:31:17+02 jv Exp jv $
% Author          : Johan Vromans
% Created On      : Fri Mar  3 11:15:17 1995
% Last Modified By: Johan Vromans
% Last Modified On: Sat Dec 14 22:27:09 2002
% Update Count    : 222
% Status          : Unknown, Use with caution!

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{mmds_let}
{ \catcode`\$=11
  \typeout{Squirrel/MMDS `mmds_let' $Revision: 1.6 $}
}

% no twoside option
\@twosidefalse

% Letterhead and logo handling.
\newif\if@letterhead \@letterheadtrue
\newif\if@logo \@logofalse

% Logo in Black/White.
\newif\if@bwlogo \@bwlogofalse

% Font setup.
\def\set@font{}

\DeclareOption{letterhead}   {\@letterheadtrue\@logotrue  }
\DeclareOption{noletterhead} {\@letterheadfalse }
\DeclareOption{logo}         {\@logotrue  }
\DeclareOption{nologo}       {\@logofalse }
\DeclareOption{bwlogo}       {\@bwlogotrue\@logotrue  }

\DeclareOption{Garamond}{
  \def\set@font{
    \typeout {Using Garamond PostScript fonts.}
    \usepackage{itcgaramond}
    \usepackage{helvlight}
  }
}

% Process options
%\ExecuteOptions{Garamond}
\ProcessOptions

\def\footertext{}

%  ****************************************
%  *               FONTS                  *
%  ****************************************
%

\set@font
\input{size11.clo}
\lineskip 1pt            % \lineskip is 1pt for all font sizes.
\normallineskip 1pt
\def\baselinestretch{1}

% Each size-changing command \SIZE executes the command
%        \@setsize\SIZE{BASELINESKIP}\FONTSIZE\@FONTSIZE
% where:
%   BASELINESKIP = Normal value of \baselineskip for that size.  (Actual 
%                  value will be \baselinestretch * BASELINESKIP.)
%
%  \FONTSIZE     = Name of font-size command.  The currently available
%                  (preloaded) font sizes are: \vpt (5pt), \vipt (6pt),
%                  \viipt (etc.), \viiipt, \ixpt, \xpt, \xipt, \xiipt,
%                  \xivpt, \xviipt, \xxpt, \xxvpt.
%  \@FONTSIZE    = The same as the font-size command except with an
%                  '@' in front---e.g., if \FONTSIZE = \xivpt then
%                  \@FONTSIZE = \@xivpt.
%
% For reasons of efficiency that needn't concern the designer,
% the document style defines \@normalsize instead of \normalsize .  This is
% done only for \normalsize, not for any other size-changing commands.

\def\@normalsize{\@setsize\normalsize{14.5pt}\xipt\@xipt
\abovedisplayskip 12pt plus3pt minus7pt%
\belowdisplayskip \abovedisplayskip
\abovedisplayshortskip  \z@ plus3pt%   
\belowdisplayshortskip  6.5pt plus3.5pt minus3pt%
\let\@listi\@listI}   % Setting of \@listi added 22 Dec 87

\def\small{\@setsize\small{13.6pt}\xipt\@xipt
\abovedisplayskip 11pt plus3pt minus6pt%
\belowdisplayskip \abovedisplayskip
\abovedisplayshortskip  \z@ plus3pt%   
\belowdisplayshortskip  6.5pt plus3.5pt minus3pt%
\def\@listi{\leftmargin\leftmargini %% Def of \@list i added 22 Dec 87
\parsep 4.5pt plus 2pt minus 1pt
            \itemsep \parsep
            \topsep 9pt plus 3pt minus 5pt}}

\def\footnotesize{\@setsize\footnotesize{12pt}\xpt\@xpt
\abovedisplayskip 10pt plus2pt minus5pt%
\belowdisplayskip \abovedisplayskip
\abovedisplayshortskip  \z@ plus3pt%   
\belowdisplayshortskip  6pt plus3pt minus3pt%
\def\@listi{\leftmargin\leftmargini %% Def of \@list i added 22 Dec 87
\topsep 6pt plus 2pt minus 2pt\parsep 3pt plus 2pt minus 1pt
\itemsep \parsep}}

\def\scriptsize{\@setsize\scriptsize{9.5pt}\viiipt\@viiipt}
\def\tiny{\@setsize\tiny{7pt}\vipt\@vipt}
\def\large{\@setsize\large{18pt}\xivpt\@xivpt}
\def\Large{\@setsize\Large{22pt}\xviipt\@xviipt}
\def\LARGE{\@setsize\LARGE{25pt}\xxpt\@xxpt}
\def\huge{\@setsize\huge{30pt}\xxvpt\@xxvpt}
\let\Huge=\huge

\normalsize  % Choose the normalsize font.


%  ****************************************
%  *            PAGE LAYOUT               *
%  ****************************************
%
% SIDE MARGINS:

\oddsidemargin   0.25cm  % Left margin on odd-numbered pages.
                         %    Note: TeX starts at 1" from the top/left.
\evensidemargin  0.25cm  % Left margin on even-numbered pages.
\marginparwidth  90pt    % Width of marginal notes.
\marginparsep    11pt    % Horizontal space between outer margin and 
                         % marginal note
\marginparpush 5pt       % Minimum vertical space between marginal notes.

\setlength{\baselineskip}{14pt} % inter-line spacing

% VERTICAL SPACING:        
                         % Top of page:
\topmargin -20mm         %    Nominal distance from top of page to top of
                         %    box containing running head.
                         %    Note: TeX starts at 1" from the top/left.
\headheight 19mm         %    Height of box containing running head.
\headsep 15mm            %    Space between running head and text.
% \topskip = 10pt        %    '\baselineskip' for first line of page.
                         % Bottom of page:
%\footheight 5mm          %    Height of box containing running foot.
\footskip 17mm           %    Distance from baseline of box containing foot 
                         %    to baseline of last line of text.

% DIMENSION OF TEXT:

\textheight 235mm        % Height of text (including footnotes and figures, 
                         % excluding running head and foot).
\textwidth 15.5cm        % Width of text line.
                         % For two-column mode: 
\columnsep 10pt          %    Space between columns 
\columnseprule 0pt       %    Width of rule between columns.

\raggedbottom             % 'ragged bottom' (all pages set to natural
                          % height, with no stretch or shrinkage) 
\frenchspacing            % no double space after period

% FOOTNOTES:

\footnotesep 12pt    % Height of strut placed at the beginning of every
                     % footnote.
\skip\footins 10pt plus 2pt minus 4pt  % Space between last line of text and 
                                       % top of first footnote.


% FLOATS:
%   The following items must be defined, even though there are no
%   floats in this style.
\floatsep 12pt plus 2pt minus 2pt
\textfloatsep  20pt plus 2pt minus 4pt
\intextsep 12pt plus 2pt minus 2pt
\dblfloatsep 12pt plus 2pt minus 2pt
\dbltextfloatsep 20pt plus 2pt minus 4pt
%\@maxsep 20pt
%\@dblmaxsep 20pt
\@fptop 0pt plus 1fil
\@fpsep 8pt plus 2fil
\@fpbot 0pt plus 1fil
\@dblfptop 0pt plus 1fil
\@dblfpsep 8pt plus 2fil
\@dblfpbot 0pt plus 1fil
\newlength{\enumindent}\setlength{\enumindent}{1.75em}


%    ****************************************
%    *           LETTER COMMANDS            *
%    ****************************************
%
% The following declarations, shown with examples, give information about the
% sender:
%
% \signature{Larry User} : goes after the closing.
%
% The letter environment: creates a new letter, starting from page 1.
% (The first page is unnumbered.)  It has a single argument, which
% is the adressee and his address, as in
%        \begin{letter}{Sam Jones \\ 
%                       Institute for Retarded Study\\ Princeton, N.J.}
%
% Text is begun with the \opening command, whose argument generates the
% salutation, as in 
%           \opening{Dear Henry,} 
% The body of the letter follows, ended by a \closing command, as in
%            \closing{Yours truly,} 
% The 'signature' is provided automatically.
%  
%  After the \closing you can put arbitrary stuff, which is typeset
%  with \parindent = 0 and no page breaking.  Commands designed
%  for use after the closing are:
%
%  \cc[cc:]{Tinker\\Evers\\Chance} -- which produces:
%        cc: Tinker
%            Evers
%            Chance
%  
%  DOCUMENT STYLE PARAMETERS AND COMMANDS.  CHANGE THESE TO
%  CUSTOMIZE LETTER STYLE.
%
%  \opening{Dear Mr. Foo:}- Command to produce everything up to and including
%     Should produce everything up to and including the 'Dear Mr. Foo:'
%     and a \par command that follows.  Since there's a \vfil at the bottom
%     of every page, it can add vertical  fil  to position a short letter.
%     It should use the following commands:
%       
%     \toname       : name part of 'to' address.  Will be one line long.
%     \toaddress    : address part of 'to' address. Lines separated by \\.
%     \fromname     : name of sender.
%     \fromaddress  : argument of current \address declaration--null if none.
%                     Should use standard institutional address if null.
%     \fromlocation : argument of current \location declaration--null if none.
%     \telephonenum : argument of current \telephone declaration--null if none.
%
%     Note that  \ifx\foo\@empty  tests for a null value of \foo.
%
%  \closing{TXT} : Generates the closing matter, and the signature.
%     An obvious thing to do is to use a \parbox for the closing
%     and the signature.  Should use the following:
%
%     \fromsig    : argument of current \signature declaration or, if null,
%                   the \fromname .
%     \stopbreaks : a macro that inhibits page breaking.
%
%  \cc[tag]{ARG}  : obvious use of a \parbox[t] .
%
%  \ps : The only thing that this needs to do is call \startbreaks, which
%        allows page breaking again.
%
%  \stopletter : Command called by \endletter to do the following:
%     * Add any desired  fil  or other material at the end of the letter.
% Much of the following is copied from the letter format in the TeXbook.

\newdimen\longindentation
\longindentation=.5\textwidth
\newdimen\indentedwidth
\indentedwidth=\textwidth
%\advance\indentedwidth -\longindentation

\def\@date{}            % Location plus date
\def\date#1{\def\@date{#1}}
\def\@ref{}             % Reference number
\def\@refi{}            % Ref tag
\def\ref[#1]#2{\def\@refi{#1}\def\@ref{#2}}
\def\@subj{}            % Subject
\def\@subji{}           % Subject tag
\def\subject[#1]#2{\def\@subji{#1}\def\@subj{#2}}
\def\opening#1{
  \thispagestyle{firstpage}
  \vspace*{10mm}
  \vbox to 38mm{\raggedright \toname \\ \toaddress \vfill}
  \vskip 21pt plus .00003fil minus 10pt
  \ifx\@subj\@empty
    \@refi~\@ref\hfill\@date\par
  \else 
    \parbox[t]{\textwidth}{
      \makebox[2cm][l]{\@refi}\@ref\hfill\@date\par
      \medskip\noindent
      \hangindent=2cm\hangafter=1
      \makebox[2cm][l]{\@subji}\@subj
      \par}
  \fi
  \vskip 21pt plus .00001fil minus 10pt
  #1\par
  \vskip 14pt plus .00001fil minus 7pt
  \nobreak}

\long\def\closing#1{
  \par\nobreak\vskip 14pt plus .00001fil minus 7pt
  \stopbreaks
  \noindent
  \parbox{\textwidth}
      {\raggedright
       \ignorespaces {\setlength{\baselineskip}{21pt} #1\\[2cm]}
       \fromsig\strut}
  \par}

\def\ps{\par\startbreaks}

\def\cc[#1]#2{\medskip\noindent
   \parbox[t]{\textwidth}{\@hangfrom{\rm #1~ }\ignorespaces #2\strut}\par}

\def\stopletter{}


%    ****************************************
%    *     THE GENERIC LETTER COMMANDS      *
%    ****************************************
%



\long\def\letter#1{\newpage
  \c@page\@ne
  \interlinepenalty=200 % smaller than the TeXbook value
  \@processto{#1}}

\def\endletter{\stopletter\@@par\pagebreak\@@par}

% \@processto gets the \toname and \toaddress from the letter
% environment's macro.  
%
\long\def\@processto#1{\@xproc #1\\@@@\ifx\toaddress\@empty 
    \else \@yproc #1@@@\fi}
\long\def\@xproc #1\\#2@@@{\def\toname{#1}\def\toaddress{#2}}
\long\def\@yproc #1\\#2@@@{\def\toaddress{#2}}

\def\stopbreaks{\interlinepenalty \@M
   \def\par{\@@par\nobreak}\let\\=\@nobreakcr
   \let\vspace\@nobreakvspace}

\def\@nobreakvspace{\@ifstar{\@nobreakvspacex}{\@nobreakvspacex}}

\def\@nobreakvspacex#1{\ifvmode\nobreak\vskip #1\relax\else
               \@bsphack\vadjust{\nobreak\vskip #1}\@esphack\fi}

\def\@nobreakcr{\vadjust{\penalty\@M}\@ifstar{\@xnewline}{\@xnewline}}

\def\startbreaks{\let\\=\@normalcr
   \interlinepenalty 200\def\par{\@@par\penalty 200}}

\def\name#1{\def\fromname{#1}}

\def\signature#1{\def\fromsig{#1}}
\def\fromsig{}

\long\def\address#1{\def\fromaddress{#1}}
\def\fromaddress{}

\def\location#1{\def\fromlocation{#1}}
\def\fromlocation{}

\def\telephone#1{\def\telephonenum{#1}}
\def\telephonenum{}


%    ****************************************
%    *            PAGE STYLES               *
%    ****************************************
%

% The letter style sets \@texttop to \vskip 0pt plus .00006fil on
% the first page of a letter, which centers a short letter on the page.
% This fil value may have to be changed for other letterheads.

%\def\@texttop{\ifnum\c@page=1\vskip 0pt plus .00006fil\relax\fi}
\def\@texttop{\relax}

\def\ps@headings{\def\@oddhead{\sl To \ignorespaces\toname \hfil \@date
    \hfil Page \thepage}\def\@oddfoot{}}

\def\ps@empty{%
        \def\@oddhead{}\def\@oddfoot{}%
        \def\@evenhead{}\def\@evenfoot{}}

\newlength{\logo@height}\setlength{\logo@height}{55pt}
%\addtolength{\logo@height}{-\logo@disp}
\newlength{\logo@offset}\setlength{\logo@offset}{47mm}
\newlength{\logo@width}\setlength{\logo@width}{60mm}
\def\ps@firstpage{%
  \def\@oddhead{%
     \hbox to \textwidth{%
      \hbox to 55mm{%
       \if@logo
        \hspace{\logo@offset}%
        \llap{\vbox{%
          \setlength{\rtextw}{\logo@width}%
          \if@bwlogo%
            \epsfbox{Squirrel_LogoSubBW.eps}%
          \else%
            \epsfbox{Squirrel_LogoSub.eps}%
          \fi%
        }}\fi\hfill}%
      \hfill
      {\ssl\raise0ex\hbox{%
         \setlength{\baselineskip}{10pt}
	 \renewcommand{\arraystretch}{0.8}
	 \begin{tabular}{@{}|l|l|@{}}
         Duvenvoordestraat 46 &
	 Web: www.squirrel.nl\\
	 2013 AG~~~Haarlem &
	 E-mail: info@squirrel.nl\\
         Tel. 023 -- 5341864 &
         Postgiro 3410691\\
	 Fax 023 -- 5342409 &
	 K.v.K. Amsterdam 34101005\\
	 ~ & ~ 
	 \end{tabular}%
       }}
     }}%
  \def\@oddfoot{\if@letterhead\ssl\footertext\fi}
  \def\@evenhead{}%
  \def\@evenfoot{}}

\def\ps@otherpages{%
  \def\@oddhead{%
      \if@logo\hbox to \textwidth{%
       \hspace{\logo@offset}%
        \llap{\vbox{%
          \setlength{\rtextw}{\logo@width}%
          \if@bwlogo%
            \epsfbox{Squirrel_LogoSubBW.eps}%
          \else%
            \epsfbox{Squirrel_LogoSub.eps}%
          \fi%
          }}\hfill}%
      \fi%
     }%
  \def\@oddfoot{}
  \let\@evenhead=\@oddhead \let\@evenfoot=\@oddfoot}


%  ****************************************
%  *           PARAGRAPHING               *
%  ****************************************
%
\parskip 7pt plus 3pt              % half-line spacing between paragraphs
\setlength{\smallskipamount}{\parskip} % half-line
\setlength{\medskipamount}{2\parskip} % single line
\setlength{\bigskipamount}{3\parskip} % one-and-a-half line
\parindent 0pt                     % Width of paragraph indentation.
\topsep 0pt plus 1pt               % Extra vertical space, in addition to 
                                   % \parskip, added above and below list and
                                   % paragraphing environments.
\partopsep 0pt plus 1pt            % Extra vertical space, in addition to 
                                   % \parskip and \topsep, added when user
                                   % leaves blank line before environment.
\itemsep 0pt plus 1pt              % Extra vertical space, in addition to
                                   % \parskip, added between list items.
%\raggedright

% The following page-breaking penalties are defined

\@lowpenalty   51      % Produced by \nopagebreak[1] or \nolinebreak[1]
\@medpenalty  151      % Produced by \nopagebreak[2] or \nolinebreak[2]
\@highpenalty 301      % Produced by \nopagebreak[3] or \nolinebreak[3]

\@beginparpenalty -\@lowpenalty    % Before a list or paragraph environment.
\@endparpenalty   -\@lowpenalty    % After a list or paragraph environment.
\@itempenalty     -\@lowpenalty    % Between list items.

% \clubpenalty         % 'Club line'  at bottom of page.
% \widowpenalty        % 'Widow line' at top of page.
% \displaywidowpenalty % Math display widow line.
% \predisplaypenalty   % Breaking before a math display.
% \postdisplaypenalty  % Breaking after a math display.
% \interlinepenalty    % SET BY THE LETTER COMMANDS
% \brokenpenalty       % Breaking after a hyphenated line.

% Float placement parameters set by some commands.  Easier to define
% them than change the commands.

\c@topnumber=2
\def\topfraction{.7}
\c@bottomnumber=1
\def\bottomfraction{.3}
\c@totalnumber=3
\def\textfraction{.2}
\def\floatpagefraction{.5}
\c@dbltopnumber= 2
\def\dbltopfraction{.7}
\def\dblfloatpagefraction{.5}
\newlength\mctcw
\renewcommand{\arraystretch}{1.5}

%% Copied from article.sty
\arraycolsep 5pt \tabcolsep 6pt \arrayrulewidth .4pt \doublerulesep 2pt 
\tabbingsep \labelsep 

%%%%%%%%%%%%%%%% Sections and such %%%%%%%%%%%%%%%%
%
% Note: zero is a 'hot' value. approximate with 0.1pt
\def\mh@section{\@startsection {section}{1}{0pt}
    {\medskipamount}{0.1pt}{\normalsize}
}
\def\mh@subsection{\@startsection{subsection}{2}{0pt}
  {\smallskipamount}{0.1pt}{\normalsize}
}
\def\mh@subsubsection{\@startsection{subsubsection}{3}
  {0pt}{0.1pt}{0.1pt}{\normalsize}
}
%
\def\rendi#1{\uppercase{#1}}
\let\rendii=\relax \let\rendiii=\relax
\newcommand{\section}[2]{
  \pagebreak[0]
  \mh@section*{\rendi{#1}}
}
\newcommand{\subsection}[1]{
  \pagebreak[0]
  \mh@subsection*{\rendii{#1}}
}
\newcommand{\subsubsection}[1]{
  \pagebreak[0]
  \mh@subsubsection*{\rendiii{#1}}
}
\newcommand{\bfcaption}[1]{
  \leavevmode
  {\bf #1 \par}
}
\newcommand{\emcaption}[1]{
  \leavevmode
  {\parskip0pt\em #1 \\}
}
%
%%%%%%%%%%%%%%%% Enumerations %%%%%%%%%%%%%%%%
%
% Two levels are supported
%
% Usage:
%
%  \begin{enum}
%  \Xitem Blah blah blah...
%  \Xitem Blah bla ...
%  ...
%  \end{enum}
%
% where X is x, n, a or l.
% Text is indented 1.75em (0.7cm). However, a minimal 
% space of 0.5em is enforced between the leader and the following text.
% Default \xitem labels are $\bullet$ for level 1, and -- for level 2.
% Alternatively, \nitem and \aitem produce numeric resp. alpha-numeric
% leaders. \litem can be used to explicitly pass a leader.
%
\def\labelitemi{\char'267}      % use PostScript bullet
\def\labelitemii{--}            % normal en-dash for second level
%
\newenvironment{enum}
  { %begin
    \ifnum \@itemdepth >1 \@toodeep
    \else
      \advance\@itemdepth \@ne
      \edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
      \list {\csname\@itemitem\endcsname}
        {
          \setlength{\topsep}{0pt plus 1pt}
          \setlength{\partopsep}{0pt plus 1pt}
          \setlength{\itemsep}{0pt plus 1pt}
          \setlength{\parsep}{\parskip}
          %%%% Disable unreleased feature %%%%
          % \setlength{\parsep}{0pt plus 1pt}
          \setlength{\itemindent}{0pt}
          \setlength{\leftmargin}{\enumindent}
          % Enforce 0.5em spacing
          \setlength{\labelsep}{0.5em}
          \setlength{\labelwidth}{\leftmargin}
          \addtolength{\labelwidth}{-\labelsep}
          \usecounter{enum\romannumeral\the\@itemdepth}
        }
    \fi
  }{ %end
    \endlist
  }
%
% Item functions
%
\def\xitem{                     % normal leader
  \def\makelabel##1{{##1}\hss}
  \@noitemargtrue\@item[\@itemlabel]}
\def\nitem{                     % numeric leader
  \def\makelabel##1{{\arabic{enum\romannumeral\the\@itemdepth}.\hss}}
  \@noitemargtrue\@item[\@itemlabel]}
\def\aitem{                     % alpha-numeric leader
  \def\makelabel##1{{\alph{enum\romannumeral\the\@itemdepth}.\hss}}
  \@noitemargtrue\@item[\@itemlabel]}
\def\litem#1{                   % explicit leader
  \def\makelabel##1{{##1}\hss}
  \@noitemargtrue\@item[{#1}]}
%
%%%%%%%%%%%%%%%% Emphasis %%%%%%%%%%%%%%%%
%
% Almost the same as \begin{em} ... \end{em}
%
\newenvironment{emphasis}{\em}{\par}
\newenvironment{strong}{\bf}{\par}
%
%%%%%%%%%%%%%%%% Pseudo-literal Environment %%%%%%%%%%%%%%%%
%
% Print ``as-is'', using small, fixed font.
%
\newenvironment{literal}
  { %begin
    \footnotesize       % 10pt
    \ptt
    \baselineskip10pt
    \parskip0pt
    \vspace\smallskipamount
%    \addtolength{\textwidth}{3cm}      % enough to fall off the page
    \frenchspacing
    \obeylines
  }{ %end
    \par
  }
%
\newenvironment{screen}
  { %begin
    \scriptsize         % 8pt
    \ptt
    \baselineskip8pt
    \parskip0pt
    \vspace\smallskipamount
%    \addtolength{\textwidth}{3cm}      % enough to fall off the page
    \frenchspacing
    \obeylines
  }{ %end
    \par
  }
%
\def\reportsize{\@setsize\scriptsize{5pt}\vpt}
\newenvironment{report}
  { %begin
    \reportsize
    \ptt
    \baselineskip6pt
    \parskip0pt
    \vspace\smallskipamount
%    \addtolength{\textwidth}{3cm}      % enough to fall off the page
    \frenchspacing
    \obeylines
  }{ %end
    \par
  }
%
%%%%%%%%%%%%%%%% Drafts %%%%%%%%%%%%%%%%
%
\def\draft#1{
\special{! userdict begin /overlaytext  (#1) def /bop-hook { overlay } def end }
}
%
%%%%%%%%%%%%%%%% EPSF Pictures %%%%%%%%%%%%%%%%
%
% Usage: \epspic[Caption]{EPS-file}
%
% The [Caption] is optional.
%
% The figure is centered, and scaled to fit if needed.
%
\input epsf.sty
\newlength{\rtextw}
\epsfverbosetrue
\def\epsfsize#1#2{\ifnum#1>\rtextw\rtextw\else#1\fi}
%
\def\epspic{\@ifnextchar[{\@xepspic}{\@yepspic}}
\def\@xepspic[#1]#2{
%  \begin{figure}[h]
    \leavevmode
    \setlength{\rtextw}{15cm}
    \addtolength{\rtextw}{-\leftmargin}
    \centerline{\epsffile{#2}}
    \centerline{\footnotesize \strut}
    \centerline{\footnotesize {#1}}
%  \end{figure}
}
\def\@yepspic#1{
%  \begin{figure}[h]
    \leavevmode
    \setlength{\rtextw}{15cm}
    \addtolength{\rtextw}{-\leftmargin}
    \centerline{\epsffile{#1}}
%  \end{figure}
}
%
%%%%%%%%%%%%%%%% KeyCaps %%%%%%%%%%%%%%%%
%
\newlength{\@xcp}
\newlength{\@ycp}\settowidth{\@ycp}{\footnotesize\sf{m}}
\def\kcp#1{%
    {%
        \settowidth{\@xcp}{\footnotesize\sf{#1}}%
        \ifnum\@xcp<\@ycp\setlength{\@xcp}{\@ycp}\fi%
        \fboxsep1pt\fbox{\vrule height7pt depth3pt width0pt%
        \footnotesize\sf\makebox[\@xcp][c]{#1}}%
    }\hspace{2pt}%
}
%


%%%%%%%%%%%%%%%% Initialization %%%%%%%%%%%%%%%%
%

\ps@otherpages               % 'plain' page style
\pagenumbering{arabic}       % Arabic page numbers
\onecolumn                   % Single-column
\@fileswfalse                % Inhibits writing of .AUX file.

%%%%%%%%%%%%%%%% Emacs support %%%%%%%%%%%%%%%%
%
% Local Variables:
% eval:(auto-fill-mode 0)
% eval:(headers)
% End:
