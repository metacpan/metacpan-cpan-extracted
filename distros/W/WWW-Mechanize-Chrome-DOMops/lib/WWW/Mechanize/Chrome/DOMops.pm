package WWW::Mechanize::Chrome::DOMops;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = (
	# I wanted to distinguish find() from similar subs from foreign modules
	# and domops_find() came. But for consistency now all are prefixed ...
	'domops_zap',
	'domops_find',
	'domops_VERBOSITY',
	'domops_read_dom_element_selectors_from_JSON_string',
	'domops_read_dom_element_selectors_from_JSON_file',
	'domops_wait_for_page_to_load'
);

our $VERSION = '0.11';

use String::Escape qw/escape/;

use Data::Roundtrip qw/perl2dump json2perl perl2json no-unicode-escape-permanently/;

# caller can set this to 0,1,2,3
our $domops_VERBOSITY = 0;

# Here are JS helpers. We use these in our own internal JS code.
# They are visible to the user's JS callbacks.
my $_aux_js_functions = <<'EOJ';
const getAllChildren = (htmlElement) => {
	if( (htmlElement === null) || (htmlElement === undefined) ){
		console.log("getAllChildren() : warning null input");
		return [];
	}
	if( domops_VERBOSITY > 1 ){ console.log("getAllChildren() : called for element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); }

	if (htmlElement.children.length === 0) return [htmlElement];

	let allChildElements = [];

	for (let i = 0; i < htmlElement.children.length; i++) {
		let children = getAllChildren(htmlElement.children[i]);
		if (children) allChildElements.push(...children);
	}
	allChildElements.push(htmlElement);

	return allChildElements;
};
EOJ

# The input is a hashref of parameters
# the 'element-*' parameters specify some condition to be matched
# for example id to be such and such or better use CSS or XPath selectors.
# The conditions can be combined either as a union (OR)
# or an intersection (AND). Default is intersection.
# The param || => 1 changes this to Union.
#
# NOTE: the selector spec(s) are saved in an array and then
#  are converted into JSON and then
# passed on to javascript (via mech->eval()) to JSON.parse()
# and then are array which we loop over. Quoting may be
# wrong when you get problems, check quoting first.
# it returns a hash which contains 'status' as following:
#  -3 parameters error
#  -2 if javascript failed
#  -1 if one or more of the specified selectors failed to match
#  >=0 : the number of elements matched
# if 'status' is < 0, then there is a 'message' item with
# the error message.
# if 'status' is >= 0 then there is a 'found' array with
# all the element ids matched.
sub domops_find {
	my $params = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 0 ){ print STDOUT "$whoami (via $parent), line ".__LINE__." : called ...\n" }

	my $amech_obj = exists($params->{'mech-obj'}) ? $params->{'mech-obj'} : undef;
	if( ! $amech_obj ){
		my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : a mech-object is required via 'mech-obj'.";
		print STDERR $anerrmsg."\n";
		return {
			'status' => -3,
			'message' => $anerrmsg
		}
	}
	my $js_outfile = exists($params->{'js-outfile'}) ? $params->{'js-outfile'} : undef;

	# html element selectors:
	# e.g. params->{'element-name'} = ['a','b'] or params->{'element-name'} = 'a'
	my @known_selectors = ('element-name', 'element-class', 'element-tag', 'element-id', 'element-cssselector', 'element-xpathselector');
	my (%selectors, $have_a_selector, $m);
	for my $asel (@known_selectors){
		next unless exists($params->{$asel}) and defined($params->{$asel});
		if( ref($params->{$asel}) eq '' ){ # Scalar a string selector, make it into an array
			#$selectors{$asel} = '["' . $params->{$asel} . '"]';
			$selectors{$asel} = [ $params->{$asel} ];
		} elsif( ref($params->{$asel}) eq 'ARRAY' ){ # it's an array
			#$selectors{$asel} = '["' . join('","', @{$params->{$asel}}) . '"]';
			$selectors{$asel} = $params->{$asel};
		} else {
			my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : error, parameter '$asel' expects a scalar or an ARRAYref and not '".ref($params->{$asel})."'.";
			print STDERR $anerrmsg."\n";
			return {
				'status' => -3,
				'message' => $anerrmsg
			}
		}
		$have_a_selector = 1;
		if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 1 ){ print STDOUT perl2dump($selectors{$asel})."$whoami (via $parent), line ".__LINE__." : found selector '$asel' with above content.\n" }
	}
	if( not $have_a_selector ){
		my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : at least one selector must be specified by supplying one or more parameters from these: '".join("','", @known_selectors)."'.";
		print STDERR $anerrmsg."\n";
		return {
			'status' => -3,
			'message' => $anerrmsg
		}
	}

	# If specified it will add an ID to any html element which does not have an ID (field id).
	# The ID will be prefixed by this string and have an incrementing counter postfixed
	my $insert_id_if_none;
	if( exists($params->{'insert-id-if-none-random'}) && defined($params->{'insert-id-if-none-random'}) ){
		# we are given a prefix and also asked to add our own rands
		$insert_id_if_none = $params->{'insert-id-if-none-random'} . int(rand(1_000_000)) . int(rand(1_000_000)) . int(rand(1_000_000));
	} elsif( exists($params->{'insert-id-if-none'}) && defined($params->{'insert-id-if-none'}) ){
		# we are given a prefix and no randomisation, both cases we will be adding the counter at the end
		$insert_id_if_none = $params->{'insert-id-if-none'};
	}

	# these callbacks are pieces of javascript code to execute but they should not have the function
	# preamble or postamble, just the function content. The parameter 'htmlElement' is what
	# we pass in and it is the currently matched HTML element.
	# whatever the callback returns (including nothing = undef) will be recorded
	# The callbacks are in an array with keys 'code' and 'name'.
	# The callbacks are executed in the same order they have in this array
	# the results are recorded in the same order in an array, one result for one htmlElement matched.
	# callback(s) to execute for each html element matched in the 1st level (that is, not including children of match)
	my @known_callbacks = ('find-cb-on-matched', 'find-cb-on-matched-and-their-children');
	my %callbacks;
	for my $acbname (@known_callbacks){
		if( exists($params->{$acbname}) && defined($m=$params->{$acbname}) ){
			# one or more callbacks must be contained in an ARRAY
			if( ref($m) ne 'ARRAY' ){
				my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : error callback parameter '$acbname' must be an array of hashes each containing a 'code' and a 'name' field. You supplied a '".ref($m)."'.";
				print STDERR $anerrmsg."\n";
				return { 'status' => -3, 'message' => $anerrmsg }
			}
			for my $acbitem (@$m){
				# each callback must be a hash with a 'code' and 'name' key
				if( ! exists($acbitem->{'code'})
				 || ! exists($acbitem->{'name'})
				){
					my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : error callback parameter '$acbname' must be an array of hashes each containing a 'code' and a 'name' field.";
					print STDERR $anerrmsg."\n";
					return { 'status' => -3, 'message' => $anerrmsg }
				}
			}
			$callbacks{$acbname} = $m;
			if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 0 ){ print STDOUT "$whoami (via $parent), line ".__LINE__." : adding ".scalar(@$m)." callback(s) of type '$acbname' ...\n" }
		}
	}

	# each specifier yields a list each, how to combine this list?:
	#    intersection (default): specified with '||' => 0 or '&&' => 1 in params,
	#	the list is produced by the intersection set of all individual result sets (elements-by-name, by-id, etc.)
	#	This means an item must exist in ALL result sets which were specified by the caller.
	# or
	#    union: specified with '||' => 1 or '&&' => 0 in params
	#       the list is produced by the union set of all individual result sets (elements-by-name, by-id, etc.)
	#       This means an item must exist in just one result set specified by the caller.
	# Remember that the caller can specify elements by name ('element-name' => '...'), by id, by tag etc.
	my $Union = (exists($params->{'||'}) && defined($params->{'||'}) && ($params->{'||'} == 1))
		 || (exists($params->{'&&'}) && defined($params->{'&&'}) && ($params->{'&&'} == 0))
		 || 0 # <<< default is intersection (superfluous but verbose)
	;

	if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 1 ){ print "$whoami (via $parent), line ".__LINE__." : using ".($Union?'UNION':'INTERSECTION')." to combine the matched elements.\n"; }
	# there is no way to break a JS eval'ed via perl and return something back unless
	# one uses gotos or an anonymous function, see
	#    https://www.perlmonks.org/index.pl?node_id=1232479
	# Here we are preparing JS code to be eval'ed in the page

	# do we have user-specified JS code for adjusting the return value of each match?
	# this falls under the 'element-information-from-matched' input parameter
	# if we don't have we use our own default so this JS function will be used always for extracting info from matched
	# NOTE: a user-specified must make sure that it returns a HASH
	my $element_information_from_matched_function = "const element_information_from_matched_function = (htmlElement) => {\n";
	if( exists($params->{'element-information-from-matched'}) && defined($m=$params->{'element-information-from-matched'}) ){
		$element_information_from_matched_function .= $m;
	} else {
		# there is no user-specified function for extracting info from each matched element, so use our own default:
		$element_information_from_matched_function .= "\t" . 'return {"tag" : htmlElement.tagName, "id" : htmlElement.id};';
	}
	$element_information_from_matched_function .= "\n}; // end element_information_from_matched_function\n";

	# do we have user-specified JS code for callbacks?
	# this falls under the 'find-cb-on-matched' and 'find-cb-on-matched-and-their-children' input parameters
	my $cb_functions = "const cb_functions = {\n";
	for my $acbname (@known_callbacks){
		next unless exists $callbacks{$acbname};
		$m = $callbacks{$acbname};
		$cb_functions .= "  \"${acbname}\" : [\n";
		for my $acb (@$m){
			my $code = $acb->{'code'};
			my $name = $acb->{'name'}; # something to identify it with, can contain any chars etc.
			$cb_functions .= <<EOJ;
    {"code" : (htmlElement) => { ${code} }, "name" : "${name}"},
EOJ
		}
		$cb_functions =~ s/,\n$//m;
		$cb_functions .= "\n  ],\n";
	}
	$cb_functions =~ s/,\n*$//s;
	$cb_functions .= "\n};";

	# This is the JS code to execute, we restrict its scope
	# TODO: don't accumulate JS code for repeated domops_find() calls on the same mech obj
	#       perhaps create a class which is overwritten on multiple calls?
	my $jsexec = '{ /* our own scope */' # <<< run it inside its own scope because multiple mech->eval() accumulate and global vars are re-declared etc.
	      . "\n\nconst domops_VERBOSITY = ${WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY};\n\n"
	      . $_aux_js_functions . "\n\n"
	      . $element_information_from_matched_function . "\n\n"
	      . $cb_functions . "\n\n"
		# and now here-doc an anonymous function which will be called to orchestrate the whole operation, avanti maestro!
	      . <<'EOJ';
