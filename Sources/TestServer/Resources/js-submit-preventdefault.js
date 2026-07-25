var form = document.querySelectorAll("form")[0];
form.addEventListener("submit", function (event) {
  event.preventDefault();
  document.querySelectorAll("strong")[0].innerHTML = "submit was intercepted";
});
