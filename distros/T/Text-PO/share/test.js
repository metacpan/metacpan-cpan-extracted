window.addEventListener('load', function()
{
    var testsPlanned = 0;
    var testNo = 0;
    var failed = 0;
    var startTime, endTime;
    var DEBUG = 0;
    var OK = 'ok';
    var NOT_OK = '<span style="color:#ff0000">not ok</span>';
    
    function writeTestName( testName, failReason )
    {
        _write( " " + ++testNo + ( typeof( testName ) === 'undefined' ? "" : ( " - " + testName ) + "<br />\n" ) );
        if( typeof( failReason ) !== 'undefined' )
        {
            _write( failReason );
        }
    }
    
    function diag()
    {
        var args = Array.from(arguments);
        var text = args.join( '' );
        _write( '// ' + text + "<br />\n" );
    }
    
    function ok( boolValue, testName)
    {
        if( typeof( boolValue ) === 'boolean' )
        {
            if( !boolValue ) failed++;
            _write( boolValue ? OK : NOT_OK );
        }
        else
        {
            failed++;
            _write( "not ok. Value provided (" + boolValue + ") is not a boolean value." );
        }
        writeTestName( testName );
    }
    
    function fail(testName)
    {
        failed++;
        _write( NOT_OK );
        writeTestName( testName );
    }
    
    function pass(testName)
    {
        _write( OK );
        writeTestName( testName );
    }
    
    function is( testVal1, testVal2, testName )
    {
        var failReason;
        var rv;
        if( isNumeric( testVal1 ) && testVal1 == testVal2 )
        {
            _write( OK );
            rv = true;
        }
        else if( testVal1 === testVal2 )
        {
            _write( OK );
            rv = true;
        }
        else
        {
            caller = _callInfo(2);
            console.log( testVal1 + " !== " + testVal2 );
            failed++;
            failReason  = "<pre>\n";
            failReason += "//  Failed test " + ( ( typeof( testName ) === 'undefined' ) ? testNo + 1 : "'" + testName + "'" ) + '<br />';
            failReason += "//  at " + caller.file + " line " + caller.line + '.' + '<br />';
            failReason += "//          got: '" + _encodeEntities( testVal1 ) + "'<br />";
            failReason += "//     expected: '" + _encodeEntities( testVal2 ) + "'<br />";
            failReason += "</pre>\n";
            _write( NOT_OK );
            rv = false;
        }
        writeTestName( testName, failReason );
        return( rv );
    }
    
    function isnt( testVal1, testVal2, testName )
    {
        return( !is( testVal1, testVal2, testName ) );
    }
    
    function isa_ok( objectVal, objectClass, testName )
    {
        if( typeof( objectVal ) === 'object' )
        {
            if( ( objectVal instanceof eval(objectClass) ) )
            {
                _write( OK );
            }
            else
            {
                failed++;
                _write( NOT_OK );
            }
        }
        else
        {
            failed++;
            _write( NOT_OK );
        }
        writeTestName( testName );
    }
    
    function is_deeply( data, check, testName )
    {
        if( DEBUG ) console.log( "Checking data " + data + " against validation data " + check );
        var isOk = true;
        var crawl = function( orig, test )
        {
            if( DEBUG ) console.log( "Crawling data '" + orig + "' vs '" + test + "'" );
            if( typeof( orig ) === 'object' )
            {
                var keys1 = Object.keys( test );
                var keys2 = Object.keys( orig );
                var len1 = keys1.length;
                var len2 = keys2.length;
                if( DEBUG ) console.log( "data has " + len1 + " keys vs " + len2 );
                // No need to go further
                if( len1 !== len2 )
                {
                    if( DEBUG ) console.log( "Length " + len1 + " is not same as length " + len2 );
                    return( false );
                }
                
                for( var i = 0; i < keys1.length; i++ )
                {
                    if( DEBUG ) console.log( "Checking key '" + keys1[i] + "'." );
                    // Our hash key does not exist in the test hash; no need to go further
                    if( !data.hasOwnProperty( keys1[i] ) )
                    {
                        console.log( "Data does not seem to have the key '" + keys1[i] + "'." );
                        return( false );
                    }
                    
                    // Compare the value in both hashes
                    if( !crawl( orig[ keys1[i] ], test[ keys1[i] ] ) )
                    {
                        if( DEBUG ) console.log( "Calling crawl with '" + orig[ keys1[i] ] + " and " + test[ keys1[i] ] );
                        return( false );
                    }
                }
                if( DEBUG ) console.log( "Returning true." );
                return( true );
            }
            else if( Array.isArray( orig ) )
            {
                // The size of both array do not match; no need to go further
                if( orig.length !== test.length )
                {
                    if( DEBUG ) console.log( "Length " + len1 + " is not same as length " + len2 );
                    return( false );
                }
                
                for( var i = 0; i < orig.length; i++ )
                {
                    if( ( typeof( orig[i] ) === 'undefined' && typeof( test[i] ) !== 'undefined' ) ||
                        ( typeof( orig[i] ) !== 'undefined' && typeof( test[i] ) === 'undefined' ) ||
                        ( typeof( orig[i] ) === null && typeof( test[i] ) !== null )
                        ( typeof( orig[i] ) !== null && typeof( test[i] ) === null ) )
                    {
                        if( DEBUG ) console.log( "Value '" + orig[i] + "' does not match with test value '" + test[i] + "'." );
                        return( false );
                    }
                    else if( !crawl( orig[i], test[i] ) )
                    {
                        if( DEBUG ) console.log( "Recursive crawling for value '" + orig[i] + "' against '" + test[i] + "' returned false." );
                        return( false );
                    }
                }
                return( true );
            }
            else
            {
                return( orig == test );
            }
        };
        
        if( typeof( data ) === 'undefined' )
        {
            return( false );
        }
        else if( typeof( check ) === 'undefined' )
        {
            throw new Error( "Validation data provided is undefined!" );
        }
        
        if( typeof( data ) !== 'object' &&
            !Array.isArray( data ) )
        {
            throw new Error( "Data to check must be either an hash or an array, but you provided data of type " + typeof( data ) );
        }
        else if( typeof( check ) !== 'object' &&
            !Array.isArray( check ) )
        {
            throw new Error( "Validation data must be either an hash or an array, but you provided data of type " + typeof( check ) );
        }
        else if( ( typeof( data ) === 'object' && Array.isArray( check ) ) ||
                 ( Array.isArray( data )  && typeof( check ) === 'object' ) )
        {
            throw new Error( "You provided data and validation data of different data type. Either provided both hash or both array, but not a mix of them." );
        }
        
        if( crawl( data, check ) )
        {
            _write( OK );
        }
        else
        {
            failed++;
            _write( NOT_OK );
        }
        writeTestName( testName );
    }
    
    // Credits: <https://stackoverflow.com/a/175787/4814971>
    function isNumeric(str)
    {
        if( typeof( str ) === 'number' )
        {
            return( true );
        }
        return(
            // use type coercion to parse the _entirety_ of the string (`parseFloat` alone does not do this)...
            !isNaN( str ) &&
            // ...and ensure strings of whitespace fail
            !isNaN(parseFloat(str))
        );
    }
    
    function done_testing()
    {
        if( testsPlanned > 0 && testsPlanned !== testNo )
        // if( testsPlanned > 0 && !is( testsPlanned, testNo, 'planned to run ' + testsPlanned + ' but done_testing() expects ' + testNo ) )
        {
            _write( NOT_OK );
            caller = _callInfo(2);
            var testName = 'planned to run ' + testsPlanned + ' but done_testing() expects ' + testNo;
            failed++;
            failReason  = "<pre>\n";
            failReason += "//  Failed test '" + testName + "'" + '<br />';
            failReason += "//  at " + caller.file + " line " + caller.line + '.' + '<br />';
            failReason += "// Looks like you planned " + testsPlanned + " tests but ran " + testNo;
            failReason += "</pre>\n";
            writeTestName( testName, failReason );
        }
        
        // console.log( "failed is: " + failed );
        // Results
        if( failed > 0 )
        {
            var passed = testNo - failed;
            _write( passed + " tests passed. " + failed + " failed.<br />\n" );
        }
        else
        {
            _write( "1.." + testNo + "<br />\n" );
            _write( "All tests successful.<br />\n" );
        }
        endTime = window.performance.now();
        var diffTime = endTime - startTime;
        _write( "Tests " + testNo + ", wallclock " + diffTime + " milliseconds<br />\n" );
    }
    
    function tests(total)
    {
        if( typeof( total ) !== 'number' )
        {
            throw new Error( "I was expecting a number, and instead I got '" + total + "' (" + typeof( total ) + ")" );
        }
        testsPlanned = total;
    }
    
    function _write( str )
    {
        document.body.innerHTML = document.body.innerHTML + str;
    }
    
    function _callInfo( offset )
    {
        if( typeof( offset ) !== 'number' )
        {
            throw new Error( "Offset provided is not a number." );
        }
        var e = new Error();
        // ready@http://localhost:8000/share/gettext.js:1967:17
        var regex = /^(.*?):(\d+):(\d+)$/;
        var stack = e.stack.split("\n");
        console.log( "Checking " + stack[ offset ] );
        var matches = stack[ offset ].match( regex );
        var def = {};
        def.url = matches[1];
        def.file = def.url.split( '/' ).slice(-1)[0];
        def.line = matches[2];
        def.col = matches[3];
        return( def );
    }

    function _encodeEntities( str )
    {
        // Not applicable
        if( typeof( str ) === 'undefined' ||
            typeof( str ) === null ||
            typeof( str ) === 'object' ||
            typeof( str ) === 'number' ||
            Array.isArray( str ) ||
            ( typeof( str ) === 'string' && str.length === 0 ) ||
            ( typeof( str ) === 'string' && str.indexOf( '<' ) === -1 ) )
        {
            return( str );
        }
        console.log( "String is '" + str + "' (" + typeof( str ) + ")" );
        var encoded = str.replace( /[\u00A0-\u9999<>\&]/g, function(i)
        {
            return( '&#' + i.charCodeAt(0) +';' );
        });
        return( encoded );
    }
    
    // Credits: <https://www.w3docs.com/snippets/javascript/how-to-check-if-a-value-is-an-object-in-javascript.html>
    function isObject( objValue )
    {
        return( objValue && typeof( objValue ) === 'object' && objValue.constructor === Object );
    }

    function sleep(milliseconds)
    {
        var date = Date.now();
        var currentDate = null;
        do {
            currentDate = Date.now();
        } while( currentDate - date < milliseconds );
    }
    
    window.onerror = function(msg, url, line)
    {
        failed++;
        _write( "Error in file \"" + url + "\" at line " + line + ": " + msg + '<br />' );
        return( true );
    };
    
    // tests( 52 );
    
    var startTime = window.performance.now();
    var po = new Gettext({ domain: "com.example.api", locale: "fr-FR", path: "../t", useCategory: true, debug: DEBUG });
    var po_ja;
    // ok( !( po instanceof Error ) && typeof( po ) === 'object', 'new Gettext returns object' );
    isa_ok( po, 'Gettext', 'new Gettext returns object' );
    /*    
    is( po.getLocale(), 'fr-FR', 'getLocale' );
    is( po.getTextDomain(), 'com.example.api', 'getDomain' );
    var plural = po.getPlural();
    ok( Array.isArray( plural ), 'getPlural() returns an array' );
    */
    po.ready(function()
    {
        diag( "Data is ready for test." );
        // console.log( "Got here with error: " + Gettext.ERROR );
        is( po.getLocale(), 'fr-FR', 'getLocale' );
        is( po.getTextDomain(), 'com.example.api', 'getDomain' );
        var plural = po.getPlural();
        ok( Array.isArray( plural ), 'getPlural() returns an array' );
        is( plural.length, 2, 'plural array size' );
        // diag( "plural[0] -> " + plural[0] );
        is( plural[0], 1, "total plurals for French (fr-FR)" );
        is( plural[1], 'n>1', "Offset for plural" );
        var headerStr = 'text/plain; charset=utf-8';
        var headerVal = po.parseHeaderValue( headerStr );
        isa_ok( headerVal, 'HeaderValue', 'parseHeaderValue() returns an HeaderValue object' );
        is( headerVal.value, 'text/plain', 'Header main value -> text/plain' );
        ok( isObject( headerVal.params ), 'HeaderValue.params returns an hash' );
        ok( headerVal.params.hasOwnProperty('charset' ), 'found charset attribute' );
        is( headerVal.params.charset, 'utf-8', 'charset attribute value' );
        is( po.language(), 'fr_FR', 'Language header' );
        is( po.contentEncoding(), '8bit', 'contentEncoding() -> Content-Encoding' );
        is( po.contentType(), 'text/plain; charset=utf-8', 'contentType() -> Content-Type' );
        is( po.languageTeam(), 'French <john.doe@example.com>', 'languageTeam() -> Language-Team' );
        is( po.lastTranslator(), 'John Doe <john.doe@example.com>', 'lastTranslator() -> Last-Translator' );
        is( po.mimeVersion(), '1.0', 'mimeVersion() -> MIME-Version' );
        isa_ok( po.poRevisionDate(), 'Date', 'poRevisionDate() returns a Date object' );
        is( po.poRevisionDate().toISOString(), '2019-10-03T19:44:00.000Z', 'poRevisionDate() as string' );
        isa_ok( po.potCreationDate(), 'Date', 'potCreationDate() returns a Date object' );
        is( po.potCreationDate().toISOString(), '2019-10-03T19:44:00.000Z', 'potCreationDate() as string' );
        is( po.pluralForms(), 'nplurals=1; plural=n>1;', 'pluralForms() -> Plural-Forms' );
        is( po.projectIdVersion(), 'MyProject 0.1', 'projectIdVersion() -> Project-Id-Version' );
        is( po.reportBugsTo(), 'john.doe@example.com', 'reportBugsTo() -> Report-Msgid-Bugs-To' );
        is( po.gettext( 'Bad Request' ), 'Mauvaise requête', 'gettext()' );
        is( po.dgettext( 'com.example.api', 'Bad Request' ), 'Mauvaise requête', 'dgettext()' );
        is( po.ngettext( 'You have %d message', 'You have %d messages', 3 ), 'Vous avez %d messages', 'ngettext()' );
        is( po.dngettext( 'com.example.api', 'You have %d message', 'You have %d messages', 3 ), 'Vous avez %d messages', 'dngettext()' );
        var rv = po.addItem( 'fr-FR', 'Hello!', 'Bonjour !' );
        // diag( "addItem returned: " + rv );
        is( typeof( rv ), 'object', 'addItem() returned value' );
        is_deeply( rv, { msgid: "Hello!", msgstr: "Bonjour !" }, 'addItem content' );
        is( po.gettext( 'Hello!' ), 'Bonjour !', 'addItem' );
        // The lang in <html lang=""> tag attribute
        is( po.currentLang(), 'en', 'currentLang()' );
        ok( po.exists( 'fr-FR' ), 'fr-FR exists' );
        is( po.getDataPath(), '/locale', 'getDataPath()' );
        is( po.getLangDataPath('ru_RU'), '/l10n', 'getLangDataPath()' );
        try
        {
            po.getLangDataPath( 'bad' );
            fail( 'getLangDataPath() -> Error' );
        }
        catch( e )
        {
            is( typeof( e ), 'object', 'getLangDataPath("bad") -> Error' );
        }
        var l10n = po.getLanguageDict( 'fr-FR' );
        is( typeof( l10n ), 'object', 'getLanguageDict() returns an hash' );
        is( po.getLocale(), 'fr-FR', 'getLocale()' );
        ok( Array.isArray( po.getMetaKeys() ), 'getMetaKeys() returns array' );
        
        diag( "Getting new po object for Japanese locale" );
        var po_ja = new Gettext({ domain: "com.example.api", locale: "ja-JP", path: "../t", useCategory: true, debug: DEBUG });
        po_ja.ready(function()
        {
            isa_ok( po_ja, 'Gettext', 'new Gettext returns object' );
            ok( po.exists( 'ja-JP' ), 'ja-JP exists' );
            // diag( po_ja.gettext( 'Bad Request' ) );
            // diag( JSON.stringify( po_ja.getDomainHash({ locale: 'ja-JP' }) ) );
            // diag( JSON.stringify( window.Gettext.L10N['com.example.api']['ja_JP'] ) );
            is( po_ja.gettext( 'Bad Request' ), '不正リクエスト', 'gettext() -> ja_JP' );
            var spans = po.fetchLocale( 'Bad Request' );
            ok( Array.isArray( spans ), 'fetchLocale() returns an array' );
            ok( spans.length == 2, 'fetchLocale() array size is 2' );
            is( spans[0], '<span lang="fr-FR">Mauvaise requête</span>', 'fetchLocale() array first value' );
            is( po_ja.getLocales( 'Bad Request' ), '<span lang="fr-FR">Mauvaise requête</span>' + "\n" + '<span lang="ja-JP">不正リクエスト</span>', 'getLocales()' );
            is( po.getLocalesf( 'Unknown properties: %s', 'bidule' ), '<span lang="fr-FR">Propriété inconnue: bidule</span>' + "\n" + '<span lang="ja-JP">不明プロパティ：bidule</span>', 'getLocalesf()' );
            is( po_ja.getText( 'An unexpected server error occurred. Please try again later.', 'fr_FR' ), "Une erreur inattendue s'est produite. Veuillez réessayer plus tard.", 'getText() -> fr-FR' );
            is( po_ja.getText( 'An unexpected server error occurred. Please try again later.', 'ja-JP' ), "予期せぬエラーが発生してしまいました。あと暫くして経ってからやり直してください。", 'getText() -> ja-JP' );
            is( po_ja.getTextf( 'Unknown properties: %s', 'bidule', { lang: 'fr-FR' }), "Propriété inconnue: bidule", 'getTextf() -> fr-FR' );
            ok( po_ja.isSupportedLanguage( 'fr-FR' ) && po_ja.isSupportedLanguage( 'ja-JP' ), 'isSupportedLanguage() -> fr-FR && ja-JP' );
            
            done_testing();
        }, function()
        {
            fail( "Loading data for com.example.api and locale ja-JP" );
            done_testing();
        });
    }, function()
    {
        fail( "Loading data for com.example.api and locale fr-FR" );
        done_testing();
    });
    
    // is( po.getError().length, 0, 'No error during instantiation.' );
    
});
