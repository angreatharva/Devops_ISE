// Polyfill for process object
if (typeof window !== 'undefined') {
  window.process = window.process || {};
  window.process.uptime = function() {
    return 0;
  };
  window.process.env = window.process.env || {};
} 