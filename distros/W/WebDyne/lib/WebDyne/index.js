function toggleSourceRow(el, state) {

  // Log
  //
  console.log ('toggleSourceRow', state);
  
  
  // Get filename and associated md5 
  //
  const filename = el.dataset.filename;
  const md5=el.dataset.md5;


  // If open, close and visa versa
  //
  if (state.isOpen) {
    // Close
    document.querySelectorAll("#source-row-"+md5).forEach((el) => el.remove());
    state.isOpen = false;
  } else {
    // Open
    state.isOpen = true;
    // Manually trigger HTMX request
    const row = el.closest("tr");
    htmx.ajax("GET", "?source=" + encodeURIComponent(filename), {
      target: row,
      swap: "afterend",
    });
  }
}


function highlight_code(root, md5) {

  // Log
  //
  console.log('highlight_code', md5);
  
  // Get all the script objects
  //
  const script_ar = root.querySelectorAll('script[data-lang]');
  script_ar.forEach( script => {
  
    // Iterate and get language, code
    //
    const lang=script.getAttribute('data-lang');
    let code=script.textContent;
    console.log('lang', lang);
    if (!lang || !code) return
    
    // Escape script blocks so they don't false trigger
    //
    code = code.replace(/<\\\/script>/g, "</" + "script>");
    
    
    // Run highlighting code
    //
    let result;
    try {
      if (lang == "automatic") {
        result = hljs.highlightAuto(code);
      } else {
        result = hljs.highlight(code, { language: lang });
      }
    } catch (e) {
      console.error(`Highlight.js failed for language: ${lang}`, e);
      result = { value: hljs.escapeHTML(code) };
    }
    
    // Insert into doc
    //
    document.getElementById('srce_highlight-' + md5).innerHTML += result.value;
  })
}


htmx.onLoad(function (root) {

  // Skip inital page load
  //
  console.log(root);
  if (root === document.body) {
    console.log('skip inital page load');
    return; // skip initial load
  }
  
  
  // Get md5 of file we want to show conten
  //
  const md5 = root.getAttribute('data-md5');
  console.log('md5:', md5);
  
  
  // And run HighlighJS over it and display
  //
  return highlight_code(root,md5);

});


function refreshIcons() {
    console.log("refreshIcons running…");
    if (window.lucide) {
        lucide.createIcons();
    } else {
        console.error("lucide not found!");
    }
}


// Load lucide icons
//
document.addEventListener('DOMContentLoaded', refreshIcons);
// Don't seem to be needed
//
//document.addEventListener('htmx:afterSwap', refreshIcons);

