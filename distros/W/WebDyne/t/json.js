
// Fetch the JSON script tag content
const jsonScriptTag = document.getElementById('json-data');
const jsonData = JSON.parse(jsonScriptTag.textContent);

// Select the output container
const outputDiv = document.getElementById('output');

// Display the JSON data in a readable format
//outputDiv.innerHTML = `<pre>${JSON.stringify(jsonData, null, 2)}</pre>`;
const pre = document.createElement('pre');
pre.textContent = JSON.stringify(jsonData, null, 2);
outputDiv.textContent = '';
outputDiv.appendChild(pre);