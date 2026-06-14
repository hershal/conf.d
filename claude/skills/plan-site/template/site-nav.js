/* THE SITE OUTLINE — declared ONCE for the whole report.
   report.js reads this on every page and renders the sidebar tree, the page
   numbers, the group headers, and the "current page" highlight from it. Order
   here is reading order; numbering is derived, so you never hand-type ordinals
   (and they can never drift between pages). Insert/reorder a page → just edit
   this one file.

   Copy this file into the report folder next to the pages and edit it. Each
   page must <script defer src="./site-nav.js"></script> BEFORE report.js.

   A page's *sections* are NOT listed here — report.js reads them from the page
   itself: every <section>/<header> with an id and a data-toc="Label" becomes a
   sub-entry under the current page. */

window.SITE_NAV = {
  report: "Report Title",          // shown in the brand + breadcrumb
  logo: "RT",                       // 2–3 char mark in the brand chip
  tagline: "Project · 1 Jan 2026",  // optional small line under the brand
  groups: [
    // A group with label:null renders its pages with no header (top-level).
    { label: null, pages: [
      { file: "index.html", title: "Overview" },
    ]},
    { label: "Part one", pages: [
      { file: "page-two.html",   title: "Second page" },
      { file: "page-three.html", title: "Third page" },
    ]},
    // { label: "Part two", pages: [ … ] },
  ],
};
