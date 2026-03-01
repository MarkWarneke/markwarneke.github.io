// Main site JavaScript - vanilla JS (no jQuery dependency)

var main = {
  bigImgEl: null,
  numImgs: null,

  init: function () {
    var navbar = document.querySelector(".navbar");
    var avatarContainer = document.querySelector(".navbar-custom .avatar-container");

    // Shorten the navbar after scrolling a little bit down
    window.addEventListener("scroll", function () {
      if (navbar && navbar.getBoundingClientRect().top + window.scrollY > 50) {
        navbar.classList.add("top-nav-short");
        if (avatarContainer) avatarContainer.style.opacity = "0";
      } else {
        navbar.classList.remove("top-nav-short");
        if (avatarContainer) avatarContainer.style.opacity = "1";
      }
    });

    // On mobile, hide the avatar when expanding the navbar menu
    var mainNavbar = document.getElementById("main-navbar");
    if (mainNavbar) {
      mainNavbar.addEventListener("show.bs.collapse", function () {
        navbar.classList.add("top-nav-expanded");
      });
      mainNavbar.addEventListener("hidden.bs.collapse", function () {
        navbar.classList.remove("top-nav-expanded");
      });

      // On mobile, when clicking on a multi-level navbar menu, show the child links
      mainNavbar.addEventListener("click", function (e) {
        if (e.target.classList.contains("navlinks-parent")) {
          var allParents = document.querySelectorAll(".navlinks-parent");
          allParents.forEach(function (el) {
            if (el === e.target) {
              el.parentElement.classList.toggle("show-children");
            } else {
              el.parentElement.classList.remove("show-children");
            }
          });
        }
      });
    }

    // Ensure nested navbar menus are not longer than the menu header
    var menus = document.querySelectorAll(".navlinks-container");
    if (menus.length > 0) {
      var navbarUl = document.querySelector("#main-navbar ul");
      if (navbarUl) {
        var fakeMenu = document.createElement("li");
        fakeMenu.className = "fake-menu";
        fakeMenu.style.display = "none";
        fakeMenu.innerHTML = "<a></a>";
        navbarUl.appendChild(fakeMenu);

        menus.forEach(function (menu) {
          var children = menu.querySelectorAll(".navlinks-children a");
          var words = [];
          children.forEach(function (el) {
            words = words.concat(el.textContent.trim().split(/\s+/));
          });
          var maxwidth = 0;
          words.forEach(function (word) {
            fakeMenu.innerHTML = "<a>" + word + "</a>";
            fakeMenu.style.display = "";
            var width = fakeMenu.offsetWidth;
            fakeMenu.style.display = "none";
            if (width > maxwidth) maxwidth = width;
          });
          menu.style.minWidth = maxwidth + "px";
        });

        fakeMenu.remove();
      }
    }

    // show the big header image
    main.initImgs();
  },

  initImgs: function () {
    var el = document.getElementById("header-big-imgs");
    if (!el) return;

    main.bigImgEl = el;
    main.numImgs = parseInt(el.getAttribute("data-num-img"), 10);

    var imgInfo = main.getImgInfo();
    main.setImg(imgInfo.src, imgInfo.desc);

    // For better UX, prefetch the next image
    var getNextImg = function () {
      var imgInfo = main.getImgInfo();
      var src = imgInfo.src;
      var desc = imgInfo.desc;

      var prefetchImg = new Image();
      prefetchImg.src = src;

      setTimeout(function () {
        var img = document.createElement("div");
        img.className = "big-img-transition";
        img.style.backgroundImage = "url(" + src + ")";

        var header = document.querySelector(".intro-header.big-img");
        if (header) header.prepend(img);

        setTimeout(function () {
          img.style.opacity = "1";
        }, 50);

        setTimeout(function () {
          main.setImg(src, desc);
          img.remove();
          getNextImg();
        }, 1000);
      }, 6000);
    };

    if (main.numImgs > 1) {
      getNextImg();
    }
  },

  getImgInfo: function () {
    var randNum = Math.floor(Math.random() * main.numImgs + 1);
    var src = main.bigImgEl.getAttribute("data-img-src-" + randNum);
    var desc = main.bigImgEl.getAttribute("data-img-desc-" + randNum);
    return { src: src, desc: desc };
  },

  setImg: function (src, desc) {
    var header = document.querySelector(".intro-header.big-img");
    if (header) header.style.backgroundImage = "url(" + src + ")";

    var imgDesc = document.querySelector(".img-desc");
    if (imgDesc) {
      if (desc) {
        imgDesc.textContent = desc;
        imgDesc.style.display = "";
      } else {
        imgDesc.style.display = "none";
      }
    }
  }
};

document.addEventListener("DOMContentLoaded", main.init);

// Reading progress bar
window.addEventListener("scroll", function () {
  var bar = document.getElementById("myBar");
  if (!bar) return;
  var winScroll = document.body.scrollTop || document.documentElement.scrollTop;
  var height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  bar.style.width = (winScroll / height) * 100 + "%";
});

// Scroll to top button
document.addEventListener("DOMContentLoaded", function () {
  var scrollBtn = document.getElementById("scroll");
  if (!scrollBtn) return;

  window.addEventListener("scroll", function () {
    if (window.scrollY > 100) {
      scrollBtn.style.display = "block";
      scrollBtn.style.opacity = "1";
    } else {
      scrollBtn.style.opacity = "0";
      setTimeout(function () {
        if (window.scrollY <= 100) scrollBtn.style.display = "none";
      }, 300);
    }
  });

  scrollBtn.addEventListener("click", function (e) {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  });
});
