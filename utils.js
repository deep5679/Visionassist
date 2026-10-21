// Pure helper functions (unit-testable in Node and usable in the browser).
function cleanText(raw) {
  if (typeof raw !== 'string') return '';
  return raw
    .replace(/\r\n?/g, '\n')
    .replace(/[ \t]+/g, ' ')
    .split('\n')
    .map((line) => line.trim())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

function clampRate(value) {
  const n = Number(value);
  if (Number.isNaN(n)) return 1;
  return Math.min(2, Math.max(0.5, n));
}

if (typeof module !== 'undefined') module.exports = { cleanText, clampRate };
