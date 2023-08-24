{ /* our own scope */

const VERBOSE_DOMops = 0;

const getAllChildren = (htmlElement) => {
	if( (htmlElement === null) || (htmlElement === undefined) ){
		console.log("getAllChildren() : warning null input");
		return [];
	}
	if( VERBOSE_DOMops > 1 ){ console.log("getAllChildren() : called for element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); }

	if (htmlElement.children.length === 0) return [htmlElement];

	let allChildElements = [];

	for (let i = 0; i < htmlElement.children.length; i++) {
		let children = getAllChildren(htmlElement.children[i]);
		if (children) allChildElements.push(...children);
	}
	allChildElements.push(htmlElement);

	return allChildElements;
};


const element_information_from_matched_function = (htmlElement) => {
	return {"tag" : htmlElement.tagName, "id" : htmlElement.id};
} // end element_information_from_matched_function


const cb_functions = {
  "find-cb-on-matched" : [
    {"code" : (htmlElement) => { console.log("find-cb-on-matched() : called on element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); return 1; }, "name" : "func11"},
    {"code" : (htmlElement) => { console.log("find-cb-on-matched() : called on element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); return 1; }, "name" : "func22"}
  ],
  "find-cb-on-matched-and-their-children" : [
    {"code" : (htmlElement) => { console.log("find-cb-on-matched-and-their-children() : called on element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); return 1; }, "name" : "func1"},
    {"code" : (htmlElement) => { console.log("find-cb-on-matched-and-their-children() : called on element '"+htmlElement+"' with tag '"+htmlElement.tagName+"' and id '"+htmlElement.id+"' ..."); return 1; }, "name" : "func2"}
  ]
};

// the return value of this anonymous function is what perl's eval will get back
(function(){
	var retval = -1; // this is what we return
	// returns -1 for when one of the element searches matched nothing
	// returns 0 if after intersection/union nothing was found to delete
	// returns >0 : the number of elements deleted
	var anelem, anelems, i, j;
	var allfound = [];
	var allfound_including_children = [];
	var elems = [];
	elems['element-name'] = null;
	elems['element-class'] = null;
	elems['element-tag'] = null;
	elems['element-id'] = null;
	elems['element-cssselector'] = null;
	const union = 0;
	const insert_id_if_none = 'abc';
	const known_callbacks = ["find-cb-on-matched", "find-cb-on-matched-and-their-children"];
	// selector 'element-tag' was specified: ["nav"]
	for(let asel of ["nav"]){
		// this can return an array or a single html element (e.g. in ById)
		if( VERBOSE_DOMops > 1 ){ console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : selecting elements with this function 'document.getElementsByTagName' ..."); }
		let tmp = document.getElementsByTagName(asel);
		// if getElementsBy return an HTMLCollection,
		// getElementBy (e.g. ById) returns an html element
		// and querySelectorAll returns NodeList
		// convert them all to an array:
		if( (tmp === null) || (tmp === undefined) ){
			if( VERBOSE_DOMops > 1 ){ console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) : nothing matched."); }
			continue;
		}
		anelems = (tmp.constructor.name === 'HTMLCollection') || (tmp.constructor.name === 'NodeList')
			? Array.prototype.slice.call(tmp) : [tmp]
		;
		if( anelems == null ){
			if( union == 0 ){
				msg = "WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-tag '"+asel+"' not found, this specifier has failed and will not continue with the rest.";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-tag '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		if( anelems.length == 0 ){
			if( union == 0 ){
				msg = "WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-tag '"+asel+"' not found, this specifier has failed and will not continue with the rest.";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-tag '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		// now anelems is an array
		if( elems["element-tag"] === null ){
			elems["element-tag"] = anelems;
		} else {
			elems["element-tag"] = elems["element-tag"].length > 0 ? [...elems["element-tag"], ...anelems] : anelems;
		}
		allfound = allfound.length > 0 ? [...allfound, ...anelems] : anelems;
		if( VERBOSE_DOMops > 1 ){
			console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : found "+elems["element-tag"].length+" elements selected with element-tag '"+asel+"'");
			if( (VERBOSE_DOMops > 2) && (elems["element-tag"].length>0) ){
				for(let el of elems["element-tag"]){ console.log("  tag: '"+el.tagName+"', id: '"+el.id+"'"); }
				console.log("--- end of the elements selected with element-tag.");
			}
		}
	}
	// selector 'element-cssselector' was specified: ["nav#nav-id-1"]
	for(let asel of ["nav#nav-id-1"]){
		// this can return an array or a single html element (e.g. in ById)
		if( VERBOSE_DOMops > 1 ){ console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : selecting elements with this function 'document.querySelectorAll' ..."); }
		let tmp = document.querySelectorAll(asel);
		// if getElementsBy return an HTMLCollection,
		// getElementBy (e.g. ById) returns an html element
		// and querySelectorAll returns NodeList
		// convert them all to an array:
		if( (tmp === null) || (tmp === undefined) ){
			if( VERBOSE_DOMops > 1 ){ console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) : nothing matched."); }
			continue;
		}
		anelems = (tmp.constructor.name === 'HTMLCollection') || (tmp.constructor.name === 'NodeList')
			? Array.prototype.slice.call(tmp) : [tmp]
		;
		if( anelems == null ){
			if( union == 0 ){
				msg = "WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-cssselector '"+asel+"' not found, this specifier has failed and will not continue with the rest.";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-cssselector '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		if( anelems.length == 0 ){
			if( union == 0 ){
				msg = "WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-cssselector '"+asel+"' not found, this specifier has failed and will not continue with the rest.";
				console.log(msg);
				return {"status":-1,"message":msg};
			} else {
				console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : element(s) selected with element-cssselector '"+asel+"' not found (but because we are doing a union of the results, we continue with the other specifiers).");
				continue;
			}
		}
		// now anelems is an array
		if( elems["element-cssselector"] === null ){
			elems["element-cssselector"] = anelems;
		} else {
			elems["element-cssselector"] = elems["element-cssselector"].length > 0 ? [...elems["element-cssselector"], ...anelems] : anelems;
		}
		allfound = allfound.length > 0 ? [...allfound, ...anelems] : anelems;
		if( VERBOSE_DOMops > 1 ){
			console.log("WWW::Mechanize::Chrome::DOMops::find (via N/A) via js-eval : found "+elems["element-cssselector"].length+" elements selected with element-cssselector '"+asel+"'");
			if( (VERBOSE_DOMops > 2) && (elems["element-cssselector"].length>0) ){
				for(let el of elems["element-cssselector"]){ console.log("  tag: '"+el.tagName+"', id: '"+el.id+"'"); }
				console.log("--- end of the elements selected with element-cssselector.");
			}
		}
	}
	// calculating the INTERSECTION of all elements found...
	var opts = ['element-name','element-class','element-tag','element-id','element-cssselector'];
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

	if( VERBOSE_DOMops > 1 ){
		console.log("Eventually matched "+allfound.length+" elements");
		if( (VERBOSE_DOMops > 2) && (allfound.length>0) ){
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
		if( VERBOSE_DOMops > 1 ){ console.log("found callback for '"+acbname+"' and processing its code blocks ..."); }
		let res1 = [];
		let adata = acbname == 'find-cb-on-matched-and-their-children' ? allfound_including_children : allfound;
		for(let acb of cb_functions[acbname]){
			let res2 = [];
			for(let i=0;i<adata.length;i++){
				let el = adata[i];
				if( VERBOSE_DOMops > 1 ){ console.log("executing callback of type '"+acbname+"' (name: '"+acb["name"]+"') on matched element tag '"+el.tagName+"' and id '"+el.id+"' ..."); }
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
				if( VERBOSE_DOMops > 1 ){ console.log("success executing callback of type '"+acbname+"' (name: '"+acb["name"]+"') on matched element tag '"+el.tagName+"' and id '"+el.id+"'. Result is '"+ares+"'."); }
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
