// SPDX-License-Identifier: AGPL-3.0-or-later

/* global searxng */

searxng.ready(() => {
  searxng.infinite_scroll_supported =
    "IntersectionObserver" in window &&
    "IntersectionObserverEntry" in window &&
    "intersectionRatio" in window.IntersectionObserverEntry.prototype;

  if (searxng.endpoint !== "results") {
    return;
  }

  if (!searxng.infinite_scroll_supported) {
    console.log("IntersectionObserver not supported");
    return;
  }

  const d = document;
  const onlyImages = d.getElementById("results").classList.contains("only_template_images");

  function newLoadSpinner() {
    const loader = d.createElement("div");
    loader.classList.add("loader");
    return loader;
  }

  function replaceChildrenWith(element, children) {
    element.textContent = "";
    children.forEach((child) => element.appendChild(child));
  }

  function loadNextPage(callback) {
    const form = d.querySelector("#pagination form.next_page");
    if (!form) {
      return;
    }
    replaceChildrenWith(d.querySelector("#pagination"), [newLoadSpinner()]);
    const formData = new FormData(form);
    searxng
      .http("POST", d.querySelector("#search").getAttribute("action"), formData)
      .then((response) => {
        const nextPageDoc = new DOMParser().parseFromString(response, "text/html");
        const articleList = nextPageDoc.querySelectorAll("#urls article");
        const paginationElement = nextPageDoc.querySelector("#pagination");
        d.querySelector("#pagination").remove();
        if (articleList.length > 0 && !onlyImages) {
          // do not add <hr> element when there are only images
          d.querySelector("#urls").appendChild(d.createElement("hr"));
        }
        articleList.forEach((articleElement) => {
          d.querySelector("#urls").appendChild(articleElement);
        });
        if (paginationElement) {
          d.querySelector("#results").appendChild(paginationElement);
          callback();
        }
      })
      .catch((err) => {
        console.log(err);
        const e = d.createElement("div");
        e.textContent = searxng.settings.translations.error_loading_next_page;
        e.classList.add("dialog-error");
        e.setAttribute("role", "alert");
        replaceChildrenWith(d.querySelector("#pagination"), [e]);
      });
  }

  if (searxng.settings.infinite_scroll && searxng.infinite_scroll_supported) {
    const intersectionObserveOptions = {
      rootMargin: "20rem"
    };
    const observedSelector = "article.result:last-child";
    const observer = new IntersectionObserver((entries) => {
      const paginationEntry = entries[0];
      if (paginationEntry.isIntersecting) {
        observer.unobserve(paginationEntry.target);
        loadNextPage(() => observer.observe(d.querySelector(observedSelector), intersectionObserveOptions));
      }
    });
    observer.observe(d.querySelector(observedSelector), intersectionObserveOptions);
  }
});
