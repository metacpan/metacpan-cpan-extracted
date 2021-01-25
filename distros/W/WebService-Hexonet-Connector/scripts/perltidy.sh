#!/bin/bash
find ./ -type f \( -iname \*.pm -o -iname \*.t -o -iname \*.PL \) -exec perltidy -pro=.perltidyrc {} \;