// the return value of this anonymous function is what perl's eval will get back
(function(){
	var retval = -1; // this is what we return
	// returns -2 for when selector JSON spec does not parse
	// returns -1 for when one of the element searches matched nothing
	// returns 0 if after intersection/union nothing was found to delete
	// returns >0 : the number of elements deleted
	var anelem, anelems, i, j;
	var allfound = [];
	var allfound_including_children = [];
	var elems = [];
	var objselvalue;
EOJ
	for my $asel (@known_selectors){ $jsexec .= "\telems['${asel}'] = null;\n"; }
	$jsexec .= <<EOJ;
	const union = ${Union};
EOJ
	$jsexec .= "\tconst insert_id_if_none = ".(defined($insert_id_if_none) ? "'${insert_id_if_none}'" : "null").";\n";
	$jsexec .= "\tconst known_callbacks = [\"" . join('", "', @known_callbacks) . "\"];\n";
	my %selfuncs = (
		'element-class' => 'document.getElementsByClassName',
		'element-tag' => 'document.getElementsByTagName',
		'element-name' => 'document.getElementsByName',
		'element-id' => 'document.getElementById',
		'element-cssselector' => 'document.querySelectorAll',
		'element-xpathselector' => 'document.evaluate'
	);
	for my $aselname (keys %selectors){
		my $selfunc = $selfuncs{$aselname};
		my $_aselvalue = $selectors{$aselname};
		my $aselvalue = String::Escape::escape('qprintable', perl2json($_aselvalue));
		# we convert the selector(s) into json
		# which 1) quotes it properly and 2) avoid pitfalls
		# like comma at end of array.
		if( ! defined $aselvalue ){
			my $anerrmsg = "$whoami (via $parent), line ".__LINE__." : error, check the syntax of selector spec '$aselname' because it failed to be converted to JSON: ${_aselvalue}";
			print STDERR $anerrmsg."\n";
			return {
				'status' => -3,
				'message' => $anerrmsg
			}
		}
		$jsexec .= <<EOJ; # ... appending to JS started above
	/* selector '${aselname}' was specified as JSON: ${aselvalue} */
	try { objselvalue = JSON.parse(${aselvalue}); }
	catch(e){
		msg = "error, selector spec passed as JSON string does not parse: "+${aselvalue};
		console.log("$whoami (via $parent) via js-eval : "+msg);
		return {"status":-2,"message":msg};
	}
	for(let asel of objselvalue){
		// this can return an array or a single html element (e.g. in ById)
		if( domops_VERBOSITY > 1 ){ console.log("$whoami (via $parent) via js-eval : selecting elements with this function '${selfunc}' ..."); }
		let tmp;
		// ALSO, searching within document.body may fail because body may not have already been
		// settled, so we change document.evaluate()'s 2nd parameter from 'document.body' to 'document'
		if( '${selfunc}'=='document.evaluate' ){
			// special treatment for xpath...
			tmp = document.evaluate(
				asel,
				document,
				null,
				XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,
				null
			);
		} else { tmp = ${selfunc}(asel); }

		/* if getElementsBy return an HTMLCollection,
		   getElementBy (e.g. ById) returns an html element
		   and querySelectorAll returns NodeList
		   convert them all to an array:
		   NOTE: document.evaluate(XPath selector) returns
		   an XPathResult object which needs special treatment
		   to become an array. Additionally, use
		     UNORDERED_NODE_SNAPSHOT_TYPE as the type, otherwise
		   you will not get a size etc.
		     see https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/resultType
		*/
		if( (tmp === null) || (tmp === undefined) ){
			if( domops_VERBOSITY > 1 ){ console.log("$whoami (via $parent) : nothing matched."); }
			continue;
		}
		if( tmp.constructor.name === 'XPathResult' ){
			anelems = [];
			for (let i=0;i<tmp.snapshotLength;i++){
				anelems.push(tmp.snapshotItem(i));
			}
		} else {
			anelems = (tmp.constructor.name === 'HTMLCollection') || (tmp.constructor.name === 'NodeList')
				? Array.prototype.slice.call(tmp) : [tmp]
			;
		}
		if( anelems == null ){
			if( union == 0 ){
				msg = "$whoami (via $parent) via js-eval : element(s) selected with ${aselname} '"+asel+"' not found, this specifier has failed and will not continue with the rest (use '||' => 1 to the parameters in order to find as many as there are and not fail on the missing ones).";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("$whoami (via $parent) via js-eval : element(s) selected with ${aselname} '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		if( anelems.length == 0 ){
			if( union == 0 ){
				msg = "$whoami (via $parent) via js-eval : element(s) selected with ${aselname} '"+asel+"' not found, this specifier has failed and will not continue with the rest (use '||' => 1 to the parameters in order to find as many as there are and not fail on the missing ones).";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("$whoami (via $parent) via js-eval : element(s) selected with ${aselname} '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		// now anelems is an array
		if( elems["${aselname}"] === null ){
			elems["${aselname}"] = anelems;
		} else {
			elems["${aselname}"] = elems["${aselname}"].length > 0 ? [...elems["${aselname}"], ...anelems] : anelems;
		}
		allfound = allfound.length > 0 ? [...allfound, ...anelems] : anelems;
		if( domops_VERBOSITY > 1 ){
			console.log("$whoami (via $parent) via js-eval : found "+elems["${aselname}"].length+" elements selected with ${aselname} '"+asel+"' (there may be duplicates which will be sorted later)");
			if( (domops_VERBOSITY > 2) && (elems["${aselname}"].length>0) ){
				for(let el of elems["${aselname}"]){ console.log("  tag: '"+el.tagName+"', id: '"+el.id+"'"); }
				console.log("--- end of the elements selected with ${aselname} (list may contain duplicate, they will be sorted out later).");
			}
		}
	}
EOJ
	} # for my $aselname (keys %selectors){

	# if even one specified has failed, we do not reach this point, it returns -1
	if( $Union ){
		# union of all elements matched individually without duplicates:
		# we just remove the duplicates from the allfound
		# from https://stackoverflow.com/questions/9229645/remove-duplicate-values-from-js-array (by Christian Landgren)
		$jsexec .= "\t// calculating the UNION of all elements found...\n";
		if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 1 ){ $jsexec .= "\t".'console.log("calculating the UNION of all elements found (without duplicates).\n");'."\n"; }
		$jsexec .= "\t".'allfound.slice().sort(function(a,b){return a > b}).reduce(function(a,b){if (a.slice(-1)[0] !== b) a.push(b);return a;},[]);'."\n";
	} else {
		# intersection of all the elements matched individually
		$jsexec .= "\t// calculating the INTERSECTION of all elements found...\n";
		if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 1 ){ $jsexec .= "\t".'console.log("calculating the INTERSECTION of all elements found per selector category (if any).\n");'."\n"; }
		$jsexec .= "\tvar opts = ['".join("','", @known_selectors)."'];\n";
		$jsexec .= <<'EOJ';
	allfound = null;
	var nopts = opts.length;
	var n1, n2, I;
	for(let i=0;i<nopts;i++){
		n1 = opts[i];
		if( (elems[n1] != null) && (elems[n1].length > 0) ){ allfound = elems[n1].slice(0); I = i; break; }
	}
	for(let j=0;j<nopts;j++){
		if( j == I ) continue;
		n2 = opts[j];
		if( elems[n2] != null ){
			var array2 = elems[n2];
			// intersection of total and current
			allfound = allfound.filter(function(n) {
				return array2.indexOf(n) !== -1;
			});
		}
	}
	if( allfound === null ){ allfound = []; }
EOJ
	} # if Union/Intersection

	# post-process and return
	$jsexec .= <<'EOJ';
	// first, make a separate list of all the children of those found (recursively all children)
	for(let i=allfound.length;i-->0;){ allfound_including_children.push(...getAllChildren(allfound[i])); }
	// second, add id to any html element which does not have any
	if( insert_id_if_none !== null ){
		let counter = 0;
		for(let i=allfound.length;i-->0;){
			let el = allfound[i];
			if( el.id == '' ){ el.id = insert_id_if_none+'_'+counter++; }
		}
		for(let i=allfound_including_children.length;i-->0;){
			let el = allfound_including_children[i];
			if( el.id == '' ){ el.id = insert_id_if_none+'_'+counter++; }
		}
		// now that we are sure each HTML element has an ID we can remove duplicates if any
		// basically there will not be duplicates in the 1st level but in all-levels there may be
		let unis = {};
		for(let i=allfound.length;i-->0;){
			let el = allfound[i];
			unis[el.id] = el;
		}
		allfound = Object.values(unis);
		unis = {};
		for(let i=allfound_including_children.length;i-->0;){
			let el = allfound_including_children[i];
			unis[el.id] = el;
		}
		allfound_including_children = Object.values(unis);
	}

	if( domops_VERBOSITY > 1 ){
		console.log("Eventually matched "+allfound.length+" elements");
		if( (domops_VERBOSITY > 2) && (allfound.length>0) ){
			console.log("---begin matched elements:");
			for(let el of allfound){ console.log("  tag: '"+el.tagName+"', id: '"+el.id+"'"); }
			console.log("---end matched elements.");
		}
	}
	// now call the js callback function on those matched (not the children, if you want children then do it in the cb)
	let cb_results = {};
	for(let acbname of known_callbacks){
		// this *crap* does not work: if( ! acbname in cb_functions ){ continue; }
		// and caused me a huge waste of time
		if( ! cb_functions[acbname] ){ continue; }
		if( domops_VERBOSITY > 1 ){ console.log("found callback for '"+acbname+"' and processing its code blocks ..."); }
		let res1 = [];
		let adata = acbname == 'find-cb-on-matched-and-their-children' ? allfound_including_children : allfound;
		for(let acb of cb_functions[acbname]){
			let res2 = [];
			for(let i=0;i<adata.length;i++){
				let el = adata[i];
				if( domops_VERBOSITY > 1 ){ console.log("executing callback of type '"+acbname+"' (name: '"+acb["name"]+"') on matched element tag '"+el.tagName+"' and id '"+el.id+"' ..."); }
				let ares;
				try {
					// calling the callback ...
					ares = acb["code"](el);
				} catch(err) {
					msg = "error, call to the user-specified callback of type '"+acbname+"' (name: '"+acb["name"]+"') has failed with exception : "+err.message;
					console.log(msg);
					return {"status":-1,"message":msg};
				}
				res2.push({"name":acb["name"],"result":ares});
				if( domops_VERBOSITY > 1 ){ console.log("success executing callback of type '"+acbname+"' (name: '"+acb["name"]+"') on matched element tag '"+el.tagName+"' and id '"+el.id+"'. Result is '"+ares+"'."); }
			}
			res1.push(res2);
		}
		cb_results[acbname] = res1;
	}

	// returned will be an array of hashes : [{"tag":tag, "id":id}, ...] for each html element matched
	// the hash for each match is constructed with element_information_from_matched_function() which must return a hash
	// and can be user-specified or use our own default
	var returnedids = [], returnedids_of_children_too = [];
	for(let i=allfound.length;i-->0;){
		let el = allfound[i];
		let elinfo;
		try {
			elinfo = element_information_from_matched_function(el);
		} catch(err){
			msg = "error, call to the user-specified 'element-information-from-matched' has failed for directly matched element with exception : "+err.message;
			console.log(msg);
			return {"status":-1,"message":msg};			
		}
		returnedids.push(elinfo);
	}
	for(let i=allfound_including_children.length;i-->0;){
		let el = allfound_including_children[i];
		let elinfo;
		try {
			elinfo = element_information_from_matched_function(el);
		} catch(err){
			msg = "error, call to the user-specified 'element-information-from-matched' has failed for directly matched (or one of its descendents) element with exception : "+err.message;
			console.log(msg);
			return {"status":-1,"message":msg};			
		}
		returnedids_of_children_too.push(elinfo);
	}

	let ret = {
		"found" : {
			"first-level" : returnedids,
			"all-levels" : returnedids_of_children_too
		},
		"status" : returnedids.length
	};
	if( Object.keys(cb_results).length > 0 ){
		ret["cb-results"] = cb_results;
	}
	console.dir(ret);

	return ret;
})(); // end of anonymous function and now execute it
}; // end our eval scope
EOJ
	if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 2 ){ print "--begin javascript code to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : evaluating above javascript code.\n" }

	if( defined $js_outfile ){
		if( open(my $FH, '>', $js_outfile) ){ print $FH $jsexec; close $FH }
		else { print STDERR "$whoami (via $parent), line ".__LINE__." : warning, failed to open file '$js_outfile' for writing the output javascript code, skipping it ...\n" }
		if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 0 ){ print STDOUT "$whoami (via $parent), line ".__LINE__." : javascript code to be executed has been written to local file '${js_outfile}' for debugging.\n" }
	}

	my ($retval, $typ);
	eval { ($retval, $typ) = $amech_obj->eval($jsexec) };
	if( $@ ){
		print STDERR "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : eval of above javascript has failed: $@\n";
		return {
			'status' => -2,
			'message' => "eval has failed: $@"
		};
	};
	if( ! defined $retval ){
		print STDERR "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : eval of above javascript has returned an undefined result.\n";
		return {
			'status' => -2,
			'message' => "eval returned un undefined result."
		};
	}
	if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 2 ){ print "$whoami (via $parent), line ".__LINE__." : done evaluating javascript code with success.\n" }

	# this contains 'status' and 'found' which contains all
	# ids matched
	return $retval; # success
}

