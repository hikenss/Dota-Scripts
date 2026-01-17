const { ipcRenderer } = require('electron');

window.electronAPI = {
  setClickThrough: (enabled) => {
    ipcRenderer.send('set-click-through', enabled);
  }
};
