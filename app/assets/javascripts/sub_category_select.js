// Always handle failure cases while making ajax requests.
$(function () {
  $('#requirement_category_ids').on('change', function () {
    _this = this;
    $.ajax({
      type: "GET",
      dataType: "html",
      // FIXME_AB: Don't hardcode urls in JS. Pass them to jS using data attributes from erb
      url: '/categories/sub_categories',
      data: { 'parent_id': _this.value },
      success: function (response) {
        $('#sub_category_select').html(response)
      }
    })
  })
});