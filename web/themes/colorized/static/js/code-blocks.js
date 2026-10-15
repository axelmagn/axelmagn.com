// Wrap fenced code blocks with a header tab + copy button.
// Runs once after DOM is ready (loaded at end of <body>).

function copyCode(pre, header, button) {
  var code = pre.querySelector("code");
  navigator.clipboard.writeText(code.innerText);

  header.classList.add("active");
  button.disabled = true;

  setTimeout(function () {
    header.classList.remove("active");
    button.disabled = false;
  }, 1000);
}

document.querySelectorAll("pre > code[data-lang]").forEach(function (code) {
  var pre = code.parentElement;
  var lang = code.dataset.lang;

  var wrapper = document.createElement("div");
  wrapper.className = "code-block";

  var header = document.createElement("div");
  header.className = "code-header";

  var label = document.createElement("span");
  label.textContent = lang.toLowerCase();
  header.appendChild(label);

  if (navigator.clipboard) {
    var button = document.createElement("button");
    button.title = "Copy code";
    button.setAttribute("aria-label", "Copy code");
    var icon = document.createElement("i");
    icon.className = "icon";
    button.appendChild(icon);
    button.addEventListener("click", function () {
      copyCode(pre, header, button);
    });
    header.appendChild(button);
  }

  pre.parentNode.insertBefore(wrapper, pre);
  wrapper.appendChild(header);
  wrapper.appendChild(pre);
});