# The input is a hashref of parameters
# the 'element-*' parameters specify some condition to be matched
# for example id to be such and such.
# The conditions can be combined either as a union (OR)
# or an intersection (AND). Default is intersection.
# The param || => 1 changes this to Union.
# 
# returns a hash of results, which contains status
# status is -3 if general error occured, e.g. input parameters missing
# status is -2 if javascript failed
# status is -1 if one or more of the specified selectors failed to match
# status is >=0 : the number of elements deleted
# an error 'message' if status < 0
# and 'found' with all element ids matched-and-zapped when status >= 0
sub domops_zap {
	my $params = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY > 0 ){ print STDOUT "$whoami (via $parent), line ".__LINE__." : called ...\n" }

	my $amech_obj = exists($params->{'mech-obj'}) ? $params->{'mech-obj'} : undef;
	if( ! $amech_obj ){
		my $anerrmsg = ($WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY>2 ? perl2dump($params) : "")."$whoami (via $parent), line ".__LINE__." : error, input parameter 'mech-obj' is missing, see above parameters.";
		print STDERR $anerrmsg."\n";
		return {
			'status' => -3,
			'message' => $anerrmsg
		}
	}

	my $cbex = exists($params->{'find-cb-on-matched'}) && defined($params->{'find-cb-on-matched'})
		? [ @{$params->{'find-cb-on-matched'}} ] : [];
	# execute our callback last, after all user-specified if any
	push @$cbex, {
		'code' => 'htmlElement.parentNode.removeChild(htmlElement); return 1;',
		'name' => '_thezapper'
	};
	my %myparams = (
		'find-cb-on-matched' => $cbex
	);
	if( ! (exists($params->{'insert-id-if-none-random'}) && defined($params->{'insert-id-if-none-random'}))
	 && ! (exists($params->{'insert-id-if-none'}) && defined($params->{'insert-id-if-none'}))
	){
		# if no fixing of missing html element ids we ask for it and also let it be randomised
		$myparams{'insert-id-if-none-random'} = '_domops_created_id';
	}

	# this contains 'status' and 'found' which contains all
	# ids matched
	my $ret = domops_find({
		'mech-obj' => $amech_obj, 
		%$params,
		# overwrite anything like these the user specified:
		%myparams
	});

	if( ! defined $ret ){
		my $anerrmsg = ($WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY>2 ? perl2dump({%$params,'mech-obj'=>'<reducted>'}) : "")."$whoami (via $parent), line ".__LINE__." : error, call to domops_find()/1 has failed for above parameters.";
		print STDERR $anerrmsg."\n";
		return {
			'status' => -2,
			'message' => $anerrmsg
		}
	}
	if( $ret->{'status'} < 0 ){
		my $anerrmsg = ($WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY>2 ? perl2dump({%$params,'mech-obj'=>'<reducted>'}) : "")."$whoami (via $parent), line ".__LINE__." : error, call to domops_find()/2 has failed for above parameters with this error message: ".$ret->{'message'};
		print STDERR $anerrmsg."\n";
		return {
			'status' => -2,
			'message' => $anerrmsg
		}
	}

	# this contains 'status' and 'found' which contains all
	# ids matched
	return $ret; # success
}

