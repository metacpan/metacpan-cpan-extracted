#!b:/bin/bash

for i in *; do
	if [ -f chmlib/$i ]; then
		echo updating $i...
		cp -f "chmlib/$i" "$i"
	fi
done
