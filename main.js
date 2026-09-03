/* Phoenix Conexus — main.js */

/* ── NAV ── */
const nav = document.getElementById('nav');
if (nav) {
  window.addEventListener('scroll', () => nav.classList.toggle('scrolled', scrollY > 40), { passive: true });
}
const burger = document.getElementById('burger');
const navLinks = document.getElementById('navLinks');
if (burger && navLinks) {
  burger.addEventListener('click', () => navLinks.classList.toggle('open'));
}

/* ── SCROLL REVEAL ── */
const io = new IntersectionObserver((entries) => {
  entries.forEach((e, i) => {
    if (e.isIntersecting) {
      setTimeout(() => e.target.classList.add('in'), i * 70);
      io.unobserve(e.target);
    }
  });
}, { threshold: 0.08 });
document.querySelectorAll('.reveal').forEach(el => io.observe(el));

/* ── LIGHTBOX ── */
(function () {
  const lb        = document.getElementById('lightbox');
  if (!lb) return;

  const lbImg     = document.getElementById('lb-img');
  const lbCaption = document.getElementById('lb-caption');
  const lbClose   = document.getElementById('lb-close');
  const lbPrev    = document.getElementById('lb-prev');
  const lbNext    = document.getElementById('lb-next');

  let currentSection = null; // array of {src, alt} for the active section
  let currentIndex   = 0;

  function buildSectionImages(sectionEl) {
    return Array.from(sectionEl.querySelectorAll('.img-frame img')).map(img => ({
      src: img.src,
      alt: img.alt || ''
    }));
  }

  function show(images, index) {
    currentSection = images;
    currentIndex   = index;
    const item     = images[index];
    lbImg.src      = item.src;
    lbImg.alt      = item.alt;
    lbCaption.textContent = item.alt ? item.alt + '  \u2014  ' + (index + 1) + ' / ' + images.length
                                      : (index + 1) + ' / ' + images.length;
    lb.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function close() {
    lb.classList.remove('open');
    document.body.style.overflow = '';
    lbImg.src = '';
    currentSection = null;
  }

  function step(dir) {
    if (!currentSection) return;
    currentIndex = (currentIndex + dir + currentSection.length) % currentSection.length;
    show(currentSection, currentIndex);
  }

  // Click on any img-frame opens its section's lightbox
  document.querySelectorAll('.div-section').forEach(section => {
    section.querySelectorAll('.img-frame').forEach((frame, idx) => {
      frame.style.cursor = 'pointer';
      frame.addEventListener('click', () => {
        const images = buildSectionImages(section);
        show(images, idx);
      });
    });
  });

  lbClose.addEventListener('click', close);
  lbPrev.addEventListener('click', () => step(-1));
  lbNext.addEventListener('click', () => step(1));

  // Keyboard
  document.addEventListener('keydown', e => {
    if (!lb.classList.contains('open')) return;
    if (e.key === 'Escape')      close();
    if (e.key === 'ArrowLeft')   step(-1);
    if (e.key === 'ArrowRight')  step(1);
  });

  // Click outside image closes
  lb.addEventListener('click', e => {
    if (e.target === lb) close();
  });
})();
