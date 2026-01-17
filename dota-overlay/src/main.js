const { app, BrowserWindow, screen, ipcMain } = require('electron');
const path = require('path');
const server = require('./server');

let mainWindow;

function createWindow() {
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  mainWindow = new BrowserWindow({
    width: width,
    height: height,
    transparent: true,
    frame: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      enableRemoteModule: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  // Remove menu
  mainWindow.setMenu(null);
  
  // Inicia com click-through, mas permite interação em áreas específicas
  mainWindow.setIgnoreMouseEvents(true, { forward: true });
  
  // Listener para habilitar/desabilitar click-through baseado em hover
  mainWindow.webContents.on('did-finish-load', () => {
    mainWindow.webContents.executeJavaScript(`
      let isOverUI = false;
      
      function checkIfOverUI(x, y) {
        const element = document.elementFromPoint(x, y);
        const uiElements = document.querySelectorAll('.panel, .status-indicator, button, .hero-item');
        
        for (let ui of uiElements) {
          if (ui.contains(element)) {
            return true;
          }
        }
        return false;
      }
      
      document.addEventListener('mousemove', (e) => {
        const overUI = checkIfOverUI(e.clientX, e.clientY);
        if (overUI !== isOverUI) {
          isOverUI = overUI;
          window.electronAPI?.setClickThrough(!isOverUI);
        }
      });
    `);
  });

  mainWindow.loadFile('src/renderer/index.html');

  // DevTools para desenvolvimento
  // mainWindow.webContents.openDevTools();

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
  
  // IPC handler para controlar click-through
  ipcMain.on('set-click-through', (event, clickThrough) => {
    if (mainWindow) {
      mainWindow.setIgnoreMouseEvents(clickThrough, { forward: true });
    }
  });
}

app.whenReady().then(() => {
  // Inicia o servidor GSI
  server.start();
  
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  server.stop();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
