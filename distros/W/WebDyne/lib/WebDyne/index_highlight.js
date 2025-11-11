function toggleSourceRow(el, state) {

  console.log ('toggleSourceRow');
  const row = el.closest("tr");
  const filename = el.dataset.filename;

  if (state.isOpen) {
    // Close
    document.querySelectorAll(".source-row").forEach((el) => el.remove());
    state.isOpen = false;
  } else {
    // Open
    state.isOpen = true;

    // Manually trigger HTMX request
    htmx.ajax("GET", "?source=" + encodeURIComponent(filename), {
      target: row,
      swap: "afterend",
    });
  }
}

function highlightBlock(scriptId) {

  // get raw text from <script type="text/plain">
  //console.log('highlightBlock');
  let el = document.getElementById(scriptId);
  let code = el.textContent;
  const language = el.dataset.language
  console.log(`language: ${language}`);
  code = code.replace(/<\\\/script>/g, "</" + "script>");
  // highlight
  let result;
  if (language == "automatic") {
    result = hljs.highlightAuto(code);
  } else {
    result = hljs.highlight(code, { language });
  }
  return result.value; // return highlighted HTML snippet
}

function showCombinedHighlight() {
  console.log('showCombinedHighlight');
  const srce_html = highlightBlock("srce_html");
  const srce_lang = highlightBlock("srce_lang");
  const srce_highlight = srce_html + srce_lang;
  document.getElementById("srce_highlight").innerHTML = srce_highlight;
}


function showSingleHighlight() {
  console.log('showSingleHighlight');
  const srce_lang = highlightBlock("srce_lang");
  const srce_highlight = srce_lang
  document.getElementById("srce_highlight").innerHTML = srce_highlight;
}


htmx.onLoad(function (root) {
  const target = root.querySelector("#srce_highlight");
  if (!target) return; // nothing to do

  // Read the data attribute
  const mode = target.dataset.mode; // maps to data-mode="..."

  // Branch based on the attribute
  if (mode === "single") {
    showSingleHighlight();
  } else {
    showCombinedHighlight();
  }
});
