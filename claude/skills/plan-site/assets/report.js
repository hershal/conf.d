// Report interactivity: theme toggle, active-nav tracking, scroll reveal,
// and the before/after image overlay slider. No dependencies.

(function () {
  const root = document.documentElement;

  // ---- Theme (persisted) --------------------------------------------------
  const KEY = "plan-site-theme";
  function applyTheme(t) {
    root.classList.toggle("dark", t === "dark");
    document.querySelectorAll("[data-theme-label]").forEach((el) => {
      el.textContent = t === "dark" ? "Dark" : "Light";
    });
  }
  let theme = localStorage.getItem(KEY) ||
    (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  applyTheme(theme);
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-theme-toggle]");
    if (!btn) return;
    theme = root.classList.contains("dark") ? "light" : "dark";
    localStorage.setItem(KEY, theme);
    applyTheme(theme);
  });

  // ---- Mobile nav drawer (hamburger table of contents) -------------------
  // Reveals the existing sidebar <aside> as a left drawer on small screens,
  // so the table of contents needs no duplicated markup.
  const aside = document.querySelector("aside");
  if (aside) {
    let backdrop = null;
    function closeDrawer() {
      aside.classList.remove("nav-mobile-open");
      if (backdrop) backdrop.style.display = "none";
      document.body.style.overflow = "";
    }
    const openDrawer = () => {
      aside.classList.add("nav-mobile-open");
      if (!backdrop) {
        backdrop = document.createElement("div");
        backdrop.className = "nav-backdrop";
        backdrop.addEventListener("click", closeDrawer);
        document.body.appendChild(backdrop);
      }
      backdrop.style.display = "block";
      document.body.style.overflow = "hidden";
    };
    document.addEventListener("click", (e) => {
      if (e.target.closest("[data-nav-toggle]")) {
        e.preventDefault();
        aside.classList.contains("nav-mobile-open") ? closeDrawer() : openDrawer();
      } else if (aside.classList.contains("nav-mobile-open") && e.target.closest("aside a")) {
        closeDrawer();
      }
    });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeDrawer(); });
    window.matchMedia("(min-width: 1024px)").addEventListener("change", (e) => { if (e.matches) closeDrawer(); });
  }

  // ---- Active section in sticky nav --------------------------------------
  const links = Array.from(document.querySelectorAll(".nav-link"));
  const byId = new Map(links.map((l) => [l.getAttribute("href").slice(1), l]));
  const sections = links
    .map((l) => document.getElementById(l.getAttribute("href").slice(1)))
    .filter(Boolean);
  const spy = new IntersectionObserver(
    (entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) {
          links.forEach((l) => l.setAttribute("data-active", "false"));
          const link = byId.get(en.target.id);
          if (link) link.setAttribute("data-active", "true");
        }
      });
    },
    { rootMargin: "-45% 0px -50% 0px", threshold: 0 }
  );
  sections.forEach((s) => spy.observe(s));

  // ---- Reveal on scroll ---------------------------------------------------
  const revealer = new IntersectionObserver(
    (entries, obs) => {
      entries.forEach((en) => {
        if (en.isIntersecting) {
          en.target.classList.add("in");
          obs.unobserve(en.target);
        }
      });
    },
    { rootMargin: "0px 0px -8% 0px" }
  );
  document.querySelectorAll(".reveal").forEach((el) => revealer.observe(el));

  // ---- Before/after image slider -----------------------------------------
  document.querySelectorAll("[data-slider]").forEach((wrap) => {
    const after = wrap.querySelector(".slider-after");
    const handle = wrap.querySelector(".slider-handle");
    function setPct(pct) {
      pct = Math.max(0, Math.min(100, pct));
      after.style.width = pct + "%";
      handle.style.left = pct + "%";
    }
    setPct(50);
    let dragging = false;
    function fromEvent(e) {
      const rect = wrap.getBoundingClientRect();
      const x = (e.touches ? e.touches[0].clientX : e.clientX) - rect.left;
      setPct((x / rect.width) * 100);
    }
    const start = (e) => { dragging = true; fromEvent(e); };
    const move = (e) => { if (dragging) fromEvent(e); };
    const end = () => { dragging = false; };
    wrap.addEventListener("mousedown", start);
    wrap.addEventListener("touchstart", start, { passive: true });
    window.addEventListener("mousemove", move);
    window.addEventListener("touchmove", move, { passive: true });
    window.addEventListener("mouseup", end);
    window.addEventListener("touchend", end);
  });
})();
