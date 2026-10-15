// Builds the post's table of contents from its top-level headings (h2).
(() => {
  const WIDE = window.matchMedia("(min-width: 80rem)");

  const slugify = (s) =>
    s.toLowerCase().normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "section";

  function init() {
    const nav = document.getElementById("toc");
    const body = document.querySelector(".post-body");
    if (!nav || !body) return;

    const headings = [...body.querySelectorAll("h2")];
    if (headings.length < 2) return;

    const list = nav.querySelector("ol");
    const details = nav.querySelector("details");
    const used = new Set();
    const links = new Map();

    for (const h of headings) {
      if (!h.id) { // respect hand-written $heading.id(...)
        let id = slugify(h.textContent), base = id, n = 2;
        while (used.has(id) || document.getElementById(id)) id = `${base}-${n++}`;
        h.id = id;
      }
      used.add(h.id);
      const a = document.createElement("a");
      a.href = `#${h.id}`;
      a.textContent = h.textContent;
      const li = document.createElement("li");
      li.append(a);
      list.append(li);
      links.set(h, a);
    }
    nav.hidden = false;

    // Sidebar always expanded on wide screens; collapsed by default on narrow ones.
    const syncOpen = () => { details.open = WIDE.matches; };
    syncOpen();
    WIDE.addEventListener("change", syncOpen);

    // Active section = last heading that has scrolled past the top third of the viewport.
    let current = null;
    const update = () => {
      const line = window.innerHeight / 3;
      let active = null;
      for (const h of headings) {
        if (h.getBoundingClientRect().top <= line) active = h; else break;
      }
      if (active === current) return;
      if (current) links.get(current).removeAttribute("aria-current");
      if (active) links.get(active).setAttribute("aria-current", "true");
      current = active;
    };
    const io = new IntersectionObserver(update, { rootMargin: "0px 0px -66% 0px" });
    headings.forEach((h) => io.observe(h));
    update();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
