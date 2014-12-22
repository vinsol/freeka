// FIXME_AB: can you add some comments what is the purpose of this Link class. Why we need this. Looks like Link is not the right name for the class
function Link(classOfLink) {
  this.$links = $('.' + classOfLink)
};

Link.prototype.bindEvents = function() {
  var _this = this;
  this.$links.on('click', function(event) {
    event.preventDefault();
    _this.markForRemoval(this);
  })
};

Link.prototype.markForRemoval = function(link) {
  var link = $(link);
  var hiddenField = link.nextAll(".hidden_field").first();
  var linkTextElements = link.find('.remove-text');
  // FIXME_AB: Any specific reason you spelled hidden as hiddenn?
  linkTextElements.toggleClass('hiddenn').toggleClass('selected');
  hiddenField.val(linkTextElements.filter('.selected').attr('data-remove'));
};

$(function() {
  // FIXME_AB: Since we are creating only on object on the page, should we follow constructor pattern here for link class?
  (new Link('remove').bindEvents());
});