
server.modules += (
	"mod_fastcgi",
),


index-file.names += (
	
	"index.psp"

),

fastcgi.server = ( 
	
	".psp" => ( 
		"localhost" => (
			"socket"      => "<!-- $OUT=File::Spec->catfile($WEBDYNE_CACHE_DN, $FILE_FASTCGI_SOCKET) -->",
			"bin-path"    => "<!-- $OUT=File::Spec->catfile($DIR_INSTALLBIN, $FILE_FASTCGI_BIN) -->",
			"bin-environment" 	=> (
				"WEBDYNE_CACHE_DN"	=> "<!-- $OUT=$WEBDYNE_CACHE_DN -->"
			)
		)
	)
),

