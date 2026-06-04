console.log('[pm-ext] install_marker.js loaded on', window.location.href);
try { localStorage.setItem('pm_ext_installed', '1'); } catch (_) {}
document.documentElement.setAttribute('data-pm-ext-installed', '');
