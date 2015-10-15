// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//

//= require jquery/dist/jquery.min
//= require jquery-ujs/src/rails
//= require turbolinks
//= require moment/min/moment.min
//= require moment/min/locales.min
//= require eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min
//= require_tree .

$(document).on('ready page:load', function() {
  $('form[data-remote]').on('ajax:success', function(event, data, status, xhr) {
    // insert the failure message inside the "#account_settings" element
    if (!xhr.responseText.match(/^Turbolinks/)) {
      Turbolinks.replace(xhr.responseText);
    }
  });
  $('form[data-remote]').on('ajax:failure', function(event, xhr, status, error) {
    // insert the failure message inside the "#account_settings" element
    Turbolinks.replace(xhr.responseText);
  });
});