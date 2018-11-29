package Nested::DImportInto;
use Import::Into;

sub import {
    Test::OnlySome->import::into(1);
}

1;