# It calls domops_read_dom_element_selectors_from_JSON_string()
# on the contents (JSON) of the specified file (as input parameter)
# It returns undef on failure or the selectors as a Perl
# data structure on success.
sub domops_read_dom_element_selectors_from_JSON_file {
	my $jsonfile = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $FH;
	if( ! open($FH, '<:encoding(UTF-8)', $jsonfile) ){ print STDERR "$whoami (via $parent) : error, failed to open file '$jsonfile' for reading the DOM elements to be removed (as JSON): $!"; return undef }
	my $jsonstr;
	{ local $/ = undef; $jsonstr = <$FH> } close $FH;
	my $ret = WWW::Mechanize::Chrome::DOMops::domops_read_dom_element_selectors_from_JSON_string($jsonstr);
	if( ! defined $ret ){ print STDERR "$whoami (via $parent) : error, call to ".'domops_read_dom_element_selectors_from_JSON_string()'." has failed for input file '$jsonfile'.\n"; return undef }
	return $ret;
}
# It parses a JSON string (the input parameter) which
# should contain DOM element selectors in the various
# forms accepted by this package and documented in the pod.
# It returns undef on failure or the selectors as a Perl
# data structure on success.
sub domops_read_dom_element_selectors_from_JSON_string {
	my $jsonstr = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $perld = json2perl($jsonstr);
	if( ! defined $perld ){ print STDERR "${jsonstr}\n$whoami (via $parent) : error, specified dom elements to be removed (see above) failed to be parsed as JSON.\n"; return undef }
	if( ref($perld) eq 'ARRAY' ){
		for (@$perld){
			if( ref($_) ne 'HASH' ){ print STDERR "$whoami (via $parent) : error, specified dom elements to be removed (as JSON) must either specify an ARRAY of hashes, each hash being the specification for selecting a dom element, OR a HASH containing the dom element selection specification. An array was specified but it contains at least one item of type '".ref($_)."' but only HASHes are allowed as the ARRAY elements. The spec was:\n".$jsonstr."\n"; return undef }
		}
		return $perld;
	} elsif( ref($perld) eq 'HASH' ){
		return [ $perld ];
	}
	print "$whoami (via $parent) : error, specified dom element selectors (as JSON) must either specify an ARRAY of hashes, each hash being the specification of a dom element selector, OR a HASH containing the dom element selection specification. The data type of what was specified was '".ref($perld)."' and the spec was:\n".$jsonstr."\n";
	return undef
}

