$(document).on('ajax:error', function(xhr, status, error) {
  alert('An error occurred: ' + status.responseText);
  console.log('XHR: ', xhr);
  console.log('Status: ', status);
  console.log('Error: ', error);
});


$(document).on('ajax:beforeSend', function(event, xhr, settings) {
  if(event.target.dataset.extra) {
    let extra = event.target.dataset.extra;
    let extraValue = $(`[name="${extra}"]`).val();
    settings.data += (settings.data ? '&' : '') + `${extra}=${encodeURIComponent(extraValue)}`;
  }
});
