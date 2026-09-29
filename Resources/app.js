const mq = matchMedia('(prefers-color-scheme: dark)');
let last = null, gen = 0, cur = Promise.resolve();

mq.addEventListener('change', () => { if (last) render(...last); });

document.addEventListener('click', e => {
  const a = e.target.closest('a[href^="#"]');
  if (!a) return;
  e.preventDefault();
  const el = document.getElementById(decodeURIComponent(a.getAttribute('href').slice(1)));
  if (el) el.scrollIntoView();
});

function render(md, base) {
  last = [md, base];
  return cur = doRender(md, base, ++gen);
}

async function doRender(md, base, g) {
  let b = document.querySelector('base');
  if (!b) document.head.appendChild(b = document.createElement('base'));
  b.href = base;

  const el = document.getElementById('content');
  const y = scrollY;
  el.innerHTML = marked.parse(md, { gfm: true });

  const seen = {};
  el.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(h => {
    const s = h.textContent.trim().toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, '').replace(/\s/g, '-');
    h.id = seen[s] ? `${s}-${seen[s]++}` : (seen[s] = 1, s);
  });

  const nodes = [];
  el.querySelectorAll('pre > code.language-mermaid').forEach(c => {
    const d = document.createElement('div');
    d.className = 'mermaid';
    d.textContent = c.textContent;
    c.parentElement.replaceWith(d);
    nodes.push(d);
  });
  if (nodes.length) {
    mermaid.initialize({ startOnLoad: false, securityLevel: 'strict', theme: mq.matches ? 'dark' : 'default' });
    await mermaid.run({ nodes, suppressErrors: true });
  }
  if (g === gen) scrollTo(0, y);
}

// Resolve once the page follows the wanted scheme and the resulting re-render is done.
async function settle(dark) {
  if (mq.matches !== dark) {
    await new Promise(r => {
      const t = setTimeout(r, 1500);
      mq.addEventListener('change', () => { clearTimeout(t); setTimeout(r, 0); }, { once: true });
    });
  }
  await cur;
}
