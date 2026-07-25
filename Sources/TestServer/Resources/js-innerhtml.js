var count = 0;
var link = document.querySelectorAll("a")[0];
link.addEventListener("click", function (event) {
  event.preventDefault();
  count = count + 1;
  document.querySelectorAll("strong")[0].innerHTML = count.toString();
});
