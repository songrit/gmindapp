$(function() {
  $('body').show();
  $.extend(  $.mobile , {
    loadingMessage: 'กรุณารอสักครู่',
    pageLoadErrorMessage: "ขออภัย ไม่สามารถดำเนินการได้"
  });

  if ($('.ui-header .ui-btn-text').last().text()=="") {
    $('.ui-crumbs').hide();
  };
});

