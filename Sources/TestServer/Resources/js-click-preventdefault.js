var link = document.querySelectorAll("a")[0];
link.addEventListener("click", function (event) {
  event.preventDefault();
  document.querySelectorAll("strong")[0].innerHTML = "click was intercepted";
});
