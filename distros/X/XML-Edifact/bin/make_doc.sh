#!/bin/sh

cd doc

sgml2html XML-Edifact.sgml
sgml2txt XML-Edifact.sgml
sgml2rtf XML-Edifact.sgml
col -b < XML-Edifact.txt > ../README
