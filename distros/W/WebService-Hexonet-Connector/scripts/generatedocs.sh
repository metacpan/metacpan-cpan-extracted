#!/bin/bash
rm ./docs/*.md >/dev/null 2>&1

while IFS=  read -r -d $'\0'; do
    output=$(echo "${REPLY}" | rev | cut -d"/" -f1 | rev | cut -d"." -f1)
    output=$(echo "./docs/${output}.md" | perl -ne 'print lc')
    pkg=$(grep "package WebService" "${REPLY}" | cut -d" " -f2 | cut -d";" -f1)
    perldoc -oMarkdown -d"${output}" "${pkg}"
done < <(find ./lib -name "*.pm" -print0)
