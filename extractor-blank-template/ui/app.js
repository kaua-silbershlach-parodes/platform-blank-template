const { invoke } = window.__TAURI__.core;
const el = (id) => document.getElementById(id);
let ctx = null;

async function init() {
  ctx = await invoke('dialog_context');
  if (ctx.mode === 'password') {
    el('title').textContent = 'Archive Password';
    el('add-card').classList.add('hidden');
    el('password-card').classList.remove('hidden');
    return;
  }
  el('archive-name').value = ctx.suggested_name;
}

el('btn-create').addEventListener('click', async () => {
  const name = el('archive-name').value.trim();
  const format = el('format').value;
  const level = parseInt(el('level').value, 10);
  const password = el('password').value;
  const password2 = el('password2').value;
  if (!name) { el('status').textContent = 'Enter an archive name.'; return; }
  if (password !== password2) { el('status').textContent = 'Passwords do not match.'; return; }
  if (format === 'zip' && password) { el('status').textContent = 'Password encryption is available for ELITE format.'; return; }
  const ext = format === 'elite' ? '.elite' : '.zip';
  const dest = ctx.parent + '\\' + name + ext;
  el('status').textContent = 'Creating archive...';
  try {
    el('status').textContent = await invoke('create_archive', { source: ctx.source, dest, format, level, password });
  } catch (err) {
    el('status').textContent = 'Failed: ' + err;
  }
});

el('btn-extract').addEventListener('click', async () => {
  try {
    el('password-status').textContent = await invoke('extract_with_password', { password: el('extract-password').value });
  } catch (err) {
    el('password-status').textContent = 'Failed: ' + err;
  }
});

init();
