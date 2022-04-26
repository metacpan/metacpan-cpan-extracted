import "wasi";

import { Console, Descriptor, FileSystem } from "as-wasi/assembly";

console.log("Hello, world!");

console.log("argv=" + process.argv.join(","));

process.env.keys().forEach( function(k) {
    console.log("env:" + k + "=" + process.env.get(k));
} );

const dirname = "/épée";

const contents = FileSystem.readdir(dirname);
if (contents) {
    console.log(`readdir(${dirname}): ` + (contents as string[]).sort().join());
}
else {
    console.log(`readdir(${dirname}) failed`);
}

const from_stdin = Descriptor.Stdin.readString();
if (from_stdin === null) {
    Console.log("got nothing on stdin!");
}
else {
    const str = from_stdin as string;
    Console.error(`from stdin: ${str}`);
}

process.exit(42);