# wait for page to load (DOMReady) and optionally execute a callback (a sub).
# Because of XHR calls, some elements of the page may keep coming
# so, optionally, specify a list of elements XPATH selectors
# that all must be present in the page using 'elements-must-be-present'
# which can be a single XPATH or an array of XPATHs
# 'elements-must-be-present-op' can be '&&' or '||', default is &&.
# And there is a 'timeout' to stop waiting after exceeded and a 'sleep'
# for the fractional secods to sleep between checking for DOM elements.
# In case you have specified 'elements-must-be-present', then
# you can specify any other 'document' source to search in (other than
# the default document) which is useful in case your element is inside
# an iFrame, for example, if your element is an iFrame within
# the current document:
#   'document' => 'iframe[@id="myiframeid"]'
# if scalar, then it applies for all 'elements-must-be-present' selectors
# if ARRAY_REF, then there must be as many items as in the
# 'elements-must-be-present' ARRAY_REF, each corresponding to one
# element of the other.
# The above WILL MOST LIKELY FAIL
# because CORS will not allow reading what the iFrame
# contents are!
# NOTE: test
#  t/300-domops_wait_for_page_to_load-delayed-elements-inside-iframe.t.fails-because-of-cors
# is renamed so that it does not run because if fails because of CORS.
# returns 1 on failure (i.e. 'mech-obj' param not specified or a timeout on waiting)
# returns 0 on success, after waiting for the page to load
# returns 2 if it did not find elements (optional 'elements-must-be-present-all' / 'elements-must-be-present-any')
#           after timeout - most likely page is not ready
sub domops_wait_for_page_to_load {
	my $params = $_[0] // {};
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $mech_obj = (exists($params->{'mech-obj'}) && defined($params->{'mech-obj'})) ? $params->{'mech-obj'} : undef;
	if( ! $mech_obj ){ print STDERR "$whoami (via $parent), line ".__LINE__." : a mech-object is required via 'mech-obj'.\n"; return 1 }

	# wait for the page to load
	if( $domops_VERBOSITY > 0 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : called and now waiting for event 'Page.loadEventFired' ...\n" }
	my $events = $mech_obj->_collectEvents(
		sub { $_[0]->{method} eq 'Page.loadEventFired' }
	);
	if( $domops_VERBOSITY > 1 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : detected event 'Page.loadEventFired'. Page is loaded.\n" }
	# at this stage the event 'Page.loadEventFired' is fired

	# optionally check for elements to be visible, perhaps dynamically injected?

	# are there any elements to check if present? ALL
	my $sleeptime = exists($params->{'sleep'}) && defined($params->{'sleep'}) ? $params->{'sleep'} : 0.5;
	my $timeout = exists($params->{'timeout'}) && defined($params->{'timeout'}) ? $params->{'timeout'} : 15;
	my $iters = int($timeout/$sleeptime) + 1;

	if( exists($params->{'elements-must-be-present'}) && defined($params->{'elements-must-be-present'}) ){
		if( $domops_VERBOSITY > 1 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : elements to check if present have been specified, checking them with timeout=${timeout}, sleep=${sleeptime}, iterations=${iters} ...\n" }
		my @elems = (ref($params->{'elements-must-be-present'}) eq 'ARRAY') ? @{$params->{'elements-must-be-present'}} : ($params->{'elements-must-be-present'});
		my %elems = map { $_ => 1 } @elems;
		my $document_src;
		my $have_document_src = 0;
		my ($retval, $typ, $xpa, $adocsrc, $adocxpa);
		if( exists($params->{'document'}) && defined($document_src=$params->{'document'}) ){
			# we have a specified document source to search in, e.g. an iframe
			# if an array then it must have the same length as the elems and
			# the elements of both arrays are expected to correspond
			# if it is a scalar then it's one document for all elements.
			if( ref($document_src) eq '' ){
				# scalar
				$have_document_src = 1;
			} elsif( (ref($document_src) eq 'ARRAY') && (scalar(@elems)==scalar(@$document_src)) ){
				$have_document_src = 2;
			} else { print STDERR "${whoami} (via $parent), line ".__LINE__." : error, input parameter 'document' must either be a scalar (denoting a document source for all elements in 'elements-must-be-present') or an ARRAYref with exactly the same number of elements as the elements specified in 'elements-must-be-present' (the latter has ".scalar(@elems)." items).\n"; return 1 }
		} else { $adocsrc = 'var mydoc = document;' }
		my $op = ( exists($params->{'elements-must-be-present-op'}) && defined($params->{'elements-must-be-present-op'}) && $params->{'elements-must-be-present-op'}=~/^&+|\|+$/ ) ? $params->{'elements-must-be-present-op'} : '&&';
		my $success = 0;
		ITERS:
		for my $iter (1..$iters){
			ELEMS:
			for my $iElems (0..$#elems){
				$xpa = $elems[$iElems];
				next unless defined $xpa;

				if( $have_document_src > 0 ){
					$adocxpa = $have_document_src==1 ? $document_src: $document_src->[$iElems];
					$adocsrc = 'var mydoc, r; r = document.evaluate('
					  . String::Escape::escape('qprintable', $adocxpa)
					  . ', document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);'
					  . "\n"
					  . 'if( r == null ){ throw("error, failed to find document element with XPath selector: "+'.String::Escape::escape('qprintable', $adocxpa).'+" (specified by input parameter \'document\')."); }'
					  . 'else { '
					  . "\n\t" . 'if( r.snapshotLength > 1 ){ throw("error, found "+r.snapshotLength+" document elements instead of exactly one, with  XPath selector: "+'.String::Escape::escape('qprintable', $adocxpa).'+" (specified by input parameter \'document\')."); }'
					  . 'else { mydoc = r.snapshotItem(0); }'
					  . "\n".'}'
				}

				# NOTE: depending on the last-but-one param
				# into the js function 'document.evaluate()'
				# it returns an object with different methods. With:
				#   XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE
				# you get the snapshotLength
				# if you change it, it will complain it does not find method!
				# ALSO, searching within document.body may fail because body may not have already been
				# settled, so we change document.evaluate()'s 2nd parameter from 'document.body' to 'document'
				my $jsexec =
					$adocsrc
					.' if( mydoc !== null ){ r=document.evaluate('.String::Escape::escape('qprintable', $xpa).', mydoc, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);'
					.'if( r == null ){ 0 } else { r.snapshotLength; }} else { 0 }'
				;
				if( $domops_VERBOSITY > 2 ){ print STDOUT "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n${whoami} (via $parent), line ".__LINE__." : iteration $iter : executing above JS code ...\n" }
				eval { ($retval, $typ) = $mech_obj->eval($jsexec) };
				if( $@ ){ print STDERR "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : iteration $iter : eval of above javascript has failed: $@\n"; return 1 }
				if( $domops_VERBOSITY > 2 ){ print STDOUT "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : iteration $iter : the value returned from executing above javascript (of type '$typ'): '${retval}'\n" }
				if( $retval > 0 ){
					# element found
					if( $domops_VERBOSITY > 2 ){ print STDOUT "--begin javascript to eval:\n\n${jsexec}\n\n--end javascript code.\n$whoami (via $parent), line ".__LINE__." : iteration $iter : element found (operator '$op') : ${xpa}\n" }
					if( $op eq '||' ){
						$success = 1;
						last ITERS;
					}
					$elems[$iElems] = undef;
				}
				$mech_obj->sleep($sleeptime);
			} # for ELEMS:
			if( ($success=(scalar(grep { defined $_ } @elems) == 0)) ){ last ITERS }
		} # for ITERS:
		if( $success > 0 ){ if( $domops_VERBOSITY > 0 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : all elements specified were found, page is ready.\n" } }
		else {
			# some elements not found (but dom-ready event was fired)
			# the result depends on the timeout!
			if( $domops_VERBOSITY > 0 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : (some) elements specified were NOT found, page is NOT ready on the specified timeout.\n" }
			return 2;
		}
 	}

	# run the callback if any specified
	my($e,$r) = (exists($params->{'callback'}) && defined($params->{'callback'}))
		? Future->wait_all( $events, $params->{'callback'} )
		: Future->wait_all( $events )
	;
	if( $domops_VERBOSITY > 0 ){ print STDOUT "${whoami} (via $parent), line ".__LINE__." : page is now loaded!\n" }
	return 0 # success
}

## POD starts here

=pod

=head1 NAME

WWW::Mechanize::Chrome::DOMops - Operations on the DOM loaded in Chrome

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

This module provides a set of tools to operate on the DOM
loaded onto the provided L<WWW::Mechanize::Chrome> object
after fetching a URL.

Operating on the DOM is powerful but there are
security risks involved if the browser and profile
you used for loading this DOM is your everyday browser and profile.

Please read L<SECURITY WARNING> before continuing on to the main course.

Currently, L<WWW::Mechanize::Chrome::DOMops> provides these tools:

=over 4

=item * C<domops_find()> : finds HTML elements,

=item * C<domops_zap()> : deletes HTML elements.

=back

Both C<domops_find()> and C<domops_zap()> return some information from
each match and its descendents (like C<tag>, C<id> etc.).
This information can be tweaked by the caller.
C<domops_find()> and C<domops_zap()> optionally execute javascript code on
each match and its descendents and can return data back to
the caller perl code.

The selection of the HTML elements in the DOM
can be done in various ways:

=over 4

=item * by B<XPath selector>,

=item * by B<CSS selector>,

=item * by B<tag>,

=item * by B<class>.

=item * by B<id>,

=item * by B<name>.

=back

There is more information about this in section L<ELEMENT SELECTORS>.

Here are some usage scenaria:

    use WWW::Mechanize::Chrome::DOMops qw/domops_zap domops_find domops_VERBOSITY/;

    # adjust verbosity: 0, 1, 2, 3
    $WWW::Mechanize::Chrome::domops_VERBOSITY = 3;

    # First, create a mech object and load a URL on it
    # Note: you need google-chrome binary installed in your system!
    # See section CREATING THE MECH OBJECT for creating the mech
    # and how to redirect its javascript console to perl's output
    my $mechobj = WWW::Mechanize::Chrome->new();
    # fetch a page which will setup a DOM on which to operate:
    $mechobj->get('https://www.bbbbbbbbb.com');

    # find elements in the DOM, select by CSS selector,
    # XPath selector, id, tag or name:
    my $ret = domops_find({
       'mech-obj' => $mechobj,
       # find elements whose class is in the provided
       # scalar class name or array of class names
       'element-class' => ['slanted-paragraph', 'class2', 'class3'],
       # *OR* their tag is this:
       'element-tag' => 'p',
       # *OR* their name is this:
       'element-name' => ['aname', 'name2'],
       # *OR* their id is this:
       'element-id' => ['id1', 'id2'],
       # *OR* just provide a CSS selector
       'element-cssselector' => 'a-css-selector',
       # *OR* just provide a XPath selector
       'element-xpathselector' => 'a-xpath-selector',
       # specifies that we should use the union of the above sets
       # hence the *OR* in above comment
       '||' => 1,
       # this says to find all elements whose class
       # is such-and-such AND element tag is such-and-such
       # '&&' => 1 means to calculate the INTERSECTION of all
       # individual matches.

       # build the information sent back from each match
       'element-information-from-matched' => <<'EOJ',
// begin JS code to extract information from each match and return it
// back as a hash
const r = htmlElement.hasAttribute("role")
  ? htmlElement.getAttribute("role") : "<no role present>"
;
return {"tag" : htmlElement.tagName, "id" : htmlElement.id, "role" : r};
EOJ
       # optionally run javascript code on all those elements matched
       'find-cb-on-matched' => [
         {
           'code' =><<'EOJS',
  // the element to operate on is 'htmlElement'
  console.log("operating on this element "+htmlElement.tagName);
  // this is returned back in the results of domops_find() under
  // key "cb-results"->"find-cb-on-matched"
  return 1;
EOJS
           'name' => 'func1'
         }, {...}
       ],
       # optionally run javascript code on all those elements
       # matched AND THEIR CHILDREN too!
       'find-cb-on-matched-and-their-children' => [
         {
           'code' =><<'EOJS',
  // the element to operate on is 'htmlElement'
  console.log("operating on this element "+htmlElement.tagName);
  // this is returned back in the results of domops_find() under
  // key "cb-results"->"find-cb-on-matched" notice the complex data
  return {"abc":"123",{"xyz":[1,2,3]}};
EOJS
           'name' => 'func2'
         }
       ],
       # optionally ask it to create a valid id for any HTML
       # element returned which does not have an id.
       # The text provided will be postfixed with a unique
       # incrementing counter value 
       'insert-id-if-none' => '_prefix_id',
       # or ask it to randomise that id a bit to avoid collisions
       'insert-id-if-none-random' => '_prefix_id',

       # optionally, also output the javascript code to a file for debugging
       'js-outfile' => 'output.js',
    });


    # Delete an element from the DOM
    $ret = domops_zap({
       'mech-obj' => $mechobj,
       'element-id' => 'paragraph-123'
    });

    # Mass murder:
    $ret = domops_zap({
       'mech-obj' => $mechobj,
       'element-tag' => ['div', 'span', 'p'],
       '||' => 1, # the union of all those matched with above criteria
    });

    # error handling
    if( $ret->{'status'} < 0 ){ die "error: ".$ret->{'message'} }
    # status of -3 indicates parameter errors,
    # -2 indicates that eval of javascript code inside the mech object
    # has failed (syntax errors perhaps, which could have been introduced
    # by user-specified callback
    # -1 indicates that javascript code executed correctly but
    # failed somewhere in its logic.

    print "Found " . $ret->{'status'} . " matches which are: "
    # ... results are in $ret->{'found'}->{'first-level'}
    # ... and also in $ret->{'found'}->{'all-levels'}
    # the latter contains a recursive list of those
    # found AND ALL their children

    # wait for page to load with catching the Page.loadEventFired
    if( 0 == domops_wait_for_page_to_load() ){ print "page loaded\n" }
    else { die "page did not load within the default timeout" }

    domops_wait_for_page_to_load({
      'timeout' => 50.5, # fractional seconds
      'sleep' => 1.5, # fractional seconds to sleep between polling
    });

    # this waits for Page.loadEventFired AND for ALL
    # DOM elements specified with the XPath selectors:
    domops_wait_for_page_to_load({
      'elements-must-be-present' => [
        'div[@id="anid1"]',
        'span[@id="anid2"]',
      ],
      'elements-must-be-present-op' => '&&'
    });


=head1 EXPORT

=over 1

=item the sub to find element(s) in the DOM

    domops_find()

=item the sub to delete element(s) from the DOM

    domops_zap()

=item the sub to read element selectors from a JSON string

    domops_read_dom_element_selectors_from_JSON_string()

=item the sub to read element selectors from a JSON file

    domops_read_dom_element_selectors_from_JSON_file()

=item the sub to wait for the DOM to load not only via
detecting the C<DOMContentLoaded> event but by also
waiting for specific DOM elements, specified via selectors including
CSS and XPath selectors, to appear

    domops_wait_for_page_to_load()

and the flag to denote verbosity (default is 0, no verbosity)

    $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY

=back

=head1 SUBROUTINES/METHODS

=head2 domops_find($params)

It finds HTML elements in the DOM currently loaded on the
parameters-specified L<WWW::Mechanize::Chrome> object. The
parameters are:

=over 4

=item * C<mech-obj> : user must supply a L<WWW::Mechanize::Chrome> object,
this is required. See section
L<CREATING THE MECH OBJECT> for an example of creating the mech object with some parameters
which work for me and javascript console output propagated on to perl's output.

=item * C<element-information-from-matched> : optional javascript code to be run
on each HTML element matched in order to construct the information data
whih is returned back. If none
specified the following default will be used, which returns tagname and id:

   // the matched element is provided in htmlElement
   return {"tag" : htmlElement.tagName, "id" : htmlElement.id};

Basically the code is expected to be the B<body of a function> which
accepts one parameter: C<htmlElement> (that is the element matched).
That means it B<must not have>
the function preamble (function name, signature, etc.).
Neither it must have the postamble, which is the end-block curly bracket.
This piece of code B<must return a HASH>. 
The code can throw exceptions which will be caught
(because the code is run within a try-catch block)
and the error message will be propagated to the perl code with status of -1.

=item * C<insert-id-if-none> : some HTML elements simply do not have
an id (e.g. C<<p>>). If any of these elements is matched,
its tag and its id (empty string) will be returned.
By specifying this parameter (as a string, e.g. C<_replacing_empty_ids>)
all such elements matched will have their id set to
C<_replacing_empty_ids_X> where X is an incrementing counter
value starting from a random number. By running C<domops_find()>
more than once on the same on the same DOM you are risking
having the same ID. So provide a different prefix every time.
Or use C<insert-id-if-none-random>, see below.

=item * C<insert-id-if-none-random> : each time C<domops_find()> is called
a new random base id will be created formed by the specified prefix (as with
C<insert-id-if-none>) plus a long random string plus the incrementing
counter, as above. This is supposed to be better at
avoiding collisions but it can not guarantee it.
If you are setting C<rand()>'s seed to the same number
before you call C<domops_find()> then you are guaranteed to
have collisions.

=item * C<find-cb-on-matched> : an array of
user-specified javascript code
to be run on each element matched in the order
the elements are returned and in the order of the javascript
code in the specified array. Each item of the array
is a hash with keys C<code> and C<name>. The former
contains the code to be run assuming that the
html element to operate on is named C<htmlElement>.
The code must end with a C<return> statement which
will be recorded and returned back to perl code.
The code can throw exceptions which will be caught
(because the callback is run within a try-catch block)
and the error message will be propagated to the perl code with status of -1.
Basically the code is expected to be the B<body of a function> which
accepts one parameter: C<htmlElement> (that is the element matched).
That means it B<must not have>
the function preamble (function name, signature, etc.).
Neither it must have the postamble, which is the end-block curly bracket.

Key C<name> is just for
making this process more descriptive and will
be printed on log messages and returned back with
the results. C<name> can contain any characters.
Here is an  example:

    'find-cb-on-matched' : [
      {
	# this returns a complex data type
        'code' => 'console.log("found id "+htmlElement.id); return {"a":"1","b":"2"};'
        'name' => 'func1'
      },
      {
        'code' => 'console.log("second func: found id "+htmlElement.id); return 1;'
        'name' => 'func2'
      },
    ]

=item * C<find-cb-on-matched-and-their-children> : exactly the same
as C<find-cb-on-matched> but it operates on all those HTML elements
matched and also all their children and children of children etc.

=item * C<js-outfile> : optionally save the javascript
code (which is evaluated within the mech object) to a file.

=item * C<element selectors> are covered in section L</ELEMENT SELECTORS>.

=back

B<JAVASCRIPT HELPERS>

There is one javascript function available to all user-specified callbacks:

=over 2

=item * C<getAllChildren(anHtmlElement)> : it returns
back an array of HTML elements which are the children (at any depth)
of the given C<anHtmlElement>.

=back

B<RETURN VALUE>:

The returned value is a hashref with at least a C<status> key
which is greater or equal to zero in case of success and
denotes the number of matched HTML elements. Or it is -3, -2 or
-1 in case of errors:

=over 4

=item * C<-3> : there is an error with the parameters passed to this sub.

=item * C<-2> : there is a syntax error in the javascript code to be
evaluated by the mech object with something like C<$mech_obj->eval()>.
Most likely this syntax error is with user-specified callback code.
Note that all the javascript code to be evaluated is dumped to stderr
by increasing the verbosity. But also it can be saved to a local file
for easier debugging by supplying the C<js-outfile> parameter to
C<domops_find()> or C<domops_zap()>.

=item * C<-1> : there is a logical error while running the javascript code.
For example a division by zero etc. This can be both in the callback code
as well as in the internal javascript code for edge cases not covered
by my tests. Please report these.
Note that all the javascript code to be evaluated is dumped to stderr
by increasing the verbosity. But also it can be saved to a local file
for easier debugging by supplying the C<js-outfile> parameter to
C<domops_find()> or C<domops_zap()>.

=back

If C<status> is not negative, then this is success and its value
denotes the number of matched HTML elements. Which can be zero
or more. In this case the returned hash contains this

    "found" => {
      "first-level" => [
        {
          "tag" => "NAV",
          "id" => "nav-id-1"
        }
      ],
      "all-levels" => [
        {
          "tag" => "NAV",
          "id" => "nav-id-1"
        },
        {
          "id" => "li-id-2",
          "tag" => "LI"
        },
      ]
    }

Key C<first-level> contains those items matched directly while
key C<all-levels> contains those matched directly as well as those
matched because they are descendents (direct or indirect)
of each matched element.

Each item representing a matched HTML element has two fields:
C<tag> and C<id>. Beware of missing C<id> or
use C<insert-id-if-none> or C<insert-id-if-none-random> to
fill in the missing ids.

If C<find-cb-on-matched> or C<find-cb-on-matched-and-their-children>
were specified, then the returned result contains this additional data:

 "cb-results" => {
    "find-cb-on-matched" => [
      [
        {
          "name" => "func1",
          "result" => {
            "a" => 1,
            "b" => 2
          }
        }
      ],
      [
        {
          "result" => 1,
          "name" => "func2"
        }
      ]
    ],
    "find-cb-on-matched-and-their-children" => ...
  },

C<find-cb-on-matched> and/or C<find-cb-on-matched-and-their-children> will
be present depending on whether corresponding value in the input
parameters was specified or not. Each of these contain the return
result for running the callback on each HTML element in the same
order as returned under key C<found>.

HTML elements allows for missing C<id>. So field C<id> can be empty
unless caller set the C<insert-id-if-none> input parameter which
will create a unique id for each HTML element matched but with
missing id. These changes will be saved in the DOM.
When this parameter is specified, the returned HTML elements will
be checked for duplicates because now all of them have an id field.
Therefore, if you did not specify this parameter results may
contain duplicate items and items with empty id field.
If you did specify this parameter then some elements of the DOM
(those matched by our selectors) will have their missing id
created and saved in the DOM.

Another implication of using this parameter when
running it twice or more with the same value is that
you can get same ids. So, always supply a different
value to this parameter if run more than once on the
same DOM.

=head2 domops_zap($params)

It removes HTML element(s) from the DOM currently loaded on the
parameters-specified L<WWW::Mechanize::Chrome> object. The params
are exactly the same as with L</domops_find($params)> except that
C<insert-id-if-none> is ignored.

C<domops_zap()> is implemented as a C<domops_find()> with
an additional callback for all elements matched
in the first level (not their children) as:

  'find-cb-on-matched' => {
    'code' => 'htmlElement.parentNode.removeChild(htmlElement); return 1;',
    'name' => '_thezapper'
   };


B<RETURN VALUE>:

Return value is exactly the same as with L</domops_find($params)>

=head2 domops_wait_for_page_to_load($params)

It waits for the page to load by detecting the C<Page.loadEventFired>
event. However, because the DOM may be altered at any time, even if
said event has been fired, there is provision to wait for specific
DOM elements as well via the C<elements-must-be-present> input parameter.
This can be a scalar or an ARRAY_REF containing XPath selectors
for DOM elements to wait for their appearance on the page. If this
contains more than one selectors (i.e. it is an ARRAY_REF), then
input parameter C<elements-must-be-present-op> can be set
to C<&&> or C<||>, denoting the method to combine these. I.e.
wait for all (C<&&>) or wait for any (C<||>).

B<INPUT PARAMETERS>:

As a HASH_REF:

=over 4

=item * B<C<elements-must-be-present>> : optionally specify XPath selector(s)
either as a scalar or an ARRAY_REF to wait for their appearance.

=item * B<C<elements-must-be-present-op>> : optionally specify how to
combine the XPath selectors, specified via C<elements-must-be-present>
which in this case must be an ARRAY_REF, either as wait for all
elements to appear (C<&&>) or for any element to appear (C<||>).

=item * B<C<document>> : Checking for the appearance of
specific DOM elements (via C<elements-must-be-present>)
is done for elements under the default C<document>'s body.
But, if frame
elements are present (e.g. C<iframe>) then you can optionally
search in their C<document>. Javascript's C<document.evaluate()>
(which is an XPath query function) allows to use any
other node. E.g. the frame's document. In this case set C<document>
to Javascript code to return the element you want to search under it.
For example, if you have an iframe and you want to search under
it, then set 'C<document>' to this XPath selector: 'C<iframe[@id="myiframeid"]>'.
If C<elements-must-be-present> is an ARRAY_REF then 'C<document>'
can be a scalar or ARRAY_REF. In the former case, the document will
apply for each item of C<elements-must-be-present>. In the latter case,
each item of C<document> will apply to the corresponding item of
C<elements-must-be-present>.

B<WARNING>: accessing the document body of a frame element is
most likely forbidden because of the weird CORS rules. In
other words: an iframe is running on your browser but you are not allow
to know what it does or how! Only watch the rendered results.
Perfect! Note that test file C<t/300-domops_wait_for_page_to_load-delayed-elements-inside-iframe.t.fails-because-of-cors>
is renamed so that it does not run because it fails because
of CORS which guards against, even, local pages.

=item * B<C<timeout>> : fractional number of seconds to wait for
the DOM loaded event and/or any DOM elements before returning,
even without the conditions were satisfied and the page was
most likely not loaded. The default value is 15 seconds.

=item * B<C<sleep>> : fractional number of seconds to sleep
between polling for the DOM elements, if any were specified.
It does not apply when waiting for the C<Page.loadEventFired>
I could not find a way to use a timeout with L<WWW::Mechanize::Chrome::_collectEvents>,
which is used internally. Default is 0.5 seconds of sleep between polling.

=back

B<RETURN VALUE>:

=over 4

=item B<C<1>> : denotes failure. For example if required input
parameters are missing.

=item B<C<0>> : denotes absolute success meaning all events and DOM
elements requested to wait for, have appeared and page is
considered to be loaded and ready.

=item B<C<2>> : denotes partial success in that all code
was run but events and/or DOM elements had not appeared
within the current timeout. Which most likely means that
the page is not ready yet. Increase the timeout and see.
Or correct your DOM element selectors.

=back

=head2 domops_read_dom_element_selectors_from_JSON_file($filename)

It reads DOM element selectors, in their various forms
as documented at L</ELEMENT SELECTORS>,
from specified filename and returns these
as a Perl data structure which can then be passed on to
L</domops_find($params)> and L</domops_zap($params)>.

B<RETURN VALUE>:

=over 4

=item B<C<undef>> : on failure, e.g. file not found or parsing errors.

=item a Perl data structure witht the selectors on success which can
directly be passed on to L</domops_find($params)> and L</domops_zap($params)>.

=back

=head2 domops_read_dom_element_selectors_from_JSON_string($string)

It reads DOM element selectors, in their various forms
as documented at L</ELEMENT SELECTORS>,
from specified string and returns these
as a Perl data structure which can then be passed on to
L</domops_find($params)> and L</domops_zap($params)>.

B<RETURN VALUE>:

=over 4

=item B<C<undef>> : on failure, e.g. file not found or parsing errors.

=item a Perl data structure witht the selectors on success which can
directly be passed on to L</domops_find($params)> and L</domops_zap($params)>.

=back

=head2 $WWW::Mechanize::Chrome::DOMops::domops_VERBOSITY

Set this upon loading the module to C<0, 1, 2, 3>
to adjust verbosity. C<0> implies no verbosity.


=head1 ELEMENT SELECTORS

C<Element selectors> are how one selects HTML elements from the DOM.
There are 5 ways to select HTML elements: by class (C<element-class>),
tag (C<element-tag>), id (C<element-id>), name (C<element-name>),
a CSS selector (C<element-cssselector>)
or via an XPath selector (C<element-xpathselector>).

Multiple selectors can be specified
by combining the various selector types, above.
For example,
one can select by C<element-class> and C<element-tag> (and ...).
In this selection mode, the matched elements from each selector type
(e.g. set A contains the HTML elements matched via C<element-class>
and set B contains the HTML elements matched via C<element-tag>)
must be combined by means of either the UNION (C<||>)
or INTERSECTION (C<&&>) of the two sets A and B.

Each selector can take one or more values. If you want to select
by just one class then provide that one class as a string scalar.
If you want to select an HTML elements which may belong to two classes,
then provide the two class names as an array.


These are the valid selectors:

=over 2

=item * C<element-class> : find DOM elements matching this class name

=item * C<element-tag> : find DOM elements matching this element tag

=item * C<element-id> : find DOM element matching this element id

=item * C<element-name> : find DOM element matching this element name

=item * C<element-cssselector> : find DOM element matching this CSS selector

=item * C<element-xpathselector> : find DOM element matching this XPath selector

=back

And one of these two must be used to combine the results
into a final list:

=over 2

=item * C<&&> : Intersection. When set to 1 the result is the intersection of all individual results.
Meaning that an element will make it to the final list if it was matched
by every selector specified. This is the default.

=item * C<||> : Union. When set to 1 the result is the union of all individual results.
Meaning that an element will make it to the final list if it was matched
by at least one of the selectors specified.

As an example, the following selects all HTML elements which belong to class X AND class Y.
It also selects all HTML elements of the C<div> tag. And calculates
the union of the two sets:

  {
    'element-class' => ['X', 'Y'],
    'element-tag' => 'div',
    '&&' => 1,
  }


=back

=head1 CREATING THE MECH OBJECT

The mech (L<WWW::Mechanize::Chrome>) object must be supplied
to the functions in this module. It must be created by the caller.
This is how I do it:

    use WWW::Mechanize::Chrome;
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($ERROR);

    my %default_mech_params = (
    	headless => 1,
    #	log => $mylogger,
    	launch_arg => [
    		'--window-size=600x800',
    		'--password-store=basic', # do not ask me for stupid chrome account password
    #		'--remote-debugging-port=9223',
    #		'--enable-logging', # see also log above
    		'--disable-gpu',
    		'--no-sandbox',
    		'--ignore-certificate-errors',
    		'--disable-background-networking',
    		'--disable-client-side-phishing-detection',
    		'--disable-component-update',
    		'--disable-hang-monitor',
    		'--disable-save-password-bubble',
    		'--disable-default-apps',
    		'--disable-infobars',
    		'--disable-popup-blocking',
    	],
    );

    my $mech_obj = eval {
    	WWW::Mechanize::Chrome->new(%default_mech_params)
    };
    die $@ if $@;

    # This transfers all javascript code's console.log(...)
    # messages to perl's warn()
    # we need to keep $console var in scope!
    my $console = $mech_obj->add_listener('Runtime.consoleAPICalled', sub {
    	  warn
    	      "js console: "
    	    . join ", ",
    	      map { $_->{value} // $_->{description} }
    	      @{ $_[0]->{params}->{args} };
    	})
    ;

    # and now fetch a page
    my $URL = '...';
    my $retmech = $mech_obj->get($URL);
    die "failed to fetch $URL" unless defined $retmech;
    $mech_obj->sleep(1); # let it settle
    # now the mech object has loaded the URL and has a DOM hopefully.
    # You can pass it on to domops_find() or domops_zap() to operate on the DOM.


=head1 SECURITY WARNING

L<WWW::Mechanize::Chrome> invokes the C<google-chrome>
executable
on behalf of the current user. Headless or not, C<google-chrome>
is invoked. Depending on the launch parameters, either
a fresh, new browser session will be created or the
session of the current user with their profile, data, cookies,
passwords, history, etc. will be used. The latter case is very
dangerous.

This behaviour is controlled by L<WWW::Mechanize::Chrome>'s
L<constructor|WWW::Mechanize::Chrome#WWW::Mechanize::Chrome-%3Enew(-%options-)>
parameters which, in turn, are used for launching
the C<google-chrome> executable. Specifically,
see L<WWW::Mechanize::Chrome#separate_session>,
L<<WWW::Mechanize::Chrome#data_directory>
and L<WWW::Mechanize::Chrome#incognito>.

B<Unless you really need to mechsurf with your current session, aim
to launching the browser with a fresh new session.
This is the safest option.>

B<Do not rely on default behaviour as this may change over
time. Be explicit.>

Also, be warned that L<WWW::Mechanize::Chrome::DOMops> executes
javascript code on that C<google-chrome> instance.
This is done nternally with javascript code hardcoded
into the L<WWW::Mechanize::Chrome::DOMops>'s package files.

On top of that L<WWW::Mechanize::Chrome::DOMops> allows
for B<user-specified javascript code> to be executed on
that C<google-chrome> instance. For example the callbacks
on each element found, etc.

This is an example of what can go wrong if
you are not using a fresh C<google-chrome>
session:

You have just used C<google-chrome> to access your
yahoo webmail and you did not logout.
So, there will be an
access cookie in the C<google-chrome> when you later
invoke it via L<WWW::Mechanize::Chrome> (remember
you have not told it to use a fresh session).

If you allow
unchecked user-specified (or copy-pasted from ChatGPT)
javascript code in
L<WWW::Mechanize::Chrome::DOMops>'s
C<domops_find()>, C<domops_zap()>, etc. then it is, theoretically,
possible that this javascript code
initiates an XHR to yahoo and fetch your emails and
pass them on to your perl code.

But there is another problem,
L<WWW::Mechanize::Chrome::DOMops>'s
integrity of the embedded javascript code may have
been compromised to exploit your current session.

This is very likely with a Windows installation which,
being the security swiss cheese it is, it
is possible for anyone to compromise your module's code.
It is less likely in Linux, if your modules are
installed by root and are read-only for normal users.
But, still, it is possible to be compromised (by root).

Another issue is with the saved passwords and
the browser's auto-fill when landing on a login form.

Therefore, for all these reasons, B<it is advised not to invoke (via L<WWW::Mechanize::Chrome>)
C<google-chrome> with your
current/usual/everyday/email-access/bank-access
identity so that it does not have access to
your cookies, passwords, history etc.>

It is better to create a fresh
C<google-chrome>
identity/profile and use that for your
C<WWW::Mechanize::Chrome::DOMops> needs.

No matter what identity you use, you may want
to erase the cookies and history of C<google-chrome>
upon its exit. That's a good practice.

It is also advised to review the
javascript code you provide
via L<WWW::Mechanize::Chrome::DOMops> callbacks if
it is taken from 3rd-party, human or not, e.g. ChatGPT.

Additionally, make sure that the current
installation of L<WWW::Mechanize::Chrome::DOMops>
in your system is not compromised with malicious javascript
code injected into it. For this you can check its MD5 hash.

=head1 DEPENDENCIES

This module depends on L<WWW::Mechanize::Chrome> which, in turn,
depends on the C<google-chrome> executable be installed on the
host computer. See L<WWW::Mechanize::Chrome::Install> on
how to install the executable.

Test scripts (which create there own mech object) will detect the absence
of C<google-chrome> binary and exit gracefully, meaning the test passes.
But with a STDERR message to the user. Who will hopefully notice it and
proceed to C<google-chrome> installation. In any event, this module
will be installed with or without C<google-chrome>.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 CODING CONDITIONS

This code was written under extreme climate conditions of 44 Celsius.
Keep packaging those
vegs in kilos of plastic wrappers, keep obsolidating our perfectly good
hardware, keep inventing new consumer needs and brainwash them
down our throats, in short B<Crack Deep the Roof Beam, Capitalism>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-mechanize-chrome-domops at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Chrome-DOMops>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Chrome::DOMops


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Chrome-DOMops>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Mechanize-Chrome-DOMops>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Mechanize-Chrome-DOMops>

=back

=head1 DEDICATIONS

Almaz


=head1 ACKNOWLEDGEMENTS

L<CORION> for publishing  L<WWW::Mechanize::Chrome> and all its
contributors.


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::Mechanize::Chrome::DOMops
