var input = document.querySelectorAll("input")[0];
var name = input.getAttribute("name");
console.log("querySelectorAll/getAttribute: input name is " + name);
document.querySelectorAll("b")[0].innerHTML = name;
