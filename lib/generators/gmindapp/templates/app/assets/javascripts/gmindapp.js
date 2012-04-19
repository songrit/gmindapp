$(document).bind("mobileinit", function(){
  $('body').show();
  $.extend(  $.mobile , {
    loadingMessage: 'กรุณารอสักครู่',
    pageLoadErrorMessage: "ขออภัย ไม่สามารถดำเนินการได้"
  });
});
