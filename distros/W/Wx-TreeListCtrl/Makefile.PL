# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-
use 5.006;
use strict;
use Wx::build::MakeMaker;

use Wx::Overload::Driver;

my $driver = Wx::Overload::Driver->new
  ( files  => [ qw( ./XS/TreeListColumnInfo.xs ./XS/TreeListCtrl.xs ) ],
    header => 'cpp/ovl_const.h',
    source => 'cpp/ovl_const.cpp',
    );
    
$driver->process;

wxWriteMakefile(
    NAME            => 'Wx::TreeListCtrl',
    VERSION_FROM    => 'lib/Wx/TreeListCtrl.pm',
    ABSTRACT_FROM   => 'lib/Wx/TreeListCtrl.pm',
    AUTHOR          => 'Mark Wardell <mwardell@cpan.org>',
    WX_CORE_LIB     => 'core base',
    PREREQ_PM       => { Wx   => '0.57', },
    CONFIGURE_REQUIRES => {
                         'Wx::build::MakeMaker' => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://wxperltreelistctrl.googlecode.com/svn/trunk',
            keywords => ['tree','data control','GUI','wx'],
        },
    },
    clean           => { FILES => 'cpp/ovl_const.h cpp/ovl_const.cpp overload.lst'},
);
