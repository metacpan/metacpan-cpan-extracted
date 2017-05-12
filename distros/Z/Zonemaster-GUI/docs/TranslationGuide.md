#To translate the Zonemaster frontend interface 2 files must be added.

* The JSON structure holding all the messages of the Web Interface
* The file holding the FAQ

1. Adding the JSON structure holding all the messages of the Web Interface

The file is located in the following folder:
```
ZONEMASTER_DISTRIBUTION/zonemaster-gui//public/lang
```
This folder contains the language files.

Each language file contains a hash structure with English/Default messages as keys and the translated messges as values.
The file should be named with the [official languge code](http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) and must have .json extension.

2. Adding the file holding the FAQ
The file is located in the following folder:
```
ZONEMASTER_DISTRIBUTION/zonemaster/docs/documentation
```
The filename must be of the format: qui-faq-LANGUAGE_CODE.md
Where LANGUAGE_CODE is the standard 2 letter language code from: [official languge code](http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

3. Ading the language link to the web interface
The file that needs to be modified is locaded inb the following folder:
```
ZONEMASTER_DISTRIBUTION/zonemaster-gui//views
```
and is called index.tt

Locate the div 
```
<div class="pull-right">
```
And add your language using the language tag:
```
<lang lang="XX">XX</lang> |
```
