(function () {
  const $ = (id) => document.getElementById(id);
  const input = $('image'), preview = $('preview'), scan = $('scan');
  const statusEl = $('status'), progress = $('progress'), text = $('text');
  const rate = $('rate'), rateOut = $('rateOut');
  let file = null, size = 1.2;

  function setStatus(msg) { statusEl.textContent = msg; }

  input.addEventListener('change', () => {
    file = input.files[0] || null;
    if (!file) return;
    preview.src = URL.createObjectURL(file);
    preview.hidden = false;
    scan.disabled = false;
    setStatus('Photo ready. Choose "Read text from photo".');
  });

  scan.addEventListener('click', async () => {
    if (!file) return;
    if (typeof Tesseract === 'undefined') {
      setStatus('Text recognition could not load. Check your internet connection and reload the page.');
      return;
    }
    scan.disabled = true;
    progress.hidden = false;
    setStatus('Reading text. This can take a few seconds.');
    try {
      const result = await Tesseract.recognize(file, 'eng', {
        logger: (m) => { if (m.status === 'recognizing text') progress.value = Math.round(m.progress * 100); }
      });
      text.value = cleanText(result.data.text);
      setStatus(text.value ? 'Done. Choose "Read aloud" to listen.' : 'No text found. Try a clearer, well-lit photo.');
    } catch (e) {
      setStatus('Could not read this photo. Try another image.');
    } finally {
      progress.hidden = true; progress.value = 0; scan.disabled = false;
    }
  });

  $('speak').addEventListener('click', () => {
    if (!('speechSynthesis' in window)) { setStatus('Speech is not supported in this browser.'); return; }
    const t = cleanText(text.value);
    if (!t) { setStatus('There is no text to read. Add a photo or type some text.'); return; }
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(t);
    u.rate = clampRate(rate.value);
    speechSynthesis.speak(u);
    setStatus('Reading aloud.');
  });
  $('stop').addEventListener('click', () => { speechSynthesis.cancel(); setStatus('Stopped.'); });
  $('clear').addEventListener('click', () => { text.value = ''; speechSynthesis.cancel(); setStatus('Text cleared.'); });
  rate.addEventListener('input', () => { rateOut.textContent = clampRate(rate.value).toFixed(1); });

  function applySize() { document.documentElement.style.setProperty('--size', size + 'rem'); }
  $('bigger').addEventListener('click', () => { size = Math.min(2, size + 0.15); applySize(); });
  $('smaller').addEventListener('click', () => { size = Math.max(1, size - 0.15); applySize(); });

  const contrast = $('contrast');
  contrast.addEventListener('click', () => {
    const light = document.documentElement.dataset.theme !== 'light';
    document.documentElement.dataset.theme = light ? 'light' : 'dark';
    contrast.setAttribute('aria-pressed', String(light));
    contrast.textContent = light ? 'Dark mode' : 'Light mode';
  });
})();
